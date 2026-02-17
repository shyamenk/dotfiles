# Salesforce Security Cheatsheet

---

## 1. Sharing Model

### Organization-Wide Defaults (OWD)

Sets the **baseline** record access for each object. Options:

| OWD Setting          | Description                              |
|----------------------|------------------------------------------|
| Private              | Only owner and users above in hierarchy  |
| Public Read Only     | All users can read, only owner can edit  |
| Public Read/Write    | All users can read and edit              |
| Controlled by Parent | Access determined by parent record (detail in master-detail) |

### Role Hierarchy

Opens up access **upward** — managers inherit access of subordinates. Does **not** restrict access.

### Sharing Rules

Grant additional access beyond OWD based on **criteria** or **ownership**.

- **Criteria-based**: Share records matching field conditions with a group/role.
- **Owner-based**: Share records owned by a group/role with another group/role.

### Manual Sharing

Ad-hoc sharing of individual records via the **Share** button. Removed when ownership changes.

---

## 2. Apex Sharing Keywords

```apex
// Enforces sharing rules of the current user
public with sharing class SecureController {
    public List<Account> getAccounts() {
        return [SELECT Id, Name FROM Account];
    }
}

// Bypasses sharing rules — runs in system context
public without sharing class AdminService {
    public List<Account> getAllAccounts() {
        return [SELECT Id, Name FROM Account];
    }
}

// Inherits sharing mode from the calling class
// If called standalone (e.g., trigger), defaults to without sharing
public inherited sharing class FlexibleService {
    public List<Account> getAccounts() {
        return [SELECT Id, Name FROM Account];
    }
}
```

> **Best practice**: Always use `with sharing` unless you have a specific reason not to. Use `inherited sharing` for utility/service classes.

---

## 3. CRUD Checks

Check object-level permissions before DML:

```apex
if (Schema.sObjectType.Account.isAccessible()) {
    // Safe to query Account
}
if (Schema.sObjectType.Account.isCreateable()) {
    // Safe to insert Account
}
if (Schema.sObjectType.Account.isUpdateable()) {
    // Safe to update Account
}
if (Schema.sObjectType.Account.isDeletable()) {
    // Safe to delete Account
}

// Throw if insufficient access
if (!Schema.sObjectType.Contact.isCreateable()) {
    throw new AuraHandledException('Insufficient access to create Contact');
}
```

---

## 4. Field-Level Security (FLS) Checks

Check field-level permissions before reading/writing individual fields:

```apex
// Field-level read check
if (Schema.sObjectType.Account.fields.Name.getDescribe().isAccessible()) {
    // Safe to read Account.Name
}

// Field-level create check
if (Schema.sObjectType.Account.fields.Phone.getDescribe().isCreateable()) {
    // Safe to set Phone on insert
}

// Field-level update check
if (Schema.sObjectType.Account.fields.Website.getDescribe().isUpdateable()) {
    // Safe to set Website on update
}

// Iterate and build dynamic query with only accessible fields
List<String> accessibleFields = new List<String>();
Map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Account.fields.getMap();
for (String fieldName : fieldMap.keySet()) {
    if (fieldMap.get(fieldName).getDescribe().isAccessible()) {
        accessibleFields.add(fieldName);
    }
}
String query = 'SELECT ' + String.join(accessibleFields, ', ') + ' FROM Account LIMIT 10';
```

---

## 5. Security.stripInaccessible()

Automatically strips fields the user cannot access — preferred over manual FLS checks:

```apex
// Strip fields the user can't read
List<Account> accounts = [SELECT Id, Name, Phone, AnnualRevenue FROM Account];
SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, accounts);
List<Account> sanitized = decision.getRecords();
// Fields the user can't see are removed from the records

// Strip fields the user can't create before insert
List<Contact> contacts = new List<Contact>{
    new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'jane@test.com')
};
SObjectAccessDecision createDecision = Security.stripInaccessible(AccessType.CREATABLE, contacts);
insert createDecision.getRecords();

// Strip fields the user can't update before update
SObjectAccessDecision updateDecision = Security.stripInaccessible(AccessType.UPDATABLE, accounts);
update updateDecision.getRecords();

// Check which fields were removed
Set<String> removedFields = decision.getRemovedFields().get('Account');
// Returns e.g. {'AnnualRevenue'}
```

---

## 6. USER_MODE and SYSTEM_MODE

Control CRUD/FLS/sharing enforcement directly in Database operations (Spring '23+):

```apex
// USER_MODE: enforces CRUD, FLS, and sharing rules
List<Account> accounts = [SELECT Id, Name FROM Account WITH USER_MODE];

// SYSTEM_MODE: bypasses CRUD, FLS, and sharing (default for Apex)
List<Account> accounts = [SELECT Id, Name FROM Account WITH SYSTEM_MODE];

// Database.query with access level
List<Account> results = Database.query(
    'SELECT Id, Name FROM Account',
    AccessLevel.USER_MODE
);

// Database DML with access level
Database.SaveResult[] sr = Database.insert(accounts, AccessLevel.USER_MODE);
Database.SaveResult[] sr2 = Database.update(accounts, AccessLevel.USER_MODE);
Database.DeleteResult[] dr = Database.delete(accounts, AccessLevel.USER_MODE);

// Database.upsert
Database.UpsertResult[] ur = Database.upsert(accounts, Account.ExternalId__c, AccessLevel.USER_MODE);

// Search with user mode
List<List<SObject>> searchResults = Search.query(
    'FIND \'Acme\' IN ALL FIELDS RETURNING Account(Id, Name)',
    AccessLevel.USER_MODE
);
```

> **USER_MODE** is the recommended approach — it replaces manual CRUD/FLS checks and `stripInaccessible`.

---

## 7. Schema Describe Methods

### Schema.describeSObjects()

```apex
// Describe one or more objects by name
Schema.DescribeSObjectResult[] results = Schema.describeSObjects(
    new List<String>{ 'Account', 'Contact' }
);
for (Schema.DescribeSObjectResult dsr : results) {
    System.debug(dsr.getName() + ' - Accessible: ' + dsr.isAccessible());
    System.debug('Fields: ' + dsr.fields.getMap().keySet());
}
```

### Schema.getGlobalDescribe()

```apex
// Returns map of all sObject types in the org
Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

// Check if a custom object exists
if (globalDescribe.containsKey('CustomObj__c')) {
    Schema.DescribeSObjectResult dsr = globalDescribe.get('CustomObj__c').getDescribe();
    System.debug('Label: ' + dsr.getLabel());
    System.debug('Key Prefix: ' + dsr.getKeyPrefix());
}

// List all custom objects
for (String objName : globalDescribe.keySet()) {
    if (objName.endsWith('__c')) {
        System.debug('Custom Object: ' + objName);
    }
}
```

---

## 8. Record-Level Security: UserRecordAccess

Query whether the running user has access to specific records:

```apex
// Check access to a single record
UserRecordAccess access = [
    SELECT RecordId, HasReadAccess, HasEditAccess, HasDeleteAccess, HasTransferAccess, HasAllAccess
    FROM UserRecordAccess
    WHERE UserId = :UserInfo.getUserId()
    AND RecordId = :accountId
];

if (access.HasEditAccess) {
    // User can edit this record
}

// Check access to multiple records
List<UserRecordAccess> accessList = [
    SELECT RecordId, HasReadAccess, HasEditAccess
    FROM UserRecordAccess
    WHERE UserId = :UserInfo.getUserId()
    AND RecordId IN :recordIds
];
Map<Id, Boolean> editableMap = new Map<Id, Boolean>();
for (UserRecordAccess ura : accessList) {
    editableMap.put(ura.RecordId, ura.HasEditAccess);
}
```

---

## 9. Profile vs Permission Set vs Permission Set Group

| Concept               | Description                                                        |
|-----------------------|--------------------------------------------------------------------|
| **Profile**           | Baseline permissions assigned to every user. One profile per user. |
| **Permission Set**    | Additive permissions layered on top of profile. Many per user.     |
| **Permission Set Group** | Bundle of permission sets assigned as a single unit.            |
| **Muting Permission Set** | Removes specific permissions within a Permission Set Group.  |

```apex
// Query current user's profile
Profile p = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];

// Query permission sets assigned to a user
List<PermissionSetAssignment> psas = [
    SELECT PermissionSet.Name, PermissionSet.Label, PermissionSet.IsOwnedByProfile
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    AND PermissionSet.IsOwnedByProfile = false
];

// Query permission set groups
List<PermissionSetAssignment> groups = [
    SELECT PermissionSetGroup.DeveloperName
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    AND PermissionSetGroupId != null
];
```

---

## 10. Custom Permissions

Define custom permissions in Setup, then check in Apex:

```apex
// Check if running user has a custom permission
Boolean hasAccess = FeatureManagement.checkPermission('My_Custom_Permission');

if (hasAccess) {
    // User has the custom permission — enable feature
}

// In Visualforce
// $Permission.My_Custom_Permission

// In Validation Rules / Formulas
// $Permission.My_Custom_Permission
```

```apex
// Query custom permission assignments
List<SetupEntityAccess> sea = [
    SELECT SetupEntityId, Parent.Name
    FROM SetupEntityAccess
    WHERE SetupEntityType = 'CustomPermission'
    AND SetupEntityId IN (
        SELECT Id FROM CustomPermission WHERE DeveloperName = 'My_Custom_Permission'
    )
];
```

---

## 11. SOQL Injection Prevention

**Never** concatenate user input directly into SOQL:

```apex
// VULNERABLE — DO NOT DO THIS
String query = 'SELECT Id FROM Account WHERE Name = \'' + userInput + '\'';

// SAFE — Use bind variables
String safeName = userInput;
List<Account> accounts = [SELECT Id FROM Account WHERE Name = :safeName];

// SAFE — Use String.escapeSingleQuotes() for dynamic SOQL
String sanitized = String.escapeSingleQuotes(userInput);
String query = 'SELECT Id FROM Account WHERE Name = \'' + sanitized + '\'';
List<Account> results = Database.query(query);

// SAFE — Use bind variable in Database.queryWithBinds (Winter '23+)
Map<String, Object> bindVars = new Map<String, Object>{ 'name' => userInput };
String query = 'SELECT Id FROM Account WHERE Name = :name';
List<Account> results = Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE);
```

> **Best practice**: Prefer `Database.queryWithBinds()` with `USER_MODE` for dynamic SOQL.

---

## 12. XSS Prevention

### Visualforce

```html
<!-- SAFE: Default output encoding (HTML context) -->
<apex:outputText value="{!account.Name}" />

<!-- VULNERABLE: escape="false" disables encoding -->
<apex:outputText value="{!account.Name}" escape="false" />

<!-- Use JSENCODE for JavaScript context -->
<script>
    var name = '{!JSENCODE(account.Name)}';
</script>

<!-- Use URLENCODE for URL parameters -->
<a href="/page?name={!URLENCODE(account.Name)}">Link</a>

<!-- Use HTMLENCODE when needed explicitly -->
<div>{!HTMLENCODE(account.Description)}</div>

<!-- JSINHTMLENCODE for JS inside HTML attributes -->
<div onclick="alert('{!JSINHTMLENCODE(account.Name)}')">Click</div>
```

### Lightning Web Components (LWC)

```html
<!-- LWC auto-encodes template expressions — SAFE by default -->
<template>
    <p>{accountName}</p>
</template>

<!-- VULNERABLE: lwc:dom="manual" bypasses encoding -->
<template>
    <div lwc:dom="manual"></div>
</template>
```

```javascript
// DANGEROUS — avoid innerHTML / lwc:dom="manual" with user input
this.template.querySelector('div').innerHTML = userInput; // XSS risk

// SAFE — use template bindings
this.accountName = userInput; // auto-encoded by framework
```

---

## 13. Content Security Policy (CSP)

Salesforce enforces CSP headers to prevent injection attacks.

| Directive            | Purpose                                      |
|----------------------|----------------------------------------------|
| `script-src`         | Controls allowed script sources              |
| `style-src`          | Controls allowed stylesheet sources          |
| `img-src`            | Controls allowed image sources               |
| `connect-src`        | Controls allowed fetch/XHR/WebSocket targets |
| `frame-ancestors`    | Controls who can embed the page in iframes   |

**Key rules:**
- **No inline scripts** — `eval()` and inline `<script>` blocks are blocked.
- **No `unsafe-inline`** for Lightning — use static resources or LWC modules.
- **CSP Trusted Sites**: Add external domains via Setup → CSP Trusted Sites.
- **Lightning Locker / LWS**: Enforce component isolation and CSP at the component level.

```apex
// Trusted sites are configured declaratively in Setup
// For callouts to external APIs, also add to Remote Site Settings
// or Named Credentials (preferred)
```

---

## 14. Salesforce Shield

### Platform Encryption

Encrypts data at rest using tenant-specific keys.

```apex
// Check if a field is encrypted
Schema.DescribeFieldResult dfr = Account.Name.getDescribe();
System.debug('Is Encrypted: ' + dfr.isEncrypted());

// Encrypted fields have limitations:
// - Cannot use in SOQL WHERE, ORDER BY, GROUP BY (deterministic encryption allows some)
// - Cannot use in formula fields
// - SOSL search may be limited
```

**Key types**: Tenant Secret, Customer-Supplied (BYOK), Cache-Only Keys.

### Event Monitoring

Tracks user activity via `EventLogFile` and Real-Time Event objects:

```apex
// Query login event logs
List<EventLogFile> logs = [
    SELECT Id, EventType, LogDate, LogFileLength
    FROM EventLogFile
    WHERE EventType = 'Login'
    AND LogDate = LAST_N_DAYS:7
    ORDER BY LogDate DESC
];

// Download log file content
EventLogFile log = [SELECT Id, LogFile FROM EventLogFile WHERE Id = :logId];
Blob logBlob = log.LogFile;
String logCsv = logBlob.toString();
```

**Real-Time Events** (subscribe via Apex triggers or CDC):
- `LoginEvent`
- `ApiEvent`
- `ReportEvent`
- `ListViewEvent`
- `SessionHijackingEvent`

```apex
// Transaction Security Policy — trigger on real-time events
// Configured in Setup → Transaction Security Policies
// Uses Apex condition classes:
public class BlockLargeExportCondition implements TxnSecurity.EventCondition {
    public Boolean evaluate(SObject event) {
        ReportEvent re = (ReportEvent) event;
        return re.RowsProcessed > 10000;
    }
}
```

### Field Audit Trail

Retains field history data for up to **10 years** (vs. 18-month standard limit).

```apex
// Query archived field history (uses FieldHistoryArchive big object)
List<FieldHistoryArchive> history = [
    SELECT ParentId, FieldName, OldValue, NewValue, CreatedDate, CreatedById
    FROM FieldHistoryArchive
    WHERE ParentId = :accountId
    AND FieldName = 'AnnualRevenue'
    ORDER BY CreatedDate DESC
];
```

**Setup**: Define a Field History Retention Policy in Setup to specify which objects/fields to archive.

---

## Quick Reference: Security Check Decision Tree

```
Need to enforce security in Apex?
├── SOQL/DML? → Use WITH USER_MODE / AccessLevel.USER_MODE (preferred)
├── Need to strip fields? → Security.stripInaccessible()
├── Manual checks needed?
│   ├── Object-level → Schema.sObjectType.Obj.isAccessible/isCreateable/...
│   └── Field-level  → Schema.sObjectType.Obj.fields.Field.getDescribe().isAccessible()
├── Sharing rules? → Use 'with sharing' keyword on class
├── Custom feature gate? → FeatureManagement.checkPermission()
└── Dynamic SOQL? → Database.queryWithBinds() + USER_MODE
```
