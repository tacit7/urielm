defmodule UrielmWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: UrielmWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      data-auto-dismiss="5000"
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any, default: nil
  attr :variant, :string, values: ~w(primary)
  attr :loading_label, :string, default: nil
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}

    button_class =
      if assigns.class do
        ["btn", assigns.class]
      else
        ["btn", Map.fetch!(variants, assigns[:variant])]
      end

    assigns = assign(assigns, :button_class, button_class)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@button_class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button
        class={[@button_class, @loading_label && "ui-submit-button"]}
        phx-disable-with={@loading_label}
        {@rest}
      >
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :help, :string, default: nil
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :string, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            aria-invalid={@errors != []}
            aria-describedby={field_description_id(@id, @errors, @help)}
            {@rest}
          />{@label}
        </span>
      </label>
      <.field_messages id={@id} errors={@errors} help={@help} />
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[
            @class ||
              "select select-bordered min-h-11 w-full rounded-xl border-base-300 bg-base-100/70",
            @errors != [] && (@error_class || "select-error")
          ]}
          multiple={@multiple}
          aria-invalid={@errors != []}
          aria-describedby={field_description_id(@id, @errors, @help)}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.field_messages id={@id} errors={@errors} help={@help} />
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class ||
              "textarea textarea-bordered min-h-28 w-full rounded-xl border-base-300 bg-base-100/70",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          aria-invalid={@errors != []}
          aria-describedby={field_description_id(@id, @errors, @help)}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.field_messages id={@id} errors={@errors} help={@help} />
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class ||
              "input input-bordered min-h-11 w-full rounded-xl border-base-300 bg-base-100/70",
            @errors != [] && (@error_class || "input-error")
          ]}
          aria-invalid={@errors != []}
          aria-describedby={field_description_id(@id, @errors, @help)}
          {@rest}
        />
      </label>
      <.field_messages id={@id} errors={@errors} help={@help} />
    </div>
    """
  end

  attr :id, :any, required: true
  attr :errors, :list, required: true
  attr :help, :string, default: nil

  defp field_messages(assigns) do
    ~H"""
    <div
      :if={@errors != []}
      id={field_message_id(@id, "error")}
      role="alert"
      class="mt-1.5 space-y-1"
    >
      <p :for={msg <- @errors} class="flex items-center gap-2 text-sm text-error">
        <.icon name="hero-exclamation-circle" class="size-5 shrink-0" />
        {msg}
      </p>
    </div>
    <p
      :if={show_field_help?(@errors, @help)}
      id={field_message_id(@id, "help")}
      class="mt-1.5 text-xs leading-5 text-base-content/55"
    >
      {@help}
    </p>
    """
  end

  defp field_description_id(nil, _errors, _help), do: nil
  defp field_description_id(id, [_ | _], _help), do: "#{id}-error"
  defp field_description_id(id, [], help) when is_binary(help), do: "#{id}-help"
  defp field_description_id(_id, [], _help), do: nil

  defp field_message_id(nil, _suffix), do: nil
  defp field_message_id(id, suffix), do: "#{id}-#{suffix}"

  defp show_field_help?([], help) when is_binary(help), do: true
  defp show_field_help?(_errors, _help), do: false

  @doc """
  Renders compact feedback for a form-level outcome or recovery message.
  """
  attr :id, :string, required: true
  attr :kind, :atom, values: [:success, :error, :info], default: :info
  attr :title, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def form_feedback(assigns) do
    assigns =
      assigns
      |> assign(:role, if(assigns.kind == :error, do: "alert", else: "status"))
      |> assign(
        :icon,
        case assigns.kind do
          :success -> "hero-check-circle"
          :error -> "hero-exclamation-circle"
          :info -> "hero-information-circle"
        end
      )

    ~H"""
    <div
      id={@id}
      role={@role}
      aria-live="polite"
      aria-labelledby={@title && "#{@id}-title"}
      class={[
        "ui-form-feedback",
        @kind == :success && "ui-form-feedback-success",
        @kind == :error && "ui-form-feedback-error",
        @kind == :info && "ui-form-feedback-info",
        @class
      ]}
      {@rest}
    >
      <.icon name={@icon} class="size-5 shrink-0" />
      <div class="min-w-0">
        <p :if={@title} id={"#{@id}-title"} class="font-semibold text-base-content">{@title}</p>
        <div class="text-sm leading-5 text-base-content/65">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a consistent empty state with optional contextual action.

  ## Examples

      <.empty_state
        id="saved-empty"
        title="No saved items yet"
        description="Save useful content to find it here."
        icon="hero-bookmark"
      />
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :icon, :string, default: "hero-inbox"
  attr :tone, :string, values: ~w(primary secondary), default: "primary"
  attr :compact, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  slot :action, doc: "an optional contextual action"

  def empty_state(assigns) do
    ~H"""
    <section
      id={@id}
      data-ui-state="empty"
      aria-labelledby={"#{@id}-title"}
      aria-describedby={@description && "#{@id}-description"}
      class={[
        "ui-state",
        @compact && "ui-state-compact",
        @class
      ]}
      {@rest}
    >
      <div class={[
        "ui-state-icon",
        if(@tone == "secondary",
          do: "bg-secondary/10 text-secondary",
          else: "bg-primary/10 text-primary"
        )
      ]}>
        <.icon name={@icon} class="size-6" />
      </div>
      <h2 id={"#{@id}-title"} class="ui-state-title">{@title}</h2>
      <p :if={@description} id={"#{@id}-description"} class="ui-state-description">
        {@description}
      </p>
      <div :if={@action != []} class="ui-state-action">
        {render_slot(@action)}
      </div>
    </section>
    """
  end

  @doc """
  Renders an announced, recoverable error state.
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :icon, :string, default: "hero-exclamation-triangle"
  attr :compact, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  slot :action, doc: "an optional recovery action"

  def error_state(assigns) do
    ~H"""
    <section
      id={@id}
      data-ui-state="error"
      role="alert"
      aria-live="polite"
      aria-labelledby={"#{@id}-title"}
      aria-describedby={@description && "#{@id}-description"}
      class={[
        "ui-state",
        @compact && "ui-state-compact",
        @class
      ]}
      {@rest}
    >
      <div class="ui-state-icon bg-error/10 text-error">
        <.icon name={@icon} class="size-6" />
      </div>
      <h2 id={"#{@id}-title"} class="ui-state-title">{@title}</h2>
      <p :if={@description} id={"#{@id}-description"} class="ui-state-description">
        {@description}
      </p>
      <div :if={@action != []} class="ui-state-action">
        {render_slot(@action)}
      </div>
    </section>
    """
  end

  @doc """
  Renders a reduced-motion-safe loading placeholder.
  """
  attr :id, :string, required: true
  attr :label, :string, default: "Loading content"
  attr :rows, :integer, values: [1, 2, 3, 4, 5, 6], default: 3
  attr :thumbnail, :boolean, default: true
  attr :compact, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global

  def loading_state(assigns) do
    ~H"""
    <section
      id={@id}
      data-ui-state="loading"
      role="status"
      aria-live="polite"
      aria-busy="true"
      class={[
        "ui-state ui-state-loading",
        @compact && "ui-state-compact",
        @class
      ]}
      {@rest}
    >
      <span class="sr-only">{@label}</span>
      <div class="ui-state-skeleton" aria-hidden="true">
        <div :if={@thumbnail} class="ui-skeleton ui-skeleton-thumbnail"></div>
        <div
          :for={index <- 1..@rows}
          class={[
            "ui-skeleton ui-skeleton-line",
            index == @rows && "ui-skeleton-line-short"
          ]}
        >
        </div>
      </div>
    </section>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders numbered pagination with daisyUI styling.

  Uses Flop.Meta for page information and renders navigation buttons
  with daisyUI's join component pattern.

  ## Examples

      <.pagination meta={@meta} path={fn n -> ~p"/posts?page=\#{n}" end} />
      <.pagination meta={@meta} path={&build_path/1} />
  """
  attr :meta, :map, required: true, doc: "Flop.Meta struct with pagination metadata"
  attr :path, :any, required: true, doc: "Function that takes page number and returns path"

  def pagination(%{meta: nil} = assigns), do: ~H""

  def pagination(assigns) do
    ~H"""
    <div class="join">
      <%= if @meta.has_previous_page? do %>
        <.link patch={@path.(@meta.current_page - 1)} class="join-item btn btn-sm">
          «
        </.link>
      <% else %>
        <button class="join-item btn btn-sm btn-disabled">«</button>
      <% end %>

      <%= for page <- page_links(@meta) do %>
        <%= case page do %>
          <% :ellipsis -> %>
            <button class="join-item btn btn-sm btn-disabled">...</button>
          <% n when n == @meta.current_page -> %>
            <button class="join-item btn btn-sm btn-active">{n}</button>
          <% n -> %>
            <.link patch={@path.(n)} class="join-item btn btn-sm">
              {n}
            </.link>
        <% end %>
      <% end %>

      <%= if @meta.has_next_page? do %>
        <.link patch={@path.(@meta.current_page + 1)} class="join-item btn btn-sm">
          »
        </.link>
      <% else %>
        <button class="join-item btn btn-sm btn-disabled">»</button>
      <% end %>
    </div>
    """
  end

  # Generate compact page links (current ± 2 pages with ellipsis)
  defp page_links(%{current_page: current, total_pages: total}) do
    start_page = max(1, current - 2)
    end_page = min(total, current + 2)

    pages = Enum.to_list(start_page..end_page)

    pages =
      if start_page > 1 do
        [1, :ellipsis | pages]
      else
        pages
      end

    if end_page < total do
      pages ++ [:ellipsis, total]
    else
      pages
    end
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(UrielmWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(UrielmWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
