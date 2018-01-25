defmodule Fluxter.Packet do
  @moduledoc false

  use Bitwise

  otp_release = :erlang.system_info(:otp_release)
  @addr_family if(otp_release >= '19', do: [1], else: [])

  def header({n1, n2, n3, n4}, port) do
    true = Code.ensure_loaded?(:gen_udp)

    anc_data_part =
      if function_exported?(:gen_udp, :send, 5) do
        [0, 0, 0, 0]
      else
        []
      end

    @addr_family ++
      [
        band(bsr(port, 8), 0xFF),
        band(port, 0xFF),
        band(n1, 0xFF),
        band(n2, 0xFF),
        band(n3, 0xFF),
        band(n4, 0xFF)
      ] ++ anc_data_part
  end

  def build(header, name, tags, fields, unix_timestamp_ms) do
    tags = encode_tags(tags)
    fields = encode_fields(fields)

    case is_nil(unix_timestamp_ms) do
      true ->
        [header, encode_key(name), tags, ?\s, fields]

      false ->
        # Convert time to nanoseconds, which is the precision influxdb uses
        unix_timestamp_nano_secs =
          unix_timestamp_ms
          |> Kernel.*(1_000_000)
          |> Integer.to_string()

        [header, encode_key(name), tags, ?\s, fields, ?\s, unix_timestamp_nano_secs]
    end
  end

  defp encode_tags([]), do: ""

  defp encode_tags(tags) do
    for {key, val} <- Enum.sort_by(tags, &elem(&1, 0)) do
      [?,, encode_key(key), ?=, encode_key(val)]
    end
  end

  defp encode_fields(fields) do
    Enum.map_join(fields, ",", fn {key, val} ->
      [encode_key(key), ?=, encode_value(val)]
    end)
  end

  defp encode_key(val) do
    to_string(val) |> escape(' ,')
  end

  defp encode_value(val) do
    cond do
      is_float(val) ->
        Float.to_string(val)

      is_integer(val) ->
        [Integer.to_string(val), ?i]

      is_boolean(val) ->
        Atom.to_string(val)

      is_binary(val) ->
        [?\", escape(val, '"'), ?\"]
    end
  end

  defp escape(val, reserved) do
    for <<char <- val>>, into: "" do
      if char in reserved, do: <<?\\, char>>, else: <<char>>
    end
  end
end
