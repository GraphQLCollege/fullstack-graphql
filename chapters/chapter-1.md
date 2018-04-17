---
online: true
---
## Web development workflow

In this chapter you will learn about the development workflow of a full stack Node and React GraphQL app. You will learn how to develop an app from scratch, from requirements to deployment. Even though we will create a simple application, the process for creating a larger app is exactly the same. You will use this exact workflow to develop a large, production scale application throughout the book.

Broadly speaking, this is how the workflow looks like:

* Write requirements
* Create tests
* Satisfy requirement by adding code on the server and/or client
* Deploy changes

Another goal of this chapter, besides presenting a development workflow, is showing how to develop and deploy a GraphQL client which communicates with a Node GraphQL server.

We will develop a React client which uses `fetch` to ask the serve for information, showing that you might not need a GraphQL framework for simple use cases. GraphQL is just a query language that you can send over HTTP.

You will implement the GraphQL server with Express and Apollo Server. It will have a simple schema which defines the resources it exposes to its clients.

The client will be deployed to Netlify and the server to Heroku. Both services are production grade hosts which make it really easy to get started using them.

Let's start by defining our development machine requirements.

### System prerequisites

Actually NodeJS is the only requirement you need in order to install everything in this tutorial. I wrote all steps in this guide in a machine with NodeJS v8.9.4, so I'd recommend installing that version to follow along. You might want to install Node using a utility called [nvm](https://github.com/creationix/nvm), which is short for Node Version Manager. Using nvm you will be able to have multiple versions of Node on the same machine.

### Requirements

Writing requirements is one of the activities I enjoy the most in software development. It may seem boring at first, well it may also seem boring at last, but I like it because writing requirements forces me to really understand the problem. It also marks a finishing line, a goal. Knowing where to go feels essential to me, it keeps me focused.

You can write requirements in any way you want. It's just words after all. Personally, I like to write requirements in a loose version of [gherkin](https://github.com/cucumber/cucumber/wiki/Gherkin). Gherkin is a language for specifying software's behaviour. It servers two purposes, documentation and automated tests. I use it only because it's a great way of specifying software requirements, so I skip the automated testing part.

As you will see in the next requirement definition, this language reads like English and has very little structure.

```gherkin
Feature: Greet the world
  In order to follow the long standing tradition of programming languages first examples
  As a GraphQL student
  I want to write an app that says "Hello world"

  Scenario: Show greeting
    Given some precondition
    When the user opens the app
    Then he should see "Hello world"
```

Here is a breakdown of the requirements for our hello world app.

* The first line specifies the name of the feature. It needs to be written as `Feature: <name>`
* You can optionally provide more context by placing indented lines below the `Feature` line
* Afterwards you write about the different scenarios in which the user interacts with your system. Every scenario must start with the keyword `Scenario`
* You write scenarios using the `given`-`when`-`then` structure
  * Given puts the system in a known state
  * When describes the action that the user performs
  * Then shows outcomes

Don't worry if you don't get all aspects of writing requirements this way. You'll see that it's an intuitive way of talking about how users interact with our system. You'll learn by watching examples and writing your own requirements. Reach out for [Gherkin documentation](https://github.com/cucumber/cucumber/wiki/Gherkin) if you need to read more.

Now that we have described what we are going to build, it's time to define our file structure.

### File structure

The project we will create will be structured as a monorepo. This means that all files will be stored in a single git repository. The opposite of this approach would be creating a git repository for the client and another for the server.

The reason we choose to work in a monorepo is because we will create new versions of our project based on requirements, not on technologies. We will work by features, which means that a single commit represents a new working version of the app. It does not matter if the changes that lead to a feature were client side, server side or both.

Our project will have three main folders. These folders are client, server, and cypress. Client will hold a react app created via `create-react-app`. Server will hold the files that make up a NodeJS server. Cypress will contain integration tests.

This is what our top level file structure will look like:

```
.
|-- client
|   |-- README.md     # Create React App's default README
|   |-- build         # Compiled client code
|   |-- netlify.toml  # Netlify configuration
|   |-- node_modules  # Client dependencies
|   |-- package.json  # List of client dependencies
|   |-- public        # Static assets like index.html and images
|   |-- src           # Client source code
|   `-- yarn.lock     # Client dependencies version list
|-- cypress
|   |-- fixtures      # Mock data
|   |-- integration   # Integration tests
|   |-- plugins       # Cypress plugins
|   |-- support       # Customize Cypress
|   `-- videos        # Cypress videos
|-- cypress.json      # Cypress configuration
|-- package.json      # Top level dependencies
`-- server
    |-- Procfile      # Heroku configuration
    |-- index.js      # Server source code
    |-- node_modules  # Server dependencies
    |-- package.json  # List of server dependencies
    `-- yarn.lock     # Server dependencies version list
```

Now that we know a bit more about file organisation, let's get started with the project.

### Getting started

We are going to use [yarn](https://yarnpkg.com/lang/en/) package manager to install our npm dependencies because it is faster than npm. Feel free to use [npm](https://docs.npmjs.com/cli/npm) if you wish. Both work great for installing js stuff.

```bash
npm install -g yarn   # Install yarn package globally
```

We will now create our root folder called `hello-graphql` and use yarn to create a file called `package.json`.

```bash
cd ~                  # Go to root folder
mkdir hello-graphql   # Create directory called hello-world
cd hello-graphql      # Go to hello-world directory
yarn init -y          # Create package.json. Answer yes to all questions
```

The next step will be creating our first integration test using a tool called Cypress.

### Testing

Testing is a huge topic. We could spend days discussing testing strategies. Is it better to write tests before code or after code?. Do we want to achieve 100% test coverage? Should we write unit tests? Integration tests? Both? The list of questions can grow forever. At the end of the day, the answer is the same as with all programming choices. It depends.

We will write mostly system tests. These tests verify that our system works based on the system's feature list. Because we are writing a product for end users, we want to verify that what we offer to end users works fine. If we were developing a library we would rely more on integration and/or unit tests, but this is not the case. We use tests to verify that our system works in the eyes of our users. Well engineered apps like [Basecamp](https://basecamp.com/) [use this strategy](https://twitter.com/dhh/status/796782788263321600?lang=en), so it's good enough for us.

The tool of choice for writing end to end tests will be [Cypress](https://www.cypress.io/). Cypress is a fast, open source testing tool. As you will see, it has a great development experience.

We will install as a global command line interface using yarn. Note that you can also install it locally as a dev dependency. That way you will have an explicit, versioned dependency on cypress in your project. In this case we will install it as a global utility.

```bash
yarn global add cypress # Install cypress package globally.
```

> Installing Cypress could take a while, depending on your internet connection.

Once Cypress it's installed, we will call `cypress open` to generate all the files it requires. It will also open a project dashboard, which you can use to do cool things like see your test suite run in real time or time travel thorugh your tests.

```bash
cypress open &
sleep 20        # Wait for cypress to create all files
```

Cypress created an example spec in the `cypress/integration` folder. Replace its contents with a single test. This test will enter the local url of our app and verify that it prints "Hello world" to the screen.

```js {cypress/integration/example_spec.js}
describe("App", () => {
  it("Should greet the world", () => {
    cy.visit("http://localhost:3000");
    cy.contains("Hello world");
  });
});
```

Running this test using `cypress run` will end up with Cypress complaining that this test is failing. Let's fix that in the next step by building our Hello world client.

### Client

To satisfy our single requirement, we are going to build an application that displays "Hello world". We are going to use a library called [React](https://reactjs.org/) to create this application.

React lets us create applications by composing components. A React component is a combination of markup, style and logic. They manage their own internal data, also called state. They can also receive external data, also called properties.

[Create React App](https://github.com/facebook/create-react-app/) is a handy tool for creating React applications. It generates a directory with everything setup so that you can start creating components right away, without touching any configuration.

Install the global command line interface with `yarn`. Then use it to create a folder called `client`.

```bash
yarn global add create-react-app
create-react-app client
cd client
```

We are going to start our client server as a background process now, so we can access it on `http://localhost:3000`. The project generated with `create-react-app` will add a `start` command to `package.json` scripts, which allows you to call `yarn start`. It will start a server which will update itself after code changes. Internally it calls `react-scripts start`. In order to start this server as a background process, we are going to use [pm2](https://github.com/Unitech/pm2) to start a node process with `react-scripts`' `start` script.

Install pm2 using yarn. Then run `pm2 start` to serve our client folder on `http://localhost:3000`.

```bash
# Install pm2 so we can start app on background
# https://github.com/facebook/create-react-app/issues/1089#issuecomment-294428373
yarn global add pm2
# Start the app
pm2 start node_modules/react-scripts/scripts/start.js --name hello-graphql
```

Now that we have our client running, modify `src/App.js` to show "Hello world".

```js {src/App.js}
import React, { Component } from "react";

class Greet extends Component {
  render() {
    return <div>Hello {this.props.to}</div>;
  }
}

export default class App extends Component {
  render() {
    return <Greet to="world" />;
  }
}
```

We created a component called `Greet`. It receives a `prop` called `to`, and renders `Hello {this.props.to}`. This means that `Greet` component can be configured to say hi to any kind of person (or planet), we just need to pass that greeting receiver in the `to` property.

Finally, we use the component we just created by returning `<Greet to="world" />` in the render method of the main `App` component.

Now we can run our integration test using `cypress run`, and all tests should pass.

```bash
cd ..
cypress run
```

Green test suites are always satisfying! Let's commit our changes using git with the new version of our app.

### Version control

We are going to use git for version control. Let's configure our repository with `git init`, stash all of our changes with `git add .`, and finally save those changes with `git commit`.

```bash
git init
git add .
git commit -m "Create hello world client"
```

Now that we have sealed our changes with a commit, the next step is deploying our application.

### Client deployment

Deploying early and often fosters healthy software. Pushing code to production as early as possible sets the stage for frequent software updates. Releasing often means you can add features and squash bugs at a faster pace.

In this stage we are going to generate a production ready bundle of our app and deploy it to [Netlify](https://netlify.com). In order to do that we need to install the Netlify CLI:

```
# Install Netlify CLI
cd /usr/bin
curl -L https://github.com/netlify/netlifyctl/releases/download/v0.3.3/netlifyctl-linux-amd64-0.3.3.tar.gz | tar xz
```

TODO: Show how to configure $NETLIFY_ACCESS_TOKEN

Now that we have a way to deploy to production, let's go to our client folder and generate a static bundle of our application. Running `yarn build` generates a `build` directory which contains all the html, css and js that our application needs to run. 

```bash
cd ~/hello-graphql/client
yarn build
```

The last step is sending our `build` directory to Netlify, which will assign a unique url to our application.

```bash
echo "yes" |netlifyctl deploy -b build -A $NETLIFY_ACCESS_TOKEN
```

Now everyone with an internet connection can access our hello world service. The next task we need to tackle is creating a GraphQL server which will offer a way to query for planets, so our client can stop being responsible for determining who to say hello to.

### Server

We are going to build a tiny GraphQL server. GraphQL is short for Graph Query Language, which is a very descriptive name. It is a **language** tailor made for **query**ing a **Graph**. It lets us design data using graphs, and it also gives us a way to query that information.

Don't worry if the word Graph scares you a bit, you don't need to have a Masters in Computer Science or anything in order to understand GraphQL. If you've ever used json, you'll feel right at home with GraphQL. You can imagine a GraphQL query as a json object with no values, only keys.

Let's say you want to design a GraphQL representation of the planets of the solar system. You might have the following json structure representing all planets:


```json
{
  "planets: [
    { "name": "Mercury" },
    { "name": "Venus" },
    { "name": "Earth" },
    { "name": "Mars" },
    { "name": "Jupiter" },
    { "name": "Saturn" },
    { "name": "Uranus" },
    { "name": "Neptune" },
    { "name": "Pluto" },
  ]
}
```

If you wanted to query an API and receive the previous list of planets, you would write a query like this one:

```graphql
{
  planets {
    name
  }
}
```

Notice that the shape of our query matches the keys of json structure we received.

```bash
mkdir ../server
cd ../server
yarn init -y
```

```bash
yarn add express body-parser apollo-server-express graphql-tools graphql cors
```

```js {index.js}
const express = require("express");
const bodyParser = require("body-parser");
const { graphqlExpress, graphiqlExpress } = require("apollo-server-express");
const { makeExecutableSchema } = require("graphql-tools");
const cors = require("cors");

const PORT = process.env.PORT || 3001;
const HOST = process.env.HOST || "localhost";

const typeDefs = `
  type Query { planet: String }
`;

const resolvers = {
  Query: {
    planet: () => {
      return "world";
    }
  }
};

const schema = makeExecutableSchema({
  typeDefs,
  resolvers
});
const server = express();

server.use(cors());

server.use("/graphql", bodyParser.json(), graphqlExpress({ schema }));

server.use(
  "/graphiql",
  graphiqlExpress({
    endpointURL: "/graphql",
    subscriptionsEndpoint: `ws://${HOST}:${PORT}/subscriptions`
  })
);

server.listen(PORT, () => {
  console.log(`Go to http://${HOST}:${PORT}/graphiql to run queries!`);
});
```

```bash
pm2 start index.js --watch --name hello-graphql-api
```

Test it in GraphiQL

```
http://localhost:3001/graphiql?query=%7B%0A%20%20planet%20%0A%7D
```

```{.gitignore}
node_modules
```

```bash
git add .
git commit -m 'Create hello world server'
```

### Communicate client with server

```bash
cd ../client
```

```bash
yarn add unfetch
```

```js {src/App.js}
import React, { Component } from "react";
import fetch from "unfetch";

class Greet extends Component {
  render() {
    return <div>Hello {this.props.to}</div>;
  }
}

export default class App extends Component {
  state = { to: "" };
  componentDidMount() {
    fetch("http://localhost:3001/graphql", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query: "{ planet }" })
    })
      .then(res => res.json())
      .then(res => this.setState({ to: res.data.planet }));
  }
  render() {
    return <Greet to={this.state.to} />;
  }
}
```

```bash
cd ..
cypress run
```

```bash
git add .
git commit -m 'Communicate client with server'
```

### Deploy server

```bash
yarn global add heroku-cli
```

```
heroku login
```

```
heroku auth:token
```

```
export HEROKU_EMAIL=email@example.com
export HEROKU_TOKEN=token_generated_with_previous_command
```

```bash
cat >~/.netrc <<EOF
machine api.heroku.com
  login $HEROKU_EMAIL
  password $HEROKU_TOKEN
machine git.heroku.com
  login $HEROKU_EMAIL
  password $HEROKU_TOKEN
EOF
```

```bash
heroku create
cd server
```

Configure heroku to deploy server directory https://elements.heroku.com/buildpacks/pagedraw/heroku-buildpack-select-subdir

```{Procfile}
web: cd server && node index.js
```

```bash
git add .
git commit -m 'Configure Procfile'
```

```bash
export API_NAME=$(heroku apps:info |head -1 |cut -d' ' -f2)
heroku buildpacks:set -a $API_NAME https://github.com/Pagedraw/heroku-buildpack-select-subdir
heroku config:add BUILDPACK='server=https://github.com/heroku/heroku-buildpack-nodejs#v83' -a $API_NAME
git push heroku master
```

### Communicate client with server in production

```bash
cd ../client
```

```bash
cat > .env.development.local << EOF
REACT_APP_API_URI=http://localhost:3001/graphql
EOF
```

```bash
cat > .env << EOF
REACT_APP_API_URI=https://$API_NAME.herokuapp.com/graphql
EOF
```

```js {src/App.js}
import React, { Component } from "react";
import fetch from "unfetch";

class Greet extends Component {
  render() {
    return <div>Hello {this.props.to}</div>;
  }
}

export default class App extends Component {
  state = { to: "" };
  componentDidMount() {
    fetch(process.env.REACT_APP_API_URI, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query: "{ planet }" })
    })
      .then(res => res.json())
      .then(res => this.setState({ to: res.data.planet }));
  }
  render() {
    return <Greet to={this.state.to} />;
  }
}
```

```bash
pm2 restart hello-graphql
```

```bash
git add .
git commit -m "Communicate client with server in production"
yarn build
netlifyctl deploy -b build -A $NETLIFY_ACCESS_TOKEN
```

### Conclusion
