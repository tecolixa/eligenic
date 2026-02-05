defmodule Eligenic.MixProject do
  @moduledoc """
  Project configuration for the Eligenic framework.
  """
  use Mix.Project

  def project do
    [
      app: :eligenic,
      version: "0.1.0",
      description: "A pluggable, highly configurable Agentic framework for Elixir and Phoenix.",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [
        main: "Eligenic",
        extras: ["README.md"]
      ]
    ]
  end

  # -----------------------------------------------------------------------------
  # 🏔️ Lifecycle: Activation
  # -----------------------------------------------------------------------------

  def application do
    [
      extra_applications: [:logger],
      mod: {Eligenic.Application, []}
    ]
  end

  # -----------------------------------------------------------------------------
  # 🍱 Metadata: Hex Package
  # -----------------------------------------------------------------------------

  defp package do
    [
      name: "eligenic",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/apporay/eligenic"}
    ]
  end

  # -----------------------------------------------------------------------------
  # 🛠️ Dependencies: Framework Core
  # -----------------------------------------------------------------------------

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:req, "~> 0.5.0"},
      {:telemetry, "~> 1.2"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end
