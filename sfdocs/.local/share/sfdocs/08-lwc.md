# Lightning Web Components (LWC) Cheatsheet

---

## Component File Structure

```
myComponent/
├── myComponent.html       <!-- Template -->
├── myComponent.js         <!-- Controller -->
├── myComponent.css        <!-- Styles (scoped) -->
├── myComponent.js-meta.xml <!-- Metadata config -->
└── __tests__/
    └── myComponent.test.js <!-- Jest tests -->
```

File names must be camelCase. The folder name becomes the component tag: `<c-my-component>`.

---

## Template Syntax

### Data Binding

```html
<template>
  <p>{greeting}</p>
  <lightning-input value={name} onchange={handleChange}></lightning-input>
</template>
```

```javascript
import { LightningElement } from 'lwc';

export default class MyComponent extends LightningElement {
  greeting = 'Hello World';
  name = '';

  handleChange(event) {
    this.name = event.target.value;
  }
}
```

> Expressions use single `{}` — no `{{}}`. Only property references are allowed, no inline expressions like `{a + b}`.

### Computed Values (Getters)

```javascript
get fullName() {
  return `${this.firstName} ${this.lastName}`;
}
```

```html
<p>{fullName}</p>
```

### Iterators — for:each

```html
<template for:each={contacts} for:item="contact" for:index="idx">
  <li key={contact.Id}>
    {idx} - {contact.Name}
  </li>
</template>
```

### Iterators — iterator

```html
<template iterator:it={items}>
  <li key={it.value.Id}>
    <span if:true={it.first}>** FIRST **</span>
    {it.value.Name}
    <span if:true={it.last}>** LAST **</span>
  </li>
</template>
```

`iterator` exposes `value`, `index`, `first`, `last`.

### Conditional Rendering (Legacy)

```html
<template if:true={isVisible}>
  <p>Visible</p>
</template>
<template if:false={isVisible}>
  <p>Hidden</p>
</template>
```

### Conditional Rendering (Modern — lwc:if / lwc:elseif / lwc:else)

```html
<template lwc:if={isAdmin}>
  <p>Admin View</p>
</template>
<template lwc:elseif={isManager}>
  <p>Manager View</p>
</template>
<template lwc:else>
  <p>Standard View</p>
</template>
```

> Prefer `lwc:if` over `if:true`/`if:false` — it supports `elseif`/`else` and is the modern standard.

---

## Decorators

### @api — Public Property / Method

```javascript
import { LightningElement, api } from 'lwc';

export default class ChildComponent extends LightningElement {
  @api recordId;         // public reactive property
  @api title = 'Default';

  @api
  refresh() {            // public method callable by parent
    this.loadData();
  }
}
```

```html
<!-- Parent -->
<c-child-component record-id={myId} title="Hello"></c-child-component>
```

### @track — Deep Reactivity (Rarely Needed)

```javascript
import { LightningElement, track } from 'lwc';

export default class Example extends LightningElement {
  @track config = { color: 'red', size: 10 };

  changeColor() {
    this.config.color = 'blue'; // reactive because of @track
  }
}
```

> Since Spring '20, primitive fields are reactive by default. Use `@track` only when you need deep reactivity on object/array mutations.

### @wire — Reactive Data Fetching

```javascript
import { LightningElement, wire } from 'lwc';
import getContacts from '@salesforce/apex/ContactController.getContacts';

export default class Example extends LightningElement {
  @wire(getContacts)
  contacts;  // { data, error }
}
```

---

## Lifecycle Hooks

```javascript
import { LightningElement } from 'lwc';

export default class LifecycleDemo extends LightningElement {

  constructor() {
    super();
    // Runs on instantiation. Cannot access DOM or public props.
    // Do NOT touch `this.template`.
  }

  connectedCallback() {
    // Component inserted into DOM. Access public props.
    // Good for: fetch data, subscribe to events, add listeners.
  }

  renderedCallback() {
    // Called after every render. Use sparingly.
    // Guard with a flag to avoid infinite loops.
  }

  disconnectedCallback() {
    // Component removed from DOM.
    // Good for: cleanup listeners, unsubscribe.
  }

  errorCallback(error, stack) {
    // Catches errors in child components.
    // Acts as an error boundary.
    console.error(error.message, stack);
  }
}
```

**Order:** `constructor` → `connectedCallback` → `renderedCallback` (repeats on re-render) → `disconnectedCallback`.

---

## Wire Service

### @wire with Apex

```javascript
// Apex: ContactController.cls
// @AuraEnabled(cacheable=true)
// public static List<Contact> getContacts(String searchKey) { ... }

import { LightningElement, wire } from 'lwc';
import getContacts from '@salesforce/apex/ContactController.getContacts';

export default class ContactList extends LightningElement {
  searchKey = '';

  @wire(getContacts, { searchKey: '$searchKey' })
  contacts;
  // contacts.data / contacts.error

  @wire(getContacts, { searchKey: '$searchKey' })
  wiredContacts(result) {
    // Function syntax — result has { data, error }
    // result can also be refreshed via refreshApex(result)
    if (result.data) {
      this.records = result.data;
    } else if (result.error) {
      this.error = result.error;
    }
  }
}
```

> Reactive variables prefixed with `$` re-invoke the wire when they change.

### @wire with Lightning Data Service

```javascript
import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';

const FIELDS = [NAME_FIELD, INDUSTRY_FIELD];

export default class AccountDetail extends LightningElement {
  @api recordId;

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  account;

  get name() {
    return getFieldValue(this.account.data, NAME_FIELD);
  }

  get industry() {
    return getFieldValue(this.account.data, INDUSTRY_FIELD);
  }
}
```

---

## Imperative Apex Calls

```javascript
import { LightningElement } from 'lwc';
import getContacts from '@salesforce/apex/ContactController.getContacts';

export default class ImperativeExample extends LightningElement {
  contacts;
  error;

  async handleSearch() {
    try {
      this.contacts = await getContacts({ searchKey: this.searchTerm });
      this.error = undefined;
    } catch (error) {
      this.error = error;
      this.contacts = undefined;
    }
  }
}
```

> Apex methods called imperatively do NOT need `cacheable=true`. Use imperative for DML-performing methods.

### refreshApex

```javascript
import { refreshApex } from '@salesforce/apex';

// Store wired result for refresh
@wire(getContacts)
wiredResult;

async handleRefresh() {
  await refreshApex(this.wiredResult);
}
```

---

## Event Handling

### Creating and Dispatching Custom Events

```javascript
// Child
handleClick() {
  const event = new CustomEvent('selected', {
    detail: { contactId: this.contact.Id },
    bubbles: false,    // default: false
    composed: false    // default: false
  });
  this.dispatchEvent(event);
}
```

```html
<!-- Parent -->
<c-child-component onselected={handleSelected}></c-child-component>
```

```javascript
// Parent
handleSelected(event) {
  const contactId = event.detail.contactId;
}
```

### Event Propagation

| Setting | Behavior |
|---------|----------|
| `bubbles: false, composed: false` | Stays within immediate parent (default) |
| `bubbles: true, composed: false` | Bubbles within shadow DOM boundary |
| `bubbles: true, composed: true` | Crosses shadow DOM boundaries, bubbles to document |

---

## Parent-Child Communication

### Parent → Child: Public Props & Methods

```html
<!-- Parent template -->
<c-child message={parentMessage}></c-child>
<lightning-button label="Call Child" onclick={callChild}></lightning-button>
```

```javascript
// Parent
callChild() {
  this.template.querySelector('c-child').refresh();
}
```

```javascript
// Child
import { LightningElement, api } from 'lwc';

export default class Child extends LightningElement {
  @api message;

  @api
  refresh() {
    // invoked by parent
  }
}
```

### Child → Parent: Custom Events

See [Event Handling](#event-handling) above.

### Unrelated Components: Lightning Message Service

---

## Lightning Message Service (LMS)

### 1. Create Message Channel (metadata XML)

```
force-app/main/default/messageChannels/MyMessageChannel.messageChannel-meta.xml
```

```html
<?xml version="1.0" encoding="UTF-8"?>
<LightningMessageChannel xmlns="http://soap.sforce.com/2006/04/metadata">
  <masterLabel>MyMessageChannel</masterLabel>
  <isExposed>true</isExposed>
  <description>Channel for cross-component communication</description>
  <lightningMessageFields>
    <fieldName>recordId</fieldName>
    <description>The record Id</description>
  </lightningMessageFields>
</LightningMessageChannel>
```

### 2. Publisher Component

```javascript
import { LightningElement, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import MY_CHANNEL from '@salesforce/messageChannel/MyMessageChannel__c';

export default class Publisher extends LightningElement {
  @wire(MessageContext) messageContext;

  handlePublish() {
    const payload = { recordId: '001xx000003DGbYAAW' };
    publish(this.messageContext, MY_CHANNEL, payload);
  }
}
```

### 3. Subscriber Component

```javascript
import { LightningElement, wire } from 'lwc';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import MY_CHANNEL from '@salesforce/messageChannel/MyMessageChannel__c';

export default class Subscriber extends LightningElement {
  subscription = null;
  receivedId;

  @wire(MessageContext) messageContext;

  connectedCallback() {
    this.subscription = subscribe(
      this.messageContext,
      MY_CHANNEL,
      (message) => this.handleMessage(message)
    );
  }

  disconnectedCallback() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  handleMessage(message) {
    this.receivedId = message.recordId;
  }
}
```

---

## Navigation — NavigationMixin

```javascript
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NavExample extends NavigationMixin(LightningElement) {

  navigateToRecord() {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: '001xx000003DGbY',
        objectApiName: 'Account',
        actionName: 'view'   // 'view' | 'edit' | 'clone'
      }
    });
  }

  navigateToList() {
    this[NavigationMixin.Navigate]({
      type: 'standard__objectPage',
      attributes: {
        objectApiName: 'Contact',
        actionName: 'list'
      },
      state: {
        filterName: 'Recent'
      }
    });
  }

  navigateToNewRecord() {
    this[NavigationMixin.Navigate]({
      type: 'standard__objectPage',
      attributes: {
        objectApiName: 'Opportunity',
        actionName: 'new'
      }
    });
  }

  navigateToWebPage() {
    this[NavigationMixin.Navigate]({
      type: 'standard__webPage',
      attributes: {
        url: 'https://www.salesforce.com'
      }
    });
  }

  generateUrl() {
    this[NavigationMixin.GenerateUrl]({
      type: 'standard__recordPage',
      attributes: {
        recordId: '001xx000003DGbY',
        actionName: 'view'
      }
    }).then(url => {
      this.recordUrl = url;
    });
  }
}
```

---

## Lightning Data Service — Record Forms

### lightning-record-form (Auto-layout)

```html
<lightning-record-form
  record-id={recordId}
  object-api-name="Account"
  fields={fields}
  mode="edit"
  onsuccess={handleSuccess}
  onerror={handleError}>
</lightning-record-form>
```

```javascript
import NAME from '@salesforce/schema/Account.Name';
import INDUSTRY from '@salesforce/schema/Account.Industry';

export default class RecordFormDemo extends LightningElement {
  @api recordId;
  fields = [NAME, INDUSTRY];

  handleSuccess(event) {
    console.log('Saved:', event.detail.id);
  }
}
```

### lightning-record-view-form (Read-only, Custom Layout)

```html
<lightning-record-view-form record-id={recordId} object-api-name="Account">
  <div class="slds-grid">
    <div class="slds-col">
      <lightning-output-field field-name="Name"></lightning-output-field>
      <lightning-output-field field-name="Industry"></lightning-output-field>
    </div>
  </div>
</lightning-record-view-form>
```

### lightning-record-edit-form (Editable, Custom Layout)

```html
<lightning-record-edit-form
  record-id={recordId}
  object-api-name="Account"
  onsuccess={handleSuccess}>
  <lightning-messages></lightning-messages>
  <lightning-input-field field-name="Name"></lightning-input-field>
  <lightning-input-field field-name="Industry"></lightning-input-field>
  <lightning-button type="submit" label="Save"></lightning-button>
</lightning-record-edit-form>
```

### getRecord / getFieldValue (Wire)

```javascript
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';

@wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_NAME] })
account;

get accountName() {
  return getFieldValue(this.account.data, ACCOUNT_NAME);
}
```

---

## Base Lightning Components Overview

### lightning-input

```html
<lightning-input
  label="Name"
  value={name}
  type="text"
  onchange={handleChange}
  required>
</lightning-input>
<!-- Types: text, number, email, password, date, datetime, checkbox, toggle, file, url, tel, search -->
```

### lightning-button

```html
<lightning-button
  label="Save"
  variant="brand"
  onclick={handleSave}
  icon-name="utility:save">
</lightning-button>
<!-- Variants: base, neutral, brand, brand-outline, destructive, destructive-text, inverse, success -->
```

### lightning-card

```html
<lightning-card title="Contacts" icon-name="standard:contact">
  <lightning-button label="New" slot="actions" onclick={handleNew}></lightning-button>
  <div class="slds-p-horizontal_small">
    <p>Card body content</p>
  </div>
  <p slot="footer">Footer content</p>
</lightning-card>
```

### lightning-datatable

```html
<lightning-datatable
  key-field="id"
  data={data}
  columns={columns}
  onrowaction={handleRowAction}
  onsort={handleSort}
  sorted-by={sortedBy}
  sorted-direction={sortedDirection}
  show-row-number-column>
</lightning-datatable>
```

```javascript
columns = [
  { label: 'Name', fieldName: 'Name', type: 'text', sortable: true },
  { label: 'Email', fieldName: 'Email', type: 'email' },
  { label: 'Amount', fieldName: 'Amount', type: 'currency',
    typeAttributes: { currencyCode: 'USD' } },
  { label: 'Link', fieldName: 'url', type: 'url',
    typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
  { type: 'action', typeAttributes: {
      rowActions: [
        { label: 'Edit', name: 'edit' },
        { label: 'Delete', name: 'delete' }
      ]
    }
  }
];
```

### lightning-modal

```javascript
// myModal.js
import LightningModal from 'lightning/modal';

export default class MyModal extends LightningModal {
  handleOk() {
    this.close('ok');
  }
}
```

```html
<!-- myModal.html -->
<template>
  <lightning-modal-header label="Confirm"></lightning-modal-header>
  <lightning-modal-body>
    <p>Are you sure?</p>
  </lightning-modal-body>
  <lightning-modal-footer>
    <lightning-button label="OK" variant="brand" onclick={handleOk}></lightning-button>
  </lightning-modal-footer>
</template>
```

```javascript
// Caller component
import MyModal from 'c/myModal';

async handleOpenModal() {
  const result = await MyModal.open({
    size: 'small',   // 'small' | 'medium' | 'large' | 'full'
    description: 'Confirm action'
  });
  if (result === 'ok') { /* proceed */ }
}
```

---

## XML Metadata Configuration

```html
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
  <apiVersion>59.0</apiVersion>
  <isExposed>true</isExposed>
  <masterLabel>My Component</masterLabel>
  <description>A reusable component</description>

  <targets>
    <target>lightning__RecordPage</target>
    <target>lightning__AppPage</target>
    <target>lightning__HomePage</target>
    <target>lightning__FlowScreen</target>
    <target>lightning__Tab</target>
    <target>lightning__UtilityBar</target>
    <target>lightningCommunity__Page</target>
    <target>lightningCommunity__Default</target>
  </targets>

  <targetConfigs>
    <targetConfig targets="lightning__RecordPage">
      <objects>
        <object>Account</object>
        <object>Contact</object>
      </objects>
      <property name="title" type="String" label="Title" default="Hello" />
      <property name="showHeader" type="Boolean" label="Show Header" default="true" />
      <property name="maxRecords" type="Integer" label="Max Records" default="10" />
      <property name="variant" type="String" label="Variant"
                datasource="Standard,Compact,Detailed" />
    </targetConfig>

    <targetConfig targets="lightning__FlowScreen">
      <property name="inputValue" type="String" role="inputOnly" />
      <property name="outputValue" type="String" role="outputOnly" />
    </targetConfig>
  </targetConfigs>
</LightningComponentBundle>
```

### Design Attributes in Component

```javascript
import { LightningElement, api } from 'lwc';

export default class ConfigurableComponent extends LightningElement {
  @api title = 'Hello';
  @api showHeader = true;
  @api maxRecords = 10;
}
```

---

## Slots

### Default Slot

```html
<!-- container.html -->
<template>
  <div class="wrapper">
    <slot></slot>
  </div>
</template>
```

```html
<!-- Parent usage -->
<c-container>
  <p>This goes into the default slot</p>
</c-container>
```

### Named Slots

```html
<!-- card.html -->
<template>
  <div class="card">
    <header><slot name="header"></slot></header>
    <div class="body"><slot></slot></div>
    <footer><slot name="footer"></slot></footer>
  </div>
</template>
```

```html
<!-- Parent usage -->
<c-card>
  <span slot="header">Card Title</span>
  <p>Default slot content (body)</p>
  <span slot="footer">Footer text</span>
</c-card>
```

### Slot Change Detection

```javascript
renderedCallback() {
  const slot = this.template.querySelector('slot');
  if (slot) {
    slot.addEventListener('slotchange', () => {
      const assigned = slot.assignedNodes();
      console.log('Slotted nodes:', assigned.length);
    });
  }
}
```

---

## CSS Styling

### Scoped Styles

```css
/* myComponent.css — scoped to component automatically */
:host {
  display: block;
  padding: 1rem;
}

:host(.active) {
  border: 2px solid blue;
}

h1 {
  font-size: 1.5rem;
  color: var(--lwc-colorTextDefault, #333);
}

.container {
  display: flex;
  gap: 1rem;
}
```

### CSS Custom Properties (Theming)

```css
/* parent.css */
c-child {
  --child-bg-color: #f0f0f0;
  --child-text-color: navy;
}
```

```css
/* child.css */
:host {
  background-color: var(--child-bg-color, white);
  color: var(--child-text-color, black);
}
```

### SLDS Utility Classes

```html
<div class="slds-p-around_medium slds-m-bottom_small">
  <p class="slds-text-heading_small slds-text-color_weak">Styled text</p>
</div>
```

### Sharing Styles

```css
/* cssLibrary/cssLibrary.css */
.shared-button {
  background: var(--lwc-brandPrimary);
  color: white;
  border-radius: 4px;
}
```

```javascript
// myComponent.js
import { LightningElement } from 'lwc';
import sharedStyles from 'c/cssLibrary';

export default class MyComponent extends LightningElement {
  static stylesheets = [sharedStyles];
}
```

---

## Jest Testing Basics

### Setup

```
sfdx force:lightning:lwc:test:setup
```

### Basic Test

```javascript
// __tests__/myComponent.test.js
import { createElement } from 'lwc';
import MyComponent from 'c/myComponent';

describe('c-my-component', () => {

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it('renders greeting', () => {
    const element = createElement('c-my-component', { is: MyComponent });
    document.body.appendChild(element);

    const p = element.shadowRoot.querySelector('p');
    expect(p.textContent).toBe('Hello World');
  });

  it('updates on public property change', () => {
    const element = createElement('c-my-component', { is: MyComponent });
    element.title = 'Test Title';
    document.body.appendChild(element);

    return Promise.resolve().then(() => {
      const heading = element.shadowRoot.querySelector('h1');
      expect(heading.textContent).toBe('Test Title');
    });
  });
});
```

### Testing Events

```javascript
it('fires selected event on click', () => {
  const element = createElement('c-my-component', { is: MyComponent });
  document.body.appendChild(element);

  const handler = jest.fn();
  element.addEventListener('selected', handler);

  const button = element.shadowRoot.querySelector('lightning-button');
  button.click();

  expect(handler).toHaveBeenCalledTimes(1);
  expect(handler.mock.calls[0][0].detail).toEqual({ contactId: '003xx' });
});
```

### Mocking Wire Adapters

```javascript
import { createElement } from 'lwc';
import MyComponent from 'c/myComponent';
import getContacts from '@salesforce/apex/ContactController.getContacts';

jest.mock(
  '@salesforce/apex/ContactController.getContacts',
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const MOCK_CONTACTS = [
  { Id: '003xx1', Name: 'John' },
  { Id: '003xx2', Name: 'Jane' }
];

describe('c-my-component with wire', () => {
  it('renders contacts from wire', () => {
    const element = createElement('c-my-component', { is: MyComponent });
    document.body.appendChild(element);

    getContacts.emit(MOCK_CONTACTS);

    return Promise.resolve().then(() => {
      const items = element.shadowRoot.querySelectorAll('li');
      expect(items.length).toBe(2);
    });
  });

  it('handles wire error', () => {
    const element = createElement('c-my-component', { is: MyComponent });
    document.body.appendChild(element);

    getContacts.error();

    return Promise.resolve().then(() => {
      const errorEl = element.shadowRoot.querySelector('.error');
      expect(errorEl).not.toBeNull();
    });
  });
});
```

### Mocking Navigation

```javascript
import { createElement } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import MyNav from 'c/myNav';

const mockNavigation = require('lightning/navigation');

describe('navigation', () => {
  it('navigates to record page', () => {
    const element = createElement('c-my-nav', { is: MyNav });
    document.body.appendChild(element);

    const button = element.shadowRoot.querySelector('lightning-button');
    button.click();

    const { pageReference } = mockNavigation.Navigate.mock.calls[0][0];
    expect(pageReference.type).toBe('standard__recordPage');
  });
});
```

### Useful `flushPromises` Helper

```javascript
function flushPromises() {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

it('async test', async () => {
  const element = createElement('c-my-component', { is: MyComponent });
  document.body.appendChild(element);

  element.recordId = '001xx';
  await flushPromises();

  const el = element.shadowRoot.querySelector('.result');
  expect(el.textContent).toBe('Loaded');
});
```

---

## Quick Reference Table

| Pattern | Mechanism |
|---|---|
| Parent → Child data | `@api` property |
| Parent → Child action | `@api` method |
| Child → Parent | `CustomEvent` + `dispatchEvent` |
| Unrelated components | Lightning Message Service |
| Read record data | `@wire(getRecord)` / `lightning-record-*-form` |
| Call Apex (cached) | `@wire(apexMethod)` — needs `cacheable=true` |
| Call Apex (DML) | Imperative `await apexMethod()` |
| Navigate | `NavigationMixin` |
| Reactive re-fetch | `$` prefix in wire params |
| Refresh wired data | `refreshApex(wiredResult)` |
