<?php
$input = file_get_contents("php://input");
$input = escapeshellarg($input);
shell_exec ("echo $input > ./neekshellbot/tempinput");
shell_exec ("cd ./neekshellbot/ && timeout 5s ./neekshellbot.sh");
?>
