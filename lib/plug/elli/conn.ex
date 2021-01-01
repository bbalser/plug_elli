defmodule Plug.Elli.Conn do
  def conn(req) do
    %Plug.Conn{
      adapter: {__MODULE__, req},
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

  def send_resp(req, status, headers, body) do
    headers = [{"content-length", to_string(byte_size(body))} | headers]
    :ok = :elli_http.send_response(req, status, headers, body)

    {:ok, nil, req}
  end

  def read_req_body(req, _opts) do
    {:ok, :elli_request.body(req), req}
  end

  defp fix_headers(headers) do
    Enum.map(headers, fn {name, value} ->
      {String.downcase(name), value}
    end)
  end
end
