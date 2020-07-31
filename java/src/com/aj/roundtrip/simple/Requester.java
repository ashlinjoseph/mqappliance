package com.aj.roundtrip.simple;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import javax.jms.JMSConsumer;
import javax.jms.JMSContext;
import javax.jms.JMSException;
import javax.jms.JMSProducer;
import javax.jms.Message;
import javax.jms.Queue;
import javax.jms.TemporaryQueue;
import javax.jms.TextMessage;

import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.msg.client.wmq.WMQConstants;

public class Requester {

	public static void main(String[] args) {
		String hostname = System.getProperty("host");
		int port = Integer.parseInt(System.getProperty("port"));
		String channel = System.getProperty("channel");
		String qmgr = System.getProperty("qmgr");
		String requestQ = System.getProperty("requestQ");
		String user = System.getProperty("user"); 
		String pwd = System.getProperty("pwd"); 
		int numberOfMsgs=Integer.parseInt(System.getProperty("nomsgs"));;

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
			System.out.println(dateFormat.format(new Date())+": Connection established to send a message");
			
			JMSProducer prod = context.createProducer();
			Queue requestQueue = context.createQueue(requestQ);

			TemporaryQueue responseQueue = context.createTemporaryQueue();
			JMSConsumer consumer = context.createConsumer(responseQueue);

			List<TextMessage> reqMsgs=new ArrayList<TextMessage>();
			
			for(int j=0;j<numberOfMsgs;j++) {
				TextMessage reqMsg = context.createTextMessage();
				reqMsg.setText("AJMsg"+j);
				reqMsg.setJMSReplyTo(responseQueue);
				reqMsgs.add(reqMsg);
			}
			long startTime, stopTime;
			ArrayList<Long> roundTripTimes=new ArrayList<Long>();
			

			System.out.println(dateFormat.format(new Date()) + ": Starting to send "+numberOfMsgs+" messages!");
			for (int i=0; i<numberOfMsgs; i++) {
				startTime = System.currentTimeMillis();
				prod.send(requestQueue, reqMsgs.get(i));
				Message message = consumer.receive(30000);
				stopTime = System.currentTimeMillis();
				if(message!=null) {
					if(((TextMessage) message).getText().contains("AJResponseMsg")) {
						roundTripTimes.add(stopTime - startTime);
					}
					else {
						System.out.println(dateFormat.format(new Date()) + ": Incorrect msg received: " + ((TextMessage) message).getText());
						System.exit(1);
					}
				}
				else {
					System.out.println(dateFormat.format(new Date()) + ": No msg received for 30 seconds!");
					System.exit(1);
				}
			}
		
			System.out.println(dateFormat.format(new Date()) + ": "+roundTripTimes.size()+" responses received!");
			long totalTime=0;
			long longestRoundTrip=0;
			int longestRoundTripMsgNo=0;
			long shortestRoundTrip=roundTripTimes.get(0);
			int shortestRoundTripMsgNo=1;
			
		    for (int k=0; k < roundTripTimes.size();k++) {
		        totalTime = totalTime + roundTripTimes.get(k);
		        if(roundTripTimes.get(k) > longestRoundTrip){
		        	longestRoundTrip = roundTripTimes.get(k);
		        	longestRoundTripMsgNo = k+1;
		        }
		        if(shortestRoundTrip > roundTripTimes.get(k)) {
		        	shortestRoundTrip=roundTripTimes.get(k);
		        	shortestRoundTripMsgNo=k+1;
		        }
		    }
		    long averageRoundTripTime=totalTime/numberOfMsgs;
			System.out.println(dateFormat.format(new Date()) + ": Avgerage round trip time is: "+ (averageRoundTripTime)+ "milliseconds");
		
			System.out.println(dateFormat.format(new Date()) + ": Longest round trip was msg no: "+ longestRoundTripMsgNo + " and round trip took " + longestRoundTrip+"milliseconds");
			System.out.println(dateFormat.format(new Date()) + ": Shortest round trip was msg no: "+ shortestRoundTripMsgNo + " and round trip took " + shortestRoundTrip+"milliseconds");
			System.out.println(dateFormat.format(new Date()) + ": Total time taken for "+ numberOfMsgs +" round trips is: "+(totalTime/1000)+ " seconds");
			
			if(totalTime>1000) {
				long msgRatePerSec=numberOfMsgs/(totalTime/1000);
				System.out.println(dateFormat.format(new Date()) + ": Round trip rate is: "+ msgRatePerSec+ "/sec");
			}
			else
				System.out.println(dateFormat.format(new Date()) + ": The entire round trip ran for less than a second to calculate the round trip per second rate.");
			context.close();
			
		} catch (JMSException e) {
			System.out.println(dateFormat.format(new Date()) + ": Failed to Connect");
			e.printStackTrace();
		}

	}

}
