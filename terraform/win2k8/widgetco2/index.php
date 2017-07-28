<?php
	// session_start();
	$query_str = '';
	$rows = [];
	$errors = [];
	$db_name = "wc2";

	// main query
	$seach_term = isset($_REQUEST['seach_term'])? trim($_REQUEST['seach_term']) : NULL;
	if($seach_term){
		$db = new PDO("sqlite:{$db_name}.sqlite");
		$query_str = "SELECT id, price FROM products WHERE id = '{$seach_term}';";

		try{
			$q = $db->query($query_str);
			if($q){
				$Rows  = $q->fetchAll(PDO::FETCH_OBJ);
				$rows = [];
				foreach($Rows as $row){
					$ok = true;
					foreach($row as $col){
						if(!is_numeric($col)) $ok = false;
					}
					if($ok) $rows[] = $row;
				}
					
				if(!count($rows)) $errors[] = "No results!";
			}
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
	1) why doesn't this work??
	' UNION ALL SELECT name, type FROM sqlite_master WHERE '1=1
	
	2) does this help us at all?
	' UNION ALL SELECT 1, 1 FROM sqlite_master WHERE '1=1

	3) what about this?
	' UNION ALL SELECT 1, 1 FROM users WHERE username = 'admin' AND password LIKE 's%
	*/
?>

<!doctype html>
<html>

<head>
	<title></title>
	<link rel="stylesheet" type="text/css" href="css/bootstrap.min.css">
	<!-- <script type="text/javascript" src="js/bootstrap.min.js"></script> -->
</head>

<body>
	<nav class="navbar navbar-full navbar-dark bg-inverse" style='margin-bottom: 1rem;'>
		<h1 class="navbar-brand">Widget Co</h1>
		<form class="form-inline" method='POST' style='display:inline-block;'>
			<input class="form-control mr-sm-2" type="text" placeholder="Admin Password" name='answer'>
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
				<p>Get the admin password for the flag.</p>
			</div>
		</div>

		<div class="row">
			<div class="col-sm-12">
				<h2>Inventory Checker</h2>
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
						<label for="seach_term">Search IDs</label>

						<div class="input-group">
							<input type="text" class="form-control" name='seach_term' placeholder="Enter product ID">
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