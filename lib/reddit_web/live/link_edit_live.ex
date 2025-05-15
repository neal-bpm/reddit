defmodule RedditWeb.LinkEditLive do
  use RedditWeb, :live_view

  alias Reddit.Content
  alias Reddit.Content.Link
  alias Reddit.Accounts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    topics = Content.list_topics()
    link = Content.get_link!(id) |> Content.preload_associations_for_link()
    form = link |> Content.change_link() |> to_form()

    {:ok,
     socket
     |> assign(:page_title, "Edit Link")
     |> assign(:link, link)
     |> assign(:topics, topics)
     |> assign(:form, form)
     |> assign(:username, link.user.username)}
  end

  @impl true
  def handle_event("save", %{"link" => link_params, "username" => username}, socket) do
    # Find or create user based on username
    username_params = %{username: username}
    user_result = Accounts.find_or_create_user_by_username(username_params)

    case user_result do
      {:ok, user} ->
        # Add user_id to link_params
        link_attrs =
          Map.merge(link_params, %{
            "user_id" => user.id
          })

        case Content.update_link(socket.assigns.link, link_attrs) do
          {:ok, link} ->
            {:noreply,
             socket
             |> put_flash(:info, "Link updated successfully!")
             |> redirect(to: ~p"/links/#{link.id}")}

          {:error, changeset} ->
            {:noreply,
             socket
             |> assign(:form, to_form(changeset))
             |> assign(:username, username)}
        end

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Error with username. Please try again.")}
    end
  end

  @impl true
  def handle_event("validate", %{"link" => link_params}, socket) do
    # Use the username from socket assigns since the field is disabled in the form
    form =
      socket.assigns.link
      |> Content.change_link(link_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     socket
     |> assign(:form, form)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-3 py-4">
      <div class="mb-5">
        <h1 style="font-family: var(--font-display); font-size: 2rem; background: linear-gradient(to right, var(--color-bright-blue), var(--color-teal)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 0.2rem">
          Edit Link
        </h1>
        <p style="font-family: var(--font-text); color: var(--color-bright-purple); font-size: 0.95rem;">
          Update your shared link ✏️
        </p>
      </div>

      <div style="border-radius: 12px; background-color: white; padding: 20px; box-shadow: 0 3px 15px rgba(137,207,240,0.15); border: 1px solid rgba(255,105,180,0.2);">
        <.form for={@form} phx-submit="save" phx-change="validate">
          <div class="grid grid-cols-1 gap-5">
            <div>
              <.input
                field={@form[:url]}
                type="url"
                label="Website URL"
                required
                style="font-family: var(--font-text); color: var(--color-text); background-color: white; border: 2px solid rgba(137,207,240,0.4); border-radius: 8px;"
              />
            </div>

            <div>
              <.input
                field={@form[:title]}
                type="text"
                label="Title"
                required
                style="font-family: var(--font-text); color: var(--color-text); background-color: white; border: 2px solid rgba(255,105,180,0.4); border-radius: 8px;"
              />
            </div>

            <div>
              <.input
                field={@form[:body]}
                type="textarea"
                label="Description"
                style="font-family: var(--font-text); color: var(--color-text); background-color: white; border: 2px solid rgba(191,95,255,0.4); border-radius: 8px; resize: vertical; min-height: 100px;"
              />
              <p style="font-family: var(--font-text); color: var(--color-bright-purple); font-size: 0.85rem; margin-top: 4px; font-style: italic;">
                Optional additional context about your link
              </p>
            </div>

            <div>
              <.input
                field={@form[:topic_id]}
                type="select"
                label="Topic"
                options={topic_select_options(@topics)}
                required
                style="font-family: var(--font-text); color: var(--color-text); background-color: white; border: 2px solid rgba(0,183,255,0.4); border-radius: 8px;"
              />
              <div style="margin-top: 8px; font-family: var(--font-text); font-size: 0.85rem;">
                <span style="color: var(--color-bright-blue);">
                  Don't see what you're looking for?
                </span>
                <.link
                  navigate={~p"/topics/new"}
                  style="color: var(--color-hot-pink); border-bottom: 2px dotted var(--color-hot-pink); font-weight: 600; padding-bottom: 1px;"
                >
                  Create a new topic
                </.link>
              </div>
            </div>

            <div>
              <.input
                name="username"
                value={@username}
                placeholder="Your display name"
                label="Username"
                required
                disabled
                style="font-family: var(--font-text); color: var(--color-text); background-color: rgba(255,153,51,0.05); border: 2px solid rgba(255,153,51,0.4); border-radius: 8px;"
              />
              <input type="hidden" name="username" value={@username} />
              <p style="font-family: var(--font-text); color: var(--color-neon-orange); font-size: 0.85rem; margin-top: 4px; font-style: italic;">
                Original poster's username (cannot be changed)
              </p>
            </div>

            <div class="flex items-center space-x-4 mt-3">
              <.button
                type="submit"
                class="px-4 py-2 rounded-full hover:scale-105 transition-transform"
                style="background: linear-gradient(to right, var(--color-bright-blue), var(--color-teal)); color: white; font-family: var(--font-heading); font-weight: 600; box-shadow: 0 3px 10px rgba(137,207,240,0.3);"
              >
                Update Link ✏️
              </.button>
              <a
                href={~p"/links/#{@link.id}"}
                class="px-4 py-2 rounded-full hover:scale-105 transition-transform"
                style="background-color: rgba(255,105,180,0.1); color: var(--color-hot-pink); font-family: var(--font-heading); font-weight: 600; border: 2px solid rgba(255,105,180,0.3);"
              >
                Cancel
              </a>
            </div>
          </div>
        </.form>
      </div>

      <div
        class="text-center mt-5 py-2"
        style="font-family: var(--font-text); background: linear-gradient(to right, rgba(137,207,240,0.05), rgba(0,183,255,0.05), rgba(137,207,240,0.05)); border-radius: 20px;"
      >
        <a
          href={~p"/links/#{@link.id}"}
          style="color: var(--color-bright-blue); border-bottom: 2px dotted var(--color-bright-blue); font-weight: 600; padding-bottom: 1px;"
        >
          Back to link details
        </a>
        •
        <a
          href={~p"/"}
          style="color: var(--color-bright-purple); border-bottom: 2px dotted var(--color-bright-purple); font-weight: 600; padding-bottom: 1px;"
        >
          All links
        </a>
        🔄
      </div>
    </div>
    """
  end

  # Helper function to format topics for select dropdown
  defp topic_select_options(topics) do
    Enum.map(topics, fn topic ->
      {topic.name, topic.id}
    end)
  end
end
