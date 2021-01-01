defmodule Plug.Elli.Handler do
  @behaviour :elli_handler

  def init(_req, _args) do
    {:ok, :handover}
  end

  def handle(req, {plug, plug_opts}) do
    conn =
      req
      |> Plug.Elli.Conn.conn()
      |> plug.call(plug_opts)
      |> maybe_close_stream()

    {close_or_keepalive(req, conn.resp_headers), ""}
  end

  def handle_event(_req, _data, _args) do
    :ok
  end

  defp maybe_close_stream(%Plug.Conn{adapter: {_, %Plug.Elli.Conn{stream_pid: pid}}} = conn) when is_pid(pid) do
    :elli_request.close_chunk(pid)

    conn
  end

  defp maybe_close_stream(conn), do: conn

  defp close_or_keepalive(req, resp_headers) do
    # TODO Not sure this is correct
    req_headers = :elli_request.headers(req)

    case get_header(resp_headers, "connection") do
      :undefined ->
        case get_header(req_headers, "connection") do
          value when value in ["close", "Close"] -> :close
          _ -> :keep_alive
        end

      value when value in ["close", "Close"] ->
        :close

      value when value in ["Keep-Alive", "keep-alive"] ->
        :keep_alive
    end
  end

  defp get_header(headers, key, default \\ :undefined) do
    case_folded_key = :string.casefold(key)

    Enum.find_value(headers, default, fn {name, value} ->
      case :string.equal(case_folded_key, name, true) do
        true -> value
        false -> false
      end
    end)
  end
end
