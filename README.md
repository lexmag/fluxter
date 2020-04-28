# Fluxter

[![Build Status](https://travis-ci.org/lexmag/fluxter.svg?branch=master "Build Status")](https://travis-ci.org/lexmag/fluxter)
[![Hex Version](https://img.shields.io/hexpm/v/fluxter.svg "Hex Version")](https://hex.pm/packages/fluxter)

Fluxter is an InfluxDB writer for Elixir. It uses InfluxDB's line protocol over UDP.

## Installation

Add Fluxter as a dependency to your `mix.exs` file:

```elixir
defp deps() do
  [{:fluxter, "~> 0.8"}]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

## Usage

See [the documentation](https://hexdocs.pm/fluxter) for detailed usage information.

A module that uses Fluxter becomes an InfluxDB connection pool:

```elixir
defmodule MyApp.Fluxter do
  use Fluxter
end
```

Each Fluxter pool provides a `start_link/1` function that starts the pool and connects to InfluxDB; this function needs to be invoked before the pool can be used.
Typically, you won't call `start_link/1` directly as you'll want to
add a Fluxter pool to your application's supervision tree.
For this use case, pools provide a `child_spec/1` function:

```elixir
def start(_type, _args) do
  children = [
    MyApp.Fluxter.child_spec(),
    #...
  ]
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

Once the Fluxter pool is started, its `write/2,3`, `measure/2,3,4`, and other functions can successfully be used to send points to the data store.

## License

This software is licensed under [the ISC license](LICENSE).
