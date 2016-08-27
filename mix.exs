defmodule Slacktappdex.Mixfile do
  use Mix.Project

  def project do
    [app: :slacktappdex,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [
      applications: [
        :httpotion,
        :logger
      ]
    ]
  end

  defp deps do
    [
      {:httpotion, "~> 3.0.0"}
    ]
  end
end
