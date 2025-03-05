# Conditional Access for Azure Purview

## Prerequisites
- Azure AD Premium P1/P2 license
- Purview account with Azure AD integration

## Implementation Steps

1. **Create Security Groups**
   ```powershell
   New-AzADGroup -DisplayName "Purview-HighPrivilege" `
     -MailNickname "PurviewAdmins"
   ```

2. **Configure Baseline Policy**
   ```json
   {
       "displayName": "Purview Admin Protection",
       "state": "enabled",
       "conditions": {
           "applications": {
               "includeApplications": ["purview-app-id"]
           },
           "users": {
               "includeGroups": ["Purview-HighPrivilege"]
           }
       },
       "grantControls": {
           "operator": "AND",
           "builtInControls": ["mfa", "compliantDevice"]
       }
   }
   ```

3. **Block Legacy Authentication**
   ```azurecli
   az rest --method POST --uri https://graph.microsoft.com/v1.0/policies/conditionalAccessPolicies \
     --body @legacy-auth-block.json
   ```

## Monitoring
```kql
SigninLogs 
| where AppId == "purview-app-id"
| summarize attempts = count() by ResultType, UserPrincipalName
```

## Best Practices
- Require phishing-resistant MFA for Data Owner roles
- Use Azure AD Privileged Identity Management (PIM) for JIT access
- Enable session timeout after 15 minutes of inactivity
