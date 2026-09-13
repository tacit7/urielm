defmodule UrielmWeb.SEO do
  @moduledoc """
  Builds server-rendered SEO metadata for the persistent shell routes.

  JSON-LD is returned as inert `application/ld+json` data for crawlers. The JSON
  encoder output is escaped for `<` so content values cannot break out of the
  script element.
  """

  alias Urielm.Accounts
  alias Urielm.Content
  alias Urielm.Content.{Post, Prompt, Video}
  alias Urielm.Learning
  alias Urielm.Learning.{Course, Lesson}

  @site_name "Urielm"
  @site_url "https://urielm.dev"
  @default_description "Urielm is a public learning platform with practical AI tutorials, structured courses, reusable prompts, and developer community discussions."
  @code_kata_image "/images/code-kata/hero-editor-results.png"
  @default_image "/images/social-card.png"
  @head_keys ~w(page_title meta_description canonical_url robots og_title og_description og_url og_type og_site_name og_image twitter_card twitter_title twitter_description twitter_image json_ld)a

  def head_payload(assigns), do: Map.take(assigns, @head_keys)

  defp segment(value), do: URI.encode(value, &URI.char_unreserved?/1)

  def site_name, do: @site_name
  def default_description, do: @default_description

  def absolute_url(path) when is_binary(path) do
    path =
      cond do
        String.starts_with?(path, "http://") -> URI.parse(path).path || "/"
        String.starts_with?(path, "https://") -> URI.parse(path).path || "/"
        String.starts_with?(path, "/") -> path
        true -> "/" <> path
      end

    @site_url <> path
  end

  def metadata(:home, _params, _viewer) do
    ok(
      title: "Practical AI Learning",
      description: @default_description,
      path: "/",
      type: "website"
    )
  end

  def metadata(:blog_index, _params, _viewer) do
    ok(
      title: "Blog",
      description:
        "Read practical notes on AI workflows, prompting, developer tools, and durable ways to build with modern software.",
      path: "/blog",
      type: "website",
      structured_data: [
        breadcrumb([
          {"Home", "/"},
          {"Blog", "/blog"}
        ])
      ]
    )
  end

  def metadata(:blog_show, %{"slug" => slug}, _viewer) when is_binary(slug) do
    case Content.get_post_by_slug(slug) do
      %Post{} = post ->
        description = first_present([post.excerpt, plain_text(post.body), @default_description])
        image = absolute_optional_url(post.hero_image)

        ok(
          title: post.title,
          description: description,
          path: "/blog/#{segment(post.slug)}",
          type: "article",
          image: image,
          structured_data: [
            article(post, description, image),
            breadcrumb([
              {"Home", "/"},
              {"Blog", "/blog"},
              {post.title, "/blog/#{segment(post.slug)}"}
            ])
          ]
        )

      nil ->
        not_found()
    end
  end

  def metadata(:blog_show, _params, _viewer), do: not_found()

  def metadata(:prompts, _params, _viewer) do
    ok(
      title: "Prompts",
      description:
        "Browse reusable AI prompts for writing, coding, research, planning, and creative workflows.",
      path: "/prompts",
      type: "website"
    )
  end

  def metadata(:prompt_show, %{"id" => id}, _viewer) do
    with {:ok, prompt_id} <- parse_positive_integer(id),
         %Prompt{} = prompt <- Content.get_prompt(prompt_id) do
      ok(
        title: prompt.title,
        description:
          first_present([prompt.description, plain_text(prompt.prompt), @default_description]),
        path: "/prompts/#{prompt.id}",
        type: "article",
        structured_data: [
          breadcrumb([
            {"Home", "/"},
            {"Prompts", "/prompts"},
            {prompt.title, "/prompts/#{prompt.id}"}
          ])
        ]
      )
    else
      _ -> not_found()
    end
  end

  def metadata(:videos, params, _viewer) do
    path = videos_canonical_path(params)

    ok(
      title: "Videos",
      description:
        "Watch practical AI walkthroughs, developer tutorials, and quick videos from Urielm.",
      path: path,
      type: "website"
    )
  end

  def metadata(:video, %{"slug" => slug}, _viewer) when is_binary(slug) do
    case Content.get_video_by_slug(slug, preload_tags: true) do
      %Video{visibility: "public"} = video ->
        if Content.video_published?(video) and
             DateTime.compare(video.published_at, DateTime.utc_now()) != :gt do
          description =
            first_present([plain_text(video.description_md), "Watch #{video.title} on Urielm."])

          image = video_image(video)

          ok(
            title: video.title,
            description: description,
            path: "/videos/#{segment(video.slug)}",
            type: "video.other",
            image: image,
            structured_data: [
              video_object(video, description, image),
              breadcrumb([
                {"Home", "/"},
                {"Videos", "/videos"},
                {video.title, "/videos/#{segment(video.slug)}"}
              ])
            ]
          )
        else
          protected()
        end

      %Video{} ->
        protected()

      nil ->
        not_found()
    end
  end

  def metadata(:video, _params, _viewer), do: not_found()

  def metadata(:courses, _params, _viewer) do
    ok(
      title: "Courses",
      description:
        "Follow structured Urielm courses for practical AI, developer workflows, and repeatable learning paths.",
      path: "/courses",
      type: "website"
    )
  end

  def metadata(:course, %{"course_slug" => slug}, _viewer) when is_binary(slug) do
    case Learning.get_course_by_slug(slug) do
      %Course{} = course ->
        ok(
          title: course.title,
          description:
            first_present([
              course.description,
              "Learn #{course.title} with a focused Urielm course."
            ]),
          path: "/courses/#{segment(course.slug)}",
          type: "website",
          structured_data: [
            breadcrumb([
              {"Home", "/"},
              {"Courses", "/courses"},
              {course.title, "/courses/#{segment(course.slug)}"}
            ])
          ]
        )

      nil ->
        not_found()
    end
  end

  def metadata(:course, _params, _viewer), do: not_found()

  def metadata(:lesson, %{"course_slug" => course_slug, "lesson_slug" => lesson_slug}, _viewer)
      when is_binary(course_slug) and is_binary(lesson_slug) do
    with %Course{} = course <- Learning.get_course_by_slug(course_slug),
         %Lesson{} = lesson <- Learning.get_lesson_by_slug(course.id, lesson_slug) do
      ok(
        title: "#{lesson.title} - #{course.title}",
        description:
          first_present([
            plain_text(lesson.notes_md),
            "Watch #{lesson.title} from #{course.title}."
          ]),
        path: "/courses/#{segment(course.slug)}/lessons/#{segment(lesson.slug)}",
        type: "video.other",
        image: lesson_image(lesson),
        structured_data: [
          breadcrumb([
            {"Home", "/"},
            {"Courses", "/courses"},
            {course.title, "/courses/#{segment(course.slug)}"},
            {lesson.title, "/courses/#{segment(course.slug)}/lessons/#{segment(lesson.slug)}"}
          ])
        ]
      )
    else
      _ -> not_found()
    end
  end

  def metadata(:lesson, _params, _viewer), do: not_found()

  def metadata(:code_kata, _params, _viewer) do
    ok(
      title: "Code Kata",
      description:
        "Code Kata is a focused desktop app for practicing Python and JavaScript problems, tracking mastery, and reviewing what needs another pass.",
      path: "/code-kata",
      type: "website",
      image: absolute_url(@code_kata_image)
    )
  end

  def metadata(:themes, _params, _viewer) do
    ok(
      title: "Themes",
      description:
        "Preview Urielm's theme system and interface components across supported color palettes.",
      path: "/themes",
      type: "website",
      robots: "noindex"
    )
  end

  def metadata(:user_profile, %{"username" => username}, viewer) when is_binary(username) do
    case Accounts.get_user_by_username(username) do
      %{active: false} ->
        protected()

      nil ->
        protected()

      user ->
        if Accounts.can_view_profile?(nil, user) and Accounts.can_view_profile?(viewer, user) do
          display_name =
            first_present([user.display_name, user.name, "@#{segment(user.username)}"])

          ok(
            title: "#{display_name} (@#{segment(user.username)})",
            description: first_present([user.bio, "#{display_name}'s public Urielm profile."]),
            path: "/u/#{segment(user.username)}",
            type: "profile"
          )
        else
          protected()
        end
    end
  end

  def metadata(:user_profile, _params, _viewer), do: not_found()

  def metadata(_action, _params, _viewer), do: default()

  def json_ld(%{structured_data: structured_data}) when is_list(structured_data) do
    structured_data
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&Jason.encode!/1)
    |> Enum.map(&String.replace(&1, "<", "\\u003c"))
  end

  def json_ld(_metadata), do: []

  defp ok(opts) do
    metadata =
      opts
      |> Map.new()
      |> normalize_metadata()

    {:ok, metadata}
  end

  defp default do
    {:ok,
     normalize_metadata(%{
       title: "Urielm",
       description: @default_description,
       path: "/",
       type: "website"
     })}
  end

  defp protected do
    {:ok,
     normalize_metadata(%{
       title: "Urielm",
       description: @default_description,
       path: nil,
       type: "website",
       robots: "noindex",
       protected?: true
     })}
  end

  defp not_found do
    {:not_found,
     normalize_metadata(%{
       title: "Not Found",
       description: "The requested Urielm page could not be found.",
       path: nil,
       robots: "noindex",
       type: "website"
     })}
  end

  defp normalize_metadata(metadata) do
    title = clean_text(Map.get(metadata, :title), "Urielm", 90)
    description = clean_text(Map.get(metadata, :description), @default_description, 180)
    canonical_url = if path = Map.get(metadata, :path), do: absolute_url(path)
    image = Map.get(metadata, :image) || absolute_url(@default_image)

    %{
      page_title: title,
      meta_description: description,
      canonical_url: canonical_url,
      robots: Map.get(metadata, :robots),
      og_title: title,
      og_description: description,
      og_url: canonical_url,
      og_type: Map.get(metadata, :type, "website"),
      og_site_name: @site_name,
      og_image: image,
      twitter_card: "summary_large_image",
      twitter_title: title,
      twitter_description: description,
      twitter_image: image,
      structured_data: Map.get(metadata, :structured_data, []),
      protected?: Map.get(metadata, :protected?, false)
    }
  end

  defp article(%Post{} = post, description, image) do
    %{
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => post.title,
      "description" => description,
      "url" => absolute_url("/blog/#{segment(post.slug)}"),
      "datePublished" => iso8601(post.published_at),
      "dateModified" => iso8601(post.updated_at),
      "image" => image
    }
    |> compact()
  end

  defp video_object(_video, _description, nil), do: nil

  defp video_object(%Video{} = video, description, image) do
    %{
      "@context" => "https://schema.org",
      "@type" => "VideoObject",
      "name" => video.title,
      "description" => description,
      "url" => absolute_url("/videos/#{segment(video.slug)}"),
      "uploadDate" => iso8601(video.published_at),
      "thumbnailUrl" => image,
      "embedUrl" => youtube_embed_url(video.youtube_url)
    }
    |> compact()
  end

  defp breadcrumb(items) do
    %{
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" =>
        items
        |> Enum.with_index(1)
        |> Enum.map(fn {{name, path}, position} ->
          %{
            "@type" => "ListItem",
            "position" => position,
            "name" => name,
            "item" => absolute_url(path)
          }
        end)
    }
  end

  defp videos_canonical_path(params) do
    params = params || %{}

    allowed =
      [
        {"q", clean_param(params["q"])},
        {"format", known_format(params["format"])},
        {"tag", clean_param(params["tag"])}
      ]
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)

    case allowed do
      [] -> "/videos"
      query -> "/videos?" <> URI.encode_query(query)
    end
  end

  defp known_format(format) when format in ["standard", "short"], do: format
  defp known_format(_format), do: nil

  defp clean_param(value) when is_binary(value) do
    value = String.trim(value)
    if value == "", do: nil, else: String.slice(value, 0, 120)
  end

  defp clean_param(_value), do: nil

  defp parse_positive_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} when id > 0 and id <= 9_223_372_036_854_775_807 -> {:ok, id}
      _ -> :error
    end
  end

  defp parse_positive_integer(value)
       when is_integer(value) and value > 0 and value <= 9_223_372_036_854_775_807,
       do: {:ok, value}

  defp parse_positive_integer(_value), do: :error

  defp plain_text(nil), do: nil

  defp plain_text(value) when is_binary(value) do
    value
    |> String.replace(~r/```.*?```/s, " ")
    |> String.replace(~r/`([^`]+)`/, "\\1")
    |> String.replace(~r/!\[[^\]]*\]\([^)]+\)/, " ")
    |> String.replace(~r/\[([^\]]+)\]\([^)]+\)/, "\\1")
    |> String.replace(~r/[#>*_\-]+/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp first_present(values) do
    values
    |> Enum.find_value(fn
      value when is_binary(value) ->
        value = clean_text(value, nil, 180)
        if value == "", do: nil, else: value

      _ ->
        nil
    end)
  end

  defp clean_text(nil, default, _max_length), do: default

  defp clean_text(value, default, max_length) when is_binary(value) do
    value =
      value
      |> String.replace(~r/\s+/, " ")
      |> String.trim()
      |> String.slice(0, max_length)

    if value == "", do: default, else: value
  end

  defp absolute_optional_url(nil), do: nil

  defp absolute_optional_url(value) when is_binary(value) do
    value = String.trim(value)

    cond do
      value == "" -> nil
      String.starts_with?(value, "https://") -> value
      String.starts_with?(value, "http://") -> value
      String.starts_with?(value, "/") -> absolute_url(value)
      true -> nil
    end
  end

  defp video_image(%Video{youtube_url: url}) when is_binary(url) do
    case youtube_id(url) do
      nil -> nil
      id -> "https://img.youtube.com/vi/#{id}/hqdefault.jpg"
    end
  end

  defp video_image(%Video{id: id, tiktok_url: url}) when is_binary(url) and url != "" do
    absolute_url("/video-thumbnails/#{id}")
  end

  defp video_image(_video), do: nil

  defp lesson_image(%Lesson{youtube_video_id: id}) when is_binary(id) and id != "" do
    "https://img.youtube.com/vi/#{id}/hqdefault.jpg"
  end

  defp lesson_image(_lesson), do: nil

  defp youtube_embed_url(url) do
    case youtube_id(url) do
      nil -> nil
      id -> "https://www.youtube.com/embed/#{id}"
    end
  end

  defp youtube_id(url) when is_binary(url) do
    uri = URI.parse(url)
    host = String.downcase(uri.host || "")

    id =
      cond do
        uri.scheme not in ["http", "https"] ->
          nil

        host in ["youtu.be", "www.youtu.be"] ->
          String.trim_leading(uri.path || "", "/")

        host in [
          "youtube.com",
          "www.youtube.com",
          "m.youtube.com",
          "youtube-nocookie.com",
          "www.youtube-nocookie.com"
        ] ->
          case String.split(uri.path || "", "/", trim: true) do
            ["watch"] -> URI.decode_query(uri.query || "")["v"]
            [kind, id] when kind in ["embed", "shorts", "live"] -> id
            _ -> nil
          end

        true ->
          nil
      end

    if is_binary(id) and Regex.match?(~r/^[a-zA-Z0-9_-]{11}$/, id), do: id
  end

  defp youtube_id(_url), do: nil

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp iso8601(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)
  defp iso8601(value), do: to_string(value)

  defp compact(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> Map.new()
  end
end
