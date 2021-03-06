Clear-Host

function Get-DisconnectedMailbox {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$false)]
        [System.String]
        $Name = '*'
    )
    
    $mailboxes = Get-MailboxServer
    $mailboxes | %{
        $disconn = Get-Mailboxstatistics -Server $_.name | ?{ $_.DisconnectDate -ne $null }
        $disconn | ?{$_.displayname -like $Name} | 
            Select DisplayName,
            @{n="StoreMailboxIdentity";e={$_.MailboxGuid}},
            Database
    }
}

$i = 0
$LogFile = "D:\Log.txt"
$ReadyDisconnectedFile = "D:\ReadyDisconnected.txt"
$DisconnectedMailbox = @()

Get-DisconnectedMailbox | 
%{
	If ( ($_.DisplayName -notlike "*Online Archive*") -and
	($_.DisplayName -notlike "*Личный архив*") -and
	($_.DisplayName -notlike "*Personal Archive*") -and
	($_.Database -ne "Disconnected Box") )
	{
		$DisconnectedMailbox += $_
		$i++
	}
}
$i
$Date = Get-Date
Add-Content -Path $LogFile ""
Add-Content -Path $LogFile "===Начало работы скрипта==="
Add-Content -Path $LogFile -Value $Date
$AllDisconnectedElements = Get-DisconnectedMailbox
$i = 0
Foreach ($Box in $DisconnectedMailbox)
{
	$BoxDisaplayname = "*"+$Box.DisplayName+"*"
	$Count = 0
	$DisconnectedMailboxBoxElement = $null
	$DisconnectedMailboxArchiveElement = $null
	$AllDisconnectedElements | 
	%{If ($_.DisplayName -like $BoxDisaplayname) 
		{
			$Count++
			If ($Count -le 2) {}#$_}
			If (($_.DisplayName -eq $Box.DisplayName) -and ($Count -le 2)){$DisconnectedMailboxBoxElement = $_}
			If (($_.DisplayName -ne $Box.DisplayName) -and ($Count -le 2)){$DisconnectedMailboxArchiveElement = $_}
		}
	}
	
	$NoReadyDisconnectedMailbox = $true
	
	If (Test-Path $ReadyDisconnectedFile)
	{
		Get-Content -Path $ReadyDisconnectedFile | 
		%{If ($_ -eq $DisconnectedMailboxBoxElement.DisplayName) {$NoReadyDisconnectedMailbox = $false}}
	}
	
	If ($NoReadyDisconnectedMailbox)
	{
		$TempStr = "------------------------------------------"
		$TempStr
		Add-Content -Path $LogFile -Value $TempStr
		$TempStr = "DisconnectedMailboxBoxElement: "+$DisconnectedMailboxBoxElement.DisplayName
		$TempStr
		Add-Content -Path $LogFile -Value $TempStr
		$TempStr = "DisconnectedMailboxArchiveElement: "+$DisconnectedMailboxArchiveElement.DisplayName
		$TempStr
		Add-Content -Path $LogFile -Value $TempStr
		$i++
		Get-ADUser -SearchBase "OU=Пользователи,OU=ХОЛДИНГ,DC=zaoeps,DC=local" -Filter {name -like $BoxDisaplayname} | %{$Login = $_.samaccountname}
		$ZaoepsUser = "zaoeps\"+$Login
#		$Login
		$ZaoepsUser
		
		$GetMailbox = Get-Mailbox $ZaoepsUser
		If ($GetMailbox -ne $null) {Write-Host "Есть активный ящик. Надо думать!!!" -ForegroundColor DarkRed}
		Else
		{	# Есть только отключенный ящик и возможно отключенный архив
			Write-Host "Можно работать" -ForegroundColor DarkGreen
			$TempStr = $DisconnectedMailboxBoxElement.DisplayName+" ARCHIVE: "+$DisconnectedMailboxArchiveElement.DisplayName
			Add-Content -Path "D:\UserWithoutActiveBox.txt" -Value $TempStr
			
			# Включение учетной записи
			Get-ADUser -SearchBase "OU=Пользователи,OU=ХОЛДИНГ,DC=zaoeps,DC=local" -Filter {displayname -like $BoxDisaplayname} |
			Set-ADUser -Enabled $true -ErrorAction Inquire
			"Учетка включена"
			Start-Sleep -Seconds 10

			# Подключение почтового ящика
			Connect-Mailbox -Identity $DisconnectedMailboxBoxElement.StoreMailboxIdentity -Database $DisconnectedMailboxBoxElement.Database -User $ZaoepsUser -Alias $Login
			Start-Sleep -Seconds 20
			$GetMailbox = $false
			Do 
			{
				If ((Get-Mailbox $Login) -ne $null) {$GetMailbox = $true}
				Else {"Ящик еще не подключен. Ждем 10 секунд"; Start-Sleep -Seconds 10}
				# Подключаем к ящику архив
				If (($DisconnectedMailboxArchiveElement.DisplayName -notlike "") -and ($DisconnectedMailboxArchiveElement.DisplayName -ne $null))
				{
					Connect-Mailbox –Identity $DisconnectedMailboxArchiveElement.DisplayName -Database "Removed Mailbox" -Archive -Confirm:$false
				}
			}
			Until ($GetMailbox = $true)
			"Ящик подключен: "+$ZaoepsUser

		}
	}
}
$i
