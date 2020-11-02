# Powershell script to automatically add a VPN connection and its certificate

$connectionName = "VPN-IKEv2"
$server = "linusplus.duckdns.org"
$certificate = .\certificate.crt"

# Do not modify below this line

try
{
	Add-VpnConnection -Name $connectionName -ServerAddress $server -TunnelType "Ikev2"
	Write-Output "VPN connection $connectionName added successfully"
}
catch
{
	Write-Output "Warning: VPN connection $connectionName already exists, attributes will be overwritten"
}
Set-VpnConnectionIPsecConfiguration -ConnectionName $connectionName -AuthenticationTransformConstants SHA196 -CipherTransformConstants AES256 -EncryptionMethod AES256 -IntegrityCheckMethod SHA256 -PfsGroup None -DHGroup Group14 -PassThru -Force
try
{
	Import-Certificate -FilePath $certificate -CertStoreLocation cert:\LocalMachine\Root
	Write-Output "Certificate imported successfully"
}
catch [UnauthorizedAccessException]
{
	Write-Output "Error: cannot add certificate, run the script with admin rights"
}
catch [System.IO.FileNotFoundException]
{
	Write-Output "Error: $certificate does not exists"
}
