defmodule ExAliyun.MNS.Client do
  @moduledoc false

  require Logger

  alias ExAliyun.MNS.{Xml, Parser, Application}

  def request(%{action: action} = operation, config, http_opts \\ []) do
    operation
    |> send_request(config, http_opts)
    |> parse_response(action)
  end

  defp send_request(
         %{action: "CreateQueue", params: %{queue_name: queue_name} = params} = _operation,
         config,
         http_opts
       ) do
    body = Xml.generate_queue(params)

    config
    |> new_client(http_opts)
    |> put("/queues/#{queue_name}", body)
  end

  defp send_request(
         %{action: "SetQueueAttributes", params: %{queue_url: queue_url} = params},
         config,
         http_opts
       ) do
    body = Xml.generate_queue(params)

    config
    |> new_client(http_opts)
    |> put("#{queue_url}", body, query: [{"metaoverride", true}])
  end

  defp send_request(
         %{action: "GetQueueAttributes", params: %{queue_url: queue_url}},
         config,
         http_opts
       ) do
    config
    |> new_client(http_opts)
    |> get(queue_url)
  end

  defp send_request(%{action: "ListQueues", headers: headers}, config, http_opts) do
    config
    |> new_client(http_opts)
    |> get("/queues", headers: headers)
  end

  defp send_request(%{action: "DeleteQueue", params: %{queue_url: queue_url}}, config, http_opts) do
    config
    |> new_client(http_opts)
    |> delete(queue_url)
  end

  defp send_request(
         %{action: "SendMessage", params: %{queue_url: queue_url} = params},
         config,
         http_opts
       ) do
    body = Xml.generate_message(params)

    config
    |> new_client(http_opts)
    |> post("#{queue_url}/messages", body)
  end

  defp send_request(
         %{action: "BatchSendMessage", params: %{queue_url: queue_url, messages: messages}},
         config,
         http_opts
       ) do
    body = Xml.generate_messages(messages)

    config
    |> new_client(http_opts)
    |> post("#{queue_url}/messages", body)
  end

  defp send_request(
         %{
           action: "DeleteMessage",
           params: %{queue_url: queue_url, receipt_handle: receipt_handle}
         },
         config,
         http_opts
       ) do
    config
    |> new_client(http_opts)
    |> delete("#{queue_url}/messages", query: [{"ReceiptHandle", receipt_handle}])
  end

  defp send_request(
         %{
           action: "BatchDeleteMessage",
           params: %{queue_url: queue_url, receipt_handles: receipt_handles}
         },
         config,
         http_opts
       ) do
    body = Xml.generate_receipt_handles(receipt_handles)

    config
    |> new_client(http_opts)
    |> delete("#{queue_url}/messages", body: body)
  end

  defp send_request(
         %{action: "ReceiveMessage", params: %{queue_url: queue_url} = params},
         config,
         http_opts
       ) do
    number = Map.get(params, :number)
    wait_time_seconds = Map.get(params, :wait_time_seconds)

    query = format_query([{"numOfMessages", number}, {"waitseconds", wait_time_seconds}])

    opts =
      if wait_time_seconds != nil, do: [timeout: (wait_time_seconds + 10) * 1000], else: http_opts

    config
    |> new_client(opts)
    |> get("#{queue_url}/messages", query: query)
  end

  defp send_request(
         %{action: "PeekMessage", params: %{queue_url: queue_url} = params},
         config,
         http_opts
       ) do
    number = Map.get(params, :number)
    query = format_query([{"peekonly", true}, {"numOfMessages", number}])

    config
    |> new_client(http_opts)
    |> get("#{queue_url}/messages", query: query)
  end

  defp send_request(
         %{
           action: "ChangeMessageVisibility",
           params: %{
             queue_url: queue_url,
             receipt_handle: receipt_handle,
             visibility_timeout: visibility_timeout
           }
         },
         config,
         http_opts
       ) do
    query = [{"receiptHandle", receipt_handle}, {"visibilityTimeout", visibility_timeout}]

    config
    |> new_client(http_opts)
    |> put("#{queue_url}/messages", nil, query: query)
  end

  defp send_request(
         %{action: "CreateTopic", params: %{topic_name: topic_name} = params},
         config,
         http_opts
       ) do
    body = Xml.generate_topic(params)

    config
    |> new_client(http_opts)
    |> put("/topics/#{topic_name}", body)
  end

  defp send_request(
         %{action: "SetTopicAttributes", params: %{topic_url: topic_url} = params},
         config,
         http_opts
       ) do
    body = Xml.generate_topic(params)

    config
    |> new_client(http_opts)
    |> put("#{topic_url}", body, query: [{"metaoverride", true}])
  end

  defp send_request(
         %{action: "GetTopicAttributes", params: %{topic_url: topic_url}},
         config,
         http_opts
       ) do
    config
    |> new_client(http_opts)
    |> get(topic_url)
  end

  defp send_request(%{action: "DeleteTopic", params: %{topic_url: topic_url}}, config, http_opts) do
    config
    |> new_client(http_opts)
    |> delete(topic_url)
  end

  defp send_request(%{action: "ListTopics", headers: headers}, config, http_opts) do
    config
    |> new_client(http_opts)
    |> get("/topics", headers: headers)
  end

  defp send_request(
         %{
           action: "Subscribe",
           params: %{topic_url: topic_url, subscription_name: subscription_name} = params
         },
         config,
         http_opts
       ) do
    body = Xml.generate_subscription(params)

    config
    |> new_client(http_opts)
    |> put("#{subscription_url(topic_url, subscription_name)}", body)
  end

  defp send_request(
         %{
           action: "SetSubscriptionAttributes",
           params: %{topic_url: topic_url, subscription_name: subscription_name} = params
         },
         config,
         http_opts
       ) do
    body = Xml.generate_subscription(params)

    config
    |> new_client(http_opts)
    |> put("#{subscription_url(topic_url, subscription_name)}", body,
      query: [{"metaoverride", true}]
    )
  end

  defp send_request(
         %{
           action: "GetSubscriptionAttributes",
           params: %{topic_url: topic_url, subscription_name: subscription_name}
         },
         config,
         http_opts
       ) do
    config
    |> new_client(http_opts)
    |> get("#{subscription_url(topic_url, subscription_name)}")
  end

  defp send_request(
         %{
           action: "Unsubscribe",
           params: %{topic_url: topic_url, subscription_name: subscription_name}
         },
         config,
         http_opts
       ) do
    config
    |> new_client(http_opts)
    |> delete("#{subscription_url(topic_url, subscription_name)}")
  end

  defp send_request(
         %{action: "ListSubscriptions", headers: headers, params: %{topic_url: topic_url}},
         config,
         http_opts
       ) do
    config
    |> new_client(http_opts)
    |> get("#{topic_url}/subscriptions", headers: headers)
  end

  defp send_request(
         %{action: "PublishMessage", params: %{topic_url: topic_url} = params},
         config,
         http_opts
       ) do
    body = Xml.generate_topic_message(params)

    config
    |> new_client(http_opts)
    |> post("#{topic_url}/messages", body)
  end

  defp new_client(config, opts) do
    middleware = [
      {Tesla.Middleware.BaseUrl, config.host},
      {Tesla.Middleware.Retry, delay: 500, max_retries: 10, should_retry: &match_should_retry?/1},
      {ExAliyun.MNS.Http.Middleware, config}
    ]

    timeout = Keyword.get(opts, :timeout, 15_000)

    adapter = {
      Tesla.Adapter.Finch,
      name: Application.http_name(), receive_timeout: timeout
    }

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

  defp match_should_retry?({:error, :closed}), do: true
  defp match_should_retry?({:error, :timeout}), do: true
  defp match_should_retry?({:error, "socket closed"}), do: true
  defp match_should_retry?({:error, "timeout"}), do: true

  defp match_should_retry?({:error, error}) when is_atom(error) do
    Logger.error(fn ->
      "ExAliyunMNS occurs an unknown error: #{inspect(error)}, will retry it."
    end)

    true
  end

  defp match_should_retry?(_), do: false
end
