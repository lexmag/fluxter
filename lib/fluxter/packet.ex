defmodule Fluxter.Packet do
  @moduledoc false

  use Bitwise

  def header({n1, n2, n3, n4}, port) do
    [band(bsr(port, 8), 0xFF),
     band(port, 0xFF),
     band(n1, 0xFF),
     band(n2, 0xFF),
     band(n3, 0xFF),
     band(n4, 0xFF)]
  end

  def build(header, name, tags, fields, nil) do
    tags   = encode_tags(tags)
    fields = encode_fields(fields)
    [header, encode_key(name), tags, ?\s, fields]
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