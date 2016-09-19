<?php
require_once 'vendor/autoload.php';

throw new \RuntimeException('Insert your API key'); // REMOVE THIS
$ably = new \Ably\AblyRest("{{ApiKey}}");

echo "Instancing channel...\n";

$channel = $ably->channels->get("persisted:sounds");

echo "Publishing messages...\n";

$channel->publish("play", "bark");
$channel->publish("play", "meow");
$channel->publish("play", "cluck");
