<?php
if (isset($_REQUEST['username'])) {
    setcookie('username', $_REQUEST['username']);
    header('Location: /', true, 302);
} else {
    http_response_code(500);
    echo "Username is required to login";
}
