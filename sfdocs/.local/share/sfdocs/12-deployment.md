# Deployment & DevOps Cheatsheet

---

## SF CLI Project Structure

```
my-project/
├── sfdx-project.json        # Project config (required)
├── .forceignore              # Files to exclude from sync
├── .sf/                     # Local CLI state
├── config/
│   └── project-scratch-def.json  # Scratch org definition
├── force-app/               # Default package directory
│   └── main/
│       └── default/
│           ├── classes/
│           ├── triggers/
│           ├── lwc/
│           ├── aura/
│           ├── objects/
│           ├── permissionsets/
│           ├── layouts/
│           └── pages/
├── manifest/
│   └── package.xml          # Deployment manifest
└── scripts/
    └── apex/                # Anonymous Apex scripts
```

### sfdx-project.json

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true,
      "package": "MyPackage",
      "versionName": "ver 1.0",
      "versionNumber": "1.0.0.NEXT"
    },
    {
      "path": "utils",
      "default": false
    }
  ],
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "60.0"
}
```

---

## Manifest File (package.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <version>60.0</version>

    <types>
        <members>MyController</members>
        <members>MyService</members>
        <name>ApexClass</name>
    </types>

    <types>
        <members>AccountTrigger</members>
        <name>ApexTrigger</name>
    </types>

    <types>
        <members>Account.My_Field__c</members>
        <name>CustomField</name>
    </types>

    <types>
        <members>My_Object__c</members>
        <name>CustomObject</name>
    </types>

    <types>
        <members>myLwcComponent</members>
        <name>LightningComponentBundle</name>
    </types>

    <types>
        <members>My_Flow</members>
        <name>Flow</name>
    </types>

    <types>
        <members>Admin_Perms</members>
        <name>PermissionSet</name>
    </types>

    <!-- Wildcard: retrieve ALL of a type -->
    <types>
        <members>*</members>
        <name>ApexClass</name>
    </types>
</Package>
```

### Generate package.xml from Org

```bash
# Generate manifest from org
sf project generate manifest --from-org myOrg --output-dir manifest/

# Generate manifest from local source
sf project generate manifest --source-dir force-app --name package.xml
```

---

## Common Metadata API Types

| Metadata Type              | Directory Name     | Suffix              |
|----------------------------|--------------------|----------------------|
| `ApexClass`                | `classes/`         | `.cls`               |
| `ApexTrigger`              | `triggers/`        | `.trigger`           |
| `ApexPage`                 | `pages/`           | `.page`              |
| `ApexComponent`            | `components/`      | `.component`         |
| `LightningComponentBundle` | `lwc/`             | (directory-based)    |
| `AuraDefinitionBundle`     | `aura/`            | (directory-based)    |
| `CustomObject`             | `objects/`         | `.object-meta.xml`   |
| `CustomField`              | (inside objects)   | `.field-meta.xml`    |
| `Layout`                   | `layouts/`         | `.layout-meta.xml`   |
| `Flow`                     | `flows/`           | `.flow-meta.xml`     |
| `PermissionSet`            | `permissionsets/`  | `.permissionset-meta.xml` |
| `Profile`                  | `profiles/`        | `.profile-meta.xml`  |
| `CustomTab`                | `tabs/`            | `.tab-meta.xml`      |
| `StaticResource`           | `staticresources/` | `.resource-meta.xml` |
| `CustomLabel`              | `labels/`          | `.labels-meta.xml`   |
| `FlexiPage`                | `flexipages/`      | `.flexipage-meta.xml`|
| `ValidationRule`           | (inside objects)   | `.validationRule-meta.xml` |
| `CustomMetadata`           | `customMetadata/`  | `.md-meta.xml`       |
| `EmailTemplate`            | `email/`           | `.email-meta.xml`    |

---

## Source Tracking: Deploy & Retrieve

### Deploy to Org

```bash
# Deploy entire default package directory
sf project deploy start --source-dir force-app

# Deploy specific directory
sf project deploy start --source-dir force-app/main/default/classes

# Deploy specific metadata types
sf project deploy start --metadata ApexClass
sf project deploy start --metadata ApexClass:MyController
sf project deploy start --metadata "ApexClass:MyController,ApexTrigger:AccountTrigger"

# Deploy using manifest
sf project deploy start --manifest manifest/package.xml

# Deploy to a specific org
sf project deploy start --source-dir force-app --target-org myOrg

# Dry run (validate only, no deploy)
sf project deploy start --source-dir force-app --dry-run

# Deploy with test execution
sf project deploy start --source-dir force-app --test-level RunLocalTests

# Run specific tests during deploy
sf project deploy start --source-dir force-app \
  --test-level RunSpecifiedTests \
  --tests MyControllerTest \
  --tests MyServiceTest

# Deploy and wait (default 33 min)
sf project deploy start --source-dir force-app --wait 60

# Async deploy
sf project deploy start --source-dir force-app --async
sf project deploy report --job-id 0Af...

# Resume a deploy
sf project deploy resume --job-id 0Af...

# Quick deploy (after successful validation)
sf project deploy quick --job-id 0Af...
```

### Retrieve from Org

```bash
# Retrieve entire default package directory
sf project retrieve start --source-dir force-app

# Retrieve specific metadata
sf project retrieve start --metadata ApexClass
sf project retrieve start --metadata ApexClass:MyController

# Retrieve using manifest
sf project retrieve start --manifest manifest/package.xml

# Retrieve from specific org
sf project retrieve start --source-dir force-app --target-org myOrg

# Retrieve to a specific directory
sf project retrieve start --metadata ApexClass --output-dir retrieved/

# Retrieve and ignore conflicts
sf project retrieve start --source-dir force-app --ignore-conflicts
```

### Source Tracking Commands (Scratch Orgs / Sandboxes with Tracking)

```bash
# See what changed locally or in org
sf project deploy preview
sf project retrieve preview

# Deploy only local changes (tracked)
sf project deploy start

# Retrieve only org changes (tracked)
sf project retrieve start

# Resolve conflicts
sf project deploy start --ignore-conflicts
sf project retrieve start --ignore-conflicts
```

---

## Test Levels

| Level                  | When to Use                          | Description                             |
|------------------------|--------------------------------------|-----------------------------------------|
| `NoTestRun`            | Non-production deploys               | Skip all tests                          |
| `RunSpecifiedTests`    | Targeted validation                  | Run only named test classes             |
| `RunLocalTests`        | Production deploy (default)          | All tests except managed package tests  |
| `RunAllTestsInOrg`     | Full validation                      | Every test in the org                   |

```bash
# No tests
sf project deploy start --source-dir force-app --test-level NoTestRun

# Specific tests
sf project deploy start --source-dir force-app \
  --test-level RunSpecifiedTests \
  --tests MyControllerTest --tests MyServiceTest

# Local tests (required for production)
sf project deploy start --source-dir force-app --test-level RunLocalTests

# All tests
sf project deploy start --source-dir force-app --test-level RunAllTestsInOrg
```

> **Production deploys** require `RunLocalTests` or higher. At least 75% overall code coverage is mandatory.

---

## Development Models

### Org Development Model

- Work directly against a shared org (sandbox/production)
- Use `sf project deploy start` / `sf project retrieve start`
- No source tracking (unless sandbox tracking is enabled)
- Good for: admin-heavy teams, existing orgs, quick fixes

```bash
# Typical workflow
sf project retrieve start --metadata ApexClass:MyController --target-org mySandbox
# ... edit locally ...
sf project deploy start --source-dir force-app/main/default/classes --target-org mySandbox
```

### Package Development Model (Recommended)

- Source of truth is version control (Git)
- Use scratch orgs for isolated development
- Package your changes as unlocked/managed packages
- Source tracking enabled by default

```bash
# Typical workflow
sf org create scratch --definition-file config/project-scratch-def.json --alias dev
sf project deploy start --source-dir force-app       # push source
# ... develop and test ...
sf project retrieve start --source-dir force-app     # pull changes
git add . && git commit -m "feature: new component"
sf package version create --package MyPkg --wait 30   # package it
```

---

## Scratch Orgs

### Scratch Org Definition File (`config/project-scratch-def.json`)

```json
{
  "orgName": "My Scratch Org",
  "edition": "Developer",
  "features": [
    "EnableSetPasswordInApi",
    "Communities",
    "ServiceCloud",
    "MarketingUser"
  ],
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    },
    "securitySettings": {
      "passwordPolicies": {
        "enableSetPasswordInApi": true
      }
    },
    "mobileSettings": {
      "enableS1EncryptedStoragePref2": false
    }
  }
}
```

### Scratch Org Commands

```bash
# Create scratch org (default 7-day expiry)
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias myScratch \
  --duration-days 30 \
  --set-default

# Deploy source to scratch org
sf project deploy start --source-dir force-app --target-org myScratch

# Retrieve changes from scratch org
sf project retrieve start --source-dir force-app --target-org myScratch

# Open scratch org in browser
sf org open --target-org myScratch

# List scratch orgs
sf org list --all

# Delete scratch org
sf org delete scratch --target-org myScratch --no-prompt

# Generate password
sf org generate password --target-org myScratch

# View org details
sf org display --target-org myScratch
```

---

## Sandboxes

| Type           | Data     | Storage     | Refresh  | Use Case                  |
|----------------|----------|-------------|----------|---------------------------|
| **Developer**  | No data  | 200 MB      | 1 day    | Dev & unit testing        |
| **Developer Pro** | No data | 1 GB     | 1 day    | Larger dev & testing      |
| **Partial Copy** | Sample (template) | 5 GB | 5 days | QA with subset of data |
| **Full**       | Full copy | Same as prod | 29 days | Staging, UAT, load test  |

```bash
# Create sandbox
sf org create sandbox \
  --definition-file config/sandbox-def.json \
  --alias devSandbox \
  --set-default \
  --target-org production

# Sandbox definition file
cat config/sandbox-def.json
```

```json
{
  "sandboxName": "devbox",
  "licenseType": "DEVELOPER",
  "autoActivate": true
}
```

```bash
# Resume sandbox creation (long-running)
sf org resume sandbox --name devbox --target-org production

# List sandboxes
sf org list --all

# Delete sandbox
sf org delete sandbox --target-org devSandbox --no-prompt

# Login to sandbox
sf org login web --instance-url https://test.salesforce.com --alias devSandbox
```

---

## Change Sets

- UI-based deployment between related orgs (sandbox → production)
- **Outbound Change Set**: created in source org, components selected manually
- **Inbound Change Set**: received in target org, must be deployed manually
- No version control, no rollback
- **Setup → Deployment Settings**: authorize connections between orgs first
- **Setup → Outbound Change Sets → New**: add components → Upload
- **Setup → Inbound Change Sets**: select → Deploy

**Limitations:**
- Cannot delete components
- Cannot deploy to unrelated orgs
- No automation/scripting
- Manual, error-prone for large deployments

> Prefer SF CLI or packaging for anything beyond simple config changes.

---

## Unlocked Packages

Modular, upgradeable, no namespace lock-in. Best for organizing internal metadata.

```bash
# Create package
sf package create \
  --name MyUnlockedPkg \
  --package-type Unlocked \
  --path force-app \
  --target-dev-hub devHub

# Create package version
sf package version create \
  --package MyUnlockedPkg \
  --installation-key mySecret123 \
  --wait 30 \
  --code-coverage

# List versions
sf package version list --packages MyUnlockedPkg

# Install package in target org
sf package install \
  --package MyUnlockedPkg@1.0.0-1 \
  --installation-key mySecret123 \
  --target-org targetOrg \
  --wait 20

# Promote to released (cannot be deleted)
sf package version promote --package MyUnlockedPkg@1.0.0-1
```

## 2GP Managed Packages

For ISVs / AppExchange. Namespace-locked, IP protection, LMA support.

```bash
# Create managed package (requires namespace)
sf package create \
  --name MyManagedPkg \
  --package-type Managed \
  --path force-app \
  --target-dev-hub devHub

# Same version create workflow as unlocked
sf package version create \
  --package MyManagedPkg \
  --installation-key mySecret \
  --wait 30 \
  --code-coverage
```

| Feature           | Unlocked         | 2GP Managed          |
|-------------------|------------------|----------------------|
| Namespace         | Optional         | Required             |
| IP Protection     | No (source visible) | Yes (obfuscated)  |
| AppExchange       | No               | Yes                  |
| Upgradeable       | Yes              | Yes                  |
| Uninstallable     | Yes              | With restrictions    |

---

## .forceignore

Controls which files are excluded from source tracking and deployments.

```
# .forceignore

# Ignore profiles (manage separately)
**/profiles/**

# Ignore specific metadata
**/appMenus/**
**/objectTranslations/**

# Ignore admin profile
force-app/main/default/profiles/Admin.profile-meta.xml

# Ignore all permission set groups
**/*.permissionsetgroup-meta.xml

# Ignore by pattern
**/__tests__/**
**/jsconfig.json

# Ignore specific LWC
force-app/main/default/lwc/myTestComponent/**

# Ignore all static resources over pattern
**/staticresources/*.json
```

---

## CI/CD with SF CLI

### GitHub Actions Example

```yaml
# .github/workflows/deploy.yml
name: Deploy to Salesforce

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install SF CLI
        run: npm install -g @salesforce/cli

      - name: Authenticate
        run: |
          echo "${{ secrets.SF_AUTH_URL }}" > authfile
          sf org login sfdx-url --sfdx-url-file authfile --alias targetOrg

      - name: Validate (PR) / Deploy (merge)
        run: |
          if [ "${{ github.event_name }}" = "pull_request" ]; then
            sf project deploy start \
              --source-dir force-app \
              --target-org targetOrg \
              --test-level RunLocalTests \
              --dry-run \
              --wait 60
          else
            sf project deploy start \
              --source-dir force-app \
              --target-org targetOrg \
              --test-level RunLocalTests \
              --wait 60
          fi
```

### Generate Auth URL (for CI secrets)

```bash
# Login first, then export the auth URL
sf org login web --alias myOrg
sf org display --target-org myOrg --verbose
# Copy the "Sfdx Auth Url" value → store as CI secret
```

### Delta Deployments (deploy only changed files)

```bash
# Install sfdx-git-delta plugin
sf plugins install sfdx-git-delta

# Generate package.xml from git diff
sgd --from origin/main --to HEAD --output delta/ --generate-delta

# Deploy only delta
sf project deploy start --manifest delta/package/package.xml --target-org targetOrg
```

---

## Quick Reference: Key Flags

### `sf project deploy start`

| Flag               | Description                                  |
|--------------------|----------------------------------------------|
| `--source-dir`     | Path to local source directory               |
| `--metadata`       | Metadata type or type:name                   |
| `--manifest`       | Path to package.xml                          |
| `--target-org`     | Alias or username of target org              |
| `--test-level`     | Test execution level                         |
| `--tests`          | Specific test class names (repeatable)       |
| `--dry-run`        | Validate only, do not deploy                 |
| `--wait`           | Minutes to wait (default 33)                 |
| `--async`          | Run asynchronously                           |
| `--ignore-conflicts` | Override source tracking conflicts         |
| `--ignore-errors`  | Continue deploy on component errors          |

### `sf project retrieve start`

| Flag               | Description                                  |
|--------------------|----------------------------------------------|
| `--source-dir`     | Path to retrieve into                        |
| `--metadata`       | Metadata type or type:name                   |
| `--manifest`       | Path to package.xml                          |
| `--target-org`     | Alias or username of source org              |
| `--output-dir`     | Retrieve to different directory              |
| `--wait`           | Minutes to wait                              |
| `--ignore-conflicts` | Override source tracking conflicts         |
| `--api-version`    | Override API version                         |

---

## Org Management Commands

```bash
# List all authenticated orgs
sf org list

# Set default org
sf config set target-org myOrg

# Set default Dev Hub
sf config set target-dev-hub devHub

# View current config
sf config list

# Login via browser
sf org login web --alias myOrg

# Login via JWT (CI)
sf org login jwt \
  --client-id CONNECTED_APP_ID \
  --jwt-key-file server.key \
  --username user@example.com \
  --alias myOrg

# Logout
sf org logout --target-org myOrg --no-prompt
```
