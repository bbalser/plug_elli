defmodule Testing.Simple.Plug do
  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    Plug.Conn.send_resp(conn, 200, "hello world")
  end
end
