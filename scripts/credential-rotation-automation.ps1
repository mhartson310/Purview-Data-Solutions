<#
.SYNOPSIS
Automates credential rotation for Purview scanning accounts

.DESCRIPTION
1. Retrieves current credentials from Key Vault
2. Creates new credentials in target systems
3. Updates Purview scan configurations
4. Tests new credentials
5. Removes old credentials
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$KeyVaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$PurviewAccountName
)

# Connect to services
Connect-AzAccount -Identity
$purview = Get-AzPurviewAccount -Name $PurviewAccountName
$kv = Get-AzKeyVault -VaultName $KeyVaultName

# Rotate credentials for each data source
$dataSources = Get-AzPurviewDataSource -AccountName $purview.Name

foreach ($ds in $dataSources) {
    try {
        $secretName = "$($ds.Name)-cred"
        $currentSecret = Get-AzKeyVaultSecret -VaultName $kv.VaultName -Name $secretName
        
        # Generate new credential
        $newSecret = New-AzADServicePrincipal -SkipAssignment
        $newSecretValue = ConvertTo-SecureString $newSecret.PasswordCredentials.SecretText -AsPlainText -Force
        
        # Update Key Vault
        Set-AzKeyVaultSecret -VaultName $kv.VaultName -Name $secretName -SecretValue $newSecretValue
        
        # Update Purview
        Update-AzPurviewDataSourceCredential -AccountName $purview.Name `
          -Name $ds.CredentialReferenceName `
          -CredentialType "ServicePrincipal" `
          -Credential $newSecret
        
        # Validate connection
        Test-AzPurviewDataSource -AccountName $purview.Name -Name $ds.Name
        
        # Remove old credential
        Remove-AzADServicePrincipal -ObjectId $currentSecret.Id
    }
    catch {
        Write-Error "Rotation failed for $($ds.Name): $_"
        exit 1
    }
}

Write-Host "Credential rotation completed successfully" -ForegroundColor Green
