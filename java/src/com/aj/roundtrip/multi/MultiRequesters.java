package com.aj.roundtrip.multi;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashMap;
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

class Requester implements Runnable {
	
	String qmgr=null;
	String hostname=null; 
	int port=0;
	String channel=null;
	String user=null;
	String pwd=null;
	String requestQ=null;
	int numberOfMsgs=0;
	ArrayList<Long> roundTripTimes=new ArrayList<Long>(); 
	
	public Requester(String qmgr, String hostname, int port, String channel, String requestQ, int noMsgsPerThread) {
		this.qmgr=qmgr;
		this.hostname=hostname;
		this.port=port;
		this.channel=channel;
		this.requestQ=requestQ;
		this.numberOfMsgs=noMsgsPerThread;
	}
	
	public Requester(String qmgr, String hostname, int port, String channel, String requestQ, String user, String pwd, int noMsgsPerThread) {
		this.qmgr=qmgr;
		this.hostname=hostname;
		this.port=port;
		this.channel=channel;
		this.requestQ=requestQ;
		this.user=user;
		this.pwd=pwd;
		this.numberOfMsgs=noMsgsPerThread;
	}
	
	public void run() {

		DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss:SSS");
		
		try {
			
			MQQueueConnectionFactory cf = new MQQueueConnectionFactory();
			cf.setIntProperty(WMQConstants.WMQ_CONNECTION_MODE, WMQConstants.WMQ_CM_CLIENT);
			cf.setStringProperty(WMQConstants.WMQ_QUEUE_MANAGER, qmgr);
			cf.setStringProperty(WMQConstants.WMQ_HOST_NAME, hostname);
			cf.setIntProperty(WMQConstants.WMQ_PORT, port);
			cf.setStringProperty(WMQConstants.WMQ_CHANNEL, channel);
			if(user!=null ) {
				cf.setStringProperty(WMQConstants.USERID, user);
				cf.setStringProperty(WMQConstants.PASSWORD, pwd);
			} 
			cf.setClientReconnectOptions(WMQConstants.WMQ_CLIENT_RECONNECT);
		    cf.setClientReconnectTimeout(30000);

			JMSContext context = cf.createContext();
			System.out.println(dateFormat.format(new Date()) + ": Connection established to " + qmgr + " at " + hostname + " to send a request");
			
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
			
			//System.out.println(dateFormat.format(new Date()) + ": Starting to send "+numberOfMsgs+" messages!");
			for (int i=0; i<numberOfMsgs; i++) {
				startTime = System.currentTimeMillis();
				prod.send(requestQueue, reqMsgs.get(i));
				Message message = consumer.receive(4000);
				stopTime = System.currentTimeMillis();
				if(message!=null) {
					if(((TextMessage) message).getText().contains("AJResponseMsg")) {
						roundTripTimes.add(stopTime - startTime);
					}
					else {
						//System.out.println(dateFormat.format(new Date()) + ": Incorrect msg received: " + ((TextMessage) message).getText());
						System.exit(1);
					}
				}
				else {
					//System.out.println(dateFormat.format(new Date()) + ": No msg received for 4 seconds!");
					System.exit(1);
				}
			}
		
			System.out.println(dateFormat.format(new Date()) + ": "+roundTripTimes.size()+" responses received on this thread!");
			context.close();
			
		} catch (JMSException e) {
			System.out.println(dateFormat.format(new Date()) + ": Failed to Connect");
			e.printStackTrace();
		}
	}
}

public class MultiRequesters {

	public static void main(String[] args) {
		String hostname = System.getProperty("host");
		int port = Integer.parseInt(System.getProperty("port"));
		String channel = System.getProperty("channel");
		String qmgr = System.getProperty("qmgr");
		String requestQ = System.getProperty("requestQ");
		String user = System.getProperty("user"); 
		String pwd = System.getProperty("pwd"); 
		int numberOfThreads=Integer.parseInt(System.getProperty("nothread"));
		int numberOfMsgs=Integer.parseInt(System.getProperty("nomsgs"));

		final List<Requester> requesters = new ArrayList<>();
		DateFormat dateFormat = new SimpleDateFormat("HH:mm:ss:SSS");
		
		
		for(int i=0;i<numberOfThreads;i++) {
			requesters.add(new Requester(qmgr, hostname, port, channel, requestQ, user, pwd, numberOfMsgs));
		}
		System.out.println(dateFormat.format(new Date()) + ": Requesters created.");

		final List<Thread> threads = new ArrayList<>();
		
		for (final Requester requester : requesters) {
			threads.add(new Thread(requester));
		}
		System.out.println(dateFormat.format(new Date()) + ": Threads created.");
		long threadsStartTime = System.currentTimeMillis();
		for (final Thread thread : threads) {
			thread.start();
		}
		System.out.println(dateFormat.format(new Date()) + ": Threads started.");
		long threadsStopTime = 0;
		for (final Thread thread : threads) {
			try {
				thread.join();
				threadsStopTime = System.currentTimeMillis();
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
		
		long allThreadsRoundTripTime = threadsStopTime-threadsStartTime;

		int threadno=1;
		for(Requester requester: requesters) {
			long totalTime=0;
			long longestRoundTrip=0;
			int longestRoundTripMsgNo=0;
			long shortestRoundTrip=requester.roundTripTimes.get(0);
			int shortestRoundTripMsgNo=1;
			
		    for (int k=0; k < requester.roundTripTimes.size();k++) {
		        totalTime = totalTime + requester.roundTripTimes.get(k);
		        if(requester.roundTripTimes.get(k) > longestRoundTrip){
		        	longestRoundTrip = requester.roundTripTimes.get(k);
		        	longestRoundTripMsgNo = k+1;
		        }
		        if(shortestRoundTrip > requester.roundTripTimes.get(k)) {
		        	shortestRoundTrip = requester.roundTripTimes.get(k);
		        	shortestRoundTripMsgNo=k+1;
		        }
		    }
		    long averageRoundTripTime=totalTime/numberOfMsgs;
		    System.out.println("=======================================");
		    System.out.println(dateFormat.format(new Date()) + ": THREAD No:"+ threadno);
			System.out.println(dateFormat.format(new Date()) + ": Avgerage round trip time is: "+ (averageRoundTripTime)+ "milliseconds");
			System.out.println(dateFormat.format(new Date()) + ": Longest round trip was msg no: "+ longestRoundTripMsgNo + " and round trip took " + longestRoundTrip+"milliseconds");
			System.out.println(dateFormat.format(new Date()) + ": Shortest round trip was msg no: "+ shortestRoundTripMsgNo + " and round trip took " + shortestRoundTrip+"milliseconds");
			System.out.println(dateFormat.format(new Date()) + ": Total time taken for "+ numberOfMsgs +" round trips is: "+(totalTime/1000)+ " seconds");
			System.out.println("\n");
			threadno++;	
		}
		System.out.println(dateFormat.format(new Date()) + ": "+(numberOfMsgs*numberOfThreads)+ " round trips completed across "+numberOfThreads+" threads and it took "+ allThreadsRoundTripTime + "milliseconds");
		
		if(allThreadsRoundTripTime>1000) {
			long msgRatePerSec=(numberOfMsgs*numberOfThreads)/(allThreadsRoundTripTime/1000);
			System.out.println(dateFormat.format(new Date()) + ": Round trip rate is: "+ msgRatePerSec+ "/sec");
		}
		else
			System.out.println(dateFormat.format(new Date()) + ": The entire round trip ran for less than a second to calculate the round trip per second rate.");
		
	}

}
