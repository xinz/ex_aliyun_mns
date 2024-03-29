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

    authorization = "MNS #{config.access_key_id}:#{signature(env, config, date)}"

    headers =
      initialize_headers(date, config.host)
      |> add_content_length_to_headers(env.body)
      |> add_authorization_to_headers(authorization)

    Tesla.put_headers(env, headers)
  end

  defp signature(env, config, date) do
    method = Atom.to_string(env.method) |> String.upcase()
    uri = extract_uri(env, config)
    mns_headers_str = extract_mns_headers([mns_version_header() | env.headers])
    str_to_sign = "#{method}\n\n#{@content_type}\n#{date}\n#{mns_headers_str}\n#{uri}"
    Base.encode64(hmac_fun(:sha, config.access_key_secret).(str_to_sign))
  end

  # TODO: remove when we require OTP 22.1
  if Code.ensure_loaded?(:crypto) and function_exported?(:crypto, :mac, 4) do
    defp hmac_fun(digest, key), do: &:crypto.mac(:hmac, digest, key, &1)
  else
    defp hmac_fun(digest, key), do: &:crypto.hmac(digest, key, &1)
  end

  defp mns_version_header() do
    {"x-mns-version", "2015-06-06"}
  end

  defp initialize_headers(date, host) do
    [
      {"content-type", @content_type},
      {"date", date},
      {"host", extract_host(host)},
      mns_version_header()
    ]
  end

  defp now() do
    Timex.lformat!(Timex.now(), "%a, %d %b %Y %H:%M:%S GMT", "en", :strftime)
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

  defp extract_encoded_query([]), do: nil
  defp extract_encoded_query(query), do: URI.encode_query(query)

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

  defp add_content_length_to_headers(headers, nil), do: headers

  defp add_content_length_to_headers(headers, body) do
    [{"content-length", "#{String.length(body)}"} | headers]
  end

  defp add_authorization_to_headers(headers, authorization) do
    [{"authorization", authorization} | headers]
  end
end
