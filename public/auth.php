<?php
require_once 'ably.php';
// Check if the user is logged in
if (isset($_COOKIE['username'])) {
    // Issue a token request with pub & sub permissions on all channels +
    // configure the token with an identity
    $tokenParams = [
        'capability' => [
            '*' => ['publish', 'subscribe']
        ],
        'clientId'  => $_COOKIE['username']
    ];
} else {
    // Issue a token with subscribe privileges restricted to one channel
    // and configure the token without an identity (anonymous)
    $tokenParams = [
        'capability' => [
            'notifications' => ['subscribe']
        ]
    ];
}
header('Content-Type: application/json');
echo json_encode($ably->auth->createTokenRequest($tokenParams)->toArray());
