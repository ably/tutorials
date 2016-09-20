<?php
require_once __DIR__ . 'vendor/autoload.php';

throw new \RuntimeException('Insert your API key'); // REMOVE THIS
$ably = new \Ably\AblyRest("{{ApiKey}}");
