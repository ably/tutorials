package io.ably.tutorial.push_tutorial_two;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.provider.Settings;
import android.support.annotation.Nullable;
import android.support.v4.content.LocalBroadcastManager;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.google.gson.Gson;

import io.ably.lib.push.LocalDevice;
import io.ably.lib.realtime.AblyRealtime;
import io.ably.lib.realtime.ConnectionStateListener;
import io.ably.lib.types.AblyException;
import io.ably.lib.types.ClientOptions;
import io.ably.lib.types.ErrorInfo;
import io.ably.lib.types.Param;
import io.ably.lib.util.IntentUtils;
import io.ably.tutorial.push_tutorial_two.receivers.AblyPushMessagingService;
import io.ably.tutorial.push_tutorial_two.server.NetResponse;
import io.ably.tutorial.push_tutorial_two.server.ServerAPI;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

/**
 * Created by Amit S.
 */
public class MainActivity extends AppCompatActivity {

    public static final int SUCCESS = 0;
    public static final int FAILURE = 1;
    public static final int UPDATE_LOGS = 2;

    public static final String STEP_1 = "Initialize Ably";
    public static final String STEP_2 = "Register & Subscribe Channels via Server";

    private static final String PRIVATE_SERVER_AUTH_URL = BuildConfig.SERVER_BASE_URL + "/auth";

    //Broadcast receiver actions
    public static final String ABLY_PUSH_ACTIVATE_ACTION = "io.ably.broadcast.PUSH_ACTIVATE";

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
                    stepsButton.setEnabled(true);
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
            if (ABLY_PUSH_ACTIVATE_ACTION.equalsIgnoreCase(intent.getAction())) {
                ErrorInfo error = IntentUtils.getErrorInfo(intent);
                if (error != null) {
                    logMessage("Error activating push service: " + error);
                    handler.sendMessage(handler.obtainMessage(FAILURE));
                    return;
                }
                return;
            }

        }
    };

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        rollingLogs = findViewById(R.id.rolling_logs);
        stepsButton = findViewById(R.id.steps);
        LocalBroadcastManager.getInstance(this).registerReceiver(pushReceiver, new IntentFilter(ABLY_PUSH_ACTIVATE_ACTION));
        LocalBroadcastManager.getInstance(this).registerReceiver(pushReceiver, new IntentFilter(AblyPushMessagingService.PUSH_NOTIFICATION_ACTION));
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
            }
        } catch (AblyException e) {
            logMessage("AblyException " + e.getMessage());
            handler.sendMessage(handler.obtainMessage(FAILURE));
        }
    }

    /**
     * By default we set client ID as the androidID.
     *
     * @return
     */
    private String getClientId() {
        String clientId = Settings.Secure.getString(getContentResolver(), Settings.Secure.ANDROID_ID);
        return clientId;
    }

    /**
     * Step 1: Initialize Ably library and perform authentication with private server
     *
     * @throws AblyException
     */
    private void initAblyRuntime() throws AblyException {

        ClientOptions options = new ClientOptions();
        options.environment = BuildConfig.ABLY_ENV;
        options.key = BuildConfig.ABLY_KEY;
        options.authUrl = PRIVATE_SERVER_AUTH_URL;
        options.authParams = new Param[]{new Param("clientId", getClientId())};

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

    /**
     * Step 2: Register for Push notification through private server.
     * We also subscribe for the required channels on Server for the relevant device Id.
     *
     * @throws AblyException
     */
    private void initAblyPush() throws AblyException {
        LocalDevice device = ablyRealtime.push.getActivationContext().getLocalDevice();
        if (device.push.recipient == null) {
            logMessage("Push not initialized. Please check Firebase settings");
            return;
        }
        String registrationToken = device.push.recipient.get("registrationToken").getAsString();
        if (registrationToken == null || registrationToken.length() == 0) {
            logMessage("Registration token cannot be null. Please check Firebase settings");
            return;
        }
        String deviceId = device.id;
        String clientId = getClientId();

        logMessage("Sending registration Token: " + registrationToken);
        logMessage("Device ID: " + deviceId);
        logMessage("Client ID: " + clientId);
        logMessage("Registering device via Server");
        logMessage("Subscribing channels");

        ServerAPI.getInstance().api().register(deviceId, registrationToken, clientId).enqueue(new Callback<NetResponse>() {
            @Override
            public void onResponse(Call<NetResponse> call, Response<NetResponse> response) {
                //This is where device is successfully registered via Server.
                logMessage("Successfully registered: " + new Gson().toJson(response.body()));
            }

            @Override
            public void onFailure(Call<NetResponse> call, Throwable t) {
                logMessage("Error registering with server: " + t.getMessage());
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
}
