package com.example.pushtutorial;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.provider.Settings;
import android.util.Log;
import android.view.View;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import com.example.pushtutorial.receivers.AblyPushMessagingService;

import io.ably.lib.realtime.AblyRealtime;
import io.ably.lib.realtime.CompletionListener;
import io.ably.lib.realtime.ConnectionStateListener;
import io.ably.lib.types.AblyException;
import io.ably.lib.types.ClientOptions;
import io.ably.lib.types.ErrorInfo;
import io.ably.lib.util.IntentUtils;

public class MainActivity extends AppCompatActivity {
    private AblyRealtime ablyRealtime;
    private TextView rollingLogs;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        rollingLogs = findViewById(R.id.rolling_logs);
        try {
            initAblyRuntime();
        } catch (AblyException e) {
            logMessage("AblyException " + e.getMessage());
        }
    }
    /**
     * Step 1: Initialize Ably Runtime
     *
     * @throws AblyException
     */
    private void initAblyRuntime() throws AblyException {
        ClientOptions options = new ClientOptions();
        options.key = "YOUR_API_KEY";
        options.clientId = Settings.Secure.getString(getContentResolver(), Settings.Secure.ANDROID_ID);
        ablyRealtime = new AblyRealtime(options);
        ablyRealtime.setAndroidContext(getApplicationContext());
        ablyRealtime.connect();
        LocalBroadcastManager.getInstance(this).registerReceiver(pushReceiver, new IntentFilter("io.ably.broadcast.PUSH_ACTIVATE"));
        LocalBroadcastManager.getInstance(this).registerReceiver(pushReceiver, new IntentFilter(AblyPushMessagingService.PUSH_NOTIFICATION_ACTION));
        ablyRealtime.connection.on(new ConnectionStateListener() {
            @Override
            public void onConnectionStateChanged(ConnectionStateChange state) {
                logMessage("Connection state changed to : " + state.current.name());
                switch (state.current) {
                    case connected:
                        logMessage("Connected to Ably with clientId " + ablyRealtime.auth.clientId);
                        break;
                }
            }
        });
    }
    private void logMessage(String message) {
        Log.i(MainActivity.class.getSimpleName(), message);
        rollingLogs.append(message);
        rollingLogs.append("\n");
    }

    public void activatePush(View view) {
        try {
            ablyRealtime.push.activate();
        } catch (AblyException e) {
            logMessage("AblyException activating push: " + e.getMessage());
        }
    }

    public void deactivatePush(View view) {
        try {
            logMessage("Deactivating Push on device");
            ablyRealtime.push.deactivate();
        } catch (AblyException e){
            logMessage("AblyException deactivating push: " + e.getMessage());
        }
    }

    private BroadcastReceiver pushReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if ("io.ably.broadcast.PUSH_ACTIVATE".equalsIgnoreCase(intent.getAction())) {
                ErrorInfo error = IntentUtils.getErrorInfo(intent);
                if (error!=null) {
                    logMessage("Error activating push service: " + error);
                    return;
                }
                try {
                    logMessage("Device is now registered for push with deviceId " + deviceId());
                    subscribeChannels();
                } catch(AblyException e) {
                    logMessage("AblyException getting deviceId: " + e);
                }
                return;
            }
            if (AblyPushMessagingService.PUSH_NOTIFICATION_ACTION.equalsIgnoreCase(intent.getAction())) {
                logMessage("Received Push message");
            }
        }
    };
    private String deviceId() throws AblyException {
        return ablyRealtime.device().id;
    }
    private void subscribeChannels() {
        ablyRealtime.channels.get("push:test_push_channel").push.subscribeClientAsync(new CompletionListener() {
            @Override
            public void onSuccess() {
                logMessage("Subscribed to push for the channel");
            }
            @Override
            public void onError(ErrorInfo reason) {
                logMessage("Error subscribing to push channel " + reason.message);
                logMessage("Visit link for more details: " + reason.href);
            }
        });
    }
}