<?php
// open the database
$db = new PDO("sqlite:{$db_name}.sqlite");
$db->exec("DROP TABLE {$table_name};"); 
$arr = [];
foreach($cols as $key => $val) $arr[] = "{$key} {$val}";
$q = "CREATE TABLE {$table_name} (id INTEGER PRIMARY KEY, " . join(', ', $arr) . ");";
echo $db->exec($q);
var_dump($q);

// inserts
$arr = [];
foreach($rows as $row) $arr[] = "('" . join("', '", $row) . "')";
$q = "INSERT INTO {$table_name} (" . join(', ', array_keys($cols)) . ") VALUES " . 
	join(', ', $arr) . ";";
echo $db->exec($q);
var_dump($q);

// close the database connection
$db = NULL;