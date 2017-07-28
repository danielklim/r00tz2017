$template = "c:\www\wp46\wp-config.php.template"
$target = "c:\www\wp46\wp-config.php"

Copy-Item $template -Destination $target

$ip = (Test-Connection -ComputerName (hostname) -Count 1).IPV4Address.IPAddressToString
$toadd = "define('WP_HOME','http://$ip/wp46');define('WP_SITEURL','http://$ip/wp46');"
$toadd | Add-Content $target