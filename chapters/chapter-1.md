---
online: true
---
## Introduction to GraphQL

GraphQL allows you to architect HTTP APIs. It plays the same role as [REST](https://en.wikipedia.org/wiki/Representational_state_transfer). Even though you can use GraphQL for any use task where you can use REST, this technology shines in mobile apps, application dashboards and public APIs. Another selling point of GraphQL is that it provides a way to push content from servers to clients in real time. Don't worry if all these benefits sound like too much work, you don't have to throw away your APIs and start from scratch because GraphQL provides a gradual adoption path.

### Comparing GraphQL to REST

GraphQL shares many things with REST. It is also an HTTP specification. It also provides a way to design resources. It allows developers to map resources to backend functions. It provides a way to access those resources from clients.

GraphQL is an HTTP specification. This means that it provides several guidelines which can be used to create HTTP servers and clients in any language. Currently there are GraphQL servers written in [Javascript](https://www.apollographql.com/server), [Ruby](http://graphql-ruby.org/), [Elixir](https://absinthe-graphql.org/) and more. There are also many GraphQL clients and frameworks, the most populars being [Apollo client](https://www.apollographql.com/client) and [Relay](https://facebook.github.io/relay/), but there are many more.

It provides a way to design resources. Just like you would represent a dog in your REST API as a `/dogs` resource, you would represent a dog as a `Dog` type in GraphQL. GraphQL provides a way to represent resource properties, just like you do in REST HTTP payloads. Every GraphQL type has fields which represent their properties.

HTTP

```
/dogs/:id
{ "id": 1, "name": "Scooby Doo" }
```

GraphQL

```graphql
type Dog {
  id: ID,
  name: String
}
type Query {
  dog(id: ID!): Dog
}
```

Developers can expose resources by mapping them to backend functions. In REST you define functions that handle the different routes in your API. GraphQL also allows you to define a function for each field in your types.

REST

```js
server.get("/dogs/:id", (req, res) => {
  res.send({
    "id": 1,
    "name": "Scooby Doo"
  });
})
```

GraphQL

```js
const resolvers = {
  Query: {
    dog: () => {
      return {
        "id": 1,
        "name": "Scooby Doo"
      }
    }
  }
};
```

GraphQL provides HTTP clients a way to access resources. REST APIs offer routes which clients can use to access the resources they need. In contrast, GraphQL APIs offer a query language which clients can use to access the types they need. Because of this query language, GraphQL APIs present a single route to clients. Offering resources in a single HTTP route means that clients can ask for multiple types in a single HTTP request. Compared to REST APIs, GraphQL APIs are much more network efficient.

HTTP

```js
const dog = await fetch("/dogs/1", {}).then(res => res.json())
console.log(dog)
// { "id": 1, "name": "Scooby Doo" }
```

GraphQL

```js
const dog = await fetch(
  "/graphql", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query: "{ dog(id: 1) { id, name } }" })
  }).then(res => res.json())
console.log(dog);
// { "id": 1, "name": "Scooby Doo" }
```

REST APIs usually provide fixed HTTP payloads, whereas in GraphQL clients can request only the fields they need. This results in smaller HTTP payloads. We will talk more about GraphQL type system in the next chapter, "Schemas and Types".

```js
const dog = await fetch(
  "/graphql", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query: "{ dog(id: 1) { name } }" })
  }).then(res => res.json())
console.log(dog);
// { "name": "Scooby Doo" }
```

Network efficiency is one of the big selling points of GraphQL. GraphQL clients make fewer network requests than REST clients. They also get smaller HTTP payloads than their REST equivalents. This is a universal benefit. In the next section, we'll analyze specific use cases that showcase GraphQL advantages over REST APIs.

### Ideal use cases

GraphQL is a pleasure for developing any kind of frontend or backend, but it truly shines in certain cases.

Its network efficiency, both in number of requests and request payload size, make it great for developing mobile apps. In fact, [Facebook engineers created GraphQL](https://code.facebook.com/posts/1691455094417024/graphql-a-data-query-language/) because they needed a powerful and simple way to develop APIs. Mobile clients have constrained resources compared to desktop clients, and network is one of the scarcest resources in mobile phones.

GraphQL allows developers to create efficient, maintainable dashboards. App dashboards have many definitions. In this case we are talking about pages that show a quick glance of several items of interest to the app user. REST clients end up hitting several different endpoints to gather the information they need. This usually ends up in two different scenarios, overfetching or custom endpoints.

One outcome is that the client overfetches information by hitting the different resources endpoints, but only uses a subset of that data. Another possible scenario is that the backend creates a special route which contains the exact information that the client needs, which solves the overfetching on the client but has maintainability issues. GraphQL solves the dashboard overfetching problem by empowering clients to request only the data that they need. Not more, not less. This is achieved using a single GraphQL endpoint.

GraphQL type system allows much better tooling, which is especially beneficial to Public API developers who get API documentation for free. Let's face it, writing documentation for REST APIs has always been difficult. This is why solutions like [Swagger](https://swagger.io/) or [Open API](https://www.openapis.org/) exist.

The problem with REST API documentation solutions is that they are optional, non standard ways of documenting APIs. In contrast, all GraphQL APIs will have a well defined type system, which means that all GraphQL APIs can be documented and explored by many tools. [GraphiQL](https://github.com/graphql/graphiql) is an in browser IDE that provides syntax highlighting, autocompletion and schema browsing.

### Real time

Another big selling point of teh GraphQL specification are GraphQL Subscriptions. Subscriptions provide a way to push data from servers to clients in real time. We'll go deeper into how to implement Subscriptions both on frontends and on backends in the Subscriptions chapter.

### Gradual adoption

Adopting GraphQL and Apollo client brings several benefits. Some of them are: smaller HTTP payloads, less network requests, zero config API documentation and declarative data fetching. Less network usage will benefit your users, and your developers will be more productive with better tooling and clear boundaries between frontend and backend.

But changing your entire stack is a tremendous effort. Fortunately you can gradually adopt GraphQL. [This guide](http://www.graphql.college/gradually-migrating-a-node-and-react-app-from-rest-to-graphql/) will show you how to go from a REST and React stack to a stack with GraphQL and Apollo client.

### Conclusion

To summarize, GraphQL allows you to create well documented, network efficient, real-time HTTP APIs. In this book you will create an HTTP client and server from scratch using NodeJS, React and GraphQL.

You will create a Pinterest clone called PinApp step-by-step. It will allow users to create pins, list them in real time, register, login, logout and show info in a dashboard. Every step will have a live, editable version so you can focus on learning.