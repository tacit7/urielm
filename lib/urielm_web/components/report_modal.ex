defmodule UrielmWeb.Components.ReportModal do
  @moduledoc """
  Shared report modal component used across thread and video views.
  Handles both content reports (threads/videos) and comment reports.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  import UrielmWeb.CoreComponents, only: [button: 1, input: 1]
  import UrielmWeb.Components.UMIcon, only: [um_icon: 1]

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :form_event, :string, required: true
  attr :form_id, :string, default: nil
  attr :form_testid, :string, default: nil
  attr :comment_id, :any, default: nil
  attr :submit_disabled, :boolean, default: false
  attr :submit_class, :string, default: "btn btn-error"
  attr :cancel_class, :string, default: "btn btn-ghost"
  attr :description_label, :string, default: "Description (required)"
  attr :description_placeholder, :string, default: "Explain why you're reporting this content..."
  attr :bg_class, :string, default: "bg-base-200"
  attr :rest, :global

  def report_modal(assigns) do
    assigns = assign(assigns, :form, to_form(%{}))

    ~H"""
    <dialog id={@id} class="modal" {@rest}>
      <div class={"modal-box #{@bg_class}"}>
        <button
          type="button"
          class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
          aria-label="Close"
          phx-click={JS.remove_attribute("open", to: "##{@id}")}
        >
          <.um_icon name="close" class="w-4 h-4" />
        </button>
        <h3 class="font-bold text-lg mb-4">{@title}</h3>
        <%= if @subtitle do %>
          <p class="pb-4 text-sm text-base-content/60">{@subtitle}</p>
        <% end %>
        <.form
          for={@form}
          id={@form_id}
          phx-submit={@form_event}
          class="space-y-4"
          data-testid={@form_testid}
        >
          <%= if @comment_id do %>
            <input type="hidden" name="comment_id" value={@comment_id} />
          <% end %>
          <.input
            field={@form[:reason]}
            id={"#{@id}-reason"}
            type="select"
            label="Reason"
            prompt="Select a reason"
            options={[Spam: "spam", Abuse: "abuse", Offensive: "offensive", Other: "other"]}
            required
          />
          <.input
            field={@form[:description]}
            id={"#{@id}-description"}
            type="textarea"
            label={@description_label}
            placeholder={@description_placeholder}
            help="Minimum 5 words and 20 characters · Maximum 5,000 characters."
            required
            minlength="20"
            maxlength="5000"
          />
          <div class="modal-action">
            <button
              type="button"
              class={@cancel_class}
              phx-click={JS.remove_attribute("open", to: "##{@id}")}
            >
              Cancel
            </button>
            <.button
              type="submit"
              loading_label="Submitting report…"
              class={@submit_class}
              disabled={@submit_disabled}
            >
              Submit Report
            </.button>
          </div>
        </.form>
      </div>
      <button
        type="button"
        class="modal-backdrop"
        aria-label="Close report dialog"
        phx-click={JS.remove_attribute("open", to: "##{@id}")}
      >
      </button>
    </dialog>
    """
  end
end
