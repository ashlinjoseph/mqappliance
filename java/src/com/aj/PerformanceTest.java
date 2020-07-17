package com.aj;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.jms.JMSConsumer;
import javax.jms.JMSContext;
import javax.jms.JMSException;
import javax.jms.JMSProducer;
import javax.jms.Message;
import javax.jms.Queue;
import javax.jms.TextMessage;

import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.wmq.WMQConstants;

public class PerformanceTest {

	public static void main(String[] args) {
		String hostname = "9.20.49.89";
		int port = 1987;
		String channel = "CHNL.AJ";
		String qm = "QMAJ1";
		String senderQ = "Q.AJ";
		String receiverQ = "Q.AJ";
		String APP_USER = "aj"; // User name that application uses to connect to MQ
		String APP_PASSWORD = "app123"; // Password that the application uses to connect to MQ
		DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss:SSS");
		
		System.out.println(dateFormat.format(new Date())+": Connection to "+qm+" at "+hostname+":"+port + " via channel: " + channel);
		
		try {
			
			MQQueueConnectionFactory cf = new MQQueueConnectionFactory();
	
			cf.setIntProperty(WMQConstants.WMQ_CONNECTION_MODE, WMQConstants.WMQ_CM_CLIENT);
			cf.setStringProperty(WMQConstants.WMQ_QUEUE_MANAGER, qm);
			cf.setStringProperty(WMQConstants.WMQ_HOST_NAME, hostname);
			cf.setIntProperty(WMQConstants.WMQ_PORT, port);
			cf.setStringProperty(WMQConstants.WMQ_CHANNEL, channel);
			cf.setStringProperty(WMQConstants.USERID, APP_USER);
			cf.setStringProperty(WMQConstants.PASSWORD, APP_PASSWORD); 
			cf.setClientReconnectOptions(WMQConstants.WMQ_CLIENT_RECONNECT);
		    cf.setClientReconnectTimeout(30000);

			JMSContext context = cf.createContext();
			System.out.println(dateFormat.format(new Date())+": Connection established to send a message");
			
			JMSProducer prod = context.createProducer();
			Queue senderQueue = context.createQueue(senderQ);
			
			TextMessage textMessage = context.createTextMessage();
			textMessage.setText("AJMsg");
			prod.send(senderQueue, textMessage);

			Queue receiverQueue = context.createQueue(receiverQ);
			System.out.println(dateFormat.format(new Date()) + ": Connection established to receive a message");
			JMSConsumer consumer = context.createConsumer(receiverQueue);
			Message message = consumer.receive(1000);
			if(message!=null)
			{
				System.out.println(dateFormat.format(new Date()) + ": Message received: "+ ((TextMessage) message).getText());
			}
			else {
				System.out.println(dateFormat.format(new Date()) + ": No Message received");
			}
			context.close();
			
		} catch (JMSException e) {
			System.out.println(dateFormat.format(new Date()) + ": Failed to Connect");
			e.printStackTrace();
		}

	}

}
