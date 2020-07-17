package com.ibm.aj.roundtrip;

/**
Java Class: RoundTripWithSSL
Author: Ashlin Joseph
Date: 06/03/2019

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

(C) Copyright IBM Corp. 2019 All Rights Reserved.
**/

import java.io.IOException;
import java.util.UUID;
import java.util.logging.FileHandler;
import java.util.logging.Logger;

import javax.jms.JMSConsumer;
import javax.jms.JMSContext;
import javax.jms.JMSException;
import javax.jms.JMSProducer;
import javax.jms.Message;
import javax.jms.Queue;
import javax.jms.TextMessage;

import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.wmq.WMQConstants;

public class RoundTripWithSSL {

	public static void main(String[] args) {
		
		Logger logger = Logger.getLogger("AJLog");  
	    FileHandler fileHandler; 
	    
		String hostname = System.getProperty("hostname");
		int port = Integer.parseInt(System.getProperty("port"));
		String channel = System.getProperty("channel");
		String qm = System.getProperty("qmgr");
		String senderQ = System.getProperty("senderQ");
		String receiverQ = System.getProperty("receiverQ");
		String logfile = System.getProperty("logFile");
		try {
			fileHandler = new FileHandler(logfile);  
	        logger.addHandler(fileHandler);
			
			MQQueueConnectionFactory cf = new MQQueueConnectionFactory();
			cf.setTransportType(1);
			cf.setIntProperty(WMQConstants.WMQ_CONNECTION_MODE, WMQConstants.WMQ_CM_BINDINGS_THEN_CLIENT);
			cf.setStringProperty(WMQConstants.WMQ_QUEUE_MANAGER, qm);
			cf.setStringProperty(WMQConstants.WMQ_HOST_NAME, hostname);
			cf.setIntProperty(WMQConstants.WMQ_PORT, port);
			cf.setStringProperty(WMQConstants.WMQ_CHANNEL, channel);
			
			logger.info("Connecting to "+qm+" at "+hostname+":"+port + " via channel: " + channel);
			JMSContext context = cf.createContext();
			logger.info("Connection established to send a message");
			
			JMSProducer prod = context.createProducer();
			Queue senderQueue = context.createQueue(senderQ);
			
			TextMessage textMessage = context.createTextMessage();
			textMessage.setText("Ashlin's message is " + UUID.randomUUID().toString());
			prod.send(senderQueue, textMessage);
			logger.info("Message Sent: " + textMessage.getText());
			
			Queue receiverQueue = context.createQueue(receiverQ);
			logger.info("Connection established to receive a message");
			JMSConsumer consumer = context.createConsumer(receiverQueue);
			logger.info("Trying to receive a message");
			Message message = consumer.receive(1000);
			if(message!=null)
			{
				logger.info("Message received: "+ ((TextMessage) message).getText());
			}
			else {
				logger.info("No Message received");
			}
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
