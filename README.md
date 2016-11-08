# Fluxter

[![Build Status](https://travis-ci.org/lexmag/fluxter.svg?branch=master "Build Status")](https://travis-ci.org/lexmag/fluxter)
[![Hex Version](https://img.shields.io/hexpm/v/fluxter.svg "Hex Version")](https://hex.pm/packages/fluxter)

Fluxter is an InfluxDB writer for Elixir. It uses InfluxDB's line protocol over UDP.

**NOTE**: if you're on Erlang 19 or greater, you need Fluxter 0.4.0 or greater
otherwise reporting metrics will (silently) not work because of some network
driver changes happened between Erlang 18 and Erlang 19.

## Installation

Add Fluxter as a dependency to your `mix.exs` file:

```elixir
def application() do
  [applications: [:fluxter]]
end

defp deps() do
  [{:fluxter, "~> 0.4"}]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

## Usage

A module that uses Fluxter becomes an InfluxDB connection pool:

```elixir
defmodule MyApp.Fluxter do
  use Fluxter
end
```

Each Fluxter pool provides a `start_link/0` function that starts the pool and connects to InfluxDB; this function needs to be invoked before the pool can be used. Usually, you won't call `start_link/0` directly as you'll want to use a Fluxter pool as part of your application's supervision tree. For example:

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

Once the Fluxter pool is started, its `write/2,3` and `measure/2,3,4` functions can successfully be used to send points to the data store.

Much more information can be found in the [documentation](http://hexdocs.pm/fluxter).

## License

This software is licensed under [the ISC license](LICENSE).
