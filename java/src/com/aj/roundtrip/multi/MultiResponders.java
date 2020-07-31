package com.aj.roundtrip.multi;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

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

class Responder implements Runnable {

	String qmgr = null;
	String hostname = null;
	int port = 0;
	String channel = null;
	String user = null;
	String pwd = null;
	String requestQ = null;
	int waitTimes = 0;

	public Responder(String qmgr, String hostname, int port, String channel, String requestQ, int waitTimes) {
		this.qmgr = qmgr;
		this.hostname = hostname;
		this.port = port;
		this.channel = channel;
		this.requestQ = requestQ;
		this.waitTimes = waitTimes;
	}

	public Responder(String qmgr, String hostname, int port, String channel, String requestQ, String user, String pwd,
			int waitTimes) {
		this.qmgr = qmgr;
		this.hostname = hostname;
		this.port = port;
		this.channel = channel;
		this.requestQ = requestQ;
		this.user = user;
		this.pwd = pwd;
		this.waitTimes = waitTimes;
	}

	public void run() {
		DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss:SSS");

		try {

			MQQueueConnectionFactory cf = new MQQueueConnectionFactory();

			cf.setIntProperty(WMQConstants.WMQ_CONNECTION_MODE, WMQConstants.WMQ_CM_BINDINGS_THEN_CLIENT);
			cf.setStringProperty(WMQConstants.WMQ_QUEUE_MANAGER, qmgr);
			cf.setStringProperty(WMQConstants.WMQ_HOST_NAME, hostname);
			cf.setIntProperty(WMQConstants.WMQ_PORT, port);
			cf.setStringProperty(WMQConstants.WMQ_CHANNEL, channel);
			if (user != null) {
				cf.setStringProperty(WMQConstants.USERID, user);
				cf.setStringProperty(WMQConstants.PASSWORD, pwd);
			}
			cf.setClientReconnectOptions(WMQConstants.WMQ_CLIENT_RECONNECT);
			cf.setClientReconnectTimeout(30000);

			JMSContext context = cf.createContext();

			TextMessage textMessage = context.createTextMessage();
			textMessage.setText("AJResponseMsg");

			Queue requestQueue = context.createQueue(requestQ);
			System.out.println(dateFormat.format(new Date()) + ": Connection established to " + qmgr + " at " + hostname + " to receive a message");
			JMSConsumer consumer = context.createConsumer(requestQueue);
			JMSProducer prod = context.createProducer();

			System.out.println(dateFormat.format(new Date()) + ": Waiting to receive requests..");

			while (true) {
				Message message = consumer.receive(waitTimes);
				if (message != null) {
					Destination responderQ = message.getJMSReplyTo();
					prod.send(responderQ, textMessage);
				} else {
					System.out.println(
							dateFormat.format(new Date()) + ": No requests received in " + waitTimes + " milliseconds!");
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

public class MultiResponders {

	public static void main(String[] args) {

		String hostname = System.getProperty("host");
		int port = Integer.parseInt(System.getProperty("port"));
		String channel = System.getProperty("channel");
		String qmgr = System.getProperty("qmgr");
		String requestQ = System.getProperty("requestQ");
		String user = System.getProperty("user");
		String pwd = System.getProperty("pwd");
		int numberOfThreads = Integer.parseInt(System.getProperty("nothread"));
		int waitTimes = Integer.parseInt(System.getProperty("responderwaitTimes"));

		final List<Responder> responders = new ArrayList<>();
		DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss:SSS");

		for (int i = 0; i < numberOfThreads; i++) {
			responders.add(new Responder(qmgr, hostname, port, channel, requestQ, user, pwd, waitTimes));
		}
		System.out.println(dateFormat.format(new Date()) + ": Runnables created.");

		final List<Thread> threads = new ArrayList<>();
		for (final Responder responder : responders) {
			threads.add(new Thread(responder));
		}
		System.out.println(dateFormat.format(new Date()) + ": Threads created.");

		for (final Thread thread : threads) {
			thread.start();
		}
		System.out.println(dateFormat.format(new Date()) + ": Threads started.");

		for (final Thread thread : threads) {
			try {
				thread.join();
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
		System.out.println(dateFormat.format(new Date()) + ": All threads completed the lifecycle.");
	}

}
