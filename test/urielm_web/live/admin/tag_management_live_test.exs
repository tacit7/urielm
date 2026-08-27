defmodule UrielmWeb.Admin.TagManagementLiveTest do
  use UrielmWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Urielm.Fixtures
  alias Urielm.Forum
  alias Urielm.Repo

  describe "permission boundary" do
    test "administrators can access tag management", %{conn: conn} do
      conn = log_in_user(conn, Fixtures.admin_fixture())
      {:ok, view, _html} = live(conn, "/admin/tags")

      assert has_element?(view, "#admin-tag-management-page")
      assert has_element?(view, "#admin-nav-tags[aria-current='page']")
    end

    test "moderators and regular users are redirected", %{conn: conn} do
      moderator =
        Fixtures.user_fixture()
        |> Ecto.Changeset.change(%{is_moderator: true})
        |> Repo.update!()

      for user <- [moderator, Fixtures.user_fixture()] do
        assert {:error, {:redirect, %{to: "/"}}} = live(log_in_user(conn, user), "/admin/tags")
      end
    end
  end

  describe "tag and group CRUD" do
    setup %{conn: conn} do
      %{conn: log_in_user(conn, Fixtures.admin_fixture())}
    end

    test "creates, edits, and deletes a tag", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/admin/tags")

      view
      |> form("#admin-tag-form", tag: %{name: "Needs review", slug: "needs-review"})
      |> render_submit()

      tag = Forum.get_tag_by_slug("needs-review")
      assert has_element?(view, "#admin-tag-#{tag.id}", "Needs review")

      view |> element("#edit-tag-#{tag.id}") |> render_click()

      view
      |> form("#admin-tag-form", tag: %{name: "Reviewed", slug: "reviewed"})
      |> render_submit()

      assert has_element?(view, "#admin-tag-#{tag.id}", "Reviewed")
      view |> element("#delete-tag-#{tag.id}") |> render_click()
      refute has_element?(view, "#admin-tag-#{tag.id}")
    end

    test "creates, edits, and deletes a tag group", %{conn: conn} do
      {:ok, tag} = Forum.create_tag(%{name: "Question", slug: "question"})
      {:ok, view, _html} = live(conn, "/admin/tags")

      view
      |> form("#admin-tag-group-form",
        tag_group: %{name: "Workflow", description: "Discussion type", tag_ids: [tag.id]}
      )
      |> render_submit()

      [group] = Forum.list_tag_groups_with_tags()
      assert has_element?(view, "#admin-tag-group-#{group.id}", "Workflow")
      assert has_element?(view, "#admin-tag-group-#{group.id}", "Question")

      view |> element("#edit-tag-group-#{group.id}") |> render_click()

      view
      |> form("#admin-tag-group-form",
        tag_group: %{name: "Discussion type", description: "Renamed", tag_ids: [tag.id]}
      )
      |> render_submit()

      assert has_element?(view, "#admin-tag-group-#{group.id}", "Discussion type")
      view |> element("#delete-tag-group-#{group.id}") |> render_click()
      refute has_element?(view, "#admin-tag-group-#{group.id}")
    end
  end
end
