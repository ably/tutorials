<html>
    <head>
        <script src="https://cdn.ably.io/lib/ably.min.js" type="text/javascript"></script>
    </head>
    <body>
        <h1>Token auth example</h1>
        <div id="panel-anonymous">
            <h3>Login</h3>
            <form action="/login.php">
                <input type="text" name="username" placeholder="Enter your username">
                <input type="submit" value="Login">
            </form>
        </div>
        <div id="panel-logged-in">
            Your are logged in. <a href="/logout.php">Log out</a>
        </div>
    </body>
    <script type="text/javascript">
        /* Set up a Realtime client that authenticates with the local web server auth endpoint */
        var realtime = new Ably.Realtime({ authUrl: '/auth.php' });
        realtime.connection.once('connected', function() {
            var user = realtime.auth.tokenDetails.clientId || 'anonymous';
            var capability = realtime.auth.tokenDetails.capability;
            alert(
                'You are now connected to Ably \n' +
                'User: ' + user + ' \n' +
                'Capabilities: ' + capability
            );
        });
        var loggedIn = document.cookie.indexOf('username') >= 0;
        document.getElementById('panel-anonymous').
        setAttribute('style', "display: " + (loggedIn ? 'none' : 'block'));
        document.getElementById('panel-logged-in').
        setAttribute('style', "display: " + (loggedIn ? 'block' : 'none'));
    </script>
</html>
