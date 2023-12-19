defmodule Fluxter.Packet do
  @moduledoc false

  def build(prefix, name, tags, fields) do
    tags = encode_tags(tags)
    fields = encode_fields(fields)
    [prefix, encode_key(name), tags, ?\s, fields]
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

  defp encode_key(nil), do: "nil"

  defp encode_key(val) do
    val
    |> to_string()
    |> String.trim()
    |> case do
      "" ->
        "empty"

      other ->
        other
        |> to_string()
        |> String.trim_leading("_")
        |> escape(~c" ,")
    end
  end

  defp encode_value(nil), do: inspect("nil")

  defp encode_value(val) do
    cond do
      is_float(val) ->
        Float.to_string(val)

      is_integer(val) ->
        [Integer.to_string(val), ?i]

      is_boolean(val) ->
        Atom.to_string(val)

      is_binary(val) ->
        val
        |> String.trim()
        |> case do
          "" -> "\"empty\""
          other -> [?\", escape(other, ~c"\""), ?\"]
        end

      true ->
        val
        |> inspect()
        |> encode_value()
    end
  end

  defp escape(val, reserved) do
    for <<char <- val>>, into: "" do
      if char in reserved, do: <<?\\, char>>, else: <<char>>
    end
  end
end
