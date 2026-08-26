defmodule UrielmWeb.CoreComponentsTest do
  use ExUnit.Case, async: true
  use Phoenix.Component

  import Phoenix.LiveViewTest

  alias UrielmWeb.CoreComponents

  def loading_button_fixture(assigns) do
    ~H"""
    <CoreComponents.button id="save-button" type="submit" loading_label="Saving changes…">
      Save changes
    </CoreComponents.button>
    """
  end

  def feedback_fixture(assigns) do
    ~H"""
    <CoreComponents.form_feedback id="profile-feedback" kind={:success} title="Changes saved">
      Your profile is up to date.
    </CoreComponents.form_feedback>
    """
  end

  test "button exposes a stable loading label and submit affordance" do
    html = render_component(&loading_button_fixture/1, %{})
    document = LazyHTML.from_fragment(html)

    assert LazyHTML.filter(
             document,
             "#save-button.ui-submit-button[phx-disable-with='Saving changes…']"
           ) != []
  end

  test "input links errors and help text to the field" do
    error_html =
      render_component(&CoreComponents.input/1, %{
        id: "website",
        name: "website",
        label: "Website",
        value: "not-a-url",
        errors: ["must be a valid URL"],
        help: "Include https://"
      })

    error_document = LazyHTML.from_fragment(error_html)

    assert LazyHTML.filter(
             error_document,
             "#website[aria-invalid='true'][aria-describedby='website-error']"
           ) != []

    assert LazyHTML.filter(error_document, "#website-error[role='alert']") != []
    refute error_html =~ "Include https://"

    help_html =
      render_component(&CoreComponents.input/1, %{
        id: "username",
        name: "username",
        label: "Username",
        value: "",
        help: "Use 3–20 lowercase characters."
      })

    help_document = LazyHTML.from_fragment(help_html)

    assert LazyHTML.filter(help_document, "#username[aria-describedby='username-help']") != []
    assert LazyHTML.filter(help_document, "#username-help") != []
  end

  test "form feedback uses compact status semantics" do
    html = render_component(&feedback_fixture/1, %{})
    document = LazyHTML.from_fragment(html)

    assert LazyHTML.filter(document, "#profile-feedback[role='status'][aria-live='polite']") != []
    assert LazyHTML.filter(document, "#profile-feedback-title") != []
  end

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
