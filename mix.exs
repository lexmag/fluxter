defmodule Fluxter.Mixfile do
  use Mix.Project

  @version "0.9.0"
  @source_url "https://github.com/lexmag/fluxter"

  def project() do
    [
      app: :fluxter,
      version: @version,
      elixir: "~> 1.3",
      deps: deps(),

      # Hex
      package: package(),
      description: desc(),

      # Docs
      name: "Fluxter",
      docs: docs()
    ]
  end

  def application() do
    [applications: [:logger], env: [host: "127.0.0.1", port: 8092]]
  end

  defp desc() do
    "Fast and reliable InfluxDB writer for Elixir."
  end

  defp package() do
    [
      maintainers: ["Aleksei Magusev", "Andrea Leopardi"],
      licenses: ["ISC"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp deps() do
    [{:ex_doc, "~> 0.20.0", only: :dev}]
  end

  defp docs() do
    [
      main: "Fluxter",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md"
      ]
    ]
  end
end
