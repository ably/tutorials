package io.ably.example.androidpushexample.receivers;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

/**
 *
 */
public class AblyPushMessagingService extends FirebaseMessagingService {
    public static final String PUSH_DATA_ACTION = "io.ably.example.androidpushexample.PUSH_DATA_MESSAGE";
    public static final String PUSH_NOTIFICATION_ACTION = "io.ably.example.androidpushexample.PUSH_NOTIFICATION_MESSAGE";
    private static final String TAG = AblyPushMessagingService.class.getName();

    @Override
    public void onMessageReceived(RemoteMessage message) {
        //FCM data is received here.

    }




}
