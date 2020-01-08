defmodule ExAliyun.MNS.Parser do
  @moduledoc false

  def parse({:ok, %{body: nil, url: url} = response}, "CreateQueue") do
    body = %{
      "request_id" => extract_request_id(response.headers),
      "queue_url" => url
    }
    response = parse_response(response, body)
    {:ok, response}
  end

  def parse({:ok, %{body: nil, url: url} = response}, "CreateTopic") do
    body = %{
      "request_id" => extract_request_id(response.headers),
      "topic_url" => url
    }
    response = parse_response(response, body)
    {:ok, response}
  end

  def parse({:ok, %{body: nil} = response}, _action) do
    use_request_id_when_body_nil(response)
  end

  def parse({:ok, %{body: body, status: status} = response}, _action) when body != nil and (status >= 200 and status < 400) do
    {:ok, body} = SAXMap.from_string(body)
    response = parse_response(response, body)
    {:ok, response}
  end

  def parse({:ok, %{body: body, status: status} = response}, _action) when body != nil and (status >= 400 and status <= 502) do
    # fail cases
    {:ok, body} = SAXMap.from_string(body)
    response = parse_response(response, body)
    {:error, response}
  end

  def parse(value, _), do: value

  defp parse_response(response, body) do
    response
    |> remap_response()
    |> Map.put(:body, body)
  end

  defp remap_response(response) do
    Map.take(response, [:method, :url, :query, :headers, :body, :status, :opts])
  end

  defp extract_request_id(headers) do
    {_, request_id} = List.keyfind(headers, "x-mns-request-id", 0)
    request_id
  end

  defp use_request_id_when_body_nil(%{status: status} = response) when status >= 200 and status < 400 do
    body = %{
      "request_id" => extract_request_id(response.headers)
    }
    response = parse_response(response, body)
    {:ok, response}
  end
  defp use_request_id_when_body_nil(response) do
    body = %{
      "request_id" => extract_request_id(response.headers)
    }
    response = parse_response(response, body)
    {:error, response}
  end

end
