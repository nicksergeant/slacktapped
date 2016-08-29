defmodule SlacktappdexTest do
  use ExUnit.Case, async: true
  doctest Slacktappdex

  setup do
    %{
      checkin_with_badge: Slacktappdex.checkins |> Enum.at(6),
      checkin_with_comment: Slacktappdex.checkins |> Enum.at(0)
    }
  end

  test "parse_badge", context do
    badge = get_in(context.checkin_with_badge, ["badges", "items"])
      |> Enum.at(0)

    parsed = Slacktappdex.parse_badge(badge)
    assert(parsed == "badge")
  end

  test "parse_checkin", context do
    parsed = Slacktappdex.parse_checkin(context.checkin_with_badge)
    assert(parsed == "checkin")
  end

  test "parse_comment", context do
    comment = get_in(context.checkin_with_comment, ["comments", "items"])
      |> Enum.at(0)

    parsed = Slacktappdex.parse_comment(comment)
    assert(parsed == "comment")
  end
end
