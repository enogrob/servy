defmodule Servy.Plugins do
  require Logger

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
end
