package ably.io.tutorial;

import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;

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

    /* Add AblyException to method signature as AblyRest constructor can throw one */
    private void initAbly() throws AblyException {
        AblyRealtime ablyRealtime = new AblyRealtime(API_KEY);
    }
}
