package io.ably.tutorial;

import io.ably.lib.rest.AblyRest;
import io.ably.lib.rest.Channel;
import io.ably.lib.types.AblyException;
import io.ably.lib.types.Message;

public class Example {
	
	private final static String API_KEY = "INSERT-YOUR-API-KEY-HERE"; /* Sign up at ably.io to get your API key */

    /* RuntimeException will be thrown if API_KEY will not be set to a proper one */
    static {
        if (API_KEY.contains("INSERT")) {
            throw new RuntimeException("API key is not set, sign up on ably.io to get yours");
        }
    }

	public static void main(String[] args) {
		try {
			initAbly();
		} catch (AblyException e) {
			e.printStackTrace();
		}
	}
	
	/* Add AblyException to method signature as AblyRest constructor can throw one */
	private static void initAbly() throws AblyException{
		AblyRest ablyRest = new AblyRest(API_KEY);
        Channel channel = ablyRest.channels.get("persisted:sounds");
        
        /* Publish three messages, specify event name first, then payload */
        channel.publish("play", "bark");
        channel.publish("play", "meow");
        channel.publish("play", "cluck");
        
        /* Fetch historical messages from channel, you can customize history query with parameters, when no parameters are needed just pass null */
        Message[] historicMessages = channel.history(null).items();
        for (Message message : historicMessages) {       
            System.out.println("message: " + message.id + " - " + message.data);
        }
	}
}
