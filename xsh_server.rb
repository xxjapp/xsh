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
                send_line(client, "#{client}: Connection established!")
                process(client)
            end
        }.join
    end

    def process(client)
        loop {
            # handle request
            req_id  = get_line(client)
            request = get_line(client)

            # log request
            puts "/--------------------------------------------------------------"
            puts "req_id  : #{req_id}"
            puts "request : #{request}"
            puts "--------------------------------"

            status = nil

            # handle response
            begin
                cmd = request.encode(Encoding.default_external)

                Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
                    stdin.close

                    stdout.each_line { |line| send_line(client, line) }
                    stderr.each_line { |line| send_line(client, line) }

                    status = wait_thr.value
                end
            rescue => e
                send_line client, e.to_s
            end

            # send response end
            send_line(client, req_id, log: false)

            puts "--------------------------------"
            puts "status  : #{status}"
            puts "\\--------------------------------------------------------------"
        }
    end

private

    def get_line(client)
        line = client.gets.chomp
        line.force_encoding('UTF-8')
    end

    def send_line(client, line, options = {})
        encoded = line.encode('UTF-8')

        client.puts encoded
        puts encoded if options[:log] != false
    end
end

Server.new(3000, "localhost").run
