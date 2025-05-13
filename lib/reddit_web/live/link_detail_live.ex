defmodule RedditWeb.LinkDetailLive do
  use RedditWeb, :live_view

  alias Reddit.Content
  alias Reddit.Content.Comment
  alias Reddit.Accounts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    link = Content.get_link_with_comments!(id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Reddit.PubSub, "comments:#{id}:new")
    end

    {:ok,
      socket
      |> assign(:page_title, link.title)
      |> assign(:link, link)
      |> assign(:comments, link.comments)
      |> assign(:comment_changeset, Content.change_comment(%Comment{}))
      |> assign(:username, "")
      |> assign(:parent_comment_id, nil)}
  end

  @impl true
  def handle_event("save_comment", %{"comment" => comment_params, "username" => username}, socket) do
    # Find or create user based on username
    username_params = %{username: username}
    user_result = Accounts.find_or_create_user_by_username(username_params)

    case user_result do
      {:ok, user} ->
        # Add required fields to comment_params
        comment_attrs = Map.merge(comment_params, %{
          "user_id" => user.id,
          "link_id" => socket.assigns.link.id,
          "parent_comment_id" => socket.assigns.parent_comment_id,
          "posted_at" => DateTime.utc_now()
        })

        case Content.create_comment(comment_attrs) do
          {:ok, _comment} ->
            {:noreply,
              socket
              |> assign(:comment_changeset, Content.change_comment(%Comment{}))
              |> assign(:username, username)
              |> assign(:parent_comment_id, nil)}

          {:error, changeset} ->
            {:noreply, assign(socket, :comment_changeset, changeset)}
        end

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Error with username. Please try again.")}
    end
  end

  @impl true
  def handle_event("validate_comment", %{"comment" => comment_params, "username" => username}, socket) do
    changeset =
      %Comment{}
      |> Content.change_comment(comment_params)
      |> Map.put(:action, :validate)

    {:noreply,
      socket
      |> assign(:comment_changeset, changeset)
      |> assign(:username, username)}
  end

  @impl true
  def handle_event("reply_to_comment", %{"id" => parent_id}, socket) do
    {:noreply, assign(socket, :parent_comment_id, parent_id)}
  end

  @impl true
  def handle_event("cancel_reply", _, socket) do
    {:noreply, assign(socket, :parent_comment_id, nil)}
  end

  @impl true
  def handle_info(%{event: "new_comment", payload: comment_payload}, socket) do
    updated_comments = socket.assigns.comments ++ [comment_payload]
    {:noreply, assign(socket, :comments, updated_comments)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="mb-8">
        <div class="flex items-center mb-2">
          <a href={~p"/"} class="text-blue-600 hover:text-blue-800 mr-2">← Back to all links</a>
          <span class="text-gray-500">
            in <a href={~p"/topics/#{@link.topic.slug}"} class="text-blue-600 hover:underline">
              <%= @link.topic.name %>
            </a>
          </span>
        </div>

        <div class="bg-white p-6 rounded shadow">
          <h1 class="text-3xl font-bold mb-2"><%= @link.title %></h1>
          <div class="text-gray-600 mb-4">
            <a href={@link.url} target="_blank" class="text-blue-600 hover:underline">
              <%= @link.url %>
            </a>
          </div>

          <%= if @link.body do %>
            <div class="border-t border-gray-200 pt-4 mt-4 prose max-w-none">
              <%= @link.body %>
            </div>
          <% end %>

          <div class="mt-4 text-sm text-gray-600">
            Posted by <%= @link.user.username %> • <%= relative_time(@link.posted_at) %>
          </div>
        </div>
      </div>

      <div class="mb-8">
        <h2 class="text-2xl font-bold mb-4">Comments</h2>

        <div class="bg-white p-6 rounded shadow mb-6">
          <h3 class="text-lg font-semibold mb-4">
            <%= if @parent_comment_id do %>
              Replying to a comment
              <button phx-click="cancel_reply" class="text-sm text-red-600 ml-2">Cancel</button>
            <% else %>
              Add a comment
            <% end %>
          </h3>

          <.form for={@comment_changeset} phx-submit="save_comment" phx-change="validate_comment">
            <div class="mb-4">
              <.input field={@comment_changeset[:body]} type="textarea" label="Your comment" required />
            </div>

            <div class="mb-4">
              <.input name="username" value={@username} placeholder="Your username" label="Username" required />
            </div>

            <.button type="submit" class="w-full md:w-auto">Post Comment</.button>
          </.form>
        </div>

        <div class="space-y-4">
          <%= if Enum.empty?(@comments) do %>
            <p class="text-gray-500 text-center py-4">No comments yet. Be the first to comment!</p>
          <% else %>
            <%= for comment <- @comments do %>
              <div class="bg-white p-4 rounded shadow" id={"comment-#{comment.id}"}>
                <div class="flex items-start">
                  <div class="flex-grow">
                    <div class="mb-2">
                      <span class="font-semibold"><%= comment.user.username %></span>
                      <span class="text-gray-500 text-sm ml-2"><%= relative_time(comment.posted_at) %></span>
                    </div>
                    <div class="prose prose-sm max-w-none">
                      <%= comment.body %>
                    </div>
                    <div class="mt-2">
                      <button
                        phx-click="reply_to_comment"
                        phx-value-id={comment.id}
                        class="text-sm text-blue-600 hover:text-blue-800"
                      >
                        Reply
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Helper to format relative time
  defp relative_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)} minutes ago"
      diff < 86400 -> "#{div(diff, 3600)} hours ago"
      diff < 2_592_000 -> "#{div(diff, 86400)} days ago"
      true -> "#{div(diff, 2_592_000)} months ago"
    end
  end
end
