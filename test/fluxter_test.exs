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

    @impl true
    def init(port) do
      {:ok, socket} = :gen_udp.open(port, [:binary, active: true])
      {:ok, %{socket: socket, test: nil}}
    end

    @impl true
    def handle_call({:set_current_test, current_test}, _from, %{test: test} = state) do
      if is_nil(test) or is_nil(current_test) do
        {:reply, :ok, %{state | test: current_test}}
      else
        {:reply, :error, state}
      end
    end

    @impl true
    def handle_info({:udp, socket, _, _, packet}, %{socket: socket, test: test} = state) do
      send(test, {:echo, packet})
      {:noreply, state}
    end
  end

  defmodule TestFluxter do
    use Fluxter
  end

  setup_all do
    {:ok, server} = EchoServer.start_link(8092)
    {:ok, _} = TestFluxter.start_link()
    {:ok, %{server: server}}
  end

  setup %{server: server} do
    :ok = EchoServer.set_current_test(server, self())
    on_exit(fn -> EchoServer.set_current_test(server, nil) end)
  end

  test "get_config/2" do
    config = [
      {TestFluxter,
       [
         host: "tortoise.tld",
         port: 2233,
         prefix: "bar"
       ]},
      host: "hare.tld",
      port: 1122,
      prefix: "foo"
    ]

    # TODO: Use put_all_env/3 with Elixir v1.9 and higher.
    for {key, value} <- config, do: Application.put_env(:fluxter, key, value)

    try do
      assert Fluxter.get_config(TestFluxter, []) == %{
               host: "tortoise.tld",
               port: 2233,
               prefix: "foo_bar_"
             }
    after
      for {key, _} <- config, do: Application.delete_env(:fluxter, key)
    end
  end

  test "start_link/1" do
    defmodule OtherFluxter do
      use Fluxter
    end

    {:ok, server} = EchoServer.start_link(9092)
    :ok = EchoServer.set_current_test(server, self())

    options = [port: 9092, prefix: "xyzzy"]
    {:ok, _} = OtherFluxter.start_link(options)

    OtherFluxter.write(~c"foo", bar: 2)
    assert_receive {:echo, "xyzzy_foo bar=2i"}
  after
    :code.delete(OtherFluxter)
    :code.purge(OtherFluxter)
  end

  describe "write/2,3" do
    test "no tags, multiple values" do
      TestFluxter.write("foo", bar: 11, baz: 0)
      assert_receive {:echo, "foo bar=11i,baz=0i"}
    end

    test "no tags, space in measurement" do
      TestFluxter.write("foo bar", 11)
      assert_receive {:echo, "foo\\ bar value=11i"}
    end

    test "float value" do
      TestFluxter.write("foo", 1.0)
      payload = "foo value=#{Float.to_string(1.0)}"
      assert_receive {:echo, ^payload}
    end

    test "quote in value" do
      TestFluxter.write("foo", "data\"")
      assert_receive {:echo, "foo value=\"data\\\"\""}
    end

    test "bool values" do
      TestFluxter.write(~c"foo", true)
      assert_receive {:echo, "foo value=true"}
      TestFluxter.write("foo", false)
      assert_receive {:echo, "foo value=false"}
    end

    test "multiple tags, integer value" do
      TestFluxter.write("foo", [bar: "baz", qux: "baz"], 0)
      assert_receive {:echo, "foo,bar=baz,qux=baz value=0i"}
    end

    test "space in tag key" do
      TestFluxter.write("foo", [{:"space bar", "baz"}], 0)
      assert_receive {:echo, "foo,space\\ bar=baz value=0i"}
    end

    test "space in tag value" do
      TestFluxter.write("foo", [bar: "baz qux"], 0)
      assert_receive {:echo, "foo,bar=baz\\ qux value=0i"}
    end

    test "equal sign in tag key" do
      TestFluxter.write("foo", [{:"equal=bar", "baz"}], 0)
      assert_receive {:echo, "foo,equal\=bar=baz value=0i"}
    end

    test "equal sign in tag value" do
      TestFluxter.write("foo", [bar: "equal=baz"], 0)
      assert_receive {:echo, "foo,bar=equal\=baz value=0i"}
    end

    test "tag key starting with underscore" do
      TestFluxter.write("foo", [{:__under_bar, "baz"}], 0)
      assert_receive {:echo, "foo,under_bar=baz value=0i"}
    end

    test "field key starting with underscore" do
      TestFluxter.write("foo", [{:bar, "baz"}], [{:_under_qux, 16}])
      assert_receive {:echo, "foo,bar=baz under_qux=16i"}
    end

    test "nil tag" do
      TestFluxter.write("foo", [bar: "baz", qux: "baz", nil: nil], 0)
      assert_receive {:echo, "foo,bar=baz,nil=nil,qux=baz value=0i"}
    end

    test "nil field" do
      TestFluxter.write("foo", [bar: "baz", qux: "baz"], nil)
      assert_receive {:echo, "foo,bar=baz,qux=baz value=\"nil\""}
    end

    test "empty string tag" do
      TestFluxter.write("foo", [bar: "baz", qux: "baz", empty: ""], 0)
      assert_receive {:echo, "foo,bar=baz,empty=empty,qux=baz value=0i"}
    end

    test "only spaces in tag" do
      TestFluxter.write("foo", [bar: "baz", qux: "baz", empty: "     "], 0)
      assert_receive {:echo, "foo,bar=baz,empty=empty,qux=baz value=0i"}
    end

    test "empty string field" do
      TestFluxter.write("foo", "")
      assert_receive {:echo, "foo value=\"empty\""}
    end

    test "only spaces in field" do
      TestFluxter.write("foo", "    ")
      assert_receive {:echo, "foo value=\"empty\""}
    end

    test "atom field" do
      TestFluxter.write("foo", [bar: "baz", qux: "baz"], :atom)
      assert_receive {:echo, "foo,bar=baz,qux=baz value=\":atom\""}
    end

    test "list field" do
      TestFluxter.write("foo", [bar: "baz", qux: "baz"], [1, 2, 3])
      assert_receive {:echo, "foo,bar=baz,qux=baz value=\"[1, 2, 3]\""}
    end

    test "map field" do
      TestFluxter.write("foo", [bar: "baz", qux: "baz"], %{a: 1})
      assert_receive {:echo, "foo,bar=baz,qux=baz value=\"%{a: 1}\""}
    end

    test "multiple complex values" do
      TestFluxter.write("foo", bar: :atom, baz: [1, 2, 3], qux: %{"a" => "b"}, xnil: nil)

      assert_receive {:echo,
                      "foo bar=\":atom\",baz=\"[1, 2, 3]\",qux=\"%{\\\"a\\\" => \\\"b\\\"}\",xnil=\"nil\""}
    end
  end

  test "measure/2,3,4 with functions" do
    result = TestFluxter.measure("foo", fn -> sleep_and_return("OK") end)

    assert_receive {:echo, <<"foo value=10", _::4-bytes, "i">>}
    assert result == "OK"

    result =
      TestFluxter.measure("foo", [bar: "baz"], fn ->
        sleep_and_return("OK")
      end)

    assert_receive {:echo, <<"foo,bar=baz value=10", _::4-bytes, "i">>}
    assert result == "OK"

    refute_receive _any
  end

  test "measure/2,3,4 with module, function, arguments tuples" do
    mfa = {__MODULE__, :sleep_and_return, ["OK"]}

    result = TestFluxter.measure("foo", mfa)
    assert_receive {:echo, <<"foo value=10", _::4-bytes, "i">>}
    assert result == "OK"

    result = TestFluxter.measure("foo", [bar: "baz"], mfa)
    assert_receive {:echo, <<"foo,bar=baz value=10", _::4-bytes, "i">>}
    assert result == "OK"

    refute_receive _any
  end

  test "counter functionality" do
    counter = TestFluxter.start_counter("bar")

    assert is_pid(counter)

    assert TestFluxter.flush_counter(counter) == :ok
    refute_receive _any
    refute_alive(counter)

    counter = TestFluxter.start_counter("foo", bar: "baz")

    assert TestFluxter.increment_counter(counter, 2) == :ok
    refute_receive _any

    assert TestFluxter.increment_counter(counter, 1) == :ok
    refute_receive _any

    assert TestFluxter.flush_counter(counter) == :ok
    assert_receive {:echo, "foo,bar=baz value=3i"}

    refute_receive _any
    refute_alive(counter)

    counter = TestFluxter.start_counter("qux", [], bar: "baz")

    assert TestFluxter.increment_counter(counter, 1.0) == :ok
    refute_receive _any

    assert TestFluxter.flush_counter(counter) == :ok
    payload = "qux value=#{Float.to_string(1.0)},bar=\"baz\""
    assert_receive {:echo, ^payload}

    refute_receive _any
    refute_alive(counter)

    parent = self()

    spawn(fn ->
      counter = TestFluxter.start_counter("bar")
      send(parent, {:counter, counter})
      exit(:timeout)
    end)

    assert_receive {:counter, counter}
    refute_alive(counter)
  end

  defp refute_alive(pid) do
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, _, _, _}, 500
  end

  def sleep_and_return(term) do
    :timer.sleep(100)
    term
  end
end
