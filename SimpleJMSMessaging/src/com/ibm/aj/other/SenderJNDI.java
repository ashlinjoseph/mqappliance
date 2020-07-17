package com.ibm.aj.other;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Hashtable;

import javax.jms.Connection;
import javax.jms.ConnectionFactory;
import javax.jms.Destination;
import javax.jms.JMSException;
import javax.jms.MessageProducer;
import javax.jms.Session;
import javax.jms.TextMessage;
import javax.naming.Context;
import javax.naming.NamingException;
import javax.naming.directory.InitialDirContext;

import com.ibm.msg.client.jms.JmsConnectionFactory;
import com.ibm.msg.client.jms.JmsDestination;
import com.ibm.msg.client.wmq.WMQConstants;


public class SenderJNDI {
	static Context jndiContext;
	static ConnectionFactory connectionFactory;
    static Destination destination; 

	public static void main(String[] args) {

	    String initialContextUrl = "file:/C:\\Users\\aj\\IBM\\WebSphereMQ\\JDNI";
	    String connectionFactoryFromJndi = "mqoc";
	    String destinationFromJndi = "qaj";
	    String APP_USER = "ajtestapp"; // User name that application uses to connect to MQ
		String APP_PASSWORD = "cN-XdC2TYzYrTpEtI4aaidQRcwhVDj-iSeiEGd8Ed9xf"; // Password that the application uses to connect to MQ
		
	    
	    // Variables
	    Connection connection = null;
	    Session session = null;
	    MessageProducer producer = null;
		int noMsgs = 10;
		DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss:SSS");

	    try {
	      // Instantiate the initial context
	      String contextFactory = "com.sun.jndi.fscontext.RefFSContextFactory";
	      Hashtable<String, String> environment = new Hashtable<String, String>();
	      environment.put(Context.INITIAL_CONTEXT_FACTORY, contextFactory);
	      environment.put(Context.PROVIDER_URL, initialContextUrl);
	      Context context = new InitialDirContext(environment);
	      System.out.println("Initial context found!");

	      // Lookup the connection factory
	      JmsConnectionFactory cf = (JmsConnectionFactory) context.lookup(connectionFactoryFromJndi);
	      // Lookup the destination
	      destination = (JmsDestination) context.lookup(destinationFromJndi);

	      cf.setStringProperty(WMQConstants.USERID, APP_USER);
	      cf.setStringProperty(WMQConstants.PASSWORD, APP_PASSWORD);
	      
	      System.out.println("Connection Factory pulled out: " + cf);
		
	      // Create JMS objects
	      connection = cf.createConnection();
	      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
	      producer = session.createProducer(destination);

			for (int i = 0; i < noMsgs; i++) {
				TextMessage textMessage = session.createTextMessage();
				textMessage.setText("AshlinMsg" + Integer.toString(i));
				producer.send(destination, textMessage);
			}
			System.out.println(dateFormat.format(new Date()) + ": All Messages Sent!");
		
		} catch (JMSException e) {
			e.printStackTrace();
		} catch (NamingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
}
