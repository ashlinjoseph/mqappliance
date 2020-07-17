package com.ibm.aj.other;

import javax.jms.JMSConsumer;
import javax.jms.JMSContext;
import javax.jms.JMSException;
import javax.jms.Queue;

import com.ibm.msg.client.jms.JmsConnectionFactory;
import com.ibm.msg.client.jms.JmsFactoryFactory;
import com.ibm.msg.client.wmq.WMQConstants;

public class ReceiverApp {
	
	// Create variables for the connection to MQ//  
	private static final String HOST = "9.20.87.138"; // Host name or IP address
	private static final int PORT = 1987; // Listener port for your queue manager
	private static final String CHANNEL = "CHNL.AJ"; // Channel name
	private static final String QMGR = "QM.AJ"; // Queue manager name
	private static final String APP_USER = "aj"; // User name that application uses to connect to MQ
	private static final String APP_PASSWORD = "123456"; // Password that the application uses to connect to MQ
	private static final String QUEUE_NAME = "Q.AJ"; // Queue that the application uses to put and get
	private static final int expectedNoMsgs = 100;

	public static void main(String[] args) {
		System.out.println("Welcome Ashlin, Receiver App!");
		System.out.println("---------------");
		
		JmsFactoryFactory ff;
		JmsConnectionFactory cf;
		JMSContext context;
		Queue queue;
		JMSConsumer consumer;
		
		try {
			ff = JmsFactoryFactory.getInstance(WMQConstants.WMQ_PROVIDER);
			cf = ff.createConnectionFactory();
			cf.setStringProperty(WMQConstants.WMQ_HOST_NAME, HOST);
			cf.setIntProperty(WMQConstants.WMQ_PORT, PORT);
			cf.setStringProperty(WMQConstants.WMQ_CHANNEL, CHANNEL);
			cf.setIntProperty(WMQConstants.WMQ_CONNECTION_MODE, WMQConstants.WMQ_CM_CLIENT);
			cf.setStringProperty(WMQConstants.WMQ_QUEUE_MANAGER, QMGR);
			cf.setStringProperty(WMQConstants.WMQ_APPLICATIONNAME, "JmsPutGet (JMS)");
//			cf.setBooleanProperty(WMQConstants.USER_AUTHENTICATION_MQCSP, true);
			cf.setStringProperty(WMQConstants.USERID, APP_USER);
			cf.setStringProperty(WMQConstants.PASSWORD, APP_PASSWORD);
			
			/* Create JMS objects	*/
			context = cf.createContext();
			queue = context.createQueue("queue:///" + QUEUE_NAME);
			System.out.println("Connection with MQ established!");
			consumer = context.createConsumer(queue);
			int i;
			long startTime = System.nanoTime();  
			for(i=0;i<expectedNoMsgs;i++)
				consumer.receive();
			long timeTook = System.nanoTime() - startTime;
			System.out.println(i + " messages Received!");
			System.out.println("Time taken for receiving messages: "+ timeTook/1000000000.0);

		} catch (JMSException e) {
			e.printStackTrace();
		}
	}
}
