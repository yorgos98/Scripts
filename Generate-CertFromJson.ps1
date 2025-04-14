param (
    [string]$JsonPath = ".\cert-info.json"
)

# Load the JSON
if (-Not (Test-Path $JsonPath)) {
    Write-Error "JSON file not found at path: $JsonPath"
    exit 1
}

$certInfo = Get-Content $JsonPath | ConvertFrom-Json

# Build subject string for OpenSSL
$subject = "/C=$($certInfo.Country)/ST=$($certInfo.State)/L=$($certInfo.Locality)/O=$($certInfo.Organization)/OU=$($certInfo.OrganizationalUnit)/CN=$($certInfo.CommonName)/emailAddress=$($certInfo.Email)"

# Run OpenSSL to generate key and cert
$opensslCmd = "openssl req -x509 -nodes -newkey rsa:2048 -keyout `"$($certInfo.KeyOut)`" -out `"$($certInfo.CertOut)`" -days $($certInfo.Days) -subj `"$subject`""
Write-Host "Running: $opensslCmd"
Invoke-Expression $opensslCmd

# Generate random alphanumeric password (safe for shell)
$chars = ([char[]]'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')
$password = -join ($chars | Get-Random -Count 16)

# Save password to a file
$passwordPath = "$($certInfo.KeyOut).password.txt"
Set-Content -Path $passwordPath -Value $password

# Generate PFX file using OpenSSL
$pfxOut = "$($certInfo.CertOut).pfx"
$opensslPfxCmd = "openssl pkcs12 -export -out `"$pfxOut`" -inkey `"$($certInfo.KeyOut)`" -in `"$($certInfo.CertOut)`" -password pass:$password"
Write-Host "Running: $opensslPfxCmd"
Invoke-Expression $opensslPfxCmd

# Output result
if ((Test-Path $certInfo.KeyOut) -and (Test-Path $certInfo.CertOut) -and (Test-Path $pfxOut)) {
    Write-Host "`n✅ Certificate, key, and PFX successfully generated:"
    Write-Host " - Key:  $($certInfo.KeyOut)"
    Write-Host " - Cert: $($certInfo.CertOut)"
    Write-Host " - PFX:  $pfxOut"
    Write-Host " - Password saved to: $passwordPath"
} else {
    Write-Error "❌ Failed to generate one or more output files."
}
