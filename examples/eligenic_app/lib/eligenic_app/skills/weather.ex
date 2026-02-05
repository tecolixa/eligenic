defmodule EligenicApp.Skills.Weather do
  @moduledoc """
  Skill for retrieving real-time weather data and forecasts.
  Utilizes Eligenic.Tool introspection for automatic schema generation.
  """
  use Eligenic.Skill

  # -----------------------------------------------------------------------------
  # 🌐 Capabilities: Weather Intelligence
  # -----------------------------------------------------------------------------

  @doc "Gets the current temperature for a city"
  @spec get_temperature(city :: String.t()) :: String.t()
  def get_temperature(city) do
    "The temperature in #{city} is 22°C and sunny."
  end

  @doc "Gets the forecast for a city"
  @spec get_forecast(city :: String.t(), days :: integer()) :: String.t()
  def get_forecast(city, days) do
    "The forecast for #{city} over the next #{days} days is mostly clear."
  end

  # -----------------------------------------------------------------------------
  # 🛠️ Definition: Skill Contract
  # -----------------------------------------------------------------------------

  @impl true
  def tools do
    [
      Eligenic.Tool.introspect(__MODULE__, :get_temperature) |> elem(1),
      Eligenic.Tool.introspect(__MODULE__, :get_forecast) |> elem(1)
    ]
  end

  @impl true
  def execute(name, args) do
    # Map from tool name back to function call
    function_name = String.split(name, ".") |> List.last() |> String.to_existing_atom()
    Eligenic.Tool.execute(__MODULE__, function_name, args)
  end
end
