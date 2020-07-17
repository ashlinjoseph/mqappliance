package com.ibm.aj.other;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.jms.JMSContext;
import javax.jms.JMSException;
import javax.jms.JMSProducer;
import javax.jms.Queue;
import javax.jms.TextMessage;

import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.wmq.WMQConstants;

public class SenderAutoReconnect {

	public static void main(String[] args) {
		String hostname = "9.20.194.189(1987),9.20.194.190(1987)";
		String channel = "CHNL.AJ";
		String qm = "QM_FINAL";
		String senderQ = "Q.AJ";
		String APP_USER = "ajtestapp"; // User name that application uses to connect to MQ
		String APP_PASSWORD = "cN-XdC2TYzYrTpEtI4aaidQRcwhVDj-iSeiEGd8Ed9xf"; // Password that the application uses to connect to MQ
		int noMsgs = 1000;

		DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss:SSS");

		System.out.println(dateFormat.format(new Date()) + ": Connection to " + qm + " at " + hostname
				+ " via channel: " + channel);

		try {

			MQQueueConnectionFactory cf = new MQQueueConnectionFactory();
			cf.setIntProperty(WMQConstants.WMQ_CONNECTION_MODE, WMQConstants.WMQ_CM_CLIENT);
			cf.setStringProperty(WMQConstants.WMQ_QUEUE_MANAGER, qm);
			cf.setStringProperty(WMQConstants.WMQ_CONNECTION_NAME_LIST, hostname);
			cf.setStringProperty(WMQConstants.WMQ_CHANNEL, channel);
			cf.setStringProperty(WMQConstants.USERID, APP_USER);
			cf.setStringProperty(WMQConstants.PASSWORD, APP_PASSWORD);
			cf.setClientReconnectOptions(WMQConstants.WMQ_CLIENT_RECONNECT);
			cf.setClientReconnectTimeout(30000);

			JMSContext context = cf.createContext();
			System.out.println(dateFormat.format(new Date()) + ": Connection established to send a message");

			JMSProducer prod = context.createProducer();
			Queue senderQueue = context.createQueue(senderQ);

			for (int i = 0; i < noMsgs; i++) {
				TextMessage textMessage = context.createTextMessage();
				textMessage.setText("AshlinMsg" + Integer.toString(i));
				prod.send(senderQueue, textMessage);
			}

			System.out.println(dateFormat.format(new Date()) + ": All Messages Sent!");

		} catch (JMSException e) {
			e.printStackTrace();
		}
	}
}
