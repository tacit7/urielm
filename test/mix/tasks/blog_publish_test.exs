defmodule Mix.Tasks.Blog.PublishTest do
  use Urielm.DataCase

  import Urielm.Fixtures

  alias Mix.Tasks.Blog.Publish
  alias Urielm.Content.Post
  alias Urielm.Repo

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    Mix.Task.reenable("blog.publish")

    path =
      Path.join(
        System.tmp_dir!(),
        "blog-publish-#{System.unique_integer([:positive, :monotonic])}.md"
      )

    on_exit(fn ->
      Mix.shell(previous_shell)
      Mix.Task.reenable("blog.publish")
      File.rm(path)
    end)

    %{path: path}
  end

  test "publishes a metadata-backed Markdown file and removes draft-only framing", %{path: path} do
    author = user_fixture(%{username: "article_author"})
    File.write!(path, article_file("Original body paragraph."))

    post = Publish.run([path, "--author", author.username, "--hero-image", "/images/article.png"])

    assert %Post{} = post
    assert post.title == "Markdown vs. AGENTS.md vs. Skills vs. Plugins"
    assert post.slug == "markdown-agents-md-skills-plugins"
    assert post.excerpt == "A concise comparison for coding-agent workflows."
    assert post.author_id == author.id
    assert post.hero_image == "/images/article.png"
    assert post.status == "published"
    assert post.published_at
    assert post.body == "Original body paragraph.\n"

    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Published blog post:"
    assert message =~ "/blog/markdown-agents-md-skills-plugins"
  end

  test "updates an existing slug instead of inserting a duplicate", %{path: path} do
    author = user_fixture(%{username: "updating_author"})
    File.write!(path, article_file("First version."))
    first = Publish.run([path, "--author", author.username])
    first_published_at = first.published_at
    flush_shell_messages()

    File.write!(path, article_file("Updated version."))
    second = Publish.run([path, "--author", author.username])

    assert second.id == first.id
    assert second.body == "Updated version.\n"
    assert second.published_at == first_published_at
    assert Repo.aggregate(Post, :count) == 1
    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Updated blog post:"
  end

  test "--draft stores the post without a publication time", %{path: path} do
    author = user_fixture(%{username: "draft_author"})
    File.write!(path, article_file("Draft body."))

    post = Publish.run([path, "--author", author.username, "--draft"])

    assert post.status == "draft"
    assert post.published_at == nil
    assert_received {:mix_shell, :info, [message]}
    assert message =~ "Saved draft:"
  end

  test "requires an explicit author username", %{path: path} do
    File.write!(path, article_file("Body."))

    assert_raise Mix.Error, fn -> Publish.run([path]) end
    assert_received {:mix_shell, :error, [message]}
    assert message =~ "--author USERNAME is required"
  end

  test "rejects an unknown author", %{path: path} do
    File.write!(path, article_file("Body."))

    assert_raise Mix.Error, fn -> Publish.run([path, "--author", "missing-user"]) end
    assert_received {:mix_shell, :error, ["Author not found: missing-user"]}
  end

  test "rejects files without required publishing metadata", %{path: path} do
    author = user_fixture(%{username: "metadata_author"})
    File.write!(path, "# An ordinary document\n\nBody.\n")

    assert_raise Mix.Error, fn -> Publish.run([path, "--author", author.username]) end
    assert_received {:mix_shell, :error, [message]}
    assert message =~ "Missing publishing metadata"
  end

  defp article_file(body) do
    """
    <!--
    Publishing metadata
    Title: Markdown vs. AGENTS.md vs. Skills vs. Plugins
    Slug: markdown-agents-md-skills-plugins
    Author: Uriel Maldonado
    Excerpt: A concise comparison for coding-agent workflows.
    -->

    # Markdown vs. AGENTS.md vs. Skills vs. Plugins

    By Uriel Maldonado

    #{body}
    """
  end

  defp flush_shell_messages do
    receive do
      {:mix_shell, _level, _message} -> flush_shell_messages()
    after
      0 -> :ok
    end
  end
end
