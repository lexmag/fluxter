defmodule Fluxter.Conn do
  @moduledoc false

  use GenServer

  alias Fluxter.Packet

  require Logger

  defstruct [:sock, :header]

  def new(host, port) when is_binary(host) do
    new(String.to_char_list(host), port)
  end

  def new(host, port) when is_list(host) or is_tuple(host) do
    {:ok, addr} = :inet.getaddr(host, :inet)
    header = Packet.header(addr, port)
    %__MODULE__{header: header}
  end

  def start_link(%__MODULE__{} = conn, worker) do
    GenServer.start_link(__MODULE__, conn, [name: worker])
  end

  def write(worker, name, tags, fields)
  when (is_binary(name) or is_list(name)) and is_list(tags) and is_list(fields) do
    # TODO: Remove `try` wrapping when we depend on Elixir ~> 1.3
    try do
      GenServer.cast(worker, {:write, name, tags, fields})
    catch
      _, _ -> :ok
    end
  end

  def init(conn) do
    {:ok, sock} = :gen_udp.open(0, [active: false])
    {:ok, %{conn | sock: sock}}
  end

  def handle_cast({:write, name, tags, fields}, conn) do
    packet = Packet.build(conn.header, name, tags, fields, nil)
    send(conn.sock, {self(), {:command, packet}})
    {:noreply, conn}
  end

  def handle_info({:inet_reply, _sock, :ok}, conn) do
    {:noreply, conn}
  end

  def handle_info({:inet_reply, _sock, {:error, reason}}, conn) do
    Logger.error [
      "Metric sending failed with reason ",
      ?", :inet.format_error(reason), ?",
    ]
    {:noreply, conn}
  end
end
