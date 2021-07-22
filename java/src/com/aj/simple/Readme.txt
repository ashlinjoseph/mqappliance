To run SimpleReceiver add the following properties in the JVM:
-Dhostname=<hostIP>
-Dport=<port>
-Dchannel=<channelname>
-Dqmgr=<qmgr name>
-DreceiverQ=<queue>
-Duser=<username>
-Dpwd=<password>
-Dnumsgs=<number of messages to receive>
-DlogFile=<log path for eg: C:\Users\aj\logs\SimpleSender.log>

If running in Eclipse, pass them on 'VM' arguments. 


To run SimpleSender add the following properties in the JVM:
-Dhostname=<hostIP>
-Dport=<port>
-Dchannel=<channelname>
-Dqmgr=<qmgr name>
-DsenderQ=<queue>
-Duser=<username>
-Dpwd=<password>
-Dnumsgs=<number of messages to receive>
-DlogFile=<log path for eg: C:\Users\aj\logs\SimpleSender.log>

