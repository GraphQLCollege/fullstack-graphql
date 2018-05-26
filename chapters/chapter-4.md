## 4. GraphQL clients

### 4.1 Apollo Client

* Apollo client
  * `ApolloBoost`
  * https://glitch.com/edit/#!/pinapp-initial
  * https://glitch.com/edit/#!/pinapp-apollo-client

### 4.2 React Apollo

* React Apollo
  * Patterns
    * Context Provider (ApolloProvider)
    * Functions as children (Query, Mutation and Subscription)
  * Components
    * `<ApolloProvider />`
    * `<Query />`
    * `gql`
    * `{ loading, error, data }`
    * `variables`
    * `<Mutation />`
    * `update`
    * `refetchQueries`
    * https://glitch.com/edit/#!/pinapp-react-apollo

### 4.3 Subscriptions

* Subscriptions
  * Apollo Boost Migration
    * https://www.apollographql.com/docs/react/advanced/boost-migration.html
    * https://www.apollographql.com/docs/react/advanced/subscriptions.html
    * `ApolloClient`
    * `InMemoryCache`
    * `HttpLink`
    * `ApolloLink`
    * `split`
      * https://www.apollographql.com/docs/link/composition.html#directional
      * https://github.com/Akryum/vue-apollo/issues/144
  * Subscription APIs
    * `WebsocketLink`
    * `<Subscription />`
    * `subscribeToMore`
    * https://glitch.com/edit/#!/pinapp-client-subscriptions

### 4.4 Testing

* Learn how to test in React Apollo using Jest and Enzyme
  * https://glitch.com/edit/#!/pinapp-client-testing

