defmodule Fluxter.Counter do
  @moduledoc false

  use GenServer

  defstruct [:measurement, :tags, :fields, :parent, value: 0, flush?: false]

  def start(measurement, tags, fields)
      when is_list(tags) and is_list(fields) and
           (is_binary(measurement) or is_list(measurement)) do
    state = %__MODULE__{measurement: measurement, tags: tags, fields: fields, parent: self()}
    {:ok, pid} = GenServer.start_link(__MODULE__, state)
    pid
  end

  def increment(counter, change) when is_number(change) do
    GenServer.cast(counter, {:increment, change})
  end

  def flush(counter, pool) when is_atom(pool) do
    GenServer.call(counter, {:flush, pool})
  end

  def handle_cast({:increment, change}, %__MODULE__{value: value} = state) do
    {:noreply, %{state | value: value + change, flush?: true}}
  end

  def handle_call({:flush, pool}, from, %__MODULE__{parent: parent} = state) do
    Process.unlink(parent)
    GenServer.reply(from, :ok)
    if state.flush? do
      %{value: value, tags: tags, fields: fields, measurement: measurement} = state
      pool.write(measurement, tags, [value: value] ++ fields)
    end
    {:stop, :normal, state}
  end
end
