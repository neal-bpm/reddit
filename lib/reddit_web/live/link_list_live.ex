defmodule RedditWeb.LinkListLive do
  use RedditWeb, :live_view

  alias Reddit.Content

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Reddit.PubSub, "links:new")
    end

    {:ok,
      socket
      |> assign(:page_title, "All Links")
      |> assign(:links, Content.list_homepage_links())}
  end

  @impl true
  def handle_info(%{event: "new_link", payload: link_payload}, socket) do
    updated_links = [link_payload | socket.assigns.links]
    {:noreply, assign(socket, :links, updated_links)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-center mb-8">
        <h1 class="text-3xl font-bold">Latest Links</h1>
        <a href={~p"/links/new"} class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
          Submit New Link
        </a>
      </div>

      <div class="space-y-4">
        <%= if Enum.empty?(@links) do %>
          <p class="text-gray-500 text-center py-8">No links have been posted yet. Be the first!</p>
        <% else %>
          <%= for link <- @links do %>
            <div class="bg-white p-4 rounded shadow">
              <div class="flex items-start">
                <div class="flex-grow">
                  <h2 class="text-xl font-bold mb-1">
                    <a href={~p"/links/#{link.id}"} class="text-blue-600 hover:text-blue-800"><%= link.title %></a>
                  </h2>
                  <div class="text-sm">
                    <span class="text-gray-500">
                      <a href={link.url} target="_blank" class="text-gray-600 hover:underline">
                        <%= link.url |> URI.parse() |> Map.get(:host) |> to_string() %>
                      </a>
                    </span>
                  </div>
                  <div class="mt-2 text-sm text-gray-600">
                    Posted by <%= link.user.username %> in
                    <a href={~p"/topics/#{link.topic.slug}"} class="text-blue-600 hover:underline">
                      <%= link.topic.name %>
                    </a>
                    • <%= relative_time(link.posted_at) %>
                    • <%= link.comment_count %> comments
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
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
