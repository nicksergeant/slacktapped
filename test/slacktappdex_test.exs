defmodule SlacktappdexTest do
  use ExUnit.Case, async: true
  doctest Slacktappdex

  setup_all do
    Application.put_env(:slacktappdex, :access_token, "a1b2c3")
    Application.put_env(:slacktappdex, :client_id, "123")
    Application.put_env(:slacktappdex, :client_secret, "shh")
  end

  test "main" do
    checkins = Slacktappdex.main
  end
end
