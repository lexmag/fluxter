defmodule FluxterTest do
  use ExUnit.Case

  defmodule EchoServer do
    use GenServer

    def start_link(port) do
      GenServer.start_link(__MODULE__, port)
    end

    def set_current_test(server, test) do
      GenServer.call(server, {:set_current_test, test})
    end

    def init(port) do
      {:ok, socket} = :gen_udp.open(port, [:binary, active: true])
      {:ok, %{socket: socket, test: nil}}
    end

    def handle_call({:set_current_test, current_test}, _from, %{test: test} = state) do
      if is_nil(test) or is_nil(current_test) do
        {:reply, :ok, %{state | test: current_test}}
      else
        {:reply, :error, state}
      end
    end

    def handle_info({:udp, socket, _, _, packet}, %{socket: socket, test: test} = state) do
      send(test, {:echo, packet})
      {:noreply, state}
    end
  end

  defmodule FluxterSample do
    use Fluxter
  end

  defmodule FluxterXyzzy do
    use Fluxter
  end

  setup_all do
    {:ok, server} = EchoServer.start_link(8092)
    {:ok, _} = FluxterSample.start_link()
    {:ok, %{server: server}}
  end

  setup %{server: server} do
    :ok = EchoServer.set_current_test(server, self())
    on_exit(fn -> EchoServer.set_current_test(server, nil) end)
  end

  test "start_link/1" do
    {:ok, server} = EchoServer.start_link(9092)
    :ok = EchoServer.set_current_test(server, self())

    options = [port: 9092, prefix: "xyzzy"]
    {:ok, _} = FluxterXyzzy.start_link(options)

    FluxterXyzzy.write('foo', bar: 2)
    assert_receive {:echo, "xyzzy_foo bar=2i"}
  end

  test "write/2,3" do
    FluxterSample.write("foo", bar: 11, baz: 0)
    assert_receive {:echo, "foo bar=11i,baz=0i"}

    FluxterSample.write("foo bar", 11)
    assert_receive {:echo, "foo\\ bar value=11i"}

    FluxterSample.write("foo", 1.0)
    payload = "foo value=#{Float.to_string(1.0)}"
    assert_receive {:echo, ^payload}

    FluxterSample.write("foo", "data\"")
    assert_receive {:echo, "foo value=\"data\\\"\""}

    FluxterSample.write('foo', true)
    assert_receive {:echo, "foo value=true"}
    FluxterSample.write("foo", false)
    assert_receive {:echo, "foo value=false"}

    FluxterSample.write("foo", [bar: "baz qux"], 0)
    assert_receive {:echo, "foo,bar=baz\\ qux value=0i"}

    FluxterSample.write("foo", [bar: "baz", qux: "baz"], 0)
    assert_receive {:echo, "foo,bar=baz,qux=baz value=0i"}

    refute_receive _any
  end

  test "measure/2,3,4" do
    result = FluxterSample.measure("foo", fn ->
      :timer.sleep(100)
      "OK"
    end)
    assert_receive {:echo, <<"foo value=10", _::4-bytes, "i">>}
    assert result == "OK"

    result = FluxterSample.measure("foo", [bar: "baz"], fn ->
      :timer.sleep(100)
      "OK"
    end)
    assert_receive {:echo, <<"foo,bar=baz value=10", _::4-bytes, "i">>}
    assert result == "OK"

    refute_receive _any
  end

  test "counter functionality" do
    counter = FluxterSample.start_counter("bar")

    assert is_pid(counter)

    assert FluxterSample.flush_counter(counter) == :ok
    refute_receive _any
    refute_alive counter

    counter = FluxterSample.start_counter("foo", [bar: "baz"])

    assert FluxterSample.increment_counter(counter, 2) == :ok
    refute_receive _any

    assert FluxterSample.increment_counter(counter, 1) == :ok
    refute_receive _any

    assert FluxterSample.flush_counter(counter) == :ok
    assert_receive {:echo, "foo,bar=baz value=3i"}

    refute_receive _any
    refute_alive counter

    counter = FluxterSample.start_counter("qux", [], [bar: "baz"])

    assert FluxterSample.increment_counter(counter, 1.0) == :ok
    refute_receive _any

    assert FluxterSample.flush_counter(counter) == :ok
    payload = "qux value=#{Float.to_string(1.0)},bar=\"baz\""
    assert_receive {:echo, ^payload}

    refute_receive _any
    refute_alive counter

    parent = self()
    spawn(fn ->
      counter = FluxterSample.start_counter("bar")
      send(parent, {:counter, counter})
      exit(:timeout)
    end)
    assert_receive {:counter, counter}
    refute_alive counter
  end

  defp refute_alive(pid) do
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, _, _, _}, 500
  end
end
