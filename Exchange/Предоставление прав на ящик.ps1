# Ящик, на который требуется предоставить права (Отображаемое имя владельца ящика)
$Mailbox = "крутова о"

# Пользователь, которому требуется предоставить права (Отображаемое имя)
$UserRight = "мазурова з"

# Требование предоставить права 'Отправить как'
$NeedSendAs = 0
# 0 - права не требуются
# 1 - права требуются

# Поиск всех вхождений $Mailbox
$CountUsers = 0 # Количество найденных пользователей
$UserDisplayNameForFilter = "*"+$Mailbox+"*" # Подготавливаем строковое значение для фильтра
Get-ADUser -filter {displayname -like $UserDisplayNameForFilter } | # Ищем все вхождения по пользователям
%{  # Если есть вхождение
	$CountUsers++
	Write-Host "Mailbox: "$_.name -ForegroundColor DarkGreen
	$MailboxDisplayName = $_.name
}
If ($CountUsers -eq 0) {"Почтовый ящик с таким отображаемым именем не найден! Задайте другое значение."; return}
If ($CountUsers -gt 1) {"Найдено следующее количество вхождений: "+$CountUsers; "Требуется уточнить владельца почтового ящика"; return}


# Поиск всех вхождений $UserRight
$CountUsers = 0 # Количество найденных пользователей
$UserDisplayNameForFilter = "*"+$UserRight+"*" # Подготавливаем строковое значение для фильтра
Get-ADUser -filter {displayname -like $UserDisplayNameForFilter } | # Ищем все вхождения по пользователям
%{  # Если есть вхождение
	$CountUsers++
	Write-Host "UserRight: "$_.name -ForegroundColor DarkBlue
	$UserRightAccountName = $_.samaccountname
}
If ($CountUsers -eq 0) {"Пользователь с таким отображаемым именем не найден! Задайте другое значение."; return}
If ($CountUsers -gt 1) {"Найдено следующее количество вхождений: "+$CountUsers; "Требуется уточнить пользователя для предоставления прав"; return}

$Rights = $null
$Rights = Get-MailboxPermission $MailboxDisplayName -User $UserRightAccountName
If ($Rights -ne $null) {Write-Host "Права на почтовый ящик уже имеются!" -ForegroundColor DarkRed}
Else
{
	# Предоставить полные права на почтовый ящик 
	Add-MailboxPermission $MailboxDisplayName -User $UserRightAccountName -AccessRights FullAccess -InheritanceType All
	Write-Host "Права на почтовый ящик предоставлены" -ForegroundColor DarkGreen
}


If ($NeedSendAs -eq 1)
{
	$Rights = $null
	$User = "ZAOEPS\"+$UserRightAccountName
	$Rights = Get-ADPermission -Identity $MailboxDisplayName | where {$_.user -like $User}
	If ($Rights -ne $null) {Write-Host "Права на 'Отправить как' уже имеются!" -ForegroundColor DarkRed}
	Else
	{
		# Предоставить права "Отправить как"
		Add-ADPermission -Identity $MailboxDisplayName -User $UserRightAccountName -AccessRights "ExtendedRight" -ExtendedRights "Send-As" -InheritanceType All
		Write-Host "Права на 'Отправить как' предоставлены" -ForegroundColor DarkBlue
	}
}


