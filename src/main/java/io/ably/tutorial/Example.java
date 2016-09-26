package io.ably.tutorial;

import io.ably.lib.realtime.AblyRealtime;
import io.ably.lib.types.AblyException;

public class Example {
	
	private final static String API_KEY = "INSERT-YOUR-API-KEY-HERE"; /* Sign up at ably.io to get your API key */

    /* RuntimeException will be thrown if API_KEY will not be set to a proper one */
    static {
        if (API_KEY.contains("INSERT")) {
            throw new RuntimeException("API key is not set, sign up at ably.io to get yours");
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
		AblyRealtime ablyRealtime = new AblyRealtime(API_KEY); 
	}
}
