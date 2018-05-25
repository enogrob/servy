defmodule Servy.Handler do
  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1]
  import Servy.Parser, only: [parse: 1]
  alias Servy.Conv

  @moduledoc "Handles HTTP requests."
  @pages_path Path.expand("../../pages", __DIR__)

  @doc "Transforms the request into a response."
  def handle(request) do
    request
    |> parse
    |> rewrite_path
    |> log
    |> route
    |> emojify
    |> track
    |> format_response
  end

  def emojify(%Conv{status: 200} = conv) do
    emojies = String.duplicate("🎉", 5)
    body = emojies <> "\n" <> conv.resp_body <> "\n" <> emojies

    %{ conv | resp_body: body }
  end

  def emojify(%Conv{} = conv), do: conv


  def route(%Conv{method: "GET", path: "/wildthings"} = conv) do
    %{conv | status: 200, resp_body: "Bears, Lions, Tigers"}
  end

  def route(%Conv{method: "GET", path: "/bears"} = conv) do
    %{conv | status: 200, resp_body: "Teddy, Smokey, Paddington"}
  end

  def route(%Conv{method: "GET", path: "/bears/" <> id} = conv) do
    %{conv | status: 200, resp_body: "Bear #{id}"}
  end

  def route(%Conv{method: "POST", path: "/bears"} = conv) do
    %{conv | status: 201, resp_body: "Created a #{conv.params["type"]} bear named #{conv.params["name"]}"}
  end

  def route(%Conv{method: "GET", path: "/about" } = conv) do
    file =
      @pages_path
      |> Path.join("about.html")

    case File.read(file) do
      {:ok, content} ->
        %{conv | status: 200, resp_body: content}
      {:error, :enoent} ->
        %{conv | status: 404, resp_body: "File not found"}
      {:error, reason} ->
        %{conv | status: 500, resp_body: "File Error: #{reason}"}
    end
  end

  def route(%Conv{method: "GET", path: "/pages/" <> file} = conv) do
    file =
      @pages_path
      |> Path.join(file <> ".html")

    case File.read(file) do
      {:ok, content} ->
        %{conv | status: 200, resp_body: content}
      {:error, :enoent} ->
        %{conv | status: 404, resp_body: "File not found"}
      {:error, reason} ->
        %{conv | status: 500, resp_body: "File Error: #{reason}"}
    end
  end

  def route(%Conv{method: "DELETE", path: "/bears/" <> _id} = conv) do
    %{conv | status: 403, resp_body: "Deleting a bear is forbidden!"}
  end

  def route(%Conv{path: path} = conv) do
    %{conv | status: 404, resp_body: "No #{path} here!"}
  end

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}
    Content-Type: text/html
    Content-Length: #{String.length(conv.resp_body)}

    #{conv.resp_body}
    """
  end
end
