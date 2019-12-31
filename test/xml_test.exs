defmodule ExAliyunMNSTest.Xml do
  use ExUnit.Case

  alias ExAliyun.MNS.Xml

  test "generate_queue with delay_seconds/maximum_message_size/message_retention_period" do
    xml_content = Xml.generate_queue(%{
      delay_seconds: 100,
      maximum_message_size: 10,
      message_retention_period: 100,
      visibility_timeout: nil,
      polling_wait_seconds: nil,
      logging_enabled: false
    })
    assert String.match?(xml_content, ~r/<DelaySeconds>100<\/DelaySeconds>/)
    assert String.match?(xml_content, ~r/<MaximumMessageSize>10<\/MaximumMessageSize>/)
    assert String.match?(xml_content, ~r/<MessageRetentionPeriod>100<\/MessageRetentionPeriod>/)
    assert String.match?(xml_content, ~r/<LoggingEnabled>False<\/LoggingEnabled>/)
    assert String.contains?(xml_content, ["PollingWaitSeconds", "VisibilityTimeout"]) == false
  end

  test "generate_queue with polling_wait_seconds/visibility_timeout" do
    xml_content = Xml.generate_queue(%{
      delay_seconds: nil,
      maximum_message_size: nil,
      message_retention_period: nil,
      visibility_timeout: 60,
      polling_wait_seconds: 3,
      logging_enabled: true
    })
    assert String.match?(xml_content, ~r/<PollingWaitSeconds>3<\/PollingWaitSeconds>/)
    assert String.match?(xml_content, ~r/<VisibilityTimeout>60<\/VisibilityTimeout>/)
    assert String.match?(xml_content, ~r/<LoggingEnabled>True<\/LoggingEnabled>/)
  end

  test "invalid input" do
    xml_content = Xml.generate_queue(%{
      delay_seconds: "invalid",
      maximum_message_size: nil,
      message_retention_period: "9",
      visibility_timeout: "100",
      polling_wait_seconds: "invalid",
      logging_enabled: 1
    })
    assert String.match?(xml_content, ~r/<DelaySeconds>100<\/DelaySeconds>/) == false
    assert String.match?(xml_content, ~r/<MaximumMessageSize>10<\/MaximumMessageSize>/) == false
    assert String.match?(xml_content, ~r/<MessageRetentionPeriod>100<\/MessageRetentionPeriod>/) == false
    assert String.match?(xml_content, ~r/<LoggingEnabled>False<\/LoggingEnabled>/)
    assert String.match?(xml_content, ~r/<PollingWaitSeconds>3<\/PollingWaitSeconds>/) == false
    assert String.match?(xml_content, ~r/<VisibilityTimeout>60<\/VisibilityTimeout>/) == false
  end

end
