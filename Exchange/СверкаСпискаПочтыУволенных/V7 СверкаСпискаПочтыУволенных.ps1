<#

 V3

 Добавлена проверка на наличие внешнего адреса.

 Возможно удалить внешние адреса с автоматической отправкой письма об удалении форварда, при условии,
 что почта и архив пользователя находятся в базе 'Removed Mailbox'.

 Теперь для отключения почтового ящика кроме требования отсутствия назначенных на ящик прав для
 других пользователей, требуется отсутствие внешних адресов.


 V4

 При доступности отключения ящика, проверяется наличие контактов


 V5

 Добавленa возможность создать запрос на перемещение почтового ящика в базу 'Removed Mailbox',
 отследить статус на перемещение, удалить запрос на перемещение, проверить текущее месторасположение
 в базах почтового ящика


 V6

 Добавлен поиск присутсвия прав для групп (ранее только пользователей)


 V7

 Отправка письма об удалени форварда теперь происходит при отключении почтового ящика

#>

$emailTo = "gr_svyazi@zaoeps.local,epalkina@zaoeps.local" # получатель письма об удалении форварда

#Проверяем наличие активных подключений к ActiveDirectory и при необходимости создаем новое
If  ( (Get-Module -Name activedirectory) -ne $null ) {} Else {"ActiveDirectory module was not loaded. Loading AD...";Import-Module activedirectory;"ActiveDirectory module loaded."}

# Подгрузить командлеты Exchange (занимает некоторое время)
If (get-pssnapin microsoft.exchange.management.powershell.e2010) {} Else {add-pssnapin microsoft.exchange.management.powershell.e2010}

#Добавляем сборку для работы с графическим интерфейсом
[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

$Form = new-object System.Windows.Forms.form
$Form.Text = "Проверка прав на почтовый ящик пользователя"
$Form.Width = 770
$Form.Height = 550

$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Уволенный:"
$Label.Left = 20
$Label.Top = 20
$Form.Controls.Add($Label)

$TextBoxUvol = New-Object System.Windows.Forms.TextBox
$TextBoxUvol.Width = 300
$TextBoxUvol.Top = $Label.Top + 30
$TextBoxUvol.Left = $Label.Left
$Form.Controls.Add($TextBoxUvol)

$Button = New-Object System.Windows.Forms.Button
$Button.Text = "Проверить"
$Button.Left = $TextBoxUvol.Width + 30
$Button.Top = $TextBoxUvol.Top - 2
$Form.Controls.Add($Button) 

$CheckLogin = New-Object System.Windows.Forms.CheckBox
$CheckLogin.Left = $Button.Left
$CheckLogin.Top = $Button.Top - 30
$CheckLogin.Width = 60
$CheckLogin.Text = "Login"
$CheckLogin.Checked = $false
$Form.Controls.Add($CheckLogin)

$ButtonPasteUvol = New-Object System.Windows.Forms.Button
$ButtonPasteUvol.Text = "Вставить"
$ButtonPasteUvol.Left = $Label.Left + $Label.Width + 30
$ButtonPasteUvol.Top = $Label.Top
$Form.Controls.Add($ButtonPasteUvol)
$ButtonPasteUvol.Enabled = $false

$TextBoxLogUvol = New-Object System.Windows.Forms.TextBox
$TextBoxLogUvol.Top = $TextBoxUvol.Top + 30
$TextBoxLogUvol.Left = $TextBoxUvol.Left
$TextBoxLogUvol.Width = $TextBoxUvol.Width + 20
$TextBoxLogUvol.Height = 270
$TextBoxLogUvol.Multiline = $true			# Установка многострочного режима
$TextBoxLogUvol.ReadOnly = $true			# Запрет редактирования текста
$TextBoxLogUvol.ScrollBars = "Vertical"		# Создания вертикального ScrollBar для TextBox
$TextBoxLogUvol.BackColor = "White"			# Так как в режиме на чтение TextBox серый, делаем фон белым
$Form.Controls.Add($TextBoxLogUvol)

$ButtonPostRights = New-Object System.Windows.Forms.Button
$ButtonPostRights.Text = "<=Права"
$ButtonPostRights.Left = $TextBoxUvol.Width + 45
$ButtonPostRights.Top = $Button.Top + 60
$ButtonPostRights.Width = $Button.Width - 15
$ButtonPostRights.Enabled = $false
$Form.Controls.Add($ButtonPostRights)

$ButtonDelExtAddr = New-Object System.Windows.Forms.Button
$ButtonDelExtAddr.Text = "Удалить"
$ButtonDelExtAddr.Left = $TextBoxUvol.Width + 45
$ButtonDelExtAddr.Top = $Button.Top + 220
$ButtonDelExtAddr.Width = $Button.Width - 15
$ButtonDelExtAddr.Enabled = $false
$Form.Controls.Add($ButtonDelExtAddr)

$LabelDelExtAddr1 = New-Object System.Windows.Forms.Label
$LabelDelExtAddr1.Text = "Удалить все"
$LabelDelExtAddr1.Width = 71
$LabelDelExtAddr1.Height = 12
$LabelDelExtAddr1.Left = $ButtonDelExtAddr.Left - 7
$LabelDelExtAddr1.Top = $ButtonDelExtAddr.Top - 50
$Form.Controls.Add($LabelDelExtAddr1)

$LabelDelExtAddr2 = New-Object System.Windows.Forms.Label
$LabelDelExtAddr2.Text = "внешние"
$LabelDelExtAddr2.Width = 71
$LabelDelExtAddr2.Height = 12
$LabelDelExtAddr2.Left = $ButtonDelExtAddr.Left - 7
$LabelDelExtAddr2.Top = $ButtonDelExtAddr.Top - 35
$Form.Controls.Add($LabelDelExtAddr2)

$LabelDelExtAddr3 = New-Object System.Windows.Forms.Label
$LabelDelExtAddr3.Text = "адреса"
$LabelDelExtAddr3.Width = 71
$LabelDelExtAddr3.Height = 12
$LabelDelExtAddr3.Left = $ButtonDelExtAddr.Left - 7
$LabelDelExtAddr3.Top = $ButtonDelExtAddr.Top - 20
$Form.Controls.Add($LabelDelExtAddr3)

$GroupBox = New-Object System.Windows.Forms.GroupBox
$GroupBox.Left = 5
$GroupBox.Width = 405
$GroupBox.Height = 355
$Form.Controls.Add($GroupBox)

$TextBoxUvolForDelRights = New-Object System.Windows.Forms.TextBox
$TextBoxUvolForDelRights.Width = $TextBoxUvol.Width
$TextBoxUvolForDelRights.Top = 370
$TextBoxUvolForDelRights.Left = $TextBoxUvol.Left
$TextBoxUvolForDelRights.Enabled = $false
$TextBoxUvolForDelRights.BackColor = "White"
$Form.Controls.Add($TextBoxUvolForDelRights)

$TextBoxUvolDeleteManagedBy = New-Object System.Windows.Forms.TextBox
$TextBoxUvolDeleteManagedBy.Left = $TextBoxUvolForDelRights.Left + 90
$TextBoxUvolDeleteManagedBy.Width = $TextBoxUvolForDelRights.Width - 90 
$TextBoxUvolDeleteManagedBy.Top = $TextBoxUvolForDelRights.Top + 30
$TextBoxUvolDeleteManagedBy.Enabled = $false
$TextBoxUvolDeleteManagedBy.BackColor = "White"
$Form.Controls.Add($TextBoxUvolDeleteManagedBy)

$LabelUvolDeleteManagedBy = New-Object System.Windows.Forms.Label
$LabelUvolDeleteManagedBy.Left = $TextBoxUvolForDelRights.Left
$LabelUvolDeleteManagedBy.Top = $TextBoxUvolDeleteManagedBy.Top + 5
$LabelUvolDeleteManagedBy.Text = "DEL ManagedBy"
$Form.Controls.Add($LabelUvolDeleteManagedBy)

$ButtonUvolDeleteManagedBy = New-Object System.Windows.Forms.Button
$ButtonUvolDeleteManagedBy.Left = $TextBoxUvolDeleteManagedBy.Left + $TextBoxUvolDeleteManagedBy.Width + 5
$ButtonUvolDeleteManagedBy.Top = $TextBoxUvolDeleteManagedBy.Top
$ButtonUvolDeleteManagedBy.Text = "<=Вставить"
$ButtonUvolDeleteManagedBy.Enabled = $false
$Form.Controls.Add($ButtonUvolDeleteManagedBy)

$ButtonUvolDeleteManagedByDelete = New-Object System.Windows.Forms.Button
$ButtonUvolDeleteManagedByDelete.Left = $ButtonUvolDeleteManagedBy.Left + $ButtonUvolDeleteManagedBy.Width + 80
$ButtonUvolDeleteManagedByDelete.Top = $ButtonUvolDeleteManagedBy.Top
$ButtonUvolDeleteManagedByDelete.Text = "<=Удалить"
$ButtonUvolDeleteManagedByDelete.Enabled = $false
$Form.Controls.Add($ButtonUvolDeleteManagedByDelete)

$CheckBoxManagedByDelete = New-Object System.Windows.Forms.CheckBox
$CheckBoxManagedByDelete.Left = $ButtonUvolDeleteManagedByDelete.Left - 20
$CheckBoxManagedByDelete.Top = $ButtonUvolDeleteManagedByDelete.Top
$CheckBoxManagedByDelete.Width = 15
$CheckBoxManagedByDelete.Checked = $false
$Form.Controls.Add($CheckBoxManagedByDelete)

$TextBoxUvolDeleteSendAs = New-Object System.Windows.Forms.TextBox
$TextBoxUvolDeleteSendAs.Left = $TextBoxUvolForDelRights.Left + 90
$TextBoxUvolDeleteSendAs.Width = $TextBoxUvolForDelRights.Width - 90 
$TextBoxUvolDeleteSendAs.Top = $TextBoxUvolForDelRights.Top + 60
$TextBoxUvolDeleteSendAs.Enabled = $false
$TextBoxUvolDeleteSendAs.BackColor = "White"
$Form.Controls.Add($TextBoxUvolDeleteSendAs)

$LabelUvolDeleteSendAs = New-Object System.Windows.Forms.Label
$LabelUvolDeleteSendAs.Left = $TextBoxUvolForDelRights.Left
$LabelUvolDeleteSendAs.Top = $TextBoxUvolDeleteManagedBy.Top + 35
$LabelUvolDeleteSendAs.Text = "DEL SendAs"
$Form.Controls.Add($LabelUvolDeleteSendAs)

$ButtonUvolDeleteSendAs = New-Object System.Windows.Forms.Button
$ButtonUvolDeleteSendAs.Left = $TextBoxUvolDeleteSendAs.Left + $TextBoxUvolDeleteSendAs.Width + 5
$ButtonUvolDeleteSendAs.Top = $TextBoxUvolDeleteSendAs.Top
$ButtonUvolDeleteSendAs.Text = "<=Вставить"
$ButtonUvolDeleteSendAs.Enabled = $false
$Form.Controls.Add($ButtonUvolDeleteSendAs)

$ButtonUvolDeleteSendAsDelete = New-Object System.Windows.Forms.Button
$ButtonUvolDeleteSendAsDelete.Left = $ButtonUvolDeleteSendAs.Left + $ButtonUvolDeleteSendAs.Width + 80
$ButtonUvolDeleteSendAsDelete.Top = $ButtonUvolDeleteSendAs.Top
$ButtonUvolDeleteSendAsDelete.Text = "<=Удалить"
$ButtonUvolDeleteSendAsDelete.Enabled = $false
$Form.Controls.Add($ButtonUvolDeleteSendAsDelete)

$CheckBoxSendAsDelete = New-Object System.Windows.Forms.CheckBox
$CheckBoxSendAsDelete.Left = $ButtonUvolDeleteSendAsDelete.Left - 20
$CheckBoxSendAsDelete.Top = $ButtonUvolDeleteSendAsDelete.Top
$CheckBoxSendAsDelete.Width = 15
$CheckBoxSendAsDelete.Checked = $false
$Form.Controls.Add($CheckBoxSendAsDelete)

$CheckBoxDisableMailbox = New-Object System.Windows.Forms.CheckBox
$CheckBoxDisableMailbox.Left = 25
$CheckBoxDisableMailbox.Top = $CheckBoxSendAsDelete.Top + 30
$CheckBoxDisableMailbox.Width = 15
$CheckBoxDisableMailbox.Checked = $false
$CheckBoxDisableMailbox.Enabled = $false
$Form.Controls.Add($CheckBoxDisableMailbox)

$ButtonDisableMailbox = New-Object System.Windows.Forms.Button
$ButtonDisableMailbox.Left = 50
$ButtonDisableMailbox.Top = $CheckBoxDisableMailbox.Top
$ButtonDisableMailbox.Width = 200
$ButtonDisableMailbox.Text = "Отключить почтовый ящик"
$ButtonDisableMailbox.Enabled = $false
$Form.Controls.Add($ButtonDisableMailbox)

$GroupBoxDeleteRights = New-Object System.Windows.Forms.GroupBox
$GroupBoxDeleteRights.Left = $GroupBox.Left
$GroupBoxDeleteRights.Width = $GroupBox.Width + 160
$GroupBoxDeleteRights.Top = $GroupBox.Height
$GroupBoxDeleteRights.Height = 140
$Form.Controls.Add($GroupBoxDeleteRights)
#------------------------------------------------------------------------------------

# Запрос на перемещение
$ButtonMoveRequest = New-Object System.Windows.Forms.Button
$ButtonMoveRequest.Text = "Переместить в 'Removed Mailbox'"
$ButtonMoveRequest.Left = $ButtonPostRights.Left + 130
$ButtonMoveRequest.Top = 47
$ButtonMoveRequest.Width = 200
$ButtonMoveRequest.Enabled = $false
$Form.Controls.Add($ButtonMoveRequest)

$LabelMoveRequestStatus = New-Object System.Windows.Forms.Label
$LabelMoveRequestStatus.Text = "Status: "
$LabelMoveRequestStatus.Left = $ButtonMoveRequest.Left
$LabelMoveRequestStatus.Top = $ButtonMoveRequest.Top + 40
$LabelMoveRequestStatus.Width = 150
$Form.Controls.Add($LabelMoveRequestStatus)

$LabelMoveRequestPercentCompleted = New-Object System.Windows.Forms.Label
$LabelMoveRequestPercentCompleted.Text = "Percent:"
$LabelMoveRequestPercentCompleted.Left = $LabelMoveRequestStatus.Left
$LabelMoveRequestPercentCompleted.Top = $LabelMoveRequestStatus.Top + 25
$LabelMoveRequestPercentCompleted.Width = $LabelMoveRequestStatus.Width
$Form.Controls.Add($LabelMoveRequestPercentCompleted)

$ButtonMoveRequestStatus = New-Object System.Windows.Forms.Button
$ButtonMoveRequestStatus.Text = "Статус перемещения"
$ButtonMoveRequestStatus.Left = $LabelMoveRequestPercentCompleted.Left
$ButtonMoveRequestStatus.Top = $LabelMoveRequestPercentCompleted.Top + 25
$ButtonMoveRequestStatus.Width = 140
$ButtonMoveRequestStatus.Enabled = $false
$Form.Controls.Add($ButtonMoveRequestStatus)

$ButtonRemoveMoveRequest = New-Object System.Windows.Forms.Button
$ButtonRemoveMoveRequest.Text = "Удалить запрос на перемещение"
$ButtonRemoveMoveRequest.Left = $ButtonMoveRequestStatus.Left
$ButtonRemoveMoveRequest.Top = $ButtonMoveRequestStatus.Top + 40
$ButtonRemoveMoveRequest.Width = 200
$ButtonRemoveMoveRequest.Enabled = $false
$Form.Controls.Add($ButtonRemoveMoveRequest)
#------------------------------------------------------------------------------------

# Определение почтовых баз пользователя и пользовательского архива
$ButtonDatabase = New-Object System.Windows.Forms.Button
$ButtonDatabase.Text = "Database"
$ButtonDatabase.Left = $ButtonMoveRequestStatus.Left
$ButtonDatabase.Top = $ButtonRemoveMoveRequest.Top + 100
$ButtonDatabase.Width = 65
$ButtonDatabase.Enabled = $false
$Form.Controls.Add($ButtonDatabase)

$LabelMailboxDatabase = New-Object System.Windows.Forms.Label
$LabelMailboxDatabase.Text = "Mailbox Database:"
$LabelMailboxDatabase.Left = $ButtonDatabase.Left + $ButtonDatabase.Width + 5
$LabelMailboxDatabase.Top = $ButtonDatabase.Top - 7 
$LabelMailboxDatabase.Width = 200
$Form.Controls.Add($LabelMailboxDatabase)

$LabelArciveDatabase = New-Object System.Windows.Forms.Label
$LabelArciveDatabase.Text = "Archive Database:"
$LabelArciveDatabase.Left = $ButtonDatabase.Left + $ButtonDatabase.Width + 5
$LabelArciveDatabase.Top = $ButtonDatabase.Top + 17
$LabelArciveDatabase.Width = 200
$Form.Controls.Add($LabelArciveDatabase)


# Вывод в TextBox с автоматическим скроллингом вниз
function OutputScrollingText {
	param ($TextBoxOutput, $Text)
	$TextBoxOutput.Lines = $TextBoxOutput.Lines+$Text
	$TextBoxOutput.Select($TextBoxOutput.Text.Length, 0)
	$TextBoxOutput.ScrollToCaret()
}

$button.add_Click(
{
	$CheckBoxManagedByDelete.Checked = $false
	$ButtonUvolDeleteManagedByDelete.Enabled = $false
	$CheckBoxSendAsDelete.Checked = $false
	$ButtonUvolDeleteSendAsDelete.Enabled = $false
	$TextBoxUvolDeleteManagedBy.Text = ""
	$ButtonUvolDeleteManagedBy.Enabled = $false
	$TextBoxUvolDeleteSendAs.Text = ""
	$ButtonUvolDeleteSendAs.Enabled = $false
	$Button.Enabled = $false
	$ButtonDisableMailbox.Enabled = $false
	$CheckBoxDisableMailbox.Checked = $false
	$CheckBoxDisableMailbox.Enabled = $false
	$ButtonMoveRequest.Enabled = $false
	$ButtonMoveRequestStatus.Enabled = $false
	$ButtonRemoveMoveRequest.Enabled = $false
	$LabelMoveRequestStatus.Text = "Status: "
	$LabelMoveRequestPercentCompleted.Text = "Percent:"
	$ButtonDatabase.Enabled = $false
	$LabelMailboxDatabase.Text = "Mailbox Database:"
	$LabelArciveDatabase.Text = "Archive Database:"
	$CountFindUser = 0
	$TextBoxLogUvol.Text = ""
	$Uvolenniy = "*" + $TextBoxUvol.Text + "*"
	$User = $null
	If ($CheckLogin.Checked) {$User = Get-ADUser -Filter {Samaccountname -like $Uvolenniy}}
	Else {$User = Get-ADUser -Filter {Name -like $Uvolenniy}}
	If ($User -eq $null) 
	{
		If ($CheckLogin.Checked)
		{OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "По заданному Логину пользователь не найден"}
		Else
		{OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "По заданному Отображаемому Имени пользователь не найден"}
	}
	Else
	{
		$User | 
		%{
			If ($_.enabled) {$Enabled = " - АКТИВНЫЙ!"} Else {$Enabled = " - отключен"}
			OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text ($_.name + $Enabled)
			$CountFindUser++
			$Uvolenniy = $_.name
		}
	}
	If ($CountFindUser -eq 1) 
	{
		$ButtonPostRights.Enabled = $true
		$TextBoxUvolForDelRights.Text = $Uvolenniy
	}
	Else 
	{
		$ButtonPostRights.Enabled = $false
		$TextBoxUvolForDelRights.Text = ""
		$ButtonUvolDeleteManagedBy.Enabled = $false
		$ButtonUvolDeleteSendAs.Enabled = $false
		$TextBoxUvolDeleteManagedBy.Text = ""
		$TextBoxUvolDeleteSendAs.Text = ""
	}
	$ButtonPasteUvol.Enabled = $true
	$Button.Enabled = $true
})

$ButtonPostRights.add_Click(
{
	$CheckBoxManagedByDelete.Checked = $false
	$ButtonUvolDeleteManagedByDelete.Enabled = $false
	$CheckBoxSendAsDelete.Checked = $false
	$ButtonUvolDeleteSendAsDelete.Enabled = $false
	$ButtonPostRights.Enabled = $false
	$TextBoxUvolDeleteManagedBy.Text = ""
	$ButtonUvolDeleteManagedBy.Enabled = $false
	$TextBoxUvolDeleteSendAs.Text = ""
	$ButtonUvolDeleteSendAs.Enabled = $false
	$NotManagedBy = $false		 # Определитель, если у кого-то права на почтовыя ящик
	$NotSendAs = $false			 # Определитель, если у кого-то права на отправку от имени владельца почтового ящика
	OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "----------------"
	$Uvolenniy = $TextBoxUvolForDelRights.Text
	If ((Get-Mailbox -ResultSize Unlimited -Identity $Uvolenniy) -ne $null) # Если существует почтовый ящик для пользователя
	{	
		$AccessUser = @()
		Get-MailboxPermission $Uvolenniy | 
		Where {
			-not ($_.User -like "ZAOEPS\Администраторы домена") -and
			-not ($_.User -like "ZAOEPS\Администраторы предприятия") -and
			-not ($_.User -like "ZAOEPS\dom_admin") -and
			-not ($_.User -like "ZAOEPS\IAbramov") -and
			-not ($_.User -like "ZAOEPS\sredkin") -and
#			-not ($_.User -like "ZAOEPS\VMusatov") -and
			-not ($_.User -like "ZAOEPS\Exchange Services") -and
			-not ($_.User -like "ZAOEPS\Exchange Organization Administrators") -and
			-not ($_.User -like "ZAOEPS\Exchange Trusted Subsystem") -and
			-not ($_.User -like "ZAOEPS\Organization Management") -and
			-not ($_.User -like "ZAOEPS\Exchange Enterprise Servers") -and
			-not ($_.User -like "ZAOEPS\Exchange View-Only Administrators") -and
			-not ($_.User -like "ZAOEPS\Delegated Setup") -and
			-not ($_.User -like "ZAOEPS\Exchange Domain Servers") -and
			-not ($_.User -like "ZAOEPS\Exchange Servers") -and
			-not ($_.User -like "NT AUTHORITY\NETWORK SERVICE") -and
			-not ($_.User -like "NT AUTHORITY\система") -and
			-not ($_.User -like "NT AUTHORITY\SYSTEM") -and
			-not ($_.User -like "ZAOEPS\ServerAdmin") -and
			-not ($_.User -like "ZAOEPS\Public Folder Management") -and
			-not ($_.User -like "NT AUTHORITY\SELF")
		} | %{$AccessUser += $_.User.SecurityIdentifier.Value}
		If ($AccessUser.Count -eq 0)
		{
			OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "Ни у кого нет прав на почтовый ящик"
			$NotManagedBy = $true
		}
		Else
		{
			OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "Права на почтовый ящик есть у:"
			For ($i=0; $i -lt $AccessUser.Count; $i++)
			{
				$Str = $AccessUser[$i]
				$UtIsUser = $null # Предположим, что объект, который имеет права на ящик, не является пользователем
				$ErrorActionPreference = "SilentlyContinue"
				$UtIsUser = Get-ADUser -Filter {SID -eq $Str} -Properties SID
				$ErrorActionPreference = "Continue"
				If ($UtIsUser -ne $null)
				{	# Если объект есть пользователь
					Get-ADUser -Filter {SID -eq $Str} -Properties SID , Enabled | 
					%{
						If ($_.Enabled) {$Enabled = " - активный"} Else {$Enabled = " - отключен"}
						OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text (">>> "+ $_.name + $Enabled)
					}
				}
				Else
				{	# Если объект не пользователь, т.е. объект - есть группа
					Get-ADGroup -Filter {SID -eq $Str} -Properties SID | %{OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text (">>> "+$_.SamAccountName+" ("+$_.Name+")")}
				}
			}		
		}
		OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "----------------"
		OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "Права Send-As:"
		# Примем, что ни у кого нет прав на отправку почты от имени владельца почтового ящика
		# Если в процессе перебора права будут обнаружены, изменим значение $NotSendAs на $false
		$NotSendAs = $true
		Get-adpermission $Uvolenniy | where {$_.ExtendedRights -like "Send-As"} |
		Where {$_.User -notlike "NT AUTHORITY\SELF"} | 
		%{
			$UtIsUser = $null # Предположим, что объект, который имеет права на ящик, не является пользователем
			$ErrorActionPreference = "SilentlyContinue"
			$UtIsUser = Get-ADUser ($_.User -replace "ZAOEPS\\")
			$ErrorActionPreference = "Continue"
			If ($UtIsUser -ne $null)
			{	# Если объект есть пользователь
				$User = Get-ADUser ($_.User -replace "ZAOEPS\\") -Properties Enabled
				If ($User.Enabled) {$Enabled = " - активный"} Else {$Enabled = " - отключен"}
				OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text (">>> "+$User.name + $Enabled)
			}
			Else
			{	# Если объект не пользователь, т.е. объект - есть группа
				Get-ADGroup -Filter {SID -like $_.User.SecurityIdentifier} -Properties SID | %{OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text ($_.SamAccountName+" ("+$_.Name+")")}
			}
			$NotSendAs = $false # Встретился пользователь у которого есть права на отправку почты от имени владельца почтового ящика
		}
	}
	Else {OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "У пользователя нет почтового ящика"}
	OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "----------------"
	$ButtonPostRights.Enabled = $true
	$ButtonUvolDeleteManagedBy.Enabled = $true
	$ButtonUvolDeleteSendAs.Enabled = $true
	If (($NotManagedBy -eq $true) -and ($NotSendAs -eq $true)) 
	{	# Если ни у кого нет никаких прав на почтовый ящик
		$MB = $null
		$MB = Get-Mailbox -Identity $Uvolenniy
		OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text ("Mailbox database: " + $MB.Database.Name)
		OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text ("Archive database: " + $MB.ArchiveDatabase.Name)
		OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text ("Primary SmtpAddressddress: "+$MB.PrimarySmtpAddress.Local +"@"+ $MB.PrimarySmtpAddress.Domain)
		If ( ($MB.PrimarySmtpAddress.Domain -like "zaoeps.local") -and ($MB.Database.Name -like "Removed Mailbox") -and (($MB.ArchiveDatabase.Name -like "Removed Mailbox") -or ($MB.ArchiveDatabase.Name -eq $null)) )
		{	# Если основной адрес *@zaoeps.local и почта с архивом в 'Removed Mailbox', то активируем чекбокс для отключения почтового ящика
			# И ищем контакты пользователя
			$Login = (Get-ADUser -Filter {DisplayName -like $Uvolenniy}).SamAccountName
			
			# Заполняем список несимметричных контактов, у которых в описании указан логин пользователя
			$NesimmetrContacts = $null
			$NesimmetrContacts = (Get-Contact).Guid | Get-ADObject -Properties Description | Where {$_.Description -like $Login}
			# Заполняем список локальных адресов для нисимметричных контактов, присутствующих в ящике пользователя
			$ExistLocalContactAddr = $false
			$LocalContactAddr = @()
			$EmailAdresses = (Get-Mailbox $Login).EmailAddresses
			For ($i=0; $i -lt $EmailAdresses.Count; $i++)
			{
				If (($EmailAdresses[$i].PrefixString -like "smtp") -and (($EmailAdresses[$i].AddressString -replace "@.+") -notlike $Login))
				{
					$LocalContactAddr+= $EmailAdresses[$i].AddressString -replace "@.+"
					$ExistLocalContactAddr = $true
				}
			}
			# Заполняем список обычных контактов пользователя
			$Login = "*"+$Login+"*"
			$MailContactslist = $null
			$MailContactslist = Get-MailContact -Filter {Alias -like $Login}
			
			If ( ($MailContactslist -eq $null) -and ($NesimmetrContacts -eq $null) -and ($ExistLocalContactAddr -eq $false) )
			{OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "Почтовые контакты не найдены"}
			Else 
			{
				OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "Найдены следующие почтовые контакты:" -ForegroundColor DarkGreen
				If ($MailContactslist -ne $null) {OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text $MailContactslist.Name}
				If ($NesimmetrContacts -ne $null) {OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text $NesimmetrContacts.Name}
				If ($ExistLocalContactAddr) {OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text $LocalContactAddr}
			}							
			$CheckBoxDisableMailbox.Enabled = $true
		}
		If (($MB.PrimarySmtpAddress.Domain -notlike "zaoeps.local") -and ($MB.Database.Name -like "Removed Mailbox") -and ($MB.ArchiveDatabase.Name -like "Removed Mailbox"))
		{	# Если основной адрес НЕ *@zaoeps.local и почта с архивом в 'Removed Mailbox', активируем кнопку удаления всех внешних smtp адресов
			$ButtonDelExtAddr.Enabled = $true
		}
	}
	$ButtonMoveRequest.Enabled = $true
	$ButtonDatabase.Enabled = $true
})

$ButtonPasteUvol.add_Click(
{
	$TextBoxUvol.Text = $TextBoxLogUvol.SelectedText
})

# Вставляем отображаемое имя пользователя в поле для уделения прав на почтовый ящик из окна логов
# Если под условие попадает более 1 пользователя или ни одного, заполняем текстом "BAD Selected"
$ButtonUvolDeleteManagedBy.add_Click(
{
	$CountUsers = 0;
	$ButtonUvolDeleteManagedBy.Enabled = $false
	$UserDeleteManagedBySelect = "*" + $TextBoxLogUvol.SelectedText + "*"
	$UserDeleteManagedBy = Get-ADUser -Filter {Name -like $UserDeleteManagedBySelect}
	$UserDeleteManagedBy | %{$CountUsers++}
	If ($UserDeleteManagedBy -eq $null) {$CountUsers = 0}
	If ($CountUsers -eq 1) {$TextBoxUvolDeleteManagedBy.Text = $UserDeleteManagedBy.name}
	Else {$TextBoxUvolDeleteManagedBy.Text = "BAD Select"}
	$ButtonUvolDeleteManagedBy.Enabled = $true
})

# Вставляем отображаемое имя пользователя в поле для уделения прав на отправку почты от имени из окна логов
# Если под условие попадает более 1 пользователя или ни одного, заполняем текстом "BAD Selected"
$ButtonUvolDeleteSendAs.add_Click(
{
	$CountUsers = 0;
	$ButtonUvolDeleteSendAs.Enabled = $false
	$UserDeleteSendAsSelect = "*" + $TextBoxLogUvol.SelectedText + "*"
	$UserDeleteSendAs = Get-ADUser -Filter {Name -like $UserDeleteSendAsSelect}
	$UserDeleteSendAs | %{$CountUsers++}
	If ($UserDeleteSendAs -eq $null) {$CountUsers = 0}
	If ($CountUsers -eq 1) {$TextBoxUvolDeleteSendAs.Text = $UserDeleteSendAs.name}
	Else {$TextBoxUvolDeleteSendAs.Text = "BAD Select"}
	$ButtonUvolDeleteSendAs.Enabled = $true
})

# Активация кнопки удаления прав на почтовый ящик только если уже указан пользователь - владелец почтового ящика
# и указан пользователь, которого требуется удалить из списка прав
$CheckBoxManagedByDelete.add_CheckedChanged(
{
	If ($CheckBoxManagedByDelete.Checked -eq $false) {$ButtonUvolDeleteManagedByDelete.Enabled = $false}
	Else
	{
		If (($TextBoxUvolForDelRights.Text -notlike "") -and ($TextBoxUvolDeleteManagedBy.Text -notlike "") -and
		($TextBoxUvolDeleteManagedBy.Text -notlike "BAD Select")) 
		{$ButtonUvolDeleteManagedByDelete.Enabled = $true}
		Else {$CheckBoxManagedByDelete.Checked = $false}
	}
})

# Активация кнопки удаления прав на отправку "от имени" только если уже указан пользователь - владелец почтового ящика
# и указан пользователь, которого требуется удалить из списка прав отправки "от имени"
$CheckBoxSendAsDelete.add_CheckedChanged(
{
	If ($CheckBoxSendAsDelete.Checked -eq $false) {$ButtonUvolDeleteSendAsDelete.Enabled = $false}
	Else
	{
		If (($TextBoxUvolForDelRights.Text -notlike "") -and ($TextBoxUvolDeleteSendAs.Text -notlike "") -and
		($TextBoxUvolDeleteSendAs.Text -notlike "BAD Select")) 
		{$ButtonUvolDeleteSendAsDelete.Enabled = $true}
		Else {$CheckBoxSendAsDelete.Checked = $false}
	}
})

$ButtonUvolDeleteManagedByDelete.add_Click(
{
	$ButtonUvolDeleteManagedByDelete.Enabled = $false
	$Permissions = $null
	$MailBoxUser = $TextBoxUvolForDelRights.Text
	$PermissionUser = $TextBoxUvolDeleteManagedBy.Text
	
	$Permissions = Get-MailboxPermission -Identity $MailBoxUser -User $PermissionUser
	OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text $Permissions
	If ($Permissions -eq $null) {OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "У пользователя нет никаких прав"}
	Else
	{
		Remove-MailboxPermission -Identity $MailBoxUser -User $PermissionUser -InheritanceType 'All' -AccessRights $Permissions.AccessRights -Confirm:$false
	}
	OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text ("Из ящика'" + $MailBoxUser + "'")
	OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text ("удалены права ManagedBy: '" + $PermissionUser + "'")
	OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "----------------"
	
	$TextBoxUvolDeleteManagedBy.Text = ""
	$CheckBoxManagedByDelete.Checked = $false
})

$ButtonUvolDeleteSendAsDelete.add_Click(
{
	$ButtonUvolDeleteSendAsDelete.Enabled = $false
	$MailBoxUser = $TextBoxUvolForDelRights.Text	
	Remove-ADPermission -Identity $TextBoxUvolForDelRights.Text -User $TextBoxUvolDeleteSendAs.Text -ExtendedRights "Send As" -Confirm:$false
	OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text ("Из ящика'" + $MailBoxUser + "'")
	OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text ("удалены права Send-As: '" + $TextBoxUvolDeleteSendAs.Text + "'")
	OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "----------------"	
	$TextBoxUvolDeleteSendAs.Text = ""
	$CheckBoxSendAsDelete.Checked = $false	
})

$CheckBoxDisableMailbox.add_CheckedChanged(
{
	If ($CheckBoxDisableMailbox.Checked -eq $false) {$ButtonDisableMailbox.Enabled = $false}
	Else {$ButtonDisableMailbox.Enabled = $true}
})

$ButtonDisableMailbox.add_Click(
{
	$ButtonDisableMailbox.Enabled = $false
	$CheckBoxDisableMailbox.Checked = $false
	$CheckBoxDisableMailbox.Enabled = $false
	
	# Отправляем сообщение об удалении форварда.
	# Для отправки почты на транспортных серверах Exchange требуется разрешение отправки с анонимных адресов для данного компьютера
	# ------------------------------------------
	$Forvard = (Get-ADUser -filter {displayname -like $TextBoxUvolForDelRights.Text}).samaccountname
	$StartTime = ((Get-Date).AddMinutes(-2))
	$emailFrom = "Automatic Message <automat@zaoeps.local>"
	$subject = "Удалить форвард "+$Forvard
	$body = "Требуется удалить форвард для: "+$Forvard
	$message = New-Object System.Net.Mail.MailMessage –ArgumentList $emailFrom, $emailTo, $subject, $body
	$ErrorActionPreference = "SilentlyContinue"
	If (Test-Connection cas.zaoeps.local) 
	{
		$smtpServer = "cas.zaoeps.local"
		$smtp = new-object Net.Mail.SmtpClient($smtpServer)
		Write-Host "Отправка письма об удалении форварда..." -ForegroundColor DarkGreen
		$smtp.Send($message)
		$EndTime = ((Get-Date).AddMinutes(2))
		$LetterFromB000334 = $null
		$LetterFromB000334 = Get-MessageTrackingLog -Sender "automat@zaoeps.local" -server b000334.zaoeps.local -Start $StartTime -End $EndTime
		$LetterFromB000335 = $null
		$LetterFromB000335 = Get-MessageTrackingLog -Sender "automat@zaoeps.local" -server b000335.zaoeps.local -Start $StartTime -End $EndTime
		If (($LetterFromB000334 -eq $null) -and ($LetterFromB000335 -eq $null))
		{OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "Внимание! Подтверждение отправки письма об удалении форварда НЕ получено"}
		Else {OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "Подтверждение отправки письма об удалении форварда получено"}
	}
	Else {Write-Host "Не пингуется почтовый сервер 'cas.zaoeps.local'. Письмо об удалении форварда не отправлено!" -ForegroundColor Red}	
	$ErrorActionPreference = "Continue"	
	# ------------------------------------------
	
	Disable-Mailbox -Identity $TextBoxUvolForDelRights.Text -Confirm:$false #-WhatIf
	OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "Команда на отключение почтового ящика отправлена"
	$ButtonDatabase.Enabled = $false
})

$ButtonDelExtAddr.add_Click(
{
	$UserDisplayName = $TextBoxUvolForDelRights.Text
	# Если в основном почтовом адресе почтовый домен не zaoeps.local, тогда выбираем именно его. 
	# Удаляем все неосновные smtp адреса. 
	# Если в основном почтовом адресе почтовый домен не "zaoeps.local", 
	# тогда записываем весь адрес в поле "Заметки" и выбираем "zaoeps.local" основным почтовым доменом
	$PrimarySmtpAddress = (Get-Mailbox $UserDisplayName).PrimarySmtpAddress # Запоминаем основной почтовый домен
	"Текущий основной почтовый домен: "+$PrimarySmtpAddress.Domain
	If ($PrimarySmtpAddress.Domain -ne "zaoeps.local") 
	{   # Если основной почтовый домен не "zaoeps.local"
		$User = Get-ADUser -filter {name -eq $UserDisplayName} -Properties info # Получаем пользователя с полем "Заметки"
		$User.info = $User.info+" Основной почтовый адрес до удаления внешних адресов: "+$PrimarySmtpAddress.Local+"@"+$PrimarySmtpAddress.Domain # В поле "Заметки" дописываем основной почтовый адрес
		"Добавление записи в поле 'Заметки(Notes)': "+" Основной почтовый адрес до удаления: "+$PrimarySmtpAddress.Local+"@"+$PrimarySmtpAddress.Domain
		Set-ADUser -Instance $User # Обновляем в AD поле "Заметки" для пользователя

		$PrimarySmtpAddress = $PrimarySmtpAddress.Local+"@zaoeps.local" # Формируем новый основной почтовый адрес
		"Установлен следующий основной адрес: "+$PrimarySmtpAddress
		Set-Mailbox $UserDisplayName -PrimarySmtpAddress $PrimarySmtpAddress -WarningAction SilentlyContinue # Записываем новый основной почтовый адрес
	}

	# Удаление второстепенных (неосновных) snmp адресов
	$EmailAddresses = $null
	$RightPrimaryAddress = $false # Проверка наличия правильного основного snmp адреса (zaoeps.local)
	Do # Цикл считывания списка адресов пользователя до тех пор пока он не обновится в Exchange (основной snmp адрес станет zaoeps.local)
	{
		Start-Sleep -s 5 # Задержка времени 5 секунд
		$EmailAddresses = (Get-Mailbox $UserDisplayName).EmailAddresses # Запоминаем список всех почтовых адресов
		For ($i=0; $i -lt $EmailAddresses.Count; $i++) # Для всех почтовых адресов в списке
		{	
			If (($EmailAddresses[$i].ProxyAddressString -cmatch "SMTP:") -and 
			($EmailAddresses[$i].ProxyAddressString -match "zaoeps.local"))
			{$RightPrimaryAddress = $true} # Запоминаем, что основной почтовый адрес обновился (стал user@zaoeps.local), чтобы завершить цикл
		}
	}
	While ($RightPrimaryAddress -eq $false) # Завершаем цикл, если основной SMTP адрес обновился (стал user@zaoeps.local)
	$CountOfAddressesBefore = $EmailAddresses.Count # Количество адресов у пользователя до обработки

	# Т.к. не получается формирования массива с объектами адресов ($NewEmailAddresses) по правилам Powershell,
	# найдено следующее решение из трех блоков

	# Подсчет количества элементов в новом списке адресов
	$CountForNewEmailAddresses = $EmailAddresses.Count # Количество элементов в новом списке адресов
	For ($i=0; $i -lt $EmailAddresses.Count; $i++)
	{If ($EmailAddresses[$i].ProxyAddressString -cmatch "smtp:") {$CountForNewEmailAddresses = $CountForNewEmailAddresses - 1}} # Получаем реальное количество адресов в новом списке

	# Формирование пустого массива списка новых адресов с пустыми элементами
	$NewEmailAddresses = @() # Список для формирования новых адресов (все старые за исключением второстепенных snmp адресов)
	For ($i=0; $i -lt $CountForNewEmailAddresses; $i++) # Для всего количества элементов в новом списке
	{$NewEmailAddresses += ""} # Создаем пустые элементы массива (нового списка адресов)

	# Заполнение нового списка адресов без неосновных snmp адресов
	$CountForNewEmailAddresses = 0
	For ($i=0; $i -lt $EmailAddresses.Count; $i++)
	{   # Для всех элементов в новом списке
		If ($EmailAddresses[$i].ProxyAddressString -cmatch "smtp:") {} 
		Else {$NewEmailAddresses[$CountForNewEmailAddresses] = $EmailAddresses[$i]; $CountForNewEmailAddresses++}
	}

	$CountOfAddressesAfter = $NewEmailAddresses.Count # Количество адресов у пользователя после обработки
	Set-Mailbox $UserDisplayName -EmailAddresses $NewEmailAddresses -WarningAction SilentlyContinue # Замещаем список адресов новым (где нет второстепенных почтовых адресов)

	If ($CountOfAddressesBefore -eq $CountOfAddressesAfter)
	{
		"Нет внешних адресов"
		OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "Нет внешних адресов"
	}
	Else
	{
		"Удалены все второстепенные smtp адреса"
		OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "Удалены все второстепенные smtp адреса"
	}
	
	$ButtonDelExtAddr.Enabled = $false
})

$ButtonMoveRequest.add_Click(
{
	$Request = $null
	$Request = Get-MoveRequest -Identity $TextBoxUvolForDelRights.Text
	If ($Request -eq $null) 
	{
		New-MoveRequest -Identity $TextBoxUvolForDelRights.Text -TargetDatabase 'Removed Mailbox' -BadItemLimit '50'
		OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "----------------"
		OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text ("Для пользователя '" + $TextBoxUvolForDelRights.Text + "' создан запрос на перемещение")
		$ButtonMoveRequestStatus.Enabled = $true
	}
	Else
	{
		OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "----------------"
		OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text ("Для пользователя '" + $TextBoxUvolForDelRights.Text + "' запрос на перемещение уже существует")
		$Status = (Get-MoveRequestStatistics $Request).Status
		$PercentComplete = (Get-MoveRequestStatistics $Request).PercentComplete
		$LabelMoveRequestStatus.Text = "Status:   " + $Status
		$LabelMoveRequestPercentCompleted.Text = "Percent: " + $PercentComplete
		If ($PercentComplete -eq 100) {$ButtonRemoveMoveRequest.Enabled = $true}
		Else {$ButtonMoveRequestStatus.Enabled = $true}
	}
	$ButtonMoveRequest.Enabled = $false
})

$ButtonRemoveMoveRequest.add_Click(
{
	Remove-MoveRequest $TextBoxUvolForDelRights.Text -Confirm:$false
	OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "----------------"
	OutputScrollingText -TextBoxOutput $TextBoxLogUvol -Text "Запрос на перемещение удален"
	$ButtonRemoveMoveRequest.Enabled = $false
	$LabelMoveRequestStatus.Text = "Status: "
	$LabelMoveRequestPercentCompleted.Text = "Percent:"
})

$ButtonMoveRequestStatus.add_Click(
{
	$Request = $null
	$Request = Get-MoveRequest -Identity $TextBoxUvolForDelRights.Text
	$Status = (Get-MoveRequestStatistics $Request).Status
	$PercentComplete = (Get-MoveRequestStatistics $Request).PercentComplete
	$LabelMoveRequestStatus.Text = "Status:   " + $Status
	$LabelMoveRequestPercentCompleted.Text = "Percent: " + $PercentComplete
	If ($PercentComplete -eq 100)
	{
		$ButtonRemoveMoveRequest.Enabled = $true
		$ButtonMoveRequestStatus.Enabled = $false
	}
})

$ButtonDatabase.add_Click(
{
	$MB = Get-Mailbox -Identity $TextBoxUvolForDelRights.Text -ResultSize Unlimited
	$LabelMailboxDatabase.Text = "Mailbox Database: " + $MB.Database.Name
	$LabelArciveDatabase.Text = "Archive Database: " + $MB.ArchiveDatabase.Name
})

$Form.ShowDialog()
