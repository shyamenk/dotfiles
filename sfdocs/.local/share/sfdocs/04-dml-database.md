# DML Operations & Database Methods Cheatsheet

## DML Statements

Direct DML statements throw `DmlException` on failure — all or nothing.

```apex
// INSERT
Account acc = new Account(Name = 'Acme');
insert acc; // acc.Id is populated after insert

// UPDATE
acc.Name = 'Acme Corp';
update acc;

// UPSERT — insert or update based on ID or external ID field
upsert acc;
upsert acc External_Id__c; // match on external ID

// DELETE
delete acc;

// UNDELETE — restore from recycle bin
undelete acc;

// MERGE — merge up to 3 records into one (Accounts, Contacts, Leads)
Account master = [SELECT Id FROM Account WHERE Name = 'Acme Corp' LIMIT 1];
Account dupe = [SELECT Id FROM Account WHERE Name = 'Acme Duplicate' LIMIT 1];
merge master dupe; // dupe is deleted, children reparented
```

### Merge Details

```apex
// Merge up to 3 records
List<Account> dupes = [SELECT Id FROM Account WHERE Name LIKE 'Acme Dup%' LIMIT 2];
merge master dupes;
// - Child records (contacts, opps, etc.) reparented to master
// - Duplicate records deleted
// - Only works with Account, Contact, Lead, Case
```

---

## Database Methods

Partial success with `allOrNone = false`. No exception thrown on partial failure.

```apex
// Database.insert()
Database.SaveResult[] results = Database.insert(accounts, false); // allOrNone=false

// Database.update()
Database.SaveResult[] results = Database.update(accounts, false);

// Database.upsert()
Database.UpsertResult[] results = Database.upsert(accounts, External_Id__c, false);

// Database.delete()
Database.DeleteResult[] results = Database.delete(accountIds, false);

// Database.undelete()
Database.UndeleteResult[] results = Database.undelete(accountIds, false);
```

### allOrNone Parameter

| Value   | Behavior                                              |
|---------|-------------------------------------------------------|
| `true`  | All succeed or all fail (same as DML statement)       |
| `false` | Partial success — failed records skipped, no exception|

---

## Result Handling

### Database.SaveResult (insert/update)

```apex
Database.SaveResult[] results = Database.insert(accounts, false);
for (Database.SaveResult sr : results) {
    if (sr.isSuccess()) {
        System.debug('Inserted: ' + sr.getId());
    } else {
        for (Database.Error err : sr.getErrors()) {
            System.debug('Status: ' + err.getStatusCode());
            System.debug('Message: ' + err.getMessage());
            System.debug('Fields: ' + err.getFields());
        }
    }
}
```

### Database.UpsertResult

```apex
Database.UpsertResult[] results = Database.upsert(accounts, false);
for (Database.UpsertResult ur : results) {
    if (ur.isSuccess()) {
        System.debug((ur.isCreated() ? 'Created' : 'Updated') + ': ' + ur.getId());
    } else {
        for (Database.Error err : ur.getErrors()) {
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
        }
    }
}
```

### Database.DeleteResult

```apex
Database.DeleteResult[] results = Database.delete(accountIds, false);
for (Database.DeleteResult dr : results) {
    if (!dr.isSuccess()) {
        for (Database.Error err : dr.getErrors()) {
            System.debug(err.getMessage());
        }
    }
}
```

### Database.Error Methods

| Method             | Returns              | Description                        |
|--------------------|----------------------|------------------------------------|
| `getStatusCode()`  | `StatusCode` enum    | e.g. `FIELD_CUSTOM_VALIDATION_EXCEPTION` |
| `getMessage()`     | `String`             | Human-readable error message       |
| `getFields()`      | `List<String>`       | Fields that caused the error       |

---

## Savepoints & Rollback

```apex
Savepoint sp = Database.setSavepoint();
try {
    insert account;
    insert contacts;
} catch (DmlException e) {
    Database.rollback(sp);
}

// Limitations:
// - Static variable values are NOT rolled back
// - ID values on sObjects are NOT cleared after rollback
// - Don't use savepoints with callouts (after callout, no DML/rollback allowed)
// - Each savepoint counts against DML statement limit
```

---

## External ID Fields & Upsert

```apex
// Define external ID field on object (must be unique, indexed)
// Upsert matches existing records by external ID

List<Account> accounts = new List<Account>();
accounts.add(new Account(ERP_Id__c = 'ERP-001', Name = 'Acme'));
accounts.add(new Account(ERP_Id__c = 'ERP-002', Name = 'Globex'));

// Inserts if no match, updates if ERP_Id__c match found
upsert accounts ERP_Id__c;

// Foreign key resolution via external ID (no query needed)
Contact c = new Contact(
    LastName = 'Smith',
    Account = new Account(ERP_Id__c = 'ERP-001') // resolved by external ID
);
insert c;
```

---

## Record Locking (FOR UPDATE)

```apex
// Locks records to prevent concurrent modification
Account[] accs = [SELECT Id, Name FROM Account WHERE Id = :accId FOR UPDATE];
// Other transactions trying to lock same records will wait (up to 10 seconds)
// Throws QueryException if lock can't be acquired

// Use to prevent race conditions in concurrent operations
// Locked until transaction commits
```

---

## Bulk DML Best Practices

```apex
// BAD — DML inside loop
for (Account acc : accounts) {
    acc.Name = acc.Name + ' Updated';
    update acc; // hits governor limit quickly
}

// GOOD — collect and bulkify
List<Account> toUpdate = new List<Account>();
for (Account acc : accounts) {
    acc.Name = acc.Name + ' Updated';
    toUpdate.add(acc);
}
update toUpdate; // single DML statement

// GOOD — use Maps for related record lookups
Map<Id, Account> accountMap = new Map<Id, Account>(
    [SELECT Id, Name FROM Account WHERE Id IN :accountIds]
);
```

---

## DML Limits & Governor Limits

| Limit                                  | Value         |
|----------------------------------------|---------------|
| DML statements per transaction         | 150           |
| Total records processed by DML         | 10,000        |
| Records retrieved by SOQL              | 50,000        |
| Savepoints per transaction             | 5 (additional)|
| `FOR UPDATE` lock timeout              | 10 seconds    |
| Records per `merge` statement          | 3             |

```apex
// Check limits at runtime
System.debug('DML statements: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements());
System.debug('DML rows: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows());
```

---

## Trigger Context Variables

```apex
trigger AccountTrigger on Account (before insert, before update, before delete,
                                    after insert, after update, after delete, after undelete) {

    // Trigger.new — list of new versions of records (insert, update, undelete)
    // Trigger.old — list of old versions of records (update, delete)
    // Trigger.newMap — Map<Id, SObject> of new versions (update, after insert)
    // Trigger.oldMap — Map<Id, SObject> of old versions (update, delete)

    // Trigger.isInsert, isUpdate, isDelete, isUndelete
    // Trigger.isBefore, isAfter
    // Trigger.size — total records in trigger invocation
    // Trigger.operationType — enum: BEFORE_INSERT, AFTER_UPDATE, etc.
}
```

### Context Variable Availability

| Variable        | before insert | after insert | before update | after update | before delete | after delete | after undelete |
|-----------------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `Trigger.new`   | ✓   | ✓   | ✓   | ✓   |     |     | ✓   |
| `Trigger.old`   |     |     | ✓   | ✓   | ✓   | ✓   |     |
| `Trigger.newMap` |    | ✓   | ✓   | ✓   |     |     | ✓   |
| `Trigger.oldMap` |    |     | ✓   | ✓   | ✓   | ✓   |     |

```apex
// Common patterns
// Detect field changes in before/after update
for (Account acc : Trigger.new) {
    Account old = Trigger.oldMap.get(acc.Id);
    if (acc.Name != old.Name) {
        // Name changed
    }
}

// Modify records in before trigger (no DML needed)
for (Account acc : Trigger.new) {
    acc.Description = 'Auto-set in trigger';
}

// Add errors to prevent DML
for (Account acc : Trigger.new) {
    if (acc.Name == null) {
        acc.addError('Name is required');         // record-level error
        acc.Name.addError('Cannot be blank');      // field-level error
    }
}
```

---

## Platform Events & EventBus.publish()

```apex
// Define platform event: Order_Event__e (Setup > Platform Events)
// Fields are suffixed with __c

// Publishing
Order_Event__e evt = new Order_Event__e(
    Order_Id__c = '12345',
    Status__c = 'Shipped'
);
Database.SaveResult sr = EventBus.publish(evt);
if (sr.isSuccess()) {
    System.debug('Event published');
}

// Bulk publish
List<Order_Event__e> events = new List<Order_Event__e>();
events.add(new Order_Event__e(Order_Id__c = '001', Status__c = 'Created'));
events.add(new Order_Event__e(Order_Id__c = '002', Status__c = 'Created'));
List<Database.SaveResult> results = EventBus.publish(events);

// Subscribing via Apex trigger
trigger OrderEventTrigger on Order_Event__e (after insert) {
    for (Order_Event__e evt : Trigger.new) {
        System.debug('Order: ' + evt.Order_Id__c + ' Status: ' + evt.Status__c);
    }
}

// Key differences from standard DML:
// - Not subject to transaction rollback
// - EventBus.publish() counts toward DML limits
// - Use Trigger.operationType == System.TriggerOperation.AFTER_INSERT
// - Set resume checkpoint: EventBus.TriggerContext.currentContext().setResumeCheckpoint(evt.ReplayId);
```

---

## Quick Reference

```text
DML Statement        Database Method              Result Type
─────────────        ───────────────              ───────────
insert               Database.insert()            SaveResult
update               Database.update()            SaveResult
upsert               Database.upsert()            UpsertResult
delete               Database.delete()            DeleteResult
undelete             Database.undelete()          UndeleteResult
merge                (no Database method)         —
─                    EventBus.publish()           SaveResult
```
