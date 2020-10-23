defmodule ExAliyun.MNS do
  @moduledoc """
  The official link to introduce [Alibaba Cloud Message Service](https://www.alibabacloud.com/help/doc-detail/27414.htm){:target="_blank"}.

  ## Queue APIs

    * `batch_send_message/2`
    * `batch_delete_message/3`
    * `change_message_visibility/4`
    * `create_queue/2`
    * `ensure_queue/2`
    * `delete_message/3`
    * `delete_queue/2`
    * `get_queue_attributes/2`
    * `list_queues/1`
    * `peek_message/2`
    * `send_message/3`
    * `set_queue_attributes/2`
    * `receive_message/2`

  ## Topic APIs

    * `create_topic/2`
    * `delete_topic/1`
    * `get_subscription_attributes/3`
    * `get_topic_attributes/1`
    * `list_subscriptions/2`
    * `list_topics/1`
    * `publish_topic_message/3`
    * `set_subscription_attributes/4`
    * `set_topic_attributes/2`
    * `subscribe/4`
    * `unsubscribe/3`
  """

  alias ExAliyun.MNS.{Topic, Queue, Client, Config}

  defmodule Operation do
    @moduledoc false
    defstruct [
      :params,
      :action,
      :headers
    ]
  end

  @type result :: {:ok, map()} | {:error, map()} | {:error, term()}

  @doc """
  Send HTTP request, NO need to directly call this function by default.

  The following options all are optional, but they are requeired to identify request's authorization in
  every operation request, we can set them as a global config:

  ```elixir
  config :ex_aliyun_mns,
    access_key_id: "",
    access_key_secret: "",
    host: ""
  ```

  Or set these option(s) via `config_overrides` option to dynamically set/override in each operation request.

  ## Config options

    * `access_key_id`, optional, the access key id of Alibaba Cloud RAM for MNS;
    * `access_key_secret`, optional, the access key secret of Alibaba Cloud RAM for MNS;
    * `host`, optional, the MNS's regions to request, the available regions can be found in MNS's console,
      e.g. "https://xxxx.mns.us-east-1.aliyuncs.com".

  ## Http options

    * `timeout`, optional, time in milliseconds, used when receiving data over a connection, default it `15_000`.
  """
  @spec request(operation :: Operation.t(), config_overrides :: Keyword.t()) :: result
  def request(operation, config_overrides \\ [], http_opts \\ []) do
    Client.request(operation, Config.new(config_overrides), http_opts)
  end

  @doc """
  Create a new message queue, the message queue name should be no more than 256 characters, and constituted by letters, digits, or hyphens (-), while the first character must be a letter.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/35129.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details;
    * `:delay_seconds`, optional, message sent to the queue can be consumed after `delay_seconds` seconds, the valid value range in 0..604800 (7 days), by default is 0 second;
    * `:maximum_message_size`, optional, maximum body length of a message sent to the queue, measured in bytes, by default is 65536 (64 KB);
    * `:message_retention_period`, optional, maximum lifetime of the message in the queue, measured in seconds,
       the valid value range in 60..604800 seconds, by default is 259200 (3 days);
    * `:visibility_timeout`, optional, the valid value range in 1..43200 seconds (12 hours), by default is 30 seconds;
    * `:polling_wait_seconds`, optional, the valid value range in 0..30 seconds, by default is 0 second;
    * `:logging_enabled`, optional, whether to enable MNS server logging, by default is false.
  """
  @spec create_queue(queue_name :: String.t(), opts :: Keyword.t()) :: result
  def create_queue(queue_name, opts \\ []) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])
    Queue.create(queue_name, opts) |> request(config_overrides)
  end

  @doc """
  Create a new message queue if it doesn't exist

  More details can be seen at:

    * `list_queues/0`, `list_queues/1`
    * `create_queue/1`, `create_queue/2`

  ## Options

    Support all the options of `list_queues/2`, `create_queue/2`
  """
  @spec ensure_queue(queue_name :: String.t(), opts :: Keyword.t()) ::
          {:error, :already_exists} | result
  def ensure_queue(queue, opts \\ []) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])
    list_queues_opts = [queue_name_prefix: queue, number: 1, config_overrides: config_overrides]

    {list_queues_opts, create_queue_opts} =
      case Keyword.pop(opts, :marker) do
        {nil, create_queue_opts} ->
          {list_queues_opts, create_queue_opts}

        {marker, create_queue_opts} ->
          {[{:marker, marker} | list_queues_opts], create_queue_opts}
      end

    case list_queues(list_queues_opts) do
      {:ok, %{body: body}} ->
        case get_in(body, ["Queues", "Queue"]) do
          %{"QueueName" => ^queue} -> true
          list when is_list(list) -> Enum.any?(list, &match?(^queue, &1["QueueName"]))
          _ -> false
        end

      error ->
        error
    end
    |> case do
      true ->
        {:error, :already_exists}

      false ->
        create_queue(queue, [{:config_overrides, config_overrides} | create_queue_opts])

      error ->
        error
    end
  end

  @doc """
  Modify attributes of a message queue.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/35130.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details;
    * `:delay_seconds`, optional, message sent to the queue can be consumed after `delay_seconds` seconds, the valid value range in 0..604800 (7 days), by default is 0 second;
    * `:maximum_message_size`, optional, maximum body length of a message sent to the queue, measured in bytes,
       by default is 65536 (64 KB);
    * `:message_retention_period`, optional, maximum lifetime of the message in the queue, measured in seconds,
       the valid value range in 60..604800 seconds, by default is 259200 (3 days);
    * `:visibility_timeout`, optional, the valid value range in 1..43200 seconds (12 hours), by default is 30 seconds;
    * `:polling_wait_seconds`, optional, the valid value range in 0..30 seconds, by default is 0 second;
    * `:logging_enabled`, optional, whether to enable MNS server logging, by default is false.
  """
  @spec set_queue_attributes(queue_url :: String.t(), opts :: Keyword.t()) :: result
  def set_queue_attributes(queue_url, opts \\ []) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])
    Queue.set_queue_attributes(queue_url, opts) |> request(config_overrides)
  end

  @doc """
  Get the attributes of a message queue.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/35131.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details.
  """
  @spec get_queue_attributes(queue_url :: String.t(), opts :: Keyword.t()) :: result
  def get_queue_attributes(queue_url, opts \\ []) do
    config_overrides = Keyword.get(opts, :config_overrides, [])
    Queue.get_queue_attributes(queue_url) |> request(config_overrides)
  end

  @doc """
  List the available message queues.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/35133.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details;
    * `:queue_name_prefix`, optional, search for the queue name starting with this prefix;
    * `:number`, optional, maximum number of results returned for a single request, the valid value range in 1..1000, by default is 1000;
    * `:marker`, optional, a similar pagination cursor when list a large queues list, which is acquired from the `NextMarker` returned in the previous request.
  """
  @spec list_queues(opts :: Keyword.t()) :: result
  def list_queues(opts \\ []) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])
    Queue.list_queues(opts) |> request(config_overrides)
  end

  @doc """
  Delete an existed message queue.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/35132.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details.
  """
  @spec delete_queue(queue_url :: String.t(), opts :: Keyword.t()) :: result
  def delete_queue(queue_url, opts \\ []) do
    config_overrides = Keyword.get(opts, :config_overrides, [])
    Queue.delete(queue_url) |> request(config_overrides)
  end

  @doc """
  Sand a message to MNS Queue.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/35134.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details;
    * `:delay_seconds`, optional, message sent to the queue can be consumed after `delay_seconds` seconds, the valid value range in 0..604800 (7 days), by default is 0 second;
    * `:priority`
  """
  @spec send_message(queue_url :: String.t(), message_body :: String.t(), opts :: Keyword.t()) ::
          result
  def send_message(queue_url, message_body, opts \\ []) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])
    Queue.send_message(queue_url, message_body, opts) |> request(config_overrides)
  end

  @type mns_batch_message ::
          String.t()
          | [
              {:message_body, String.t()},
              {:delay_seconds, 0..604_800},
              {:priority, 1..16}
            ]

  @doc """
  Send up to 16 messages to a MNS Queue in a single request.

  [Alibaba Cloud API Docs](https://help.aliyun.com/document_detail/35135.html){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details.
  """
  @spec batch_send_message(queue_url :: String.t(), messages :: [mns_batch_message]) :: result
  def batch_send_message(queue_url, messages, opts \\ []) when is_list(messages) do
    config_overrides = Keyword.get(opts, :config_overrides, [])
    Queue.batch_send_message(queue_url, messages) |> request(config_overrides)
  end

  @doc """
  Delete a message from a MNS Queue.

  [Alibaba Cloud API Docs](https://help.aliyun.com/document_detail/35138.html){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details.
  """
  @spec delete_message(queue_url :: String.t(), receipt_handle :: String.t(), opts :: Keyword.t()) ::
          result
  def delete_message(queue_url, receipt_handle, opts \\ []) do
    config_overrides = Keyword.get(opts, :config_overrides, [])
    Queue.delete_message(queue_url, receipt_handle) |> request(config_overrides)
  end

  @doc """
  Delete a list of messages from a MNS Queue in a single request.

  [Alibaba Cloud API Docs](https://help.aliyun.com/document_detail/35139.html){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details.
  """
  @spec batch_delete_message(
          queue_url :: String.t(),
          receipt_handles :: [String.t()],
          opts :: Keyword.t()
        ) :: result
  def batch_delete_message(queue_url, receipt_handles, opts \\ []) do
    config_overrides = Keyword.get(opts, :config_overrides, [])
    Queue.batch_delete_message(queue_url, receipt_handles) |> request(config_overrides)
  end

  @doc """
  Read message(s) from a MNS Queue.

  [Alibaba Cloud API Docs](https://help.aliyun.com/document_detail/35136.html){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details;
    * `:wait_time_seconds`, optional, the maximum wait time for polling message in current request, settable value range is 0..30 (seconds),
    if not set this option will use Queue's `polling_wait_seconds` attribute (see `create_queue/2`) as default.
    * `:number`, optional, receive up to 16 messages ([doc](https://help.aliyun.com/document_detail/35137.html)) from a MNS Queue in a single request, by default as 1.
  """
  @spec receive_message(queue_url :: String.t(), opts :: Keyword.t()) :: result
  def receive_message(queue_url, opts \\ []) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])
    Queue.receive_message(queue_url, opts) |> request(config_overrides)
  end

  @doc """
  View message(s) from a MNS Queue but do not change message(s) status.

  [Alibaba Cloud API Docs](https://help.aliyun.com/document_detail/35140.html){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details;
    * `:number`, optional, maximum number of messages can be viewed for the current operation ([see BatchPeekMessage doc](https://www.alibabacloud.com/help/doc-detail/35141.htm)), the default number is 1, the maximum number is 16.
  """
  @spec peek_message(queue_url :: String.t(), opts :: Keyword.t()) :: result
  def peek_message(queue_url, opts \\ []) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])
    Queue.peek_message(queue_url, opts) |> request(config_overrides)
  end

  @doc """
  Modify the next consumable time of a message which has been consumed and is still in `inactive` status. After `VisibilityTimeout` of the message is modified successfully, a new ReceiptHandle will be returned.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/35142.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details.
  """
  @spec change_message_visibility(
          queue_url :: String.t(),
          receipt_handle :: String.t(),
          visibility_timeout :: integer(),
          opts :: Keyword.t()
        ) :: result
  def change_message_visibility(queue_url, receipt_handle, visibility_timeout, opts \\ []) do
    config_overrides = Keyword.get(opts, :config_overrides, [])

    Queue.change_message_visibility(queue_url, receipt_handle, visibility_timeout)
    |> request(config_overrides)
  end

  @doc """
  Create a new topic, a topic name is a string of no more than 256 characters, including letters, numbers, and hyphens (-). It must start with a letter or number.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/27495.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details;
    * `:maximum_message_size`, optional, maximum body length of a message sent to the queue, measured in bytes, by default is 65536 (64 KB);
    * `:logging_enabled`, optional, whether to enable MNS server logging, by default is false.
  """
  @spec create_topic(topic_name :: String.t(), opts :: Keyword.t()) :: result
  def create_topic(topic_name, opts \\ []) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])
    Topic.create(topic_name, opts) |> request(config_overrides)
  end

  @doc """
  Modify the attributes of an existing topic.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/140704.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details;
    * `:maximum_message_size`, optional, maximum body length of a message sent to the queue, measured in bytes, by default is 65536 (64 KB);
    * `:logging_enabled`, optional, whether to enable MNS server logging, by default is false.
  """
  @spec set_topic_attributes(topic_url :: String.t(), opts :: Keyword.t()) :: result
  def set_topic_attributes(topic_url, opts) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])

    Topic.set_topic_attributes(topic_url, opts) |> request(config_overrides)
  end

  @doc """
  Get the attributes of an existing topic.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/140711.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details.
  """
  @spec get_topic_attributes(topic_url :: String.t()) :: result
  def get_topic_attributes(topic_url, opts \\ []) do
    config_overrides = Keyword.get(opts, :config_overrides, [])

    Topic.get_topic_attributes(topic_url) |> request(config_overrides)
  end

  @doc """
  Delete an existing topic.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/140713.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details.
  """
  @spec delete_topic(topic_url :: String.t()) :: result
  def delete_topic(topic_url, opts \\ []) do
    config_overrides = Keyword.get(opts, :config_overrides, [])

    Topic.delete(topic_url) |> request(config_overrides)
  end

  @doc """
  List the topics of an account.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/140714.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details;
    * `:topic_name_prefix`, optional, search for the topic name starting with this prefix;
    * `:number`, optional, maximum number of results returned for a single request, the valid value range in 1..1000, by default is 1000;
    * `:marker`, optional, a similar pagination cursor when list a large topics list, which is acquired from the `NextMarker` returned in the previous request.
  """
  @spec list_topics(opts :: Keyword.t()) :: result
  def list_topics(opts \\ []) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])
    Topic.list_topics(opts) |> request(config_overrides)
  end

  @doc """
  Create a subscription to a topic.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/27496.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details;
    * `:filter_tag`, optional, a string no more than 16 characters, there is no message filter set by default;
    * `:notify_strategy`, optional, `"BACKOFF_RETRY"` or `"EXPONENTIAL_DECAY_RETRY"`, as `"BACKOFF_RETRY"` by default;
    * `:notify_content_format`, optional, `"XML"`, `"JSON"`, or `"SIMPLIFIED"`, as `"XML"` by default
  """
  @spec subscribe(
          topic_url :: String.t(),
          subscription_name :: String.t(),
          endpoint :: String.t(),
          opts :: Keyword.t()
        ) :: result
  def subscribe(topic_url, subscription_name, endpoint, opts \\ []) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])
    Topic.subscribe(topic_url, subscription_name, endpoint, opts) |> request(config_overrides)
  end

  @doc """
  Modify `notify_strategy` of subscription attribute, the value of `notify_strategy`
  can be set as `"BACKOFF_RETRY"` or `"EXPONENTIAL_DECAY_RETRY"`.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/140719.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details.
  """
  @spec set_subscription_attributes(
          topic_url :: String.t(),
          subscription_name :: String.t(),
          notify_strategy :: String.t(),
          opts :: Keyword.t()
        ) :: result
  def set_subscription_attributes(topic_url, subscription_name, notify_strategy, opts \\ []) do
    config_overrides = Keyword.get(opts, :config_overrides, [])

    topic_url
    |> Topic.set_subscription_attributes(subscription_name, notify_strategy)
    |> request(config_overrides)
  end

  @doc """
  Get subscription attributes.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/140720.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details.
  """
  @spec get_subscription_attributes(
          topic_url :: String.t(),
          subscription_name :: String.t(),
          opts :: Keyword.t()
        ) :: result
  def get_subscription_attributes(topic_url, subscription_name, opts \\ []) do
    config_overrides = Keyword.get(opts, :config_overrides, [])

    topic_url
    |> Topic.get_subscription_attributes(subscription_name)
    |> request(config_overrides)
  end

  @doc """
  Cancel a subscription.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/140721.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details.
  """
  @spec unsubscribe(topic_url :: String.t(), subscription_name :: String.t(), opts :: Keyword.t()) ::
          result
  def unsubscribe(topic_url, subscription_name, opts \\ []) do
    config_overrides = Keyword.get(opts, :config_overrides, [])

    Topic.unsubscribe(topic_url, subscription_name) |> request(config_overrides)
  end

  @doc """
  List the subscriptions to a topic, support pagination query.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/140718.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details;
    * `:subscription_name_prefix`, optional, search for the subscription name starting with this prefix;
    * `:number`, optional, maximum number of results returned for a single request, the valid value range in 1..1000, by default is 1000;
    * `:marker`, optional, a similar pagination cursor when list a large subscriptions list, which is acquired from the `NextMarker` returned in the previous request.
  """
  @spec list_subscriptions(topic_url :: String.t(), opts :: Keyword.t()) :: result
  def list_subscriptions(topic_url, opts \\ []) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])

    Topic.list_subscriptions(topic_url, opts) |> request(config_overrides)
  end

  @doc """
  Publish a message to a specified topic, the message is pushed to endpoints for consumption.

  [Alibaba Cloud API Docs](https://www.alibabacloud.com/help/doc-detail/27497.htm){:target="_blank"}

  ## Options

    * `:config_overrides`, optional, the options in `config_overrides`, please see `request/2` for details;
    * `:message_tag`, optional, a string no more than 16 characters, there is no message tag set by default;
    * `:message_attributes`, optional, a string of message attributes, only be useable for email or SMS push, please see API documents for details.
  """
  @spec publish_topic_message(
          topic_url :: String.t(),
          message_body :: String.t(),
          opts :: Keyword.t()
        ) :: result
  def publish_topic_message(topic_url, message_body, opts \\ []) do
    {config_overrides, opts} = Keyword.pop(opts, :config_overrides, [])

    Topic.publish_message(topic_url, message_body, opts) |> request(config_overrides)
  end

  @doc false
  def format_opts_to_headers(opts) do
    Enum.reduce(opts, [], fn {key, value}, acc ->
      header = format_header(key, value)
      if header != nil, do: [header | acc], else: acc
    end)
  end

  @doc false
  defp format_header(:topic_name_prefix, value) do
    {"x-mns-prefix", "#{value}"}
  end

  defp format_header(:queue_name_prefix, value) do
    {"x-mns-prefix", "#{value}"}
  end

  defp format_header(:subscription_name_prefix, value) do
    {"x-mns-prefix", "#{value}"}
  end

  defp format_header(:number, value) do
    {"x-mns-ret-number", "#{value}"}
  end

  defp format_header(:marker, value) do
    {"x-mns-marker", value}
  end

  defp format_header(_key, _value) do
    nil
  end
end
