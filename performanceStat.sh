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
echo "Enter the username:"
read USERNAME
echo "Enter the password:"
stty -echo
read PASSWORD
stty echo

ERROR_FILE_NAME=getCPUUsage_ERROR.json

echo '--------'
echo "CPU USAGE"
echo '--------'
getCPUUsage
echo '--------'
echo "Memory USAGE"
echo '--------'
getMemoryUsage
echo '--------'
echo "Memory USAGE"
echo '--------'
getSystemUptimeReload
echo '--------'
