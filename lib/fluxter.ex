defmodule Fluxter do
  defmacro __using__(_opts) do
    quote [unquote: false, location: :keep] do
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

      def write(name, tags \\ [], fields)

      def write(name, tags, fields) when is_list(fields) do
        System.unique_integer([:positive])
        |> rem(@pool_size)
        |> worker_name()
        |> Fluxter.Conn.write(name, tags, fields)
      end

      def write(name, tags, value)
      when is_float(value) or is_integer(value)
      when is_boolean(value) or is_binary(value) do
        write(name, tags, [value: value])
      end

      def measure(name, tags \\ [], fields \\ [], fun)
      when is_function(fun, 0) do
        {elapsed, result} = :timer.tc(fun)
        write(name, tags, [value: elapsed] ++ fields)
        result
      end
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
