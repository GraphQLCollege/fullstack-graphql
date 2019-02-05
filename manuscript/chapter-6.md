# 6. Testing

Testing is key when producing solid software. A solid testing suite improves development speed because it provides confidence that all features keep working after adding new functionality.

This chapter will teach you how to test GraphQL APIs and clients. You will write tests that verify the behavior of all features you added in this book.

Let's start by learning about API testing.

## 6.1 How to test GraphQL APIs

This section will teach you how to test GraphQL APIs using two approaches. The first will test the GraphQL layer, and the second will test the HTTP layer. Both methods will use [Jest](http://facebook.github.io/jest/), a Javascript testing library.

The first approach tests the GraphQL layer by sending queries and mutations directly against the app's schema.

![Testing GraphQL layer](images/graphql-schema.png "Testing GraphQL layer")

The second approach tests that the HTTP layer works by creating a test client that sends queries and mutations against a server.

![Testing HTTP layer](images/client-server.png "Testing HTTP layer")

Both methodologies have benefits. Testing the HTTP layer is a great way to verify that your API works from the point of view of HTTP clients, which are the end users of an API. The other approach, testing the GraphQL layer, is faster and simpler because it does not add any HTTP-related overhead.

Which one you choose depends on your use case. It is always a good idea to test systems from the point of view of their users, so testing APIs in the HTTP layer is always a great approach. Sometimes you want faster test runs to improve developer productivity, so you decide that testing the GraphQL layer is the best approach. Remember that you can even mix and match approaches.

## 6.2 Testing setup

Before creating the tests itself, you will need to make some changes so that the codebase is more testable. Right now `server.js` defines a `Server` class, initializes it and calls `server.listen()`. The first change you need to make is split definition from usage.

Create a file called `index.js`. It will `require` the Server class from `server.js`, and call `listen`.

```js
const Server = require("./server");

const server = new Server();

server.listen().then(({ url }) => {
  console.log(`🚀  Server ready at ${url}`);
});
```

Modify the `start` script from `package.json`. It will run `index.js` instead of `server.js`.

```json
"scripts": {
  "start": "node index.js",
  // ...
},
```

Now it's time to prepare `server.js` for testing. You will modify `Server` so that you are able to setup and stop it between tests. The Server class needs to initialize in its constructor all the resources it needs, and free up those resources in its `stop` method.

Initialize database and pubsub in server's constructor. At this point, database initialization happens in `database.js`, and pubsub initialization happens in `pins/resolver.js`. Now they will both happen in the `Server` constructor from `server.js`.

Also create a `stop` function in the `Server` class. It will clean up the main database client and the pubsub database client. This is very important, because if you don't clear up database connections after each test run, you will have to manually stop your test suite because you will quickly run out of available database connections.

```js
const { ApolloServer } = require('apollo-server');
const { PostgresPubSub } = require("graphql-postgres-subscriptions");
const { Client } = require("pg");

const schema = require('./schema');
const createDatabase = require('./database');

class Server extends ApolloServer {
  constructor() {
    const database = createDatabase();
    const client = new Client({
      connectionString: process.env.NODE_ENV === "test" ?
        `${process.env.TEST_DATABASE_URL}?ssl=true` :
        `${process.env.DATABASE_URL}?ssl=true`
    });
    client.connect();
    const pubsub = new PostgresPubSub({
      client
    });
    super({
      schema,
      context: async ({ req }) => {
        const context = { database, pubsub };
        if (req && req.headers && req.headers.authorization) {
          context.token = req.headers.authorization;
        }
        return context;
      }
    });
    this.database = database;
    this.pubsub = pubsub;
  }
  stop() {
    return Promise.all([
      super.stop(),
      this.database.destroy(),
      this.pubsub.client.end()
    ]);
  }
}

module.exports = Server;
```

You may have noticed a new database url, called `TEST_DATABASE_URL`. Create a new database in any provider you'd like, and assign it to `TEST_DATABASE_URL=` in `.env`. Creating Postgres databases in Heroku is free of charge.

Now all resolvers can access database from their third argument, `context`. Modify all three resolvers by removing `const database = require("../database")` and accessing it from context.

Modify `authentication/resolvers.js`:

```js
// ...
const resolvers = {
  Query: {
    users: async (_, __, { database }) => { /* */ },
    me: async (_, __, { token, database }) => { /* */ }
  },
  Mutation: {
    sendShortLivedToken: async (_, { email }, { database }) => { /* */ },
    createLongLivedToken: (_, { token }) => { /* */ }
  },
  Person: { /* */ },
  User: {
    pins(person, _, { database }) { /* */ }
  }
```

Modify `pins/resolvers.js`. Remove `PostgresPubSub` initialization, because it already is in `server.js`. Access `pubsub` and `database` from resolvers' context.

```js
const { addPin } = require("./index");
const { verify, authorize } = require("../authentication");

const resolvers = {
  Query: {
    pins: (_ , __ , { database }) => database("pins").select(),
  },
  Mutation: {
    addPin: async (_, { pin }, { token, database, pubsub }) => { /* */ }
  },
  Subscription: {
    pinAdded: {
      subscribe: (_, __, { pubsub }) => { /* */ }
    }
  }
};

module.exports = resolvers;
```

Modify `search/resolvers.js`:

```js
const resolvers = {
  Query: {
    search: async (_, { text }, { database }) => { /* */ }
  },
  SearchResult: {
    __resolveType: searchResult => { /* */ }
  }
};

module.exports = resolvers;
```

Also modify `database.js` so that it exports an initialization function, instead of initializing the database and exporting its instance.

```js
module.exports = () => require('knex')(require("./knexfile"));
```

The final thing you need before you start writing tests is adding Jest to the `"devDependencies"` in `package.json` and also adding a `"test"` script. This script will run `jest --watchAll --runInBand`. `watchAll` reruns the test suite whenever a file changes, and `runInBand` runs all tests serially instead of concurrently. This behavior is necessary because all tests share a single database, and running all of them at the same time would result in data corruption.

```json
{
  "scripts": {
    // ...
    "test": "jest --watchAll --runInBand"
  },
  "devDependencies": {
    "jest": "^22.4.3"
  },
```

As with all examples, you can [remix the testing example](https://glitch.com/edit/#!/remix/pinapp-server-testing) in case you need to refer to a working project.

## 6.3 GraphQL layer

Testing the data layer is as simple as using the `graphql` function from `graphql-js` against your schema. You will recognize this pattern, because it is the same approach you used to learn queries and mutations in Chapter 1. The only difference this time is that you will use this library in the context of a Jest test.

To test queries using this approach, a good strategy is seeding the database before the first test, and cleaning it up after the last one. This allows you to write fast tests that verify multiple queries, because queries don't modify your data.

Jest snapshots are a great tool to test results of GraphQL queries. Snapshots store values in JSON files from each test on the first run. On successive runs of the test suite, Jest checks that the stored values have not changed. If the snapshots changed, the test fails; otherwise, it passes.

Testing GraphQL results using snapshots is great because it is low effort way to verify that everything works. You can write tests by focusing on requests, and not on responses. Focusing on JSON responses can be a lot of manual work, so delegating it to Jest makes you write tests in less time.

For example to write a test that checks the behavior of the `search` query, you could create a test that calls `graphql()` with a search query, a `"text"` variable with value `"First"`, and the app's schema.

You are going to use this technique to test the data layer of PinApp's. Create a file called `server.test.js` with the following code that tests users, pins and search queries:

```js
const { graphql } = require("graphql");

const createDatabase = require("./database");
const schema = require('./schema');
const { search } = require("./queries");

describe("GraphQL layer", () => {
  let database;
  beforeAll(async () => {
    database = createDatabase();
    return database.seed.run();
  });
  afterAll(() => database.destroy());

  it("should return users' pins", () => {
    const query = `
  {
    users {
      id
      email
      pins {
        user_id
      }
    }
  }  
  `;
    return graphql(schema, query, undefined, { database })
      .then(result => {
        expect(result.data.users).toMatchSnapshot();
      });
  });

  it("should list all pins", () => {
    const query = `
  {
    pins {
      id
      title
      link
      image
      user_id
    }
  }
  `;
    return graphql(schema, query, undefined, { database })
      .then(result => {
        expect(result.data.pins).toMatchSnapshot();
      });
  });

  it("should search pins by title", () => {
    return graphql(schema, search, undefined, { database }, { text: "First" })
      .then(result => {
        expect(result.data.search).toMatchSnapshot();
      });
  });
});
```

This approach is inspired by an awesome open source project called [Spectrum](https://spectrum.chat/). It has an extensive testing suite that uses Jest snapshots to test their GraphQL schema. Check out [Spectrum's github repository](https://github.com/withspectrum/spectrum/tree/e603e77bbb965bbbc7c678d9e9295e976c9381e0/api/test) to see this approach in a production codebase.

Sometimes it's best to recreate the exact conditions in which users interact with a system. In this case, users are HTTP clients, not `graphql-js` clients. The next section will teach you how to test the HTTP layer of GraphQL APIs.

## 6.4 HTTP Layer

To test the HTTP layer, you are going to create an instance of `Server` before each test, and stop it after each one. You are also going to delete all pins and users before each test, and delete all emails.

```js
const { graphql } = require("graphql");

const createDatabase = require("./database");
const schema = require('./schema');
const { search } = require("./queries");
const Server = require("./server");
const { deleteEmails } = require("./email");

describe("GraphQL layer", () => { /* */ });

describe("HTTP layer", () => {
  let server;
  let serverInfo;

  beforeEach(async () => {
    server = new Server();
    /*
      Ignore event emitter errors.
      In most cases this error appears because a database query got sent after closing database connection.
    */
    server.pubsub.ee.on("error", () => {});
    await Promise.all([
      server.database("users").del(),
      server.database("pins").del()
    ]);
    serverInfo = await server.listen({ http: { port: 3001 } });
    deleteEmails();
  });

  afterEach(() => server.stop());

  // Tests

});
```

Most of the time, the tests you can write against the HTTP layer are very similar to the tests you can write agains the GraphQL layer. For example, testing that unauthorized users cannot add pins consists of creating a query, and sending it either against an HTTP server or against the schema directly. In this case, we are going to write it against the HTTP server, but it is a matter of choice.

```js
const { graphql } = require("graphql");
const fetch = require("isomorphic-unfetch");

// ... Previous imports
const Server = require("./server");
const { deleteEmails } = require("./email");

describe("GraphQL layer", () => { /* */ });

describe("HTTP layer", () => {
  let server;
  let serverInfo;

  beforeEach(async () => { /* */ });

  afterEach(() => server.stop());

  it("should not allow unauthorized users to add pins", () => {
    const variables = {
      pin: {
        title: "Example",
        link: "http://example.com",
        image: "http://example.com"
      }
    };
    return fetch(serverInfo.url, {
      body: JSON.stringify({ query: addPin, variables }),
      headers: { "Content-Type": "application/json" },
      method: "POST"
    })
    .then(response => response.json())
    .then(response => {
      expect(response.errors).toMatchSnapshot();
    });
  });
```

## 6.5 Testing email based authentication

Up until this point, you have been using an SMTP server like [`Ethereal`](https://ethereal.email). But there is a better option for tests, Nodemailer provides the option of creating a JSON transport. This transporter does not communicate with any other server, it just stores the list of mails as JSON objects.

Modify `email.js` by setting JSON transport in tests:

```js
const nodemailer = require('nodemailer');

let transporter;

if (process.env.NODE_ENV === "test") {
  transporter = nodemailer.createTransport({
    jsonTransport: true
  });
} else {
  transporter = nodemailer.createTransport({
    host: 'smtp.ethereal.email',
    port: 587,
    auth: {
      user: process.env.MAIL_USER,
      pass: process.env.MAIL_PASSWORD
    }
  });
}

function sendMail({ from, to, subject, text, html }) {
  const mailOptions = {
    from,
    to,
    subject,
    text,
    html
  };
  return new Promise((resolve, reject) => {
    transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        return reject(error);
      }
      resolve(info);
    });
  });
}

module.exports = {
  sendMail
};
```

In order to test email authentication, you are going to need to access the list of emails sent. You can keep an array of emails sent in `email.js` and expose them. You are also going to need a way to clean up this list of emails, so you are also going to expose a function called `deleteEmails`.

```js
const nodemailer = require('nodemailer');

let transporter;
var emails = [];

if (process.env.NODE_ENV === "test") {
  /* */
} else {
  /* */
}

function sendMail({ from, to, subject, text, html }) {
  const mailOptions = { /* */ };
  emails.push(mailOptions);
  return new Promise((resolve, reject) => { /* */ });
}

function deleteEmails() {
  while(emails.length > 0) {
      emails.pop();
  }
}

module.exports = {
  emails,
  sendMail,
  deleteEmails
};
```

To test that users can create short lived tokens, you can send a `createShortLivedToken` query against the server, and check that it sent an email containing the user's address.

```js
const { graphql } = require("graphql");
const fetch = require("isomorphic-unfetch");

// ... Previous imports
const {
  search,
  createShortLivedToken,
} = require("./queries");
const Server = require("./server");
const { deleteEmails, emails } = require("./email");

describe("GraphQL layer", () => { /* */ });

describe("HTTP layer", () => {
  let server;
  let serverInfo;

  beforeEach(async () => { /* */ });

  afterEach(() => server.stop());

  // ...

  it("should allow users to create short lived tokens", () => {
    const email = "name@example.com";
    const variables = {
      email
    };
    return fetch(serverInfo.url, {
      body: JSON.stringify({ query: createShortLivedToken, variables }),
      headers: { "Content-Type": "application/json" },
      method: "POST"
    })
    .then(response => response.json())
    .then(response => {
      expect(emails[emails.length - 1].to).toEqual(email)
    });
  });
});
```

Testing that users can create long lived token is a little more complex. The strategy for testing this would be to first create a short lived token, then parse the token from the email sent and send it to the server as a `"token"` variable, along with a `createLongLivedToken` query.

To parse the token, you are going to use Node API's [`url.parse`](https://nodejs.org/docs/latest/api/url.html#url_url_parse_urlstring_parsequerystring_slashesdenotehost) function. When you pass it a URL as a first argument, and `true` as the second, it returns a query object. Parsing the url sent in the email message will contain a `token` key.

To verify that the long lived token generated with `createLongLivedToken` is valid, you are going to use the `verify` function from `authenticate/index.js`. It returns the token data, or an error if the token is not valid. Checking that the token's email is the same as the user's email will be enough to verify that authentication works.

```js
const { graphql } = require("graphql");
const fetch = require("isomorphic-unfetch");
const url = require("url");

// ... Previous imports
const {
  search,
  createShortLivedToken,
  createLongLivedToken,
} = require("./queries");
const Server = require("./server");
const { deleteEmails, emails } = require("./email");
const { verify } = require("./authentication");

describe("GraphQL layer", () => { /* */ });

describe("HTTP layer", () => {
  let server;
  let serverInfo;

  beforeEach(async () => { /* */ });

  afterEach(() => server.stop());

  // ...

  it("should allow users to create long lived tokens", () => {
    const email = "name@example.com";
    const variables = {
      email
    };
    return fetch(serverInfo.url, {
      body: JSON.stringify({ query: createShortLivedToken, variables }),
      headers: { "Content-Type": "application/json" },
      method: "POST"
    })
    .then(response => response.json())
    .then(response => {
      const token = url.parse(emails[emails.length - 1].text, true).query.token;
      return fetch(serverInfo.url, {
        body: JSON.stringify({ query: createLongLivedToken, variables: { token } }),
        headers: { "Content-Type": "application/json" },
        method: "POST"
      })
    })
    .then(response => response.json())
    .then(response => {
      expect(verify(response.data.createLongLivedToken).email).toEqual(email);
    });
  });
});
```

Testing that the app returns the current authenticated user consists of checking that the `me` query works. In order to test this, you need to simulate a login flow by creating a short lived token and exchanging it with a long lived one, finally passing it to the `me` query.

```js
it("should return authenticated user", () => {
  const email = "name@example.com";
  const variables = {
    email
  };
  let token;
  return fetch(serverInfo.url, {
    body: JSON.stringify({ query: createShortLivedToken, variables }),
    headers: { "Content-Type": "application/json" },
    method: "POST"
  })
  .then(response => response.json())
  .then(response => {
    token = url.parse(emails[emails.length - 1].text, true).query.token;
    return fetch(serverInfo.url, {
      body: JSON.stringify({ query: createLongLivedToken, variables: { token } }),
      headers: { "Content-Type": "application/json" },
      method: "POST"
    })
  })
  .then(response => response.json())
  .then(response => {
    return fetch(serverInfo.url, {
      body: JSON.stringify({ query: me }),
      headers: { "Content-Type": "application/json", Authorization: token },
      method: "POST"
    });
  })
  .then(response => response.json())
  .then(response => {
    expect(response.data).toMatchSnapshot();
  });
});
```

Another test that needs a complete login flow is checking that authenticated users can create pins. To test this, complete a login flow and send a long lived token, along with the `addPin` query to the server.

```js
  it("should allow authenticated users to create pins", () => {
    const email = "name@example.com";
    const variables = {
      email
    };
    let token;
    return fetch(serverInfo.url, {
      body: JSON.stringify({ query: createShortLivedToken, variables }),
      headers: { "Content-Type": "application/json" },
      method: "POST"
    })
    .then(response => response.json())
    .then(response => {
      token = url.parse(emails[emails.length - 1].text, true).query.token;
      return fetch(serverInfo.url, {
        body: JSON.stringify({ query: createLongLivedToken, variables: { token } }),
        headers: { "Content-Type": "application/json" },
        method: "POST"
      })
    })
    .then(response => response.json())
    .then(response => {
      const pin = {
        title: "Example",
        link: "http://example.com",
        image: "http://example.com"
      };
      return fetch(serverInfo.url, {
        body: JSON.stringify({ query: addPin, variables: { pin } }),
        headers: { "Content-Type": "application/json", Authorization: token },
        method: "POST"
      });
    })
    .then(response => response.json())
    .then(response => {
      expect(response.data).toMatchSnapshot();
    });
  });
```

This test completes all authentication related tests. The following section will teach you how to verify that subscriptions work in your API.

## 6.6 Subscription endpoints

To test GraphQL Subscriptions you need a Websockets client, in the same way that you need an HTTP client to test queries and mutations. In this section you are going to use a Websockets subscriptions client from the [`"subscriptions-transport-ws" library`](https://github.com/apollographql/subscriptions-transport-ws).

The first step is adding this library to `package.json`'s `"dependencies"`.

```json
{
  "dependencies": {
    // ...
    "subscriptions-transport-ws": "^0.9.9"
  }
}
```

Testing a subscription query (like `pinAdded` from PinApp schema) involves pointing an instance of `SubscriptionClient` to a subscriptions url, sending the query and checking that the result is valid.

To test `pinAdded` you need to simulate a login flow and create a pin. You are going to put this logic in a helper function called `authenticateAndAddPin`. It contains almost the same steps as the add pin test.

```js
const { graphql } = require("graphql");
const fetch = require("isomorphic-unfetch");
const url = require("url");
const { SubscriptionClient } = require("subscriptions-transport-ws");

// ...

describe("HTTP layer", () => {
  // ...
  it("should subscribe to pins", done => {
    const subscriptionClient = new SubscriptionClient(
      serverInfo.url.replace("http://", "ws://"),
      {
        reconnect: true,
        connectionCallback: error => {
          if (error) {
            done(error);
          }
        }
      }
    );
    subscriptionClient.on("connected", () => {
      subscriptionClient
        .request({
          query: pinsSubscription
        })
        .subscribe({
          next: result => {
            expect(result).toMatchSnapshot();
            done();
          },
          error: done
        });
      authenticateAndAddPin(serverInfo.url);
    });
    subscriptionClient.on("error", done);
  });
});

function authenticateAndAddPin(serverUrl) {
  const email = "name@example.com";
  const variables = {
    email
  };
  let token;
  return fetch(serverUrl, {
    body: JSON.stringify({ query: createShortLivedToken, variables }),
    headers: { "Content-Type": "application/json" },
    method: "POST"
  })
  .then(response => {
    token = url.parse(emails[emails.length - 1].text, true).query.token;
    const pin = {
      title: "Example",
      link: "http://example.com",
      image: "http://example.com"
    };
    return fetch(serverUrl, {
      body: JSON.stringify({ query: addPin, variables: { pin } }),
      headers: { "Content-Type": "application/json", Authorization: token },
      method: "POST"
    })
    .then(response => response.json());
  })
  .then(response => {
    if (response.errors) {
      throw new Error(response.errors[0].message);
    }
  })
}
```

This is the final step in testing PinApp's API. The next sections will teach you how to test GraphQL clients, more specifically how to test Apollo GraphQL clients.

## 6.7 How to test React Apollo GraphQL clients

In this chapter you will learn how to test React Apollo clients. To do this, you will use [Jest](https://facebook.github.io/jest/) as a test runner, [Enzyme](https://github.com/airbnb/enzyme/) because it provides testing tools for React, and React Apollo's testing utilities.

To test the network layers, you are going to take advantage of the fact that Apollo GraphQL's network layer is configurable using [Apollo Link](https://www.apollographql.com/docs/react/advanced/network-layer.html). The strategy is swapping the Provider defined in `src/App.js` with a `MockedProvider`. This Provider is useful for testing purposes because it does not communicate with any server, instead it receives an array of mocks that it uses for sending GraphQL responses. If `MockedProvider` has a mock that corresponds to a request, it sends the mock's response. If no mock matches a request, it throws an error.

As with all steps, you have the chance to [remix the current example](https://glitch.com/edit/#!/remix/pinapp-client-testing) in case you need any help.

Let's write a basic test. You may have seen this test a bunch of times if you are used to bootstrapping apps using [`create-react-app`](https://github.com/facebook/create-react-app). This test verifies that the app renders without crashing. To stop the app from making network requests, you will use Jest to replace `ApolloProvider` with a dummy component. You will also wrap the app with React Router's `MemoryRouter`, because Jest runs in Node, not in the browser.

Create a file called `src/App.test.js` with the following contents:

```js
import React from "react";
import ReactDOM from "react-dom";
import { MockedProvider } from "react-apollo/test-utils";
import * as ReactRouter from "react-router";
import * as ReactApollo from "react-apollo";

const MemoryRouter = ReactRouter.MemoryRouter;

ReactApollo.ApolloProvider = jest.fn(({ children }) => <div>{children}</div>);

import App from "./App";

it("renders without crashing", () => {
  const div = document.createElement("div");
  ReactDOM.render(
    <MemoryRouter>
      <MockedProvider mocks={[]}>
        <App />
      </MockedProvider>
    </MemoryRouter>,
    div
  );
  ReactDOM.unmountComponentAtNode(div);
});
```

You also need to pass a property called `noRouter` to `pinapp-component`'s `Container`. Otherwise it will try to use a Router implementation which depends on the browser's history API, which is not available in Node. Pass `noRouter={process.env.NODE_ENV === "test"}` to `Container` in `src/App.js`

```js
// ...
export default class App extends React.Component {
  // ...
  render() {
    return (
      <ApolloProvider client={this.state.client}>
        <Container noRouter={process.env.NODE_ENV === "test"}>
          {/* */}
        </Container>
      </ApolloProvider>
    );
  }
```

Finally install `react-router` by adding it to `package.json`. Note that the previous test will work whether or not you install `react-router`. This happens because `pinapp-components` already has React Router as a dependency. But now React Router is also a dependency of your app, because you use `MemoryRouter` in your tests.

You also need to install `jest-cli` if you are following the examples on glitch. This is a temporary workaround because of a bug in `pnpm`, which is the package manager that Glitch uses. It is similar to NPM or Yarn, but much more disk efficient because it uses symlinks instead of installing duplicated packages. You normally don't need to install Jest if you are using `react-scripts` with Yarn or NPM, so skip `jest-cli` if you are developing outside of Glitch.

```json
{
  "dependencies": {
    // ...
    "jest-cli": "23.0.1",
    "react-router": "^4.2.0"
  }
}
```

Run the test suite by opening the console and running `npm test`.

Now let's write a test based on a use case of the app. You are going to verify that the app shows the text "There are no pins yet" initially.

Instead of using React to render the App, you will use Enzyme's `mount` function. It performs a full DOM rendering. just like calling `ReactDOM.render`, the difference is that choosing `mount` allows you to use Enzyme's querying and expectations capabilities.

You will pass a mock list instead of an empty array to `MockedProvider`. Mocks are object with two keys, `request` and `result`. `request` is an object that has a `query` key and can have a `variables` key. `result` contains a Javascript object that simulates the server's response. In this case mocks will consist of two elements, the first simulates a `LIST_PINS` query with a list of empty pins as response, and the second simulates a `PINS_SUBSCRIPTION` query with no pin as a response. These are the two requests that App sends when it starts.

```js
// ...
import {
  LIST_PINS,
  PINS_SUBSCRIPTION,
  CREATE_SHORT_LIVED_TOKEN,
  CREATE_LONG_LIVED_TOKEN,
  ME,
  ADD_PIN
} from "./queries";

it("shows 'There are no pins yet' initially", async () => {
  const mocks = [
    {
      request: { query: LIST_PINS },
      result: {
        data: {
          pins: []
        }
      }
    },
    {
      request: {
        query: PINS_SUBSCRIPTION
      },
      result: { data: { pinAdded: null } }
    }
  ];
  const wrapper = mount(
    <MemoryRouter>
      <MockedProvider mocks={mocks}>
        <App />
      </MockedProvider>
    </MemoryRouter>
  );
  // Wait for async pins query
  await wait();
  // Manually update enzyme wrapper
  // https://github.com/airbnb/enzyme/blob/master/docs/guides/migration-from-2-to-3.md#for-mount-updates-are-sometimes-required-when-they-werent-before)
  wrapper.update();
  expect(
    wrapper.contains(node => node.text() === "There are no pins yet.")
  ).toBe(true);
  wrapper.unmount();
});
```

Another useful test would be verifying that the app shows a list of pins when it receives a non empty pins response. The test structure for doing this is very similar to the previous test, with the difference that the `LIST_PINS` query will contain a list of pins in the response. This test will verify that there is an element with class pins that has three elements with class pin.

```js
it("should show a list of pins", async () => {
  const pins = [
    {
      id: "1",
      title: "Modern",
      link: "https://pinterest.com/pin/637540890973869441/",
      image:
        "https://i.pinimg.com/564x/5a/22/2c/5a222c93833379f00777671442df7cd2.jpg"
    },
    {
      id: "2",
      title: "Broadcast Clean Titles",
      link: "https://pinterest.com/pin/487585097141051238/",
      image:
        "https://i.pinimg.com/564x/85/ce/28/85ce286cba63daf522464a7d680795ba.jpg"
    },
    {
      id: "3",
      title: "Drawing",
      link: "https://pinterest.com/pin/618611698790230574/",
      image:
        "https://i.pinimg.com/564x/00/7a/2e/007a2ededa8b0ce87e048c60fa6f847b.jpg"
    }
  ];
  const mocks = [
    {
      request: { query: LIST_PINS },
      result: {
        data: {
          pins
        }
      }
    },
    {
      request: {
        query: PINS_SUBSCRIPTION
      },
      result: { data: { pinAdded: null } }
    }
  ];
  const wrapper = mount(
    <MemoryRouter>
      <MockedProvider mocks={mocks}>
        <App />
      </MockedProvider>
    </MemoryRouter>
  );
  await wait();
  wrapper.update();
  expect(wrapper.find(".pins .pin").length).toBe(3);
  wrapper.unmount();
});
```

## 6.8 Testing client-side authentication

The login flow consists of two steps. The first is when the user clicks login, and then fill the email input with an email address, clicking submit afterwards. The second step happens when the user clicks the link in the received email, going to `/verify?token=123456`, which will authenticate the user if the token is valid.

To test the first step, let's write a test that simulates the action that the user needs to take in order to receive a magic link in its email address. The first action is clicking the login button in the app's footer, which will redirect the user to the login page.

```js
wrapper.find('a[href="/login"]').simulate("click", { button: 0 });
```

To simulate user's actions, you will use an Enzyme function called `prop`. This function allows you to access properties from React components. In this case, it will be useful to access the `onChange` function from the email input, and the `onSubmit` function from the email form.

The app will need a mock that will handle the API call when the user sends a `CREATE_SHORT_LIVED_TOKEN` mutation, so you will add this mock to the list. If you don't add this mock, the test will fail.

Finally this test will verify that the app shows a an "Email sent" message.

```js
it("should allow users to login", async () => {
  const email = "name@example.com";
  const mocks = [
    {
      request: { query: LIST_PINS },
      result: {
        data: {
          pins: []
        }
      }
    },
    {
      request: {
        query: PINS_SUBSCRIPTION
      },
      result: { data: { pinAdded: null } }
    },
    {
      request: {
        query: CREATE_SHORT_LIVED_TOKEN,
        variables: {
          email
        }
      },
      result: {
        data: {
          sendShortLivedToken: true
        }
      }
    }
  ];
  const wrapper = mount(
    <MemoryRouter>
      <MockedProvider mocks={mocks}>
        <App />
      </MockedProvider>
    </MemoryRouter>
  );
  await wait();
  wrapper.update();
  expect(wrapper.find(".auth-banner").length).toBe(1);
  expect(wrapper.find('a[href="/profile"]').length).toBe(0);
  wrapper.find('a[href="/login"]').simulate("click", { button: 0 }); // Add { button: 0 } because of React Router bug https://github.com/airbnb/enzyme/issues/516
  wrapper
    .find("#email")
    .first()
    .prop("onChange")({ value: email });
  await wait();
  wrapper.update();
  wrapper.find("form").prop("onSubmit")({ preventDefault: () => {} });
  await wait();
  wrapper.update();
  expect(
    wrapper.contains(
      node =>
        node.text() === `We sent an email to ${email}. Please check your inbox.`
    )
  ).toBe(true);
  wrapper.unmount();
});
```

To test that the app authenticates users who enter the verify page, you will use a property from `MemoryRouter` called `initialEntries`. This property receives an array of URLs, so passing it `['/verify?token=${token}']` will start the app on the Verify page.

The list of mocks will need a response for the `CREATE_LONG_LIVED_TOKEN` query, containing a string that represents the auth token.

To verify that the authentication works, you will simulate a user who enters to the Profile page after a successful authentication. This is why you will add a response to the `ME` query to the list of mocks. Checking that the app shows the user's email is enough to verify that this test works.

```js
it("should authenticate users who enter verify page", async () => {
  const email = "name@example.com";
  const token = "5minutes";
  const mocks = [
    {
      request: { query: LIST_PINS },
      result: {
        data: {
          pins: []
        }
      }
    },
    {
      request: {
        query: PINS_SUBSCRIPTION
      },
      result: { data: { pinAdded: null } }
    },
    {
      request: {
        query: CREATE_LONG_LIVED_TOKEN,
        variables: {
          token
        }
      },
      result: {
        data: {
          createLongLivedToken: "30days"
        }
      }
    },
    {
      request: { query: ME },
      result: {
        data: {
          me: { email }
        }
      }
    }
  ];
  const initialEntries = [`/verify?token=${token}`];
  const wrapper = mount(
    <MemoryRouter initialEntries={initialEntries}>
      <MockedProvider mocks={mocks}>
        <App />
      </MockedProvider>
    </MemoryRouter>
  );
  await wait();
  wrapper.update();
  // Verify Page shows "Success!" for 1 second (1000 ms), then redirects to "/"
  await wait(1000);
  wrapper.update();
  wrapper.find('a[href="/profile"]').simulate("click", { button: 0 });
  await wait();
  wrapper.update();
  expect(
    wrapper.find(".profile-page").contains(node => node.text() === email)
  ).toBe(true);
  wrapper.unmount();
});
```

In the next step you will learn how to test client side subscriptions by creating a test that verifies that users can add pins.

## 6.9 Client subscriptions

MockedProvider is perfect for mocking request/response pairs, but it does not provide a way of testing server sent events, like subscriptions. Fortunately, React Apollo provides the tools you need to mock server sent events with `MockSubscriptionLink`.

To simulate subscription results, you can create an instance of `MockSubscriptionLink` and use a function called `simulateResult`.

```js
subscriptionsLink.simulateResult({
  result: {
    data: {
      pinAdded: {
        title,
        link,
        image,
        id: "1"
      }
    }
  }
});
```

The strategy for testing subscriptions will be creating a custom MockContainer, and accessing `subscriptionsLink` by exposing it as a class property. This allows you to call `simulateResult` anywhere in the test.

This MockContainer will have the same API and implementation as React Apollo's `MockProvider`. It will receive a list of mocks and create a `MockLink` using this list. It will merge this link with an instance of `MockSubscriptionLink` using `split`. To determine which link `MockSubscriptionsProvider` uses, you are going to define the same logic that you used to decide between `HttpLink` and `WebsocketLink` in `src/App.js`.

Import the new dependencies and define a class called `MockSubscriptionLink` at the end of `src/App.test.js`.

```js
// ...
import {
  MockedProvider,
  MockLink,
  MockSubscriptionLink
} from "react-apollo/test-utils";
import { InMemoryCache as Cache } from "apollo-cache-inmemory";
import { getMainDefinition } from "apollo-utilities";
import { split } from "apollo-link";
import ApolloClient from "apollo-client";

const ApolloProvider = ReactApollo.ApolloProvider;
const MemoryRouter = ReactRouter.MemoryRouter;

ReactRouter.Router = jest.fn(({ children }) => <div>{children}</div>);
ReactApollo.ApolloProvider = jest.fn(({ children }) => <div>{children}</div>);

// ...

it("should allow logged in users to add pins", async () => { /* */ });

class MockedSubscriptionsProvider extends React.Component {
  constructor(props, context) {
    super(props, context);
    const subscriptionsLink = new MockSubscriptionLink();
    const addTypename = false;
    const mocksLink = new MockLink(props.mocks, addTypename);
    const link = split(
      // split based on operation type
      ({ query }) => {
        const { kind, operation } = getMainDefinition(query);
        return kind === "OperationDefinition" && operation === "subscription";
      },
      subscriptionsLink,
      mocksLink
    );
    const client = new ApolloClient({
      link,
      cache: new Cache({ addTypename })
    });
    this.client = client;
    this.subscriptionsLink = subscriptionsLink;
  }
  render() {
    return (
      <ApolloProvider client={this.client}>
        {this.props.children}
      </ApolloProvider>
    );
  }
}
```

Now it's time to verify that logged in users can create pins, and the new pins appear in the list. This test will perform the same initial steps as the previous authentication tests. It will differ with those tests once it authenticates a user, because it will navigate to the add pin page instead of the profile.

Once the user is in the add pin page, it will simulate the user filling out the new pin form and clicking "Add". For this to complete successfully. you will add a mock for the `ADD_PIN` query to the mocks list.

After this, the test will simulate a new subscription result by accessing the `subscriptionsLink` from the `MockedSubscriptionsProvider` instance and calling `simulateResult` with a new pin.

The test will check that this new pin appears in the pins list by using `expect(wrapper.find(".pins .pin").length).toBe(1);`.

```js
it("should allow logged in users to add pins", async () => {
  const title = "GraphQL College";
  const link = "http://graphql.college";
  const image = "http://www.graphql.college/fullstack-graphql";
  const email = "name@example.com";
  const token = "5minutes";
  const mocks = [
    {
      request: { query: LIST_PINS },
      result: {
        data: {
          pins: []
        }
      }
    },
    {
      request: {
        query: PINS_SUBSCRIPTION
      },
      result: { data: { pinAdded: null } }
    },
    {
      request: {
        query: CREATE_LONG_LIVED_TOKEN,
        variables: {
          token
        }
      },
      result: {
        data: {
          createLongLivedToken: "30days"
        }
      }
    },
    {
      request: { query: ME },
      result: {
        data: {
          me: { email }
        }
      }
    },
    {
      request: {
        query: ADD_PIN,
        variables: {
          pin: {
            title,
            link,
            image
          }
        }
      },
      result: {
        data: {
          addPin: {
            title,
            link,
            image
          }
        }
      }
    }
  ];
  const initialEntries = [`/verify?token=${token}`];
  const wrapper = mount(
    <MemoryRouter initialEntries={initialEntries}>
      <MockedSubscriptionsProvider mocks={mocks}>
        <App />
      </MockedSubscriptionsProvider>
    </MemoryRouter>
  );
  await wait();
  wrapper.update();
  await wait(1000);
  wrapper.update();
  wrapper
    .find('a[href="/upload-pin"]')
    .first()
    .simulate("click", { button: 0 });
  wrapper.update();
  wrapper
    .find('[placeholder="Title"]')
    .first()
    .prop("onChange")({ target: { value: title } });
  wrapper
    .find('[placeholder="URL"]')
    .first()
    .prop("onChange")({ target: { value: link } });
  wrapper
    .find('[placeholder="Image URL"]')
    .first()
    .prop("onChange")({ target: { value: image } });
  wrapper.update();
  wrapper.find("form").prop("onSubmit")({ preventDefault: () => {} });
  const subscriptionsLink = wrapper.find(MockedSubscriptionsProvider).instance()
    .subscriptionsLink;
  subscriptionsLink.simulateResult({
    result: {
      data: {
        pinAdded: {
          title,
          link,
          image,
          id: "1"
        }
      }
    }
  });
  await wait(1000);
  wrapper.update();
  expect(wrapper.find(".pins .pin").length).toBe(1);
  wrapper.unmount();
});
```

Testing subscriptions is very straightforward once you can simulate results using `MockSubscriptionLink`.

## 6.9 Summary

In this chapter you learned how to test GraphQL APIs and React Apollo clients.

You used two different strategies to write API tests, once that tests the GraphQL layer and another that tests the HTTP layer. To write expectations, you used Jest snapshots in some cases and manual expectations in other occasions.

You tested queries and mutations in React Apollo clients using `MockedProvider`. You also learned how to test subscriptions by using `MockSubscriptionLink` to simulate server sent events.

Now you are ready to apply this techniques to verify the correct behavior of your GraphQL Applications.
