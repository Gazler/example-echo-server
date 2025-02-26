import gleam/bit_builder.{BitBuilder}
import gleam/bit_string
import gleam/result
import gleam/string
import gleam/elli
import gleam/http.{Get, Post}
import gleam/http/middleware
import echo/web/logger

fn echo(req) {
  let content_type = req
    |> http.get_req_header("content-type")
    |> result.unwrap("application/octet-stream")

  http.response(200)
  |> http.set_resp_body(req.body)
  |> http.prepend_resp_header("content-type", content_type)
}

fn not_found() {
  let body = "There's nothing here. Try POSTing to /echo"
    |> bit_string.from_string

  http.response(404)
  |> http.set_resp_body(body)
  |> http.prepend_resp_header("content-type", "text/plain")
}

fn hello(name) {
  let reply = case string.lowercase(name) {
    "mike" -> "Hello, Joe!"
    _ -> string.concat(["Hello, ", name, "!"])
  }

  http.response(200)
  |> http.set_resp_body(bit_string.from_string(reply))
  |> http.prepend_resp_header("content-type", "text/plain")
}

pub fn service(req) {
  let path = http.req_segments(req)

  case req.method, path {
    Post, ["echo"] -> echo(req)
    Get, ["hello", name] -> hello(name)
    _, _ -> not_found()
  }
}

pub fn start() {
  let service = service
    |> middleware.prepend_resp_header("made-with", "Gleam")
    |> middleware.map_resp_body(bit_builder.from_bit_string)
    |> logger.middleware

  elli.start(service, on_port: 3000)
  |> result.map_error(fn(_) { "failed to start" })
}
