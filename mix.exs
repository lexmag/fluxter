defmodule Fluxter.Mixfile do
  use Mix.Project

  def project() do
    [app: :fluxter,
     name: "Fluxter",
     version: "0.7.0",
     elixir: "~> 1.2",
     package: package(),
     description: desc(),
     deps: deps()]
  end

  def application() do
    [
      applications: [:logger]
    ]
  end

  defp desc() do
    "An InfluxDB writer for Elixir"
  end

  defp package() do
    [maintainers: ["Aleksei Magusev", "Andrea Leopardi"],
     licenses: ["ISC"],
     links: %{"GitHub" => "https://github.com/lexmag/fluxter"}]
  end

  defp deps() do
    [{:ex_doc, "~> 0.15", only: :dev}]
  end
end
