# Async Apex Cheatsheet

## @future Methods

Run code asynchronously in a separate thread. Fire-and-forget — no job ID returned.

```apex
public class AccountService {
    @future
    public static void processAccounts(Set<Id> accountIds) {
        List<Account> accts = [SELECT Id, Name FROM Account WHERE Id IN :accountIds];
        // long-running work
    }

    @future(callout=true)
    public static void syncExternal(Set<Id> ids) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.example.com/sync');
        req.setMethod('POST');
        new Http().send(req);
    }
}
```

**Limitations:**

- Parameters must be primitive types or collections of primitives (no sObjects)
- Cannot call another @future from a @future
- Cannot be used in Batch Apex or Queueable
- Max 50 @future calls per transaction
- No job ID — cannot monitor or chain

**When to use:** Simple async work, callouts from triggers, avoiding mixed DML errors.

---

## Queueable Apex

More powerful than @future — supports complex types, chaining, and returns a job ID.

```apex
public class AccountProcessor implements Queueable {
    private List<Account> accounts;

    public AccountProcessor(List<Account> accounts) {
        this.accounts = accounts;
    }

    public void execute(QueueableContext ctx) {
        for (Account a : accounts) {
            a.Description = 'Processed';
        }
        update accounts;

        // Chain another job
        if (!Test.isRunningTest()) {
            System.enqueueJob(new FollowUpJob());
        }
    }
}
```

**Enqueue with options:**

```apex
// Basic enqueue — returns AsyncApexJob Id
Id jobId = System.enqueueJob(new AccountProcessor(accts));

// With AsyncOptions (API v60.0+)
System.AsyncOptions opts = new System.AsyncOptions();
opts.MaximumQueueableStackDepth = 5;   // max chain depth
opts.MinimumQueueableDelayInMinutes = 5; // delay before execution
Id jobId = System.enqueueJob(new AccountProcessor(accts), opts);
```

**Callouts from Queueable:**

```apex
public class ExternalSync implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext ctx) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.example.com/data');
        req.setMethod('GET');
        HttpResponse res = new Http().send(req);
    }
}
```

**Key points:**

- Accepts sObjects and complex types as constructor params
- Max 50 `enqueueJob` calls per transaction
- Chaining: 1 child job per execute (unlimited depth in Developer/Enterprise)
- Returns job ID for monitoring

---

## Batch Apex

Process large data volumes in chunks. Implements `Database.Batchable<sObject>`.

```apex
public class AccountBatch implements Database.Batchable<sObject>,
                                     Database.Stateful,
                                     Database.AllowsCallouts {
    public Integer recordsProcessed = 0; // Stateful: persists across execute()

    // Called once — return the query or iterable
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Name FROM Account WHERE Active__c = true');
    }

    // Called for each chunk (scope)
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account a : scope) {
            a.Description = 'Batch processed';
            recordsProcessed++;
        }
        update scope;
    }

    // Called once after all chunks
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,
                            JobItemsProcessed, TotalJobItems
                            FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        System.debug('Processed ' + recordsProcessed + ' records with '
                     + job.NumberOfErrors + ' errors');
    }
}
```

**Execute batch:**

```apex
// Default scope size: 200
Id jobId = Database.executeBatch(new AccountBatch());

// Custom scope size (1–2000)
Id jobId = Database.executeBatch(new AccountBatch(), 100);

// Use scope of 1 for callout-heavy batches (max 100 callouts per execute)
Id jobId = Database.executeBatch(new AccountBatch(), 1);
```

**Interfaces:**

| Interface | Purpose |
|---|---|
| `Database.Batchable<sObject>` | Required. Defines start/execute/finish |
| `Database.Stateful` | Maintain instance variable state across execute() calls |
| `Database.AllowsCallouts` | Allow HTTP callouts in execute() |
| `Database.RaisesPlatformEvents` | Emit `BatchApexErrorEvent` on failures |

**Key points:**

- QueryLocator: up to 50 million records
- Iterable: up to 50,000 records (use for complex data sources)
- Max 5 active batch jobs queued/running simultaneously
- Each execute() gets fresh governor limits
- Scope size: 1–2000 (default 200)

---

## Schedulable Apex

Run Apex on a schedule using CRON expressions.

```apex
public class WeeklyAccountCleanup implements Schedulable {
    public void execute(SchedulableContext sc) {
        // Kick off a batch from scheduled job
        Database.executeBatch(new AccountBatch(), 200);
    }
}
```

**Schedule via Apex:**

```apex
// CRON: Seconds Minutes Hours Day_of_month Month Day_of_week Optional_year
// Every day at 1:00 AM
String jobId = System.schedule(
    'Daily Account Cleanup',
    '0 0 1 * * ?',
    new WeeklyAccountCleanup()
);

// Every Monday at 8:30 AM
System.schedule('Monday Job', '0 30 8 ? * MON', new WeeklyAccountCleanup());

// First day of every month at midnight
System.schedule('Monthly Job', '0 0 0 1 * ?', new WeeklyAccountCleanup());

// Abort a scheduled job
System.abortJob(jobId);
```

**CRON expression format:**

```
┌─────── seconds (0–59)
│ ┌───── minutes (0–59)
│ │ ┌─── hours (0–23)
│ │ │ ┌─ day of month (1–31)
│ │ │ │ ┌─ month (1–12 or JAN–DEC)
│ │ │ │ │ ┌─ day of week (1–7 or SUN–SAT)
│ │ │ │ │ │ ┌─ year (optional)
0 0 1 * * ? *
```

Special characters: `*` (all), `?` (no specific value, day fields only), `L` (last), `W` (weekday), `#` (nth weekday).

**Key points:**

- Max 100 scheduled Apex jobs at once
- Minimum interval: 1 hour (for repeated schedules via UI)
- Cannot guarantee exact execution time under heavy load

---

## Platform Events

Publish/subscribe event-driven architecture. Decouples producers and consumers.

**Define:** Setup → Platform Events → New Platform Event (e.g., `Order_Event__e`).

**Publish:**

```apex
Order_Event__e evt = new Order_Event__e(
    Order_Id__c = '001xx000003ABCD',
    Status__c = 'Shipped'
);

// Single event
Database.SaveResult sr = EventBus.publish(evt);
if (sr.isSuccess()) {
    System.debug('Event published: ' + sr.getId());
}

// Bulk publish
List<Order_Event__e> events = new List<Order_Event__e>();
events.add(new Order_Event__e(Order_Id__c = 'A', Status__c = 'New'));
events.add(new Order_Event__e(Order_Id__c = 'B', Status__c = 'New'));
List<Database.SaveResult> results = EventBus.publish(events);
```

**Subscribe via Apex trigger:**

```apex
trigger OrderEventTrigger on Order_Event__e (after insert) {
    List<Task> tasks = new List<Task>();
    for (Order_Event__e evt : Trigger.New) {
        tasks.add(new Task(
            Subject = 'Follow up: ' + evt.Order_Id__c,
            Status = 'New',
            Priority = 'High'
        ));
    }
    insert tasks;
}
```

**Retry on failure:**

```apex
trigger OrderEventTrigger on Order_Event__e (after insert) {
    for (Order_Event__e evt : Trigger.New) {
        try {
            // processing logic
        } catch (Exception e) {
            // Retry from this event on next invocation
            EventBus.RetryableException re = new EventBus.RetryableException();
            re.setMessage('Transient error: ' + e.getMessage());
            throw re;
        }
    }
}
```

**Key points:**

- Publish operations do NOT roll back on transaction failure
- `EventBus.publish()` counts against DML limits
- Subscribers run in their own transaction with fresh governor limits
- Supports `after insert` triggers only
- Set `Publish Behavior` to "Publish After Commit" or "Publish Immediately"

---

## Change Data Capture (CDC)

Streams record change events (create, update, delete, undelete) for subscribed objects.

**Enable:** Setup → Change Data Capture → Select objects.

**Event object:** `<ObjectName>ChangeEvent` (e.g., `AccountChangeEvent`).

```apex
trigger AccountCDC on AccountChangeEvent (after insert) {
    for (AccountChangeEvent evt : Trigger.New) {
        EventBus.ChangeEventHeader header = evt.ChangeEventHeader;

        String changeType = header.getChangeType();     // CREATE, UPDATE, DELETE, UNDELETE
        List<String> changedFields = header.getChangedFields();
        List<String> recordIds = header.getRecordIds();

        if (changeType == 'UPDATE' && changedFields.contains('Rating')) {
            // React to Rating changes
            System.debug('Rating changed on: ' + recordIds);
        }
    }
}
```

**Key points:**

- Near real-time (not synchronous)
- Enriched headers: changed fields, change origin, transaction info
- Gap detection: `EventBus.getReplayId()` to track position
- Respects field-level security and sharing
- Does NOT count against Apex trigger limits on the originating transaction

---

## Decision Guide: When to Use Which

| Method | Max Records | Callouts | Chaining | Monitoring | Use When |
|---|---|---|---|---|---|
| **@future** | N/A | Yes (`callout=true`) | No | No | Simple fire-and-forget, callouts from triggers |
| **Queueable** | N/A | Yes (implement `AllowsCallouts`) | Yes (1 per execute) | Yes (job ID) | Complex types, chaining, need job tracking |
| **Batch** | 50M (QueryLocator) | Yes (implement `AllowsCallouts`) | Chain in finish() | Yes (job ID) | Large data volumes, long-running processes |
| **Schedulable** | N/A | Via Batch/Queueable | Via Batch/Queueable | Yes (CronTrigger) | Recurring time-based execution |
| **Platform Events** | N/A | In subscriber | N/A | Via EventBusSubscriber | Decoupled event-driven architecture |

**Quick decision:**

1. Simple callout from trigger? → `@future`
2. Need complex params or chaining? → `Queueable`
3. Processing thousands/millions of records? → `Batch`
4. Need it on a schedule? → `Schedulable` (usually wrapping Batch/Queueable)
5. Cross-system or decoupled notification? → `Platform Events`

---

## Governor Limits by Async Type

| Limit | Synchronous | @future | Queueable | Batch (per execute) |
|---|---|---|---|---|
| SOQL queries | 100 | 200 | 200 | 200 |
| DML statements | 150 | 150 | 150 | 150 |
| Total records (DML) | 10,000 | 10,000 | 10,000 | 10,000 |
| Callouts | 100 | 100 | 100 | 100 |
| Heap size | 6 MB | 12 MB | 12 MB | 12 MB |
| CPU time | 10,000 ms | 60,000 ms | 60,000 ms | 60,000 ms |
| Max @future per txn | 50 | — | — | — |
| Max enqueueJob per txn | 50 | 1 | 1 | 1 |

---

## Monitoring Async Jobs

**Query AsyncApexJob:**

```apex
List<AsyncApexJob> jobs = [
    SELECT Id, ApexClassId, ApexClass.Name, Status, JobType,
           NumberOfErrors, JobItemsProcessed, TotalJobItems,
           CreatedDate, CompletedDate, ExtendedStatus
    FROM AsyncApexJob
    WHERE JobType IN ('Future', 'BatchApex', 'Queueable', 'ScheduledApex')
    ORDER BY CreatedDate DESC
    LIMIT 20
];

for (AsyncApexJob j : jobs) {
    System.debug(j.ApexClass.Name + ' | ' + j.Status + ' | Errors: ' + j.NumberOfErrors);
}
```

**Check specific batch job:**

```apex
Id batchId = Database.executeBatch(new AccountBatch());

AsyncApexJob job = [
    SELECT Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
    FROM AsyncApexJob
    WHERE Id = :batchId
];
// Status: Queued, Preparing, Processing, Completed, Failed, Aborted
```

**Query scheduled jobs (CronTrigger):**

```apex
List<CronTrigger> scheduled = [
    SELECT Id, CronJobDetail.Name, State, NextFireTime, PreviousFireTime,
           CronExpression, TimesTriggered
    FROM CronTrigger
    WHERE CronJobDetail.JobType = '7'  // Scheduled Apex
];
```

**Abort jobs:**

```apex
// Abort batch
System.abortJob(batchJobId);

// Abort scheduled
System.abortJob(cronTriggerId);
```
