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
        link_attrs = Map.merge(link_params, %{
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
    <div class="container mx-auto px-4 py-8">
      <div class="mb-6">
        <h1 class="text-3xl font-bold">Submit a New Link</h1>
        <p class="text-gray-600">Share something interesting with the community</p>
      </div>

      <div class="bg-white p-6 rounded shadow">
        <.form for={@form} phx-submit="save" phx-change="validate">
          <div class="grid grid-cols-1 gap-6">
            <div>
              <.input field={@form[:url]} type="url" label="URL" required />
            </div>

            <div>
              <.input field={@form[:title]} type="text" label="Title" required />
            </div>

            <div>
              <.input field={@form[:body]} type="textarea" label="Description (optional)" />
              <p class="text-sm text-gray-500 mt-1">Add some context or description for this link (optional)</p>
            </div>

            <div>
              <.input
                field={@form[:topic_id]}
                type="select"
                label="Topic"
                prompt="Select a topic"
                options={topic_select_options(@topics)}
                required
              />
              <div class="mt-2 text-sm">
                <span class="text-gray-600">Don't see a topic you like? </span>
                <.link navigate={~p"/topics/new"} class="text-blue-600 hover:underline">
                  Create a new topic
                </.link>
              </div>
            </div>

            <div>
              <.input name="username" value={@username} placeholder="Your username" label="Username" required />
              <p class="text-sm text-gray-500 mt-1">Enter your username to identify yourself</p>
            </div>

            <div class="flex items-center space-x-4">
              <.button type="submit">Submit Link</.button>
              <a href={~p"/"} class="text-gray-600 hover:text-gray-800">Cancel</a>
            </div>
          </div>
        </.form>
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
