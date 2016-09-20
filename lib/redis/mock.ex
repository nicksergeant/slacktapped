defmodule Slacktapped.Redis.Mock do
  @doc """
  Returns some pre-defined mocked objects for testing and development.

  ## Examples

      iex> Slacktapped.Redis.Mock.command("GET test:354080681:with-image")
      {:ok, "1"}

      iex> Slacktapped.Redis.Mock.command("GET test:5566:without-image")
      {:ok, "1"}

      iex> Slacktapped.Redis.Mock.command("GET test:9988:with-image")
      {:ok, "1"}

      iex> Slacktapped.Redis.Mock.command("GET test:badge-5533")
      {:ok, "1"}

      iex> Slacktapped.Redis.Mock.command("GET test:badge-5566")
      {:ok, nil}

      iex> Slacktapped.Redis.Mock.command("GET test:comment-3344")
      {:ok, nil}

      iex> Slacktapped.Redis.Mock.command("GET test:comment-3355")
      {:ok, "1"}

  Falls back to simply returning the command if no match:

      iex> Slacktapped.Redis.Mock.command("GET foo")
      {:ok, "GET foo"}

  """
  def command(command) do
    case command do
      "GET test:354080681:with-image" -> {:ok, "1"}
      "GET test:5566:without-image" -> {:ok, "1"}
      "GET test:9988:with-image" -> {:ok, "1"}
      "GET test:badge-5533" -> {:ok, "1"}
      "GET test:badge-5566" -> {:ok, nil}
      "GET test:comment-3344" -> {:ok, nil}
      "GET test:comment-3355" -> {:ok, "1"}
      _ -> {:ok, command}
    end
  end
end
