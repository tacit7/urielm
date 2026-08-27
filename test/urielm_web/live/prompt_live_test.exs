defmodule UrielmWeb.PromptLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Urielm.Content
  alias Urielm.Fixtures

  setup do
    {:ok, prompt} =
      Content.create_prompt(%{
        title: "Reliable code review",
        category: "coding",
        prompt: "Review this change for correctness and maintainability."
      })

    %{prompt: prompt}
  end

  test "renders the shared prompt detail hierarchy", %{conn: conn, prompt: prompt} do
    {:ok, view, _html} = live(conn, "/prompts/#{prompt.id}")

    assert has_element?(view, "#prompt-detail-page.ui-page-shell")
    assert has_element?(view, "#prompt-detail-header.ui-page-header")
    assert has_element?(view, "#prompt-content-panel.ui-card")
    assert has_element?(view, "#copy-prompt-btn[aria-label='Copy prompt']")
    assert has_element?(view, "#prompt-comments-section")
    assert has_element?(view, "#prompt-sign-in-to-comment.alert-info a[href='/signin']")
    assert has_element?(view, "#prompt-comments-empty")
  end

  test "renders the signed-in comment composer as a shared surface", %{
    conn: conn,
    prompt: prompt
  } do
    conn = log_in_user(conn, Fixtures.user_fixture())
    {:ok, view, _html} = live(conn, "/prompts/#{prompt.id}")

    assert has_element?(view, "#prompt-comment-form.ui-card")
    assert has_element?(view, "#prompt-comment-body[name='comment[body]']")
    assert has_element?(view, "#prompt-comment-submit")
    refute has_element?(view, "#prompt-sign-in-to-comment")
  end
end
