defmodule Mix.Tasks.Videos.AddTest do
  use Urielm.DataCase

  import ExUnit.CaptureIO

  alias Mix.Tasks.Videos.Add
  alias Urielm.Content
  alias Urielm.Content.Tag
  alias Urielm.Content.Video
  alias Urielm.Repo

  @url "https://www.youtube.com/watch?v=g5oEAoKdrdw"

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)
    Mix.Task.reenable("videos.add")

    Application.put_env(:urielm, :youtube_oembed_fetcher, fn _url ->
      {:ok,
       %{
         "title" => "The ULTIMATE ChatGPT Tutorial: Crash Course for Beginners",
         "author_name" => "Uriel",
         "author_url" => "https://www.youtube.com/@uriel"
       }}
    end)

    on_exit(fn ->
      Mix.shell(previous_shell)
      Application.delete_env(:urielm, :youtube_oembed_fetcher)
      Mix.Task.reenable("videos.add")
    end)
  end

  describe "run/1" do
    test "missing URL prints usage and raises" do
      assert_raise Mix.Error, fn ->
        capture_io(:stderr, fn -> Add.run([]) end)
      end

      assert_received {:mix_shell, :error, [message]}
      assert message =~ "Usage: mix videos.add YOUTUBE_URL"
    end

    test "valid URL inserts a published public video with oEmbed metadata" do
      video = Add.run([@url])

      assert %Video{} = video
      assert video.title == "The ULTIMATE ChatGPT Tutorial: Crash Course for Beginners"
      assert video.slug == "the-ultimate-chatgpt-tutorial-crash-course-for-beginners"
      assert video.youtube_url == @url
      assert video.author_name == "Uriel"
      assert video.author_url == "https://www.youtube.com/@uriel"
      assert video.visibility == "public"
      assert video.published_at

      assert_received {:mix_shell, :info, [message]}
      assert message =~ "Inserted video:"
      assert message =~ "/videos/the-ultimate-chatgpt-tutorial-crash-course-for-beginners"
    end

    test "--draft inserts without published_at" do
      video = Add.run([@url, "--draft"])

      assert video.published_at == nil
    end

    test "--visibility signed_in stores requested visibility" do
      video = Add.run([@url, "--visibility", "signed_in"])

      assert video.visibility == "signed_in"
    end

    test "invalid visibility raises before insert" do
      assert_raise Mix.Error, fn -> Add.run([@url, "--visibility", "premium"]) end

      assert Repo.aggregate(Video, :count) == 0
      assert_received {:mix_shell, :error, ["Invalid visibility: premium"]}
    end

    test "--title overrides oEmbed title" do
      video = Add.run([@url, "--title", "Custom Tutorial"])

      assert video.title == "Custom Tutorial"
      assert video.slug == "custom-tutorial"
    end

    test "--slug overrides generated slug" do
      video = Add.run([@url, "--slug", "custom-slug"])

      assert video.slug == "custom-slug"
    end

    test "existing URL is idempotent and does not insert a duplicate" do
      first = Add.run([@url])
      flush_shell_messages()

      second = Add.run([@url])

      assert second.id == first.id
      assert Repo.aggregate(Video, :count) == 1

      assert_received {:mix_shell, :info, [message]}
      assert message =~ "Already exists:"
      assert message =~ "/videos/#{first.slug}"
    end

    test "--tags creates and attaches tags" do
      video = Add.run([@url, "--tags", "AI, Tutorial, , Beginner"])

      assert Enum.map(Content.list_video_tags(video.id), & &1.slug) == [
               "ai",
               "beginner",
               "tutorial"
             ]
    end

    test "--tags reuses existing tag by normalized slug" do
      {:ok, existing} = Content.find_or_create_tag("AI")

      video = Add.run([@url, "--tags", "ai,A.I."])

      assert Repo.aggregate(Tag, :count) == 1
      assert Enum.map(Content.list_video_tags(video.id), & &1.id) == [existing.id]
    end

    test "--tags on an existing video replaces the previous tag set" do
      first = Add.run([@url, "--tags", "AI"])
      flush_shell_messages()

      second = Add.run([@url, "--tags", "Beginner"])

      assert second.id == first.id
      assert Repo.aggregate(Video, :count) == 1
      assert Enum.map(Content.list_video_tags(second.id), & &1.slug) == ["beginner"]
    end

    test "empty --tags value clears tags when updating an existing video" do
      Add.run([@url, "--tags", "AI"])
      flush_shell_messages()

      video = Add.run([@url, "--tags", " , "])

      assert Content.list_video_tags(video.id) == []
    end

    test "duplicate generated slug appends a suffix from the YouTube video id" do
      Add.run([@url])

      other_url = "https://youtu.be/abcDEF12345"
      video = Add.run([other_url])

      assert video.slug == "the-ultimate-chatgpt-tutorial-crash-course-for-beginners-abcdef12"
      assert Repo.aggregate(Video, :count) == 2
    end

    test "custom slug collision fails" do
      Add.run([@url, "--slug", "custom-slug"])

      assert_raise Mix.Error, fn ->
        Add.run(["https://www.youtube.com/watch?v=abcDEF12345", "--slug", "custom-slug"])
      end

      assert Repo.aggregate(Video, :count) == 1
      assert_received {:mix_shell, :error, ["Slug already exists: custom-slug"]}
    end

    test "metadata fetch failure raises a useful error" do
      Application.put_env(:urielm, :youtube_oembed_fetcher, fn _url ->
        {:error, "YouTube oEmbed returned HTTP 404"}
      end)

      assert_raise Mix.Error, fn -> Add.run([@url]) end

      assert_received {:mix_shell, :error,
                       ["Metadata could not be fetched: YouTube oEmbed returned HTTP 404"]}
    end
  end

  defp flush_shell_messages do
    receive do
      {:mix_shell, _level, _message} -> flush_shell_messages()
    after
      0 -> :ok
    end
  end
end
