defmodule ServyTest do
  use ExUnit.Case
#  import ExUnit.CaptureIO
  import ExUnit.CaptureLog

  alias Servy.Handler, as: Subject
  alias Servy.Plugins, as: Plugins
  alias Servy.Parser, as: Parser
  alias Servy.Conv, as: Conv

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
    result = Parser.parse(request)
    assert result == %Conv{ method: "GET", path: "/wildthings", resp_body: "", status: nil}
  end

  test "Responds to rewrite_path properly" do
    conv = %Conv{ method: "GET", path: "/bears?id=1", resp_body: "", status: nil }
    result = Plugins.rewrite_path(conv)
    assert result == %Conv{ method: "GET", path: "/bears/1", resp_body: "", status: nil }
    conv = %Conv{ method: "GET", path: "/wildlife", resp_body: "", status: nil }
    result = Plugins.rewrite_path(conv)
    assert result == %Conv{ method: "GET", path: "/wildthings", resp_body: "", status: nil }
  end

  test "Responds to log properly" do
    conv = %Conv{ method: "GET", path: "/wildthings", resp_body: "Bears, Lions, Tigers" }
    result = Plugins.log(conv)
    assert result == %Conv{method: "GET", path: "/wildthings", resp_body: "Bears, Lions, Tigers"}
  end

  test "Responds to route properly" do
    conv = %Conv{ method: "GET", path: "/wildthings", resp_body: "", status: nil}
    result = Subject.route(conv)
    assert result == %Conv{ method: "GET", path: "/wildthings", resp_body: "Bears, Lions, Tigers", status: 200 }
    conv = %Conv{ method: "GET", path: "/bears", resp_body: "", status: nil }
    result = Subject.route(conv)
    assert result == %Conv{ method: "GET", path: "/bears", resp_body: "Teddy, Smokey, Paddington", status: 200 }
    conv = %Conv{ method: "GET", path: "/bears/1", resp_body: "", status: nil }
    result = Subject.route(conv)
    assert result == %Conv{ method: "GET", path: "/bears/1", resp_body: "Bear 1", status: 200 }
    conv = %Conv{ method: "DELETE", path: "/bears/1", resp_body: "", status: nil }
    result = Subject.route(conv)
    assert result == %Conv{ method: "DELETE", path: "/bears/1", resp_body: "Deleting a bear is forbidden!", status: 403 }
    conv = %Conv{ method: "GET", path: "/teddy", resp_body: "", status: nil }
    result = Subject.route(conv)
    assert result == %Conv{ method: "GET", path: "/teddy", resp_body: "No /teddy here!", status: 404 }
    conv = %Conv{ method: "GET", path: "/about", resp_body: "", status: nil }
    result = Subject.route(conv)
    {:ok, content} = File.read("pages/about.html")
    assert result == %Conv{ method: "GET", path: "/about", resp_body: content, status: 200 }
    conv = %Conv{ method: "GET", path: "/pages/contact", resp_body: "", status: nil }
    result = Subject.route(conv)
#    {:ok, content} = File.read("pages/about.html")
    assert result == %Conv{ method: "GET", path: "/pages/contact", resp_body: "File not found", status: 404 }
  end

  test "Responds to emojify properly" do
    conv = %Conv{ method: "GET", path: "/wildlife", resp_body: "Bears, Lions, Tigers", status: 200 }
    assert Subject.emojify(conv) == %Conv{ method: "GET", path: "/wildlife", resp_body: "🎉🎉🎉🎉🎉\nBears, Lions, Tigers\n🎉🎉🎉🎉🎉", status: 200 }
  end

  test "Responds to track properly" do
    conv = %Conv{ method: "GET", path: "/wild", resp_body: "", status: 404 }
    fun = fn -> Plugins.track(conv) end
    assert capture_log(fun) =~ "Warning /wild is on the loose"
  end

  test "Responds to format_response properly" do
    conv = %Conv{ method: "GET", path: "/wildthings", resp_body: "Bears, Lions, Tigers", status: 200}
    assert IO.puts Subject.format_response(conv) == """
      HTTP/1.1 200 OK
      Content-Type: text/html
      Content-Length: 20
      Bears, Lions, Tigers
      """
  end
end
