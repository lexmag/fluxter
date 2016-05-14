defmodule Fluxter.Batch do
  @moduledoc false

  use GenServer

  defstruct [:pool, :name, :tags, :fields, value: 0, flush?: false]

  def start(pool, name, tags, fields)
  when is_atom(pool) and (is_binary(name) or is_list(name)) and
       is_list(tags) and is_list(fields) do
    state = %__MODULE__{
      pool: pool, name: name, tags: tags, fields: fields
    }
    GenServer.start_link(__MODULE__, state)
  end

  def write(batch, extra) when is_number(extra) do
    GenServer.cast(batch, {:write, extra})
  end

  def flush(batch) do
    GenServer.cast(batch, :flush)
  end

  def handle_cast({:write, extra}, %__MODULE__{value: value} = state) do
    {:noreply, %{state | value: value + extra, flush?: true}}
  end

  def handle_cast(:flush, %__MODULE__{} = state) do
    if state.flush? do
      %{value: value, tags: tags, fields: fields, name: name, pool: pool} = state
      pool.write(name, tags, [value: value] ++ fields)
    end
    {:stop, :normal, :ok}
  end
end
