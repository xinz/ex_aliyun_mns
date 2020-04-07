defmodule ExAliyun.MNS.Parser do
  @moduledoc false

  def parse({:ok, %{body: body, url: url} = response}, "CreateQueue")
      when body == ""
      when body == nil do
    body = %{
      "request_id" => extract_request_id(response.headers),
      "queue_url" => url
    }
    response = parse_response(response, body)
    {:ok, response}
  end

  def parse({:ok, %{body: body, url: url} = response}, "CreateTopic")
      when body == ""
      when body == nil do
    body = %{
      "request_id" => extract_request_id(response.headers),
      "topic_url" => url
    }
    response = parse_response(response, body)
    {:ok, response}
  end

  def parse({:ok, %{body: body} = response}, _action)
      when body == ""
      when body == nil do
    use_request_id_when_body_nil(response)
  end

  def parse({:ok, %{body: body, status: status} = response}, _action)
      when body != "" and (status >= 200 and status < 400)
      when body != nil and (status >= 200 and status < 400) do
    {:ok, body} = SAXMap.from_string(body)
    response = parse_response(response, decode_message_body(body))
    {:ok, response}
  end

  def parse({:ok, %{body: body, status: status} = response}, _action)
      when body != "" and (status >= 400 and status <= 502)
      when body != nil and (status >= 400 and status <= 502) do
    # fail cases
    {:ok, body} = SAXMap.from_string(body)
    response = parse_response(response, body)
    {:error, response}
  end

  def parse(value, _), do: value

  def encode_message_body(message_body) when is_bitstring(message_body) do
    Base.encode64(message_body)
  end
  def encode_message_body(message) when is_list(message) do
    message_body = encode_message_body(message[:message_body])
    Keyword.put(message, :message_body, message_body)
  end

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

  defp decode_message_body(%{"Message" => %{"MessageBody" => message_body} = message} = body) do
    message = Map.put(message, "MessageBody", Base.decode64!(message_body))
    Map.put(body, "Message", message)
  end
  defp decode_message_body(%{"Messages" => %{"Message" => %{"MessageBody" => message_body} = message}} = body) when is_map(message) do
    message = Map.put(message, "MessageBody", Base.decode64!(message_body))
    Map.put(body, "Messages", [message])
  end
  defp decode_message_body(%{"Messages" => %{"Message" => messages}} = body) when is_list(messages) do
    messages =
      Enum.map(messages, fn
        %{"MessageBody" => message_body} = message ->
          Map.put(message, "MessageBody", Base.decode64!(message_body))
        message ->
          message
      end)
    Map.put(body, "Messages", messages)
  end
  defp decode_message_body(body) do
    body
  end

end
