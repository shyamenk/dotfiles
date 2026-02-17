# Governor Limits Reference

Salesforce enforces governor limits per transaction to ensure shared resources on the multitenant platform are not monopolized.

## Limits Reference Table

### Query and Data Limits

| Limit | Synchronous | Asynchronous |
|---|---|---|
| SOQL queries | 100 | 200 |
| SOQL rows retrieved | 50,000 | 50,000 |
| SOSL queries | 20 | 20 |
| DML statements | 150 | 150 |
| DML rows | 10,000 | 10,000 |
| Describe calls | 100 | 100 |

### Execution Limits

| Limit | Synchronous | Asynchronous |
|---|---|---|
| CPU time | 10,000 ms | 60,000 ms |
| Heap size | 6 MB | 12 MB |
| Total stack depth | 16 | 16 |

### External and Async Limits

| Limit | Value |
|---|---|
| Callouts (HTTP/Web service) | 100 per transaction |
| Callout timeout | 120 seconds (total cumulative) |
| Future calls (`@future`) | 50 per transaction |
| Queueable jobs (`System.enqueueJob`) | 50 per transaction |
| Email invocations (`Messaging.sendEmail`) | 10 per transaction |

## Checking Limits at Runtime

Use the `Limits` class to inspect current consumption and maximum allowances.

| Method | Returns |
|---|---|
| `Limits.getQueries()` | SOQL queries used so far |
| `Limits.getLimitQueries()` | Maximum SOQL queries allowed |
| `Limits.getDmlStatements()` | DML statements used so far |
| `Limits.getLimitDmlStatements()` | Maximum DML statements allowed |
| `Limits.getDmlRows()` | DML rows used so far |
| `Limits.getLimitDmlRows()` | Maximum DML rows allowed |
| `Limits.getCpuTime()` | CPU time consumed (ms) |
| `Limits.getLimitCpuTime()` | Maximum CPU time allowed (ms) |
| `Limits.getHeapSize()` | Heap bytes used |
| `Limits.getLimitHeapSize()` | Maximum heap bytes allowed |
| `Limits.getCallouts()` | Callouts made so far |
| `Limits.getLimitCallouts()` | Maximum callouts allowed |
| `Limits.getFutureCalls()` | Future calls used so far |
| `Limits.getLimitFutureCalls()` | Maximum future calls allowed |
| `Limits.getQueueableJobs()` | Queueable jobs enqueued so far |
| `Limits.getLimitQueueableJobs()` | Maximum queueable jobs allowed |
| `Limits.getSoslQueries()` | SOSL queries used so far |
| `Limits.getLimitSoslQueries()` | Maximum SOSL queries allowed |

### Debugging Pattern

Log limit consumption at key points to catch problems before they surface in production:

```apex
public class LimitsDebugger {
    public static void logUsage(String context) {
        System.debug(LoggingLevel.INFO, '=== Limits Usage [' + context + '] ===');
        System.debug(LoggingLevel.INFO,
            'SOQL Queries: ' + Limits.getQueries() + ' / ' + Limits.getLimitQueries());
        System.debug(LoggingLevel.INFO,
            'DML Statements: ' + Limits.getDmlStatements() + ' / ' + Limits.getLimitDmlStatements());
        System.debug(LoggingLevel.INFO,
            'DML Rows: ' + Limits.getDmlRows() + ' / ' + Limits.getLimitDmlRows());
        System.debug(LoggingLevel.INFO,
            'CPU Time: ' + Limits.getCpuTime() + ' ms / ' + Limits.getLimitCpuTime() + ' ms');
        System.debug(LoggingLevel.INFO,
            'Heap Size: ' + Limits.getHeapSize() + ' / ' + Limits.getLimitHeapSize());
        System.debug(LoggingLevel.INFO,
            'Callouts: ' + Limits.getCallouts() + ' / ' + Limits.getLimitCallouts());
    }
}
```

Use it around suspect code:

```apex
LimitsDebugger.logUsage('Before account processing');

List<Account> accounts = [SELECT Id, Name FROM Account WHERE Industry = 'Tech'];
for (Account a : accounts) {
    a.Description = 'Processed';
}
update accounts;

LimitsDebugger.logUsage('After account processing');
```

### Guard Clause Pattern

Abort or reroute execution when limits are close to being exceeded:

```apex
if (Limits.getQueries() >= Limits.getLimitQueries() - 5) {
    System.debug(LoggingLevel.WARN, 'Approaching SOQL query limit — skipping additional queries');
    return;
}

if (Limits.getCallouts() >= Limits.getLimitCallouts()) {
    throw new LimitException('Callout limit reached. Deferring to async.');
}
```

## Strategies to Avoid Hitting Limits

### 1. Bulkification

Never place SOQL queries or DML statements inside loops. Collect records and operate in bulk.

```apex
// BAD — query and DML inside loop
for (Id contactId : contactIds) {
    Contact c = [SELECT Id, LastName FROM Contact WHERE Id = :contactId];
    c.Description = 'Updated';
    update c;
}

// GOOD — single query, single DML
List<Contact> contacts = [SELECT Id, LastName FROM Contact WHERE Id IN :contactIds];
for (Contact c : contacts) {
    c.Description = 'Updated';
}
update contacts;
```

### 2. Lazy Loading and Selective Queries

Query only the fields and records you need. Use indexed filters (`Id`, `Name`, `External Id`, etc.) and limit result sets.

```apex
// Avoid SELECT * equivalents — specify fields explicitly
List<Account> accounts = [
    SELECT Id, Name
    FROM Account
    WHERE CreatedDate = TODAY
    LIMIT 200
];
```

Use related queries instead of separate ones when possible:

```apex
// One query instead of two
List<Account> accounts = [
    SELECT Id, Name, (SELECT Id, LastName FROM Contacts)
    FROM Account
    WHERE Id IN :accountIds
];
```

### 3. Async Processing

Offload heavy work to asynchronous contexts which have higher limits.

```apex
// Move callout-heavy work to a future method
public class ExternalService {
    @future(callout=true)
    public static void syncRecords(Set<Id> recordIds) {
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id IN :recordIds];
        for (Account a : accounts) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.example.com/sync');
            req.setMethod('POST');
            req.setBody(JSON.serialize(a));
            new Http().send(req);
        }
    }
}
```

For large data volumes, use `Queueable` to chain work across transactions:

```apex
public class ProcessRecordsJob implements Queueable {
    private List<Id> recordIds;
    private Integer batchStart;

    public ProcessRecordsJob(List<Id> recordIds, Integer batchStart) {
        this.recordIds = recordIds;
        this.batchStart = batchStart;
    }

    public void execute(QueueableContext ctx) {
        Integer batchEnd = Math.min(batchStart + 200, recordIds.size());
        List<Id> chunk = new List<Id>();
        for (Integer i = batchStart; i < batchEnd; i++) {
            chunk.add(recordIds[i]);
        }

        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id IN :chunk];
        for (Account a : accounts) {
            a.Description = 'Batch processed';
        }
        update accounts;

        if (batchEnd < recordIds.size()) {
            System.enqueueJob(new ProcessRecordsJob(recordIds, batchEnd));
        }
    }
}
```

### 4. Use Maps to Avoid Repeated Queries

```apex
// Query once, look up by Id without additional SOQL
Map<Id, Account> accountMap = new Map<Id, Account>(
    [SELECT Id, Name, Industry FROM Account WHERE Id IN :accountIds]
);

for (Opportunity opp : opportunities) {
    Account relatedAccount = accountMap.get(opp.AccountId);
    if (relatedAccount != null) {
        opp.Description = 'Account: ' + relatedAccount.Name;
    }
}
```

### 5. Batch Apex for Very Large Datasets

When processing more than 10,000 records, use `Database.Batchable` to split work into separate transactions:

```apex
public class CleanupBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM Lead WHERE IsConverted = false AND CreatedDate < LAST_YEAR');
    }

    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        delete scope;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Cleanup complete');
    }
}

// Execute with a scope size of 200
Database.executeBatch(new CleanupBatch(), 200);
```
