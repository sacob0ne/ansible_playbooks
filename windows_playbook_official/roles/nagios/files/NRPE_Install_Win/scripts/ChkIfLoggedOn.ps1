
param($computername, $username)

$risultato = Get-WmiObject Win32_LoggedOnUser -ComputerName $computername 2>$null | Select Antecedent -Unique
if (!$?)
{
	write-output "UNKNOWN - Caught Exception Calling WMI-Win32_LoggedOnUser on $computername";
	exit 3; 
}

$usrtmp = ""

for ($i = 0 ; $i -lt $risultato.count; $i++){
    $stringa = [string]($risultato[$i]) 
    $usrtmp = (($stringa.split("="))[3]).split('"')[1] 
    if ($username -eq $usrtmp){
        write-output "OK - User: $username logged on $computername";
        exit 0;
    }
}
write-output "CRITICAL - User: $username is NOT logged on $computername";
exit 2;