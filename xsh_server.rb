#!/usr/bin/env ruby
# encoding: UTF-8

require 'socket'
require 'open3'
require 'awesome_print'

# SEE: https://github.com/gimite/web-socket-ruby/issues/6
HOST = '0.0.0.0'
PORT = '3000'
HOME = File.expand_path('~')

class Server
    def initialize(host, port)
        @server = TCPServer.open(host, port)
        puts "#{@server} started OK!"
    end

    def run()
        loop {
            Thread.start(@server.accept) do | client |
                send_line(client, "#{client}: Connection established!")
                process(client, 'init', 'cd ~')
            end
        }.join
    end

    def process(client, req_id, request)
        loop {
            # handle request
            req_id  ||= get_line(client)
            request ||= get_line(client)

            # log request
            puts "/--------------------------------------------------------------"
            puts "client  : #{client}"
            puts "req_id  : #{req_id}"
            puts "request : #{request}"

            cmd    = request.encode(Encoding.default_external)
            params = parse(cmd)
            status = :unknown

            # save req_id & client
            params[:req_id] = req_id
            params[:client] = client

            # handle response
            begin
                # exit?
                if params[:exit]
                    # send cmd info
                    send_info(params, :exit, :yes)
                    status = :exit
                    return
                end

                if params[:cd]
                    dir = File.expand_path(params[:path])
                    Dir.chdir dir

                    # send short dir info
                    send_info(params, :sdir, short_dir(dir))

                    # send file list info
                    # send_info(params, :ls, `ls`)

                    status = :ok
                elsif !params[:no_output]
                    Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
                        # stdin not supported
                        stdin.close

                        puts "--------------------------------"

                        stdout.each_line { |line| send_line(client, line) }
                        stderr.each_line { |line| send_line(client, line) }

                        status = wait_thr.value
                    end
                else
                    cmd = params[:cmd]
                    Open3.popen3(cmd)
                    status = :ok
                end
            rescue => e
                send_line client, e.to_s.force_encoding(Encoding.default_external)
                status = :error
            ensure
                # close response send
                close_send(params)

                puts "--------------------------------"
                puts "status  : #{status}"
                puts "\\--------------------------------------------------------------"

                # clear status
                req_id  = nil
                request = nil
            end
        }
    rescue => e
        puts "Error during processing: #{$!}"
        puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"

        raise e
    end

private

    def short_dir(dir)
        return '~' if dir == HOME
        return dir.split('/')[-1]
    end

    def get_line(client)
        line = client.gets.chomp
        line.force_encoding('UTF-8')
    end

    def send_line(client, line)
        encoded = line.encode('UTF-8')
        client.puts encoded
        puts encoded
    end

    def send_info(params, key, value)
        if !params[:info]
            params[:info] = true
            puts "--------------------------------"

            send_line params[:client], "#{params[:req_id]}:info"
        end

        send_line params[:client], "#{key.to_s}:#{value.to_s}"
    end

    def close_send(params)
        return if params[:closed]
        params[:closed] = true

        send_line params[:client], params[:req_id]
    end

    def parse(cmd)
        params = {}
        exe    = File.basename(cmd.split[0], ".*").downcase.to_sym

        case exe
        when :start
            params[:no_output] = true
            params[:cmd]       = cmd.split[1..-1].join(' ')
        when :exit
            params[:exit]      = true
        when :cd
            params[:cd]        = true
            params[:path]      = cmd.split[1..-1].join(' ')
            params[:path]      = '~' if params[:path].empty?    # use linux way
        end

        print 'params  = '
        ap params

        return params
    end
end

Server.new(HOST, PORT).run
