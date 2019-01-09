package com.android.ably.pushdemo;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.support.v7.app.AppCompatActivity;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.google.firebase.iid.FirebaseInstanceId;
import com.google.gson.Gson;

import java.util.HashMap;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import com.android.volley.RequestQueue;
import com.android.volley.toolbox.RequestFuture;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.google.gson.Gson;

import org.w3c.dom.Text;

import io.ably.lib.realtime.AblyRealtime;
import io.ably.lib.realtime.Channel;
import io.ably.lib.realtime.CompletionListener;
import io.ably.lib.realtime.ConnectionState;
import io.ably.lib.realtime.ConnectionStateListener;
import io.ably.lib.rest.Auth;
import io.ably.lib.types.AblyException;
import io.ably.lib.types.ClientOptions;
import io.ably.lib.types.ErrorInfo;


public class AblyServerLoginActivity extends AppCompatActivity {

    AblyRealtime ablyRealtime;

    private TextView tvCapabilities;
    private EditText etClientId;
    private SharedPreferences preferences;
    private boolean firstStart = true;

    private  Auth.TokenRequest tokenRequest;

    private String  apiKey      = "FJWZrQ.swLeTg:_R4gkfPIxXcj3tRy";
    private String  environment = "production";

    private String runId;
    private String channelName;

    private TextView textView;
    private TextViewLogger logger;
    private ErrorInfo error = null;
    private PushReceiver pushMessageReceiver;

    private class PushReceiver extends BroadcastReceiver {

        private final Object lock = new Object();
        private String action = "";
        private String runId = "";

        @Override
        public void onReceive(Context context, Intent intent) {

            HashMap<String, String> pushData = (HashMap<String, String>) intent.getSerializableExtra("data");
            synchronized (lock) {
                this.action = intent.getAction();
                this.runId = pushData.get("runId");
                lock.notifyAll();
            }
            onPushMessageReceived(this.action, pushData);
        }
    }

    private void onPushMessageReceived(String action, HashMap<String, String>data) {
        System.out.println(" push message received...." + data);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_example);

        textView = (TextView)findViewById(R.id.editText1);
        logger   = new TextViewLogger(textView);

        preferences = PreferenceManager.getDefaultSharedPreferences(this);
        setUI();
        registerReceiver();
    }

    private void setUI() {
        etClientId = (EditText) findViewById(R.id.etClientId);
        tvCapabilities = (TextView) findViewById(R.id.tvCapabilities);
        findViewById(R.id.btLogin).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        String result = authenticate(etClientId.getEditableText().toString(), "\"01D0BY616FCSGB14N5ZPYG0ZVY\"");
                        if(result != null) {
                            System.out.println(" what is result  " + result);
                            setButtonsState();
                        }
                    }
                }).start();
            }
        });
        findViewById(R.id.btLogout).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        authenticate(null, "");
                    }
                }).start();
            }
        });

    }

    private String authenticate(String clientId, String deviceId) {
        RequestQueue queue = Volley.newRequestQueue(getBaseContext());
        RequestFuture<String> future = RequestFuture.newFuture();
        /* 10.0.2.2 is the IP address of localhost seen from emulator's perspective */
        String url = "http://10.0.2.2:3000/login?clientId="+clientId+"&deviceId="+ deviceId;
        StringRequest request = new StringRequest(url, future, future);
        queue.add(request);
        try {
            /* return response from server with timeout set to 3 seconds */
            return future.get(3, TimeUnit.SECONDS);
        } catch (InterruptedException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
        }
        return null;
    }

    private void registerReceiver() {
        pushMessageReceiver = new PushReceiver();
        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(AblyPushMessagingService.PUSH_DATA_ACTION);
        intentFilter.addAction(AblyPushMessagingService.PUSH_NOTIFICATION_ACTION);
        registerReceiver(pushMessageReceiver, intentFilter);
    }

    private void setButtonsState() {
        runOnUiThread(new Runnable() {
            public void run() {
//                etClientId.setText(tokenRequest.clientId);
//                tvCapabilities.setText(tokenRequest.capability);
//                findViewById(R.id.btLogin).setVisibility(tokenRequest.clientId == null ? View.VISIBLE : View.GONE);
//                findViewById(R.id.etClientId).setEnabled(tokenRequest.clientId == null);
//                findViewById(R.id.btLogout).setVisibility(tokenRequest.clientId == null ? View.GONE : View.VISIBLE);

            }
        });
    }

}
