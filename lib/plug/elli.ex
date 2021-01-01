defmodule Plug.Elli do
  def child_spec(opts) do
    plug =
      case Keyword.fetch!(opts, :plug) do
        {plug, plug_opts} -> {plug, plug.init(plug_opts)}
        plug -> {plug, plug.init([])}
      end

    %{
      id: __MODULE__,
      start:
        {:elli, :start_link,
         [[callback: Plug.Elli.Handler, port: 4000, callback_args: plug]]}
    }
  end
end
