#Проверяем наличие активных подключений к ActiveDirectory и при необходимости создаем новое
If  ( (Get-Module -Name activedirectory) -ne $null ) {} Else {"ActiveDirectory module was not loaded. Loading AD...";Import-Module activedirectory;"ActiveDirectory module loaded."}

$Server = "b000223"

Write-Host "Выполнение скрипта..." -ForegroundColor DarkGreen

$Login = Read-Host "Логин пользователя"

$UserGuid = $null
$UserGuid = (Get-ADUser $Login).ObjectGuid
If ($UserGuid -eq $null) {
	Write-Host $Login" - Такого пользователя не существует" -ForegroundColor DarkBlue 
	Write-Host "Выполнение скрипта завершено" -ForegroundColor DarkGreen
	return
} 
Else {Write-Host $Login" - Guid: "$UserGuid -ForegroundColor DarkBlue}

$UserGuid = "{"+$UserGuid+"}"

$Date = Get-Date

 $DestinationPath = "\\"+$Server+"\c$\users\"+$Login
 $NewFolderName = "1_"+$Login+"_"+$Date.TimeOfDay.Ticks
 If (Test-Path $DestinationPath) {Rename-Item $DestinationPath $NewFolderName; "Папка "+$DestinationPath+" переименована"}

 #Имя удаленного сервера
 $ServerName = $Server

 #Подключение к удаленному реестру
 $ServerKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,  $ServerName)

 #$ServerKey | Get-Member

 #Удаление записи пользователя в "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\"
 $key = $ServerKey.OpenSubkey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\",$false)
 $key.GetSubKeyNames() | ForEach-Object {
    #Путь в реестре к текущему профилю
	$FindProfileList = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\"+$_
	$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(‘LocalMachine’, $ServerName)
	
	#Получение ключей для текущего профиля
	$key_ = $reg.OpenSubKey($FindProfileList)
	$ProfileGuid = $key_.GetValue('Guid')
	If ($ProfileGuid -eq $UserGuid) {$reg.DeleteSubKeyTree($FindProfileList); "Удаление записи в реестре (ProfileList) на "+$Servers[$i]+" для "+$Login}
 }
 
 #Удаление записи пользователя в "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileGuid\"
 $key = $ServerKey.OpenSubkey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileGuid\",$false)
 $key.GetSubKeyNames() | ForEach-Object {
    #Путь в реестре к текущему профилю
	$FindProfileList = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileGuid\"+$_
	$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(‘LocalMachine’, $ServerName)
	If ($_ -eq $UserGuid) {$reg.DeleteSubKeyTree($FindProfileList); "Удаление записи в реестре (ProfileGuid) на "+$Servers[$i]+" для "+$Login}
 }

Write-Host "Выполнение скрипта завершено" -ForegroundColor DarkGreen