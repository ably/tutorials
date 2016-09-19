<?php
setcookie('username', null, -1, '/');
header('Location: /', true, 302);
