# Microsoft Purview Compliance Reporting Templates 📋

**Automated Compliance Workflows for Major Regulations**  
*Last updated: 3/3/2025 

---

## Table of Contents
1. [GDPR Article 30 Workbook](#1-gdpr-article-30-workbook)  
2. [HIPAA Audit Package](#2-hipaa-audit-package)  
3. [ISO 27001 Reporting Suite](#3-iso-27001-reporting-suite)  
4. [PCI DSS Evidence Collector](#4-pci-dss-evidence-collector)  
5. [CCPA Data Inventory](#5-ccpa-data-inventory)  
6. [Implementation Guide](#6-implementation-guide)  

---

## 1. GDPR Article 30 Workbook
**Automated Record of Processing Activities (ROPA)**  

```powershell
# Generate GDPR Article 30 Report
Connect-PurviewAccount -Endpoint "https://{account}.purview.azure.com"

$report = Get-PurviewDataSource | ForEach-Object {
    [PSCustomObject]@{
        DataSource = $_.Name
        ProcessingPurpose = (Get-PurviewClassification -DataSource $_.Name).BusinessMetadata.Purpose
        DataSubjects = (Get-PurviewDataSubjectType -DataSource $_.Name).Types
        ThirdCountries = $_.Location | Where-Object { $_ -notin $EUCountries }
    }
}

$report | Export-Excel -Path "GDPR-Article30-Report-$(Get-Date -Format yyyyMMdd).xlsx"
```

**Template Components**:
- [Download Power BI ROPA Dashboard](gdpr-ropa.pbit)
- [Data Subject Rights Tracker](templates/gdpr-rights-tracker.csv)
- [Third Country Transfer Impact Assessment](templates/gdpr-tia.docx)

---

## 2. HIPAA Audit Package
**PHI Protection & Access Monitoring**  

```kql
// Log Analytics: PHI Access Audit
PurviewDataAccessLogs
| where DataClassifications has "PHI"
| project TimeGenerated, UserPrincipalName, ResourceId, OperationName
| join kind=inner (SigninLogs) on UserPrincipalName
| extend Location = LocationDetails.countryName
```

**Key Reports**:
1. **Required Reports**:
   - [Breach Notification Checklist](templates/hipaa-breach-checklist.md)
   - [BAE (Business Associate Agreement) Tracker](templates/hipaa-baa-tracker.xlsx)

2. **Automated Evidence**:
   ```python
   # Verify Encryption Status
   from azure.purview.scanning import PurviewClient
   client = PurviewClient()
   for source in client.data_sources.list():
       if source.scan_results.classifications.has_phi:
           assert source.properties.encryption.status == "Enabled"
   ```

---

## 3. ISO 27001 Reporting Suite
**Information Security Management System (ISMS) Evidence**  

```bash
# Export Audit Logs for Annex A Controls
az monitor activity-log list --namespace "Microsoft.Purview" \
  --offset 90d \
  --query "[].{Operation:operationName.localizedValue, User:claims.name}" \
  -o json > ISMS-Audit-Logs.json
```

**Template Toolkit**:
- [Risk Assessment Matrix](templates/iso-risk-matrix.xlsx)
- [Statement of Applicability Generator](scripts/iso-soa-generator.ps1)
- [Continuous Monitoring Logic App](templates/iso-monitoring-logicapp.json)

**Sample Control Mapping**:
| ISO Control | Purview Feature | Evidence Source |
|-------------|-----------------|-----------------|
| **A.12.4** | Data Lineage | Azure Data Factory Logs |
| **A.13.2** | Information Protection | Sensitivity Label Reports |
| **A.18.1** | Data Catalog | Asset Inventory Export |

---

## 4. PCI DSS Evidence Collector
**Cardholder Data Environment (CDE) Reporting**  

```powershell
# PCI Scan: Find PAN Data
$panResults = Search-Purview -Query "CreditCardNumber" 
  -Filter "Classification eq 'Microsoft.CreditCardNumber'"
$panResults | Select-Object ResourceName, Location, LastScanDate 
  | Export-Csv -Path "PCI-PAN-Report.csv"
```

**Compliance Kit**:
- [ASV Scan Checklist](templates/pci-asv-checklist.pdf)
- [Segmentation Test Script](scripts/pci-network-test.ps1)
- [Quarterly SAQ Generator](templates/pci-saq.docx)

**Automated Validation**:
```kql
// Sentinel: PAN Data Exfiltration Alert
SecurityEvent
| where EventID == 4688
| where ProcessCommandLine has "CreditCardNumber"
| join kind=inner (PurviewDataMap 
    | where Classification == "Microsoft.CreditCardNumber") on $left.ObjectName == $right.ResourceId
```

---

## 5. CCPA Data Inventory
**California Consumer Privacy Act Reporting**  

```python
# Generate Data Inventory
from azure.purview.catalog import PurviewClient
client = PurviewClient()

consumer_data = []
for asset in client.search_entities("PersonalInformation"):
    if asset.classifications.contains("CaliforniaResident"):
        consumer_data.append({
            "Asset": asset.name,
            "Location": asset.location,
            "BusinessPurpose": asset.businessMetadata.purpose
        })

pd.DataFrame(consumer_data).to_excel("CCPA-Data-Inventory.xlsx")
```

**Template Features**:
- [Right to Delete Workflow](templates/ccpa-deletion-flow.png)
- [Opt-Out Mechanism Tracker](scripts/ccpa-optout-monitor.ps1)
- [Third-Party Sharing Register](templates/ccpa-third-parties.csv)

---

## 6. Implementation Guide
**Deploy Compliance Automation**  

1. **Prerequisites**  
   ```bash
   # Install Purview PowerShell Module
   Install-Module -Name Az.Purview -AllowPrerelease
   ```

2. **Deploy Templates**  
   ```powershell
   # Deploy GDPR Power BI Dashboard
   New-AzResourceGroupDeployment -ResourceGroupName "Compliance-RG" `
     -TemplateFile "templates/gdpr-dashboard.json" `
     -PurviewAccountName "pv-audit"
   ```

3. **Schedule Reports**  
   ```azurecli
   # Create GDPR Report Schedule
   az automation schedule create --name "GDPR-Monthly" `
     --resource-group "Compliance-RG" `
     --frequency Day --interval 30 `
     --start-time "2023-01-01T00:00:00+00:00"
   ```

---

## 🔗 Additional Resources
- [Purview Compliance Manager Integration](https://learn.microsoft.com/en-us/microsoft-365/compliance/compliance-manager?view=o365-worldwide)
- [NIST CSF Purview Mapping](https://nvlpubs.nist.gov/nistpubs/CSWP/NIST.CSWP.04162018.pdf)
- [FedRAMP Moderate Compliance Kit](https://marketplace.azurecr.io/microsoft/fedramp-purview)


**Pro Tips**:
1. Use [Azure Policy](https://learn.microsoft.com/en-us/azure/governance/policy/) to auto-remediate compliance gaps
2. Integrate with [Microsoft Compliance Manager](https://learn.microsoft.com/en-us/microsoft-365/compliance/compliance-manager?view=o365-worldwide) for cross-cloud assessments
3. Leverage [Purview's Business Glossary](https://learn.microsoft.com/en-us/azure/purview/concept-business-glossary) for regulation-specific term mapping

**Contribution Guidelines**:
```markdown
# How to Contribute
1. Fork the repository
2. Add new compliance templates to `/templates/{regulation}`
3. Include validation scripts in `/scripts`
4. Submit PR with [Compliance] tag
