defmodule ExAliyun.MNS.Config do
  @moduledoc false

  @common_config [
    :access_key_id,
    :access_key_secret,
    :host
  ]

  def new(opts \\ []) do
    opts
    |> Map.new()
    |> build_base()
    |> retrieve_runtime_config()
    |> validate()
  end

  defp build_base(overrides) do
    config = Application.get_all_env(:ex_aliyun_mns) |> Map.new() |> Map.take(@common_config)
    Map.merge(config, overrides)
  end

  defp retrieve_runtime_config(config) do
    Enum.reduce(config, config, fn
      {k, v}, config ->
        case retrieve_runtime_value(v) do
          result when is_map(result) -> Map.merge(config, result)
          value -> Map.put(config, k, value)
        end
    end)
  end

  defp retrieve_runtime_value({:system, env_key}) do
    System.fetch_env!(env_key)
  end

  defp retrieve_runtime_value(value), do: value

  defp validate(%{host: host, access_key_id: access_key_id, access_key_secret: access_key_secret} = config) do
    expect_valid_str(host, :host)
    expect_valid_str(access_key_id, :access_key_id)
    expect_valid_str(access_key_secret, :access_key_secret)

    config
  end
  defp validate(config) do
    raise ArgumentError, "got invalid config: #{inspect(config)}, please check required fields: `host`, `access_key_id`, and `access_key_secret`"
  end

  defp expect_valid_str(value, field) when is_bitstring(value) do
    if String.trim(value) != "" do
      :ok
    else
      raise ArgumentError, "got an invalid value: `#{inspect(value)}` for field: #{inspect(field)} when configure"
    end
  end
  defp expect_valid_str(nil, field) do
    raise ArgumentError, "got a nil value for field: `#{inspect(field)}` when configure"
  end
  defp expect_valid_str(value, field) do
    raise ArgumentError, "got a non-string value: `#{inspect(value)}` for field: #{inspect(field)} when configure"
  end
end
