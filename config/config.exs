use Mix.Config

if Mix.env() == :test do
  import_config "#{Mix.env()}.secret.exs"
end
