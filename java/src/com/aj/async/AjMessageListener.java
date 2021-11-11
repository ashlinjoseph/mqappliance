package com.aj.async;

import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.MessageListener;
import javax.jms.TextMessage;

public class AjMessageListener implements MessageListener {

		public void onMessage(Message message) 
		{
			try {
				System.out.println("I got the message: " + ((TextMessage) message).getText());
			} catch (JMSException e) {
				e.printStackTrace();
			}
		}
	
	}

