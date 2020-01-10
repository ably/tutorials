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
        // We will fill this in the next step
    }
    public void deactivatePush(View view) {
        // We will fill this in the next step
    }
}