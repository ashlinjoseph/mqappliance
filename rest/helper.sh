  #!/bin/bash
  ################################################################################
  #
  # Copyright 2022 Fidesint LLC
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
  ################################################################################
  ## File Name: helper.sh                                                       ##
  ## Author: Ashlin Joseph                                                      ##                                                 
  ##                                                                            ##
  ##    This helper library is built around some of the MQ Appliance REST API   ##
  ##  to help MQ appliance users to easily built scripts that can be used to    ##
  ##  perform tasks in the appliance.                                           ##
  ##                                                                            ##
  ##  To use the helper library you need to import the helper library:          ##
  ##          source ./restHelperLibrary.#!/bin/sh                              ##
  ##                                                                            ##
  ##  This script is built using Curl and jq.                                   ##
  ##    Curl: https://curl --silent.haxx.se/docs/manpage.html                   ##
  ##    jq: https://stedolan.github.io/jq/                                      ##
  ##                                                                            ##
  ################################################################################

  # Fn returns the list of running qmgrs in a given appliance via the REST API
  function getRunningQueueManagerNames {

    #Curl command to get running qmgr names and status;
    output3=$(curl --silent -s -u $MQ_REST_USER:$MQ_REST_PASSWORD -k https://$HOSTNAME:$REST_PORT/ibmmq/rest/v2/admin/qmgr -X GET)

    #Gets the names of the queue manager that are in "running" state
    qmgrNames=`echo $output3 | jq '.qmgr[] | select(.state == "running") | .name' | tr -d \" `
    # echo $qmgrNames > $LOG_DIR/QueueManagers.json
    #OUTPUT_FILE_NAME=$LOG_FILE_NAME'_getRunningQueueManagerNames.json'
    ERROR_FILE_NAME=ERROR_GET_RUNNING_QMGR_NAMES_${LOG_FILE_NAME}
    #Error Handling: If the qmgr names returned is empty, something has gone wrong!
    if [[ `echo $qmgrNames` == "" ]]
    then
      mkdir -p $ERROR_DIR
      echo "ERROR: GET Running Queue Manager Names Command FAILED" >> $ERROR_DIR/$ERROR_FILE_NAME
      echo "$output3" >> $ERROR_DIR/$ERROR_FILE_NAME
    #else
      #echo "$(date) Queue managers running in the appliance with IP: $HOSTNAME #are: \n"
      #echo $qmgrNames
    fi
  }

  function getAllQueueManagerNames {

    #Curl command to get all qmgr names and status;
    output3=$(curl --silent -s -u $MQ_REST_USER:$MQ_REST_PASSWORD -k https://$HOSTNAME:$REST_PORT/ibmmq/rest/v2/admin/qmgr -X GET)
    #Gets the names of the queue manager that are in "running" state
    AllqmgrNames=`echo $output3 | jq '.qmgr[] | .name' | tr -d \" `

    #Error Handling: If the qmgr names returned is empty, something has gone wrong!
    ERROR_FILE_NAME=ERROR_GET_ALL_QMGR_NAMES_${LOG_FILE_NAME}

    if [[ `echo $AllqmgrNames` == "" ]]
    then
      mkdir -p $ERROR_DIR
      echo "$output3" >> $ERROR_DIR/$ERROR_FILE_NAME
      echo "Getting all Queue Manager names failed!" >> $ERROR_DIR/$ERROR_FILE_NAME
    #else
      #echo "$(date) Queue managers running in the appliance with IP: $HOSTNAME #are: \n"
      #echo $AllqmgrNames
    fi
  }

  #Gets the port number 'LISTENER_PORT' for the given Listener 'LISTENERNAME'
  function returnListenerPort {

  	output3=$(curl --silent -k https://$HOSTNAME:$REST_PORT/ibmmq/rest/v1/admin/action/qmgr/$QMGR/mqsc -X POST -u $MQ_REST_USER:$MQ_REST_PASSWORD -H "ibm-mq-rest-csrf-token: value" -H "Content-Type: application/json" --data "{\"type\": \"runCommandJSON\", \"command\": \"display\", \"qualifier\": \"listener\", \"name\": \"$LISTENERNAME\", \"responseParameters\" : [\"PORT\"]}")

    LISTENER_PORT=`echo $output3 | jq '.commandResponse[].parameters | .port' | tr -d \"`

    ERROR_FILE_NAME=ERROR_RETURN_LISTENER_PORT_${LOG_FILE_NAME}
    MQRC_REASON_CODE=`echo $output3 | jq '.commandResponse[0].reasonCode'`

    if [[ `echo $output3 | jq '.overallCompletionCode'` != 0 ]]
    then
      if [[ $MQRC_REASON_CODE != '2085'  ]]
      then
          echo "ERROR: RUNMQSC COMMAND TO RETURN LISTENER PORT FOR ${LISTENERNAME} in ${QMGR} FAILED" >> $ERROR_DIR/$ERROR_FILE_NAME
          echo $output3 >> $ERROR_DIR/$ERROR_FILE_NAME
      fi
    fi
  }

  #Fn that runs a given RUNMQSC command via the REST API
  function runmqscrest {

    # ACTION=`echo "$MQSC_COMMAND"`
    #Curl command that runs RUNMQSC command WITH INPUT IN JSON FORMAT and receive the response
    #output3=$(curl --silent -k https://$HOSTNAME:$REST_PORT/ibmmq/rest/v2/admin/action/qmgr/$QMGR/mqsc -X POST -u $MQ_REST_USER:$MQ_REST_PASSWORD -H "ibm-mq-rest-csrf-token: value" -H "Content-Type: application/json" --data "{\"type\": \"runCommandJSON\",\"command\": \"$ACTION\", \"qualifier\": \"$MQSC_OBJ_TYPE\",\"name\": \"$MQSC_NAME\"}")
    #Curl command that runs RUNMQSC command and receive the response

    output3=$(curl --silent -k https://$HOSTNAME:$REST_PORT/ibmmq/rest/v2/admin/action/qmgr/$QMGR/mqsc -X POST -u $MQ_REST_USER:$MQ_REST_PASSWORD -H "ibm-mq-rest-csrf-token: value" -H "Content-Type: application/json" --data "{\"type\": \"runCommand\",\"parameters\": {\"command\": \"$ACTION \"}}")

    #Error Handling: Ensuring the REST Call was made successfully

    ACTION_IDENTITY=`echo "$ACTION" | tr -cd '[:alnum:]' | awk '{print substr($0,1,8);exit}'`
    # OUTPUT_FILE_NAME=${ACTION_IDENTITY}_OUTPUT.json
    ERROR_FILE_NAME=ERROR_RUNMQSC_${QMGR}_${LOG_FILE_NAME}

    DEFINE_COMPLETION_CODE=`echo $output3 | jq '.overallReasonCode'`
    MQRC_REASON_CODE=`echo $output3 | jq '.commandResponse[0].reasonCode'`
    # printf "DEFINE_COMPLETION_CODE: $DEFINE_COMPLETION_CODE \n" >> $LOG_DIR/autoDlq.log

    if [[ $DEFINE_COMPLETION_CODE != 0 ]]
    then
      if [[ $MQRC_REASON_CODE != 4001 && $MQRC_REASON_CODE != 3337 && $MQRC_REASON_CODE != 3249 ]]
      then
        echo "ERROR: RUNMQSC COMMAND: $ACTION DID NOT SUCCEED" >> $LOG_DIR/$LOG_FILE_NAME
        echo $output3 >> $LOG_DIR/$LOG_FILE_NAME
      fi
    fi

    #Getting the RUNMQSC response back to the control via variables set
    output2=`echo $output3 | jq '.commandResponse[].text'`
    #Adds the output from running RUNMQSC to a variable that can be used later
    OUTPUT=`echo "$output2" | sed -n 's/  */ /gp' | tr -d \"`
  }

  #Fn that creates a directory in the appliance via REST API
  function createDir {
    #Curl command that creates the dir; requires certain variables to be set before running the fn

    DIR_TO_USE=`echo "$FILE_PATH" | cut -d'/' -f 1`
    FOLDER_TO_USE=`echo "$FILE_PATH" | cut -d'/' -f 2`

    output3=$(curl --silent -s -k https://$HOSTNAME:$REST_PORT/mgmt/filestore/default/$DIR_TO_USE -X POST -u $MQ_REST_USER:$MQ_REST_PASSWORD -H "ibm-mq-rest-csrf-token: value" -H "Content-Type: application/json" --data "{\"directory\":{\"name\":\"$FOLDER_TO_USE\"}}" )

    #Error Handling: Ensuring the REST Call was made successfully
    #if [[ `echo $output3 | jq '.result'` != "\"Directory was created.\"" ]]
    #then
      #mkdir -p $ERROR_DIR
      #echo "ERROR: createDir FAILED"
      #echo "REST response written logged to $ERROR_DIR/createDir_ERROR.json"
      #echo $output3 > $ERROR_DIR/createDir_ERROR.json
    #else
      #echo "$FILE_PATH in $HOSTNAME created successfully"
    #fi
  }

  #Fn that gets contents of a directory in the appliance via REST API
  function listDirContents {
    #Curl command that creates the dir; requires certain variables to be set before running the fn
    output3=$(curl --silent -s -k https://$HOSTNAME:$REST_PORT/mgmt/filestore/default/$GET_CONTENTS_DIR -X GET -u $MQ_REST_USER:$MQ_REST_PASSWORD)


    OUTPUT_FILE_NAME="OUTPUT_ListDir_Log"

    #Error Handling: If the qmgr names returned is empty, something has gone wrong!
    if [[ `echo $output3 | jq '.filestore.location.file[] | .name' | tr -d \" ` == "" ]]
    then
      mkdir -p $ERROR_DIR
      echo "ERROR: GET Dir Contents Command FAILED"
      echo "REST response written logged to $ERROR_DIR/$OUTPUT_FILE_NAME.json"
      echo "$output3" > $ERROR_DIR/$OUTPUT_FILE_NAME.json
    else
      output2=`echo $echo $output3 | jq '.filestore.location.file[] | .name' | tr -d \"`
    fi
  }


  #Fn that deletes a dir
  function deleteDir {
    #Curl command that deletes a given dir; requires certain variables to be set
    output3=$(curl --silent -s -k https://$HOSTNAME:$REST_PORT/mgmt/filestore/default/$FILE_PATH -X DELETE -u $MQ_REST_USER:$MQ_REST_PASSWORD -H "ibm-mq-rest-csrf-token: value")

    #Error Handling: Ensuring the REST Call was made successfully
    #if [[ `echo $output3 | jq '.result'` == "\"Directory was deleted.\"" ]]
    #then
      #echo "$FILE_PATH in $HOSTNAME deleted successfully"
    #else
      #mkdir -p $ERROR_DIR
      #echo "ERROR: deleteDir FAILED"
      #echo "REST response written logged to $ERROR_DIR/deleteDir_ERROR.json"
    #   echo $output3 > $ERROR_DIR/deleteDir_ERROR.json
    #fi

  }

  #Fn that creates a file in the appliance via REST API
  function putFile {
    #Converting the file content to be in base64 format
    fileContentBase64=`echo -en "$fileContent1" | base64`

    #Curl command that creates a file in the appliance; requires certain variables to be set.
    output3=$(curl --silent -s -k https://$HOSTNAME:$REST_PORT/mgmt/filestore/default/$FILE_PATH/$FILE_NAME -X PUT -u $MQ_REST_USER:$MQ_REST_PASSWORD -H "ibm-mq-rest-csrf-token: value" -H "Content-Type: application/json" --data "{
      \"file\": {
        \"name\":\"$FILE_NAME\",
        \"content\":\"$fileContentBase64\"
      }
    }")

    OUTPUT_FILE_NAME="OUTPUT_PutFile_$FILE_NAME"
  

    #Error Handling: Ensuring the REST Call was made successfully
    # if [[ `echo $output3 | jq '.result'` == "\"File was created.\"" ]]
    # then
    #   echo "$FILE_PATH/$FILE_NAME in $HOSTNAME created successfully"
    #   echo $output3 > $LOG_DIR/$OUTPUT_FILE_NAME
    # else
    #   mkdir -p $ERROR_DIR
    #   echo "ERROR: putFile FAILED for "$controlName" with "$qmgr
    #   echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
    #   echo $output3 > $ERROR_DIR/$ERROR_FILE_NAME
    # fi
  }

  #Fn that executes all the files in $FILE_PATH/$FILE_NAME
  function execFile {

    DIR_TO_USE=`echo "$FILE_PATH" | cut -d'/' -f 1`
    FOLDER_TO_USE=`echo "$FILE_PATH" | cut -d'/' -f 2`

    #Since it's executed as #ExecConfig, we don't need to change mode to 'config;'
    output3=$(curl --silent -s -k https://$HOSTNAME:$REST_PORT/mgmt/actionqueue/default -X POST -u $MQ_REST_USER:$MQ_REST_PASSWORD --data "{
      \"ExecConfig\" : {
        \"URL\" : \"$DIR_TO_USE://$FOLDER_TO_USE/$FILE_NAME\"
      }
    }")

    OUTPUT_FILE_NAME="OUTPUT_Execute_$FILE_NAME"
    ERROR_FILE_NAME="ERROR_Execute_$FILE_NAME"
    #Error Handling: Ensuring the REST Call was made successfully
    if [[ `echo $output3 | jq '.ExecConfig'` != "\"Operation completed.\"" ]]
    then
      mkdir -p $ERROR_DIR
      echo "ERROR: execFile FAILED for" $controlName" with "$qmgr
      echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
      echo $output3 >> $ERROR_DIR/$ERROR_FILE_NAME
    fi
  }

  #Fn that allows to copy file from the appliance
  function copyOutOfMQA {
    FILE_PATH="temporary/execDir"
    FILE_NAME="copyOutOfMQA"

    deleteDir
    createDir
    fileContent1="copy $COPY_FROM_DIR://$COPY_FILE scp://$LINUX_SERVER_USER:$LINUX_SERVER_PWD@$LINUX_SERVER_IP//$LINUX_SERVER_DIR"
    putFile

    execFile
  }

  #Fn that allows to copy file from remote location to appliance
  function copyToMQA {
    FILE_PATH="temporary/execDir"
    FILE_NAME="copyToMQA"

    deleteDir
    createDir
    fileContent1="copy scp://$LINUX_SERVER_USER:$LINUX_SERVER_PWD@$REMOTE_BOX_IP//$LINUX_SERVER_DIR/$BACKUP_FILE $COPY_TO_DIR://$COPIED_FILE"
    putFile

    execFile
  }

  #Fn that shows any given config file in the appliance
  function getFile {
    output3=$(curl --silent -s -k https://$HOSTNAME:$REST_PORT/mgmt/filestore/default/$FILE_PATH/$FILE_NAME -X GET -u $MQ_REST_USER:$MQ_REST_PASSWORD)

    #Error Handling: Ensuring the REST Call was made successfully
    if [[ `echo $output3 | jq '.file'` == "" ]]
    then
      mkdir -p $ERROR_DIR
      echo "ERROR: getConfigFile FAILED for "$controlName
      echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
      echo $output3 >> $ERROR_DIR/$ERROR_FILE_NAME
    fi

    #Decoding the file content from binary to readable text
    OUTPUT=`echo $output3 | jq '.file' | tr -d \" | base64 --decode`
  }

  function deleteFile {
    output3=$(curl --silent -s -k https://$HOSTNAME:$REST_PORT/mgmt/filestore/default/$FILE_PATH_TO_DELETE/$FILE_NAME_TO_DELETE -X DELETE -u $MQ_REST_USER:$MQ_REST_PASSWORD)
    #Error Handling: Ensuring the REST Call was made successfully
    #if [[ `echo $output3 | jq '.result'` == null ]]
    #then
      #mkdir -p errors
      #ERROR_FILE_NAME="ERROR_deleteFile_$FILE_NAME_TO_DELETE.json"
      #echo "ERROR: FAILED to delete "$FILE_NAME_TO_DELETE
      #echo "REST response written logged to "$ERROR_DIR/$ERROR_FILE_NAME
      # echo $output3 > errors/$ERROR_FILE_NAME
    #fi
  }

  #Fn that deletes a files
  function deleteListedFilesWithPattern {

    for file in $output2
    do
      if [[ $file == $PATTERN ]] ;
      then
          FILE_PATH_TO_DELETE=$GET_CONTENTS_DIR
          FILE_NAME_TO_DELETE=$file

          deleteFile
      fi
    done
  }


  #Fn that shows any given config file in the appliance
  function getConfigFile {
    output3=$(curl --silent -s -k https://$HOSTNAME:$REST_PORT/mgmt/filestore/default/$CONFIG_FILE_PATH/$CONFIG_FILE -X GET -u $MQ_REST_USER:$MQ_REST_PASSWORD)

    #Error Handling: Ensuring the REST Call was made successfully
    if [[ `echo $output3 | jq '.file'` != "" ]]
    then
      echo "$CONFIG_FILE_PATH/$CONFIG_FILE in $HOSTNAME retrieved successfully"
    else
      mkdir -p $ERROR_DIR
      echo "ERROR: getConfigFile FAILED for "$controlName
      echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
      # echo $output3 > $ERROR_DIR/$ERROR_FILE_NAME
    fi

    #Decoding the file content from binary to readable text
    OUTPUT=`echo $output3 | jq '.file' | tr -d \" | base64 --decode`
  }


  #Fn that returns MQ Appliance CPU Usage
  function getCPUUsage {
    #Curl command to get CPU Usage;
    output3=$(curl --silent -s -u $MQ_REST_USER:$MQ_REST_PASSWORD -k https://$HOSTNAME:$REST_PORT/mgmt/status/default/SystemCpuStatus -X GET)

    avgLoad1m=`echo $output3 | jq '.SystemCpuStatus.CpuLoadAvg1' | tr -d \" `
    avgLoad5m=`echo $output3 | jq '.SystemCpuStatus.CpuLoadAvg5' | tr -d \" `
    avgLoad15m=`echo $output3 | jq '.SystemCpuStatus.CpuLoadAvg15' | tr -d \" `

    OUTPUT_FILE_NAME='getCPUUsage'

    #Error Handling: Ensuring the REST Call was made successfully
    if [[ avgLoad1m != "" ]]
    then
      echo 'Average CPU Load in the last 1 min:' $avgLoad1m
      echo 'Average CPU Load in the last 5 min:' $avgLoad5m
      echo 'Average CPU Load in the last 15 min:' $avgLoad15m
      # echo $output3 > $LOG_DIR/$OUTPUT_FILE_NAME
    else
      mkdir -p $ERROR_DIR
      echo "ERROR: getCPUUsage FAILED for "$controlName
      echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
      # echo $output3 > $ERROR_DIR/$ERROR_FILE_NAME
    fi
  }

  #Fn that returns MQ Appliance Memory Usage
  function getMemoryUsage {
    #Curl command to get CPU Usage;
    output3=$(curl --silent -s -u $MQ_REST_USER:$MQ_REST_PASSWORD -k https://$HOSTNAME:$REST_PORT/mgmt/status/default/SystemMemoryStatus -X GET)

    totalMemory=`echo $output3 | jq '.SystemMemoryStatus.TotalMemory' | tr -d \" `
    usedMemory=`echo $output3 | jq '.SystemMemoryStatus.UsedMemory' | tr -d \" `
    freeMemory=`echo $output3 | jq '.SystemMemoryStatus.FreeMemory' | tr -d \" `

    OUTPUT_FILE_NAME='getCPUUsage'

    #Error Handling: Ensuring the REST Call was made successfully
    if [[ avgLoad1m != "" ]]
    then
      echo 'Total Memory:' $totalMemory
      echo 'Used Memory:' $usedMemory
      echo 'Free Memory:' $freeMemory
      # echo $output3 > $LOG_DIR/$OUTPUT_FILE_NAME
    else
      mkdir -p $ERROR_DIR
      echo "ERROR: getCPUUsage FAILED for "$controlName
      echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
      # echo $output3 > $ERROR_DIR/$ERROR_FILE_NAME
    fi
  }


  #Fn that returns MQ Appliance Memory Usage
  function getSystemUptimeReload {
    #Curl command to get CPU Usage;
    output3=$(curl --silent -s -u $MQ_REST_USER:$MQ_REST_PASSWORD -k https://$HOSTNAME:$REST_PORT/mgmt/status/default/DateTimeStatus -X GET)
    upTime=`echo $output3 | jq '.DateTimeStatus.uptime2' | tr -d \" `
    echo "Uptime is $upTime"
  }


  #Fn that returns the IPPROCS of a given $queuename
  function returnIPPROCS {

  	output3=$(curl --silent -k https://$HOSTNAME:$REST_PORT/ibmmq/rest/v1/admin/action/qmgr/$QMGR/mqsc -X POST -u $MQ_REST_USER:$MQ_REST_PASSWORD -H "ibm-mq-rest-csrf-token: value" -H "Content-Type: application/json" --data "{\"type\": \"runCommandJSON\", \"command\": \"display\", \"qualifier\": \"qlocal\", \"name\": \"$queuename\", \"responseParameters\" : [\"IPPROCS\"]}")

    queueIPPROCSvalue=`echo $output3 | jq '.commandResponse[].parameters | .ipprocs' | tr -d \"`

  }

  #This function generates and gets  the ccdt file from an MQAppliance for the given Queue Manager '$QMGR'
  function getCcdtFile(){

      #Deleting any existing ccdt file with the name '${QMGR}_AMQCLCHL.TAB'
      FILE_PATH_TO_DELETE=mqbackup
      FILE_NAME_TO_DELETE=$CCDT_FILE_NAME
      deleteFile

      OUTPUT_FILE_NAME=${QMGR}_GETCCDT_LOGS.json
      #CREATE TEMPORARY DIR --> PUT FILE --> EXECUTE ON THE APPLIANCE --> GET_CCDT

      #creating a folder for executing copy commands
      FILE_PATH="temporary/execDir"
      deleteDir
      createDir

      #'rcrmqobj' creates the CCDT file (the client channel should have been created already at this point)
      FILE_NAME="getCcdt"
      fileContent1=`echo -en "mqcli\nrcrmqobj -z -m $QMGR -t clchltab"`
      putFile

      #Execute the file to create ccdt
      execFile

      #The file is copied out to 'OUTPUT' variable
      FILE_PATH=temporary
      controlName=$HOSTNAME
      ERROR_FILE_NAME=$QMGR"_GETFILE.json"
      getFile

      #deletes the old ccdt file
      rm -f $CCDT_DIR/$CCDT_FILE_NAME
      #Writes to a file
      echo $OUTPUT > $CCDT_DIR/$CCDT_FILE_NAME

      FILE_PATH="temporary/execDir"
      deleteDir
  }


  function createJSONccdt(){
    json_data=$(cat <<EOF
{
	"channel": [
      {
        "name": "$DLQCHANNEL",
        "clientConnection": {
          "connection": [
            {
              "host": "$HOSTNAME",
              "port": $DLQHANDLER_PORT
            }
          ],
          "queueManager": "$QMGR"
        },
        "type": "clientConnection"
      }
    ]
}
EOF
)
    echo $json_data > $CCDT_DIR/$CCDT_FILE_NAME
  }

  function createJSONSSLccdt(){
    json_data=$(cat <<EOF
{
	"channel": [
      {
        "name": "$DLQCHANNEL",
        "clientConnection": {
          "connection": [
            {
              "host": "$HOSTNAME",
              "port": $DLQHANDLER_PORT
            }
          ],
          "queueManager": "$QMGR"
        },
        "transmissionSecurity":
        {
          "cipherSpecification": "TLS_RSA_WITH_AES_256_CBC_SHA256",
          "certificateLabel": "ibmwebspheremqrestdlq"
        },
        "type": "clientConnection"
      }
    ]
}
EOF
)
    echo $json_data > $CCDT_DIR/$CCDT_FILE_NAME
  }