package ably.io.application

import ably.io.application.databinding.ActivityExampleBinding
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import io.ably.lib.realtime.AblyRealtime
import io.ably.lib.realtime.Channel
import io.ably.lib.types.AblyException
import io.ably.lib.types.Message
import io.ably.lib.types.PaginatedResult

class ExampleActivity : AppCompatActivity() {
    private lateinit var activityExampleBinding: ActivityExampleBinding

    private val API_KEY = "INSERT-YOUR-API-KEY-HERE" /* Sign up at ably.io to get your API key */

    private var channel: Channel? = null /* add field for Channel */

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        activityExampleBinding = ActivityExampleBinding.inflate(layoutInflater)
        setContentView(activityExampleBinding.root)

        /* RuntimeException will be thrown if API_KEY will not be set to a proper one */
        if (API_KEY.contains("INSERT")) {
            throw RuntimeException("API key is not set, sign up at ably.io to get yours")
        }

        try {
            initAbly()
        } catch (e: AblyException) {
            e.printStackTrace()
        }

        activityExampleBinding.btPublish.setOnClickListener {
            if (channel !== null) {
                Toast.makeText(baseContext, "Publishing three messages...", Toast.LENGTH_SHORT)
                    .show()

                /* Always do network instructions outside the Main Thread */
                Thread {
                    try {
                        /* Wrap method in try/catch block to prevent application from crashing due to AblyException */
                        publishMessages()
                    } catch (e: AblyException) {
                        e.printStackTrace()
                    }
                }.start()
            }
        }

        /* set a button click listener for fetching channel history */
        activityExampleBinding.btHistory.setOnClickListener {
            if (channel !== null) {
                Toast.makeText(
                    baseContext,
                    "Retrieving channel's history...",
                    Toast.LENGTH_SHORT
                )
                    .show()
                /* Always do network instructions outside the Main Thread */
                Thread {
                    try {
                        fetchHistory()
                    } catch (e: AblyException) {
                        e.printStackTrace()
                    }
                }.start()
            }
        }
    }

    /* Add AblyException to method signature as AblyRest constructor can throw one */
    @Throws(AblyException::class)
    private fun initAbly() {
        val ablyRealtime = AblyRealtime(API_KEY)

        /* Get channel for storing sounds */
        channel = ablyRealtime.channels.get("persisted:sounds")
    }

    @Throws(AblyException::class)
    private fun publishMessages() {
        /* Publish three messages, specify event name first, then payload */
        if (channel !== null) {
            channel?.publish("play", "bark")
            channel?.publish("play", "meow")
            channel?.publish("play", "cluck")

            /* Always do UI work inside UI Thread */
            runOnUiThread {
                Toast.makeText(
                    baseContext,
                    "Messages sent",
                    Toast.LENGTH_SHORT
                ).show()
            }
        }
    }

    @Throws(AblyException::class)
    private fun fetchHistory() {
        /* Fetch historical messages from channel, you can customize history query with parameters, when no parameters are needed just pass null */
        val historicMessages: PaginatedResult<Message>? = channel?.history(null)

        if (historicMessages !== null) {
            for (message in historicMessages.items()) {
                /* Always do UI work inside UI Thread */
                runOnUiThread {
                    Toast.makeText(
                        baseContext,
                        "message: " + message.id + " - " + message.data,
                        Toast.LENGTH_SHORT
                    ).show()
                }
            }
        }
    }

}