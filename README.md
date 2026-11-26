# handler

[![CI](https://github.com/gql-go/handler/actions/workflows/ci.yml/badge.svg)](https://github.com/gql-go/handler/actions/workflows/ci.yml)
[![Go Reference](https://pkg.go.dev/badge/github.com/gql-go/handler.svg)](https://pkg.go.dev/github.com/gql-go/handler)

A Go `http.Handler` for [`gql-go/graphql`](https://github.com/gql-go/graphql).

This is a community-maintained continuation of
[`graphql-go/handler`](https://github.com/graphql-go/handler), created by
[Hafiz Ismail](https://github.com/sogko) and maintained by
[Chris Ramón](https://github.com/chris-ramon). It moves together with
`gql-go/graphql`; see that repository for the motivation, the commitments and the
roadmap. Its transport items (GraphQL over HTTP, WebSocket and server-sent
events, persisted queries) will land here.

## Getting started

```bash
go get github.com/gql-go/handler
```

```go
package main

import (
	"net/http"

	"github.com/gql-go/graphql"
	"github.com/gql-go/handler"
)

func main() {
	schema, _ := graphql.NewSchema(graphql.SchemaConfig{ /* ... */ })

	h := handler.New(&handler.Config{
		Schema:   &schema,
		Pretty:   true,
		GraphiQL: true,
	})

	http.Handle("/graphql", h)
	http.ListenAndServe(":8080", nil)
}
```

To serve GraphQL Playground instead of GraphiQL, set `GraphiQL: false` and
`Playground: true`.

### Migrating from `graphql-go/handler`

The API is unchanged. Replace both import prefixes:

```
github.com/graphql-go/handler  ->  github.com/gql-go/handler
github.com/graphql-go/graphql  ->  github.com/gql-go/graphql
```

## Request parameters

The handler accepts:

- **`query`**: the GraphQL document to execute.
- **`variables`**: the values for the operation's variables, as a JSON object.
- **`operationName`**: which operation to run when `query` contains several
  named operations.

It looks for them first in the URL query string:

```
/graphql?query=query+getUser($id:ID){user(id:$id){name}}&variables={"id":"4"}
```

Otherwise it reads the POST body according to its `Content-Type`:

- **`application/json`**: a JSON object with the parameters above.
- **`application/x-www-form-urlencoded`**: url-encoded key-value pairs.
- **`application/graphql`**: the body is the `query` itself.

`NewRequestOptions` exposes this parsing on its own, for servers that execute the
operation themselves.

## Contributing

Issues and pull requests are welcome, including ones still open on the original
repository. See the [`gql-go/graphql`](https://github.com/gql-go/graphql)
README for how the project is run.

## License

[MIT](LICENSE), the same as the original project.
