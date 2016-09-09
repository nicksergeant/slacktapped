defmodule Slacktapped.Redis.Mock do
  def command(command) do
    {:ok, "OK"}
  end
end
