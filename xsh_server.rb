#!/usr/bin/env ruby
# encoding: UTF-8

require 'socket'

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
      request.force_encoding('UTF-8').encode!(Encoding.default_external)

      puts request

      begin
        response = `#{request} 2>&1`.chomp
        response.encode!('UTF-8')
      rescue => e
        response = e
      end

      puts response

      client.puts response
    }
  end
end

Server.new(3000, "localhost").run
