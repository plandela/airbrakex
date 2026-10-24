defmodule Airbrakex.NotifierTest do
  use ExUnit.Case

  setup do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, active: false, packet: :raw, reuseaddr: true])
    {:ok, port} = :inet.port(socket)

    Application.put_env(:airbrakex, :endpoint, "http://localhost:#{port}")
    on_exit(fn -> Application.delete_env(:airbrakex, :endpoint) end)

    %{socket: socket}
  end

  test "posts the notice to the endpoint", %{socket: socket} do
    test_pid = self()

    Task.start_link(fn ->
      {:ok, client} = :gen_tcp.accept(socket)
      send(test_pid, {:request, read_request(client, "")})
      :ok = :gen_tcp.send(client, "HTTP/1.1 201 Created\r\ncontent-length: 2\r\n\r\n{}")
    end)

    assert {:ok, %Finch.Response{status: 201}} =
             Airbrakex.Notifier.notify(%{type: "Error", message: "boom"},
               project_id: "id1",
               project_key: "key1",
               session: %{id: 1}
             )

    assert_receive {:request, {head, body}}
    assert head =~ "POST /api/v3/projects/id1/notices?key=key1 HTTP/1.1"
    assert head =~ ~r/content-type: application\/json/i

    assert %{
             "errors" => [%{"type" => "Error", "message" => "boom"}],
             "session" => %{"id" => 1},
             "context" => %{"language" => "Elixir"},
             "notifier" => %{"name" => "Airbrakex"}
           } = Jason.decode!(body)
  end

  test "returns the error when the endpoint is not reachable", %{socket: socket} do
    :gen_tcp.close(socket)

    assert %Finch.TransportError{reason: :econnrefused} =
             Airbrakex.Notifier.notify(%{type: "Error", message: "boom"},
               project_id: "id1",
               project_key: "key1"
             )
  end

  # reads the request's head and body (by its content-length)
  defp read_request(client, buffer) do
    case String.split(buffer, "\r\n\r\n", parts: 2) do
      [head, body] ->
        [_, length] = Regex.run(~r/content-length: (\d+)/i, head)
        {head, read_body(client, body, String.to_integer(length))}

      [_] ->
        {:ok, data} = :gen_tcp.recv(client, 0, 5_000)
        read_request(client, buffer <> data)
    end
  end

  defp read_body(_client, body, length) when byte_size(body) >= length, do: body

  defp read_body(client, body, length) do
    {:ok, data} = :gen_tcp.recv(client, 0, 5_000)
    read_body(client, body <> data, length)
  end
end
