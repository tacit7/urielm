defmodule UrielmWeb.ThreadCardTest do
  use ExUnit.Case, async: true

  @thread_card Path.expand("../../assets/svelte/ThreadCard.svelte", __DIR__)

  test "thread actions stay visible and touch-friendly on mobile" do
    source = File.read!(@thread_card)

    assert source =~ "opacity-100 md:opacity-0"
    assert source =~ "md:group-hover:opacity-100"
    assert source =~ "md:group-focus-within:opacity-100"
    assert source =~ "min-h-10 min-w-10"
  end

  test "thread actions expose their state to assistive technology" do
    source = File.read!(@thread_card)

    assert source =~ ~s|aria-label={is_saved ? "Remove saved thread" : "Save thread"}|
    assert source =~ "aria-pressed={is_saved}"

    assert source =~
             ~s|aria-label={is_subscribed ? "Unsubscribe from thread" : "Subscribe to thread"}|

    assert source =~ "aria-pressed={is_subscribed}"
  end

  test "keeps the board link outside of the thread link" do
    source = File.read!(@thread_card)

    [_, thread_link_contents] =
      Regex.run(~r|<a href="/forum/t/\{id\}".*?>(.*?)</a>|s, source)

    refute thread_link_contents =~ "<a"
    assert source =~ ~s|<a href="/forum/b/{board.slug}"|
  end
end
