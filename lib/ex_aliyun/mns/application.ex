defmodule ExAliyun.MNS.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    Supervisor.start_link(child_spec(), strategy: :one_for_one)
  end

  def http_name() do
    __MODULE__.Finch
  end

  defp child_spec() do
    app = Application.get_application(__MODULE__)
    host = Application.get_env(app, :host, :default)

    pool_size = Application.get_env(app, :pool_size, 100)
    pool_count = Application.get_env(app, :pool_count, 1)

    [
      {
        Finch,
        name: http_name(),
        pools: %{
          host => [size: pool_size, count: pool_count]
        }
      }
    ]
  end
end
