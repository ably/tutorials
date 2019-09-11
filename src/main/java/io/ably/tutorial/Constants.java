package io.ably.tutorial;

class Constants {
    static final String API_KEY = "INSERT-YOUR-API-KEY-HERE"; /* Sign up at ably.io to get your API key */
    
    /* RuntimeException will be thrown if API_KEY will not be set to a proper one */
    static {
        if (Constants.API_KEY.contains("INSERT")) {
            throw new RuntimeException("API key is not set, sign up on ably.io to get yours");
        }
    }
    
}
