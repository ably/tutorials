<?php
require_once __DIR__ . '/../vendor/autoload.php';

throw new \RuntimeException('Insert your API key'); // REMOVE THIS
$ably = new \Ably\AblyRest("{{ApiKey}}");

echo "<pre>\n";

echo "Retrieving channel...\n";

$channel = $ably->channels->get("persisted:sounds");

echo "Publishing messages...\n";

$channel->publish("play", "bark");
$channel->publish("play", "meow");
$channel->publish("play", "cluck");

echo "Releasing channel...\n";
// this part is only for tutorial purposes, in real you can use same instance of $channel
unset($channel);
$ably->channels->release("persisted:sounds");

echo "Retrieving channel...\n";

$channel = $ably->channels->get("persisted:sounds");

echo "Retrieving history...\n";

$paginatedResult = $channel->history();

foreach ($paginatedResult->items as $message) {
    /** @var \Ably\Models\Message $message */
    echo sprintf(
        "Latest message published: %s\n",
        $message->data
    );
}

echo "</pre>\n";
