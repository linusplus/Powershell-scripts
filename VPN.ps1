try
{
	Add-VpnConnection -Name "VPN-IKEv2" -ServerAddress linusplus.duckdns.org -TunnelType "Ikev2"
	Write-Output "VPN connection added successfully"
}
catch
{
	Write-Output "Warning: VPN connection VPN-IKEv2 already exists, attributes will be overwritten"
}
Set-VpnConnectionIPsecConfiguration -ConnectionName "VPN-IKEv2" -AuthenticationTransformConstants SHA196 -CipherTransformConstants AES256 -EncryptionMethod AES256 -IntegrityCheckMethod SHA256 -PfsGroup None -DHGroup Group14 -PassThru -Force
try
{
	Import-Certificate -FilePath ".\certificate.crt" -CertStoreLocation cert:\LocalMachine\Root
	Write-Output "Certificate imported successfully"
}
catch [UnauthorizedAccessException]
{
	Write-Output "Error: cannot add the certificate, run the script with admin rights"
}