defmodule Slacktapped.Redis.Live do
  def command(command) do
    Redix.command(:redix, ~w(#{command}))
  end
end
