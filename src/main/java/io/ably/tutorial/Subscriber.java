package io.ably.tutorial;

import static io.ably.tutorial.Constants.API_KEY;
import static io.ably.tutorial.Constants.CHANNEL_NAME;
import static io.ably.tutorial.Constants.CIPHER_KEY_BASE64;

import io.ably.lib.realtime.AblyRealtime;
import io.ably.lib.realtime.Channel;
import io.ably.lib.types.AblyException;
import io.ably.lib.types.ChannelOptions;

public class Subscriber {
    
    public static void main(String[] args) throws AblyException {
        AblyRealtime ablyRealtime = new AblyRealtime(API_KEY);
        ChannelOptions options = ChannelOptions.fromCipherKey(CIPHER_KEY_BASE64);
        Channel channel = ablyRealtime.channels.get(CHANNEL_NAME, options);
        
        channel.subscribe(CHANNEL_NAME, message -> System.out.println("Decrypted data: " + message.data));
    }
    
}
