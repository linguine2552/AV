param($Url)
$Time = Get-Date -Format "MMddyyyyHHmmss"
$Path = 'C:\Users\Testo\samples\'
$Sample = $Path + $Time + '.gz'
Invoke-WebRequest -Uri $Url -OutFile $Sample
$Binary = & 'pUnq.exe ' $Sample
& 'Mag.S.exe ' "$($Binary)"