defmodule UrielmWeb.VideoThumbnailController do
  use UrielmWeb, :controller

  alias Urielm.Content
  alias Urielm.Content.Video

  @cache_control "public, max-age=3600"

  # The thumbnail URL comes from TikTok's oembed response, i.e. it is not fully
  # trusted. Do not follow redirects (constrained SSRF) and cap how many bytes
  # we buffer into memory.
  @max_thumbnail_bytes 5 * 1024 * 1024
  @allowed_thumbnail_content_types ~w(image/jpeg image/png image/gif image/webp)

  # sobelow_skip ["XSS.SendResp", "XSS.ContentType"]
  def show(conn, %{"id" => id}) do
    with {:ok, video_id} <- Ecto.UUID.cast(id),
         %Video{} = video <- Content.get_video(video_id),
         true <- public_tiktok_video?(video),
         {:ok, body, content_type} <- thumbnail_fetcher().(video.tiktok_url),
         {:ok, content_type} <- response_content_type(content_type) do
      conn
      |> put_resp_content_type(content_type)
      |> put_resp_header("cache-control", @cache_control)
      |> send_resp(:ok, body)
    else
      _ -> send_resp(conn, :not_found, "Not found")
    end
  end

  defp response_content_type(content_type)
       when content_type in @allowed_thumbnail_content_types do
    {:ok, content_type}
  end

  defp response_content_type(_content_type), do: {:error, :invalid_content_type}

  defp public_tiktok_video?(video) do
    video.visibility == "public" and not is_nil(video.published_at) and
      is_binary(video.tiktok_url) and video.tiktok_url != ""
  end

  defp thumbnail_fetcher do
    Application.get_env(:urielm, :tiktok_thumbnail_fetcher, &fetch_tiktok_thumbnail/1)
  end

  defp fetch_tiktok_thumbnail(tiktok_url) do
    with {:ok, thumbnail_url} <- fetch_thumbnail_url(tiktok_url),
         {:ok, %{status: 200} = response} <- fetch_capped_image(thumbnail_url),
         body when is_binary(body) and byte_size(body) <= @max_thumbnail_bytes <- response.body,
         [content_type | _] <- Req.Response.get_header(response, "content-type"),
         true <- String.starts_with?(content_type, "image/") do
      {:ok, body, content_type}
    else
      _ -> {:error, :thumbnail_unavailable}
    end
  end

  defp fetch_capped_image(thumbnail_url) do
    Req.get(thumbnail_url,
      receive_timeout: 10_000,
      redirect: false,
      into: fn {:data, data}, {req, resp} ->
        resp = update_in(resp.body, &(&1 <> data))

        if byte_size(resp.body) > @max_thumbnail_bytes do
          {:halt, {req, resp}}
        else
          {:cont, {req, resp}}
        end
      end
    )
  end

  defp fetch_thumbnail_url(tiktok_url) do
    request_url =
      "https://www.tiktok.com/oembed?url=#{URI.encode_www_form(tiktok_url)}"

    case Req.get(request_url, receive_timeout: 10_000) do
      {:ok, %{status: 200, body: %{"thumbnail_url" => url}}}
      when is_binary(url) and url != "" ->
        {:ok, url}

      _ ->
        {:error, :oembed_unavailable}
    end
  end
end
