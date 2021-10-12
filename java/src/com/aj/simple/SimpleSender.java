package com.aj.simple;

import java.io.IOException;
import java.util.UUID;
import java.util.logging.FileHandler;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;

import javax.jms.JMSContext;
import javax.jms.JMSException;
import javax.jms.JMSProducer;
import javax.jms.Queue;
import javax.jms.TextMessage;

import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.wmq.WMQConstants;

/**
 * SimpleSender.java is a simple JMS sender app that can connect to a
 * queue in a queue manager using username and password as security
 * and send a simple message. 
 *  
 * */

public class SimpleSender {

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
		int nuOfMessages = Integer.parseInt(System.getProperty("numsgs"));
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

			logger.info("Connecting to "+qm+" at "+hostname+":"+port + " via channel: " + channel);
			JMSContext context = cf.createContext();
			
			JMSProducer prod = context.createProducer();
			Queue senderQueue = context.createQueue(senderQ);
			
			for (int i=0;i<nuOfMessages;i++)
			{
				TextMessage textMessage = context.createTextMessage();
				textMessage.setText("AJ Message:" + UUID.randomUUID().toString());
				prod.send(senderQueue, textMessage);
			}

			logger.info(nuOfMessages+ " messages Sent: ");
			
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