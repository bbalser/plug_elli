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

  def send_resp(payload, status, headers, body) do
    headers = [
      Plug.Elli.Request.connection(payload.req, headers),
      {"content-length", to_string(byte_size(body))}
      | headers
    ]

    :ok = :elli_http.send_response(payload.req, status, headers, body)

    {:ok, nil, payload}
  end

  def read_req_body(payload, _opts) do
    {:ok, :elli_request.body(payload.req), payload}
  end

  def send_chunked(payload, status, headers) do
    stream_pid = spawn_link(Plug.Elli.Stream, :init, [payload.req, status, headers])

    {:ok, nil, %{payload | stream_pid: stream_pid}}
  end

  def chunk(payload, body) do
    :elli_request.send_chunk(payload.stream_pid, body)

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
