<?php
$input = file_get_contents("php://input");
$input = escapeshellarg($input);
$input = str_replace('\\\\', '\\\\\\', $input);
$input = str_replace('"', '\"', $input );
$input = str_replace('$', '\$', $input );
$input = str_replace('\\\\"', '\\\\\\"', $input);
$command = "sudo su neekshellbot -c \"cd ./neekshellbot/ && timeout 240s ./neekshellbot.sh $input\"";
shell_exec ($command);
?>
