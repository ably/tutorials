<?php
require_once 'vendor/autoload.php';
$apikey = '{{ApiKey}}';
if (strpos($apikey, 'ApiKey')) {
    throw new RuntimeException('Insert your API key');
}
$ably = new \Ably\AblyRest($apikey);
