defmodule ExAliyun.MNS.Http.Middleware do
  @moduledoc false

  @behaviour Tesla.Middleware

  @content_type "text/xml;charset=utf-8"

  @impl true
  def call(env, next, config) do
    env
    |> put_required_headers(config)
    |> Tesla.run(next)
  end

  defp put_required_headers(env, config) do
    date = now()

    headers = [
      {"x-mns-version", "2015-06-06"},
      {"content-type", @content_type},
      {"date", date},
      {"host", extract_host(config.host)},
    ]

    headers = content_length_to_headers(headers, env.body)

    authorization = "MNS #{config.access_key_id}:#{signature(env, config, date, headers)}"

    Tesla.put_headers(env, [{"authorization", authorization} | headers])
  end

  defp signature(env, config, date, headers) do
    method = Atom.to_string(env.method) |> String.upcase()
    uri = extract_uri(env, config)
    mns_headers_str = extract_mns_headers(headers ++ env.headers)
    str_to_sign = "#{method}\n\n#{@content_type}\n#{date}\n#{mns_headers_str}\n#{uri}"
    Base.encode64(:crypto.hmac(:sha, config.access_key_secret, str_to_sign))
  end

  defp now() do
    Timex.format!(Timex.now(), "%a, %d %b %Y %H:%M:%S GMT", :strftime)
  end

  defp extract_host(host) do
    [_http_scheme, host] = String.split(host, "://", parts: 2)
    host
  end

  defp extract_uri(env, config) do
    path = String.replace(env.url, config.host, "")
    encoded_query = extract_encoded_query(env.query)
    URI.to_string(%URI{path: path, query: encoded_query})
  end

  defp extract_encoded_query([]) do
    nil
  end

  defp extract_encoded_query(query) do
    URI.encode_query(query)
  end

  defp extract_mns_headers(headers) do
    headers
    |> Enum.reduce([], fn {key, value}, acc ->
      downcase_key = String.downcase(key)
      if String.starts_with?(downcase_key, "x-mns-"), do: [{downcase_key, value} | acc], else: acc
    end)
    |> Enum.sort(fn {k1, _}, {k2, _} -> k1 <= k2 end)
    |> Enum.map(fn {key, value} ->
      "#{key}:#{value}"
    end)
    |> Enum.join("\n")
  end

  defp content_length_to_headers(headers, nil) do
    headers
  end
  defp content_length_to_headers(headers, body) do
    [{"content-length", "#{String.length(body)}"} | headers]
  end

end
