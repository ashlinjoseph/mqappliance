package com.aj.roundtrip.simple;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.jms.Destination;
import javax.jms.JMSConsumer;
import javax.jms.JMSContext;
import javax.jms.JMSException;
import javax.jms.JMSProducer;
import javax.jms.Message;
import javax.jms.Queue;
import javax.jms.TextMessage;

import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.wmq.WMQConstants;

public class Responder {

	public static void main(String[] args) {
		String hostname = System.getProperty("host");
		int port = Integer.parseInt(System.getProperty("port"));
		String channel = System.getProperty("channel");
		String qmgr = System.getProperty("qmgr");
		String requestQ = System.getProperty("requestQ");
		String user = System.getProperty("user"); 
		String pwd = System.getProperty("pwd"); 
		
		DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss:SSS");
		
		System.out.println(dateFormat.format(new Date())+": Connection to "+qmgr+" at "+hostname+":"+port + " via channel: " + channel);
		
		try {
			
			MQQueueConnectionFactory cf = new MQQueueConnectionFactory();
	
			cf.setIntProperty(WMQConstants.WMQ_CONNECTION_MODE, WMQConstants.WMQ_CM_CLIENT);
			cf.setStringProperty(WMQConstants.WMQ_QUEUE_MANAGER, qmgr);
			cf.setStringProperty(WMQConstants.WMQ_HOST_NAME, hostname);
			cf.setIntProperty(WMQConstants.WMQ_PORT, port);
			cf.setStringProperty(WMQConstants.WMQ_CHANNEL, channel);
			cf.setStringProperty(WMQConstants.USERID, user);
			cf.setStringProperty(WMQConstants.PASSWORD, pwd); 
			cf.setClientReconnectOptions(WMQConstants.WMQ_CLIENT_RECONNECT);
		    cf.setClientReconnectTimeout(30000);

			JMSContext context = cf.createContext();

			TextMessage textMessage = context.createTextMessage();
			textMessage.setText("AJResponseMsg");
			
			Queue requestQueue = context.createQueue(requestQ);
			System.out.println(dateFormat.format(new Date()) + ": Connection established to receive a message");
			JMSConsumer consumer = context.createConsumer(requestQueue);
			JMSProducer prod = context.createProducer();
			
			System.out.println(dateFormat.format(new Date()) + ": Waiting to receive requests..");
			
			while(true) {
				Message message = consumer.receive(30000);
				if(message!=null) {
					Destination responderQ = message.getJMSReplyTo();
					prod.send(responderQ, textMessage);
				}
				else {
					System.out.println(dateFormat.format(new Date()) + ": No more requests to respond");
					break;
				}
			}
			context.close();
			
		} catch (JMSException e) {
			System.out.println(dateFormat.format(new Date()) + ": Failed to Connect");
			e.printStackTrace();
		}

	}

}
