package io.ably.tutorial;

class Constants {
    static final String API_KEY = "INSERT-YOUR-API-KEY-HERE"; /* Sign up at ably.io to get your API key */
    
    // Note: A sample base64 key is provided here for simplicity.
    // Alternatively, one could use io.ably.lib.util.Crypto.generateRandomKey()
    static final String CIPHER_KEY_BASE64 = "G98udOf2gFPJd0ITsIng8DdQJ32yhAjtRdTsMnCqkmw=";
    static final String CHANNEL_NAME = "encrypted:messages";
    
    /* RuntimeException will be thrown if API_KEY will not be set to a proper one */
    static {
        if (Constants.API_KEY.contains("INSERT")) {
            throw new RuntimeException("API key is not set, sign up on ably.io to get yours");
        }
    }
    
}
