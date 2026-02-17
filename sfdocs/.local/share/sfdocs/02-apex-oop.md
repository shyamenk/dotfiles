# Apex OOP Cheatsheet

## Classes & Access Modifiers

```apex
public class MyClass {
    private String secret;
    protected String familyOnly;
    public String openToAll;
    // global — visible across namespaces (managed packages)
}

global class ApiClass {
    global static void endpoint() { }
}
```

| Modifier    | Visibility                              |
| ----------- | --------------------------------------- |
| `private`   | Same class only (default)               |
| `protected` | Same class + subclasses                 |
| `public`    | Same namespace                          |
| `global`    | All namespaces (required for web services, REST, etc.) |

---

## Constructors & Overloading

```apex
public class Account {
    public String name;
    public String industry;

    // No-arg constructor
    public Account() {
        this('Default', 'Other');
    }

    // Parameterized constructor
    public Account(String name, String industry) {
        this.name = name;
        this.industry = industry;
    }
}

Account a1 = new Account();
Account a2 = new Account('Acme', 'Tech');
```

---

## Static vs Instance

```apex
public class Counter {
    // Shared across all instances (per-transaction)
    public static Integer count = 0;

    // Belongs to each instance
    public String label;

    public Counter(String label) {
        this.label = label;
        count++;
    }

    // Static method — called on the class
    public static Integer getCount() {
        return count;
    }

    // Instance method — called on an object
    public String getLabel() {
        return this.label;
    }
}

Counter c = new Counter('First');
Integer n = Counter.getCount(); // 1
```

**Key rules:**
- Static variables reset per transaction (not truly global state).
- Static methods cannot access instance variables.
- Instance methods can access static variables.

---

## Properties (get / set)

```apex
public class Contact {
    // Auto-property
    public String FirstName { get; set; }

    // Read-only externally
    public String FullName { get; private set; }

    // Computed property
    public String Greeting {
        get {
            return 'Hello, ' + FirstName;
        }
    }

    // Property with logic
    private String email;
    public String Email {
        get { return email; }
        set {
            if (value != null && value.contains('@')) {
                email = value.toLowerCase();
            }
        }
    }
}
```

---

## Inheritance — virtual / abstract / override

```apex
// ── Virtual class (can be extended, can be instantiated) ──
public virtual class Animal {
    public virtual String speak() {
        return '...';
    }

    public String breathe() {
        return 'inhale/exhale';
    }
}

public class Dog extends Animal {
    public override String speak() {
        return 'Woof';
    }
}

Animal a = new Dog();
a.speak(); // 'Woof'

// ── Abstract class (cannot be instantiated) ──
public abstract class Shape {
    public abstract Decimal area();

    public String describe() {
        return 'Area: ' + area();
    }
}

public class Circle extends Shape {
    private Decimal radius;
    public Circle(Decimal r) { this.radius = r; }

    public override Decimal area() {
        return Math.PI * radius * radius;
    }
}
```

---

## Interfaces & implements

```apex
public interface Discountable {
    Decimal getDiscount(Decimal price);
}

public interface Loggable {
    void log(String message);
}

// A class can implement multiple interfaces
public class PremiumCustomer implements Discountable, Loggable {
    public Decimal getDiscount(Decimal price) {
        return price * 0.20;
    }

    public void log(String message) {
        System.debug('PREMIUM: ' + message);
    }
}
```

Common platform interfaces: `Comparable`, `Schedulable`, `Database.Batchable<SObject>`, `Queueable`, `Database.Stateful`.

---

## Inner Classes

```apex
public class Outer {
    private String secret = 'hidden';

    public class Inner {
        public String getSecret(Outer o) {
            return o.secret; // inner classes CAN access outer private members
        }
    }

    // Often used for wrapper / response types
    public class Result {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
    }
}

Outer.Inner i = new Outer.Inner();
```

- Inner classes cannot be `virtual` or `abstract`.
- No implicit reference to the outer instance (unlike Java).

---

## Sharing Keywords

```apex
// Enforces record-level security (CRUD/FLS still manual)
public with sharing class SecureService { }

// Bypasses record-level security
public without sharing class AdminService { }

// Inherits sharing from the calling class
public inherited sharing class FlexService { }
```

| Keyword              | Behavior                                        |
| -------------------- | ----------------------------------------------- |
| `with sharing`       | Current user's sharing rules enforced            |
| `without sharing`    | Runs as system (all records visible)             |
| `inherited sharing`  | Uses caller's sharing; defaults to `with sharing` if no caller |

**Best practice:** Default to `with sharing`; use `without sharing` only in service layers that explicitly need it.

---

## Design Patterns

### Singleton

```apex
public class Settings {
    private static Settings instance;
    private Map<String, String> cache;

    private Settings() {
        cache = new Map<String, String>();
        for (App_Setting__mdt s : App_Setting__mdt.getAll().values()) {
            cache.put(s.DeveloperName, s.Value__c);
        }
    }

    public static Settings getInstance() {
        if (instance == null) {
            instance = new Settings();
        }
        return instance;
    }

    public String get(String key) {
        return cache.get(key);
    }
}

// Usage — SOQL runs only once per transaction
String val = Settings.getInstance().get('API_Endpoint');
```

### Factory

```apex
public interface NotificationSender {
    void send(String recipient, String body);
}

public class EmailSender implements NotificationSender {
    public void send(String recipient, String body) {
        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        m.setToAddresses(new String[]{ recipient });
        m.setPlainTextBody(body);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ m });
    }
}

public class SmsSender implements NotificationSender {
    public void send(String recipient, String body) {
        // callout to SMS API
    }
}

public class NotificationFactory {
    public static NotificationSender create(String channel) {
        switch on channel {
            when 'email' { return new EmailSender(); }
            when 'sms'   { return new SmsSender(); }
            when else    { throw new IllegalArgumentException('Unknown: ' + channel); }
        }
    }
}

// Usage
NotificationFactory.create('email').send('a@b.com', 'Hello');
```

### Strategy

```apex
public interface PricingStrategy {
    Decimal calculate(Decimal basePrice, Integer qty);
}

public class StandardPricing implements PricingStrategy {
    public Decimal calculate(Decimal basePrice, Integer qty) {
        return basePrice * qty;
    }
}

public class BulkPricing implements PricingStrategy {
    public Decimal calculate(Decimal basePrice, Integer qty) {
        Decimal discount = qty > 100 ? 0.15 : (qty > 50 ? 0.10 : 0);
        return basePrice * qty * (1 - discount);
    }
}

public class OrderCalculator {
    private PricingStrategy strategy;

    public OrderCalculator(PricingStrategy strategy) {
        this.strategy = strategy;
    }

    public Decimal getTotal(Decimal price, Integer qty) {
        return strategy.calculate(price, qty);
    }
}

// Usage
OrderCalculator calc = new OrderCalculator(new BulkPricing());
Decimal total = calc.getTotal(9.99, 200);
```

---

## System Classes Overview

| Class        | Purpose & Key Methods |
| ------------ | --------------------- |
| `System`     | `debug()`, `assert()`, `assertEquals()`, `now()`, `today()`, `abortJob()`, `enqueueJob()`, `schedule()` |
| `Database`   | `insert()`, `update()`, `upsert()`, `delete()`, `undelete()` with partial success via `allOrNone=false`; `query()`, `getQueryLocator()`, `countQuery()`, `setSavepoint()`, `rollback()` |
| `Schema`     | `getGlobalDescribe()`, `describeSObjects()`, `SObjectType`, `DescribeSObjectResult`, `DescribeFieldResult` — runtime metadata inspection |
| `Limits`     | `getQueries()`, `getLimitQueries()`, `getDmlStatements()`, `getLimitDmlStatements()`, `getHeapSize()`, `getCpuTime()` — governor limit checks |
| `UserInfo`   | `getUserId()`, `getProfileId()`, `getOrganizationId()`, `getSessionId()`, `getTimeZone()`, `isMultiCurrencyOrganization()` |
| `JSON`       | `serialize()`, `serializePretty()`, `deserialize()`, `deserializeUntyped()`, `deserializeStrict()` |
| `Test`       | `startTest()`, `stopTest()`, `isRunningTest()`, `createStub()`, `loadData()` — fresh governor limits between start/stop |

```apex
// Database partial success
Database.SaveResult[] results = Database.insert(records, false);
for (Database.SaveResult sr : results) {
    if (!sr.isSuccess()) {
        for (Database.Error err : sr.getErrors()) {
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
        }
    }
}

// Schema describe
Schema.DescribeSObjectResult dsr = Account.SObjectType.getDescribe();
Map<String, Schema.SObjectField> fields = dsr.fields.getMap();

// Limits check
System.debug('SOQL: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
```

---

## Common Annotations

### @AuraEnabled

Expose methods/properties to Lightning components (Aura & LWC).

```apex
public with sharing class AccountController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        return [SELECT Id, Name FROM Account LIMIT 50];
    }

    @AuraEnabled
    public static void updateAccount(Id accountId, String name) {
        update new Account(Id = accountId, Name = name);
    }
}
```

### @InvocableMethod / @InvocableVariable

Callable from Flows, Process Builder, Einstein Bots.

```apex
public class LeadConverter {
    public class Request {
        @InvocableVariable(required=true label='Lead ID')
        public Id leadId;

        @InvocableVariable(label='Create Opportunity')
        public Boolean createOpp = false;
    }

    public class Result {
        @InvocableVariable(label='Account ID')
        public Id accountId;
    }

    @InvocableMethod(label='Convert Lead' description='Converts a lead to account/contact')
    public static List<Result> convert(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(req.leadId);
            lc.setConvertedStatus('Closed - Converted');
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            Result r = new Result();
            r.accountId = lcr.getAccountId();
            results.add(r);
        }
        return results;
    }
}
```

### @TestVisible

Access private members from test classes.

```apex
public class OrderService {
    @TestVisible private static Integer retryCount = 0;

    @TestVisible
    private static void resetState() {
        retryCount = 0;
    }
}
```

### @IsTest

Mark test classes and methods. Test code doesn't count against org code limits.

```apex
@IsTest
private class OrderServiceTest {

    @TestSetup
    static void setup() {
        insert new Account(Name = 'Test');
    }

    @IsTest
    static void testCreateOrder() {
        Test.startTest();
        // call method under test
        Test.stopTest();
        // assertions
        System.assertEquals(1, [SELECT COUNT() FROM Order]);
    }

    @IsTest(SeeAllData=true)
    static void testWithOrgData() {
        // has access to real org data (avoid when possible)
    }
}
```

### @Future

Async execution in a separate transaction.

```apex
public class AsyncService {
    @Future
    public static void processAsync(Set<Id> recordIds) {
        List<Account> accs = [SELECT Id, Name FROM Account WHERE Id IN :recordIds];
        // long-running logic
    }

    @Future(callout=true)
    public static void callExternalApi(String endpoint) {
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
    }
}
```

**Limits:** max 50 `@Future` calls per transaction; no chaining futures; params must be primitive or collections of primitives.

### @RemoteAction

JavaScript Remoting from Visualforce pages.

```apex
global class RemoteController {
    @RemoteAction
    global static String fetchData(String query) {
        return JSON.serialize(Database.query(query));
    }
}
```

### @ReadOnly

Raises SOQL row limit to 1,000,000 (VF read-only mode or `@RemoteAction`).

```apex
public class ReportController {
    @RemoteAction @ReadOnly
    global static List<AggregateResult> getLargeReport() {
        return [SELECT StageName, COUNT(Id) cnt FROM Opportunity GROUP BY StageName];
    }
}
```

### Quick Reference Table

| Annotation           | Context                        | Key Constraint                     |
| -------------------- | ------------------------------ | ---------------------------------- |
| `@AuraEnabled`       | LWC / Aura controllers        | Must be `static` and `public/global` |
| `@InvocableMethod`   | Flow / Process Builder         | One per class, `List` in & out     |
| `@InvocableVariable` | Input/output for invocable     | Must be `public`, simple types     |
| `@TestVisible`       | Test access to private members | No runtime effect                  |
| `@IsTest`            | Test classes/methods           | Not counted in code coverage       |
| `@Future`            | Async processing               | Primitives only, max 50/txn       |
| `@RemoteAction`      | Visualforce JS Remoting        | Must be `global static`           |
| `@ReadOnly`          | Large queries (VF/Remote)      | No DML allowed                     |
