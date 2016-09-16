package ably.io.tutorial;


import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.Toast;

import io.ably.lib.realtime.AblyRealtime;
import io.ably.lib.realtime.Channel;
import io.ably.lib.types.AblyException;

public class ExampleActivity extends AppCompatActivity {

    private final static String API_KEY = "INSERT-YOUR-API-KEY-HERE"; /* Sign up at ably.io to get your API key */

    /* RuntimeException will be thrown if API_KEY will not be set to a proper one */
    static {
        if (API_KEY.contains("INSERT")) {
            throw new RuntimeException("API key is not set, sign up at ably.io to get yours");
        }
    }

    private Channel channel; /* add field for Channel */

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_example);
        try {
            initAbly();
        } catch (AblyException e) {
            e.printStackTrace();
        }

        /* set a button click listener for publishing messages */
        findViewById(R.id.btPublish).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Toast.makeText(getBaseContext(), "Publishing three messages...", Toast.LENGTH_SHORT).show();
                /* Always do network instructions outside the Main Thread */
                new Thread(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            /* Wrap method in try/catch block to prevent application from crashing due to AblyException */
                            publishMessages();
                        } catch (AblyException e) {
                            e.printStackTrace();
                        }
                    }
                }).start();
            }
        });
    }

    /* Add AblyException to method signature as AblyRest constructor can throw one */
    private void initAbly() throws AblyException {
        AblyRealtime ablyRealtime = new AblyRealtime(API_KEY);
        /* Get channel for storing sounds */
        channel = ablyRealtime.channels.get("persisted:sounds");
    }

    private void publishMessages() throws AblyException {
        /* Publish three messages, specify event name first, then payload */
        channel.publish("play", "bark");
        channel.publish("play", "meow");
        channel.publish("play", "cluck");

        /* Always do UI work inside UI Thread */
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(getBaseContext(), "Messages sent", Toast.LENGTH_SHORT).show();
            }
        });
    }
}
