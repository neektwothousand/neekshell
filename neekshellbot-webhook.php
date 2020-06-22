<?php
$input = file_get_contents("php://input");
$input = escapeshellarg($input);
$input = str_replace('\\\\', '\\\\\\', $input);
$input = str_replace('"', '\"', $input );
$input = str_replace('$', '\$', $input );
$input = str_replace('\\\\"', '\\\\\\"', $input);
$command = "sudo su neekshellbot -c \"timeout 30s ./neekshellbot.sh $input\"";
#shell_exec ($command.' >/dev/null 2>/dev/null &');
shell_exec ($command);
?>
