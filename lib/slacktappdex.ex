defmodule Slacktappdex do
  @api Application.get_env(:slacktappdex, :api)

  def main() do
    checkins = @api.get("checkin/recent")
  end
end
