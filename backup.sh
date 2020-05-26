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
## File Name: sampleREST01.sh                                                 ##
##                                                                            ##
##    An example script that uses the restHelperLibrary.sh as an example      ##
##  In this script, at first all the running queue managers are listed.       ##
##  Then for each queue manager required information is retrieved via MQRSC   ##
##  calls and queue manager dump. Then the script retrieves config data from  ##
##  the appliance.                                                            ##
##                                                                            ##
################################################################################

##  THE FOLLOWING VARIABLES MUST BE CHANGED TO SUIT YOUR APPLIANCE!

APPLIANCE_IP=9.20.49.89
TOKEN_FILE=/tmp/token.cookie
REST_PORT=5554

#Appliance file path and directory to which exec files will be added to
DIR_TO_USE=temporary
FOLDER_TO_USE=aj

#Linux server access details to which files are to be moved
linuxServer=9.20.196.113
linuxUser=root
linuxPassword=
linuxDir=aib/qmgrBackups

#Directory to which logs are written to
LOG_DIR=logs
#Directory to which errors are written to, if any
ERROR_DIR=errors

#Removing logs dir
rm -rf $LOG_DIR

#Removing errors dir
rm -rf $ERROR_DIR

#Creating logs dir
mkdir -p $LOG_DIR

source ./helper.sh

#===============================================================================

# Getting MQ config dump file; $qmgr= Queue Manager name
function getQmgrDump {
  echo "Get qmgr dump for $qmgr"
  controlName='getQmgrDump'

  #Setting the file content
  fileContent1="mqcli\ndmpmqcfg -m $qmgr -a -o 1line"

  #Setting the file postfix; in the putfile $qmgr name will be added to the filename
  FILE_POSTFIX=_Exec.config
  FILE_NAME="$qmgr$FILE_POSTFIX"
  ERROR_FILE_NAME=$controlName"_"$qmgr"_putFile_ERROR.json"
  OUTPUT_FILE_NAME=$controlName"_"$qmgr"_putFile_OUTPUT.json"
  putFile

  #Executing the config file that was added
  ERROR_FILE_NAME=$controlName"_"$qmgr"_execFile_ERROR.json"
  OUTPUT_FILE_NAME=$controlName"_"$qmgr"_putFile_OUTPUT.json"
  execFile

  ERROR_FILE_NAME=$controlName"_getConfigFile_ERROR.json"

  echo "$OUTPUT" > $LOG_DIR/$controlName$qmgr.out
}

#Fn copies ouot all QMGR backup files
function getAllQmgrBackupFiles {

  output3=$(curl -s -k https://$APPLIANCE_IP:$REST_PORT/mgmt/filestore/default/$DIR_TO_USE/$DIR_TO_USE/$FILENAME -X GET -u $USERNAME:$PASSWORD)

  echo "Enter the password for $linuxUser for $linuxServer:"
  read linuxPassword


}

# Getting all user config from the appliance
function getMQApplianceUserConfig {
  echo "Get MQ Appliance User Config"
  controlName='getMQApplianceUserConfig'

  #Setting path and filename to the auto-user.cfg in the appliance
  CONFIG_FILE_PATH=config
  CONFIG_FILE=auto-user.cfg
  ERROR_FILE_NAME=$controlName"_getConfigFile_ERROR.json"
  getConfigFile
  echo "$OUTPUT" > $LOG_DIR/$controlName.out

}

#Control #9: Getting the aplpiance config file
function getMQApplianceConfig {
  echo "Get MQ Appliance Config"
  controlName='getMQApplianceConfig'

  #Setting path and filename to the autoconfig.cfg in the appliance
  CONFIG_FILE_PATH=config
  CONFIG_FILE=autoconfig.cfg
  ERROR_FILE_NAME=$controlName"_getConfigFile_ERROR.json"
  getConfigFile
  echo "$OUTPUT" > $LOG_DIR/$controlName.out
}

#===============================================================================
echo "Enter the username for $APPLIANCE_IP:"
read USERNAME
echo "Enter the password for $APPLIANCE_IP:"
stty -echo
read PASSWORD
stty echo

# Log in to the MQ REST API to create the token required for MQ object update (POST or DELETE) calls
curl -s -k https://$APPLIANCE_IP:$REST_PORT/ibmmq/rest/v1/login -X POST --data "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" -c $TOKEN_FILE

# Recreating the directory in the appliance to ensure it's clean
deleteDir
createDir

echo "Enter password for $linuxUser in $linuxServer"
stty -echo
read linuxPassword
stty echo

controlName=getQmgrBackups

getQueueManagerNames
qmgrs=( $qmgrNames )

# For loop for all queue managers
for qmgr in "${qmgrs[@]}"
do
  fileContent1="mqcli\nmqbackup -m $qmgr -o $qmgr.bak"
  FILE_NAME=$qmgr"_backup.config"
  OUTPUT_FILE_NAME=$qmgr"_copyBackup_putFile_OUTPUT.json"
  ERROR_FILE_NAME=$qmgr"_copyBackup_putFile_ERROR.json"
  putFile
  OUTPUT_FILE_NAME=$qmgr"_copyBackup_execFile_OUTPUT.json"
  ERROR_FILE_NAME=$qmgr"_copyBackup_execFile_ERROR.json"
  execFile

  fileContent1="copy mqbackup:///QMgrs/$qmgr.bak scp://$linuxUser:$linuxPassword@$linuxServer//$linuxUser/$linuxDir"
  FILE_NAME=$qmgr"_copyBackup.config"
  ERROR_FILE_NAME=$qmgr"_copyBackup_putFile_ERROR.json"
  putFile
  #Executing the config file that was added
  ERROR_FILE_NAME=$qmgr"_copyBackup_execFile_ERROR.json"
  execFile
done


#getAllQmgrBackupFiles

echo "Logging out from the appliance and deleting the security token file. "
curl -k https://$APPLIANCE_IP:$REST_PORT/ibmmq/rest/v1/login -X DELETE -H "ibm-mq-rest-csrf-token: value" -b $TOKEN_FILE -c $TOKEN_FILE
rm -rf $TOKEN_FILE
