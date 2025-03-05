# Purview Data Breach Response Protocol

## Identification Phase
1. **Detect Anomalies**
   ```kql
   PurviewDataAccessLogs
   | where OperationName == "Export"
   | where DataClassifications has "Confidential"
   | where UserAgent != "PurviewScanningEngine"
   ```

2. **Validate Alert**
   ```powershell
   Get-PurviewDataAccess -UserPrincipalName "suspect@contoso.com" -Last 24h
   ```

## Containment Phase
1. **Immediate Actions**
   ```bash
   # Suspend Purview scanning
   az purview account update --name "contoso-purview" \
     --resource-group "security-rg" \
     --managed-resource-group "quarantine-rg"
   ```

2. **Preserve Evidence**
   ```powershell
   Start-AzStorageBlobCopy -SrcContainer "audit-logs" `
     -DestContainer "forensics-$(Get-Date -Format yyyyMMdd)"
   ```

## Eradication Phase
1. **Rotate Credentials**
   ```powershell
   ./credential-rotation-automation.ps1 -FullRotation -Force
   ```

2. **Review Data Lineage**
   ```python
   from azure.purview.catalog import PurviewClient
   client = PurviewClient()
   breach_asset = client.entities.get_by_guid("affected-asset-guid")
   print(client.lineage.get(breach_asset.id))
   ```

## Recovery Phase
1. **Validate Backups**
   ```bash
   az purview account show --name "contoso-purview" \
     --query "properties.eventHubNamespace"
   ```

2. **Communicate Resolution**
   - Internal stakeholders within 2 hours
   - Regulators within 72 hours (GDPR)

## Post-Incident
- Conduct blameless post-mortem
- Update classification rules
