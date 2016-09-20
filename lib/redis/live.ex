defmodule Slacktapped.Redis.Live do
  @doc """
  Runs the given command as a command through [Redix](https://github.com/whatyouhide/redix).

  ## Example

      iex> Slacktapped.Redis.Live.command("SET foo bar")
      {:ok, "OK"}

  """
  def command(command) do
    Redix.command(:redix, ~w(#{command}))
  end
end
