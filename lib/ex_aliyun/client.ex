defmodule ExAliyun.MNS.Client do
  @moduledoc false

  alias ExAliyun.MNS.{Xml, Parser}

  @timeout_seconds 10_000

  def request(%{action: :create_queue, params: %{queue_name: queue_name} = params} = _operation, config) do
    body = Xml.generate_queue(params)

    config
    |> new_client()
    |> put("/queues/#{queue_name}", body)
    |> parse_response(:create_queue)
  end
  def request(%{action: :set_queue_attributes, params: %{queue_url: queue_url} = params}, config) do
    body = Xml.generate_queue(params)

    config
    |> new_client()
    |> put("#{queue_url}", body, query: [{"metaoverride", true}])
    |> parse_response(:set_queue_attributes)
  end
  def request(%{action: :get_queue_attributes, params: %{queue_url: queue_url}}, config) do
    config
    |> new_client()
    |> get(queue_url)
    |> parse_response(:get_queue_attributes)
  end
  def request(%{action: :list_queues, headers: headers}, config) do
    config
    |> new_client()
    |> get("/queues", headers: headers)
    |> parse_response(:list_queues)
  end
  def request(%{action: :delete_queue, params: %{queue_url: queue_url}}, config) do
    config
    |> new_client()
    |> delete(queue_url)
    |> parse_response(:delete_queue)
  end
  def request(%{action: :send_message, params: %{queue_url: queue_url} = params}, config) do
    body = Xml.generate_message(params)

    config
    |> new_client()
    |> post("#{queue_url}/messages", body)
    |> parse_response(:send_message)
  end
  def request(%{action: :batch_send_message, params: %{queue_url: queue_url, messages: messages}}, config) do
    body = Xml.generate_messages(messages)

    config
    |> new_client()
    |> post("#{queue_url}/messages", body)
    |> parse_response(:send_messages)
  end
  def request(%{action: :delete_message, params: %{queue_url: queue_url, receipt_handle: receipt_handle}}, config) do
    config
    |> new_client()
    |> delete("#{queue_url}/messages", query: [{"ReceiptHandle", receipt_handle}])
    |> parse_response(:delete_message)
  end
  def request(%{action: :batch_delete_message, params: %{queue_url: queue_url, receipt_handles: receipt_handles}}, config) do
    body = Xml.generate_receipt_handles(receipt_handles)
    config
    |> new_client()
    |> delete("#{queue_url}/messages", body: body)
    |> parse_response(:batch_delete_message)
  end
  def request(%{action: :receive_message, params: %{queue_url: queue_url, number: number, wait_time_seconds: wait_time_seconds}}, config) do
    query = format_query([{"numOfMessages", number}, {"waitseconds", wait_time_seconds}])

    opts = if wait_time_seconds != nil, do: [timeout: (wait_time_seconds + 2) * 1000], else: []

    config
    |> new_client(opts)
    |> get("#{queue_url}/messages", query: query)
    |> parse_response(:receive_message)
  end
  def request(%{action: :peek_message, params: %{queue_url: queue_url, number: number}}, config) do
    query = format_query([{"peekonly", true}, {"numOfMessages", number}])

    config
    |> new_client()
    |> get("#{queue_url}/messages", query: query)
    |> parse_response(:peek_message)
  end
  def request(%{action: :change_message_visibility, params: %{queue_url: queue_url, receipt_handle: receipt_handle, visibility_timeout: visibility_timeout}}, config) do
    query = [{"receiptHandle", receipt_handle}, {"visibilityTimeout", visibility_timeout}]

    config
    |> new_client()
    |> put("#{queue_url}/messages", nil, query: query)
    |> parse_response(:change_message_visibility)
  end
  def request(%{action: :create_topic, params: %{topic_name: topic_name} = params}, config) do
    body = Xml.generate_topic(params) 

    config
    |> new_client()
    |> put("/topics/#{topic_name}", body)
    |> parse_response(:create_topic)
  end
  def request(%{action: :set_topic_attributes, params: %{topic_url: topic_url} = params}, config) do
    body = Xml.generate_topic(params)

    config
    |> new_client()
    |> put("#{topic_url}", body, query: [{"metaoverride", true}])
    |> parse_response(:set_topic_attributes)
  end
  def request(%{action: :get_topic_attributes, params: %{topic_url: topic_url}}, config) do
    config
    |> new_client()
    |> get(topic_url)
    |> parse_response(:get_topic_attributes)
  end
  def request(%{action: :delete_topic, params: %{topic_url: topic_url}}, config) do
    config
    |> new_client()
    |> delete(topic_url)
    |> parse_response(:delete_topic)
  end
  def request(%{action: :list_topics, headers: headers}, config) do
    config
    |> new_client()
    |> get("/topics", headers: headers)
    |> parse_response(:list_topics)
  end
  def request(%{action: :subscribe, params: %{topic_url: topic_url, subscription_name: subscription_name} = params}, config) do
    body = Xml.generate_subscription(params)

    config
    |> new_client()
    |> put("#{subscription_url(topic_url, subscription_name)}", body)
    |> parse_response(:subscribe)
  end
  def request(%{action: :set_subscription_attributes, params: %{topic_url: topic_url, subscription_name: subscription_name} = params}, config) do
    body = Xml.generate_subscription(params)

    config
    |> new_client()
    |> put("#{subscription_url(topic_url, subscription_name)}", body, query: [{"metaoverride", true}])
    |> parse_response(:set_subscription_attributes)
  end
  def request(%{action: :get_subscription_attributes, params: %{topic_url: topic_url, subscription_name: subscription_name}}, config) do
    config
    |> new_client()
    |> get("#{subscription_url(topic_url, subscription_name)}")
    |> parse_response(:get_subscription_attributes)
  end
  def request(%{action: :unsubscribe, params: %{topic_url: topic_url, subscription_name: subscription_name}}, config) do
    config
    |> new_client()
    |> delete("#{subscription_url(topic_url, subscription_name)}")
    |> parse_response(:unsubscribe)
  end
  def request(%{action: :list_subscriptions, headers: headers, params: %{topic_url: topic_url}}, config) do
    config
    |> new_client()
    |> get("#{topic_url}/subscriptions", headers: headers)
    |> parse_response(:list_subscriptions)
  end
  def request(%{action: :publish_message, params: %{topic_url: topic_url} = params}, config) do
    body = Xml.generate_topic_message(params)

    config
    |> new_client()
    |> post("#{topic_url}/messages", body)
    |> parse_response(:publish_message)
  end

  defp new_client(config, opts \\ [timeout: @timeout_seconds]) do
    middleware = [
      {Tesla.Middleware.BaseUrl, config.host},
      {ExAliyun.MNS.Http.Middleware, config}
    ]
    adapter = {Tesla.Adapter.Mint, opts}
    Tesla.client(middleware, adapter)
  end

  defp put(client, url, body, opts \\ []) do
    Tesla.put(client, url, body, opts)
  end

  defp get(client, url, opts \\ []) do
    Tesla.get(client, url, opts)
  end

  defp delete(client, url, opts \\ []) do
    Tesla.delete(client, url, opts)
  end

  defp post(client, url, body, opts \\ []) do
    Tesla.post(client, url, body, opts)
  end

  defp parse_response(env, action) do
    Parser.parse(env, action)
  end

  defp format_query(query) do
    format_query(query, [])
  end

  defp format_query([], result) do
    result
  end
  defp format_query([{_key, nil} | other], result) do
    format_query(other, result)
  end
  defp format_query([{key, value} | other], result) do
    format_query(other, [{key, value} | result])
  end

  defp subscription_url(topic_url, subscription_name) do
    "#{topic_url}/subscriptions/#{subscription_name}"
  end
end
