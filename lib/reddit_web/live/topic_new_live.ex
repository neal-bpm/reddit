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
      {:ok, _topic} ->
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
    <div class="container mx-auto px-3 py-4">
      <div class="mb-5">
        <h1 style="font-family: var(--font-display); font-size: 2rem; background: linear-gradient(to right, var(--color-teal), var(--color-bright-purple)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 0.2rem">
          Create a New Topic
        </h1>
        <p style="font-family: var(--font-text); color: var(--color-bright-blue); font-size: 0.95rem;">
          Start a new category for the community to discover! 🌈
        </p>
      </div>

      <div style="border-radius: 12px; background-color: white; padding: 20px; box-shadow: 0 3px 15px rgba(137,207,240,0.15); border: 1px solid rgba(191,95,255,0.2);">
        <.form for={@form} phx-submit="save" phx-change="validate">
          <div class="grid grid-cols-1 gap-5">
            <div>
              <.input
                field={@form[:name]}
                type="text"
                label="Topic Name"
                required
                style="font-family: var(--font-text); color: var(--color-text); background-color: white; border: 2px solid rgba(191,95,255,0.4); border-radius: 8px;"
              />
            </div>

            <div>
              <.input
                field={@form[:slug]}
                type="text"
                label="Topic Slug"
                style="font-family: var(--font-text); color: var(--color-text); background-color: white; border: 2px solid rgba(137,207,240,0.4); border-radius: 8px;"
              />
              <p style="font-family: var(--font-text); color: var(--color-bright-blue); font-size: 0.85rem; margin-top: 4px; font-style: italic;">
                Leave blank to generate automatically from the topic name
              </p>
            </div>

            <div>
              <.input
                field={@form[:description]}
                type="textarea"
                label="Description"
                style="font-family: var(--font-text); color: var(--color-text); background-color: white; border: 2px solid rgba(255,105,180,0.4); border-radius: 8px; resize: vertical; min-height: 100px;"
              />
            </div>

            <div class="flex items-center space-x-4 mt-3">
              <.button
                type="submit"
                class="px-4 py-2 rounded-full hover:scale-105 transition-transform"
                style="background: linear-gradient(to right, var(--color-bright-purple), var(--color-teal)); color: white; font-family: var(--font-heading); font-weight: 600; box-shadow: 0 3px 10px rgba(191,95,255,0.3);"
              >
                Create Topic ✨
              </.button>
              <.link
                navigate={~p"/topics"}
                class="px-4 py-2 rounded-full hover:scale-105 transition-transform inline-block"
                style="background-color: rgba(255,105,180,0.1); color: var(--color-hot-pink); font-family: var(--font-heading); font-weight: 600; border: 2px solid rgba(255,105,180,0.3);"
              >
                Cancel
              </.link>
            </div>
          </div>
        </.form>
      </div>

      <div
        class="text-center mt-5 py-2"
        style="font-family: var(--font-text); background: linear-gradient(to right, rgba(191,95,255,0.05), rgba(64,224,208,0.05), rgba(191,95,255,0.05)); border-radius: 20px;"
      >
        <a
          href={~p"/topics"}
          style="color: var(--color-bright-purple); border-bottom: 2px dotted var(--color-bright-purple); font-weight: 600; padding-bottom: 1px;"
        >
          Back to all topics
        </a>
        💜
      </div>
    </div>
    """
  end
end
