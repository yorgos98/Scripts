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

# Run OpenSSL
$opensslCmd = "openssl req -x509 -nodes -newkey rsa:2048 -keyout `"$($certInfo.KeyOut)`" -out `"$($certInfo.CertOut)`" -days $($certInfo.Days) -subj `"$subject`""
Write-Host "Running: $opensslCmd"
Invoke-Expression $opensslCmd

# Generate random password using only PowerShell
$chars = ([char[]]'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=') | Get-Random -Count 16
$password = -join $chars

# Save password to a file
$passwordPath = "$($certInfo.KeyOut).password.txt"
Set-Content -Path $passwordPath -Value $password

# Output result
if ((Test-Path $certInfo.KeyOut) -and (Test-Path $certInfo.CertOut)) {
    Write-Host "`n✅ Certificate and key successfully generated:"
    Write-Host " - Key:  $($certInfo.KeyOut)"
    Write-Host " - Cert: $($certInfo.CertOut)"
    Write-Host " - Password saved to: $passwordPath"
} else {
    Write-Error "❌ Failed to generate certificate or key."
}
