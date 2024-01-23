defmodule ExAliyunMNSTest.Topic.Integration do
  use ExUnit.Case

  alias ExAliyun.MNS

  @topic_name "exaliyunmns-topic"

  setup_all do
    {:ok, %{body: %{"topic_url" => topic_url}}} = MNS.create_topic(@topic_name)
    {:ok, %{body: %{"topic_url" => _}}} = MNS.create_topic(@topic_name <> "-1")
    {:ok, %{body: %{"topic_url" => _}}} = MNS.create_topic(@topic_name <> "-2")

    on_exit(fn ->
      MNS.delete_topic(topic_url)
      MNS.delete_topic(topic_url <> "-1")
      MNS.delete_topic(topic_url <> "-2")
    end)

    Process.sleep(2_000)

    {:ok, topic_url: topic_url, topic_name_prefix: "exaliyunmns"}
  end

  test "list topics", context do
    {:ok, resp} = MNS.list_topics(topic_name_prefix: "none")
    assert topic_size(resp) == 0

    topic_name_prefix = context[:topic_name_prefix]
    {:ok, resp} = MNS.list_topics(topic_name_prefix: topic_name_prefix)
    assert topic_size(resp) == 3
    {:ok, resp} = MNS.list_topics(topic_name_prefix: topic_name_prefix, number: 1)
    assert topic_size(resp) == 1
    next_marker = Map.get(resp.body, "Topics") |> Map.get("NextMarker")
    {:ok, resp} = MNS.list_topics(topic_name_prefix: topic_name_prefix, marker: next_marker)
    assert topic_size(resp) == 2

    {:ok, resp} = MNS.list_topics(topic_name_prefix: @topic_name <> "-1")
    assert topic_size(resp) == 1
  end

  test "manage topic", context do
    topic_url = context[:topic_url]
    {:ok, response} = MNS.set_topic_attributes(topic_url, logging_enabled: true)

    assert Map.get(response.body, "request_id") != nil

    {:ok, response} = MNS.get_topic_attributes(topic_url)

    assert Map.get(response.body, "Topic") |> Map.get("LoggingEnabled") == "True"

    {:ok, response} = MNS.list_topics()

    topic_items = Map.get(response.body, "Topics") |> Map.get("Topic")

    matched =
      Enum.find(topic_items, fn topic ->
        Map.get(topic, "TopicName") == @topic_name and
          Map.get(topic, "LoggingEnabled") == "True"
      end)

    assert matched != nil
  end

  test "subscribe with queue endpoint and unsubscribe", context do
    topic_url = context[:topic_url]
    subscription_name = "test-subname"
    endpoint = queue_endpoint("exaliyunmns")
    {:ok, _response} = MNS.subscribe(topic_url, subscription_name, endpoint)

    notify_strategy = "BACKOFF_RETRY"

    {:ok, _response} =
      MNS.set_subscription_attributes(topic_url, subscription_name, "BACKOFF_RETRY")

    {:ok, response} = MNS.get_subscription_attributes(topic_url, subscription_name)

    notify_strategy_in_get = Map.get(response.body, "Subscription") |> Map.get("NotifyStrategy")

    assert notify_strategy == notify_strategy_in_get

    {:ok, _} = MNS.unsubscribe(topic_url, subscription_name)

    {:ok, response} = MNS.list_subscriptions(topic_url)

    # Empty subscriptions
    assert subscription_size(response) == 0
  end

  test "list subscriptions", context do
    topic_url = context[:topic_url]

    sub_list = ["tmp-subname1", "tmp-subname2", "tmp-subname3"]
    endpoint = queue_endpoint("exaliyunmns")

    Enum.map(sub_list, fn subscription_name ->
      MNS.subscribe(topic_url, subscription_name, endpoint)
    end)

    {:ok, response} = MNS.list_subscriptions(topic_url, number: 1)

    next_marker = Map.get(response.body, "Subscriptions") |> Map.get("NextMarker")

    sub1_name =
      response.body
      |> Map.get("Subscriptions")
      |> Map.get("Subscription")
      |> hd()
      |> Map.get("SubscriptionName")

    {:ok, response} = MNS.list_subscriptions(topic_url, marker: next_marker)

    subs = Map.get(response.body, "Subscriptions") |> Map.get("Subscription")

    rest_subs =
      Enum.map(subs, fn sub ->
        Map.get(sub, "SubscriptionName")
      end)

    assert [sub1_name | rest_subs] == sub_list

    Enum.map(sub_list, fn subscription_name ->
      MNS.unsubscribe(topic_url, subscription_name)
    end)

    {:ok, response} = MNS.list_subscriptions(topic_url)

    # Empty subscriptions
    assert subscription_size(response) == 0
  end

  defp topic_size(response) do
    Map.get(response.body, "Topics") |> Map.get("Topic") |> length()
  end

  defp subscription_size(response) do
    Map.get(response.body, "Subscriptions") |> Map.get("Subscription") |> length()
  end

  defp queue_endpoint(queue_name) do
    url = Application.get_env(:ex_aliyun_mns, :host) |> URI.parse()
    [id, "mns", region, "aliyuncs", "com"] = String.split(url.host, ".")
    "acs:mns:#{region}:#{id}:queues/#{queue_name}"
  end
end
