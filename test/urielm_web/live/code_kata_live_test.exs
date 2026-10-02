defmodule UrielmWeb.CodeKataLiveTest do
  use Urielm.DataCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint UrielmWeb.Endpoint

  use Phoenix.VerifiedRoutes,
    endpoint: UrielmWeb.Endpoint,
    router: UrielmWeb.Router,
    statics: UrielmWeb.static_paths()

  test "renders the public Code Kata page in the application shell" do
    {:ok, view, _html} = live(build_conn(), ~p"/code-kata")

    assert has_element?(view, "#code-kata-page")
    assert has_element?(view, "#code-kata-hero h1", "Practice what matters.")
    assert has_element?(view, "#code-kata-download[phx-hook='CodeKataDownload']")

    assert has_element?(
             view,
             "#code-kata-primary-download[href='https://github.com/tacit7/code-kata/releases/latest']",
             "Download app"
           )

    assert has_element?(view, "#code-kata-download-fallbacks", "macOS")
    assert has_element?(view, "#code-kata-download-fallbacks", "Windows")
    assert has_element?(view, "#code-kata-windows-download")
    assert has_element?(view, "#code-kata-download-fallbacks", "Linux")
    assert has_element?(view, "#code-kata-macos-install")
    assert has_element?(view, "#code-kata-macos-command")
    assert has_element?(view, "#code-kata-copy-macos-command[phx-hook='CopyToClipboard']")
    assert has_element?(view, "#code-kata-review-installer[href='/install/code-kata.sh']")
    assert has_element?(view, "#code-kata-practice-loop", "Choose the queue")
    assert has_element?(view, "#code-kata-practice-loop", "Solve in Monaco")
    assert has_element?(view, "#code-kata-practice-loop", "Review what decays")
    assert has_element?(view, "#practice-mode", "One tight loop for deliberate reps.")
    assert has_element?(view, "#progress", "Track your progress.")
    assert has_element?(view, "#code-kata-closing", "Ready for your next rep?")
    assert has_element?(view, "img[src='/images/code-kata/hero-editor-results.png']")
    assert has_element?(view, "img[src='/images/code-kata/practice-queue.png']")
    assert has_element?(view, "img[src='/images/code-kata/progress-overview.png']")
    assert has_element?(view, "img[src='/images/code-kata/progress-mastery.png']")
    assert has_element?(view, "img[src='/images/code-kata/progress-trends.png']")
  end

  test "serves the macOS installer script" do
    conn = get(build_conn(), "/install/code-kata.sh")

    assert response(conn, 200) =~ "com.apple.quarantine"
  end
end
