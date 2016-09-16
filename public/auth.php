<?php
require_once 'ably.php';
header('Content-Type: application/json');
echo json_encode($ably->auth->createTokenRequest()->toArray());
