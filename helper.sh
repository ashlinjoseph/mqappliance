#!/bin/ksh
################################################################################
#
# Copyright 2018 IBM Corporation and other contributors
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
## File Name: restHelperLibrary.sh                                            ##
##                                                                            ##
##    This helper library is built around some of the MQ Appliance REST API   ##
##  to help MQ appliance users to easily built scripts that can be used to    ##
##  perform tasks in the appliance.                                           ##
##                                                                            ##
##  To use the helper library you need to import the helper library:          ##
##          source ./restHelperLibrary.#!/bin/sh                              ##
##                                                                            ##
##  This script is built using Curl and jq.                                   ##
##    Curl: https://curl.haxx.se/docs/manpage.html                            ##
##    jq: https://stedolan.github.io/jq/                                      ##
##                                                                            ##
################################################################################

# Fn returns the list of running qmgrs in a given appliance via the REST API
function getQueueManagerNames {

  #Curl command to get all qmgr names and status;
  output3=$(curl -s -u $USERNAME:$PASSWORD -k https://$APPLIANCE_IP:$REST_PORT/ibmmq/rest/v1/admin/qmgr -X GET)
  echo $output3 | jq '.qmgr[] | select(.state == "running") | .name' | tr -d \"  > logs/QueueManagers.json
  #Gets the names of the queue manager that are in "running" state
  qmgrNames=`echo $output3 | jq '.qmgr[] | select(.state == "running") | .name' | tr -d \" `

  OUTPUT_FILE_NAME='getQueueManagerNames.json'

  #Error Handling: If the qmgr names returned is empty, something has gone wrong!
  if [[ `echo $qmgrNames` != "" ]]
  then
    echo "Queue managers running in $APPLIANCE_IP are: "
    echo $qmgrNames
    echo $output3 > $LOG_DIR/$OUTPUT_FILE_NAME
  else
    mkdir -p $ERROR_DIR
    echo "ERROR: GET Queue Manager Names Command FAILED"
    echo "REST response written logged to $ERROR_DIR/GetQmgrsERROR.json"
    echo "$output3" > $ERROR_DIR/getQueueManagerNames.json
  fi
}

#Fn that runs a given RUNMQSC command via the REST API
function runmqscRest {
  #Curl command that runs RUNMQSC command and receive the response
  output3=$(curl -s -k https://$APPLIANCE_IP:$REST_PORT/ibmmq/rest/v1/admin/action/qmgr/$qmgr/mqsc -X POST -b $TOKEN_FILE -H "ibm-mq-rest-csrf-token: value" -H "Content-Type: application/json" --data "{\"type\":\"runCommand\",\"parameters\":{\"command\":\"$REST_MQSC\"}}" )
  #Error Handling: Ensuring the REST Call was made successfully
  if [[ `echo $output3 | jq '.overallCompletionCode'` == 0 ]]
  then
    echo "$REST_MQSC executed for $qmgr successfully"
    echo $output3 > $LOG_DIR/$OUTPUT_FILE_NAME
  else
    mkdir -p $ERROR_DIR
    echo "ERROR: RUNMQSC COMMAND FAILED"
    echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
    echo $output3 > $ERROR_DIR/$ERROR_FILE_NAME
  fi

  #Getting the RUNMQSC response back to the control via variables set
  output2=`echo $output3 | jq '.commandResponse[].text'`
  #Adds the output from running RUNMQSC to a variable that can be used later
  OUTPUT=`echo "$output2" | sed -n 's/  */ /gp' | tr -d \"`

}

#Fn that creates a directory in the appliance via REST API
function createDir {
  #Curl command that creates the dir; requires certain variables to be set before running the fn
  output3=$(curl -s -k https://$APPLIANCE_IP:$REST_PORT/mgmt/filestore/default/$DIR_TO_USE -X POST -u $USERNAME:$PASSWORD -H "ibm-mq-rest-csrf-token: value" -H "Content-Type: application/json" --data "{\"directory\":{\"name\":\"$FOLDER_TO_USE\"}}" )

  #Error Handling: Ensuring the REST Call was made successfully
  if [[ `echo $output3 | jq '.result'` == "\"Directory was created.\"" ]]
  then
    echo "$DIR_TO_USE/$FOLDER_TO_USE in $APPLIANCE_IP created successfully"
  else
    mkdir -p $ERROR_DIR
    echo "ERROR: createDir FAILED"
    echo "REST response written logged to $ERROR_DIR/createDir_ERROR.json"
    echo $output3 > $ERROR_DIR/createDir_ERROR.json
  fi
}

#Fn that gets contents of a directory in the appliance via REST API
function listDirContents {
  #Curl command that creates the dir; requires certain variables to be set before running the fn
  output3=$(curl -s -k https://$APPLIANCE_IP:$REST_PORT/mgmt/filestore/default/$GET_CONTENTS_DIR/$GET_CONTENTS_FOLDER -X GET -u $USERNAME:$PASSWORD)

  #Error Handling: If the qmgr names returned is empty, something has gone wrong!
  if [[ `echo $output3 | jq '.filestore.location.file[] | .name' | tr -d \" ` != "" ]]
  then
    output2=`echo $output3 | jq '.filestore.location.file[] | .name' | tr -d \" `
    files=( $output2 )
    echo $output3 > $LOG_DIR/$OUTPUT_FILE_NAME
  else
    mkdir -p $ERROR_DIR
    echo "ERROR: GET Dir Contents Command FAILED"
    echo "REST response written logged to $ERROR_DIR/listDirContentsERROR.json"
    echo "$output3" > $ERROR_DIR/getDirContent.json
  fi
}

#Fn that deletes a dir
function deleteDir {
  #Curl command that deletes a given dir; requires certain variables to be set
  output3=$(curl -s -k https://$APPLIANCE_IP:$REST_PORT/mgmt/filestore/default/$DIR_TO_USE/$FOLDER_TO_USE -X DELETE -u $USERNAME:$PASSWORD -H "ibm-mq-rest-csrf-token: value")

  #Error Handling: Ensuring the REST Call was made successfully
  if [[ `echo $output3 | jq '.result'` == "\"Directory was deleted.\"" ]]
  then
    echo "$DIR_TO_USE/$FOLDER_TO_USE in $APPLIANCE_IP deleted successfully"
  else
    mkdir -p $ERROR_DIR
    echo "ERROR: deleteDir FAILED"
    echo "REST response written logged to $ERROR_DIR/deleteDir_ERROR.json"
    echo $output3 > $ERROR_DIR/deleteDir_ERROR.json
  fi

}

#Fn that creates a file in the appliance via REST API
function putFile {
  #Converting the file content to be in base64 format
  fileContentBase64=`print $fileContent1|base64`

  #Curl command that creates a file in the appliance; requires certain variables to be set.
  output3=$(curl -s -k https://$APPLIANCE_IP:$REST_PORT/mgmt/filestore/default/$DIR_TO_USE/$FOLDER_TO_USE/$FILE_NAME -X PUT -u $USERNAME:$PASSWORD -H "ibm-mq-rest-csrf-token: value" -H "Content-Type: application/json" --data "{
    \"file\": {
      \"name\":\"$FILE_NAME\",
      \"content\":\"$fileContentBase64\"
    }
  }")

  #Error Handling: Ensuring the REST Call was made successfully
  if [[ `echo $output3 | jq '.result'` == "\"File was created.\"" ]]
  then
    echo "$DIR_TO_USE/$FOLDER_TO_USE/$FILE_NAME in $APPLIANCE_IP created successfully"
    echo $output3 > $LOG_DIR/$OUTPUT_FILE_NAME
  else
    mkdir -p $ERROR_DIR
    echo "ERROR: putFile FAILED for "$controlName" with "$qmgr
    echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
    echo $output3 > $ERROR_DIR/$ERROR_FILE_NAME
  fi
}

#Fn that executes all the files in $DIR_TO_USE/$FOLDER_TO_USE/$FILE_NAME
function execFile {
  output3=$(curl -s -k https://$APPLIANCE_IP:$REST_PORT/mgmt/actionqueue/default -X POST -u $USERNAME:$PASSWORD --data "{
    \"ExecConfig\" : {
      \"URL\" : \"$DIR_TO_USE://$FOLDER_TO_USE/$FILE_NAME\"
    }
  }")

  #Error Handling: Ensuring the REST Call was made successfully
  if [[ `echo $output3 | jq '.ExecConfig'` == "\"Operation completed.\"" ]]
  then
    echo "$DIR_TO_USE/$FOLDER_TO_USE/$FILE_NAME in $APPLIANCE_IP executed successfully"
    echo $output3 > $LOG_DIR/$OUTPUT_FILE_NAME
  else
    mkdir -p $ERROR_DIR
    echo "ERROR: execFile FAILED for" $controlName" with "$qmgr
    echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
    echo $output3 > $ERROR_DIR/$ERROR_FILE_NAME
  fi
}

#Fn that shows any given config file in the appliance
function getFile {
  output3=$(curl -s -k https://$APPLIANCE_IP:$REST_PORT/mgmt/filestore/default/$DIR_TO_USE/$FOLDER_TO_USE/$FILENAME -X GET -u $USERNAME:$PASSWORD)

  #Error Handling: Ensuring the REST Call was made successfully
  if [[ `echo $output3 | jq '.file'` != "" ]]
  then
    echo "$DIR_TO_USE/$FOLDER_TO_USE/$FILENAME in $APPLIANCE_IP retrieved successfully"
  else
    mkdir -p $ERROR_DIR
    echo "ERROR: getConfigFile FAILED for "$controlName
    echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
    echo $output3 > $ERROR_DIR/$ERROR_FILE_NAME
  fi

  #Decoding the file content from binary to readable text
  OUTPUT=`echo $output3 | jq '.file' | tr -d \" | base64 --decode`
}

#Fn that shows any given config file in the appliance
function getConfigFile {
  output3=$(curl -s -k https://$APPLIANCE_IP:$REST_PORT/mgmt/filestore/default/$CONFIG_FILE_PATH/$CONFIG_FILE -X GET -u $USERNAME:$PASSWORD)

  #Error Handling: Ensuring the REST Call was made successfully
  if [[ `echo $output3 | jq '.file'` != "" ]]
  then
    echo "$CONFIG_FILE_PATH/$CONFIG_FILE in $APPLIANCE_IP retrieved successfully"
  else
    mkdir -p $ERROR_DIR
    echo "ERROR: getConfigFile FAILED for "$controlName
    echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
    echo $output3 > $ERROR_DIR/$ERROR_FILE_NAME
  fi

  #Decoding the file content from binary to readable text
  OUTPUT=`echo $output3 | jq '.file' | tr -d \" | base64 --decode`
}

#Fn that returns MQ Appliance CPU Usage
function getCPUUsage {
  #Curl command to get CPU Usage;
  output3=$(curl -s -u $USERNAME:$PASSWORD -k https://$APPLIANCE_IP:$REST_PORT/mgmt/status/default/SystemCpuStatus -X GET)

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
    echo $output3 > $LOG_DIR/$OUTPUT_FILE_NAME
  else
    mkdir -p $ERROR_DIR
    echo "ERROR: getCPUUsage FAILED for "$controlName
    echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
    echo $output3 > $ERROR_DIR/$ERROR_FILE_NAME
  fi
}

#Fn that returns MQ Appliance Memory Usage
function getMemoryUsage {
  #Curl command to get CPU Usage;
  output3=$(curl -s -u $USERNAME:$PASSWORD -k https://$APPLIANCE_IP:$REST_PORT/mgmt/status/default/SystemMemoryStatus -X GET)

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
    echo $output3 > $LOG_DIR/$OUTPUT_FILE_NAME
  else
    mkdir -p $ERROR_DIR
    echo "ERROR: getCPUUsage FAILED for "$controlName
    echo REST response written logged to $ERROR_DIR/$ERROR_FILE_NAME
    echo $output3 > $ERROR_DIR/$ERROR_FILE_NAME
  fi
}


#Fn that returns MQ Appliance Memory Usage
function getSystemUptimeReload {
  #Curl command to get CPU Usage;
  output3=$(curl -s -u $USERNAME:$PASSWORD -k https://$APPLIANCE_IP:$REST_PORT/mgmt/status/default/DateTimeStatus -X GET)
  upTime=`echo $output3 | jq '.DateTimeStatus.uptime2' | tr -d \" `
  echo "Uptime is $upTime"
}
