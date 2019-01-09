package com.android.ably.pushdemo;

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
import io.ably.lib.realtime.ConnectionState;
import io.ably.lib.realtime.ConnectionStateListener;
import io.ably.lib.rest.Auth;
import io.ably.lib.types.AblyException;
import io.ably.lib.types.ClientOptions;


public class TestActivity extends Activity {

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

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_example);

        textView = (TextView)findViewById(R.id.editText1);
        logger   = new TextViewLogger(textView);

        preferences = PreferenceManager.getDefaultSharedPreferences(this);
        setUI();

        try {
            initAbly();
        } catch (AblyException e) {
            e.printStackTrace();
        }
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
                        authenticate(etClientId.getEditableText().toString());
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
                        authenticate(null);
                    }
                }).start();
            }
        });
    }

    private void authenticate(String clientId) {
        final Auth.TokenParams params = new Auth.TokenParams();
        params.clientId = clientId;
        try {
            ablyRealtime.auth.requestToken(params, null);
        } catch (AblyException e) {
            e.printStackTrace();
        }
    }


    private void initAbly() throws AblyException {
        ClientOptions clientOptions = new ClientOptions(apiKey);
        clientOptions.environment = "production";
        clientOptions.logLevel = io.ably.lib.util.Log.VERBOSE;
        clientOptions.authCallback = new Auth.TokenCallback() {

            @Override
            public Object getTokenRequest(Auth.TokenParams tokenParams) throws AblyException {
                if (firstStart) {
                    firstStart = false;
                    String clientId = preferences.getString("clientId", null);
                    if (clientId != null) {
                        tokenParams.clientId = tokenRequest.clientId;
                    }
                }

                String httpAuthResponse = sendRequestToServer(tokenParams.clientId);
                tokenRequest = new Gson().fromJson(httpAuthResponse, Auth.TokenRequest.class);
                preferences.edit().putString("clientId", httpAuthResponse).commit();
                setButtonsState();
                return tokenRequest;
            }
        };
        ablyRealtime = new AblyRealtime(clientOptions);
        ablyRealtime.setAndroidContext(this);

        ablyRealtime.connection.once(ConnectionState.connected, new ConnectionStateListener() {
            @Override
            public void onConnectionStateChanged(ConnectionStateListener.ConnectionStateChange state) {
                /* Always do UI updates on UI thread */
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {

                        String user = ablyRealtime.auth.clientId;
                        String capability = ablyRealtime.auth.getTokenDetails().capability;
                        Toast.makeText(getBaseContext(), "You are now connected to Ably \n" +
                                "User: " + user + " \n" +
                                "Capabilities: " + capability, Toast.LENGTH_SHORT).show();
                    }
                });
            }
        });


    }

    private String sendRequestToServer(String clientId) {
        RequestQueue queue = Volley.newRequestQueue(getBaseContext());
        RequestFuture<String> future = RequestFuture.newFuture();
        /* 10.0.2.2 is the IP address of localhost seen from emulator's perspective */
        String url = "http://10.0.2.2:3000/auth?username="+clientId;
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

    private String generateRunId(){
        runId = java.util.UUID.randomUUID().toString();
        channelName = channelName(runId);
        return runId;
    }

    private String channelName(String runId) {
        return "push:test_push_channel_" + runId;
    }

    private boolean activatePush(boolean wait) throws AblyException {
        logger.i("activatePush()", "initialising Firebase");
        String token = FirebaseInstanceId.getInstance().getToken();
        logger.i("activatePush()", "activating push system .. waiting");
        ablyRealtime.push.activate();

        if(wait) {
            /* FIXME: wait for actual state change */
            try {
                Thread.sleep(4000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        logger.i("activatePush()", ".. activated push system");
        return true;
    }

    private void setButtonsState() {
        runOnUiThread(new Runnable() {
            public void run() {
                etClientId.setText(tokenRequest.clientId);
                tvCapabilities.setText(tokenRequest.capability);
                findViewById(R.id.btLogin).setVisibility(tokenRequest.clientId == null ? View.VISIBLE : View.GONE);
                findViewById(R.id.etClientId).setEnabled(tokenRequest.clientId == null);
                findViewById(R.id.btLogout).setVisibility(tokenRequest.clientId == null ? View.GONE : View.VISIBLE);

                generateRunId();
                try {
                    activatePush(true);
                } catch (AblyException e) {
                    e.printStackTrace();
                }
            }
        });
    }
}
