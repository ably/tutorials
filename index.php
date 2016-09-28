<?php
require_once 'ably.php';
?>
<html>
<head>
    <script src="https://cdn.ably.io/lib/ably.min-1.js" type="text/javascript"></script>
</head>
<body>
<h1>Publish &amp; Subscribe sample</h1>
<iframe src="publish.php"></iframe>
</body>
<script type="text/javascript">
    /* Set up a Realtime client which will subscribe to 'sport' channel*/
    var realtime = new Ably.Realtime('<?= $apikey?>');
    var channel = realtime.channels.get("sport");
    channel.subscribe(function(msg) {
        alert("Received: " + msg.data);
    });
</script>
</html>

