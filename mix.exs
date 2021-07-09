defmodule SudoBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :sudo_bot,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Bot.Application, []}
    ]
  end

  defp deps do
    [
      {:nostrum, "~> 0.4"},
      {:poison, "~> 3.1"}
    ]
  end
end
