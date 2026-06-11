$ErrorActionPreference = "Stop"

$vaultUri = if ($env:VAULT_URI) { $env:VAULT_URI } else { "http://localhost:8200" }
$vaultToken = if ($env:VAULT_TOKEN) { $env:VAULT_TOKEN } else { "dev-only-root-token" }
$dbUser = if ($env:SPRING_DATASOURCE_USERNAME) { $env:SPRING_DATASOURCE_USERNAME } else { "atomic_user" }
$dbPassword = if ($env:SPRING_DATASOURCE_PASSWORD) { $env:SPRING_DATASOURCE_PASSWORD } else { "change_me" }

$headers = @{
    "X-Vault-Token" = $vaultToken
}

$body = @{
    data = @{
        "spring.datasource.username" = $dbUser
        "spring.datasource.password" = $dbPassword
    }
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Method Post `
    -Uri "$vaultUri/v1/secret/data/atomic-backend" `
    -Headers $headers `
    -ContentType "application/json" `
    -Body $body | Out-Null

Write-Host "Vault secrets written to secret/data/atomic-backend"
