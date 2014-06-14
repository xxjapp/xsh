#!/usr/bin/env ruby
# encoding: UTF-8

require 'socket'
require 'digest/md5'
require 'readline'

HOST = 'localhost'
PORT = '3000'

XSH_HISTORY = File.expand_path('~/.xsh_history')

class Client
    def initialize(server)
        @server = server
        init_history()
    end

    def run()
        greetings = get_line()
        puts greetings

        process_thread = Thread.new do
            loop {
                request = get_request()
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

    def init_history()
        IO.foreach(XSH_HISTORY, encoding: 'UTF-8') do |line|
            # Readline uses strings of Encoding.default_external but must pretend to be of 'ASCII-8BIT'
            line = line.chomp.encode(Encoding.default_external).force_encoding('ASCII-8BIT')
            Readline::HISTORY.push(line)
        end
    rescue Errno::ENOENT => e
        # No such file or directory: OK
    end

    def get_request()
        line = Readline.readline("[#{Time.now.strftime('%F %T')}] # ", true)
        return nil if line.nil?

        # restore lines from Readline to its correct encoding 'Encoding.default_external'
        corrent_line = line.clone.force_encoding(Encoding.default_external)

        if corrent_line =~ /^\s*$/ or Readline::HISTORY.to_a[-2] == line
            Readline::HISTORY.pop
        else
            # write to histroy
            File.open(XSH_HISTORY, 'a', encoding: 'UTF-8') { |file| file.puts corrent_line }
        end

        corrent_line
    end

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
