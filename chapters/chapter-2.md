## Reading and writing data

![Queries and mutations](./queries-and-mutations.png)

In its simplest form, GraphQL is all about asking for specific fields of objects. In this chapter you will learn how to interact with data using GraphQL's queries and mutations. Queries let you ask for data, whereas Mutations let you write data.

You will learn the following features of GraphQL syntax:

* Basic query
* Query specific fields
* Query multiple fields
* Operation name
* Arguments
* Aliases
* Fragments
* Variables
* Directives
* Default variables
* Mutations
* Inline fragments
* Meta fields

All concepts will have a runnable query implemented using `graphql-js`. This library exports a function called `graphql` which lets us send a query to a GraphQL schema. We will focus on the querying part in this chapter, while the next one will focus on how to create the schema. Learning how to use this library is really simple, and running GraphQL queries using Javascript will help you understand GraphQL.

Let's start with a basic query.

### Query

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/1-query.js:1:0

```js
const { graphql } = require("graphql");

const schema = require("../schema");

const query = `
  {
    users {
      email
    }
  }
`;

graphql(schema, query).then(result =>
  console.log(JSON.stringify(result, null, 2))
);
```

```bash
$ node queries/1-query.js
{
  "data": {
    "users": [
      {
        "email": "Hello World"
      },
      {
        "email": "Hello World"
      }
    ]
  }
}
```

### Fields

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/2-fields.js:1:0

```js
const { graphql } = require("graphql");

const schema = require("../schema");

const query = `
  {
    users {
      email
      pins {
        title
      }
    }
  }
`;

graphql(schema, query).then(result =>
  console.log(JSON.stringify(result, null, 2))
);
```

```bash
$ node queries/2-fields.js
{
  "data": {
    "users": [
      {
        "email": "Hello World",
        "pins": [
          {
            "title": "Hello World"
          },
          {
            "title": "Hello World"
          }
        ]
      },
      {
        "email": "Hello World",
        "pins": [
          {
            "title": "Hello World"
          },
          {
            "title": "Hello World"
          }
        ]
      }
    ]
  }
}
```

### Multiple fields

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/3-multiple-fields.js:1:0

```js
const { graphql } = require("graphql");

const schema = require("../schema");

const query = `
  {
    users {
      email
    }
    pins {
      title
    }
  }
`;

graphql(schema, query).then(result =>
  console.log(JSON.stringify(result, null, 2))
);
```

```bash
$ node queries/3-multiple-fields.js
{
  "data": {
    "users": [
      {
        "email": "Hello World"
      },
      {
        "email": "Hello World"
      }
    ],
    "pins": [
      {
        "title": "Hello World"
      },
      {
        "title": "Hello World"
      }
    ]
  }
}
```

### Operation name

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/4-operation-name.js:1:0

```js
const { graphql } = require("graphql");

const schema = require("../schema");

const query = `
  query GetUsers {
    users {
      email
      pins {
        title
      }
    }
  }
`;

graphql(schema, query).then(result =>
  console.log(JSON.stringify(result, null, 2))
);
```

```bash
$ node queries/4-operation-name.js
{
  "data": {
    "users": [
      {
        "email": "Hello World",
        "pins": [
          {
            "title": "Hello World"
          },
          {
            "title": "Hello World"
          }
        ]
      },
      {
        "email": "Hello World",
        "pins": [
          {
            "title": "Hello World"
          },
          {
            "title": "Hello World"
          }
        ]
      }
    ]
  }
}
```

### Arguments

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/5-arguments.js:1:0

```js
const { graphql } = require("graphql");

const schema = require("../schema");

const query = `
  query {
    pinById(id: "1") {
      title
    }
  }
`;

graphql(schema, query).then(result =>
  console.log(JSON.stringify(result, null, 2))
);
```

```bash
$ node queries/5-arguments.js
{
  "data": {
    "pinById": {
      "title": "Hello World"
    }
  }
}
```

### Aliases

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/6-aliases.js:1:0

```js
const { graphql } = require("graphql");

const schema = require("../schema");

const query = `
  query {
    firstPin: pinById(id: "1") {
      title
    }
    secondPin: pinById(id: "2") {
      title
    }
  }
`;

graphql(schema, query).then(result =>
  console.log(JSON.stringify(result, null, 2))
);
```

```bash
$ node queries/6-aliases.js
{
  "data": {
    "firstPin": {
      "title": "Hello World"
    },
    "secondPin": {
      "title": "Hello World"
    }
  }
}
```

### Fragments

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/7-fragments.js:1:0

```js
const { graphql } = require("graphql");

const schema = require("../schema");

const query = `
  query {
    pins {
      ...pinFields
    }
    users {
      email
      pins {
        ...pinFields
      }
    }
  }
  fragment pinFields on Pin {
    title
  }
`;

graphql(schema, query).then(result =>
  console.log(JSON.stringify(result, null, 2))
);
```

```bash
$ node queries/7-fragments.js
{
  "data": {
    "pins": [
      {
        "title": "Hello World"
      },
      {
        "title": "Hello World"
      }
    ],
    "users": [
      {
        "email": "Hello World",
        "pins": [
          {
            "title": "Hello World"
          },
          {
            "title": "Hello World"
          }
        ]
      },
      {
        "email": "Hello World",
        "pins": [
          {
            "title": "Hello World"
          },
          {
            "title": "Hello World"
          }
        ]
      }
    ]
  }
}
```

### Variables

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/8-variables.js:1:0

```js
const { graphql } = require('graphql');

const schema = require('../schema');

const query = `
  query ($id: String!) {
    pinById(id: $id) {
      title
    }
  }
`;

graphql(
  schema,
  query,
  undefined,
  undefined,
  {
    id: "1"
  }
).then(result => console.log(JSON.stringify(result, null, 2)))
```

```bash
$ node queries/8-variables.js 
{
  "data": {
    "pinById": {
      "title": "Hello World"
    }
  }
}
```

### Directives

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/9-directives.js:1:0

```js
const { graphql } = require('graphql');

const schema = require('../schema');

const query = `
  query ($withPins: Boolean!) {
    users {
      email
      pins @include(if: $withPins) {
        title
      }
    }
  }
`;

graphql(
  schema,
  query,
  undefined,
  undefined,
  {
    withPins: true
  }
).then(result => console.log(JSON.stringify(result, null, 2)))
```

```bash
$ node queries/9-directives.js 
{
  "data": {
    "users": [
      {
        "email": "Hello World",
        "pins": [
          {
            "title": "Hello World"
          },
          {
            "title": "Hello World"
          }
        ]
      },
      {
        "email": "Hello World",
        "pins": [
          {
            "title": "Hello World"
          },
          {
            "title": "Hello World"
          }
        ]
      }
    ]
  }
}
```

### Default variables

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/10-default-variables.js:1:0

```js
const { graphql } = require('graphql');

const schema = require('../schema');

const query = `
  query ($withPins: Boolean = true) {
    users {
      email
      pins @include(if: $withPins) {
        title
      }
    }
  }
`;

graphql(schema, query)
  .then(result => console.log(JSON.stringify(result, null, 2)))
```

### Mutations

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/11-mutations.js:1:0

```js
const { graphql } = require('graphql');

const schema = require('../schema');

const query = `
  mutation AddPin($pin: PinInput!) {
    addPin(pin: $pin) {
      id
      title
      link
      image
    }
  }
`;

graphql(
  schema,
  query,
  undefined,
  undefined,
  {
    pin: {
      title: "Hello world",
      link: "Hello world",
      image: "Hello world"
    }
  }
).then(result => console.log(JSON.stringify(result, null, 2)))
```

```bash
$ node queries/11-mutations.js 
{
  "data": {
    "addPin": {
      "id": "Hello World",
      "title": "Hello World",
      "link": "Hello World",
      "image": "Hello World"
    }
  }
}
```

### Inline fragments

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/12-inline-fragments.js:1:0

```js
const { graphql } = require('graphql');

const schema = require('../schema');

const query = `
  query ($text: String!) {
    search(text: $text) {
      ... on Person {
        email
      }
      ... on Pin {
        title
      }
    }
  }
`;

graphql(
  schema,
  query,
  undefined,
  undefined,
  {
    text: "Hello world"
  }
).then(result => console.log(JSON.stringify(result, null, 2)))
```

```bash
$ node queries/12-inline-fragments.js 
{
  "data": {
    "search": {
      "email": "Hello World"
    }
  }
}
```

### Meta fields

https://glitch.com/edit/#!/pinapp-queries-mutations?path=queries/13-meta-fields.js:1:0

```js
const { graphql } = require('graphql');

const schema = require('../schema');

const query = `
  query ($text: String!) {
    search(text: $text) {
      __typename
      ... on Person {
        email
      }
      ... on Pin {
        title
      }
    }
  }
`;

graphql(
  schema,
  query,
  undefined,
  undefined,
  {
    text: "Hello world"
  }
).then(result => console.log(JSON.stringify(result, null, 2)))
```

```bash
$ node queries/13-meta-fields.js 
{
  "data": {
    "search": {
      "__typename": "Admin",
      "email": "Hello World"
    }
  }
}
```
