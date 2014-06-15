#!/usr/bin/env ruby
# encoding: UTF-8

require 'socket'
require 'digest/md5'
require 'readline'

HOST = 'localhost'
PORT = '3000'

XSH_HISTORY = File.expand_path('~/.xsh_history')
INIT        = "init"

class Client
    @@files = []

    def initialize(server)
        @server = server
        init_history()
    end

    def self.files
        @@files
    end

    def run()
        greetings = get_line()
        puts greetings

        # handle init response
        handle_response(INIT)

        process_thread = Thread.new do
            loop {
                request = get_request()
                next if request.empty?
                next if handle_local_request? request

                req_id = Digest::MD5.hexdigest(Random.rand.to_s)[0..7]

                send_line req_id
                send_line request

                handle_response(req_id)
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
        line = Readline.readline("[#{Time.now.strftime('%F %T')} #{@sdir}] # ", true)
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

    def handle_local_request?(request)
        case request.downcase.to_sym
        when :history
            dump_history()
            return true
        else
            return false
        end
    end

    def dump_history()
        w = Readline::HISTORY.size.to_s.size
        i = 0

        Readline::HISTORY.each { |cmd|
            printf " %#{w}d %s\n", i += 1, cmd.force_encoding(Encoding.default_external)
        }
    end

    def handle_response(req_id)
        response_status = :ready

        loop {
            response = get_line() if response_status != :end

            case response_status
            when :ready
                case response
                when "#{req_id}:info"
                    response_status = :info
                when req_id
                    response_status = :end
                else
                    puts response
                end
            when :info
                case response
                when req_id
                    response_status = :end
                else
                    info = response.split(':', 2)
                    handle_info info[0], info[1]
                end
            when :end
                break
            end
        }
    end

    def handle_info(key, value)
        case key.to_sym
        when :exit
            Thread.exit
        when :sdir
            @sdir = value
        when :ls
            handle_ls value.split("\0")
        else
            puts "#{key} not supported yet"
        end
    end

    def handle_ls(files)
        @@files = files.sort
    end
end

Readline.completion_append_character = ' '
Readline.completion_proc = proc { |s| Client.files.grep( /^#{Regexp.escape(s)}/ ) }

server = TCPSocket.open(HOST, PORT)
Client.new(server).run
