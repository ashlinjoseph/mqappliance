package com.ibm.aj.simple;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.jms.JMSConsumer;
import javax.jms.JMSContext;
import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.Queue;
import javax.jms.TextMessage;

import com.ibm.msg.client.jms.JmsConnectionFactory;
import com.ibm.msg.client.jms.JmsFactoryFactory;
import com.ibm.msg.client.wmq.WMQConstants;

public class Receiver {

	public static void main(String[] args) {
		String hostname = "qm-aj-96f7.qm.eu-gb.mq.appdomain.cloud";
		int port = 32326;
		String channel = "CLOUD.APP.SVRCONN";
		String qm = "QM.AJ";
		String queueName = "DEV.QUEUE.1";
		String APP_USER = "aj"; // User name that application uses to connect to MQ
		String APP_PASSWORD = "W7aqri52R1I7Hyv9R_Py-qMJb81AKa3Ve7H0robV73WF"; // Password that the application uses to connect to MQ
		DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss:SSS");

		System.out.println(dateFormat.format(new Date()) + ": Connection to " + qm + " at " + hostname
				+ " via channel: " + channel);
		
		try {
			JmsFactoryFactory ff = JmsFactoryFactory.getInstance(WMQConstants.WMQ_PROVIDER);
			JmsConnectionFactory cf = ff.createConnectionFactory();
	
			cf.setIntProperty(WMQConstants.WMQ_CONNECTION_MODE, WMQConstants.WMQ_CM_BINDINGS_THEN_CLIENT);
			cf.setStringProperty(WMQConstants.WMQ_QUEUE_MANAGER, qm);
			cf.setStringProperty(WMQConstants.WMQ_HOST_NAME, hostname);
			cf.setIntProperty(WMQConstants.WMQ_PORT, port);
			cf.setStringProperty(WMQConstants.WMQ_CHANNEL, channel);
			cf.setStringProperty(WMQConstants.USERID, APP_USER);
			cf.setStringProperty(WMQConstants.PASSWORD, APP_PASSWORD);
			cf.setBooleanProperty(WMQConstants.USER_AUTHENTICATION_MQCSP, true);
			
			JMSContext context = cf.createContext();
			System.out.println(dateFormat.format(new Date()) + ": Connection established!");
			
			Queue queue = context.createQueue(queueName);
			JMSConsumer consumer = context.createConsumer(queue);
			int messageCount = 0;
			while(true) {
				Message message = consumer.receive(1000);
				if(message!=null)
				{
					System.out.println("Message: "+ message.getJMSMessageID());
					System.out.println("Message: "+ ((TextMessage) message).getText());
					messageCount++;
				}
				else {
					System.out.println(messageCount + " messages received!");
					break;
				}
			}
			
		} catch (JMSException e) {
			e.printStackTrace();
		}
	}

}
