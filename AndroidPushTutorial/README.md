[![Ably](https://s3.amazonaws.com/files.ably.io/logo-with-type.png)](https://www.ably.io)

---

# Android Push Tutorials

This tutorial explains how to use Ably to send Push notification from your private server.

There are some pre-requisites before you can run the app.

1. Register FCM Token from Google Firebase Console
2. Install nodejs to run the local server insider `Server/` folder
3. Setup *.ngrok.io to make the local server accessible via Internet
4. Register an account with Ably and create required App keys.


## Tutorials Setup
1. After the above steps are done, open the `push-demo-server-registration` folder as a project in Android Studio
2. The project might take some time to sync.
3. Replace `google-services.json` into `push-tutorial-one` and `push-demo-server-registration` folder.
4. For this tutorial we have used `io.ably.tutorial.push_tutorial_two` as applicationId for the app respectively. So ensure your FCM Keys have same applicationId. Feel free to modify the tutorials to suit your purpose.
5. Edit `local.properties` file and add the keys, `ably.key` (retrieved from dashboard), `ably.env` (either production or sanbox), `base.url` (pointing to your ngrok.io domain)

 
