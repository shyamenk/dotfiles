# Apex Triggers Cheatsheet

## Trigger Syntax

```apex
trigger TriggerName on ObjectName (event1, event2, ...) {
    // trigger body
}
```

```apex
trigger AccountTrigger on Account (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    // handle all events
}
```

## Trigger Events

| Event            | Timing | Use Case                                      |
| ---------------- | ------ | --------------------------------------------- |
| `before insert`  | Before | Default field values, validation, transform   |
| `before update`  | Before | Field validation, conditional field changes    |
| `before delete`  | Before | Prevent deletion, validation                  |
| `after insert`   | After  | Create related records, call external services |
| `after update`   | After  | Update related records, async processing       |
| `after delete`   | After  | Clean up related data, audit logging           |
| `after undelete` | After  | Restore related records                        |

> **Before triggers** — modify fields on `Trigger.new` directly (no DML needed for the triggering record).
> **After triggers** — records have IDs and are read-only; use DML to modify other records.

---

## Trigger Context Variables

| Variable                  | Type                      | Description                                           |
| ------------------------- | ------------------------- | ----------------------------------------------------- |
| `Trigger.new`             | `List<SObject>`           | New versions of records (insert, update, undelete)     |
| `Trigger.old`             | `List<SObject>`           | Old versions of records (update, delete)               |
| `Trigger.newMap`          | `Map<Id, SObject>`        | Map of new records by Id (after insert, update, undelete) |
| `Trigger.oldMap`          | `Map<Id, SObject>`        | Map of old records by Id (update, delete)              |
| `Trigger.isInsert`        | `Boolean`                 | True if fired by insert                                |
| `Trigger.isUpdate`        | `Boolean`                 | True if fired by update                                |
| `Trigger.isDelete`        | `Boolean`                 | True if fired by delete                                |
| `Trigger.isUndelete`      | `Boolean`                 | True if fired by undelete                              |
| `Trigger.isBefore`        | `Boolean`                 | True if before context                                 |
| `Trigger.isAfter`         | `Boolean`                 | True if after context                                  |
| `Trigger.isExecuting`     | `Boolean`                 | True if current context is a trigger                   |
| `Trigger.size`            | `Integer`                 | Total number of records (old + new)                    |
| `Trigger.operationType`   | `System.TriggerOperation` | Enum: `BEFORE_INSERT`, `AFTER_UPDATE`, etc.            |

### Availability Matrix

| Variable       | before insert | after insert | before update | after update | before delete | after delete | after undelete |
| -------------- | :-----------: | :----------: | :-----------: | :----------: | :-----------: | :----------: | :------------: |
| `Trigger.new`  | ✅            | ✅           | ✅            | ✅           | ❌            | ❌           | ✅             |
| `Trigger.old`  | ❌            | ❌           | ✅            | ✅           | ✅            | ✅           | ❌             |
| `Trigger.newMap` | ❌          | ✅           | ✅            | ✅           | ❌            | ❌           | ✅             |
| `Trigger.oldMap` | ❌          | ❌           | ✅            | ✅           | ✅            | ✅           | ❌             |

### Using operationType with switch

```apex
trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            AccountTriggerHandler.beforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            AccountTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            AccountTriggerHandler.afterInsert(Trigger.new, Trigger.newMap);
        }
        when AFTER_UPDATE {
            AccountTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
```

---

## Order of Execution

1. Load original record from database (or initialize for insert)
2. Load new field values from request and overwrite old values
3. **System validation rules** (required fields, field formats)
4. **Before triggers** execute
5. System validation rules run again, custom validation rules
6. Duplicate rules
7. Record saved to database (not committed)
8. **After triggers** execute
9. Assignment rules
10. Auto-response rules
11. **Workflow rules** — field updates from workflow re-trigger before/after update triggers (one more time only)
12. Escalation rules
13. **Flows** (record-triggered, before-save and after-save)
14. **Process Builder** (legacy — retired)
15. Entitlement rules
16. Roll-up summary field calculations on parent
17. Cross-object formula field calculations
18. Criteria-based sharing rules
19. **DML committed** to database
20. Post-commit logic (sending emails, enqueued async Apex)

> **Key insight:** If a workflow field update fires, the before and after update triggers run **again** on the same record. Use recursion guards.

---

## Bulkification

### Anti-pattern: SOQL/DML Inside Loops

```apex
// BAD — will hit governor limits
trigger ContactTrigger on Contact (after insert) {
    for (Contact c : Trigger.new) {
        Account a = [SELECT Id, Name FROM Account WHERE Id = :c.AccountId]; // SOQL in loop
        a.Description = 'Updated';
        update a; // DML in loop
    }
}
```

### Correct: Bulk Pattern

```apex
trigger ContactTrigger on Contact (after insert) {
    Set<Id> accountIds = new Set<Id>();
    for (Contact c : Trigger.new) {
        if (c.AccountId != null) {
            accountIds.add(c.AccountId);
        }
    }

    Map<Id, Account> accountMap = new Map<Id, Account>(
        [SELECT Id, Name, Description FROM Account WHERE Id IN :accountIds]
    );

    List<Account> toUpdate = new List<Account>();
    for (Contact c : Trigger.new) {
        if (c.AccountId != null && accountMap.containsKey(c.AccountId)) {
            Account a = accountMap.get(c.AccountId);
            a.Description = 'Has new contact: ' + c.LastName;
            toUpdate.add(a);
        }
    }

    if (!toUpdate.isEmpty()) {
        update toUpdate;
    }
}
```

---

## Trigger Handler Pattern

### Principle: One Trigger Per Object, Logic in Handler Class

```apex
// AccountTrigger.trigger — thin, delegates everything
trigger AccountTrigger on Account (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    new AccountTriggerHandler().run();
}
```

### Base Trigger Handler Class

```apex
public virtual class TriggerHandler {

    @TestVisible
    private static Set<String> bypassedHandlers = new Set<String>();

    public void run() {
        if (isBypassed()) {
            return;
        }

        switch on Trigger.operationType {
            when BEFORE_INSERT  { beforeInsert(); }
            when BEFORE_UPDATE  { beforeUpdate(); }
            when BEFORE_DELETE  { beforeDelete(); }
            when AFTER_INSERT   { afterInsert(); }
            when AFTER_UPDATE   { afterUpdate(); }
            when AFTER_DELETE   { afterDelete(); }
            when AFTER_UNDELETE { afterUndelete(); }
        }
    }

    // Override in subclass
    protected virtual void beforeInsert()  {}
    protected virtual void beforeUpdate()  {}
    protected virtual void beforeDelete()  {}
    protected virtual void afterInsert()   {}
    protected virtual void afterUpdate()   {}
    protected virtual void afterDelete()   {}
    protected virtual void afterUndelete() {}

    // Bypass mechanism
    public static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }

    private Boolean isBypassed() {
        return bypassedHandlers.contains(getHandlerName());
    }

    private String getHandlerName() {
        return String.valueOf(this).split(':')[0];
    }
}
```

### Concrete Handler

```apex
public class AccountTriggerHandler extends TriggerHandler {

    private List<Account> newRecords;
    private List<Account> oldRecords;
    private Map<Id, Account> newMap;
    private Map<Id, Account> oldMap;

    public AccountTriggerHandler() {
        this.newRecords = (List<Account>) Trigger.new;
        this.oldRecords = (List<Account>) Trigger.old;
        this.newMap = (Map<Id, Account>) Trigger.newMap;
        this.oldMap = (Map<Id, Account>) Trigger.oldMap;
    }

    protected override void beforeInsert() {
        setDefaults(newRecords);
        validateIndustry(newRecords);
    }

    protected override void beforeUpdate() {
        validateIndustry(newRecords);
    }

    protected override void afterInsert() {
        createDefaultContacts(newRecords);
    }

    protected override void afterUpdate() {
        syncToExternalSystem(newRecords, oldMap);
    }

    // --- Private helper methods ---

    private void setDefaults(List<Account> accounts) {
        for (Account a : accounts) {
            if (a.Industry == null) {
                a.Industry = 'Other';
            }
        }
    }

    private void validateIndustry(List<Account> accounts) {
        for (Account a : accounts) {
            if (a.AnnualRevenue != null && a.AnnualRevenue > 1000000 && a.Industry == null) {
                a.addError('Industry is required for high-revenue accounts.');
            }
        }
    }

    private void createDefaultContacts(List<Account> accounts) {
        List<Contact> contacts = new List<Contact>();
        for (Account a : accounts) {
            contacts.add(new Contact(
                LastName = 'Default Contact',
                AccountId = a.Id
            ));
        }
        insert contacts;
    }

    private void syncToExternalSystem(List<Account> accounts, Map<Id, Account> oldMap) {
        List<Id> changedIds = new List<Id>();
        for (Account a : accounts) {
            Account old = oldMap.get(a.Id);
            if (a.Name != old.Name || a.BillingCity != old.BillingCity) {
                changedIds.add(a.Id);
            }
        }
        if (!changedIds.isEmpty()) {
            AccountSyncService.enqueueSync(changedIds);
        }
    }
}
```

### Bypassing Triggers in Tests or Data Loads

```apex
TriggerHandler.bypass('AccountTriggerHandler');
insert new Account(Name = 'Skip Trigger');
TriggerHandler.clearBypass('AccountTriggerHandler');
```

---

## Recursion Prevention

### Static Variable Guard

```apex
public class TriggerRecursionGuard {
    private static Boolean hasRun = false;

    public static Boolean isFirstRun() {
        if (hasRun) {
            return false;
        }
        hasRun = true;
        return true;
    }

    public static void reset() {
        hasRun = false;
    }
}
```

```apex
trigger AccountTrigger on Account (after update) {
    if (TriggerRecursionGuard.isFirstRun()) {
        // logic that causes re-entry (e.g., DML on same object)
    }
}
```

### Per-Record Recursion Guard (Preferred)

```apex
public class RecursionGuard {
    private static Set<Id> processedIds = new Set<Id>();

    public static Boolean isAlreadyProcessed(Id recordId) {
        return processedIds.contains(recordId);
    }

    public static void markProcessed(Id recordId) {
        processedIds.add(recordId);
    }

    public static void markProcessed(Set<Id> recordIds) {
        processedIds.addAll(recordIds);
    }

    @TestVisible
    private static void reset() {
        processedIds.clear();
    }
}
```

```apex
protected override void afterUpdate() {
    List<Account> toProcess = new List<Account>();
    for (Account a : (List<Account>) Trigger.new) {
        if (!RecursionGuard.isAlreadyProcessed(a.Id)) {
            toProcess.add(a);
            RecursionGuard.markProcessed(a.Id);
        }
    }
    if (!toProcess.isEmpty()) {
        processAccounts(toProcess);
    }
}
```

---

## Common Patterns

### Field Update (Before Trigger)

```apex
protected override void beforeInsert() {
    for (Account a : newRecords) {
        if (String.isNotBlank(a.Website)) {
            a.Website = a.Website.toLowerCase().trim();
        }
        a.Account_Created_Date__c = Date.today();
    }
}
```

### Validation with addError()

```apex
protected override void beforeUpdate() {
    for (Account a : newRecords) {
        Account old = oldMap.get(a.Id);

        // Field-level error — highlights the field in the UI
        if (a.AnnualRevenue < old.AnnualRevenue) {
            a.AnnualRevenue.addError('Annual revenue cannot be decreased.');
        }

        // Record-level error — displays at the top of the page
        if (a.Rating == 'Hot' && a.Industry == null) {
            a.addError('Hot accounts must have an Industry.');
        }
    }
}
```

#### addError() Behavior

| Context          | Effect                                              |
| ---------------- | --------------------------------------------------- |
| UI (single)      | Error message displayed on page / field              |
| UI (list view)   | Partial success; error records shown to user         |
| Apex DML         | `DmlException` thrown; all records in batch rollback |
| REST / SOAP API  | Error returned in response; partial success possible with `allOrNone=false` |
| Bulk API         | Error logged per record; other records succeed       |

```apex
// On a before delete — use Trigger.old
protected override void beforeDelete() {
    for (Account a : (List<Account>) Trigger.old) {
        if (a.Type == 'Strategic') {
            a.addError('Strategic accounts cannot be deleted.');
        }
    }
}
```

### Related Record Creation (After Trigger)

```apex
protected override void afterInsert() {
    List<Opportunity> opps = new List<Opportunity>();
    for (Account a : newRecords) {
        if (a.Industry == 'Technology') {
            opps.add(new Opportunity(
                Name = a.Name + ' - Initial Opportunity',
                AccountId = a.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
    }
    if (!opps.isEmpty()) {
        insert opps;
    }
}
```

### Roll-Up Summary (After Trigger)

```apex
protected override void afterInsert() {
    recalculateContactCount();
}

protected override void afterUpdate() {
    recalculateContactCount();
}

protected override void afterDelete() {
    recalculateContactCount();
}

private void recalculateContactCount() {
    // Collect affected Account IDs
    Set<Id> accountIds = new Set<Id>();

    if (Trigger.new != null) {
        for (Contact c : (List<Contact>) Trigger.new) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }
    }
    if (Trigger.old != null) {
        for (Contact c : (List<Contact>) Trigger.old) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }
    }

    if (accountIds.isEmpty()) {
        return;
    }

    List<Account> accounts = [
        SELECT Id, (SELECT Id FROM Contacts)
        FROM Account
        WHERE Id IN :accountIds
    ];

    for (Account a : accounts) {
        a.Number_of_Contacts__c = a.Contacts.size();
    }

    update accounts;
}
```

### Detect Field Changes (After Update)

```apex
private List<Account> getChangedRecords(List<Account> newList, Map<Id, Account> oldMap, SObjectField field) {
    List<Account> changed = new List<Account>();
    for (Account a : newList) {
        if (a.get(field) != oldMap.get(a.Id).get(field)) {
            changed.add(a);
        }
    }
    return changed;
}

// Usage
List<Account> ownerChanged = getChangedRecords(newRecords, oldMap, Account.OwnerId);
```

---

## Best Practices

1. **One trigger per object** — consolidate all events into a single trigger file.
2. **No logic in triggers** — delegate to handler classes for testability.
3. **Bulkify everything** — never use SOQL or DML inside loops.
4. **Use `switch on Trigger.operationType`** — clearer than nested `if/else` chains.
5. **Guard against recursion** — use per-record static sets, not simple booleans.
6. **Query only what you need** — use selective SOQL with `WHERE Id IN :ids`.
7. **Check for empty collections** before DML: `if (!list.isEmpty()) { update list; }`.
8. **Use `addError()`** for validation instead of throwing exceptions.
9. **Avoid hardcoded IDs** — use Custom Metadata, Custom Labels, or queries.
10. **Make handlers unit-testable** — pass data in, don't rely on `Trigger.*` context inside helpers.

## Anti-Patterns

```apex
// ❌ SOQL in a loop
for (Contact c : Trigger.new) {
    Account a = [SELECT Id FROM Account WHERE Id = :c.AccountId];
}

// ❌ DML in a loop
for (Contact c : Trigger.new) {
    update new Account(Id = c.AccountId, Description = 'Updated');
}

// ❌ Hardcoded Record Type ID
if (a.RecordTypeId == '012000000000ABC') { }

// ✅ Use describe instead
Id rtId = Schema.SObjectType.Account
    .getRecordTypeInfosByDeveloperName()
    .get('Enterprise')
    .getRecordTypeId();

// ❌ Multiple triggers on the same object
trigger AccountTrigger1 on Account (before insert) { }
trigger AccountTrigger2 on Account (before insert) { } // execution order is undefined

// ❌ Future/queueable in a loop
for (Account a : Trigger.new) {
    MyFuture.doSomething(a.Id); // will exceed async limit
}

// ✅ Collect IDs, call once
Set<Id> ids = new Map<Id, Account>(Trigger.new).keySet();
MyFuture.doSomething(ids);
```

---

## Quick Reference

```text
Before Trigger → modify Trigger.new directly (no DML needed for same record)
After Trigger  → records are read-only, have IDs; use DML for other records
addError()     → before: on Trigger.new; before delete: on Trigger.old
Recursion      → static Set<Id> of processed records
Bulkify        → collect → query → process → DML (outside loops)
Testing        → use handler methods; bypass triggers for test data setup
```
