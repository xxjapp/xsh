#!/usr/bin/env ruby
# encoding: UTF-8

require "socket"

class Server
  def initialize( port, ip )
    @server = TCPServer.open( ip, port )
    run
  end

  def run
    loop {
      Thread.start(@server.accept) do | client |
        client.puts "username: "
        username = client.gets.chomp

        client.puts "password: "
        password = client.gets.chomp

        puts "#{username} #{password} #{client}"

        client.puts "Connection established!"
        listen_user_messages( username, client )
      end
    }.join
  end

  def listen_user_messages( username, client )
    loop {
      msg = client.gets.chomp
      client.puts "#{username}: #{msg}"
    }
  end
end

Server.new( 3000, "localhost" )
