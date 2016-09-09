defmodule Slacktapped.Redis.Mock do
  def command(command) do
    {:ok, command}
  end
end
