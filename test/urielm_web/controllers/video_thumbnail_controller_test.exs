defmodule UrielmWeb.VideoThumbnailControllerTest do
  use UrielmWeb.ConnCase

  import Urielm.Fixtures

  setup do
    original_fetcher = Application.get_env(:urielm, :tiktok_thumbnail_fetcher)

    on_exit(fn ->
      if original_fetcher do
        Application.put_env(:urielm, :tiktok_thumbnail_fetcher, original_fetcher)
      else
        Application.delete_env(:urielm, :tiktok_thumbnail_fetcher)
      end
    end)
  end

  test "serves a fresh cacheable thumbnail for a published TikTok video", %{conn: conn} do
    video =
      video_fixture(%{
        youtube_url: nil,
        tiktok_url: "https://www.tiktok.com/@askcatgpt/video/7675882960125431053",
        format: "short",
        published_at: ~U[2026-08-26 12:00:00Z]
      })

    Application.put_env(:urielm, :tiktok_thumbnail_fetcher, fn url ->
      assert url == video.tiktok_url
      {:ok, "thumbnail bytes", "image/webp"}
    end)

    conn = get(conn, "/video-thumbnails/#{video.id}")

    assert response(conn, 200) == "thumbnail bytes"
    assert get_resp_header(conn, "content-type") == ["image/webp; charset=utf-8"]
    assert get_resp_header(conn, "cache-control") == ["public, max-age=3600"]
  end

  test "returns not found for an unpublished TikTok video", %{conn: conn} do
    video =
      video_fixture(%{
        youtube_url: nil,
        tiktok_url: "https://www.tiktok.com/@askcatgpt/video/7675882960125431053",
        format: "short",
        published_at: nil
      })

    conn = get(conn, "/video-thumbnails/#{video.id}")

    assert response(conn, 404) == "Not found"
  end

  test "returns not found for a malformed video id", %{conn: conn} do
    conn = get(conn, "/video-thumbnails/not-a-video-id")

    assert response(conn, 404) == "Not found"
  end

  test "rejects unsafe thumbnail URLs returned by TikTok oEmbed", %{conn: conn} do
    video =
      video_fixture(%{
        youtube_url: nil,
        tiktok_url: "https://www.tiktok.com/@askcatgpt/video/7675882960125431053",
        format: "short",
        published_at: ~U[2026-08-26 12:00:00Z]
      })

    Application.put_env(:urielm, :tiktok_thumbnail_fetcher, fn url ->
      assert url == video.tiktok_url
      {:error, :unsafe_thumbnail_url}
    end)

    conn = get(conn, "/video-thumbnails/#{video.id}")

    assert response(conn, 404) == "Not found"
  end

  test "safe_thumbnail_url?/1 rejects local and private network destinations" do
    refute UrielmWeb.VideoThumbnailController.safe_thumbnail_url?("http://localhost/image.jpg")
    refute UrielmWeb.VideoThumbnailController.safe_thumbnail_url?("http://127.0.0.1/image.jpg")
    refute UrielmWeb.VideoThumbnailController.safe_thumbnail_url?("http://10.0.0.5/image.jpg")
    refute UrielmWeb.VideoThumbnailController.safe_thumbnail_url?("ftp://example.com/image.jpg")

    refute UrielmWeb.VideoThumbnailController.safe_thumbnail_url?(
             "https://user@example.com/image.jpg"
           )

    refute UrielmWeb.VideoThumbnailController.safe_thumbnail_url?("https://example.com/image.jpg")
  end

  test "safe_thumbnail_url?/1 allows TikTok CDN thumbnail hosts" do
    assert UrielmWeb.VideoThumbnailController.safe_thumbnail_url?(
             "https://p16-sign-va.tiktokcdn.com/image.jpg"
           )

    assert UrielmWeb.VideoThumbnailController.safe_thumbnail_url?(
             "https://p19-sign.tiktokcdn-us.com/image.jpg"
           )
  end
end
