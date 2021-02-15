package com.ibm.aj;

import java.io.IOException;
import java.util.UUID;
import java.util.logging.FileHandler;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;

//import javax.jms.JMSConsumer;
import javax.jms.JMSContext;
import javax.jms.JMSException;
import javax.jms.JMSProducer;
//import javax.jms.Message;
import javax.jms.Queue;
import javax.jms.TextMessage;

import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.wmq.WMQConstants;

/**
 * This app can be used for TLS/SSL Two Way mutual authentication
 * First you need a keystore and truststore at the queue manager. 
 * Create a certificate, get it signed and export the public part out. 
 * Create a keystore and truststore at the Client App (.jks). 
 * Create a certificate, get it signed and export the public part out.
 * Add eachothers pub key to the trust store. 
 * At the channel, set a cipher spec that matches the cipher suite set 
 * in the JMS app; set SSL Auth required and you're done.   
 *  
 * */
public class SenderWithSSL {

	public static void main(String[] args) {
		
		Logger logger = Logger.getLogger("AJLog");  
	    FileHandler fileHandler;
	    
		String hostname = System.getProperty("hostname");
		int port = Integer.parseInt(System.getProperty("port"));
		String channel = System.getProperty("channel");
		String qm = System.getProperty("qmgr");
		String senderQ = System.getProperty("senderQ");
		String APP_USER = System.getProperty("user"); // User name that application uses to connect to MQ
		String APP_PASSWORD = System.getProperty("pwd"); // Password that the application uses to connect to MQ
		String cipherSuite = System.getProperty("cipherSuite"); // Cipher Suite needs to match the Cipher spec at the Queue Manager
		String logfile = System.getProperty("logFile");
		try {
			fileHandler = new FileHandler(logfile);  
	        logger.addHandler(fileHandler);
	        SimpleFormatter formatter = new SimpleFormatter();  
	        fileHandler.setFormatter(formatter);
			
			MQQueueConnectionFactory cf = new MQQueueConnectionFactory();
			cf.setTransportType(1);
			cf.setIntProperty(WMQConstants.WMQ_CONNECTION_MODE, WMQConstants.WMQ_CM_CLIENT);
			cf.setStringProperty(WMQConstants.WMQ_QUEUE_MANAGER, qm);
			cf.setStringProperty(WMQConstants.WMQ_HOST_NAME, hostname);
			cf.setIntProperty(WMQConstants.WMQ_PORT, port);
			cf.setStringProperty(WMQConstants.WMQ_CHANNEL, channel);
			cf.setStringProperty(WMQConstants.USERID, APP_USER);
			cf.setStringProperty(WMQConstants.PASSWORD, APP_PASSWORD);
			cf.setBooleanProperty(WMQConstants.USER_AUTHENTICATION_MQCSP, true);
			cf.setSSLCipherSuite(cipherSuite);

			logger.info("Connecting to "+qm+" at "+hostname+":"+port + " via channel: " + channel);
			JMSContext context = cf.createContext();

			JMSProducer prod = context.createProducer();
			Queue senderQueue = context.createQueue(senderQ);
			
			TextMessage textMessage = context.createTextMessage();
			textMessage.setText("Ashlin's message is " + UUID.randomUUID().toString());
			prod.send(senderQueue, textMessage);
			logger.info("Message Sent: " + textMessage.getText());
			
			context.close();
			logger.info("Connection closed!");
			
		} catch (JMSException e) {
			e.printStackTrace();
		} catch (SecurityException e) {  
		        e.printStackTrace();  
	    } catch (IOException e) {  
	        e.printStackTrace();  
	    } 
	}
}
