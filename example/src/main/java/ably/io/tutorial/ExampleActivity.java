package ably.io.tutorial;

import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.text.TextUtils;
import android.view.View;
import android.widget.EditText;
import android.widget.Toast;

import io.ably.lib.realtime.AblyRealtime;
import io.ably.lib.realtime.Channel;
import io.ably.lib.realtime.CompletionListener;
import io.ably.lib.types.AblyException;
import io.ably.lib.types.ErrorInfo;
import io.ably.lib.types.Message;
import io.ably.lib.util.Log;

public class ExampleActivity extends AppCompatActivity {

    private final static String API_KEY = "INSERT-YOUR-API-KEY-HERE"; /* Sign up at ably.io to get your API key */

    /* RuntimeException will be thrown if API_KEY will not be set to a proper one */
    static {
        if (API_KEY.contains("INSERT")) {
            throw new RuntimeException("API key is not set, sign up at ably.io to get yours");
        }
    }

    private Channel channel;
    private EditText messageEditText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_example);
        messageEditText = (EditText) findViewById(R.id.etMessage);
        try {
            initAbly();
        } catch (AblyException e) {
            e.printStackTrace();
        }
        findViewById(R.id.btPublish).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                /* Get message content from EditText */
                String message = messageEditText.getEditableText().toString();
                /* Check if message is not empty */
                if (!TextUtils.isEmpty(message)) {
                    try {
                        Toast.makeText(getBaseContext(), "Publishing message...", Toast.LENGTH_SHORT).show();
                        publishMessage(message);
                    } catch (AblyException e) {
                        e.printStackTrace();
                    }
                }
            }
        });
    }

    /* Add AblyException to method signature as AblyRealtime constructor can throw one */
    private void initAbly() throws AblyException {
        AblyRealtime realtime = new AblyRealtime(API_KEY);
        /* Get sport channel you can subscribe to */
        channel = realtime.channels.get("sport");
        channel.subscribe(new Channel.MessageListener() {
            @Override
            public void onMessage(Message messages) {
                /* show a toast when message is received */
                Toast.makeText(getBaseContext(), "Message received: " + messages.data, Toast.LENGTH_SHORT).show();
            }
        });
    }

    /* Add AblyException to method signature as Channel#publish method can throw one */
    private void publishMessage(String message) throws AblyException {

        channel.publish("update", message, new CompletionListener() {
            @Override
            public void onSuccess() {
                /* Show success message when message is sent */
                Toast.makeText(getBaseContext(), "Message sent", Toast.LENGTH_SHORT).show();
            }

            @Override
            public void onError(ErrorInfo reason) {
                /* Show error message when something goes wrong */
                Toast.makeText(getBaseContext(), "Message not sent, error occurred: " + reason.message, Toast.LENGTH_LONG).show();
            }
        });
    }
}
