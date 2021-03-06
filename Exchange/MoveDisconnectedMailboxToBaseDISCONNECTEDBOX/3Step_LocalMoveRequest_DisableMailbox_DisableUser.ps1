Clear-Host

#Проверяем наличие активных подключений к ActiveDirectory и при необходимости создаем новое
If  ( (Get-Module -Name activedirectory) -ne $null ) {} Else {"ActiveDirectory module was not loaded. Loading AD...";Import-Module activedirectory;"ActiveDirectory module loaded."}

# Подготовка письма для отправки
$emailFrom = "Post_Relocate@zaoeps.local"
$emailTo = "adubas@zaoeps.local"
$subject = "Мало места на почовом сервере!"
$body = "Достигнут порог свободного места на диске F на серверах почтовых ящиков. Перенос уволенных в базу 'Disconnected box' приостановлен на 1 час"
$smtpServer = "cas.zaoeps.local"
$smtp = new-object Net.Mail.SmtpClient($smtpServer)

$UserWithoutActiveBox = Get-Content -Path "d:\UserWithoutActiveBox.txt"
Foreach ($User in $UserWithoutActiveBox)
{
	Get-Date
	############################################################
	# Если свободного места на диске F любого сервера почтовых ящиков меньше 50 Гб - отправлять уведомление и ждать 1 час
	# Повторять процедуру, пока свободного места на обоих серверах не будет больше 50 Гб
	$SizeAll = Get-WMIObject Win32_LogicalDisk -filter "DriveType=3" -computer "smtpmailserver2" | 
	Select SystemName,DeviceID,@{Name="size(GB)";Expression={"{0:N1}" -f($_.size/1gb)}},@{Name="freespaceGB";Expression={"{0:N1}" -f($_.freespace/1gb)}}
	$SizeAll | %{If ($_.DeviceID -like "F:") {$freeF2 = $_.freespaceGB}}
	$freeF2 = $freeF2 -replace ",.+?"
	$freeF2 = [double]$freeF2 # преобразуем строковое значение в целое
	"Smtpmailserver2 - F: "+$freeF2+"Gb free space"

	$SizeAll = Get-WMIObject Win32_LogicalDisk -filter "DriveType=3" -computer "smtpmailserver1" | 
	Select SystemName,DeviceID,@{Name="size(GB)";Expression={"{0:N1}" -f($_.size/1gb)}},@{Name="freespaceGB";Expression={"{0:N1}" -f($_.freespace/1gb)}}
	$SizeAll | %{If ($_.DeviceID -like "F:") {$freeF1 = $_.freespaceGB}}
	$freeF1 = $freeF1 -replace ",.+?"
	$freeF1 = [double]$freeF1 # преобразуем строковое значение в целое
	"Smtpmailserver1 - F: "+$freeF1+"Gb free space"

	$FreeSpace = $false
	Do
	{
		If (($freeF1 -lt 50) -or ($freeF2 -lt 50)) 
		{
			$smtp.Send($emailFrom, $emailTo, $subject, $body)	
			Start-Sleep -Seconds 3600
		}
		Else {$FreeSpace = $true}
	}
	Until ($FreeSpace)
	############################################################


	$User = $User -replace " ARCHIV.+"
	$User
	# Если учетная запись пользователя уже не находится к контейнере уволенных - сообщаем об этом и больше ничего не делаем
	If ( (get-aduser  -Filter {name -like $User} -Properties DistinguishedName).DistinguishedName -like "*,OU=Уволенные,OU=Пользователи,OU=ХОЛДИНГ,DC=zaoeps,DC=local" )
	{	
		$OUUser = "zaoeps.local/ХОЛДИНГ/Пользователи/Уволенные/"+$User
		$OUUser | New-Moverequest -TargetDatabase 'Disconnected Box' -BadItemLimit 200 -AcceptLargeDataLoss
		"Создан запрос на перемещение для: "+$User
		
		$PercentComplete = $null
		Do
		{
			Start-Sleep -Seconds 60
			Get-MoveRequestStatistics -Identity $User | %{$PercentComplete = $_.PercentComplete}
		}
		Until ($PercentComplete -eq 100)
		"Перемещение завершено"

		Get-MoveRequest | Where {$_.Displayname -eq $User} | Remove-MoveRequest -Confirm:$false
		"Запрос на перемещение удален"
		Start-Sleep -Seconds 20
		
		Disable-Mailbox -Identity $User -Confirm:$false
		"Отключение почтового ящика..."
		Start-Sleep -Seconds 20
		
		$GetMailboxNoExist = $false
		Do 
		{
			If ((Get-Mailbox $User) -eq $null) 
			{
				"Отключение почтового ящика завершено"
				$GetMailboxNoExist = $true
			}
			Else {Start-Sleep -Seconds 20}
		}
		Until ($GetMailboxNoExist = $true)
		
		Get-ADUser -Filter {name -eq $User} | Set-ADUser -Enabled $false
		$User+": учетная запись отключена"
		"---------------------------------"
	}
	Else
	{	
		$Repeat = $true
		Do 
		{
			"Учетная запись пользователя '"+$User+"' не находится в контейнере уволенных!"
			Start-Sleep -Seconds 3600
		}
		Until ($Repeat -eq $false)
	}
}
