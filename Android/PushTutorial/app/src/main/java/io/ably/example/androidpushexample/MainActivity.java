package io.ably.example.androidpushexample;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.support.annotation.Nullable;
import android.support.v4.content.LocalBroadcastManager;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import io.ably.lib.realtime.AblyRealtime;
import io.ably.lib.realtime.CompletionListener;
import io.ably.lib.realtime.ConnectionStateListener;
import io.ably.lib.types.AblyException;
import io.ably.lib.types.ClientOptions;
import io.ably.lib.types.ErrorInfo;
import io.ably.lib.util.IntentUtils;

/**
 * Created by Amit S.
 */
public class MainActivity extends AppCompatActivity {

    public static final int SUCCESS = 0;
    public static final int FAILURE = 1;
    public static final int UPDATE_LOGS = 2;

    public static final String STEP_1 = "Initialize Ably";
    public static final String STEP_2 = "Activate Push";
    public static final String STEP_3 = "Subscribe Push Channel";
    public static final String STEP_4 = "Send Push";

    public static final String TEST_PUSH_CHANNEL = "test_push_channel";
    private TextView rollingLogs;
    private Button stepsButton;
    private StringBuilder logs = new StringBuilder();
    private AblyRealtime ablyRealtime;


    private Handler handler = new Handler(new Handler.Callback() {
        @Override
        public boolean handleMessage(Message msg) {
            switch (msg.what) {
                case SUCCESS:
                    stepsButton.setText((String) msg.obj);
                    stepsButton.setEnabled(true);
                    break;
                case FAILURE:
                    stepsButton.setEnabled(false);
                    break;
                case UPDATE_LOGS:
                    rollingLogs.setText(logs.toString());
                    break;
            }
            return false;
        }
    });

    private BroadcastReceiver pushReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            ErrorInfo error = IntentUtils.getErrorInfo(intent);
            if (error != null) {
                logMessage("Error activating push service: " + error);
                handler.sendMessage(handler.obtainMessage(FAILURE));
                return;
            }

            logMessage("Device is now registered for push");
            handler.sendMessage(handler.obtainMessage(SUCCESS, STEP_3));
        }
    };

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        rollingLogs = findViewById(R.id.rolling_logs);
        stepsButton = findViewById(R.id.steps);
    }


    private void initAblyRuntime() throws AblyException {

        ClientOptions options = new ClientOptions();
        options.environment = BuildConfig.ABLY_ENV;
        options.key = BuildConfig.ABLY_KEY;

        ablyRealtime = new AblyRealtime(options);
        ablyRealtime.setAndroidContext(getApplicationContext());
        ablyRealtime.connect();

        ablyRealtime.connection.on(new ConnectionStateListener() {
            @Override
            public void onConnectionStateChanged(ConnectionStateChange state) {
                logMessage("Connection state changed to : " + state.current.name());
                switch (state.current) {
                    case connected:
                        //Go to step 2
                        handler.sendMessage(handler.obtainMessage(SUCCESS, STEP_2));
                        break;
                    case disconnected:
                    case failed:
                        handler.sendMessage(handler.obtainMessage(FAILURE));
                        break;

                }
            }
        });

    }

    private void initAblyPush() throws AblyException {
        LocalBroadcastManager.getInstance(this).registerReceiver(pushReceiver, new IntentFilter("io.ably.broadcast.PUSH_ACTIVATE"));
        ablyRealtime.push.activate();
    }

    private void subscribleChannels() {

        ablyRealtime.channels.get(TEST_PUSH_CHANNEL).push.subscribeClientAsync(new CompletionListener() {
            @Override
            public void onSuccess() {
                logMessage("Subscribed to push for the channel " + TEST_PUSH_CHANNEL);
                handler.sendMessage(handler.obtainMessage(SUCCESS, STEP_4));
            }

            @Override
            public void onError(ErrorInfo reason) {
                logMessage("Error subscribing to push channel " + reason.message);
                logMessage("Visit link for more details: " + reason.href);
                handler.sendMessage(handler.obtainMessage(FAILURE));
            }
        });

    }

    private void logMessage(String message) {
        Log.i(MainActivity.class.getSimpleName(), message);
        logs.append(message);
        logs.append("\n");
        handler.sendMessage(handler.obtainMessage(UPDATE_LOGS));

    }

    public void performAction(View view) {
        try {
            Button button = (Button) view;
            button.setEnabled(false);
            String step = button.getText().toString();
            logMessage("Performing Step: " + step);
            switch (step) {
                case STEP_1:
                    initAblyRuntime();
                    break;
                case STEP_2:
                    initAblyPush();
                    break;
                case STEP_3:
                    subscribleChannels();
                    break;
            }
        } catch (AblyException e) {
            logMessage("AblyException " + e.getMessage());
            handler.sendMessage(handler.obtainMessage(FAILURE));
        }
    }
}
