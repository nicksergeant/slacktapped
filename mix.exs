defmodule Slacktapped.Mixfile do
  use Mix.Project

  def project do
    [
      app: :slacktapped,
      build_embedded: Mix.env == :prod,
      deps: deps(),
      docs: [extras: [
        "README.md": [path: "readme", title: "Readme"]
      ]],
      elixir: "~> 1.3",
      homepage_url: "http://slacktapped.com",
      name: "Slacktapped",
      source_url: "https://github.com/nicksergeant/slacktapped",
      start_permanent: Mix.env == :prod,
      version: "1.0.0",
   ]
  end

  def application do
    [
      applications: [
        :beersearch,
        :cowboy,
        :httpotion,
        :logger,
        :plug,
        :quantum,
        :redix
      ],
      mod: {Slacktapped, []}
    ]
  end

  defp deps do
    [
      {:beersearch, "~> 0.0.8"},
      {:cowboy, "~> 1.0.0"},
      {:ex_doc, "~> 0.12", only: :dev},
      {:httpotion, "~> 3.0.0"},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:plug, "~> 1.0"},
      {:poison, "~> 2.0"},
      {:redix, ">= 0.4.0"},
      {:quantum, ">= 1.7.1"}
    ]
  end
end
