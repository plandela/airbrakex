defmodule Airbrakex.Plug do
  defmacro __using__(_env) do
    quote do
      import Airbrakex.Plug
      use Plug.ErrorHandler

      # Exceptions raised on non-existant Plug routes are ignored
      defp handle_errors(conn, %{reason: %FunctionClauseError{function: :do_match}} = ex) do
        nil
      end

      if :code.is_loaded(Phoenix) do
        # Exceptions raised on non-existant Phoenix routes are ignored
        defp handle_errors(conn, %{reason: %Phoenix.Router.NoRouteError{}} = ex) do
          nil
        end
      end

      defp handle_errors(conn, %{kind: kind, reason: reason, stack: stack}) do
        meta = build_metadata(conn)

        Airbrakex.ExceptionParser.parse(kind, reason, stack)
        |> Airbrakex.Notifier.notify(Map.to_list(meta))
      end
    end
  end

  def build_metadata(%Plug.Conn{} = conn) do
    conn =
      try do
        Plug.Conn.fetch_session(conn)
      rescue
        _e in [ArgumentError, KeyError] ->
          # just return conn and move on
          conn
      end

    conn =
      conn
      |> Plug.Conn.fetch_cookies()
      |> Plug.Conn.fetch_query_params()

    context = build_context(conn)

    %{
      context: context,
      session: conn.private.plug_session,
      params: conn.params |> filter_params,
      environment: build_environment(conn)
    }
  end

  defp filter_params(params) do
    params |> do_filter_params
  end

  @filter_parameters ~w(password)

  def do_filter_params(%{__struct__: mod} = struct) when is_atom(mod), do: struct

  def do_filter_params(%{} = map) do
    Enum.into(map, %{}, fn {k, v} ->
      if is_binary(k) && String.contains?(k, @filter_parameters) do
        {k, "[FILTERED]"}
      else
        {k, do_filter_params(v)}
      end
    end)
  end

  def do_filter_params([_ | _] = list), do: Enum.map(list, &do_filter_params(&1))
  def do_filter_params(other), do: other

  defp build_context(%Plug.Conn{} = conn) do
    {:ok, hostname} = :inet.gethostname()

    %{
      component: conn.request_path,
      action: conn.method,
      hostname: hostname |> to_string,
      version: Application.get_env(:airbrakex, :version),
      url: get_url(conn),
      rootDirectory: Application.app_dir(Application.get_env(:airbrakex, :app_name)),
      userAgent:
        conn.req_headers |> List.keyfind("user-agent", 0, {"user-agent", "undefined"}) |> elem(1)
    }
    |> Map.merge(build_user(conn))
  end

  defp build_user(%{
         assigns: %{
           auth_info: %{
             user_id: user_id,
             username: username,
             name: name,
             email: email
           }
         }
       }) do
    %{userId: user_id, userUsername: username, userName: name, userEmail: email}
  end

  defp build_user(%{
         assigns: %{
           auth_info: %{
             user_id: user_id
           }
         }
       }) do
    %{userId: user_id}
  end

  defp build_user(_) do
    %{}
  end

  defp build_environment(%Plug.Conn{} = _conn) do
    %{}
  end

  defp get_url(conn) do
    conn.private.phoenix_endpoint.url <> conn.request_path <> "?" <> conn.query_string
  end
end
