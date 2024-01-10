#!/bin/bash
  ################################################################################
  #
  # Copyright 2023 Fidesint LLC
  #
  # Licensed under the Apache License, Version 2.0 (the "License");
  # you may not use this file except in compliance with the License.
  # You may obtain a copy of the License at
  #
  # http://www.apache.org/licenses/LICENSE-2.0
  #
  # Unless required by applicable law or agreed to in writing, software
  # distributed under the License is distributed on an "AS IS" BASIS,
  # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  # See the License for the specific language governing permissions and
  # limitations under the License.
  #
  ########################################################################################
  ## File Name: autoDLQ.sh                                                      		##
  ## Author: Ashlin Joseph                                                      		##                                                 
  ##                                                                            	  	##
  ##    This script will deploy dead letter queue handlers for each of the queue 		##
  ##  managers in a given MQ Appliance after creating all the required MQ Objects. 		##
  ##  The script will then monitor the dead letter queue handlers to check if they 		##
  ##  running smoothly. If any of the handlers process dies, a new one is deployed.		##
  ##  If any of the MQ Objects required are deleted, it'll be recreated. If a new       ##
  ##  queue manager is created in the appliance, the script will deploy all the objects ##
  ##  need and it'll deploy a new dead letter queue handler for that queue manager 		##
  ##  This script is built using Curl and jq.                                   		##
  ##    Curl: https://curl --silent.haxx.se/docs/manpage.html                   		##
  ##    jq: https://stedolan.github.io/jq/                                      		##
  ##                                                                            		##
  ########################################################################################
# PRE REQUISITES
# jq installed
# nmap installed
# MQA rest admin password encrypted using: echo 'yourpassword' | openssl enc -aes-256-cbc -md sha512 -a -salt -pass pass:'encrypted.password' > passwords/MQ_REST_PASSWORD_${APPLIANCE_ID}
# Check if a messaging user called 'dlquser' exists in the MQ Appliances, if not create them
# runmqdlq to be run as root
# Scripts for each appliance to be added to the cron tab @reboot
# WantedBy=multi-user.target
# sudo systemctl enable autoDLQ

#Start autoDLQ
#./autoDLQ.sh mqaprepalp1 &

#Check autoDLQ
#ps -ef | grep autoDLQ 
#ps -ef | grep runmqdlq 

#Stop autoDLQ
#


WORKING_DIR=/home/mqm/autoDLQ

# Input Appliance data
var="$1"
if [ ! -n "$var" ]
then
	  echo "$0 - Error APPLIANCE_ID is not set or is NULL"
	  exit 1
else
	  APPLIANCE_ID=$var
fi

HOSTNAME=${APPLIANCE_ID}.aib.pri
APPLIANCE_IP=`echo $(nslookup ${HOSTNAME} | awk '/^Address: / { print $2 ; exit }')`
BOX_IP=`ip -o route get to ${APPLIANCE_IP} | sed -n 's/.*src \([0-9.]\+\).*/\1/p'`
REST_PORT=5554
MQ_REST_USER=restdlq		#MQAppliance user that's needed to make rest API calls
MQ_REST_PASSWORD=`echo $(< ${WORKING_DIR}/passwords/MQ_REST_PASSWORD_${APPLIANCE_ID}) | openssl enc -aes-256-cbc -md sha512 -a -d -salt -pass pass:'encrypted.password'`
DLQHANDLER_GROUP=dlqgrp		#Messaging user within mqcli that runs the runmqdlq handler and connects to the queue managers
DLQHANDLER_USER=dlquser
LOG_DIR=${WORKING_DIR}/logs
ERROR_DIR=${WORKING_DIR}/errors
CCDT_DIR=${WORKING_DIR}/ccdt
RULES=${WORKING_DIR}/rules
MQBIN_PATH=/app/mqm2/bin/
SSLKEYDB=/home/srv_mqaservice/autoDLQ/ssl/key

DLQCHANNEL=DLQ.CHANNEL
DLQLISTENER=DLQ.LISTENER

LOG_FILE_NAME=autoDLQHandler_${APPLIANCE_ID}.log
MQSC_LOG_FILE_NAME=mqsc_autoDLQHandler_${APPLIANCE_ID}.log


source ${WORKING_DIR}/helper.sh

mkdir -p $LOG_DIR
mkdir -p $ERROR_DIR
mkdir -p $CCDT_DIR
mkdir -p $RULES

#Returns the DEADQ configured for a given Queue Manager
function returnDLQ {

	output3=$(curl --silent -k https://$HOSTNAME:$REST_PORT/ibmmq/rest/v1/admin/action/qmgr/$QMGR/mqsc -X POST -u $MQ_REST_USER:$MQ_REST_PASSWORD -H "ibm-mq-rest-csrf-token: value" -H "Content-Type: application/json" --data "{\"type\": \"runCommandJSON\", \"command\": \"display\", \"qualifier\": \"qmgr\", \"responseParameters\" : [\"DEADQ\"]}")

	emptydeadqm=`echo $output3 | jq '.commandResponse[].parameters | .qmname' | tr -d \"`
	dlq=`echo $output3 | jq '.commandResponse[].parameters | .deadq' | tr -d \"`

	#echo "DLQ found in $QMGR : $dlq"

	ERROR_FILE_NAME=ERROR_RETURN_DLQ_${LOG_FILE_NAME}

	if [[ `echo $output3 | jq '.overallCompletionCode'` != 0 ]]
	then
		echo "ERROR: RUNMQSC COMMAND TO RETURN DLQ CONFIGURED FOR ${qmgr} FAILED" >> $ERROR_DIR/$ERROR_FILE_NAME
		echo $output3 >> $ERROR_DIR/$ERROR_FILE_NAME
	fi
}


function defineListener {

	#Create listener for each qmgr
	getRunningQueueManagerNames

	#An array is used to store queue manager name and port number [I know! Hash could've used here, but hey, keep it fun ay! ;)] It works!
	port=2
	w=1
	while [[ $QMGR != ${array[$w]} ]]
	do
		w=$(($w + 2))
		port=$(($port + 2))
	done

	DLQHANDLER_PORT=${array[$port]}

	MQSC_COMMAND="DEFINE LISTENER($DLQLISTENER) TRPTYPE(TCP) PORT($DLQHANDLER_PORT) CONTROL(QMGR)"
	ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest

}

function defineObjects {

	printf "$(date) Ensuring objects required for the DLQ Handler is in place for the $QMGR \n" >> $LOG_DIR/$LOG_FILE_NAME

	MQSC_COMMAND="DEFINE QLOCAL($QMGR.DLQ)"
	ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest

	MQSC_COMMAND="SET AUTHREC OBJTYPE(QUEUE) PROFILE($QMGR.DLQ) GROUP('"$DLQHANDLER_GROUP"') AUTHADD(ALL)"
	ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest

	if [[ ! "$dlq" ]]
	then

		MQSC_COMMAND="ALTER QMGR DEADQ($QMGR.DLQ)"
		ACTION=`echo "$MQSC_COMMAND"`
		runmqscrest

	fi

	MQSC_COMMAND="DEFINE QLOCAL($QMGR.DLQ.PAYMENTS)"
		ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest

	MQSC_COMMAND="DEFINE QLOCAL($QMGR.DLQ.QDELETED)"
		ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest

	MQSC_COMMAND="DEFINE QLOCAL($QMGR.DLQ.OTHERS)"
		ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest

	MQSC_COMMAND="DEFINE CHANNEL($DLQCHANNEL) CHLTYPE(SVRCONN) TRPTYPE(TCP)"
	ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest

	MQSC_COMMAND="ALTER CHANNEL($DLQCHANNEL) CHLTYPE(SVRCONN) TRPTYPE(TCP) SSLCIPH(TLS_RSA_WITH_AES_256_CBC_SHA256)"
	ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest

	MQSC_COMMAND="ALTER CHANNEL($DLQCHANNEL) CHLTYPE(SVRCONN) TRPTYPE(TCP) SSLCAUTH(REQUIRED)"
	ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest


	LISTENERNAME=$DLQLISTENER
	returnListenerPort

	if [[ "$LISTENER_PORT" != null ]]
	then
		MQSC_COMMAND="STOP LISTENER($DLQLISTENER)"
		ACTION=`echo "$MQSC_COMMAND"`
		runmqscrest
		MQSC_COMMAND="DELETE LISTENER($DLQLISTENER)"
		ACTION=`echo "$MQSC_COMMAND"`
		runmqscrest
	fi

	defineListener
	MQSC_COMMAND="START LISTENER($DLQLISTENER)"
	ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest
	sleep 3s

	MQSC_COMMAND="SET CHLAUTH('"$DLQCHANNEL"') TYPE(ADDRESSMAP) ADDRESS('"$BOX_IP"') USERSRC(MAP) MCAUSER('"$DLQHANDLER_USER"') ACTION(ADD)"
		ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest

	MQSC_COMMAND="SET AUTHREC OBJTYPE(QMGR) GROUP('"$DLQHANDLER_GROUP"') AUTHADD(CONNECT,INQ,DSP)"
		ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest
	returnDLQ
	MQSC_COMMAND="SET AUTHREC OBJTYPE(QUEUE) PROFILE($dlq) GROUP('"$DLQHANDLER_GROUP"') AUTHADD(ALL)"
		ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest

	MQSC_COMMAND="SET AUTHREC OBJTYPE(QUEUE) PROFILE($QMGR.DLQ.PAYMENTS) GROUP('"$DLQHANDLER_GROUP"') AUTHADD(ALL)"
		ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest
	
	MQSC_COMMAND="SET AUTHREC OBJTYPE(QUEUE) PROFILE($QMGR.DLQ.QDELETED) GROUP('"$DLQHANDLER_GROUP"') AUTHADD(ALL)"
		ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest

	MQSC_COMMAND="SET AUTHREC OBJTYPE(QUEUE) PROFILE($QMGR.DLQ.OTHERS) GROUP('"$DLQHANDLER_GROUP"') AUTHADD(ALL)"
		ACTION=`echo "$MQSC_COMMAND"`
	runmqscrest

	MQSC_COMMAND="REFRESH SECURITY TYPE(AUTHSERV)"
		ACTION=`echo "$MQSC_COMMAND" | tr '[:lower:]' '[:upper:]'`
	runmqscrest

}

#Creating dlq handler $RULES as agreed with the stakeholders
function createRules	{

		if [[ $RULES != null ]]
		then
			rm -f $RULES/$QMGR.rul
		fi
		printf "DESTQ(EP*) ACTION (FWD) FWDQ ($QMGR.DLQ.PAYMENTS) HEADER (YES)\n\nREASON(MQRC_UNKNOWN_OBJECT_NAME) ACTION (FWD) FWDQ ($QMGR.DLQ.QDELETED) HEADER (YES)\n\nREASON(MQRC_Q_DELETED) ACTION (FWD) FWDQ ($QMGR.DLQ.QDELETED) HEADER (YES)\n\nREASON(MQRC_PERSISTENT_NOT_ALLOWED) ACTION(DISCARD)\n\nDESTQ(*) ACTION (FWD) FWDQ ($QMGR.DLQ.OTHERS) HEADER (YES)\n" > $RULES/$QMGR.rul
}

#function to send email alerts
function emailalertforerrors {
	MAILFILE=$LOG_DIR/email.txt

	echo "Subject: Error in DLQ Handler" > $MAILFILE
	echo "To: to_whom@to_where.com" >> $MAILFILE
	echo "From: from_who@from_where.com" >> $MAILFILE

	echo "" >> $MAILFILE
	echo "Error: " >> $MAILFILE
	echo "" >> $MAILFILE
	echo "DLQ Handler failed to run against the QMGR ${QMGR} on the appliance ${APPLIANCE_ID}, please investigate" >> $MAILFILE

	cat $MAILFILE | ssmtp someone@gmail.com
}

#function to backup log files as it hits the limitations
function linearlogging {

		number_of_lines=`wc --lines < $LOG_DIR/$LOG_FILE_NAME`
		number_of_lines_mqsc=`wc --lines < $LOG_DIR/$MQSC_LOG_FILE_NAME`
		max_lines=3000

		if (( $number_of_lines > $max_lines ))
		then
					 printf "$(date) This log file reached $max_lines lines so the file is backed up and starting fresh \n" >> $LOG_DIR/$LOG_FILE_NAME
					 mv $LOG_DIR/$LOG_FILE_NAME $LOG_DIR"/"$LOG_FILE_NAME"_"$(date +"%Y%m%d%I%M%S")
		fi

		if (( $number_of_lines_mqsc > $max_lines ))
		then
					 printf "$(date) This log file reached $max_lines lines so the file is backed up and starting fresh \n" >> $LOG_DIR/$LOG_FILE_NAME"_mqsc.log"
					 mv $LOG_DIR/$MQSC_LOG_FILE_NAME $LOG_DIR"/"$MQSC_LOG_FILE_NAME"_"$(date +"%Y%m%d%I%M%S")
		fi
}


printf "$(date)	|| Intiating Auto DLQ Handler for appliance with IP: $APPLIANCE_ID || \n" >> $LOG_DIR/$LOG_FILE_NAME
printf "$(date) -------------Ensuring all qmgrs running in the appliance got a Dead Letter Queue Handler running on this machine------------\n" >> $LOG_DIR/$LOG_FILE_NAME
printf "." >> $LOG_DIR/$LOG_FILE_NAME

while true
do
	#Result gives all running queue manager names on the box to the array 'qmgrNames'
	getRunningQueueManagerNames

	#Result gives all running queue manager names on the box to the array 'AllqmgrNames'
	getAllQueueManagerNames

	i=1
	k=2
	declare -a array
	DLQHANDLER_PORT=3670
	#For all Queue Managers	in the box, we're assigning a port number
	for qm in $AllqmgrNames
	do
		array[$i]=$qm
		index=0

		#Loops around port numbers starting from the initial value of DLQHANDLER_PORT checking if it's taken and if not, the port number is assigned to the queue manager.
		while [ $index -ne 1 ]
		do
			#If the port is in use, nmap will return the state to be 'open'
			port_status=$(nmap -p $DLQHANDLER_PORT $HOSTNAME | awk -v port="$DLQHANDLER_PORT" '$0 ~ port {print $2}')
			if [ "port_status" != "open" ]; then
				#echo "$DLQHANDLER_PORT on the $HOSTNAME is available" >> $LOG_DIR/$LOG_FILE_NAME
				index=1
			else
				echo "$DLQHANDLER_PORT on the $APPLIANCE_ID is taken"
				if [[ "$DLQHANDLER_PORT" == 3799 ]];then
					DLQHANDLER_PORT=3670
				else
					DLQHANDLER_PORT=$(($DLQHANDLER_PORT + 1))
				fi
			fi
		done

		array[$k]=$DLQHANDLER_PORT
		DLQHANDLER_PORT=$(($DLQHANDLER_PORT + 1))
		i=$(($i + 2))
		k=$(($k + 2))

	done

	getRunningQueueManagerNames
	for QMGR in $qmgrNames
	do
		sleep 1s
		CCDT_FILE_NAME=${APPLIANCE_ID}_${QMGR}_CCDT.json
		#echo "Working on $QMGR"
		#Returns the DEADQ configured for a given Queue Manager
		returnDLQ

		if [[ -z "$dlq" ]]
		then
			queuename=$dlq
			printf "$(date) Queue manager $QMGR identified to have no DLQ configured\n" >> $LOG_DIR/$LOG_FILE_NAME
			printf "$(date) Defining objects and deploying dlqhandler for the qmgr: $QMGR \n" >> $LOG_DIR/$LOG_FILE_NAME

			mkdir -p $RULES

			#returnDLQ
			defineObjects
			createRules

			#deletes any existing the $CCDT_DIR file
			rm -f ${CCDT_DIR}/$CCDT_FILE_NAME

			#Creates a JSON CCDT File in $CCDT_DIR 
			createJSONSSLccdt

			export MQCCDTURL=file://${CCDT_DIR}/$CCDT_FILE_NAME
			export MQSSLKEYR=$SSLKEYDB

			PATH_TO_RULE_FILE=$RULES/$QMGR.rul
			printf "$(date) Starting runmqdlq on $queuename $QMGR \n" >> $LOG_DIR/$LOG_FILE_NAME
			nohup ${MQBIN_PATH}runmqdlq $dlq $QMGR -c < $PATH_TO_RULE_FILE &>> $LOG_DIR/$LOG_FILE_NAME &
			sleep 5s

		else

			#echo "Queue manager $QMGR has DLQ configured"
			queuename=$dlq
			returnIPPROCS
			#echo "IPPROCS on $queuename is $queueIPPROCSvalue"
			if [[ `echo $queueIPPROCSvalue` == "0" || -z "${queueIPPROCSvalue}" || `echo $queueIPPROCSvalue` == "null" ]]
			then
				printf "$(date) The qmgr $QMGR on the appliance $APPLIANCE_ID has been identified to be running without a DLQ handler. \n" >> $LOG_DIR/$LOG_FILE_NAME

				mkdir -p $RULES

				#returnDLQ
				defineObjects
				createRules

				#Creates a JSON CCDT File in $CCDT_DIR 
				createJSONSSLccdt

				export MQCCDTURL=file://${CCDT_DIR}/$CCDT_FILE_NAME
				export MQSSLKEYR=$SSLKEYDB

				PATH_TO_RULE_FILE=$RULES/$QMGR.rul
				printf "$(date) Starting runmqdlq on $queuename $QMGR \n" >> $LOG_DIR/$LOG_FILE_NAME
				nohup ${MQBIN_PATH}runmqdlq $dlq $QMGR -c < $PATH_TO_RULE_FILE &>> $LOG_DIR/$LOG_FILE_NAME &

				#echo "$MQSERVER $MQCHLLIB $MQCHLTAB"
				#echo "${MQBIN_PATH}runmqdlq $dlq $QMGR -c < $PATH_TO_RULE_FILE "
				sleep 5s

			#else
				#echo "No Action taken: $QMGR is running with $dlq configure and has IPPROCS: $queueIPPROCSvalue"
				#printf "$(date) NO ACTION TAKEN: A handler is open against the DEADQ $queuename in the qmgr $QMGR \n" >> $LOG_DIR/$LOG_FILE_NAME
			fi
		fi
	done


	#Sleep time for every cycle; basically how often do you want to check if the dlqhandler is running, currently set to every minute.
	sleep 1m
	printf "." >> $LOG_DIR/$LOG_FILE_NAME
	#printf "$(date) DoubleChecking all running queue managers for a runmqdlq handler \n" >> $LOG_DIR/$LOG_FILE_NAME
	for QMGR in $qmgrNames
	do
		id=0
		returnDLQ
		queuename=$dlq

		returnIPPROCS

		PID=`ps -eaf | grep runmqdlq | grep -v grep | awk '{print $9 " " $10}'`

		DLQ_PID=`echo "$PID" | grep "$queuename"`

		if [[ $DLQ_PID != '' ]]
		then
			id=1
		fi

		if [[ $queueIPPROCSvalue -eq 0 || $id -eq 0 ]]
		then

		printf "$(date) DLQ Handler failed to run against the QMGR ${QMGR} on the appliance ${APPLIANCE_ID}, please investigate \n" >> $LOG_DIR/$LOG_FILE_NAME
		#emailalertforerrors

		#else
			#printf "$(date) All is good: DLQ Handler is running against the QMGR ${QMGR} on the appliance ${APPLIANCE_ID} \n" >> $LOG_DIR/$LOG_FILE_NAME
		fi
	done
	#printf "$(date)--------------------------------------------------\n\n\n" >> $LOG_DIR/$LOG_FILE_NAME
	#linearlogging
done
