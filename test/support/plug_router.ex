defmodule Testing.Plug.Router do
  use Plug.Router
  use Plug.Debugger

  plug(:match)
  plug(Plug.Parsers, parsers: [:json, :urlencoded], json_decoder: Jason)
  plug(:dispatch)

  get "/hello/:name" do
    send_resp(conn, 200, name)
  end

  get "/chunks" do
    conn = send_chunked(conn, 200)

    ~w(one two three four five six)
    |> Enum.reduce_while(conn, fn chunk, conn ->
      case chunk(conn, chunk) do
        {:ok, conn} -> {:cont, conn}
        {:error, :closed} -> {:halt, conn}
      end
    end)
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
