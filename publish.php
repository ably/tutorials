<?php
require_once 'ably.php';
if (isset($_POST['message']) && !empty($_POST['message'])) {
    $channel = $ably->channels->get('sport');
    $channel->publish('update', $_POST['message']);
}
?>
<html>
<body>
<h1>Input message</h1>
<form method="post">
    <input type="text" name="message">
    <input type="submit" value="Publish!">
</form>
</body>
</html>
