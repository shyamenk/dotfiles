# Salesforce Integration Cheatsheet

---

## HTTP Callouts

### HttpRequest, HttpResponse, Http

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('https://api.example.com/data');
req.setMethod('GET');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Authorization', 'Bearer ' + token);
req.setTimeout(30000); // milliseconds, max 120000

Http http = new Http();
HttpResponse res = http.send(req);

System.debug(res.getStatusCode());  // 200
System.debug(res.getBody());        // response body string
System.debug(res.getHeader('Content-Type'));
```

### POST with Body

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('https://api.example.com/accounts');
req.setMethod('POST');
req.setHeader('Content-Type', 'application/json');
req.setBody('{"name":"Acme","industry":"Tech"}');

HttpResponse res = new Http().send(req);
if (res.getStatusCode() == 201) {
    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
}
```

### Blob / Binary Data

```apex
req.setBodyAsBlob(Blob.valueOf('binary content'));
Blob responseBlob = res.getBodyAsBlob();

// Send a document
req.setBodyDocument(domDocument);
```

---

## Named Credentials & External Credentials

Named Credentials store endpoint URL + authentication so you never hard-code secrets.

```apex
HttpRequest req = new HttpRequest();
// "callout:" prefix + Named Credential API name + path
req.setEndpoint('callout:My_Named_Credential/api/v1/accounts');
req.setMethod('GET');
// Auth header injected automatically
HttpResponse res = new Http().send(req);
```

**External Credentials** (post-Spring '23) separate authentication from the endpoint:

| Component | Purpose |
|---|---|
| **External Credential** | Defines auth protocol (OAuth 2.0, JWT, Custom, etc.) and principals |
| **Named Credential** | Defines the endpoint URL, references an External Credential |
| **Principal** | Maps a permission set to a specific set of credentials |

Setup: **Setup → Named Credentials → External Credentials** tab.

---

## Remote Site Settings

Required for any HTTP callout **not** using Named Credentials.

- **Setup → Remote Site Settings → New**
- Specify the full base URL (e.g., `https://api.example.com`)
- Must be HTTPS (HTTP only in sandbox with relaxed settings)
- Without this, callouts throw `System.CalloutException: Unauthorized endpoint`

---

## REST API (Salesforce Standard)

### Base URL

```
https://yourInstance.salesforce.com/services/data/vXX.0/
```

### Common Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/services/data/` | GET | List API versions |
| `/services/data/vXX.0/sobjects/` | GET | List all sObjects |
| `/services/data/vXX.0/sobjects/Account/` | POST | Create Account |
| `/services/data/vXX.0/sobjects/Account/{id}` | GET | Read Account |
| `/services/data/vXX.0/sobjects/Account/{id}` | PATCH | Update Account |
| `/services/data/vXX.0/sobjects/Account/{id}` | DELETE | Delete Account |
| `/services/data/vXX.0/query/?q=SELECT+...` | GET | SOQL query |
| `/services/data/vXX.0/composite/` | POST | Composite request |
| `/services/data/vXX.0/composite/tree/Account` | POST | Create record tree |
| `/services/data/vXX.0/composite/batch` | POST | Batch subrequests |

### Authentication

- **OAuth 2.0 flows**: Web Server (authorization code), JWT Bearer, Client Credentials, Device, Refresh Token
- **Session ID**: From `UserInfo.getSessionId()` (internal Apex calls)
- **Token endpoint**: `https://login.salesforce.com/services/oauth2/token`

```bash
# Example: Client Credentials flow
curl -X POST https://login.salesforce.com/services/oauth2/token \
  -d "grant_type=client_credentials" \
  -d "client_id=CONSUMER_KEY" \
  -d "client_secret=CONSUMER_SECRET"
```

---

## Apex REST (@RestResource)

Expose custom REST endpoints from Apex.

```apex
@RestResource(urlMapping='/Accounts/*')
global with sharing class AccountService {

    @HttpGet
    global static Account getAccount() {
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substringAfterLast('/');
        return [SELECT Id, Name, Industry FROM Account WHERE Id = :accountId];
    }

    @HttpPost
    global static Id createAccount(String name, String industry) {
        Account acc = new Account(Name = name, Industry = industry);
        insert acc;
        return acc.Id;
    }

    @HttpPut
    global static Account upsertAccount(String id, String name) {
        Account acc = new Account(Id = id, Name = name);
        upsert acc;
        return acc;
    }

    @HttpPatch
    global static Account updateAccount() {
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substringAfterLast('/');
        Account acc = [SELECT Id FROM Account WHERE Id = :accountId];
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
        if (body.containsKey('Name')) acc.Name = (String) body.get('Name');
        update acc;
        return acc;
    }

    @HttpDelete
    global static void deleteAccount() {
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substringAfterLast('/');
        delete [SELECT Id FROM Account WHERE Id = :accountId];
    }
}
```

**Endpoint**: `https://instance.salesforce.com/services/apexrest/Accounts/{id}`

### RestRequest / RestResponse Properties

```apex
RestRequest req = RestContext.request;
req.requestURI;          // /services/apexrest/Accounts/001xx
req.httpMethod;          // GET, POST, etc.
req.headers;             // Map<String, String>
req.params;              // Map<String, String> — query params
req.requestBody;         // Blob

RestResponse res = RestContext.response;
res.statusCode = 200;
res.responseBody = Blob.valueOf('{"status":"ok"}');
res.addHeader('Content-Type', 'application/json');
```

---

## SOAP Callouts (WSDL-Based)

### Generating Apex from WSDL

1. Obtain the external service WSDL file
2. **Setup → Apex Classes → Generate from WSDL**
3. Upload the WSDL → Salesforce generates proxy Apex classes
4. Add the endpoint to **Remote Site Settings**

```apex
// Using generated stub class
calculatorService.CalculatorPort calc = new calculatorService.CalculatorPort();
Double result = calc.add(5, 3); // calls external SOAP service
```

### Salesforce Enterprise/Partner WSDL

- **Enterprise WSDL**: Strongly typed, org-specific
- **Partner WSDL**: Loosely typed, generic across orgs

---

## JSON Handling

### JSON.serialize / JSON.deserialize

```apex
// Serialize: Object → JSON string
Account acc = new Account(Name = 'Acme');
String jsonStr = JSON.serialize(acc);
// '{"attributes":{"type":"Account"},"Name":"Acme"}'

// Pretty print
String pretty = JSON.serializePretty(acc);

// Deserialize: JSON string → typed Object
Account deserialized = (Account) JSON.deserialize(jsonStr, Account.class);

// With custom class
public class Payload {
    public String name;
    public Integer count;
}
Payload p = (Payload) JSON.deserialize('{"name":"test","count":5}', Payload.class);
```

### JSON.deserializeUntyped

Returns `Map<String, Object>` or `List<Object>` — useful for dynamic/unknown schemas.

```apex
String jsonStr = '{"name":"Acme","tags":["a","b"],"meta":{"key":"val"}}';
Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);

String name = (String) m.get('name');
List<Object> tags = (List<Object>) m.get('tags');
Map<String, Object> meta = (Map<String, Object>) m.get('meta');
```

### JSONParser (Streaming)

For large or complex JSON where you need fine-grained control.

```apex
JSONParser parser = JSON.createParser('{"name":"Acme","amount":100}');
String name;
Integer amount;

while (parser.nextToken() != null) {
    if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
        String field = parser.getText();
        parser.nextToken();
        if (field == 'name') {
            name = parser.getText();
        } else if (field == 'amount') {
            amount = parser.getIntegerValue();
        }
    }
}
```

### JSONGenerator

```apex
JSONGenerator gen = JSON.createGenerator(true); // pretty print
gen.writeStartObject();
gen.writeStringField('name', 'Acme');
gen.writeNumberField('amount', 500);
gen.writeFieldName('contacts');
gen.writeStartArray();
gen.writeStartObject();
gen.writeStringField('email', 'a@b.com');
gen.writeEndObject();
gen.writeEndArray();
gen.writeEndObject();
String result = gen.getAsString();
```

---

## XML Handling

### DOM Parsing

```apex
String xml = '<root><account><name>Acme</name></account></root>';
Dom.Document doc = new Dom.Document();
doc.load(xml);

Dom.XmlNode root = doc.getRootElement();
Dom.XmlNode account = root.getChildElement('account', null);
String name = account.getChildElement('name', null).getText(); // 'Acme'
```

### Building XML

```apex
Dom.Document doc = new Dom.Document();
Dom.XmlNode root = doc.createRootElement('root', null, null);
Dom.XmlNode acc = root.addChildElement('account', null, null);
acc.addChildElement('name', null, null).addTextNode('Acme');
String xmlStr = doc.toXmlString();
```

### XmlStreamReader / XmlStreamWriter

```apex
XmlStreamReader reader = new XmlStreamReader(xmlString);
while (reader.hasNext()) {
    if (reader.getEventType() == XmlTag.START_ELEMENT) {
        System.debug(reader.getLocalName());
    }
    reader.next();
}
```

---

## Connected Apps & OAuth Flows

### Connected App Setup

**Setup → App Manager → New Connected App**

- Enable OAuth Settings
- Set Callback URL
- Select OAuth Scopes (`api`, `refresh_token`, `full`, etc.)
- Obtain **Consumer Key** and **Consumer Secret**

### Common OAuth Flows

| Flow | Use Case |
|---|---|
| **Authorization Code** | Web apps with server-side backend |
| **JWT Bearer** | Server-to-server, no user interaction |
| **Client Credentials** | Server-to-server, org-level access (no user context) |
| **Device** | CLI tools, devices with limited input |
| **Refresh Token** | Renew access token without re-auth |
| **SAML Bearer** | SSO-integrated apps |
| **Asset Token** | IoT devices |

### JWT Bearer Flow (Apex Example)

```apex
Auth.JWT jwt = new Auth.JWT();
jwt.setSub('user@example.com');
jwt.setAud('https://login.salesforce.com');
jwt.setIss('CONNECTED_APP_CONSUMER_KEY');

Auth.JWS jws = new Auth.JWS(jwt, 'CertificateName');
Auth.JWTBearerTokenExchange exchange = new Auth.JWTBearerTokenExchange(
    'https://login.salesforce.com/services/oauth2/token', jws
);
String accessToken = exchange.getAccessToken();
```

---

## Callout Limits & Async Callouts

### Governor Limits

| Limit | Value |
|---|---|
| Max callouts per transaction | 100 |
| Max total callout timeout | 120 seconds |
| Max single callout timeout | 120 seconds |
| Max request/response size | 12 MB (heap) |
| Max SOQL/DML before callout | Allowed, but no callout after `getContent()` / `getContentAsPDF()` |

### No Callouts From Triggers (Directly)

Callouts in triggers must go through `@future(callout=true)` or Queueable.

```apex
// Future method for callouts
@future(callout=true)
public static void makeCallout(String recordId) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:My_Credential/api/' + recordId);
    req.setMethod('GET');
    HttpResponse res = new Http().send(req);
}
```

### Queueable with Callout

```apex
public class CalloutQueueable implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext ctx) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:My_Credential/api/data');
        req.setMethod('GET');
        HttpResponse res = new Http().send(req);
    }
}

// Enqueue
System.enqueueJob(new CalloutQueueable());
```

### Continuation (Async Callout in Lightning/Visualforce)

```apex
public class ContinuationController {
    @AuraEnabled(continuation=true cacheable=true)
    public static Object startRequest() {
        Continuation con = new Continuation(40); // timeout seconds
        con.continuationMethod = 'processResponse';

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:My_Credential/api/long-running');
        req.setMethod('GET');

        con.addHttpRequest(req);
        return con;
    }

    @AuraEnabled(cacheable=true)
    public static Object processResponse(List<String> labels, Object state) {
        HttpResponse res = Continuation.getResponse(labels[0]);
        return res.getBody();
    }
}
```

---

## Mock Callouts for Testing

Callouts are not allowed in test context. Use `HttpCalloutMock` or `StaticResourceCalloutMock`.

### HttpCalloutMock Interface

```apex
@isTest
global class MockHttpResponse implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"id":"001xx","name":"Acme"}');
        return res;
    }
}
```

### Using the Mock in Tests

```apex
@isTest
static void testCallout() {
    Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

    HttpRequest req = new HttpRequest();
    req.setEndpoint('https://api.example.com/data');
    req.setMethod('GET');
    HttpResponse res = new Http().send(req);

    System.assertEquals(200, res.getStatusCode());
    System.assert(res.getBody().contains('Acme'));
}
```

### Multi-Request Mock (Route-Based)

```apex
@isTest
global class MultiMock implements HttpCalloutMock {
    Map<String, HttpCalloutMock> mocks = new Map<String, HttpCalloutMock>();

    public void addMock(String endpoint, HttpCalloutMock mock) {
        mocks.put(endpoint, mock);
    }

    global HttpResponse respond(HttpRequest req) {
        HttpCalloutMock mock = mocks.get(req.getEndpoint());
        if (mock != null) return mock.respond(req);
        HttpResponse res = new HttpResponse();
        res.setStatusCode(404);
        return res;
    }
}
```

### StaticResourceCalloutMock

```apex
@isTest
static void testWithStaticResource() {
    StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
    mock.setStaticResource('TestResponse'); // static resource name
    mock.setStatusCode(200);
    mock.setHeader('Content-Type', 'application/json');
    Test.setMock(HttpCalloutMock.class, mock);
    // ... callout code
}
```

### WebServiceMock (for SOAP)

```apex
@isTest
global class MyWebServiceMock implements WebServiceMock {
    global void doInvoke(
        Object stub, Object request, Map<String, Object> response,
        String endpoint, String soapAction, String requestName,
        String responseNS, String responseName, String responseType
    ) {
        calculatorService.AddResponse resp = new calculatorService.AddResponse();
        resp.result = 8;
        response.put('response_x', resp);
    }
}

// In test
Test.setMock(WebServiceMock.class, new MyWebServiceMock());
```

---

## Platform Events (Async Integration)

Publish-subscribe model for real-time, event-driven integration.

### Define

**Setup → Platform Events → New**: Define fields on the event.

### Publish

```apex
// Single event
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
events.add(new Order_Event__e(Order_Id__c = '001', Status__c = 'New'));
events.add(new Order_Event__e(Order_Id__c = '002', Status__c = 'New'));
List<Database.SaveResult> results = EventBus.publish(events);
```

### Subscribe (Apex Trigger)

```apex
trigger OrderEventTrigger on Order_Event__e (after insert) {
    for (Order_Event__e evt : Trigger.New) {
        // Process each event
        System.debug('Order: ' + evt.Order_Id__c + ' Status: ' + evt.Status__c);
    }

    // Set resume checkpoint to handle retries
    EventBus.TriggerContext.currentContext().setResumeCheckpoint(
        Trigger.New[Trigger.New.size() - 1].ReplayId
    );
}
```

### Subscribe from External Systems

- **CometD** (Streaming API): `/event/Order_Event__e`
- **Pub/Sub API** (gRPC): Preferred for high-volume
- **Empapi** in LWC: `subscribe(channel, -1, callback)`

---

## Outbound Messages

Declarative integration: sends SOAP messages when workflow/flow criteria are met.

### Setup

1. **Setup → Outbound Messages → New**
2. Select sObject, fields to send, endpoint URL
3. Create a **Workflow Rule** or **Flow** to trigger the message
4. External endpoint receives a SOAP envelope with record data

### Characteristics

- Declarative (no code)
- Guaranteed delivery (retries for 24 hours)
- SOAP only (no REST)
- Sends to a single endpoint
- Ideal for near-real-time, reliable notifications

---

## Canvas Apps

Embed external web applications inside Salesforce UI.

### Overview

- External app renders in an iframe within Salesforce
- **Canvas SDK** provides signed request or OAuth for auth
- Supports placement in: Chatter Tab, Visualforce, Publisher, Mobile, Lightning Page
- **Signed Request**: Salesforce POSTs a signed JSON payload to your app with user/org context
- **Setup → Connected App → Canvas settings** (Canvas App URL, Access Method, Locations)

### Signed Request Verification

The external app receives `client_secret` to verify HMAC-SHA256 signature of the payload.

---

## External Services

Invoke external APIs declaratively — no Apex required.

### Setup

1. Register an **OpenAPI 3.0 (Swagger)** spec in Setup → External Services
2. Associate a **Named Credential** for authentication
3. Salesforce generates **invocable actions** from the spec
4. Use the actions in **Flows**, **Einstein Bots**, or **OmniStudio**

### Key Points

- Supports JSON-based REST APIs
- Auto-generates input/output types from the schema
- Max 100,000 characters for the OpenAPI spec
- Each operation becomes an invocable action
- Great for low-code integrations with external REST services

---

## Quick Reference: Integration Pattern Decision

| Scenario | Approach |
|---|---|
| Apex calling external REST | `HttpRequest` + Named Credential |
| Apex calling external SOAP | Generated WSDL proxy classes |
| External system calling Salesforce REST | Standard REST API or custom `@RestResource` |
| External system calling Salesforce SOAP | Enterprise/Partner WSDL |
| Real-time event-driven | Platform Events |
| Declarative outbound notification | Outbound Messages |
| Near-real-time subscribe | Change Data Capture / Streaming API |
| Fire-and-forget from trigger | `@future(callout=true)` or Queueable |
| Long-running callout in UI | Continuation |
| Low-code external API | External Services + Flow |
| Embed external app in SF | Canvas App |
