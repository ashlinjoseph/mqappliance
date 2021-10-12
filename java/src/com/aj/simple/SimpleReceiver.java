package com.aj.simple;

import java.io.IOException;
import java.util.logging.FileHandler;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;

import javax.jms.JMSConsumer;
import javax.jms.JMSContext;
import javax.jms.JMSException;
import javax.jms.Queue;
import javax.jms.TextMessage;

import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.wmq.WMQConstants;

public class SimpleReceiver {

	public static void main(String[] args) {

		Logger logger = Logger.getLogger("AJLog");  
	    FileHandler fileHandler;
	    
		String hostname = System.getProperty("hostname");
		int port = Integer.parseInt(System.getProperty("port"));
		String channel = System.getProperty("channel");
		String qm = System.getProperty("qmgr");
		String receiverQ = System.getProperty("receiverQ");
		String APP_USER = System.getProperty("user"); // User name that application uses to connect to MQ
		String APP_PASSWORD = System.getProperty("pwd"); // Password that the application uses to connect to MQ
		String logfile = System.getProperty("logFile");
		int nuOfMessages = Integer.parseInt(System.getProperty("numsgs"));

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
			
			Queue receiverQueue = context.createQueue(receiverQ);
			JMSConsumer consumer = context.createConsumer(receiverQueue);
			
			int msgCount=0;
			while (msgCount<nuOfMessages)
			{
				TextMessage msgReceived=(TextMessage) consumer.receive();
				if(msgReceived.getText().contains("AJ Message:")) {
					msgCount++;
				}
				else {
					logger.info("Incorrect Message Received: " + msgReceived.getText() );
					break;
				}
			}

			logger.info(nuOfMessages+ " messages received: ");
			
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
