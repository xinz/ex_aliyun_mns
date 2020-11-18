defmodule ExAliyunMNSTest.PublishMessageToEmail do
  use ExUnit.Case

  @topic_name "tmp-email"

  alias ExAliyun.MNS

  setup_all do
    {:ok, %{body: %{"topic_url" => topic_url}}} = MNS.create_topic(@topic_name)

    on_exit(fn ->
      MNS.delete_topic(topic_url)
    end)

    {:ok, topic_url: topic_url}
  end

  test "send email", context do
    topic_url = context[:topic_url]
    {email, no_reply_mail_account} = Application.get_env(:ex_aliyun_mns, :test_email)
    endpoint = "mail:directmail:#{email}"

    subscription_name = "test-email-subname"

    MNS.subscribe(topic_url, subscription_name, endpoint, notify_content_format: "SIMPLIFIED")

    Process.sleep(2_000)

    message_body = "<xml>test<hello>' 1 > 2</xml>"

    direct_mail_data =
      Jason.encode!(%{
        "AccountName" => no_reply_mail_account,
        "Subject" => "test email subscribe",
        "AddressType" => 1,
        "IsHtml" => 0,
        "ReplyToAddress" => 0
      })

    opts = [
      message_attributes: "<DirectMail>#{direct_mail_data}</DirectMail>"
    ]

    {:ok, response} = MNS.publish_topic_message(topic_url, message_body, opts)
    body = response.body
    assert body != nil
    assert is_map(Map.get(body, "Message")) == true
  end
end
