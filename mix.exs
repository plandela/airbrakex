defmodule Airbrakex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :airbrakex,
      version: "0.0.6",
      elixir: "~> 1.10",
      description: "Airbrake Elixir Notifier",
      package: package(),
      deps: deps()
    ]
  end

  def package do
    [
      maintainers: ["Michał Kalbarczyk"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/fazibear/airbrakex"}
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.2"},
      {:plug, ">= 0.13.0 and < 2.0.0"}
    ]
  end
end
