To run Responder.java, the following Java system properties needs to be passed on:
-Dhost=<qmgrIP>
-Dport=<port>
-Dchannel=<channel_name>
-Dqmgr=<queue_manager>
-DrequestQ=<queue>
-Duser=<messaging_user>
-Dpwd=<messaging_password>



To run the Requester.java, first you need to make sure the Responder.java app is running and the following Java system properties needs to be passed on:
-Dhost=<qmgrIP>
-Dport=<port>
-Dchannel=<channel_name>
-Dqmgr=<queue_manager>
-DrequestQ=<queue>
-Duser=<messaging_user>
-Dpwd=<messaging_password>
-Dnomsgs=<number_of_messages>


