defmodule Plug.Elli.Conn do

  defstruct [:stream_pid, :req]

  def conn(req) do
    %Plug.Conn{
      adapter: {__MODULE__, %__MODULE__{req: req, stream_pid: nil}},
      host: :elli_request.host(req),
      port: :elli_request.port(req),
      method: :elli_request.method(req) |> to_string(),
      scheme: :elli_request.scheme(req),
      path_info: :elli_request.path(req),
      request_path: :elli_request.raw_path(req),
      query_string: :elli_request.query_str(req),
      req_headers: :elli_request.headers(req) |> fix_headers(),
      remote_ip: :elli_request.peer(req),
      owner: self()
    }
  end

  def send_resp(conn, status, headers, body) do
    headers = [{"content-length", to_string(byte_size(body))} | headers]
    :ok = :elli_http.send_response(conn.req, status, headers, body)

    {:ok, nil, conn}
  end

  def read_req_body(conn, _opts) do
    {:ok, :elli_request.body(conn.req), conn}
  end

  def send_chunked(conn, status, headers) do
    stream_pid = spawn_link(Plug.Elli.Stream, :init, [conn.req, status, headers])

    {:ok, nil, %{conn | stream_pid: stream_pid}}
  end

  def chunk(conn, body) do
    :elli_request.send_chunk(conn.stream_pid, body)

    :ok
  end

  defp fix_headers(headers) do
    Enum.map(headers, fn {name, value} ->
      {String.downcase(name), value}
    end)
  end
end

defmodule Plug.Elli.Stream do
  import Record, only: [defrecordp: 2, extract: 2]
  defrecordp :elli_req, extract(:req, from_lib: "elli/include/elli.hrl")

  def init(req, status, headers) do
    headers = [{"Transfer-Encoding", "chunked"} | headers]
    socket = elli_req(req, :socket)
    :elli_http.send_response(req, status, headers, "")
    :elli_tcp.setopts(socket, active: :once)

    :elli_http.chunk_loop(socket)
  end

end
