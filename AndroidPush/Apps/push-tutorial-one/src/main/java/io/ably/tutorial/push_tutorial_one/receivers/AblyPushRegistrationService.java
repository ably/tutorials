package io.ably.tutorial.push_tutorial_one.receivers;

import io.ably.lib.push.AblyFirebaseInstanceIdService;

/**
 * Leave this empty as the base class AblyFirebaseInstanceIdService does the FCM token registration.
 * In case your app requires access to FCM token as well, then override io.ably.lib.push.AblyFirebaseInstanceIdService#onTokenRefresh()
 */
public class AblyPushRegistrationService extends AblyFirebaseInstanceIdService {
    @Override
    public void onTokenRefresh() {
        //Make sure to call super.onTokenRefresh to initialize Ably push environment.
        super.onTokenRefresh();
    }
}
