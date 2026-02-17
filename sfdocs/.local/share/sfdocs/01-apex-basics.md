# Apex Basics Cheatsheet

## Data Types

### Primitive Types

```apex
Integer i = 42;                        // 32-bit signed
Long l = 2147483648L;                  // 64-bit signed
Double d = 3.14159;                    // 64-bit floating point
Decimal dec = 19.99;                   // arbitrary precision (currency)
String s = 'Hello, Apex';             // single quotes only
Boolean b = true;                      // true, false, null
Date dt = Date.today();                // date only
Datetime dtt = Datetime.now();         // date + time
Time t = Time.newInstance(14, 30, 0, 0); // hour, min, sec, ms
Id recordId = '001xx000003DGbYAAW';    // 15 or 18 char Salesforce ID
Blob fileBody = Blob.valueOf('data');  // binary data
```

### Special Types

```apex
Object obj = 'anything';              // generic type, holds any value
sObject acc = new Account();           // generic sObject
Account a = new Account(Name='Acme'); // specific sObject
```

## Type Casting

```apex
// Widening (implicit)
Integer i = 10;
Double d = i;              // Integer -> Double
Decimal dec = i;           // Integer -> Decimal

// Narrowing (explicit)
Double d2 = 9.7;
Integer i2 = Integer.valueOf(d2);  // 10 (rounds)
Integer i3 = (Integer)d2;         // 9 (truncates)

// String conversions
String s = String.valueOf(42);
Integer fromStr = Integer.valueOf('42');
Double fromStr2 = Double.valueOf('3.14');
Decimal fromStr3 = Decimal.valueOf('19.99');
Boolean fromStr4 = Boolean.valueOf('true');
Date fromStr5 = Date.valueOf('2025-01-15');

// sObject casting
sObject sobj = [SELECT Id, Name FROM Account LIMIT 1];
Account acc = (Account)sobj;

// instanceof check
if (sobj instanceof Account) {
    Account a = (Account)sobj;
}
```

## String Methods

```apex
String s = '  Hello, World!  ';

// Info
s.length();                        // 19
s.contains('World');               // true
s.startsWith('  He');              // true
s.endsWith('!  ');                 // true
s.indexOf('World');                // 9
s.indexOf('x');                    // -1
s.countMatches('l');               // 3

// Extract
s.substring(9);                    // 'World!  '
s.substring(9, 14);               // 'World'
s.trim();                          // 'Hello, World!'

// Transform
s.toLowerCase();                   // '  hello, world!  '
s.toUpperCase();                   // '  HELLO, WORLD!  '
s.replace('World', 'Apex');        // '  Hello, Apex!  '
s.replaceAll('[aeiou]', '*');      // regex replace
s.split(',');                      // ['  Hello', ' World!  ']
s.trim().removeEnd('!');           // 'Hello, World'
s.trim().abbreviate(10);          // 'Hello, ...'

// Check
String.isBlank('  ');              // true (null, empty, whitespace)
String.isEmpty('');                // true (null or empty only)
String.isNotBlank('hi');           // true

// Format
String.format('Hi {0}, you have {1} items',
    new List<String>{'Admin', '5'});  // 'Hi Admin, you have 5 items'
String.valueOf(123);               // '123'
String.join(new List<String>{'a','b','c'}, ', '); // 'a, b, c'

// Comparison
'abc'.equals('abc');               // true (case-sensitive)
'abc'.equalsIgnoreCase('ABC');     // true
'abc'.compareTo('abd');            // -1
```

## Collections

### List (Ordered, Duplicates Allowed)

```apex
// Declaration
List<String> names = new List<String>();
List<String> names2 = new List<String>{'Alice', 'Bob', 'Charlie'};
String[] names3 = new String[]{'Alice', 'Bob'};  // array syntax

// Methods
names2.add('Dave');                // append
names2.add(1, 'Eve');             // insert at index
names2.addAll(new List<String>{'Frank', 'Grace'});
names2.get(0);                    // 'Alice'
names2.set(0, 'Alicia');          // replace at index
names2.remove(0);                 // remove at index, returns removed element
names2.size();                    // element count
names2.isEmpty();                 // true if size == 0
names2.contains('Bob');           // true
names2.indexOf('Bob');            // first index or -1
names2.sort();                    // in-place ascending sort
names2.clear();                   // remove all

// Iteration
for (String name : names2) {
    System.debug(name);
}

// List of sObjects
List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 10];
```

### Set (Unordered, No Duplicates)

```apex
// Declaration
Set<String> tags = new Set<String>();
Set<String> tags2 = new Set<String>{'apex', 'lwc', 'flow'};

// Methods
tags2.add('admin');                // returns true if added
tags2.addAll(new Set<String>{'vf', 'apex'}); // 'apex' ignored (dup)
tags2.remove('flow');              // returns true if removed
tags2.contains('lwc');             // true
tags2.size();                      // element count
tags2.isEmpty();                   // true if size == 0
tags2.clear();                     // remove all

// Set operations
Set<String> a = new Set<String>{'1','2','3'};
Set<String> b = new Set<String>{'2','3','4'};
a.retainAll(b);                    // intersection: {'2','3'}
a.removeAll(b);                    // difference
a.containsAll(b);                  // subset check

// Common pattern: collect IDs
Set<Id> accountIds = new Set<Id>();
for (Account acc : accounts) {
    accountIds.add(acc.Id);
}
// Or directly from query
Set<Id> ids = new Map<Id, Account>(
    [SELECT Id FROM Account LIMIT 10]
).keySet();
```

### Map (Key-Value Pairs)

```apex
// Declaration
Map<String, Integer> scores = new Map<String, Integer>();
Map<String, Integer> scores2 = new Map<String, Integer>{
    'Alice' => 95,
    'Bob' => 87,
    'Charlie' => 92
};

// Methods
scores2.put('Dave', 88);          // add/update entry
scores2.get('Alice');             // 95 (null if key absent)
scores2.containsKey('Bob');       // true
scores2.remove('Charlie');        // removes entry, returns value
scores2.size();                   // entry count
scores2.isEmpty();                // true if size == 0
scores2.keySet();                 // Set<String> of keys
scores2.values();                 // List<Integer> of values
scores2.clear();                  // remove all

// Map from SOQL (Id -> sObject)
Map<Id, Account> accMap = new Map<Id, Account>(
    [SELECT Id, Name FROM Account LIMIT 10]
);
Account a = accMap.get(someId);

// Iteration
for (String key : scores2.keySet()) {
    System.debug(key + ' => ' + scores2.get(key));
}
```

## Control Flow

### If / Else

```apex
if (score >= 90) {
    grade = 'A';
} else if (score >= 80) {
    grade = 'B';
} else {
    grade = 'C';
}

// Ternary
String result = (score >= 60) ? 'Pass' : 'Fail';
```

### Switch

```apex
switch on someValue {
    when 'A', 'B' {
        System.debug('Top tier');
    }
    when 'C' {
        System.debug('Average');
    }
    when null {
        System.debug('No value');
    }
    when else {
        System.debug('Other');
    }
}

// Switch on sObject type
switch on record {
    when Account a {
        System.debug('Account: ' + a.Name);
    }
    when Contact c {
        System.debug('Contact: ' + c.LastName);
    }
    when null {
        System.debug('Null');
    }
    when else {
        System.debug('Other sObject');
    }
}

// Switch on enum
switch on season {
    when WINTER {
        System.debug('Cold');
    }
    when SUMMER {
        System.debug('Hot');
    }
}
```

### Loops

```apex
// Traditional for
for (Integer i = 0; i < 10; i++) {
    System.debug(i);
}

// For-each
for (Account acc : [SELECT Name FROM Account]) {
    System.debug(acc.Name);
}

// While
Integer i = 0;
while (i < 5) {
    System.debug(i);
    i++;
}

// Do-while (executes at least once)
Integer j = 0;
do {
    System.debug(j);
    j++;
} while (j < 5);

// SOQL for loop (query in batches of 200, avoids heap limits)
for (List<Account> batch : [SELECT Id, Name FROM Account]) {
    for (Account acc : batch) {
        // process
    }
}
```

## Operators

### Arithmetic

```apex
Integer a = 10 + 3;   // 13
Integer b = 10 - 3;   // 7
Integer c = 10 * 3;   // 30
Integer d = 10 / 3;   // 3 (integer division)
Integer e = 10;
e += 5;               // 15
e -= 3;               // 12
e *= 2;               // 24
e++;                   // 25
e--;                   // 24
```

### Comparison

```apex
a == b      // equals (value comparison, works with null)
a != b      // not equals
a > b       // greater than
a < b       // less than
a >= b      // greater than or equal
a <= b      // less than or equal
a === b     // exact equals (same type and value)
a !== b     // exact not equals
```

### Logical

```apex
a && b      // AND (short-circuit)
a || b      // OR (short-circuit)
!a          // NOT
```

### String Concatenation

```apex
String full = 'Hello' + ' ' + 'World';  // 'Hello World'
full += '!';                              // 'Hello World!'
```

## Null Handling

### Safe Navigation Operator (`?.`)

```apex
// Without safe navigation
String city = null;
if (acc != null && acc.BillingAddress != null) {
    city = acc.BillingAddress.City;
}

// With safe navigation
String city = acc?.BillingAddress?.City;

// Works with methods
Integer len = someString?.length();  // null if someString is null

// Works with list/map access
String val = myList?.get(0);
String val2 = myMap?.get('key');
```

### Null Coalescing Operator (`??`)

```apex
// Returns left operand if non-null, otherwise right operand
String name = acc.Name ?? 'Unknown';

// Chaining
String value = first ?? second ?? 'default';

// Combined with safe navigation
String city = acc?.BillingAddress?.City ?? 'No City';
```

## Constants and Enums

### Constants

```apex
public class AppConstants {
    public static final String API_VERSION = 'v58.0';
    public static final Integer MAX_RETRIES = 3;
    public static final Decimal TAX_RATE = 0.08;

    // Constant list (still mutable at runtime — Apex has no deep freeze)
    public static final List<String> VALID_STAGES = new List<String>{
        'Prospecting', 'Qualification', 'Closed Won'
    };
}

// Usage
String v = AppConstants.API_VERSION;
```

### Enums

```apex
// Declaration
public enum Season { SPRING, SUMMER, FALL, WINTER }

// Usage
Season current = Season.SUMMER;

// Built-in methods
String name = current.name();      // 'SUMMER'
Integer pos = current.ordinal();   // 1 (zero-based)

// All values
List<Season> all = Season.values();

// Enum in a class
public class OrderProcessor {
    public enum Status { DRAFT, SUBMITTED, APPROVED, REJECTED }

    public static void process(Status s) {
        switch on s {
            when DRAFT {
                System.debug('Still in draft');
            }
            when SUBMITTED {
                System.debug('Under review');
            }
            when APPROVED {
                System.debug('Good to go');
            }
            when REJECTED {
                System.debug('Denied');
            }
        }
    }
}
```

## Exception Handling

### Try-Catch-Finally

```apex
try {
    Account acc = [SELECT Id FROM Account WHERE Name = 'Acme' LIMIT 1];
    update acc;
} catch (QueryException e) {
    System.debug('Query failed: ' + e.getMessage());
} catch (DmlException e) {
    System.debug('DML failed: ' + e.getMessage());
    System.debug('Cause: ' + e.getDmlMessage(0));
    System.debug('Fields: ' + e.getDmlFieldNames(0));
    System.debug('Status: ' + e.getDmlStatusCode(0));
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
    System.debug('Type: ' + e.getTypeName());
    System.debug('Line: ' + e.getLineNumber());
    System.debug('Stack: ' + e.getStackTraceString());
} finally {
    // Always executes
    System.debug('Cleanup complete');
}
```

### Common Exception Types

```apex
// DmlException          — insert/update/delete failures
// QueryException        — SOQL issues (e.g., no rows for assignment)
// ListException         — list index out of bounds
// NullPointerException  — method call on null reference
// MathException         — division by zero
// TypeException         — invalid type cast
// LimitException        — governor limit exceeded (cannot be caught)
// CalloutException      — HTTP/web service failures
// JSONException         — JSON parse errors
// StringException       — string operation errors
// NoAccessException     — CRUD/FLS violation
// SObjectException      — invalid field access
```

### Custom Exceptions

```apex
// Must extend Exception; name must end with 'Exception'
public class PaymentException extends Exception {}

public class InsufficientFundsException extends Exception {
    public Decimal shortfall;

    public InsufficientFundsException(Decimal amount, Decimal balance) {
        this('Insufficient funds. Short by: ' + (amount - balance));
        this.shortfall = amount - balance;
    }
}

// Throwing
if (balance < amount) {
    throw new InsufficientFundsException(amount, balance);
}

// Throwing with message
throw new PaymentException('Payment gateway timeout');

// Throwing with cause
try {
    // risky operation
} catch (Exception e) {
    throw new PaymentException('Wrapper error', e);
}

// Catching
try {
    processPayment(500.00);
} catch (InsufficientFundsException e) {
    System.debug('Short by: ' + e.shortfall);
} catch (PaymentException e) {
    System.debug(e.getMessage());
    Exception cause = e.getCause();
}
```
