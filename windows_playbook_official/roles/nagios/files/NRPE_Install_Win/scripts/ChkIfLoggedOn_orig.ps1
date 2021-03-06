
param($computername, $username)

$risultato = Get-WmiObject Win32_LoggedOnUser -ComputerName $computername | Select Antecedent -Unique
$usrtmp = ""
for ($i = 0 ; $i -lt $risultato.count; $i++){
    $stringa = [string]($risultato[$i]) 
    $usrtmp = (($stringa.split("="))[3]).split('"')[1] 
    if ($username -eq $usrtmp){
        write-output "OK - User is LoggedOn"; 
        return 0;
    }
}
write-output "CRITICAL - User is NOT LoggedOn"
return 1;