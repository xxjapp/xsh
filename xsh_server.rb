#!/usr/bin/env ruby
# encoding: UTF-8

require "socket"

class Server
  def initialize(port, ip)
    @server = TCPServer.open(ip, port)
  end

  def run()
    loop {
      Thread.start(@server.accept) do | client |
        client.puts "Connection established!"
        process(client)
      end
    }.join
  end

  def process(client)
    loop {
      request = client.gets.chomp
      response = "#{request} OK"

      puts request
      puts response

      client.puts response
    }
  end
end

Server.new(3000, "localhost").run
