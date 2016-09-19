<?php
require_once 'vendor/autoload.php';

throw new \RuntimeException('Insert your API key'); // REMOVE THIS
$ably = new \Ably\AblyRest("{{ApiKey}}");
