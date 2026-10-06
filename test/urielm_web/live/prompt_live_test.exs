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

  test "fixes silenced account posting after the prompt page opens" do
    user =
      Fixtures.user_fixture()
      |> Ecto.Changeset.change(email_verified: true)
      |> Urielm.Repo.update!()

    {:ok, prompt} =
      Content.create_prompt(%{title: "Posting policy", category: "coding", prompt: "Review code"})

    conn = log_in_user(build_conn(), user)
    {:ok, view, _html} = live(conn, "/prompts/#{prompt.id}")

    view = find_live_child(view, "page-prompt_show")

    user
    |> Ecto.Changeset.change(%{silenced_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Urielm.Repo.update!()

    view
    |> form("#prompt-comment-form", %{comment: %{body: "Blocked comment"}})
    |> render_submit()

    assert Content.get_prompt_with_comments(prompt.id).comments == []
    assert Content.get_prompt_with_comments(prompt.id).comments_count == prompt.comments_count
  end

  test "fixes unverified account posting after the prompt page opens" do
    user =
      Fixtures.user_fixture()
      |> Ecto.Changeset.change(email_verified: true)
      |> Urielm.Repo.update!()

    {:ok, prompt} =
      Content.create_prompt(%{title: "Posting policy", category: "coding", prompt: "Review code"})

    conn = log_in_user(build_conn(), user)
    {:ok, view, _html} = live(conn, "/prompts/#{prompt.id}")

    view = find_live_child(view, "page-prompt_show")
    user |> Ecto.Changeset.change(%{email_verified: false}) |> Urielm.Repo.update!()

    view
    |> form("#prompt-comment-form", %{comment: %{body: "Blocked comment"}})
    |> render_submit()

    assert Content.get_prompt_with_comments(prompt.id).comments == []
    assert Content.get_prompt_with_comments(prompt.id).comments_count == prompt.comments_count
  end

  test "fixes suspended account posting after the prompt page opens" do
    user =
      Fixtures.user_fixture()
      |> Ecto.Changeset.change(email_verified: true)
      |> Urielm.Repo.update!()

    {:ok, prompt} =
      Content.create_prompt(%{title: "Posting policy", category: "coding", prompt: "Review code"})

    conn = log_in_user(build_conn(), user)
    {:ok, view, _html} = live(conn, "/prompts/#{prompt.id}")

    view = find_live_child(view, "page-prompt_show")

    user
    |> Ecto.Changeset.change(%{suspended_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Urielm.Repo.update!()

    view
    |> form("#prompt-comment-form", %{comment: %{body: "Blocked comment"}})
    |> render_submit()

    assert Content.get_prompt_with_comments(prompt.id).comments == []
    assert Content.get_prompt_with_comments(prompt.id).comments_count == prompt.comments_count
  end

  test "comment context requires an existing account and permits expired restrictions" do
    {:ok, prompt} =
      Content.create_prompt(%{
        title: "Context posting",
        category: "coding",
        prompt: "Review code"
      })

    attrs = %{body: "Context comment", prompt_id: prompt.id}
    assert {:error, %Ecto.Changeset{}} = Content.create_comment(attrs)
    assert {:error, :unauthenticated} = Content.create_comment(Map.put(attrs, :user_id, -1))

    user =
      Fixtures.user_fixture()
      |> Ecto.Changeset.change(email_verified: true)
      |> Urielm.Repo.update!()

    expired = DateTime.utc_now() |> DateTime.add(-60) |> DateTime.truncate(:second)

    user
    |> Ecto.Changeset.change(
      silenced_at: expired,
      silenced_until: expired,
      suspended_at: expired,
      suspended_until: expired
    )
    |> Urielm.Repo.update!()

    assert {:ok, _comment} = Content.create_comment(Map.put(attrs, :user_id, user.id))

    assert {:error, %Ecto.Changeset{}} =
             Content.create_comment(Map.merge(attrs, %{user_id: user.id, body: ""}))
  end

  test "verified users can post a prompt comment", %{conn: conn, prompt: prompt} do
    user =
      Fixtures.user_fixture()
      |> Ecto.Changeset.change(email_verified: true)
      |> Urielm.Repo.update!()

    {:ok, view, _} = live(log_in_user(conn, user), "/prompts/#{prompt.id}")
    view = find_live_child(view, "page-prompt_show")

    view
    |> form("#prompt-comment-form", %{comment: %{body: "Useful feedback"}})
    |> render_submit()

    assert [%{body: "Useful feedback"}] = Content.get_prompt_with_comments(prompt.id).comments
  end
end
