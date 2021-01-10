defmodule Plug.Elli.Conn do
  defstruct [:stream_pid, :req]

  import Plug.Elli.Request, only: [elli_req: 1]

  def conn(
        elli_req(
          host: host,
          port: port,
          method: method,
          scheme: scheme,
          path: path,
          raw_path: raw_path,
          headers: headers
        ) = req
      ) do
    %Plug.Conn{
      adapter: {__MODULE__, %__MODULE__{req: req, stream_pid: nil}},
      host: host,
      port: port,
      method: to_string(method),
      scheme: scheme,
      path_info: path,
      request_path: raw_path,
      query_string: :elli_request.query_str(req),
      req_headers: fix_headers(headers),
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

  def read_req_body(%Plug.Elli.Conn{req: elli_req(body: body)} = payload, _opts) do
    {:ok, body, payload}
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
  import Plug.Elli.Request, only: [elli_req: 2]

  def init(req, status, headers) do
    headers = [
      Plug.Elli.Request.connection(req, headers),
      {"Transfer-Encoding", "chunked"}
      | headers
    ]

    socket = elli_req(req, :socket)
    :elli_http.send_response(req, status, headers, "")
    :elli_tcp.setopts(socket, active: :once)

    :elli_http.chunk_loop(socket)
  end
end
