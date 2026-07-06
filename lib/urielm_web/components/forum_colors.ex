defmodule UrielmWeb.ForumColors do
  @moduledoc false

  @colors %{
    "start-here" => "#1B4F8A",
    "announcements" => "#B03A2E",
    "qa" => "#1A7A5E",
    "prompting" => "#5B3A9E",
    "building" => "#2D6A4F",
    "models-tools" => "#8B4513",
    "show-and-tell" => "#962D4A",
    "feedback" => "#9A6B10",
    "off-topic" => "#4A5568",
    "ai-development" => "#1A3A7A"
  }

  @badge_classes %{
    "start-here" => "badge-primary",
    "announcements" => "badge-secondary",
    "qa" => "badge-accent",
    "prompting" => "badge-info",
    "building" => "badge-success",
    "models-tools" => "badge-warning",
    "show-and-tell" => "badge-neutral",
    "feedback" => "badge-error",
    "off-topic" => "badge-ghost"
  }

  def icon_color(slug), do: Map.get(@colors, slug, "#4A5568")

  def badge_class(slug), do: Map.get(@badge_classes, slug, "badge-neutral")
end
