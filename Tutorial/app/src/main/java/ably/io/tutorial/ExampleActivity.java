package ably.io.tutorial;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.android.volley.RequestQueue;
import com.android.volley.toolbox.RequestFuture;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.google.gson.Gson;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import io.ably.lib.realtime.AblyRealtime;
import io.ably.lib.realtime.ConnectionState;
import io.ably.lib.realtime.ConnectionStateListener;
import io.ably.lib.rest.Auth;
import io.ably.lib.types.AblyException;
import io.ably.lib.types.ClientOptions;

public class ExampleActivity extends AppCompatActivity {

    private AblyRealtime ablyRealtime;
    private Auth.TokenRequest tokenRequest;
    private TextView tvCapabilities;
    private EditText etClientId;
    private SharedPreferences preferences;
    private boolean firstStart = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_example);
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

    /* ask client library to authenticate user and request token*/
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
        ClientOptions clientOptions = new ClientOptions();
        clientOptions.authCallback = new Auth.TokenCallback() {

            @Override
            public Object getTokenRequest(Auth.TokenParams tokenParams) throws AblyException {
                /* check SharedPreferences if there was a user logged in previous session only once */
                if (firstStart) {
                    firstStart = false;
                    String clientId = preferences.getString("clientId", null);
                    if (clientId != null) {
                        tokenParams.clientId = tokenRequest.clientId;
                    }
                }

                /* issue synchronous query to obtain token request */
                String httpAuthResponse = sendRequestToServer(tokenParams.clientId);
                tokenRequest = new Gson().fromJson(httpAuthResponse, Auth.TokenRequest.class);
                /* save clientId to manage state of the app */
                preferences.edit().putString("clientId", httpAuthResponse).commit();
                setButtonsState();
                return tokenRequest;
            }
        };
        ablyRealtime = new AblyRealtime(clientOptions);
        ablyRealtime.connection.once(ConnectionState.connected, new ConnectionStateListener() {
            @Override
            public void onConnectionStateChanged(ConnectionStateChange connectionStateChange) {
                /* always run UI work inside UI thread */
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        /* display message when connection is established */
                        String clientId = ablyRealtime.auth.getTokenAuth().getTokenDetails().clientId;
                        String capability = ablyRealtime.auth.getTokenAuth().getTokenDetails().capability;
                        Toast.makeText(getBaseContext(), "Connected to Ably.io\n"
                                + "User: " + clientId
                                + "Capability: " + capability, Toast.LENGTH_SHORT).show();
                    }
                });
            }
        });
    }

    private String sendRequestToServer(String clientId) {
        RequestQueue queue = Volley.newRequestQueue(getBaseContext());
        RequestFuture<String> future = RequestFuture.newFuture();
        String suffix = "";
        if (clientId != null) {
            suffix = "?username=" + clientId;
        }
        /* 10.0.2.2 is the IP address of localhost seen from emulator's perspective */
        String url = "http://10.0.2.2:3000/auth" + suffix;
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

    /* fill UI with useful information, change states of buttons */
    private void setButtonsState() {
        runOnUiThread(new Runnable() {
            public void run() {
                etClientId.setText(tokenRequest.clientId);
                tvCapabilities.setText(tokenRequest.capability);
                findViewById(R.id.btLogin).setVisibility(tokenRequest.clientId == null ? View.VISIBLE : View.GONE);
                findViewById(R.id.etClientId).setEnabled(tokenRequest.clientId == null);
                findViewById(R.id.btLogout).setVisibility(tokenRequest.clientId == null ? View.GONE : View.VISIBLE);
            }
        });
    }
}
