defmodule Plug.Elli.Request do
  import Record, only: [defrecordp: 2, extract: 2]
  defrecordp :elli_req, extract(:req, from_lib: "elli/include/elli.hrl")

  @connection_header "connection"

  def close_or_keepalive(req, user_headers) do
    case get_header(user_headers, @connection_header) do
      :undefined ->
        case connection_token(req) do
          "Keep-Alive" -> :keep_alive
          "close" -> :close
        end

      "close" ->
        :close

      "Keep-Alive" ->
        :keep_alive
    end
  end

  def connection(req, user_headers) do
    case get_header(user_headers, @connection_header) do
      :undefined ->
        {@connection_header, connection_token(req)}

      _ ->
        []
    end
  end

  defp connection_token(elli_req(version: {1, 1}, headers: headers)) do
    case get_header(headers, @connection_header) do
      "close" -> "close"
      "Close" -> "close"
      _ -> "Keep-Alive"
    end
  end

  defp connection_token(elli_req(version: {1, 0}, headers: headers)) do
    case get_header(headers, @connection_header) do
      "Keep-Alive" -> "Keep-Alive"
      _ -> "close"
    end
  end

  defp connection_token(elli_req(version: {0, 9})) do
    "close"
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
