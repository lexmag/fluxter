defmodule Fluxter do
  @moduledoc """
  InfluxDB writer for Elixir that uses InfluxDB's line protocol over UDP.

  To get started with Fluxter, you have to create a module that calls `use
  Fluxter`, like this:

      defmodule MyApp.Fluxter do
        use Fluxter
      end

  This way, `MyApp.Fluxter` becomes an InfluxDB connection pool. Each Fluxter
  pool provides a `start_link/0` function that starts that pool and connects to
  InfluxDB; this function needs to be invoked before being able to send data to
  InfluxDB. Typically, you won't call `start_link/0` directly as you'll want to
  add Fluxter pools to your application's supervision tree; for example:

      def start(_type, _args) do
        import Supervisor.Spec

        children = [
          supervisor(MyApp.Fluxter, []),
          # ...
        ]
        Supervisor.start_link(children, strategy: :one_for_one)
      end

  Once a Fluxter pool is started, its `write/2,3` and `measure/2,3,4` functions
  can successfully be used to send points to the data store. A Fluxter pool
  implements the `Fluxter` behaviour, so you can read documentation for the
  callbacks the behaviour provides to know more about these functions.

  ## Configuration

  Fluxter can be configured either globally or on a per-pool basis.

  The global configuration will affect all Fluxter pools; it can be specified by
  configuring the `:fluxter` application:

      config :fluxter,
        host: "metrics.example.com",
        port: 1122

  The per-pool configuration can be specified by configuring the pool module
  under the `:fluxter` application:

      config :fluxter, MyApp.Fluxter,
        host: "metrics.example.com",
        port: 1122,
        pool_size: 10

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

  ## Batching

  Fluxter supports "batching": a batch is a metric aggregator designed to
  locally aggregate an numeric value and flush the aggregated value only once to
  the storage, as a single metric. This is very useful when you have the need to
  write a high number of metrics in a very short amount of time. Doing so can
  have a negative impact on the speed of your code and can also cause network
  packet drops.

  For example, code like the following:

      for i <- 1_000_000 do
        my_operation(i)
        MyApp.Fluxter.write("my_operation_success", [host: "eu-west"], 1)
      end

  can take advantage of batching:

      {:ok, batch} = MyApp.Fluxter.start_batch("my_operation_success", [host: "eu-west"])
      for i <- 1_000_000 do
        my_operation(i)
        MyApp.Fluxter.write_to_batch(batch, 1)
      end
      MyApp.Fluxter.flush_batch(batch)

  """

  @type measurement :: String.Chars.t
  @type tags :: [{String.Chars.t, String.Chars.t}]
  @type field_value :: number | boolean | binary
  @type fields :: [{String.Chars.t, field_value}]

  @doc """
  Starts this Fluxter pool.

  A Fluxter pool is a set of processes supervised by a supervisor; this function
  starts all that processes and that supervisor.

  Usually, you'll want to use a Fluxter pool in the supervision tree of your
  application:

      def start(_type, _args) do
        import Supervisor.Spec

        children = [
          supervisor(MyApp.Fluxter, []),
          # ...
        ]
        Supervisor.start_link(children, strategy: :one_for_one)
      end

  """
  @callback start_link() :: Supervisor.on_start

  @doc """
  Writes a metric to the data store.

  `measurement` is the name of the metric to write.
  `tags` is a list of key-value pairs that specifies tags (as name and value)
  for the data point to write; note that tag values are converted to strings
  as InfluxDB only support string values for tags.
  `fields` can either be a list of key-value pairs, in which case it
  specifies a list of fields (as name and value), or a single value
  (specifically, a boolean, float, integer, or binary). In the latter case, the
  default field name of `value` will be used: calling `write("foo", [], 4.3)` is
  the same as calling `write("foo", [], value: 4.3)`.

  The return value is always `:ok` as writing is a *fire-and-forget* operation.

  ## Examples

  Assuming a `MyApp.Fluxter` Fluxter pool exists:

      iex> MyApp.Fluxter.write("cpu_temp", [host: "eu-west"], 68)
      :ok

  """
  @callback write(measurement, tags, field_value | fields) :: :ok

  @doc """
  Should be the same as `write(measurement, [], fields)`.
  """
  @callback write(measurement, field_value | fields) :: :ok

  @doc """
  Should be the same as `measure(measurement, [], [], fun)`.
  """
  @callback measure(measurement, (() -> result)) :: result when result: var

  @doc """
  Should be the same as `measure(measurement, tags, [], fun)`.
  """
  @callback measure(measurement, tags, (() -> result)) :: result when result: var

  @doc """
  Measures the execution time of `fun` and writes it as a metric.

  This function is just an utility function to measure the execution time of a
  given function `fun`. The `measurement` and `tags` arguments work in the same way as
  in `c:write/3`.

  `fun`'s execution time is prepended as a field called `value` to the already
  existing list of `fields`. This means that if there's already a field called
  `value` in `fields`, it will be overridden by the measurement. This also means
  that `fields` must be a list of key-value pairs (field name and value): simple
  floats, integers, booleans, and binaries as values for `fields` are not
  supported like they are in `c:write/3`.

  This function returns whatever `fun` returns.

  ## Examples

  Assuming a `MyApp.Fluxter` Fluxter pool exists:

      iex> MyApp.Fluxter.measure "task_exec_time", [host: "us-east"], fn ->
      ...>   1 + 1
      ...> end
      2

  """
  @callback measure(measurement, tags, fields, (() -> result)) :: result when result: var

  @doc """
  Should be the same as `start_batch(measurement, [], [])`.
  """
  @callback start_batch(measurement) :: {:ok, pid}

  @doc """
  Should be the same as `start_batch(measurement, tags, [])`.
  """
  @callback start_batch(measurement, tags) :: {:ok, pid}

  @doc """
  Starts a batch for a metric.

  The purpose of this batch is to aggregate a numeric metric: values aggregated
  in the batch will only be written to the storage as a single metric when the
  batch is "flushed" (see `c:flush_batch/1`). `tags` and `fields` will be tags
  and fields attached to the metric when it's flushed. The aggregated value of
  the metric will be prepended to `fields` as a field called `value`; this means
  that if there's already a field called `value` in `fields`, it will be
  overridden.

  This function returns `{:ok, pid}` where `pid` is the pid of the new batch.

  See the "Batching" section in the documentation for `Fluxter` for more
  information on batches.

  ## Examples

  Assuming a `MyApp.Fluxter` Fluxter pool exists:

      iex> MyApp.Fluxter.start_batch("hits", [host: "us-west"])
      {:ok, #PID<...>}

  """
  @callback start_batch(measurement, tags, fields) :: {:ok, pid}

  @doc """
  Adds the `extra` value to the given `batch`.

  This function adds the `extra` value (a number) to the current value of the
  given `batch`. To subtract, just use a negative number to add to the current
  value of `batch`.

  This function performs a *fire-and-forget* operation (a cast) on the given
  batch, hence it will always return `:ok`.

  See the "Batching" section in the documentation for `Fluxter` for more
  information on batches.

  ## Examples

  Assuming a `MyApp.Fluxter` Fluxter pool exists:

      iex> MyApp.Fluxter.write_to_batch(batch, 1)
      :ok

  """
  @callback write_to_batch(batch :: pid, extra :: number) :: :ok

  @doc """
  Flushes the given `batch` by writing its aggregated value as a single metric.

  This function performs a *fire-and-forget* operation (a cast) on the given
  batch, hence it will always return `:ok`.

  This function will also stop the `batch` process after the metric is flushed.

  See the "Batching" section in the documentation for `Fluxter` for more
  information on batches.

  ## Examples

  Assuming a `MyApp.Fluxter` Fluxter pool exists:

      iex> MyApp.Fluxter.flush_batch(batch)
      :ok

  """
  @callback flush_batch(batch :: pid) :: :ok

  @doc false
  defmacro __using__(_opts) do
    quote [unquote: false, location: :keep] do
      @behaviour Fluxter

      @pool_size Application.get_env(__MODULE__, :pool_size, 5)
      @worker_names Enum.map(0..(@pool_size - 1), &:'#{__MODULE__}-#{&1}')

      def start_link() do
        import Supervisor.Spec

        {host, port, prefix} = Fluxter.config_for(__MODULE__)
        conn = Fluxter.Conn.new(host, port)
        conn = %{conn | header: [conn.header | prefix]}

        Enum.map(@worker_names, &worker(Fluxter.Conn, [conn, &1], id: &1))
        |> Supervisor.start_link(strategy: :one_for_one)
      end

      @compile {:inline, worker_name: 1}
      for {name, index} <- Enum.with_index(@worker_names) do
        defp worker_name(unquote(index)) do
          unquote(name)
        end
      end

      def write(measurement, tags \\ [], fields)

      def write(measurement, tags, fields) when is_list(fields) do
        System.unique_integer([:positive])
        |> rem(@pool_size)
        |> worker_name()
        |> Fluxter.Conn.write(measurement, tags, fields)
      end

      def write(measurement, tags, value)
      when is_float(value) or is_integer(value)
      when is_boolean(value) or is_binary(value) do
        write(measurement, tags, [value: value])
      end

      def measure(measurement, tags \\ [], fields \\ [], fun)
      when is_function(fun, 0) do
        {elapsed, result} = :timer.tc(fun)
        write(measurement, tags, [value: elapsed] ++ fields)
        result
      end

      def start_batch(measurement, tags \\ [], fields \\ []) do
        Fluxter.Batch.start(__MODULE__, measurement, tags, fields)
      end

      defdelegate write_to_batch(batch, extra), to: Fluxter.Batch, as: :write
      defdelegate flush_batch(batch), to: Fluxter.Batch, as: :flush
    end
  end

  @doc false
  def config_for(module) do
    {loc_env, glob_env} =
      Application.get_all_env(:fluxter)
      |> Keyword.pop(module, [])

    host = loc_env[:host] || glob_env[:host]
    port = loc_env[:port] || glob_env[:port]
    prefix = make_prefix(glob_env[:prefix], loc_env[:prefix])

    {host, port, prefix}
  end

  defp make_prefix(global, local) do
    Enum.map_join([global, local], &(&1 && [&1, ?_]))
  end
end
