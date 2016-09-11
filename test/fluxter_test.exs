defmodule FluxterTest do
  use ExUnit.Case

  defmodule EchoServer do
    def start(test, port) do
      {:ok, sock} = :gen_udp.open(port, [:binary, active: false])
      Task.start_link(fn ->
        recv(test, sock)
      end)
    end

    defp recv(test, sock) do
      send(test, {:echo, recv(sock)})
      recv(test, sock)
    end

    defp recv(sock) do
      case :gen_udp.recv(sock, 0) do
        {:ok, {_, _, packet}} ->
          packet
        {:error, _} = error ->
          error
      end
    end
  end

  defmodule Sample do
    use Fluxter
  end

  setup_all do
    {:ok, _} = Sample.start_link
    :ok
  end

  setup do
    {:ok, _} = EchoServer.start(self(), 8092)
    :ok
  end

  test "write/2,3" do
    Sample.write("foo", bar: 11, baz: 0)
    assert_receive {:echo, "foo bar=11i,baz=0i"}

    Sample.write("foo bar", 11)
    assert_receive {:echo, "foo\\ bar value=11i"}

    Sample.write("foo", 1.0)
    payload = "foo value=#{Float.to_string(1.0)}"
    assert_receive {:echo, ^payload}

    Sample.write("foo", "data\"")
    assert_receive {:echo, "foo value=\"data\\\"\""}

    Sample.write('foo', true)
    assert_receive {:echo, "foo value=true"}
    Sample.write("foo", false)
    assert_receive {:echo, "foo value=false"}

    Sample.write("foo", [bar: "baz qux"], 0)
    assert_receive {:echo, "foo,bar=baz\\ qux value=0i"}

    Sample.write("foo", [bar: "baz", qux: "baz"], 0)
    assert_receive {:echo, "foo,bar=baz,qux=baz value=0i"}

    refute_receive _any
  end

  test "measure/2,3,4" do
    result = Sample.measure("foo", fn ->
      :timer.sleep(100)
      "OK"
    end)
    assert_receive {:echo, <<"foo value=10", _::4-bytes, "i">>}
    assert result == "OK"

    result = Sample.measure("foo", [bar: "baz"], fn ->
      :timer.sleep(100)
      "OK"
    end)
    assert_receive {:echo, <<"foo,bar=baz value=10", _::4-bytes, "i">>}
    assert result == "OK"

    refute_receive _any
  end

  test "batch functions" do
    assert {:ok, pid} = Sample.start_batch("foo", [bar: "baz"])
    assert is_pid(pid)

    assert Sample.write_to_batch(pid, 2) == :ok
    refute_receive _any

    assert Sample.write_to_batch(pid, 1) == :ok
    refute_receive _any

    assert Sample.flush_batch(pid) == :ok
    assert_receive {:echo, "foo,bar=baz value=3i"}

    refute_receive _any
    assert {:ok, pid} = Sample.start_batch("qux", [], [bar: "baz"])
    assert is_pid(pid)

    assert Sample.write_to_batch(pid, 1.0) == :ok
    refute_receive _any

    assert Sample.flush_batch(pid) == :ok
    payload = "qux value=#{Float.to_string(1.0)},bar=\"baz\""
    assert_receive {:echo, ^payload}

    refute_receive _any
    assert {:ok, pid} = Sample.start_batch("bar")
    assert is_pid(pid)

    assert Sample.flush_batch(pid) == :ok
    refute_receive _any
  end
end
