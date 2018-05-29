![Cover](../images/cover.png)

# GraphQL Webapps

## PREFACE

GraphQL is revolutionizing client-server communication. It is a technology that enables better documented APIs, easier data management in HTTP clients, and optimized network usage.

One of the main benefits of GraphQL is that improves communication between APIs and API consumers. Facilitates team communication by providing an easy way for frontend developers to know all methods that the API exposes. It also enables better communication with 3rd party API consumers because GraphQL services have zero configuration API documentation.

It empowers clients by giving them complete data fetching control. GraphQL lets clients ask for the exact data that they need. Not more, not less. It also lets clients ask for nested resources in the same operation, avoiding the need for REST-style cascading requests. REST tends to push complexity to API clients.

Another benefit of GraphQL is that it optimizes network usage by reducing HTTP payloads and number of requests. Reducing data and requests directly maps to a better experience for mobile users.

### So, what is GraphQL?

GraphQL is a domain specific typed language to design and query data.

A domain specific language, or DSL, is a language built for a single application domain. They are the opposite of general purpose languages like Javascript, Ruby, Python or C, which are applicable across different domains. There are many popular DSLs in use nowadays, CSS is a DSL for styling and HTML is a DSL for markup. GraphQL is a DSL for data.

It is a typed language. This means that it uses types to define resources, it adds types to each resource's fields. It also uses types to statically check for errors. Being a typed language is the source of many of GraphQL's biggest assets, like enabling automatic API introspection and documentation.

GraphQL's domain is data. It can be used to design a schema that represents data and also to ask for specific fields on data.

Developing API servers and clients is the main use case of GraphQL. Backend developers can use GraphQL to model their data, while frontend developers can use GraphQL to write queries to retrieve specific bits of data.

Even though services generally expose GraphQL through their HTTP layer, GraphQL is not tied to HTTP or any other communication protocol.

GraphQL is a specification. This means that it specifies how it should work, allowing anyone to implement GraphQL in any programming language. There is an official implementation in Javascript called `graphql-js`, but there are also many other incarnations in other programming languages like Ruby, Elixir and more.

### Organization of the book

With this book you will learn how to develop a complete GraphQL client-server application from scratch. You will learn how to fetch data from the client, how to design that data in the server, how to develop NodeJS GraphQL servers and finally how to create React GraphQL clients.

The first two chapters will teach you how to fetch data using GraphQL. The first chapter will teach you how to create data. The second chapter will teach you how to design schemas. You will learn these pure GraphQL concepts, without the need of thinking about HTTP servers or clients. GraphQL is an abstraction that allows you to think about data without worrying about transport. You will build a schema, queries and mutations using Javascript and a couple of GraphQL libraries.

The rest of the chapters will focus on building GraphQL servers and clients.

The third chapter, GraphQL APIs, will teach you how build GraphQL HTTP servers using NodeJS and Apollo server. You will learn how to expose a GraphQL schema over HTTP, how to connect to a database, how to handle authentication and authorization and how to organize your files.

In the fourth chapter, GraphQL Clients, you will learn how to write GraphQL clients using React and Apollo client. You will learn how to ask for and create data using Apollo's `Query` and `Mutation` components, and also how to handle authentication.

The fifth chapter will teach you how to add real time functionality to your GraphQL applications using Subscriptions. Subscriptions provide GraphQL APIs the ability to push data to the clients.

You will learn how to test GraphQL APIs and clients in the sixth chapter.

### Sample application

Through the course of this book you will learn how to build a Pinterest clone called Pinapp using GraphQL, NodeJS, React and Apollo client.

Pinapp should allow users to:

* Login with magic links
* Logout
* Add pins (a pin is an image that links to a URL)
* Search pins and users
* List pins
* See new pins without refreshing browser

You will build this application in layers. First you will design the data layer, then write the business logic, after that create HTTP transport layer, then connect everything to the database layer and finally build the HTTP client.

### Development environment

There are no environment requirements to try the examples in this book, other than having a web browser and internet connection. Every step of the application has a live, editable online version hosted at glitch.com. Glitch is an awesome community to build apps created by the folks that developed Stack Overflow and Trello.

## Table of Contents

