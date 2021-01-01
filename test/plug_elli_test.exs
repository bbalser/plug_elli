defmodule PlugElliTest do
  use ExUnit.Case

  test "hello world" do
    start_supervised!({Plug.Elli, plug: Testing.Simple.Plug})

    {:ok, response} = Tesla.get("http://localhost:4000/api/v1/hello")

    assert response.body == "hello world"
  end

  describe "plug router" do
    setup do
      start_supervised!({Plug.Elli, plug: Testing.Plug.Router})

      :ok
    end

    test "get" do
      {:ok, response} = Tesla.get("http://localhost:4000/hello/brian")

      assert response.body == "brian"
    end

    test "post" do
      payload =
        %{"name" => "brian"}
        |> URI.encode_query()

      {:ok, response} =
        Tesla.post("http://localhost:4000/create", payload,
          headers: [{"content-type", "application/x-www-form-urlencoded"}]
        )

      assert response.body == "created brian"
    end
  end
end
