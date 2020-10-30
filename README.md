# Fluxter

[![Build Status](https://travis-ci.org/lexmag/fluxter.svg?branch=master "Build Status")](https://travis-ci.org/lexmag/fluxter)
[![Hex Version](https://img.shields.io/hexpm/v/fluxter.svg "Hex Version")](https://hex.pm/packages/fluxter)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/fluxter/)
[![Total Downloads](https://img.shields.io/hexpm/dt/fluxter.svg)](https://hex.pm/packages/fluxter)
[![License](https://img.shields.io/hexpm/l/fluxter.svg)](https://hex.pm/packages/fluxter)
[![Last Update](https://img.shields.io/github/last-commit/lexmag/fluxter.svg)](https://github.com/lexmag/fluxter/commits/master)

Fluxter is an [InfluxDB](https://www.influxdata.com/), an open-source time
series database writer for Elixir. It uses InfluxDB's line protocol over UDP.

## Installation

Add `fluxter` as a dependency to your `mix.exs` file:

```elixir
defp deps() do
  [{:fluxter, "~> 0.8"}]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

## Usage

<!-- USAGE !-->

To get started with Fluxter, you have to create a module that calls `use
Fluxter`, like this:

```elixir
defmodule MyApp.Fluxter do
  use Fluxter
end
```

This way, `MyApp.Fluxter` becomes an InfluxDB connection pool. Each Fluxter
pool provides a `c:start_link/1` function that starts that pool and connects to
InfluxDB; this function needs to be invoked before being able to send data to
InfluxDB. Typically, you won't call `start_link/1` directly as you'll want to
add Fluxter pools to your application's supervision tree. For this use case,
pools provide a `child_spec/1` function:

```elixir
def start(_type, _args) do
  children = [
    MyApp.Fluxter.child_spec(),
    # ...
  ]
  Supervisor.start_link(children, strategy: :one_for_one)
end
```

Once a Fluxter pool is started, its `c:write/2,3`, `c:measure/2,3,4`, and other
functions can successfully be used to send points to the data store.
A Fluxter pool implements the `Fluxter` behaviour, so you can read documentation
for the callbacks the behaviour provides to know more about these functions.

## Configuration

Fluxter can be configured either globally or on a per-pool basis.

The global configuration will affect all Fluxter pools; it can be specified by
configuring the `:fluxter` application:

```elixir
config :fluxter,
  host: "metrics.example.com",
  port: 1122
```

The per-pool configuration can be specified by configuring the pool module
under the `:fluxter` application:

```elixir
config :fluxter, MyApp.Fluxter,
  host: "metrics.example.com",
  port: 1122,
  pool_size: 10
```

The following is a list of all the supported options:

  * `:host` - (binary) the host to send metrics to. Defaults to `"127.0.0.1"`.
  * `:port` - (integer) the port (on `:host`) to send the metrics to. Defaults
    to `8092`.
  * `:prefix` - (binary or `nil`) all metrics sent to the data store through
    the configured Fluxter pool will be prefixed by the value of this
    option. If `nil`, metrics will not be prefixed. Defaults to `nil`.
  * `:pool_size` - (integer) the size of the connection pool for the given
    Fluxter pool. **This option can only be configured on a per-pool basis**;
    configuring it globally for the `:fluxter` application has no
    effect. Defaults to `5`.

## Metric aggregation

Fluxter supports counters: a counter is a metric aggregator designed to
locally aggregate a numeric value and flush the aggregated value only once to
the storage, as a single metric. This is very useful when you have the need to
write a high number of metrics in a very short amount of time. Doing so can
have a negative impact on the speed of your code and can also cause network
packet drops.

For example, code like the following:

```elixir
for value <- 1..1_000_000 do
  my_operation(value)
  MyApp.Fluxter.write("my_operation_success", [host: "eu-west"], 1)
end
```

can take advantage of metric aggregation:

```elixir
counter = MyApp.Fluxter.start_counter("my_operation_success", [host: "eu-west"])
for value <- 1..1_000_000 do
  my_operation(value)
  MyApp.Fluxter.increment_counter(counter, 1)
end
MyApp.Fluxter.flush_counter(counter)
```

<!-- USAGE !-->

## License

This software is licensed under [the ISC license](LICENSE).
