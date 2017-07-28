<?php
try{
	// $db_name = "wc1";
	// $tables = ['db_users_wc1.php', 'db_products.php'];
	// foreach($tables as $t){
	// 	include($t);
	// 	include('db_init.php');
	// }

	$db_name = "wc2";
	$tables = ['db_users_wc2.php', 'db_products.php'];
	foreach($tables as $t){
		include($t);
		include('db_init.php');
	}

}
catch(PDOException $e){
	print 'Exception : '.$e->getMessage();
}
