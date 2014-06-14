#!/usr/bin/env ruby
# encoding: UTF-8

require 'socket'
require 'open3'

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
      # handle request
      request = client.gets.chomp
      request.force_encoding('UTF-8').encode!(Encoding.default_external)

      # log request
      puts request

      # handle response
      begin
        response, status = Open3.capture2e("#{request} 2>&1")
      rescue => e
        response = e.to_s
      end

      response.encode!('UTF-8')

      # log response
      puts response
      puts status

      # send response
      client.puts response
    }
  end
end

Server.new(3000, "localhost").run
