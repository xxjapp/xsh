#!/usr/bin/env ruby
# encoding: UTF-8

require "socket"

class Client
  def initialize(server)
    @server = server
  end

  def run()
    request_thread  = send()
    response_thread = listen()

    request_thread.join
    response_thread.join
  end

  def listen
    Thread.new do
      loop {
        msg = @server.gets.chomp
        puts msg
      }
    end
  end

  def send
    Thread.new do
      loop {
        msg = $stdin.gets.chomp
        @server.puts(msg)
      }
    end
  end
end

server = TCPSocket.open("localhost", 3000)
Client.new(server).run
