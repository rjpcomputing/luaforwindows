<?php
	$data = file_get_contents('data.txt');
	for($i = 0; $i < 1000; $i++)
		$v = json_decode($data);
?>
