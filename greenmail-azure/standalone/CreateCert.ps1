param(
	[Parameter(Mandatory=$false, HelpMessage="DNS name to include in the certificate")]
	[string]$DnsName = "greenmail.domain.com",

	[Parameter(Mandatory=$false, HelpMessage="Password used to protect the exported .pfx")]
	[string]$Password = "changeme"
)

Write-Host "Creating self-signed certificate for DNS name '$DnsName'" -ForegroundColor Cyan
$certificate = New-SelfSignedCertificate -DnsName $DnsName -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears(1)

$SecurePassword = ConvertTo-SecureString -String $Password -Force -AsPlainText
Export-PfxCertificate -Cert $certificate -FilePath ".\greenmail.p12" -Password $SecurePassword | Out-Null

Write-Host "Certificate exported to .\greenmail.p12" -ForegroundColor Green
