<?php
if(isset($_GET['port'])) {
    $port = intval($_GET['port']);

    $status = checkPortStatus($port);


    echo $status;
} else {

    http_response_code(400); // Bad Request
    echo "Port nicht angegeben.";
}


function checkPortStatus($port) {
    $timeout = 1; // Timeout in Sekunden
    $connection = @fsockopen('127.0.0.1', $port, $errno, $errstr, $timeout);
    if ($connection !== false) {
        fclose($connection);
        return 'open';
    } else {
        return 'closed';
    }
}
?>
