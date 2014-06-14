#!/usr/bin/env ruby
# encoding: UTF-8

require 'socket'
require 'open3'

# SEE: https://github.com/gimite/web-socket-ruby/issues/6
HOST = '0.0.0.0'
PORT = '3000'

class Server
    def initialize(host, port)
        @server = TCPServer.open(host, port)
        puts "#{@server} started OK!"
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
                cmd     = request.encode(Encoding.default_external)
                options = parse(cmd)

                Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
                    # stdin not supported
                    stdin.close

                    if !options[:no_output]
                        stdout.each_line { |line| send_line(client, line) }
                        stderr.each_line { |line| send_line(client, line) }
                    end

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

    def parse(cmd)
        options = {}
        exe     = File.basename(cmd.split[0], ".*").downcase.to_sym

        case exe
        when :start
            options[:no_output] = true
        end

        return options
    end
end

Server.new(HOST, PORT).run
