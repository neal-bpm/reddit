defmodule RedditWeb.RedirectController do
  use RedditWeb, :controller

  def redirect_to_root(conn, _params) do
    redirect(conn, to: ~p"/")
  end
end
