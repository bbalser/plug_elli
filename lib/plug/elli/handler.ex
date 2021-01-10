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

    {Plug.Elli.Request.close_or_keepalive(req, conn.resp_headers), ""}
  end

  def handle_event(_req, _data, _args) do
    :ok
  end

  defp maybe_close_stream(%Plug.Conn{adapter: {_, %Plug.Elli.Conn{stream_pid: pid}}} = conn)
       when is_pid(pid) do
    :elli_request.close_chunk(pid)

    conn
  end

  defp maybe_close_stream(conn), do: conn
end
