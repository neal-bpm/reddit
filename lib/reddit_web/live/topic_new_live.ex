defmodule RedditWeb.TopicNewLive do
  use RedditWeb, :live_view

  alias Reddit.Content
  alias Reddit.Content.Topic

  @impl true
  def mount(_params, _session, socket) do
    form = %Topic{} |> Content.change_topic() |> to_form()
    {:ok, assign(socket, form: form, page_title: "New Topic")}
  end

  @impl true
  def handle_event("validate", %{"topic" => topic_params}, socket) do
    form =
      %Topic{}
      |> Content.change_topic(topic_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  @impl true
  def handle_event("save", %{"topic" => topic_params}, socket) do
    case Content.create_topic(topic_params) do
      {:ok, topic} ->
        {:noreply,
         socket
         |> put_flash(:info, "Topic created successfully.")
         |> redirect(to: ~p"/topics")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="mb-6">
        <h1 class="text-3xl font-bold">Create a New Topic</h1>
        <p class="text-gray-600">Create a new discussion topic</p>
      </div>

      <div class="bg-white p-6 rounded shadow">
        <.form for={@form} phx-submit="save" phx-change="validate">
          <div class="grid grid-cols-1 gap-6">
            <div>
              <.input field={@form[:name]} type="text" label="Name" required />
            </div>

            <div>
              <.input field={@form[:slug]} type="text" label="Slug (optional)" />
              <p class="text-sm text-gray-500 mt-1">Leave blank to generate automatically from name</p>
            </div>

            <div>
              <.input field={@form[:description]} type="textarea" label="Description" />
            </div>

            <div class="flex items-center space-x-4">
              <.button type="submit">Create Topic</.button>
              <.link navigate={~p"/topics"} class="text-gray-600 hover:text-gray-800">
                Cancel
              </.link>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
