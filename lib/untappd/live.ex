defmodule Slacktapped.Untappd.Live do
  require Logger

  def get(path) do
    HTTPotion.get(api_url(path))
  end

  defp api_url(path) when is_binary(path) do
    access_token = System.get_env("UNTAPPD_ACCESS_TOKEN")
    client_id = System.get_env("UNTAPPD_CLIENT_ID")
    client_secret = System.get_env("UNTAPPD_CLIENT_SECRET")

    "https://api.untappd.com/v4/#{path}?client_id=#{client_id}&client_secret=#{client_secret}&access_token=#{access_token}"
  end
end
