defmodule ExAliyun.MNS.Queue do
  @moduledoc false

  alias ExAliyun.MNS.Operation

  @spec create(queue_name :: String.t(), opts :: Keyword.t()) :: Operation.t()
  def create(queue_name, opts \\ []) do
    params =
      opts
      |> Map.new()
      |> Map.put(:queue_name, queue_name)

    operation(nil, :create_queue, params: params)
  end

  @spec set_queue_attributes(queue_url :: String.t(), opts :: Keyword.t()) :: Operation.t()
  def set_queue_attributes(queue_url, opts \\ []) do
    operation(queue_url, :set_queue_attributes, params: Map.new(opts))
  end

  @spec get_queue_attributes(queue_url :: String.t()) :: Operation.t()
  def get_queue_attributes(queue_url) do
    operation(queue_url, :get_queue_attributes)
  end

  @spec list_queues(opts :: Keyword.t()) :: Operation.t()
  def list_queues(opts \\ []) do
    headers = ExAliyun.MNS.format_opts_to_headers(opts)
    operation(nil, :list_queues, headers: headers)
  end

  @spec delete(queue_url :: String.t()) :: Operation.t()
  def delete(queue_url) do
    operation(queue_url, :delete_queue)
  end

  @spec send_message(queue_url :: String.t(), message_body :: String.t(), opts :: Keyword.t()) :: Operation.t()
  def send_message(queue_url, message_body, opts \\ []) do
    params =
      opts
      |> Map.new()
      |> Map.put(:message_body, message_body)
    operation(queue_url, :send_message, params: params)
  end

  @spec batch_send_message(queue_url :: String.t(), messages :: [ExAliyun.MNS.mns_batch_message]) :: Operation.t()
  def batch_send_message(queue_url, messages) when is_list(messages) do
    messages = Enum.map(messages, fn
      message when is_bitstring(message) -> %{message_body: message}
      message when is_list(message) -> Map.new(message)
    end)
    params = %{messages: messages}
    operation(queue_url, :batch_send_message, params: params)
  end

  @spec delete_message(queue_url :: String.t(), receipt_handle :: String.t()) :: Operation.t()
  def delete_message(queue_url, receipt_handle) do
    params = %{receipt_handle: receipt_handle}
    operation(queue_url, :delete_message, params: params)
  end

  @doc """
  Delete a list of messages from a MNS Queue in a single request

  [Aliyun API Docs](https://help.aliyun.com/document_detail/35139.html)
  """
  @spec batch_delete_message(queue_url :: String.t(), receipt_handles :: [String.t()]) :: Operation.t()
  def batch_delete_message(queue_url, receipt_handles) do
    params = %{receipt_handles: receipt_handles}
    operation(queue_url, :batch_delete_message, params: params)
  end

  @doc """
  Read message(s) from a MNS Queue

  [Aliyun API Docs](https://help.aliyun.com/document_detail/35136.html)

  ## Options

    * `:wait_time_seconds`, optional, the maximum wait time for polling message in current request, settable value range is 0..30 (seconds),
    if not set will use Queue's `polling_wait_seconds` attribute (see `create_queue`) as default.
    * `:number`, optional, receive up to 16 messages ([doc](https://help.aliyun.com/document_detail/35137.html)) from a MNS Queue in a single request, by default as 1.
  """
  @spec receive_message(queue_url :: String.t(), opts :: Keyword.t()) :: Operation.t()
  def receive_message(queue_url, opts \\ []) do
    params = Map.merge(%{wait_time_seconds: nil, number: nil}, Map.new(opts))
    operation(queue_url, :receive_message, params: params)
  end

  @spec peek_message(queue_url :: String.t(), opts :: Keyword.t()) :: Operation.t()
  def peek_message(queue_url, opts \\ [number: nil]) do
    params = Map.new(opts)
    operation(queue_url, :peek_message, params: params)
  end

  @spec change_message_visibility(queue_url :: String.t(), receipt_handle :: String.t(), visibility_timeout :: integer()) :: Operation.t()
  def change_message_visibility(queue_url, receipt_handle, visibility_timeout) do
    operation(queue_url, :change_message_visibility, params: %{receipt_handle: receipt_handle, visibility_timeout: visibility_timeout})
  end

  defp operation(queue_url, action, opts \\ [])
  defp operation(nil, action, opts) do
    %Operation{
      action: action,
      params: opts[:params],
      headers: opts[:headers]
    }
  end

  defp operation(queue_url, action, opts) do
    params = Map.put(opts[:params] || %{}, :queue_url, queue_url)
    %Operation{
      action: action,
      params: params,
      headers: opts[:headers]
    }
  end

end
