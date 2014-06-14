#!/usr/bin/env ruby
# encoding: UTF-8

require 'socket'

class Client
    def initialize(server)
        @server = server
    end

    def run()
        msg = @server.gets.chomp
        puts msg.force_encoding('UTF-8')

        process_thread = Thread.new do
            loop {
                print "[#{Time.now.strftime('%F %T')}] # "
                msg = $stdin.gets.chomp
                next if msg.empty?

                msg.encode!('UTF-8')
                req_id = Random.rand.to_s

                @server.puts(req_id)
                @server.puts(msg)

                loop {
                    msg = @server.gets.chomp
                    break if msg == req_id
                    puts msg.force_encoding('UTF-8')
                }
            }
        end

        process_thread.join
    end
end

server = TCPSocket.open("localhost", 3000)
Client.new(server).run
