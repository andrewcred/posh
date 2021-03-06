Clear-Host
$NotificationAboutFreeSpace = $false
Get-Mailbox -ResultSize Unlimited | where {$_.ArchiveDatabase -like "Users"} |
%{
#$_
	$FreeSpace = (Get-WmiObject -Class Win32_LogicalDisk -ComputerName smtpmailserver1 | ? {$_.DeviceID -eq 'F:'}).FreeSpace
	If ($FreeSpace -gt 50Gb)
	{
		New-MoveRequest $_ -ArchiveOnly -ArchiveTargetDatabase "Online Archive" -BadItemLimit 100 -AcceptLargeDataLoss #-WhatIf
		(Get-Date).DateTime
		write-host "Создан запрос на перемещение для: "$_.ArchiveName -ForegroundColor Green
		Do
		{
			Start-Sleep -Seconds 60
			$PercentComplete = (Get-MoveRequestStatistics -Identity $_.DisplayName).PercentComplete
			$Status = (Get-MoveRequestStatistics -Identity $_.DisplayName).Status
		}
		Until (($PercentComplete -eq 100) -or ($Status -like "Failed"))
		(Get-Date).DateTime
		If ($Status -like "Failed") {Write-Host "Перемещение не завершено. Failed" -ForegroundColor Red}
		Else 
		{
			Write-Host "Перемещение завершено" -ForegroundColor Green
			Get-MoveRequest -Identity $_.DisplayName | Remove-MoveRequest -Confirm:$false
			"Запрос на перемещение удален"
		}
	}
	Else 
	{
		If ($NotificationAboutFreeSpace) {$_.DisplayName}
		Else 
		{
			Write-Host "На диске меньше 50 Гб - остальные пользователи будут пропущены" -BackgroundColor DarkBlue -ForegroundColor White
			$NotificationAboutFreeSpace = $true
		}
	}
}
