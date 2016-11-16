package ably.io.tutorial;

import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
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

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_example);
        try {
            initAbly();
        } catch (AblyException e) {
            e.printStackTrace();
        }
    }

    private void initAbly() throws AblyException {
        ClientOptions clientOptions = new ClientOptions();
        clientOptions.authCallback = new Auth.TokenCallback() {

            @Override
            public Object getTokenRequest(Auth.TokenParams tokenParams) throws AblyException {
                /* issue synchronous query to obtain token request */
                String httpAuthResponse = sendRequestToServer();
                tokenRequest = new Gson().fromJson(httpAuthResponse, Auth.TokenRequest.class);
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
                        Toast.makeText(getBaseContext(), "We're connected using the token request from the server /auth endpoint!", Toast.LENGTH_SHORT).show();
                    }
                });
            }
        });
    }

    private String sendRequestToServer() {
        RequestQueue queue = Volley.newRequestQueue(getBaseContext());
        RequestFuture<String> future = RequestFuture.newFuture();
        /* 10.0.2.2 is the IP address of localhost seen from emulator's perspective */
        String url = "http://10.0.2.2:3000/auth";
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

}
