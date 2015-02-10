Function Uninstall-App ($App) {
$app = Get-WmiObject -Class Win32_Product | Where-Object { 
    $_.Name -match "$App" 
}

$app.Uninstall()
}
