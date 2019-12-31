defmodule ExAliyunMNSTest.Config do
  use ExUnit.Case

  alias ExAliyun.MNS.Config

  test "new" do
    config = Config.new()
    assert config.access_key_id != nil
    assert config.access_key_secret != nil
    assert config.host != nil

    config_overrides = Config.new([host: "testhost"])
    assert config_overrides.host == "testhost"
    assert config_overrides.access_key_id != nil
    assert config_overrides.access_key_secret != nil

    config_overrides = Config.new([host: "host1", access_key_id: "access_key_id1", access_key_secret: "access_key_secret1"])
    assert config_overrides.host == "host1"
    assert config_overrides.access_key_id == "access_key_id1"
    assert config_overrides.access_key_secret == "access_key_secret1"

    config_overrides = Config.new([access_key_secret: "abc", access_key_id: "def"])
    assert config_overrides.access_key_id == "def"
    assert config_overrides.access_key_secret == "abc"
  end

  test "new with invalid" do
    assert_raise ArgumentError, ~r/got a nil value/, fn ->
      Config.new([host: nil])
    end

    assert_raise ArgumentError, ~r/got a non-string value/, fn ->
      Config.new([access_key_secret: 100])
    end
  end
end
