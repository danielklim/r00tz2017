<?php

$table_name = "users";
$cols = [
	'username' => 'VARCHAR(255)',
	'password' => 'VARCHAR(255)', 
	'name_first' => 'VARCHAR(255)',
	'name_last' => 'VARCHAR(255)', 
	'admin' => 'TINYINT'
];
$rows = [
	['admin', 'saltyformercw3', 'Dade', 'Murphy', 1],
	['ceo', 'Eggshell+Romalian', 'Patrick', 'Bateman', 1],
	['snuffy', 'beerbeerbeer', 'John', 'Snuffy', 0],
];
foreach($rows as $i => $row) $rows[$i][1] = $row[1];