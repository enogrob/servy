defmodule ServyTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Servy.Handler, as: Subject
  doctest Servy

  test "Responds to handle properly" do
    request = """
      GET /wildthings HTTP/1.1
      Host: example.com
      User-Agent: ExampleBrowser/1.0
      Accept: */*

      """

    result = Subject.handle(request)
    assert result == """
      HTTP/1.1 200 OK
      Content-Type: text/html
      Content-Length: 32

      🎉🎉🎉🎉🎉
      Bears, Lions, Tigers
      🎉🎉🎉🎉🎉
      """
  end

  test "Responds to parse properly" do
    request = """
      GET /wildthings HTTP/1.1
      Host: example.com
      User-Agent: ExampleBrowser/1.0
      Accept: */*

      """
    result = Subject.parse(request)
    assert result == %{ method: "GET", path: "/wildthings", resp_body: "", status: nil}
  end

  test "Responds to rewrite_path properly" do
    conv = %{ method: "GET", path: "/bears?id=1", resp_body: "", status: nil }
    result = Subject.rewrite_path(conv)
    assert result == %{ method: "GET", path: "/bears/1", resp_body: "", status: nil }
    conv = %{ method: "GET", path: "/wildlife", resp_body: "", status: nil }
    result = Subject.rewrite_path(conv)
    assert result == %{ method: "GET", path: "/wildthings", resp_body: "", status: nil }
  end

  test "Responds to log properly" do
    conv = %{ method: "GET", path: "/wildthings", resp_body: "Bears, Lions, Tigers" }
    result = Subject.log(conv)
    assert result == %{method: "GET", path: "/wildthings", resp_body: "Bears, Lions, Tigers"}
  end

  test "Responds to route properly" do
    conv = %{ method: "GET", path: "/wildthings", resp_body: "", status: nil}
    result = Subject.route(conv)
    assert result == %{ method: "GET", path: "/wildthings", resp_body: "Bears, Lions, Tigers", status: 200 }
    conv = %{ method: "GET", path: "/bears", resp_body: "", status: nil }
    result = Subject.route(conv)
    assert result == %{ method: "GET", path: "/bears", resp_body: "Teddy, Smokey, Paddington", status: 200 }
    conv = %{ method: "GET", path: "/bears/1", resp_body: "", status: nil }
    result = Subject.route(conv)
    assert result == %{ method: "GET", path: "/bears/1", resp_body: "Bear 1", status: 200 }
    conv = %{ method: "DELETE", path: "/bears/1", resp_body: "", status: nil }
    result = Subject.route(conv)
    assert result == %{ method: "DELETE", path: "/bears/1", resp_body: "Deleting a bear is forbidden!", status: 403 }
    conv = %{ method: "GET", path: "/teddy", resp_body: "", status: nil }
    result = Subject.route(conv)
    assert result == %{ method: "GET", path: "/teddy", resp_body: "No /teddy here!", status: 404 }
  end

  test "Responds to emojify properly" do
    conv = %{ method: "GET", path: "/wildlife", resp_body: "Bears, Lions, Tigers", status: 200 }
    assert Subject.emojify(conv) == %{ method: "GET", path: "/wildlife", resp_body: "🎉🎉🎉🎉🎉\nBears, Lions, Tigers\n🎉🎉🎉🎉🎉", status: 200 }
  end

  test "Responds to track properly" do
    conv = %{ method: "GET", path: "/wild", resp_body: "", status: 404 }
    Subject.track(conv) == """
      Warning: /wild is on the loose!
      """
  end

  test "Responds to format_response properly" do
    conv = %{ method: "GET", path: "/wildthings", resp_body: "Bears, Lions, Tigers", status: 200}
    IO.puts Subject.format_response(conv) == """
      HTTP/1.1 200 OK
      Content-Type: text/html
      Content-Length: 20
      Bears, Lions, Tigers
      """
  end
end
