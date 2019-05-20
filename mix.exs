defmodule AblySseDemo.MixProject do
  use Mix.Project

  def project do
    [
      app: :ably_sse_demo,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AblySseDemo, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:eventsource_ex, "~> 0.0.2"},
      {:poison, "~> 4.0.1"}
    ]
  end
end
