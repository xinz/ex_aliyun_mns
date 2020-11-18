defmodule ExAliyun.MNS.Topic do
  @moduledoc false

  alias ExAliyun.MNS.{Operation, Parser}

  @spec create(topic_name :: String.t(), opts :: Keyword.t()) :: Operation.t()
  def create(topic_name, opts \\ []) do
    params =
      opts
      |> Map.new()
      |> Map.put(:topic_name, topic_name)

    operation(nil, "CreateTopic", params: params)
  end

  @spec set_topic_attributes(topic_url :: String.t(), opts :: Keyword.t()) :: Operation.t()
  def set_topic_attributes(topic_url, opts) do
    operation(topic_url, "SetTopicAttributes", params: Map.new(opts))
  end

  @spec get_topic_attributes(topic_url :: String.t()) :: Operation.t()
  def get_topic_attributes(topic_url) do
    operation(topic_url, "GetTopicAttributes")
  end

  @spec delete(topic_url :: String.t()) :: Operation.t()
  def delete(topic_url) do
    operation(topic_url, "DeleteTopic")
  end

  @spec list_topics(opts :: Keyword.t()) :: Operation.t()
  def list_topics(opts \\ []) do
    headers = ExAliyun.MNS.format_opts_to_headers(opts)
    operation(nil, "ListTopics", headers: headers)
  end

  @spec subscribe(
          topic_url :: String.t(),
          subscription_name :: String.t(),
          endpoint :: String.t(),
          opts :: Keyword.t()
        ) :: Operation.t()
  def subscribe(topic_url, subscription_name, endpoint, opts \\ []) do
    params =
      opts
      |> Map.new()
      |> Map.put(:endpoint, endpoint)
      |> Map.put(:subscription_name, subscription_name)

    operation(topic_url, "Subscribe", params: params)
  end

  @spec set_subscription_attributes(
          topic_url :: String.t(),
          subscription_name :: String.t(),
          notify_strategy :: String.t()
        ) :: Operation.t()
  def set_subscription_attributes(topic_url, subscription_name, notify_strategy)
      when notify_strategy == "BACKOFF_RETRY"
      when notify_strategy == "EXPONENTIAL_DECAY_RETRY" do
    params = %{notify_strategy: notify_strategy, subscription_name: subscription_name}
    operation(topic_url, "SetSubscriptionAttributes", params: params)
  end

  @spec get_subscription_attributes(topic_url :: String.t(), subscription_name :: String.t()) ::
          Operation.t()
  def get_subscription_attributes(topic_url, subscription_name) do
    operation(topic_url, "GetSubscriptionAttributes",
      params: %{subscription_name: subscription_name}
    )
  end

  @spec unsubscribe(topic_url :: String.t(), subscription_name :: String.t()) :: Operation.t()
  def unsubscribe(topic_url, subscription_name) do
    operation(topic_url, "Unsubscribe", params: %{subscription_name: subscription_name})
  end

  @spec list_subscriptions(topic_url :: String.t(), opts :: Keyword.t()) :: Operation.t()
  def list_subscriptions(topic_url, opts \\ []) do
    headers = ExAliyun.MNS.format_opts_to_headers(opts)
    operation(topic_url, "ListSubscriptions", headers: headers)
  end

  @spec publish_message(topic_url :: String.t(), message_body :: String.t(), opts :: Keyword.t()) ::
          Operation.t()
  def publish_message(topic_url, message_body, opts \\ []) do
    params =
      opts
      |> Map.new()
      |> transfer_publish_message_params(message_body)

    operation(topic_url, "PublishMessage", params: params)
  end

  defp transfer_publish_message_params(%{message_attributes: _} = map, message_body) do
    # `message_attributes` is only used for SMS or Email.
    Map.put(map, :message_body, filter_maybe_invalid_cdata(message_body))
  end

  defp transfer_publish_message_params(map, message_body) do
    Map.put(map, :message_body, Parser.encode_message_body(message_body))
  end

  defp operation(topic_url, action, opts \\ [])

  defp operation(nil, action, opts) do
    %Operation{
      action: action,
      params: opts[:params],
      headers: opts[:headers]
    }
  end

  defp operation(topic_url, action, opts) do
    params = Map.put(opts[:params] || %{}, :topic_url, topic_url)

    %Operation{
      action: action,
      params: params,
      headers: opts[:headers]
    }
  end

  defp filter_maybe_invalid_cdata(nil), do: nil

  defp filter_maybe_invalid_cdata(message_body) do
    # Refer https://en.wikipedia.org/wiki/CDATA#Nesting
    String.replace(message_body, "]]>", "]]]]><![CDATA[>")
  end
end
