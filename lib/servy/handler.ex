require Logger

defmodule Servy.Handler do

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

  def emojify(%{status: 200} = conv) do
    emojies = String.duplicate("🎉", 5)
    body = emojies <> "\n" <> conv.resp_body <> "\n" <> emojies

    %{ conv | resp_body: body }
  end

  def emojify(conv), do: conv

  @doc "Logs 404 requests."
  def track(%{status: 404, path: path} = conv) do
    Logger.error "Warning #{path} is on the loose"
    conv
  end

  def track(conv), do: conv

  def rewrite_path(%{path: "/wildlife"} = conv) do
    %{ conv | path: "/wildthings" }
  end

  def rewrite_path(%{path: "/bears?id=" <> id} = conv) do
    %{ conv | path: "/bears/#{id}" }
  end

  def rewrite_path(conv), do: conv

  # def rewrite_path(%{path: path} = conv) do
  #   regex = ~r{\/(?<thing>\w+)\?id=(?<id>\d+)}
  #   captures = Regex.named_captures(regex, path)
  #   rewrite_path_captures(conv, captures)
  # end
  # def rewrite_path(conv), do: conv
  #
  # def rewrite_path_captures(conv, %{"thing" => thing, "id" => id}) do
  #   %{ conv | path: "/#{thing}/#{id}" }
  # end
  # def rewrite_path_captures(conv, nil), do: conv

  def log(conv), do: IO.inspect(conv)

  def parse(request) do
    [method, path, _] =
      request
      |> String.split("\n")
      |> List.first()
      |> String.split(" ")

    %{method: method, path: path, resp_body: "", status: nil}
  end

  def route(%{method: "GET", path: "/wildthings"} = conv) do
    %{conv | status: 200, resp_body: "Bears, Lions, Tigers"}
  end

  def route(%{method: "GET", path: "/bears"} = conv) do
    %{conv | status: 200, resp_body: "Teddy, Smokey, Paddington"}
  end

  def route(%{method: "GET", path: "/bears/" <> id} = conv) do
    %{conv | status: 200, resp_body: "Bear #{id}"}
  end

  def route(%{method: "GET", path: "/about" } = conv) do
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

  def route(%{method: "GET", path: "/pages/" <> file} = conv) do
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

  def route(%{method: "DELETE", path: "/bears/" <> _id} = conv) do
    %{conv | status: 403, resp_body: "Deleting a bear is forbidden!"}
  end

  def route(%{path: path} = conv) do
    %{conv | status: 404, resp_body: "No #{path} here!"}
  end

  def format_response(conv) do
    """
    HTTP/1.1 #{conv.status} #{status_reason(conv.status)}
    Content-Type: text/html
    Content-Length: #{String.length(conv.resp_body)}

    #{conv.resp_body}
    """
  end

  defp status_reason(code) do
    codes = %{
      200 => "OK",
      201 => "Created",
      401 => "Unauthorized",
      403 => "Forbidden",
      404 => "Not Found",
      500 => "internal Server Error"
    }

    codes[code]
  end
end
