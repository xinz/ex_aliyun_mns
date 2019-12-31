defmodule ExAliyunMNSTest.Topic.Integration do
  use ExUnit.Case

  alias ExAliyun.MNS

  @topic_name "exaliyunmns-topic"

  setup_all do
    {:ok, %{body: %{"topic_url" => topic_url}}} = MNS.create_topic(@topic_name)

    on_exit(fn ->
      MNS.delete_topic(topic_url)
    end)

    Process.sleep(2_000)

    {:ok, topic_url: topic_url}
  end

  test "manage topic", context do
    topic_url = context[:topic_url]
    {:ok, response} = MNS.set_topic_attributes(topic_url, logging_enabled: true)

    assert Map.get(response.body, "request_id") != nil

    {:ok, response} = MNS.get_topic_attributes(topic_url)

    assert Map.get(response.body, "Topic") |> Map.get("LoggingEnabled") == "True"

    {:ok, response} = MNS.list_topics()

    topic_items = Map.get(response.body, "Topics") |> Map.get("Topic")
    cond do
      is_map(topic_items) ->
        assert Map.get(topic_items, "TopicName") == @topic_name and Map.get(topic_items, "LoggingEnabled") == "True"
      is_list(topic_items) ->
        matched =
          Enum.find(topic_items, fn(topic) ->
            Map.get(topic, "TopicName") == @topic_name and Map.get(topic, "LoggingEnabled") == "True"
          end)
        assert matched != nil
    end
  end

  test "subscribe with queue endpoint and unsubscribe", context do
    topic_url = context[:topic_url]
    subscription_name = "test-subname"
    endpoint = "acs:mns:cn-shenzhen:1570283091764072:queues/exaliyunmns"
    {:ok, _response} = MNS.subscribe(topic_url, subscription_name, endpoint)

    notify_strategy = "BACKOFF_RETRY"

    {:ok, _response} = MNS.set_subscription_attributes(topic_url, subscription_name, "BACKOFF_RETRY")

    {:ok, response} = MNS.get_subscription_attributes(topic_url, subscription_name)

    notify_strategy_in_get = Map.get(response.body, "Subscription") |> Map.get("NotifyStrategy")

    assert notify_strategy == notify_strategy_in_get

    {:ok, _} = MNS.unsubscribe(topic_url, subscription_name)

    {:ok, response} = MNS.list_subscriptions(topic_url)

    # Empty subscriptions
    assert Map.get(response.body, "Subscriptions") == %{}
  end

  test "list subscriptions", context do
    topic_url = context[:topic_url]

    sub_list = ["tmp-subname1", "tmp-subname2", "tmp-subname3"]
    endpoint = "acs:mns:cn-shenzhen:1570283091764072:queues/exaliyunmns"
    Enum.map(sub_list, fn(subscription_name) ->
      MNS.subscribe(topic_url, subscription_name, endpoint)
    end)

    {:ok, response} = MNS.list_subscriptions(topic_url, number: 1)

    next_marker = Map.get(response.body, "Subscriptions") |> Map.get("NextMarker")

    sub1_name = Map.get(response.body, "Subscriptions") |> Map.get("Subscription") |> Map.get("SubscriptionName")

    {:ok, response} = MNS.list_subscriptions(topic_url, marker: next_marker)

    subs = Map.get(response.body, "Subscriptions") |> Map.get("Subscription")

    rest_subs =
      Enum.map(subs, fn(sub) ->
        Map.get(sub, "SubscriptionName")
      end)

    assert [sub1_name | rest_subs] == sub_list

    Enum.map(sub_list, fn(subscription_name) ->
      MNS.unsubscribe(topic_url, subscription_name)
    end)

    {:ok, response} = MNS.list_subscriptions(topic_url)

    # Empty subscriptions
    assert Map.get(response.body, "Subscriptions") == %{}
  end

end
