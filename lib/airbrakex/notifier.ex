defmodule Airbrakex.Notifier do
  use HTTPoison.Base

  @request_headers [{"Content-Type", "application/json"}]
  @default_endpoint "http://collect.airbrake.io"

  @info %{
    name: "Airbrakex",
    version: Airbrakex.Mixfile.project()[:version],
    url: Airbrakex.Mixfile.project()[:package][:links][:github]
  }

  def notify(error, options \\ []) do
    payload =
      %{}
      |> add_notifier
      |> add_error(error)
      |> add_context(Keyword.get(options, :context))
      |> add(:session, Keyword.get(options, :session))
      |> add(:params, Keyword.get(options, :params))
      |> add(:environment, Keyword.get(options, :environment, %{}))
      |> Jason.encode!()

    case post(url(options), payload, @request_headers) do
      {:ok, _} = res -> res
      {:error, error} -> IO.inspect(error)
    end
  end

  defp add_notifier(payload) do
    payload |> Map.put(:notifier, @info)
  end

  defp add_error(payload, nil), do: payload

  defp add_error(payload, error) do
    payload |> Map.put(:errors, [error])
  end

  defp add_context(payload, nil) do
    payload |> Map.put(:context, %{} |> context_with_defaults)
  end

  defp add_context(payload, context) do
    payload |> Map.put(:context, context |> context_with_defaults)
  end

  defp context_with_defaults(context) do
    context
    |> add_if_missing(:environment, Application.get_env(:airbrakex, :environment, Mix.env()))
    |> add_if_missing(:language, "Elixir")
  end

  defp add_if_missing(map, key, val) do
    if !map[key] do
      map |> Map.put(key, val)
    else
      map
    end
  end

  defp add(payload, _key, nil), do: payload
  defp add(payload, key, value), do: Map.put(payload, key, value)

  defp url(options) do
    project_id = Keyword.get(options, :project_id) || Application.get_env(:airbrakex, :project_id)

    project_key =
      Keyword.get(options, :project_key) || Application.get_env(:airbrakex, :project_key)

    endpoint = Application.get_env(:airbrakex, :endpoint, @default_endpoint)
    "#{endpoint}/api/v3/projects/#{project_id}/notices?key=#{project_key}"
  end
end
