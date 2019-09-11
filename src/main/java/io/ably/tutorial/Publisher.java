package io.ably.tutorial;

import static io.ably.tutorial.Constants.API_KEY;

import io.ably.lib.realtime.AblyRealtime;
import io.ably.lib.types.AblyException;

public class Publisher {
    
    public static void main(String[] args) throws AblyException {
        AblyRealtime ablyRealtime = new AblyRealtime(API_KEY);
    }
    
}
