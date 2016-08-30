defmodule SlacktappdexTest do
  use ExUnit.Case, async: true

  doctest Slacktappdex

  describe "Slacktappdex.parse_checkin" do
    test "a checkin without a rating", context do
      # Should post without "rated" text.
    end

    test "a checkin with an image", context do
      # Should post a checkin with image attached.
    end

    test "an existing checkin with a new image", context do
      # Should post that an image was added to the checkin.
    end
  end
end
