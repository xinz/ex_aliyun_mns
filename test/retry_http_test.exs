defmodule ExAliyunMNSTest.RetryHttp do
  use ExUnit.Case

  alias ExAliyun.MNS

  test "mock a timeout failed case" do
    queue_name = "tmp_test_fake"
    opts = [
      access_key_id: "fake",
      access_key_secret: "fake",
      host: "https://12312316164072.mns.cn-shenzhen.aliyuncs.com"
    ]
    start_timestamp = Timex.to_unix(Timex.now())
    res =
      queue_name
      |> MNS.Queue.create([]) 
      |> MNS.request(opts, [timeout: 1])
    end_timestamp = Timex.to_unix(Timex.now())
    assert res == {:error, :timeout}
    assert end_timestamp - start_timestamp > 5
  end
end
