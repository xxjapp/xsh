#!/usr/bin/env ruby
# encoding: UTF-8

require 'socket'
require 'digest/md5'

class Client
    def initialize(server)
        @server = server
    end

    def run()
        greetings = @server.gets.chomp
        puts greetings.force_encoding('UTF-8')

        process_thread = Thread.new do
            loop {
                print "[#{Time.now.strftime('%F %T')}] # "
                request = $stdin.gets.chomp
                next if request.empty?

                request.encode!('UTF-8')
                req_id = Digest::MD5.hexdigest(Random.rand.to_s)[0..7]

                @server.puts(req_id)
                @server.puts(request)

                loop {
                    response = @server.gets.chomp
                    break if response == req_id
                    puts response.force_encoding('UTF-8')
                }
            }
        end

        process_thread.join
    end
end

server = TCPSocket.open("localhost", 3000)
Client.new(server).run
