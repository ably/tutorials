package com.android.ably.pushdemo

import android.support.v7.app.AppCompatActivity
import android.os.Bundle

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import android.widget.TextView
import com.google.firebase.iid.FirebaseInstanceId
import com.google.gson.JsonObject
import com.google.gson.JsonPrimitive
import io.ably.lib.realtime.*
import io.ably.lib.types.*
import java.util.HashMap

const val TAG = "androidpushexample"

class MainActivity : AppCompatActivity() {

    val apiKey = "FJWZrQ.swLeTg:_R4gkfPIxXcj3tRy"
    val environment = "production"

    var runId = ""
    var channelName = ""

    lateinit var client: AblyRealtime
    lateinit var textView: TextView
    lateinit var logger: TextViewLogger
    lateinit var pushMessageReceiver: PushReceiver

    inner class PushReceiver : BroadcastReceiver() {
        private val lock:Object = Object()
        private var action:String = ""
        private var runId:String = ""
        override fun onReceive(context: Context?, intent: Intent?) {
            val pushData :HashMap<String, String> = intent!!.getSerializableExtra("data") as HashMap<String, String>
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

    fun initAbly():Boolean {
        val options = ClientOptions(apiKey)
        options.environment = environment
        options.logLevel = io.ably.lib.util.Log.VERBOSE
        client = AblyRealtime(options)

        /* this is necessary before the client can perform any operations that depend on
         * an Android context, such as making the necessary platform operations for push */
        client.setAndroidContext(this)
        logger.i("initAbly()", "initialised library")

        /* monitor for connection state changes */
        client.connection.on(object: ConnectionStateListener {
            override fun onConnectionStateChanged(state: ConnectionStateListener.ConnectionStateChange?) {
                when(state!!.current) {
                    ConnectionState.connecting -> logger.w("initAbly()", "connecting")
                    ConnectionState.disconnected -> logger.w("initAbly()", "disconnected")
                    ConnectionState.connected -> logger.i("initAbly()", "connected")
                    ConnectionState.closed -> logger.e("initAbly()", "closed")
                    ConnectionState.failed -> logger.e("initAbly()", "failed: err: " + state!!.reason.message)
                    else -> logger.e("initAbly()", "unexpected connection state: ${state!!.current}")
                }
            }
        })
        return true
    }

    fun activatePush(wait:Boolean = false):Boolean {

        /* activate Firebase */
        logger.i("activatePush()", "initialising Firebase")
        //FirebaseInstanceId.getInstance().getToken()
        AblyPushRegistrationService.onNewRegistrationToken(this, FirebaseInstanceId.getInstance().getToken())
        /* ensure the Ably library registers any new token with the server */
        logger.i("activatePush()", "activating push system .. waiting")
        client.push.activate()
        if(wait) {
            /* FIXME: wait for actual state change */
            Thread.sleep(4000)
        }
        logger.i("activatePush()", ".. activated push system")
        return true
    }


    fun realtimeSubscribe(testChannelName:String = channelName, wait:Boolean = false):Boolean {
        logger.i("realtimeSubscribe()", "subscribing to channel")
        val channel = client.channels.get(testChannelName)
        channel.on(object:ChannelStateListener {
            override fun onChannelStateChanged(stateChange: ChannelStateListener.ChannelStateChange?) {
                when(stateChange!!.current) {
                    ChannelState.attaching -> logger.w("realtimeSubscribe()", "attaching")
                    ChannelState.attached -> logger.i("realtimeSubscribe()", "attached")
                    ChannelState.failed -> logger.e("realtimeSubscribe()", "failed: err: " + stateChange!!.reason.message)
                    else -> logger.e("realtimeSubscribe()", "unexpected connection state: ${stateChange!!.current}")
                }
            }
        })
        val waiter = Object()
        var error:ErrorInfo? = null
        synchronized(waiter) {
            channel.attach(object:CompletionListener{
                override fun onError(reason: ErrorInfo?) {
                    error = reason
                    synchronized(waiter) {waiter.notify()}
                }

                override fun onSuccess() {
                    channel.subscribe(object: Channel.MessageListener {
                        override fun onMessage(message: Message?) {
                            logger.i("realtimeSubscribe()", "received message: name=${message!!.name}; data=${message.data as String}")
                        }
                    })
                    synchronized(waiter) {waiter.notify()}
                }
            })
            if(wait) {
                logger.i("realtimeSubscribe()", "waiting for channel attach ..")
                waiter.wait()
                logger.i("realtimeSubscribe()", ".. channel attached")
            }
        }
        if(error != null) {
            throw AblyException.fromErrorInfo(error)
        }
        return true
    }

    fun pushSubscribe(testChannelName:String = channelName, wait:Boolean = true):Boolean {
        logger.i("pushSubscribe()", "push subscribing to channel")
        System.out.println(" channel name " + channelName)
        val channel = client.channels.get(testChannelName)
        val waiter = Object()
        var error:ErrorInfo? = null
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

    fun pushSubScribeByDevice() {
        System.out.println(" channel name " + channelName)
        val channel = client.channels.get("test")

        object:Thread() {
            override fun run() {
                Thread.sleep(1000)
                channel.push.subscribeDevice()
                logger.i("pushSubscribe()", ".. push subscription complete")
            }
        }.start()
    }

    /**
     * Publish a message via the realtime connection
     */
    fun realtimePublish(testChannelName:String = channelName):Boolean {
        logger.i("realtimePublish()", "publishing to channel")
        val channel = client.channels.get(testChannelName)
        val message = Message("testMessageName", "testMessageData from Android")
        channel.publish(message, object: CompletionListener {
            override fun onSuccess() {
                logger.i("realtimePublish()", "publish success")
            }
            override fun onError(reason: ErrorInfo?) {
                logger.e("realtimePublish()", "failed: err: " + reason!!.message)
            }
        });
        return true
    }

    fun resetLocalDevice():Boolean {
        logger.i("resetLocalDevice()", "resetting local device")
        client.push.getLocalDevice().reset()
        return true
    }

    fun resetActivationState():Boolean {
        logger.i("resetActivationState()", "resetting activation state")
        client.push.activationContext.getActivationStateMachine().reset()
        return true
    }

    fun pushPublishData(testRunId:String = runId, wait:Boolean = false):Boolean {
        logger.i("pushPublishData()", "pushing data message to channel")
        val channel = client.channels.get(channelName(testRunId))
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

        Log.i(TAG, "MainActvity onCreate")
        setContentView(R.layout.activity_main)

        textView = findViewById(R.id.editText1) as TextView
        logger = TextViewLogger(textView);

        generateRunId()
        registerReceiver()
        initAbly()

        activatePush()

        // now sunscribe to channel
//        realtimeSubscribe()

        //publish message
  //      realtimePublish()

        pushSubscribe()
        pushPublishData()
    }
}
