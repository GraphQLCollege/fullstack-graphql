## 6. Testing

### 6.1 API testing approaches

This section will teach you how to test GraphQL APIs using two approaches.

The first one tests that the HTTP layer works by mimicking a client by sending queries and mutations against a server.

![Testing GraphQL layer](../images/graphql-schema.png "Testing GraphQL layer")

The second approach tests the GraphQL layer by sending queries and mutations directly against the app's schema. Both methods will use [Jest](http://facebook.github.io/jest/), a Javascript testing library.

![Testing HTTP layer](../images/client-server.png "Testing HTTP layer")

Both methodologies have benefits. Testing the HTTP layer is a great way to verify that your API works from the point of view of HTTP clients, which are the end users of an API. The other approach, testing the GraphQL layer, is faster and simpler because it does not add any HTTP-related overhead.

Which one you choose depends on your use case. It is always a good idea to test systems from the point of view of their users, so testing APIs in the HTTP layer is always a great approach. Sometimes you want faster test runs to improve developer productivity, so you decide that testing the GraphQL layer is the best approach. Remember that you can even mix and match approaches.

Create your own copy of the testing project by remixing it:

[!["Remix image"](../images/remix.png)](https://glitch.com/edit/#!/remix/pinapp-server-testing)

### 6.2 GraphQL layer

Testing the data layer is as simple as using the `graphql` function from `graphql-js` against your schema. You will recognize this pattern, because it is the approach you used to learn queries and mutations in Chapter 1.

To test queries using this approach, a good strategy is seeding the database before the first test, and cleaning it up after the last one.

Jest snapshots are a great tool to test GraphQL results. Snapshots store values in JSON files from each test on the first run. On successive runs of the test suite, it checks that the stored values have not changed. Testing GraphQL results using snapshots is great because it is low effort way to verify that everything works.

```js
describe("Data layer", () => {
  beforeAll(() => {
    return database.seed.run();
  });
  afterAll(() => database.destroy());
  it("should search pins by title", () => {
    return graphql(schema, search, undefined, undefined, { text: "First" })
      .then(result => {
        expect(result.data.search).toMatchSnapshot();
      });
  });
});
```

This approach is inspired by an awesome open source project called [Spectrum](https://spectrum.chat/). It has an extensive testing suite that uses Jest snapshots to test their GraphQL schema. Check out [Spectrum's github repository](https://github.com/withspectrum/spectrum/tree/e603e77bbb965bbbc7c678d9e9295e976c9381e0/api/test) to see this approach in a production codebase.

### 6.3 HTTP Layer

### 6.4 Subscriptions endpoints

### 6.5 Apollo GraphQL clients

* Learn how to test in React Apollo using Jest and Enzyme
  * https://glitch.com/edit/#!/pinapp-client-testing

### 6.6 Summary

