defmodule Testing.Plug.Router do
  use Plug.Router
  use Plug.Debugger

  plug :match
  plug Plug.Parsers, parsers: [:json, :urlencoded], json_decoder: Jason
  plug :dispatch

  get "/hello/:name" do
    send_resp(conn, 200, name)
  end

  post "/create" do
    name = conn.params["name"]
    send_resp(conn, 200, "created #{name}")
  end

  match _ do
    IO.inspect(conn, label: "miss")
    send_resp(conn, 404, "not found")
  end

end
