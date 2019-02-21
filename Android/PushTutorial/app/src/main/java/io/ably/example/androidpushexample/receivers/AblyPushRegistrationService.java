package io.ably.example.androidpushexample.receivers;

import android.util.Log;

import com.google.firebase.iid.FirebaseInstanceId;

import io.ably.lib.push.AblyFirebaseInstanceIdService;

/**
 * Leave this empty as the base class AblyFirebaseInstanceIdService does the FCM token registration.
 * In case your app requires access to FCM token as well, then override io.ably.lib.push.AblyFirebaseInstanceIdService#onTokenRefresh()
 */
public class AblyPushRegistrationService extends AblyFirebaseInstanceIdService {
    @Override
    public void onTokenRefresh() {
        //Make sure to call super.onTokenRefresh to initialize Ably environment.
        super.onTokenRefresh();
        String token = FirebaseInstanceId.getInstance().getToken();
        Log.d(AblyPushRegistrationService.class.getSimpleName(), "Push Token received: " + token);

    }
}
