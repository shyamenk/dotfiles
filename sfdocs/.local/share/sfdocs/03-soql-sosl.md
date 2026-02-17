# SOQL & SOSL Cheatsheet

---

## SOQL (Salesforce Object Query Language)

### Basic Query Structure

```sql
SELECT Id, Name, Email
FROM Contact
WHERE Email != NULL
ORDER BY Name ASC
LIMIT 50
OFFSET 10
```

### Comparison Operators

```sql
-- Equality / Inequality
SELECT Id FROM Account WHERE Name = 'Acme'
SELECT Id FROM Account WHERE Name != 'Acme'

-- Numeric comparisons
SELECT Id FROM Opportunity WHERE Amount > 10000
SELECT Id FROM Opportunity WHERE Amount >= 10000
SELECT Id FROM Opportunity WHERE Amount < 50000
SELECT Id FROM Opportunity WHERE Amount <= 50000

-- LIKE (pattern matching)
SELECT Id FROM Account WHERE Name LIKE 'Acme%'       -- starts with Acme
SELECT Id FROM Account WHERE Name LIKE '%Corp'        -- ends with Corp
SELECT Id FROM Account WHERE Name LIKE '%Tech%'       -- contains Tech
SELECT Id FROM Account WHERE Name LIKE 'A_me'         -- _ matches single char

-- IN / NOT IN
SELECT Id FROM Contact WHERE MailingState IN ('CA', 'NY', 'TX')
SELECT Id FROM Contact WHERE MailingState NOT IN ('FL', 'OH')

-- INCLUDES / EXCLUDES (multi-select picklists only)
SELECT Id FROM Lead WHERE ProductInterest__c INCLUDES ('Cloud;Mobile')
SELECT Id FROM Lead WHERE ProductInterest__c EXCLUDES ('On-Premise')
```

### Logical Operators

```sql
SELECT Id, Name FROM Account
WHERE (Industry = 'Technology' OR Industry = 'Finance')
AND AnnualRevenue > 1000000
AND Name != NULL
```

### ORDER BY

```sql
SELECT Name, AnnualRevenue FROM Account
ORDER BY AnnualRevenue DESC NULLS LAST

SELECT Name FROM Contact
ORDER BY LastName ASC, FirstName ASC
```

### LIMIT and OFFSET

```sql
-- First 10 results
SELECT Id, Name FROM Account LIMIT 10

-- Pagination: skip 20, take 10
SELECT Id, Name FROM Account ORDER BY Name LIMIT 10 OFFSET 20
```

> **Note:** OFFSET max is 2000.

---

### Date Literals

```sql
-- Fixed date literals
SELECT Id FROM Opportunity WHERE CloseDate = TODAY
SELECT Id FROM Opportunity WHERE CloseDate = YESTERDAY
SELECT Id FROM Opportunity WHERE CloseDate = THIS_WEEK
SELECT Id FROM Opportunity WHERE CloseDate = LAST_WEEK
SELECT Id FROM Opportunity WHERE CloseDate = THIS_MONTH
SELECT Id FROM Opportunity WHERE CloseDate = LAST_MONTH
SELECT Id FROM Opportunity WHERE CloseDate = THIS_QUARTER
SELECT Id FROM Opportunity WHERE CloseDate = NEXT_QUARTER
SELECT Id FROM Opportunity WHERE CloseDate = THIS_YEAR
SELECT Id FROM Opportunity WHERE CloseDate = LAST_YEAR
SELECT Id FROM Opportunity WHERE CloseDate = NEXT_YEAR

-- Relative date literals with N
SELECT Id FROM Opportunity WHERE CloseDate = LAST_N_DAYS:30
SELECT Id FROM Opportunity WHERE CloseDate > LAST_N_DAYS:90
SELECT Id FROM Opportunity WHERE CloseDate < NEXT_N_MONTHS:3
SELECT Id FROM Opportunity WHERE CreatedDate = LAST_N_WEEKS:4
SELECT Id FROM Opportunity WHERE CreatedDate = NEXT_N_QUARTERS:2
SELECT Id FROM Opportunity WHERE CreatedDate = LAST_N_YEARS:5
```

### Date Functions in WHERE and GROUP BY

```sql
SELECT CALENDAR_MONTH(CloseDate), SUM(Amount)
FROM Opportunity
GROUP BY CALENDAR_MONTH(CloseDate)

SELECT Id FROM Opportunity
WHERE DAY_IN_MONTH(CloseDate) = 15

-- Available: CALENDAR_MONTH, CALENDAR_QUARTER, CALENDAR_YEAR,
-- DAY_IN_MONTH, DAY_IN_WEEK, DAY_IN_YEAR, DAY_ONLY,
-- FISCAL_MONTH, FISCAL_QUARTER, FISCAL_YEAR,
-- HOUR_IN_DAY, WEEK_IN_MONTH, WEEK_IN_YEAR
```

---

### Aggregate Functions

```sql
SELECT COUNT() FROM Account

SELECT COUNT(Id) FROM Contact WHERE AccountId != NULL

SELECT COUNT_DISTINCT(LeadSource) FROM Lead

SELECT
    Industry,
    COUNT(Id) total,
    SUM(AnnualRevenue) revenue,
    AVG(AnnualRevenue) avgRevenue,
    MIN(AnnualRevenue) minRevenue,
    MAX(AnnualRevenue) maxRevenue
FROM Account
GROUP BY Industry
```

### GROUP BY and HAVING

```sql
SELECT Industry, COUNT(Id) cnt
FROM Account
GROUP BY Industry
HAVING COUNT(Id) > 5

-- GROUP BY with multiple fields
SELECT Industry, BillingState, COUNT(Id)
FROM Account
GROUP BY Industry, BillingState

-- GROUP BY ROLLUP (subtotals)
SELECT Industry, COUNT(Id)
FROM Account
GROUP BY ROLLUP(Industry)

-- GROUP BY CUBE (all combinations)
SELECT Industry, BillingState, COUNT(Id)
FROM Account
GROUP BY CUBE(Industry, BillingState)
```

---

### Relationship Queries

#### Child-to-Parent (Dot Notation)

Navigate up from child to parent using the relationship name.

```sql
-- Standard relationship (no suffix)
SELECT Id, Name, Account.Name, Account.Industry
FROM Contact

-- Custom relationship (replace __c with __r)
SELECT Id, Name, CustomParent__r.Name, CustomParent__r.Custom_Field__c
FROM Child_Object__c
```

#### Parent-to-Child (Subquery)

Navigate down from parent to children using the plural child relationship name.

```sql
-- Standard relationship (plural name)
SELECT Id, Name,
    (SELECT Id, FirstName, LastName, Email FROM Contacts)
FROM Account

-- Custom relationship (plural with __r)
SELECT Id, Name,
    (SELECT Id, Name FROM Child_Objects__r)
FROM Parent_Object__c

-- Subquery with filters
SELECT Id, Name,
    (SELECT Id, Amount, StageName
     FROM Opportunities
     WHERE StageName = 'Closed Won'
     ORDER BY Amount DESC
     LIMIT 5)
FROM Account
WHERE Industry = 'Technology'
```

#### Custom Relationship Naming (`__r`)

| Object Type     | Field API Name       | Relationship Name     |
|-----------------|----------------------|-----------------------|
| Standard parent | AccountId            | Account               |
| Custom parent   | Custom_Parent__c     | Custom_Parent__r      |
| Standard child  | —                    | Contacts, Opportunities |
| Custom child    | —                    | Child_Objects__r      |

---

### Polymorphic Relationships (TYPEOF)

Used with polymorphic fields like `What` on Task/Event or `Owner` on various objects.

```sql
SELECT Id, Subject,
    TYPEOF What
        WHEN Account THEN Name, Industry
        WHEN Opportunity THEN Name, Amount, StageName
        ELSE Name
    END
FROM Task

SELECT Id, Subject,
    TYPEOF Who
        WHEN Contact THEN FirstName, LastName, Account.Name
        WHEN Lead THEN FirstName, LastName, Company
    END
FROM Task
```

Querying polymorphic fields without TYPEOF:

```sql
-- Filter by type
SELECT Id, Subject, What.Name
FROM Task
WHERE What.Type = 'Account'

-- Using isInstanceOf in Apex
SELECT Id, What.Id, What.Name FROM Event
```

```apex
for (Event e : [SELECT Id, What.Id, What.Name FROM Event]) {
    if (e.What instanceof Account) {
        Account a = (Account) e.What;
    }
}
```

---

### FIELDS() Functions

```sql
-- All fields (SOQL only in REST API / Developer Console, max 200 fields)
SELECT FIELDS(ALL) FROM Account LIMIT 200

-- Standard fields only
SELECT FIELDS(STANDARD) FROM Account

-- Custom fields only
SELECT FIELDS(CUSTOM) FROM Account

-- Mix with explicit fields
SELECT FIELDS(STANDARD), Custom_Field__c FROM Account
```

> **Note:** `FIELDS(ALL)` and `FIELDS(CUSTOM)` require `LIMIT 200` or less.

---

### Dynamic SOQL

```apex
String objectName = 'Account';
String fieldName = 'Industry';
String filterValue = 'Technology';

String query = 'SELECT Id, Name FROM ' + objectName
    + ' WHERE ' + fieldName + ' = :filterValue';

List<SObject> results = Database.query(query);
```

### Bind Variables

```apex
String industry = 'Technology';
Decimal minRevenue = 1000000;
Set<Id> accountIds = new Set<Id>{'001xx000003DGbY', '001xx000003DGbZ'};

// Inline SOQL with bind variables
List<Account> accounts = [
    SELECT Id, Name
    FROM Account
    WHERE Industry = :industry
    AND AnnualRevenue > :minRevenue
    AND Id IN :accountIds
];

// Dynamic SOQL also supports bind variables
String query = 'SELECT Id FROM Account WHERE Industry = :industry';
List<Account> results = Database.query(query);

// Bind with collection
List<String> states = new List<String>{'CA', 'NY'};
List<Account> filtered = [
    SELECT Id FROM Account WHERE BillingState IN :states
];

// Bind with date
Date cutoff = Date.today().addDays(-30);
List<Opportunity> recent = [
    SELECT Id FROM Opportunity WHERE CloseDate >= :cutoff
];
```

---

### FOR UPDATE, FOR VIEW, FOR REFERENCE

```apex
// FOR UPDATE — locks records to prevent concurrent modification
List<Account> lockedAccounts = [
    SELECT Id, Name FROM Account WHERE Id = :acctId FOR UPDATE
];

// FOR VIEW — updates LastViewedDate
List<Account> viewed = [
    SELECT Id, Name FROM Account ORDER BY Name LIMIT 10 FOR VIEW
];

// FOR REFERENCE — updates LastReferencedDate
List<Account> referenced = [
    SELECT Id, Name FROM Account ORDER BY Name LIMIT 10 FOR REFERENCE
];
```

> **Note:** `FOR UPDATE` cannot be used with aggregate queries, subqueries, or `COUNT()`.

---

### Semi-Joins and Anti-Joins

```sql
-- Semi-join: Accounts that HAVE related Contacts
SELECT Id, Name FROM Account
WHERE Id IN (SELECT AccountId FROM Contact WHERE Email != NULL)

-- Anti-join: Accounts with NO related Opportunities
SELECT Id, Name FROM Account
WHERE Id NOT IN (SELECT AccountId FROM Opportunity)

-- Semi-join on lookup to another object
SELECT Id, Name FROM Account
WHERE Id IN (
    SELECT AccountId FROM Opportunity
    WHERE StageName = 'Closed Won' AND Amount > 100000
)

-- Multiple semi-joins
SELECT Id, Name FROM Account
WHERE Id IN (SELECT AccountId FROM Contact)
AND Id IN (SELECT AccountId FROM Opportunity WHERE IsClosed = false)
```

> **Limits:** Max 2 semi-joins/anti-joins per query. Subquery must reference an Id or relationship field.

---

### toLabel()

Translates picklist values and record types to the user's language.

```sql
SELECT Id, toLabel(Industry), toLabel(Rating) FROM Account

SELECT Id, Name FROM Account WHERE toLabel(Industry) = 'Technologie'

SELECT Id, toLabel(StageName) FROM Opportunity WHERE StageName = 'Closed Won'
```

---

### Other Useful SOQL Features

```sql
-- Count with no field (returns integer)
SELECT COUNT() FROM Account WHERE Industry = 'Technology'

-- Filtering on related records
SELECT Id, Name FROM Account
WHERE Id IN (SELECT AccountId FROM Contact WHERE LastName = 'Smith')

-- Querying RecordType
SELECT Id, Name, RecordType.Name FROM Account WHERE RecordType.DeveloperName = 'Enterprise'

-- Multi-currency: convertCurrency()
SELECT Id, Name, convertCurrency(AnnualRevenue) FROM Account

-- FORMAT() for locale-aware formatting
SELECT Id, FORMAT(AnnualRevenue), FORMAT(CreatedDate) FROM Account
```

---

## SOSL (Salesforce Object Search Language)

### Basic FIND Syntax

```sql
FIND {search term} IN ALL FIELDS
RETURNING Account(Id, Name), Contact(Id, FirstName, LastName)
```

### Search Groups (IN clause)

```sql
-- Search all searchable fields (default)
FIND {Acme} IN ALL FIELDS RETURNING Account(Id, Name)

-- Search only Name fields
FIND {John} IN NAME FIELDS RETURNING Contact(Id, Name)

-- Search only Email fields
FIND {john@example.com} IN EMAIL FIELDS RETURNING Contact(Id, Email)

-- Search only Phone fields
FIND {415} IN PHONE FIELDS RETURNING Contact(Id, Phone)

-- Search sidebar (Knowledge articles, etc.)
FIND {password reset} IN SIDEBAR FIELDS RETURNING KnowledgeArticle(Id, Title)
```

### Search Term Syntax

```sql
-- Exact phrase
FIND {"Acme Corporation"} IN ALL FIELDS RETURNING Account

-- Wildcard: * matches zero or more chars (min 2 chars before *)
FIND {Acm*} IN ALL FIELDS RETURNING Account

-- Wildcard: ? matches exactly one char
FIND {Jo?n} IN NAME FIELDS RETURNING Contact

-- AND / OR / AND NOT
FIND {Acme AND California} IN ALL FIELDS RETURNING Account
FIND {Acme OR Globex} IN ALL FIELDS RETURNING Account
FIND {Acme AND NOT Subsidiary} IN ALL FIELDS RETURNING Account

-- Parentheses for grouping
FIND {(Acme OR Globex) AND Enterprise} IN ALL FIELDS RETURNING Account
```

### RETURNING with Field List and Filters

```sql
FIND {cloud}
RETURNING
    Account(Id, Name, Industry WHERE Industry = 'Technology' ORDER BY Name LIMIT 10),
    Contact(Id, FirstName, LastName, Email WHERE MailingState = 'CA'),
    Opportunity(Id, Name, Amount WHERE Amount > 50000 ORDER BY Amount DESC LIMIT 5)
```

### WITH Clauses

```sql
-- WITH DATA CATEGORY (Knowledge articles)
FIND {password}
RETURNING KnowledgeArticleVersion(Id, Title)
WITH DATA CATEGORY Location__c AT USA__c

-- WITH NETWORK (Experience Cloud / Communities)
FIND {help} RETURNING FeedItem(Id, Body)
WITH NETWORK = '0DBxx0000000001'

-- WITH SNIPPET (returns highlighted search excerpts)
FIND {cloud computing}
RETURNING Account(Id, Name, Description)
WITH SNIPPET(target_length=120)

-- WITH DIVISION
FIND {Acme} RETURNING Account(Id, Name) WITH DIVISION = 'West'

-- WITH SPELL_CORRECTION
FIND {Acm} RETURNING Account(Id, Name) WITH SPELL_CORRECTION = true

-- WITH METADATA (returns entity type and field names matched)
FIND {cloud} RETURNING Account(Id, Name) WITH METADATA = 'LABELS'
```

### SOSL in Apex

```apex
// Inline SOSL
List<List<SObject>> results = [
    FIND 'Acme*' IN ALL FIELDS
    RETURNING Account(Id, Name), Contact(Id, FirstName, LastName)
];
List<Account> accounts = (List<Account>) results[0];
List<Contact> contacts = (List<Contact>) results[1];

// Dynamic SOSL
String searchTerm = 'Acme';
String query = 'FIND {' + String.escapeSingleQuotes(searchTerm) + '}'
    + ' IN ALL FIELDS'
    + ' RETURNING Account(Id, Name LIMIT 20)';
List<List<SObject>> dynamicResults = Search.query(query);
```

### SOSL Limits

| Limit                            | Value    |
|----------------------------------|----------|
| Search term minimum length       | 2 chars  |
| Max RETURNING objects            | 20       |
| Max records returned per object  | 2000     |
| Total max records returned       | 2000     |
| Max SOSL queries per transaction | 20       |

---

## SOQL vs SOSL Quick Reference

| Feature                | SOQL                              | SOSL                         |
|------------------------|-----------------------------------|------------------------------|
| Purpose                | Query specific object & fields    | Full-text search across objects |
| Returns                | Records from one object (+ related) | Records from multiple objects |
| Search by              | Exact field values                | Text matching (fuzzy)        |
| Relationships          | Yes (subqueries, dot notation)    | No                           |
| Aggregate functions    | Yes                               | No                           |
| DML context            | Triggers, classes, everywhere     | Not in triggers              |
| Apex method            | `Database.query()`                | `Search.query()`             |
| Max records            | 50,000                            | 2,000                        |
| Wildcards              | `%` and `_` (LIKE only)          | `*` and `?`                  |
