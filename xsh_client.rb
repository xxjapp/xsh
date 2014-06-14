#!/usr/bin/env ruby
# encoding: UTF-8

require 'socket'
require 'digest/md5'

HOST = 'localhost'
PORT = '3000'

class Client
    def initialize(server)
        @server = server
    end

    def run()
        greetings = get_line()
        puts greetings

        process_thread = Thread.new do
            loop {
                print "[#{Time.now.strftime('%F %T')}] # "
                request = $stdin.gets.chomp
                next if request.empty?

                req_id = Digest::MD5.hexdigest(Random.rand.to_s)[0..7]

                send_line req_id
                send_line request

                loop {
                    response = get_line()

                    if response.start_with? req_id
                        cmd = response.split(':')[1]

                        case cmd
                        when 'exit'
                            Thread.exit
                        else
                            break
                        end
                    end

                    puts response
                }
            }
        end

        begin
            process_thread.join
        rescue Interrupt => e
            puts
        ensure
            puts "Connection to #{HOST} closed."
        end
    end

private

    def get_line()
        line = @server.gets.chomp
        line.force_encoding('UTF-8')
    end

    def send_line(line)
        encoded = line.encode('UTF-8')

        @server.puts encoded
        # puts encoded
    end
end

server = TCPSocket.open(HOST, PORT)
Client.new(server).run
