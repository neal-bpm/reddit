defmodule RedditWeb.LinkSubmitLive do
  use RedditWeb, :live_view

  alias Reddit.Content
  alias Reddit.Content.Link
  alias Reddit.Accounts

  @impl true
  def mount(_params, _session, socket) do
    topics = Content.list_topics()

    # Handle case where there are no topics
    if topics == [] do
      {:ok,
       socket
       |> put_flash(:error, "No topics available. Please create a topic first.")
       |> redirect(to: ~p"/topics/new")}
    else
      form = %Link{} |> Content.change_link() |> to_form()

      {:ok,
       socket
       |> assign(:page_title, "Submit New Link")
       |> assign(:topics, topics)
       |> assign(:form, form)
       |> assign(:username, "")}
    end
  end

  @impl true
  def handle_event("save", %{"link" => link_params, "username" => username}, socket) do
    # Find or create user based on username
    username_params = %{username: username}
    user_result = Accounts.find_or_create_user_by_username(username_params)

    case user_result do
      {:ok, user} ->
        # Add user_id and posted_at to link_params
        link_attrs =
          Map.merge(link_params, %{
            "user_id" => user.id,
            "posted_at" => DateTime.utc_now()
          })

        case Content.create_link(link_attrs) do
          {:ok, link} ->
            {:noreply,
             socket
             |> put_flash(:info, "Link submitted successfully!")
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
  def handle_event("validate", %{"link" => link_params, "username" => username}, socket) do
    form =
      %Link{}
      |> Content.change_link(link_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign(:username, username)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-3 py-4">
      <div class="mb-5">
        <h1 style="font-family: var(--font-display); font-size: 2rem; background: linear-gradient(to right, var(--color-bright-pink), var(--color-hot-pink)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 0.2rem">
          Share a New Link
        </h1>
        <p style="font-family: var(--font-text); color: var(--color-bright-purple); font-size: 0.95rem;">
          Share something amazing with the community! ✨
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
                prompt="Choose a topic"
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
                style="font-family: var(--font-text); color: var(--color-text); background-color: white; border: 2px solid rgba(255,153,51,0.4); border-radius: 8px;"
              />
              <p style="font-family: var(--font-text); color: var(--color-neon-orange); font-size: 0.85rem; margin-top: 4px; font-style: italic;">
                How you'll be identified in the community
              </p>
            </div>

            <div class="flex items-center space-x-4 mt-3">
              <.button
                type="submit"
                class="px-4 py-2 rounded-full hover:scale-105 transition-transform"
                style="background: linear-gradient(to right, var(--color-hot-pink), var(--color-bright-pink)); color: white; font-family: var(--font-heading); font-weight: 600; box-shadow: 0 3px 10px rgba(255,105,180,0.3);"
              >
                Submit Link ✨
              </.button>
              <a
                href={~p"/"}
                class="px-4 py-2 rounded-full hover:scale-105 transition-transform"
                style="background-color: rgba(137,207,240,0.1); color: var(--color-bright-blue); font-family: var(--font-heading); font-weight: 600; border: 2px solid rgba(137,207,240,0.3);"
              >
                Cancel
              </a>
            </div>
          </div>
        </.form>
      </div>

      <div
        class="text-center mt-5 py-2"
        style="font-family: var(--font-text); background: linear-gradient(to right, rgba(255,105,180,0.05), rgba(137,207,240,0.05), rgba(255,105,180,0.05)); border-radius: 20px;"
      >
        <a
          href={~p"/"}
          style="color: var(--color-bright-blue); border-bottom: 2px dotted var(--color-bright-blue); font-weight: 600; padding-bottom: 1px;"
        >
          Back to all links
        </a>
        🌈
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
