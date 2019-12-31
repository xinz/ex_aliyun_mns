defmodule ExAliyunMNSTest.PublishMessageToQueue do
  use ExUnit.Case

  @queue_name "pub-msg-to-queue"
  @topic_name "tmptopictest-pmtq"

  alias ExAliyun.MNS

  setup_all do
    queue_urls =
      Enum.map(["1", "2"], fn index ->
        {:ok, %{body: %{"queue_url" => queue_url}}} = 
          MNS.create_queue("#{@queue_name}#{index}")
        queue_url
      end)

    {:ok, %{body: %{"topic_url" => topic_url}}} =
      MNS.create_topic(@topic_name)

    on_exit(fn ->
      Enum.map(queue_urls, fn(queue_url) ->
        MNS.delete_queue(queue_url)
      end)

      MNS.delete_topic(topic_url)
    end)

    # give a few waiting for initialization
    Process.sleep(2_000)

    {:ok, topic_url: topic_url, queue_urls: queue_urls}
  end

  test "publish message to queue", context do
    [queue_url, _] = context[:queue_urls]
    topic_url = context[:topic_url]

    subscription_name = "test-subname"
    queue_name = String.split(queue_url, "/") |> List.last()

    endpoint = "acs:mns:cn-shenzhen:1570283091764072:queues/#{queue_name}"

    {:ok, _response} = MNS.subscribe(topic_url, subscription_name, endpoint, notify_content_format: "SIMPLIFIED")

    msg = "test msg from topic"

    # once publish message successfully, that message can be received promptly.
    {:ok, _response} = MNS.publish_topic_message(topic_url, msg)

    MNS.unsubscribe(topic_url, subscription_name)

    {:ok, response} = MNS.receive_message(queue_url)

    msg_map = Map.get(response.body, "Message")

    message_from_receive = Map.get(msg_map, "MessageBody")

    assert message_from_receive == msg

    receipt_handle = Map.get(msg_map, "ReceiptHandle")

    MNS.delete_message(queue_url, receipt_handle)
  end
  
  test "publish message to multi queues", context do
    queue_urls = context[:queue_urls]
    topic_url = context[:topic_url]

    sub_names =
      Enum.map(queue_urls, fn queue_url ->
        queue_name = String.split(queue_url, "/") |> List.last()
        endpoint = "acs:mns:cn-shenzhen:1570283091764072:queues/#{queue_name}"
        subscription_name = "#{queue_name}-sub"
        {:ok, _} = MNS.subscribe(topic_url, subscription_name, endpoint, notify_content_format: "SIMPLIFIED")
        subscription_name
      end)

    msg = "message-to-multi"

    {:ok, _} = MNS.publish_topic_message(topic_url, msg)

    Enum.each(sub_names, fn(sub_name) ->
      MNS.unsubscribe(topic_url, sub_name)
    end)

    #Process.sleep(1_000)

    Task.async_stream(queue_urls, fn queue_url ->
      {:ok, response} = MNS.receive_message(queue_url)

      msg_map = Map.get(response.body, "Message")

      message_from_receive = Map.get(msg_map, "MessageBody")

      assert message_from_receive == msg

      receipt_handle = Map.get(msg_map, "ReceiptHandle")

      MNS.delete_message(queue_url, receipt_handle)

    end)
    |> Enum.to_list()

  end

end
