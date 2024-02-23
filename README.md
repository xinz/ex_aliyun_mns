# ExAliyun.MNS

**Alibaba Cloud Message Notification Service SDK for Elixir**

## Installation

```elixir
def deps do
  [
    {:ex_aliyun_mns, "~> 1.0"}
  ]
end
```

## Configuration

Set the authorization configuration in `config` file as a global setting, for example:

```elixir
config :ex_aliyun_mns,
  access_key_id: "",
  access_key_secret: "",
  host: "https://xxxx.mns.us-east-1.aliyuncs.com"
```

Or, dynamically set or override the authorization configuration when execute operation via `config_overrides` option, for example:

```elixir
ExAliyun.MNS.create_queue(
  "test-queue",
  config_overrides: [
    access_key_id: "",
    access_key_secret: "",
    host: ""
  ]
)
```

## Usage

Please refer Alibaba Cloud Message Notification Service [API reference](https://www.alibabacloud.com/help/doc-detail/27477.htm) for details, this library provides the corresponding functions via [`ExAliyun.MNS`](https://hexdocs.pm/ex_aliyun_mns/ExAliyun.MNS.html) module.
