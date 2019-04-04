package io.ably.tutorial.push_tutorial_two.receivers;

import android.content.Intent;
import android.support.v4.content.LocalBroadcastManager;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

/**
 *
 */
public class AblyPushMessagingService extends FirebaseMessagingService {
    public static final String PUSH_NOTIFICATION_ACTION = AblyPushMessagingService.class.getName() + ".PUSH_NOTIFICATION_MESSAGE";

    @Override
    public void onMessageReceived(RemoteMessage message) {
        //FCM data is received here.

        Intent intent = new Intent(PUSH_NOTIFICATION_ACTION);
        LocalBroadcastManager.getInstance(getApplicationContext()).sendBroadcast(intent);
    }

}
