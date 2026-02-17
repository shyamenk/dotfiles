# Salesforce Apex Testing Cheatsheet

## @IsTest Annotation & testMethod Keyword

```apex
@IsTest
static void shouldCreateAccount() {
    // preferred — use @IsTest annotation
}

// legacy keyword — avoid in new code
static testMethod void shouldCreateAccount() { }
```

## Test Class Structure & Conventions

```apex
@IsTest
private class AccountServiceTest {

    @TestSetup
    static void setup() {
        insert new Account(Name = 'Test Corp');
    }

    @IsTest
    static void shouldReturnAccountByName() {
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        Account result = AccountService.findByName('Test Corp');
        Test.stopTest();

        Assert.areEqual(acc.Id, result.Id, 'Should find the inserted account');
    }
}
```

**Conventions:**
- Class name: `<ClassUnderTest>Test`
- Method name: `should...` / `when...Then...` / descriptive verb phrase
- Always `private` — test classes are never called directly
- One logical assertion per test method when practical

## @TestSetup

Runs once before all test methods. Each method gets its own copy (rolled back after each).

```apex
@TestSetup
static void setup() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 5; i++) {
        accounts.add(new Account(Name = 'Acct ' + i));
    }
    insert accounts;
}
```

## Assertion Methods

### Legacy — System.assert*

```apex
System.assert(condition, 'optional message');
System.assertEquals(expected, actual, 'optional message');
System.assertNotEquals(unexpected, actual, 'optional message');
```

### Modern — Assert Class (Winter '23+, preferred)

```apex
Assert.areEqual(expected, actual, 'msg');
Assert.areNotEqual(unexpected, actual, 'msg');
Assert.isTrue(condition, 'msg');
Assert.isFalse(condition, 'msg');
Assert.isNull(value, 'msg');
Assert.isNotNull(value, 'msg');
Assert.isInstanceOfType(obj, Account.class, 'msg');
Assert.fail('should not reach here');
```

## Test.startTest() / Test.stopTest()

Resets governor limits between `startTest` and `stopTest`, giving the code under test a fresh set of limits. Also forces async work (future, queueable, batch) to execute synchronously.

```apex
@IsTest
static void shouldProcessWithFreshLimits() {
    // arrange — setup data (counts against test limits)
    List<Account> accounts = [SELECT Id FROM Account];

    Test.startTest();  // governor limits reset here
    AccountService.process(accounts);
    Test.stopTest();   // async work completes here

    // assert
    List<Task> tasks = [SELECT Id FROM Task];
    Assert.areEqual(accounts.size(), tasks.size());
}
```

## Test.isRunningTest()

Escape hatch for code that behaves differently in tests (use sparingly).

```apex
String endpoint = Test.isRunningTest()
    ? 'https://mock.example.com'
    : AppConfig.getEndpoint();
```

## Test Data Best Practices

- **Never rely on org data** — create everything in the test.
- Use **factory/utility classes** to centralize record creation.
- Use `@TestSetup` for shared baseline data.
- Avoid hardcoded IDs.

```apex
@IsTest
private class TestDataFactory {
    public static Account createAccount(String name) {
        return new Account(Name = name, Industry = 'Technology');
    }

    public static List<Contact> createContacts(Id accountId, Integer count) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                AccountId = accountId
            ));
        }
        return contacts;
    }
}
```

## @TestVisible

Grants test classes access to private members without changing visibility.

```apex
public class AccountService {
    @TestVisible
    private static Integer retryCount = 3;

    @TestVisible
    private static Boolean validateInput(String name) {
        return String.isNotBlank(name);
    }
}

@IsTest
private class AccountServiceTest {
    @IsTest
    static void shouldValidateInput() {
        Assert.isTrue(AccountService.validateInput('Acme'));
        Assert.isFalse(AccountService.validateInput(''));
    }

    @IsTest
    static void shouldOverrideRetryCount() {
        AccountService.retryCount = 1;
        // test with reduced retries
    }
}
```

## Testing Triggers

Trigger tests are indirect — insert/update/delete records and assert side effects.

```apex
@IsTest
static void shouldSetRatingOnInsert() {
    Account acc = new Account(Name = 'Big Corp', AnnualRevenue = 5000000);

    Test.startTest();
    insert acc;
    Test.stopTest();

    acc = [SELECT Rating FROM Account WHERE Id = :acc.Id];
    Assert.areEqual('Hot', acc.Rating);
}
```

## Testing Batch Apex

```apex
@IsTest
static void shouldProcessBatch() {
    insert new List<Account>{
        new Account(Name = 'A1'),
        new Account(Name = 'A2')
    };

    Test.startTest();
    Database.executeBatch(new AccountCleanupBatch(), 200);
    Test.stopTest(); // batch execute + finish run synchronously

    List<Account> results = [SELECT Status__c FROM Account];
    for (Account a : results) {
        Assert.areEqual('Cleaned', a.Status__c);
    }
}
```

## Testing Future Methods

```apex
@IsTest
static void shouldCallFutureMethod() {
    Account acc = new Account(Name = 'Future Test');
    insert acc;

    Test.startTest();
    AccountService.updateAsync(acc.Id); // @future method
    Test.stopTest(); // future executes here

    acc = [SELECT Description FROM Account WHERE Id = :acc.Id];
    Assert.areEqual('Updated', acc.Description);
}
```

## Testing Queueable

```apex
@IsTest
static void shouldExecuteQueueable() {
    Test.startTest();
    System.enqueueJob(new AccountProcessingJob());
    Test.stopTest();

    // assert expected outcomes
    Assert.areEqual(1, [SELECT COUNT() FROM Task]);
}
```

## Testing Schedulable

```apex
@IsTest
static void shouldScheduleJob() {
    String cron = '0 0 0 1 1 ? 2030';

    Test.startTest();
    String jobId = System.schedule('Test Job', cron, new AccountSchedulable());
    Test.stopTest();

    CronTrigger ct = [SELECT State FROM CronTrigger WHERE Id = :jobId];
    Assert.areEqual('WAITING', ct.State);
}
```

## Testing Callouts

### HttpCalloutMock

```apex
@IsTest
private class PaymentGatewayMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status":"success","txnId":"12345"}');
        return res;
    }
}

@IsTest
private class PaymentServiceTest {
    @IsTest
    static void shouldProcessPayment() {
        Test.setMock(HttpCalloutMock.class, new PaymentGatewayMock());

        Test.startTest();
        PaymentResult result = PaymentService.charge(100.00);
        Test.stopTest();

        Assert.areEqual('success', result.status);
    }
}
```

### StaticResourceCalloutMock

```apex
@IsTest
static void shouldParseStaticResourceResponse() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('PaymentSuccessResponse'); // static resource name
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    PaymentResult result = PaymentService.charge(50.00);
    Test.stopTest();

    Assert.isNotNull(result.txnId);
}
```

### MultiStaticResourceCalloutMock

```apex
@IsTest
static void shouldHandleMultipleEndpoints() {
    MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();
    mock.setStaticResource('https://api.pay.com/charge', 'ChargeResponse');
    mock.setStaticResource('https://api.pay.com/refund', 'RefundResponse');
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');
    Test.setMock(HttpCalloutMock.class, mock);

    Test.startTest();
    PaymentService.chargeAndRefund();
    Test.stopTest();
}
```

## System.runAs() — Profiles & Permission Sets

Tests run as the current user by default. Use `runAs` to test under a different user context (sharing rules, FLS, profile restrictions).

```apex
@IsTest
static void shouldRestrictStandardUser() {
    Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
    User testUser = new User(
        Alias = 'tstuser',
        Email = 'test@example.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Tester',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = stdProfile.Id,
        TimeZoneSidKey = 'America/New_York',
        Username = 'testuser' + DateTime.now().getTime() + '@example.com'
    );
    insert testUser;

    System.runAs(testUser) {
        try {
            insert new Account(Name = 'Restricted');
            Assert.fail('Expected DmlException');
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains('INSUFFICIENT_ACCESS'));
        }
    }
}
```

### Assigning Permission Sets in Tests

```apex
System.runAs(testUser) {
    PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Custom_Access'];
    insert new PermissionSetAssignment(
        AssigneeId = testUser.Id,
        PermissionSetId = ps.Id
    );
    // now testUser has the permission set
}
```

## SeeAllData=true (Avoid)

By default, tests cannot see org data (good). `SeeAllData=true` breaks isolation.

```apex
@IsTest(SeeAllData=true) // AVOID — makes tests fragile and org-dependent
private class BadTest { }
```

**When it's unavoidable:**
- Accessing standard price book (`Test.getStandardPricebookId()` is better)
- Some managed package objects
- `ConnectApi` tests

Always prefer creating test data explicitly.

## Stub API — System.StubProvider

Create mock implementations without real classes. Useful for dependency injection.

```apex
@IsTest
private class AccountServiceTest {

    private class MockSelector implements System.StubProvider {
        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> paramTypes,
            List<String> paramNames,
            List<Object> args
        ) {
            if (stubbedMethodName == 'getById') {
                return new Account(Name = 'Stubbed Account');
            }
            return null;
        }
    }

    @IsTest
    static void shouldUseStub() {
        AccountSelector mockSel = (AccountSelector) Test.createStub(
            AccountSelector.class,
            new MockSelector()
        );

        AccountService svc = new AccountService(mockSel);

        Test.startTest();
        Account result = svc.getAccount('001000000000001');
        Test.stopTest();

        Assert.areEqual('Stubbed Account', result.Name);
    }
}
```

## Code Coverage Requirements

| Requirement | Threshold |
|---|---|
| **Deployment minimum** | 75% org-wide |
| **Per trigger** | At least 1% (must have a test) |
| **Recommended** | 100% for business-critical code |

**Tips:**
- Coverage ≠ quality — assert outcomes, don't just execute lines.
- Run tests: `sfdx force:apex:test:run --code-coverage --result-format human`
- Check coverage: Setup → Apex Test Execution, or `sfdx force:apex:test:report`

```apex
// Bad — covers lines but proves nothing
@IsTest
static void coverageOnly() {
    new AccountService().process(new List<Account>());
}

// Good — verifies behavior
@IsTest
static void shouldCreateTaskForEachAccount() {
    List<Account> accounts = new List<Account>{
        new Account(Name = 'A1'),
        new Account(Name = 'A2')
    };
    insert accounts;

    Test.startTest();
    new AccountService().process(accounts);
    Test.stopTest();

    Assert.areEqual(2, [SELECT COUNT() FROM Task WHERE Subject = 'Follow Up']);
}
```
