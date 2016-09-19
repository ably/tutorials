<?php
require_once 'ably.php';
header('Content-Type: application/json');
# Issue token requests to clients sending a request to the /auth.php endpoint
echo json_encode($ably->auth->createTokenRequest()->toArray());
