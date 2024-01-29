defmodule ExAliyun.MNS.MixProject do
  use Mix.Project

  @source_url "https://github.com/xinz/ex_aliyun_mns"

  def project do
    [
      app: :ex_aliyun_mns,
      name: "ExAliyun.MNS",
      version: "1.3.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      description: "Alibaba Cloud Message Notification Service (MNS) SDK",
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :eex],
      mod: {ExAliyun.MNS.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:finch, "~> 0.5"},
      {:timex, "~> 3.6"},
      {:sax_map, "~> 1.0"},
      {:msgpax, "~> 2.2", only: :test},
      {:jason, "~> 1.2", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Kevin Pan", "Xin Zou"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      formatter_opts: [gfm: true],
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
