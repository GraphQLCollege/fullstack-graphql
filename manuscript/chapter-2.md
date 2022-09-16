# 2. Data modeling

[https://www.graphqladmin.com/books/fullstack-graphql/02-data-modeling](https://www.graphqladmin.com/books/fullstack-graphql/02-data-modeling)

In the previous chapter you learned how to read and write data by sending queries against a schema using the GraphQL query language. In this chapter you will learn how to model the data behind the queries using schemas and types. To create this schema you will use the GraphQL Schema Definition Language (also called SDL, not to be confused with LSD).

Whereas the previous chapter focused on how clients interact with servers using GraphQL, this chapter will tackle how to expose a data model that clients can consume.

Remember the Pinterest clone we talked about in the introduction? After learning the concepts behind GraphQL schemas and types, you will design its data model at the end of this chapter.

## 2.1 Schema, types and resolvers

GraphQL servers expose their schema in order to let clients know which queries and mutations are available. To define what a schema looks like, you need to define the types of all fields. To define how a schema behaves, you need to define a function that the server will run when a client asks for a field, this function is called resolver. A schema needs both type definitions and resolvers.

![Types and resolvers](images/types-resolvers.png)

Because GraphQL is a specification implemented in many languages, it provides its own language to design schemas, called SDL. You write type definitions in SDL, but you can create resolvers in any language that implements the GraphQL specification. This book focuses on the Javascript GraphQL ecosystem, so you will write all resolvers in this language.

The schema you will create is more than just an example that illustrates how to write SDL. It is the initial step of building PinApp, the sample application of this book. It allows most of the features in the final app:

- Login with magic links
- Allow authenticated users to add pins
- Search pins and users
- List pins

Make your own copy of this example with the following button:

[Remix schema example](https://glitch.com/edit/#!/remix/pinapp-schema)

> After remixing, closely follow the instructions in `README.md`. This project's README instructs you to configure environment variables in `.env`.

Note that this schema is not exposed over HTTP. It is accessible with scripts using `graphql-js`. The next chapter will show you how to add an HTTP layer to this schema, using Apollo Server.

In the next section you will understand how to create schemas using a function called `makeExecutableSchema`.

## 2.2 Schemas

You create schemas by combining type definitions and resolvers. There is a handy package called [`graphql-tools`](https://github.com/apollographql/graphql-tools) that provides a function called `makeExecutableSchema`. The previous chapter contained a lot of `graphql(query, schema)` calls. All of those examples sent queries agains a schema generated with `makeExecutableSchema`.

Open the file called `schema.js` in the example project you just remixed to see how you can create a schema.

```js
const { makeExecutableSchema } = require("graphql-tools");
const { importSchema } = require("graphql-import");

const typeDefs = importSchema("schema.graphql");
const resolvers = require("./resolvers");

const schema = makeExecutableSchema({
  typeDefs,
  resolvers,
});

module.exports = schema;
```

As you can see, this file created a schema with types from `schema.graphql` and resolvers from `resolvers.js`. The next two sections will teach you how to create these type definitions and resolvers.

## 2.3 Type definitions

In this section you will learn how to write GraphQL types using SDL. A type is just a representation of an object in your schema. Objects, as in many other programming languages, can have many fields.

> You can find all examples in this section in `schema.graphql`

This is how you define an object type:

```graphql
type Pin {
  title: String!
  link: String!
  image: String!
  id: String!
  user_id: String!
}
```

As you can see, you can define the type of fields after the field name. In the case of `Pin`, all of its fields are of type `String`, and are required because they end with an exclamation mark (!).

GraphQL defines two special object types, `Query` and `Mutation`. They are special because they define the entry points of a schema. Being the entry point of a schema means that GraphQL clients must start their queries with one or more of the fields from `Query`.

```graphql
type Query {
  pins: [Pin]
  pinById(id: String!): Pin
  users: [User]
  me: User
  search(text: String): [SearchResult]
}
```

As you may have noticed, object types can have arguments. Every field has an underlying function (called resolver) that runs before returning its value, so it makes sense to think of field arguments the same way we think of function arguments.

Another new element in the previous `Query` is the List type modifier. You can wrap fields in square brackets to specify them as lists.

The GraphQL specification determines that all schemas must have a `Query` type, and they can optionally have a `Mutation` type. This is how PinApp's `Mutation` type looks like:

```graphql
type Mutation {
  addPin(pin: PinInput!): Pin
  sendShortLivedToken(email: String!): Boolean
  createLongLivedToken(token: String!): String
}
```

Notice that `addPin` has a `pin` argument of type `PinInput`, and the other two fields have arguments of `String` type. You can't pass arguments of type `Object` as arguments, you can only pass scalar types or `Input` types.

Scalar types can't have nested fields, they represent the leaves of a schema. These are the built-in scalar types in GraphQL:

- `Int`
- `Float`
- `String`
- `Boolean`
- `ID`

Some GraphQL implementations allow you to define custom scalar types. This means that you could create custom scalars such as `Date` or `JSON`.

You can define a special kind of scalars using `enum` types. Enumerations are special scalars because they are restricted to a fixed set of values.

This is how an enum looks like:

```graphql
enum PinStatus {
  DELETED
  HIDDEN
  VISIBLE
}
```

Input types behave almost exactly like objects. They can have fields inside of them, but the difference is that those fields cannot have arguments and also cannot be of `Object` type.

This is how the custom `PinInput` type is defined:

```graphql
input PinInput {
  title: String!
  link: String!
  image: String!
}
```

GraphQL allows you to define `Interface` and `Union` types. They are useful when you want to return an object which can be of several different types.

You can use interfaces when you have different types which share fields between them. A common use case would be representing a `User` type.

```graphql
interface Person {
  id: String!
  email: String!
  pins: [Pin]
}

type User implements Person {
  id: String!
  email: String!
  pins: [Pin]
}

type Admin implements Person {
  id: String!
  email: String!
  pins: [Pin]
}
```

When you want to create a type that represents different types with no shared fields between them, you must use a `Union` type. A typical operation that returns this type is a search:

```graphql
union SearchResult = User | Admin | Pin

type Query {
  # ...
  search(text: String): [SearchResult]
}
```

This is what the complete version of `schema.graphql` looks like:

```graphql
type Pin {
  title: String!
  link: String!
  image: String!
  id: String!
  user_id: String!
}

input PinInput {
  title: String!
  link: String!
  image: String!
}

interface Person {
  id: String!
  email: String!
  pins: [Pin]
}

type User implements Person {
  id: String!
  email: String!
  pins: [Pin]
}

type Admin implements Person {
  id: String!
  email: String!
  pins: [Pin]
}

union SearchResult = User | Admin | Pin

type Query {
  pins: [Pin]
  pinById(id: String!): Pin
  users: [User]
  me: User
  search(text: String): [SearchResult]
}

type Mutation {
  addPin(pin: PinInput!): Pin
  sendShortLivedToken(email: String!): Boolean
  createLongLivedToken(token: String!): String
}
```

As you learned in the previous section, a schema is comprised of type definitions and resolvers. Now that you know how type definitions look like, it's time to learn about resolvers.

## 2.4 Resolvers

Resolvers are the functions that run every time a query requests a field. When a GraphQL implementation receives a query, it runs the resolver for each field. If the resolver returns an `Object` field, then GraphQL runs that field's resolver function. When all resolvers return scalars, the chain ends and the query receives its final JSON result.

Since GraphQL is not tied to any database technology, it leaves resolver implementation entirely up to you. All functions in `resolvers.js` use a simple JS object that serves as a memory database, but in the next chapter you will learn how to migrate to a Postgres database.

You can organize resolvers in any way you want, depending on your needs. The examples in this book strive to keep resolver functions simple, and also separating database access with business logic. This is a simple case of applying the good old [Separation of Concerns](https://en.wikipedia.org/wiki/Separation_of_concerns) pattern.

This is what `resolvers.js` looks like:

```js
const {
  addPin,
  createShortLivedToken,
  sendShortLivedToken,
  createLongLivedToken,
  createUser,
} = require("./business-logic");

const database = {
  users: {},
  pins: {},
};

const resolvers = {
  Query: {
    pins: () => Object.values(database.pins),
    users: () => Object.values(database.users),
    search: (_, { text }) => {
      return [
        ...Object.values(database.pins).filter((pin) =>
          pin.title.includes(text)
        ),
        ...Object.values(database.users).filter((user) =>
          user.email.includes(text)
        ),
      ];
    },
  },
  Mutation: {
    addPin: async (_, { pin }, { user }) => {
      const { user: updatedUser, pin: createdPin } = await addPin(user, pin);
      database.pins[createdPin.id] = createdPin;
      database.users[user.id] = updatedUser;
      return createdPin;
    },
    sendShortLivedToken: (_, { email }) => {
      let user;
      const userExists = Object.values(database.users).find(
        (u) => u.email === user.email
      );
      if (userExists) {
        user = userExists;
      } else {
        user = createUser(email);
        database.users[user.id] = user;
      }
      const token = createShortLivedToken(user);
      return sendShortLivedToken(email, token);
    },
    createLongLivedToken: (_, { token }) => {
      return createLongLivedToken(token);
    },
  },
  Person: {
    __resolveType: (person) => {
      if (person.admin) {
        return "Admin";
      }
      return "User";
    },
  },
  User: {
    pins({ id }) {
      return Object.values(database.pins).filter((pin) => pin.user_id === id);
    },
  },
  SearchResult: {
    __resolveType: (searchResult) => {
      if (searchResult.admin) {
        return "Admin";
      }
      if (searchResult.email) {
        return "User";
      }
      return "Pin";
    },
  },
};

module.exports = resolvers;
```

In this case, not all fields of `Query` and `Mutation` have a corresponding resolver. When a field does not have a resolver, it will resolve as `null`. Of course this is just for demonstration purposes. Your API clients would not be very happy with queries that always return null.

You can see that most of the logic in the fields of `Query` and `Mutations` come from the functions in `business-logic.js`. The function bodies are mostly data access and calls to methods from the business logic module.

Some of the types in `resolvers.js` have methods named `__resolveType`. This is a method that `makeExecutableSchema` from `graphql-tools` uses. It determines the type of objects which are of type `Union` or `Interface`.

You can try this example schema by opening your remixed example's console and run `node queries.js`. This script simulates a user who first creates an authentication token, and sends it in order to add a new pin.

```bash
$ node queries
API Token:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
{
  "data": {
    "addPin": {
      "id": "f5220ee1-bfeb-48a0-be9f-c63d055b8139",
      "title": "Hello world",
      "link": "http://graphql.college/fullstack-graphql",
      "image": "http://graphql.college/fullstack-graphql",
      "user_id": "75c16079-b3ef-43f0-a352-ae03f2488baa"
    }
  }
}
```

Feel free to learn by modifying the different resolver functions and seeing how that changes the final result. You can also create different queries, now that you know what queries and mutations your schema exposes.

## 2.5 Summary

You learned how to create GraphQL schemas. You wrote type definitions using SDL, and resolvers using Javascript. The schema you created in this chapter is accessible by scripts using `graphql-js`.

The next chapter will teach you how to create GraphQL HTTP APIs. You will add the different layers that make up a GraphQL server on top of the GraphQL schema from this chapter. This API will have several additional layers, like HTTP, database and authentication.
