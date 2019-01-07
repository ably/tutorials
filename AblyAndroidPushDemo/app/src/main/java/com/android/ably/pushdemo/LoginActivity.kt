package com.android.ably.pushdemo

import android.app.Activity
import android.content.*
import android.os.Bundle
import android.preference.PreferenceManager
import android.view.View
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast

import com.google.gson.Gson

import java.util.concurrent.ExecutionException
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

import com.android.volley.RequestQueue
import com.android.volley.toolbox.RequestFuture
import com.android.volley.toolbox.StringRequest
import com.android.volley.toolbox.Volley
import com.google.firebase.iid.FirebaseInstanceId
import com.google.gson.JsonObject
import com.google.gson.JsonPrimitive

import io.ably.lib.realtime.AblyRealtime
import io.ably.lib.realtime.CompletionListener
import io.ably.lib.realtime.ConnectionState
import io.ably.lib.rest.Auth
import io.ably.lib.types.AblyException
import io.ably.lib.types.ClientOptions
import io.ably.lib.types.ErrorInfo
import io.ably.lib.types.Message
import java.util.HashMap


class LoginActivity : Activity() {

    lateinit var ablyRealtime: AblyRealtime

    private var tvCapabilities: TextView? = null
    private var etClientId: EditText? = null
    private var preferences: SharedPreferences? = null
    private var firstStart = true

    private var alreadyDone = false

    private var tokenRequest: Auth.TokenRequest? = null

    private val apiKey = "FJWZrQ.swLeTg:_R4gkfPIxXcj3tRy"
    private val environment = "sandbox"

    lateinit var textView: TextView
    lateinit var logger: TextViewLogger
    lateinit var pushMessageReceiver: LoginActivity.PushReceiver

    var runId = ""
    var channelName = ""

    inner class PushReceiver : BroadcastReceiver() {
        private val lock:Object = Object()
        private var action:String = ""
        private var runId:String = ""
        override fun onReceive(context: Context?, intent: Intent?) {
            val pushData : HashMap<String, String> = intent!!.getSerializableExtra("data") as HashMap<String, String>
            synchronized(lock) {
                this.action = intent!!.action
                this.runId = pushData.get("runId")!!
                lock.notifyAll()
            }
            onPushMessageReceived(this.action, pushData)
        }

        fun waitFor(action:String, runId:String) = synchronized(lock) {
            while(action != this.action || runId != this.runId) {
                lock.wait()
            }
        }
    }


    fun generateRunId():String {
        runId = java.util.UUID.randomUUID().toString()
        channelName = channelName(runId)
        return runId
    }

    fun channelName(runId:String):String {
        return "push:test_push_channel_${runId}"
    }

    fun onPushMessageReceived(action: String, data: HashMap<String, String>) {
        val actionString = when(action) {
            AblyPushMessagingService.PUSH_DATA_ACTION -> "push message"
            AblyPushMessagingService.PUSH_NOTIFICATION_ACTION -> "push notification"
            else -> "unknown"
        }
        logger.i("onPushMessageReceived()", "${actionString} received:")
        data.forEach { (key, value) -> logger.i(" - ", "$key = $value") }
    }

    fun registerReceiver() {
        pushMessageReceiver = PushReceiver()
        val intentFilter = IntentFilter()
        intentFilter.addAction(AblyPushMessagingService.PUSH_DATA_ACTION)
        intentFilter.addAction(AblyPushMessagingService.PUSH_NOTIFICATION_ACTION)
        registerReceiver(pushMessageReceiver, intentFilter)
    }

    fun activatePush(wait:Boolean = false):Boolean {

        /* activate Firebase */
        logger.i("activatePush()", "initialising Firebase")
        //FirebaseInstanceId.getInstance().getToken()
        AblyPushRegistrationService.onNewRegistrationToken(this, FirebaseInstanceId.getInstance().getToken())
        /* ensure the Ably library registers any new token with the server */
        logger.i("activatePush()", "activating push system .. waiting")
        ablyRealtime.push.activate()
        if(wait) {
            /* FIXME: wait for actual state change */
            Thread.sleep(4000)
        }
        logger.i("activatePush()", ".. activated push system")
        return true
    }

    fun pushSubscribe(testChannelName:String = channelName, wait:Boolean = true):Boolean {
        logger.i("pushSubscribe()", "push subscribing to channel")
        System.out.println(" channel name " + channelName)
        val channel = ablyRealtime.channels.get(testChannelName)
        val waiter = Object()
        var error: ErrorInfo? = null
        synchronized(waiter) {
            channel.push.subscribeDeviceAsync(object: CompletionListener {
                override fun onSuccess() {
                    logger.i("pushSubscribe()", "subscribe success")
                    synchronized(waiter) {waiter.notify()}
                }
                override fun onError(reason: ErrorInfo?) {
                    logger.e("pushSubscribe()", "failed: err: " + reason!!.message)
                    synchronized(waiter) {error = reason; waiter.notify()}
                }
            })
            if(wait) {
                logger.i("pushSubscribe()", "waiting for push subscription to channel ..")
                waiter.wait()
                logger.i("pushSubscribe()", ".. push subscription complete")
            }
        }
        if(error != null) {
            throw AblyException.fromErrorInfo(error)
        }
        return true
    }

    fun pushPublishData(testRunId:String = runId, wait:Boolean = false):Boolean {
        logger.i("pushPublishData()", "pushing data message to channel")
        val channel = ablyRealtime.channels.get(channelName(testRunId))
        val data = JsonObject()
        data.add("testKey", JsonPrimitive("testValuePublish"))
        data.add("runId", JsonPrimitive(testRunId))
        val payload = JsonObject()
        payload.add("data", data)
        val extras = JsonObject()
        extras.add("push", payload)
        val message = Message("testMessageName", "testMessageData", extras)

        val waiter = Object()
        var error:ErrorInfo? = null
        synchronized(waiter) {
            channel.publish(message, object: CompletionListener {
                override fun onSuccess() {
                    logger.i("pushPublishData()", "publish success")
                    synchronized(waiter) {waiter.notify()}
                }
                override fun onError(reason: ErrorInfo?) {
                    logger.e("pushPublishData()", "failed: err: " + reason!!.message)
                    synchronized(waiter) {error = reason; waiter.notify()}
                }
            })
            if(wait) {
                logger.i("pushPublishData()", "waiting for push publish to channel ..")
                waiter.wait()
                logger.i("pushPublishData()", ".. push publish complete")
            }
        }
        if(error != null) {
            throw AblyException.fromErrorInfo(error)
        }
        return true
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_example)

        textView = findViewById(R.id.editText1) as TextView
        logger = TextViewLogger(textView);

        preferences = PreferenceManager.getDefaultSharedPreferences(this)
        setUI()

        try {
            initAbly()
        } catch (e: AblyException) {
            e.printStackTrace()
        }

    }

    private fun setUI() {
        etClientId = findViewById<View>(R.id.etClientId) as EditText
        tvCapabilities = findViewById<View>(R.id.tvCapabilities) as TextView
        findViewById<View>(R.id.btLogin).setOnClickListener { Thread(Runnable { authenticate(etClientId!!.editableText.toString()) }).start() }
        findViewById<View>(R.id.btLogout).setOnClickListener { Thread(Runnable { authenticate(null) }).start() }

        findViewById<View>(R.id.pushSubscribe).setOnClickListener { Thread(Runnable { pushSubscribe() }).start() }
    }

    private fun authenticate(clientId: String?) {
        val params = Auth.TokenParams()
        params.clientId = clientId
        try {
            ablyRealtime.auth.requestToken(params, null)
        } catch (e: AblyException) {
            e.printStackTrace()
        }
    }


    @Throws(AblyException::class)
    private fun initAbly() {
        val clientOptions = ClientOptions(apiKey)
        clientOptions.environment = "production"
        clientOptions.logLevel = io.ably.lib.util.Log.VERBOSE
        clientOptions.authCallback = Auth.TokenCallback { tokenParams ->
            if (firstStart) {
                firstStart = false
                var clientId = preferences!!.getString("clientId", null)
                if (clientId != null) {

                    tokenParams.clientId =  tokenRequest!!.clientId

                }
            }

               if(!alreadyDone) {
                   val httpAuthResponse = sendRequestToServer(tokenParams.clientId)
                   tokenRequest = Gson().fromJson(httpAuthResponse, Auth.TokenRequest::class.java)
                   preferences!!.edit().putString("clientId", httpAuthResponse).commit()
                   setButtonsState()
                   tokenRequest
               }

        }
        ablyRealtime = AblyRealtime(clientOptions)
        ablyRealtime.setAndroidContext(this)

        ablyRealtime.connection.once(ConnectionState.connected) {
            /* Always do UI updates on UI thread */
            logger.i("initAbly()", "connected")
            runOnUiThread {
                val user = ablyRealtime.auth.clientId
                val capability = ablyRealtime.auth.tokenDetails.clientId
                Toast.makeText(baseContext, "You are now connected to Ably \n" +
                        "User: " + user + " \n" +
                        "Capabilities: " + capability, Toast.LENGTH_SHORT).show()

                logger.i("initAbly", "You are now connected to Ably \n" +
                        "User: " + user + " \n" +
                "Capabilities: " + capability);
            }
        }
    }

    private fun sendRequestToServer(clientId: String): String? {
        val queue = Volley.newRequestQueue(baseContext)
        val future = RequestFuture.newFuture<String>()
        /* 10.0.2.2 is the IP address of localhost seen from emulator's perspective */
        val url = "http://10.0.2.2:3000/auth?username="+clientId
        val request = StringRequest(url, future, future)
        queue.add(request)
        try {
            /* return response from server with timeout set to 3 seconds */
            return future.get(3, TimeUnit.SECONDS)
        } catch (e: InterruptedException) {
            e.printStackTrace()
        } catch (e: ExecutionException) {
            e.printStackTrace()
        } catch (e: TimeoutException) {
            e.printStackTrace()
        }

        return null
    }


    private fun setButtonsState() {
        runOnUiThread {
            etClientId!!.setText(tokenRequest!!.clientId)
            tvCapabilities!!.text = tokenRequest!!.capability
            findViewById<View>(R.id.btLogin).visibility = if (tokenRequest!!.clientId == null) View.VISIBLE else View.GONE
            findViewById<View>(R.id.etClientId).isEnabled = tokenRequest!!.clientId == null
            findViewById<View>(R.id.btLogout).visibility = if (tokenRequest!!.clientId == null) View.GONE else View.VISIBLE

            if(!alreadyDone) {
                alreadyDone = true;
                generateRunId()
             //   registerReceiver()

                activatePush()
            }
            //pushSubscribe()
           // pushPublishData()

        }
    }

}
