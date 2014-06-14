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
      puts "/------------------------------- #{client}"
      puts "request : #{request}"
      puts "--------------------------------"

      # handle response
      begin
        response, status = Open3.capture2e("#{request} 2>&1")
      rescue => e
        response = e.to_s
      end

      response.encode!('UTF-8')

      # send response
      client.puts response

      # log response
      puts response

      puts "--------------------------------"
      puts "status  : #{status}"
      puts "\\------------------------------- #{client}"
    }
  end
end

Server.new(3000, "localhost").run
