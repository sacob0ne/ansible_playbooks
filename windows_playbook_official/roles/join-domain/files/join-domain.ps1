#
# Script:: join-domain.ps1
# Joins a sesrver to a domain
#

param (
    [string]$username = "saipemnet\saxt0781",
    [string]$password = "<ENTER_PASSWORD>"
 )

$secretpassword= $password | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username,$secretpassword)
Add-Computer -DomainName "saipemnet.saipem.intranet" -Credential $credential -Force -Restart

eventcreate /t INFORMATION /ID 1 /L APPLICATION /SO "Ansible-Playbook" /D "joindomain-win: Added to the domain 'saipemnet.saipem.intranet'."
