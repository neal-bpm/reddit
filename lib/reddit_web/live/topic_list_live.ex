defmodule RedditWeb.TopicListLive do
  use RedditWeb, :live_view

  alias Reddit.Content

  @impl true
  def mount(_params, _session, socket) do
    topics = Content.list_topics()
    {:ok, assign(socket, topics: topics, page_title: "Topics")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold">Topics</h1>
        <.link navigate={~p"/topics/new"} class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded">
          New Topic
        </.link>
      </div>

      <div class="bg-white rounded-lg shadow">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Slug
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Description
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <%= for topic <- @topics do %>
              <tr>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="font-medium text-gray-900"><%= topic.name %></div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-500"><%= topic.slug %></div>
                </td>
                <td class="px-6 py-4">
                  <div class="text-sm text-gray-500 truncate max-w-xs"><%= topic.description %></div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <.link navigate={~p"/topics/#{topic.slug}"} class="text-blue-600 hover:text-blue-900 mr-4">
                    View
                  </.link>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
