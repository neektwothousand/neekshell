<?php
$input = file_get_contents("php://input");
$input = escapeshellarg($input);
$input = str_replace('\\\\', '\\\\\\', $input);
$input = str_replace('"', '\"', $input );
$input = str_replace('$', '\$', $input );
$input = str_replace('\\\\"', '\\\\\\"', $input);
shell_exec ("mksh -c \"./neekshellbot.sh $input\" > /dev/null &");
?>
