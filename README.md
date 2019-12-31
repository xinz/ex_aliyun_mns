# ExAliyun.MNS

**Alibaba Cloud Message Notification Service SDK for Elixir**

## Installation

```elixir
def deps do
  [
    {:ex_aliyun_mns, "~> 0.1"}
  ]
end
```

## Configuration

Option 1, we can set the authorization configuration in `config` file as a global setting, e.g.

```elixir
config :ex_aliyun_mns,
  access_key_id: "",
  access_key_secret: "",
  host: "https://xxxx.mns.us-east-1.aliyuncs.com"
```

Option 2, we can dynamically set or override the authorization configuration when execute operation, e.g.

```elixir
ExAliyun.MNS.create_queue("test-queue", 
  access_key_id: "", access_key_secret: "", host: "")
```

## Usage

Please refer Alibaba Cloud Message Notification Service [API reference](https://www.alibabacloud.com/help/doc-detail/27477.htm) for details.