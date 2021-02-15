The application connects to the given queue manager via the given SSL enabled MQ Channel and sends a single message. 

The following JVM properties needs to be set: 

-Dhostname=<hostname/ip>
-Dport=<port>
-Dchannel=<Channel with SSL Enabled>
-Dqmgr=<queue manager name>
-DsenderQ=<queue name>
-Duser=<username>
-Dpwd=<password or API key>
-DlogFile=<location for logs>/SenderSSL.log
-DcipherSuite=<Cipher Suite that matches the Cipher spec at the server side>
-Djavax.net.ssl.trustStore="<location for the java truststore with appropriate certificates>\key.jks"
-Djavax.net.ssl.trustStorePassword=<truststore password>
-Djavax.net.ssl.keyStore="<location for the java keystore with appropriate certificates>\key.jks"
-Djavax.net.ssl.keyStorePassword=<keystore password>
