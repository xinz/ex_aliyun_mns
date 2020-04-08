defmodule ExAliyun.MNS.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_aliyun_mns,
      name: "ExAliyun.MNS",
      version: "1.0.2",
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
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.3.3"},
      {:timex, "~> 3.6"},
      {:hackney, "~> 1.15"},
      {:sax_map, "~> 0.2"},
      {:msgpax, "~> 2.2", only: :test},
      {:jason, "~> 1.2", only: :test},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Xin Zou"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/xinz/ex_aliyun_mns"}
    ]
  end

  defp docs do
    [
      main: "readme",
      formatter_opts: [gfm: true],
      extras: [
       "README.md"
      ]
    ]
  end
end
