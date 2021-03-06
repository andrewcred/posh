# Померять размер ящиков и архивов
Clear-Host
$DisplayNames = Get-Content -path "d:\UserWithoutActiveBox.txt"
$MailboxesStatistics = @()
$ArchiveStatistics = @()
ForEach ($DisplayName in $DisplayNames)
{
	$DisplayName = $DisplayName -replace " ARCHIV.+"
	$MailboxesStatistics += Get-MailboxStatistics $DisplayName
	$ArchiveStatistics += Get-MailboxStatistics $DisplayName -Archive
}

$TotalItemSizeAll = 0
$TotalItemSizeArchAll = 0

$Big = 0
For ($i=0; $i -lt $MailboxesStatistics.Count; $i++)
{
	$TotalItemSize = $MailboxesStatistics[$i].TotalItemSize.Value -replace " byt.+"
	$TotalItemSize = $TotalItemSize -replace ".+\("
	$TotalItemSize = $TotalItemSize -replace ","
	$TotalItemSizeAll = $TotalItemSizeAll + $TotalItemSize

	If ($ArchiveStatistics[$i].TotalItemSize.Value -ne $null)
	{
		$TotalItemSize = $ArchiveStatistics[$i].TotalItemSize.Value -replace " byt.+"
		$TotalItemSize = $TotalItemSize -replace ".+\("
		$TotalItemSize = $TotalItemSize -replace ","
		$TotalItemSizeArchAll = $TotalItemSizeArchAll + $TotalItemSize
	}
}
"Ящики"
$TotalItemSizeAll/1Gb
"Gb"
"---"
"Архивы"
$TotalItemSizeArchAll/1Gb
"Gb"
