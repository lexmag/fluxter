# Fluxter

[![Build Status](https://travis-ci.org/lexmag/fluxter.svg?branch=master "Build Status")](https://travis-ci.org/lexmag/fluxter)
[![Hex Version](https://img.shields.io/hexpm/v/fluxter.svg "Hex Version")](https://hex.pm/packages/fluxter)

Fluxter is an InfluxDB writer for Elixir. It uses InfluxDB's line protocol over UDP.

**Important:** this is a forked version with a fix for an error with Fluxter and ERTS >= 10.5.3. Originally, Fluxter would include a hardcoded binary header to each write. This header contains the binary represetation of the destination IP address, port, and optionally a prefix. The write itself was being issued as a plain `send` to the port that was failing with error `einval`. We believe that there was a change in the way ERTS expects this header to be formatted. We patched Fluxter to use `:gen_udp.send/4` and drop the binary header to fix the issue.

**Note:** if you're using Erlang 19 or greater, you need Fluxter 0.4.0 or greater otherwise metrics reporting will (silently) not work because of network driver changes happened between Erlang 18 and Erlang 19.

## Installation

Add Fluxter as a dependency to your `mix.exs` file:

```elixir
def application() do
  [applications: [:fluxter]]
end

defp deps() do
  [{:fluxter, "~> 0.7"}]
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

Once the Fluxter pool is started, its `write/2,3` and `measure/2,3,4` functions can successfully be used to send points to the data store.

Much more information can be found in the [documentation](http://hexdocs.pm/fluxter).

## License

This software is licensed under [the ISC license](LICENSE).
