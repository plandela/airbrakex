defmodule Airbrakex.PlugTest do
  use ExUnit.Case
  use Plug.Test
  alias Airbrakex.Plug

  defmodule TestEndpoint do
    def url do
      "example.com"
    end
  end

  test "generates metadata" do
    conn =
      conn(:post, "/")
      |> put_phoenix_privates
      |> Map.put(:params, %{"username" => "en user"})

    Application.put_env(:airbrakex, :app_name, :airbrakex)
    metadata = Plug.build_metadata(conn)
    assert %{context: %{
                action: "POST", component: "/",
                url: "example.com/?", userAgent: "undefined", version: nil},
             environment: %{},
             params: %{"username" => "en user"},
             session: %{"user_id" => 1}} = metadata
  end

  test "filters passwords from params" do
    Application.put_env(:airbrakex, :app_name, :airbrakex)

    conn =
      conn(:post, "/")
      |> put_phoenix_privates
      |> Map.put(:params, %{"password" => "en password"})

    metadata = Plug.build_metadata(conn)
    assert %{params: %{"password" => "[FILTERED]"}} = metadata

    conn =
      conn(:post, "/")
      |> put_phoenix_privates
      |> Map.put(:params, %{"user" => %{"password" => "en password"}})

    metadata = Plug.build_metadata(conn)
    assert %{params: %{"user" => %{"password" => "[FILTERED]"}}} = metadata

    conn =
      conn(:post, "/")
      |> put_phoenix_privates
      |> Map.put(:params, %{"user" => [%{"password" => "en password"}]})

    metadata = Plug.build_metadata(conn)
    assert %{params: %{"user" => [%{"password" => "[FILTERED]"}]}} = metadata
  end

  defp put_phoenix_privates(conn) do
    conn
    |> put_private(:phoenix_controller, Airbrakex.TestController)
    |> put_private(:phoenix_action, :show)
    |> put_private(:phoenix_format, "json")
    |> put_private(:phoenix_endpoint, Airbrakex.PlugTest.TestEndpoint)
    |> put_private(:plug_session, %{"user_id" => 1})
    |> put_private(:plug_session_fetch, :done)
  end
end
