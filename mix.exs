defmodule Fluxter.Mixfile do
  use Mix.Project

  @version_file Path.join(__DIR__, ".library_version")

  # a special module attribute that recompiles if targeted file has changed
  @external_resource @version_file

  @version (case Regex.run(~r/^v([\d\.\w-]+)/, File.read!(@version_file), capture: :all_but_first) do
              [version] -> version
              nil -> "0.0.0"
            end)

  def project() do
    [
      app: :fluxter,
      version: @version,
      elixir: "~> 1.5",
      deps: deps(),

      # Hex
      package: package(),
      description: desc(),

      # Docs
      name: "Fluxter"
    ]
  end

  def application() do
    [applications: [:logger], env: [host: "127.0.0.1", port: 8092]]
  end

  defp desc() do
    "High-performance and reliable InfluxDB writer for Elixir."
  end

  defp package() do
    [
      licenses: ["ISC"],
      # these files get packaged and published with the library
      files: ~w(lib .formatter.exs mix.exs README.md .library_version),
      organization: "cuatro",
      links: %{"GitHub" => "https://github.com/NFIBrokerage/beetrix"}
    ]
  end

  defp deps() do
    [{:ex_doc, "~> 0.20.0", only: :dev, runtime: false}]
  end
end
