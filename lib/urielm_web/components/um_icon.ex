defmodule UrielmWeb.Components.UMIcon do
  @moduledoc """
  A thin wrapper around the core `<.icon>` component that lets us refer to
  icons by logical names and optionally swap libraries later.

  Use `<.um_icon name="bell" />` instead of hardcoding `hero-bell`.
  This preserves a single mapping point if we change icon libraries.
  """
  use Phoenix.Component

  @type variant :: nil | String.t()

  # Public API
  attr :name, :string, required: true, doc: "Logical icon name or full hero-* name"
  attr :variant, :string, default: nil, doc: "Optional variant: solid | mini | micro"
  attr :class, :string, default: nil
  attr :rest, :global

  def um_icon(assigns) do
    assigns = assign(assigns, :resolved_name, resolve(assigns.name, assigns.variant))

    ~H"""
    <span class={[@resolved_name, @class]} {@rest} />
    """
  end

  # Resolve a logical token to a concrete hero-* class. If the caller passes
  # an explicit `hero-*` value, pass it through unchanged.
  defp resolve("hero-" <> _ = explicit, _variant), do: explicit

  defp resolve(name, variant) when is_binary(name) do
    base =
      %{
        # common ui
        "home" => "home",
        "topics" => "chat-bubble-left-right",
        "chat" => "chat-bubble-left-right",
        "bookmark" => "bookmark",
        "bookmark_solid" => "bookmark-solid",
        "bell" => "bell",
        "users" => "user-group",
        "trophy" => "trophy",
        "info" => "information-circle",
        "warning" => "exclamation-triangle",
        "close" => "x-mark",
        "ellipsis" => "ellipsis-horizontal",
        "sun" => "sun",
        "moon" => "moon",
        "chevron_up" => "chevron-up",
        "chevron_down" => "chevron-down",
        "play" => "play",
        "bolt" => "bolt",
        "briefcase" => "briefcase",
        "adjustments_vertical" => "adjustments-vertical"
      }
      |> Map.get(name, name)

    has_variant_suffix =
      String.ends_with?(base, "-solid") or String.ends_with?(base, "-mini") or
        String.ends_with?(base, "-micro")

    suffix =
      if has_variant_suffix do
        ""
      else
        if variant in ["solid", "mini", "micro"], do: "-" <> variant, else: ""
      end

    "hero-" <> base <> suffix
  end
end
