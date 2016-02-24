# Fluxter

[![Build Status](https://travis-ci.org/lexmag/fluxter.svg)](https://travis-ci.org/lexmag/fluxter)

Fluxter is an InfluxDB writer for Elixir, it uses line protocol over UDP.

## Installation

Add Fluxter as a dependency to your `mix.exs` file:

```elixir
def application() do
  [applications: [:fluxter]]
end

defp deps() do
  [{:fluxter, "~> 0.1"}]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

## Usage

A module that uses Fluxter represents connection pool:

```elixir
defmodule MyApp.Fluxter do
  use Fluxter
end
```

Each Fluxter pool has a `start_link/0` function that needs to be invoked before using it. In general, this function is not called directly, but used as part of your application supervision tree, for example:

```elixir
def start(_type, _args) do
  import Supervisor.Spec

  children = [
    supervisor(MyApp.Fluxter, []),
    #...
  ]
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

Thereafter, the `write/2,3` and `measure/2,3,4` functions will be successfully sending points to the datastore.

### Configuration

Fluxter could be configured globally with:

```elixir
config :fluxter,
  prefix: "my_app",
  host: "metrics.tld",
  port: 1122
```

and on a per module basis as well:

```elixir
config :fluxter, MyApp.Fluxter,
  pool_size: 10,
  port: 2233
```

The defaults are:

* prefix: `nil`
* host: `"127.0.0.1"`
* port: `8092`
* pool_size: `5`

## License

This software is licensed under [the ISC license](LICENSE).
