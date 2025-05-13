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
    <div class="container mx-auto px-3 py-4">
      <div class="flex justify-between items-center mb-5">
        <div>
          <h1 style="font-family: var(--font-display); font-size: 2.2rem; background: linear-gradient(to right, var(--color-teal), var(--color-baby-blue)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 0.2rem">
            Topics
          </h1>
          <p style="font-family: var(--font-text); color: var(--color-bright-purple); font-size: 0.95rem; margin-top: 0;">
            Browse and explore our topic categories
          </p>
        </div>
        <.link
          navigate={~p"/topics/new"}
          class="px-4 py-2 rounded-full hover:scale-105 transition-transform"
          style="background: linear-gradient(to right, var(--color-bright-purple), var(--color-hot-pink)); color: white; font-family: var(--font-heading); font-weight: 600; box-shadow: 0 3px 10px rgba(191,95,255,0.3);"
        >
          New Topic ✨
        </.link>
      </div>

      <div
        class="topics-container"
        style="border-radius: 12px; overflow: hidden; box-shadow: 0 3px 15px rgba(137,207,240,0.15);"
      >
        <table class="w-full" style="border-collapse: collapse; font-family: var(--font-text);">
          <thead>
            <tr style="background: linear-gradient(to right, var(--color-baby-blue), var(--color-bright-blue)); color: white;">
              <th
                class="py-3 px-4 text-left"
                style="font-family: var(--font-heading); font-weight: 600; font-size: 0.9rem;"
              >
                Name
              </th>
              <th
                class="py-3 px-4 text-left hidden md:table-cell"
                style="font-family: var(--font-heading); font-weight: 600; font-size: 0.9rem;"
              >
                Slug
              </th>
              <th
                class="py-3 px-4 text-left hidden lg:table-cell"
                style="font-family: var(--font-heading); font-weight: 600; font-size: 0.9rem;"
              >
                Description
              </th>
              <th
                class="py-3 px-4 text-right"
                style="font-family: var(--font-heading); font-weight: 600; font-size: 0.9rem;"
              >
                Actions
              </th>
            </tr>
          </thead>
          <tbody>
            <%= if Enum.empty?(@topics) do %>
              <tr>
                <td colspan="4" class="py-6 text-center" style="background: white;">
                  <p style="font-family: var(--font-text); color: var(--color-hot-pink); font-size: 1.1rem;">
                    No topics yet. Create your first topic! ✨
                  </p>
                </td>
              </tr>
            <% else %>
              <%= for {topic, index} <- Enum.with_index(@topics) do %>
                <tr
                  style={"border-bottom: 1px solid rgba(255,105,180,0.1); #{if rem(index, 2) == 0, do: "background-color: white", else: "background-color: rgba(255,240,252,0.5)"}"}
                  class="hover:bg-[#FFF8FB]"
                >
                  <td class="py-3 px-4 whitespace-nowrap">
                    <div style="font-family: var(--font-heading); font-weight: 600; font-size: 1rem; color: var(--color-bright-blue);">
                      {topic.name}
                    </div>
                  </td>
                  <td class="py-3 px-4 whitespace-nowrap hidden md:table-cell">
                    <div style="color: var(--color-bright-pink); font-size: 0.9rem;">
                      {topic.slug}
                    </div>
                  </td>
                  <td class="py-3 px-4 hidden lg:table-cell">
                    <div style="color: var(--color-bright-purple); font-size: 0.9rem; overflow: hidden; text-overflow: ellipsis; max-width: 24rem; white-space: nowrap;">
                      {topic.description}
                    </div>
                  </td>
                  <td class="py-3 px-4 whitespace-nowrap text-right">
                    <.link
                      navigate={~p"/topics/#{topic.slug}"}
                      class="px-3 py-1.5 rounded-full hover:scale-105 transition-transform inline-block"
                      style="background: linear-gradient(to right, var(--color-hot-pink), var(--color-bright-pink)); color: white; font-family: var(--font-heading); font-weight: 600; font-size: 0.8rem; box-shadow: 0 2px 5px rgba(255,105,180,0.3);"
                    >
                      View 💜
                    </.link>
                  </td>
                </tr>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>

      <div
        class="text-center mt-5 py-2"
        style="font-family: var(--font-text); background: linear-gradient(to right, rgba(137,207,240,0.05), rgba(255,105,180,0.05), rgba(137,207,240,0.05)); border-radius: 20px;"
      >
        <span style="color: var(--color-bright-purple); font-weight: 600;">
          Total Topics: {Enum.count(@topics)}
        </span>
        🌈
      </div>
    </div>
    """
  end
end
