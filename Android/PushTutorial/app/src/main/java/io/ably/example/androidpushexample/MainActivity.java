package io.ably.example.androidpushexample;

import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;

import io.ably.lib.realtime.AblyRealtime;
import io.ably.lib.realtime.ConnectionStateListener;
import io.ably.lib.types.AblyException;
import io.ably.lib.types.ClientOptions;

/**
 * Created by Amit S.
 */
public class MainActivity extends AppCompatActivity {

    private AblyRealtime ablyRealtime;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        initAblyRuntime();
    }

    private void initAblyRuntime() {
        try {
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
                            break;
                        case disconnected:
                        case failed:
                            //do something
                            break;

                    }
                }
            });
        } catch (AblyException e) {
            e.printStackTrace();
        }
    }

    private void logMessage(String message) {
        Log.i(MainActivity.class.getSimpleName(), message);
    }
}
