#!/bin/ksh
#############################################################
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
## File Name: backupQueueManagers.sh                                          ##
##                                                                            ##
##    An example script that uses the restHelperLibrary.sh as an example      ##
##  In this script, at first all the running queue managers are listed.       ##
##  Then for each queue manager required information is retrieved via MQRSC   ##
##  calls and queue manager dump. Then the script retrieves config data from  ##
##  the appliance.                                                            ##
##                                                                            ##
################################################################################

###################  THE FOLLOWING VARIABLES MUST BE CHANGED TO SUIT YOUR APPLIANCE!

APPLIANCE_IP=9.20.49.89
REST_PORT=5554

#Linux server access details to which files are to be moved
linuxServer=9.20.196.113
linuxUser=root
linuxQmgrsBackupDir=/root/aib/qmgrBackups

#Directories to which logs and errors are written to:
LOG_DIR=logs
ERROR_DIR=errors

###################  END OF USER DEFINED VARIABLES

#Removing logs and error dir
rm -rf $LOG_DIR
rm -rf $ERROR_DIR

#Creating logs dir
mkdir -p $LOG_DIR

source ./helper.sh

#============================================================

#Fn copies ouot all QMGR backup files
function getAllQmgrBackupFiles {

  getQueueManagerNames
  qmgrs=( $qmgrNames )

  # For loop for all queue managers
  for qmgr in "${qmgrs[@]}"
  do
    fileContent1="mqcli\nmqbackup -m $qmgr -o $qmgr.bak"
    FILE_NAME=$qmgr"_backup.config"

    #Deleting old log files
    FILE_PATH_TO_DELETE=mqbackup/QMgrs
    FILE_NAME_TO_DELETE=$qmgr.bak
    deleteFile

    OUTPUT_FILE_NAME=$qmgr"_copyBackup_putFile_OUTPUT.json"
    ERROR_FILE_NAME=$qmgr"_copyBackup_putFile_ERROR.json"
    putFile
    OUTPUT_FILE_NAME=$qmgr"_copyBackup_execFile_OUTPUT.json"
    ERROR_FILE_NAME=$qmgr"_copyBackup_execFile_ERROR.json"
    execFile

    fileContent1="copy mqbackup:///QMgrs/$qmgr.bak scp://$linuxUser:$linuxPassword@$linuxServer/$linuxQmgrsBackupDir"
    FILE_NAME=$qmgr"_copyBackup.config"
    ERROR_FILE_NAME=$qmgr"_copyBackup_putFile_ERROR.json"
    putFile
    #Executing the config file that was added
    ERROR_FILE_NAME=$qmgr"_copyBackup_execFile_ERROR.json"
    execFile
  done

}

#============================================================
echo "Enter the username for $APPLIANCE_IP:"
read USERNAME
echo "Enter the password for $APPLIANCE_IP:"
stty -echo
read PASSWORD
stty echo

#Appliance file path and directory to which exec config files will be added to
FILE_PATH=temporary/aj

# Recreating the directory in the appliance to ensure it's clean
deleteDir
createDir

echo "Enter password for $linuxUser in $linuxServer"
stty -echo
read linuxPassword
stty echo

controlName=getAllQmgrBackupFiles
getAllQmgrBackupFiles

echo "----------------------------"
echo "Back up procedure complete"
echo "============================"
