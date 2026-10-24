defmodule Airbrakex.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Finch pool for posting notices (own pool, so that the logger backend
      # works independently of the host app's supervision tree)
      {Finch, name: Airbrakex.Finch}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Airbrakex.Supervisor)
  end
end
