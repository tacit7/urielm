defmodule UrielmWeb.CoreComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias UrielmWeb.CoreComponents

  test "empty state exposes stable accessible semantics" do
    html =
      render_component(&CoreComponents.empty_state/1, %{
        id: "library-empty",
        title: "No saved items yet",
        description: "Save useful content to find it here.",
        icon: "hero-bookmark"
      })

    document = LazyHTML.from_fragment(html)

    assert LazyHTML.filter(document, "#library-empty[data-ui-state='empty']") != []

    assert LazyHTML.filter(document, "#library-empty[aria-labelledby='library-empty-title']") !=
             []

    assert LazyHTML.filter(document, "#library-empty-title") != []
    assert LazyHTML.filter(document, ".hero-bookmark") != []
  end

  test "error state is announced and provides recovery context" do
    html =
      render_component(&CoreComponents.error_state/1, %{
        id: "feed-error",
        title: "We couldn't load this",
        description: "Check your connection and try again."
      })

    document = LazyHTML.from_fragment(html)

    assert LazyHTML.filter(document, "#feed-error[data-ui-state='error'][role='alert']") != []
    assert LazyHTML.filter(document, "#feed-error[aria-live='polite']") != []
  end

  test "loading state communicates progress without exposing decoration" do
    html =
      render_component(&CoreComponents.loading_state/1, %{
        id: "feed-loading",
        label: "Loading saved items"
      })

    document = LazyHTML.from_fragment(html)

    assert LazyHTML.filter(document, "#feed-loading[data-ui-state='loading'][aria-busy='true']") !=
             []

    assert LazyHTML.filter(document, "#feed-loading [aria-hidden='true'].ui-state-skeleton") != []
    assert html =~ "Loading saved items"
  end
end
