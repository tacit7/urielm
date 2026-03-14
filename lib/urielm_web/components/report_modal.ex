defmodule UrielmWeb.Components.ReportModal do
  @moduledoc """
  Shared report modal component used across thread and video views.
  Handles both content reports (threads/videos) and comment reports.
  """
  use Phoenix.Component
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
    ~H"""
    <dialog id={@id} class="modal" {@rest}>
      <div class={"modal-box #{@bg_class}"}>
        <form method="dialog">
          <button class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2" aria-label="Close">
            <.um_icon name="close" class="w-4 h-4" />
          </button>
        </form>
        <h3 class="font-bold text-lg mb-4">{@title}</h3>
        <%= if @subtitle do %>
          <p class="pb-4 text-sm text-base-content/60">{@subtitle}</p>
        <% end %>
        <form
          id={@form_id}
          phx-submit={@form_event}
          class="space-y-4"
          data-testid={@form_testid}
        >
          <%= if @comment_id do %>
            <input type="hidden" name="comment_id" value={@comment_id} />
          <% end %>
          <div>
            <label class="label">
              <span class="label-text">Reason</span>
            </label>
            <select name="reason" class="select select-bordered w-full" required>
              <option value="">Select a reason</option>
              <option value="spam">Spam</option>
              <option value="abuse">Abuse</option>
              <option value="offensive">Offensive</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div>
            <label class="label">
              <span class="label-text">{@description_label}</span>
            </label>
            <textarea
              name="description"
              placeholder={@description_placeholder}
              class="textarea textarea-bordered w-full min-h-24"
              required
              minlength="10"
              maxlength="5000"
            ></textarea>
            <p class="text-xs text-base-content/60 mt-1">
              Minimum 10 characters • Maximum 5000 characters
            </p>
          </div>
          <div class="modal-action">
            <form method="dialog">
              <button class={@cancel_class}>Cancel</button>
            </form>
            <button type="submit" class={@submit_class} disabled={@submit_disabled}>
              Submit Report
            </button>
          </div>
        </form>
      </div>
      <form method="dialog" class="modal-backdrop"><button>close</button></form>
    </dialog>
    """
  end
end
