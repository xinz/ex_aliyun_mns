defmodule ExAliyunMNSTest.Queue.Integration do
  use ExUnit.Case

  @queue_name "exaliyunmns"

  alias ExAliyun.MNS

  defp queue_size(response) do
    queue_items = Map.get(response.body, "Queues") |> Map.get("Queue")
    cond do
      is_map(queue_items) -> 1
      is_list(queue_items) -> length(queue_items)
    end
  end

  defp request_id(response) do
    Map.get(response.body, "request_id")
  end

  defp error_code_and_message(response) do
    error = Map.get(response.body, "Error")
    {Map.get(error, "Code"), Map.get(error, "Message")}
  end

  defp receipt_handles(response) do
    messages = Map.get(response.body, "Messages") |> Map.get("Message")

    cond do
      is_map(messages) ->
        {
          [Map.get(messages, "ReceiptHandle")],
          [Map.get(messages, "MessageBody")]
        }
      is_list(messages) ->
        Enum.reduce(messages, {[], []}, fn(message, {acc_rec, acc_mes}) ->
          {
            [Map.get(message, "ReceiptHandle") | acc_rec],
            [Map.get(message, "MessageBody") | acc_mes]
          }
        end)
    end
  end

  defp receive_messages(queue_url, number \\ 1, wait_time_seconds \\ 0) do
    case MNS.receive_message(queue_url, number: number, wait_time_seconds: wait_time_seconds) do
      {:ok, response} ->
        {receipt_handles, messages} = receipt_handles(response)

        Enum.map(receipt_handles, fn(receipt_handle) ->
          MNS.delete_message(queue_url, receipt_handle)
        end)

        messages
      _error ->
        []
    end
  end

  setup_all do
    {:ok, %{body: %{"queue_url" => queue_url, "request_id" => _request_id}}} =
      MNS.create_queue(@queue_name)

    on_exit(fn ->
      {:ok, _response} = MNS.delete_queue(queue_url)
    end)

    Process.sleep(2_000)

    {:ok, queue_url: queue_url}
  end

  test "set_queue_attributes", context do
    {:ok, response} = MNS.set_queue_attributes(context[:queue_url], logging_enabled: true)
    assert response.body != nil
  end

  test "get_queue_attributes", context do
    {:ok, response} = MNS.get_queue_attributes(context[:queue_url])
    assert Map.get(response.body, "Queue") != nil
  end

  test "list_queue", _context do
    # Ensure existed size of total queues is less 1000 (maximum getable size per request)
    {:ok, response} = MNS.list_queues()
    total_size = queue_size(response)

    {:ok, response} = MNS.list_queues(number: 1)
    marker = Map.get(response.body, "Queues") |> Map.get("NextMarker")
    size_part1 = queue_size(response)

    if marker != nil do
      {:ok, response} = MNS.list_queues(marker: marker)
      size_part2 = queue_size(response)
      assert total_size == size_part1 + size_part2
    else
      assert total_size == size_part1
    end
  end

  test "send with delay seconds and delete message", context do
    message = "Test"
    {:ok, response} = MNS.send_message(context[:queue_url], message, delay_seconds: 300)
    receipt_handle = Map.get(response.body, "Message") |> Map.get("ReceiptHandle")
    {:ok, response} = MNS.delete_message(context[:queue_url], receipt_handle)
    assert request_id(response) != nil
  end

  test "send with delay seconds and batch_delete message", context do
    queue_url = context[:queue_url]
    receipt_handles =
      Enum.map(["msg1", "msg2", "msg3"], fn message ->
        {:ok, response} = MNS.send_message(queue_url, message, delay_seconds: 300)
        Map.get(response.body, "Message") |> Map.get("ReceiptHandle")
      end)
    {:ok, response} = MNS.batch_delete_message(queue_url, receipt_handles)
    assert request_id(response) != nil
  end

  test "send-receive-delete message", context do
    queue_url = context[:queue_url]

    message = "Test"

    {:ok, _response} = MNS.send_message(queue_url, message)

    {:ok, response} = MNS.receive_message(queue_url)

    receipt_handle = Map.get(response.body, "Message") |> Map.get("ReceiptHandle")

    {:ok, _response} = MNS.delete_message(queue_url, receipt_handle)

    {:error, response} = MNS.receive_message(queue_url, wait_time_seconds: 100)

    assert error_code_and_message(response) == {"InvalidArgument", "The value of PollingWaitSeconds should between 0 and 30 seconds"}

    messages = ["msg1", "msg2", "msg3"]

    {:ok, _response} = MNS.batch_send_message(queue_url, messages)

    messages1 = receive_messages(queue_url, 3, 20)
    messages2 = receive_messages(queue_url, 3, 20)
    messages3 = receive_messages(queue_url, 3, 20)

    messages4 = receive_messages(queue_url, 3, 20)

    assert messages4 == []

    assert Enum.sort(messages1 ++ messages2 ++ messages3) == messages
  end

  test "peek and batch_peek message", context do
    queue_url = context[:queue_url]

    # There is no message so far, so will get a MessageNotExist error
    {:error, response} = MNS.peek_message(queue_url)
    {code, _} = error_code_and_message(response)
    assert code == "MessageNotExist"

    message = "test_peek"
    {:ok, _response} = MNS.send_message(queue_url, message)

    # batch_peek
    {:ok, response} = MNS.peek_message(queue_url, number: 2)

    message_from_peek = Map.get(response.body, "Messages") |> Map.get("Message") |> Map.get("MessageBody")
    
    assert message_from_peek == message

    [message_from_receive] = receive_messages(queue_url)

    assert message_from_receive == message

    # after the above operations there is not message
    {:error, response} = MNS.peek_message(queue_url)
    {code, _} = error_code_and_message(response)
    assert code == "MessageNotExist"
  end

  test "change_message_visibility", context do
    queue_url = context[:queue_url]

    message = "test_change_message_visibility"

    {:ok, _response} = MNS.send_message(queue_url, message)

    {:ok, response} = MNS.receive_message(queue_url)

    msg_map = Map.get(response.body, "Message")
  
    message_from_receive = Map.get(msg_map, "MessageBody")

    assert message_from_receive == message

    receipt_handle = Map.get(msg_map, "ReceiptHandle")

    # Once a message has been consumed, the status of this message become inactive, we can use `change_message_visibility` to 
    # make that message consumable again.
    #
    # NOTICE: 
    #
    # Per MNS product offical confirmation, after ChangeMessageVisibility, there exists about 5~10 seconds inaccuracy (need to wait) to receive
    # that message.
    {:ok, response} = MNS.change_message_visibility(queue_url, receipt_handle, 1)

    new_receipt_handle = Map.get(response.body, "ChangeVisibility") |> Map.get("ReceiptHandle")

    assert receipt_handle != new_receipt_handle

    {:ok, response} = MNS.receive_message(queue_url, wait_time_seconds: 10)

    msg_map2 = Map.get(response.body, "Message")

    message_from_receive2 = Map.get(msg_map2, "MessageBody")

    receipt_handle2 = Map.get(msg_map2, "ReceiptHandle")

    assert message_from_receive2 == message_from_receive

    MNS.delete_message(queue_url, receipt_handle2)
  end
end
