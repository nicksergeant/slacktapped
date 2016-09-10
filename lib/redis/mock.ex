defmodule Slacktapped.Redis.Mock do
  def command(command) do
    case command do
      "GET test:9988:with-image" -> {:ok, "1"}
      "GET test:354080681:with-image" -> {:ok, "1"}
      "GET test:5566:without-image" -> {:ok, "1"}
      _ -> {:ok, command}
    end
  end
end
