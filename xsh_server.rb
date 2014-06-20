#!/usr/bin/env ruby
# encoding: UTF-8

require 'socket'
require 'open3'
require 'awesome_print'
require './compgen'

# SEE: https://github.com/gimite/web-socket-ruby/issues/6
HOST = '0.0.0.0'
PORT = '620'

HOME = File.expand_path('~')
INIT = "init"

class Server
    def initialize(host, port)
        redirect_output_to_log_file

        @server = TCPServer.open(host, port)
        @exes   = CompGen.get.join("\0")
        puts "#{@server} started OK!"
    end

    def redirect_output_to_log_file
        $stdout.reopen("service.log", "w")
        $stdout.sync = true
        $stderr.reopen($stdout)
    end

    def run()
        loop {
            Thread.start(@server.accept) do | client |
                send_line(client, "#{client}: Connection established!")
                process(client, INIT, 'cd ~')
            end
        }.join
    end

    def process(client, req_id, request)
        session = {}

        loop {
            # handle request
            req_id  ||= get_line(client)
            request ||= get_line(client)

            if !req_id
                # user may pressed ^C to exit
                puts "#{client}: exit by ^C"
                return
            end

            # log request
            puts "/--------------------------------------------------------------"
            puts "client  : #{client}"
            puts "req_id  : #{req_id}"
            puts "request : #{request}"

            # save params info
            params = {}
            params[:req_id]  = req_id
            params[:client]  = client
            params[:session] = session

            cmd    = request.encode(Encoding.default_external)
            status = :unknown

            parse(params, cmd)

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
                    curr_dir = session[:curr_dir]
                    dir      = File.expand_path(params[:dir])

                    if dir != curr_dir
                        Dir.chdir dir

                        send_info(params, :sdir, short_dir(dir))
                        send_info(params, :exes, @exes) if req_id == INIT

                        session[:curr_dir] = dir
                        session[:prev_dir] = curr_dir
                    end

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
                # send file list info
                send_file_list_info(params)

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
        client.close

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
        line = client.gets
        line == nil ? nil : line.chomp.force_encoding('UTF-8')
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

    def send_file_list_info(params)
        session = params[:session]
        ls      = get_file_list_info()

        if ls != session[:prev_ls]
            send_info(params, :ls, ls)
            session[:prev_ls] = ls
        end
    end

    def close_send(params)
        return if params[:closed]
        params[:closed] = true

        send_line params[:client], params[:req_id]
    end

    def parse(params, cmd)
        exe = File.basename(cmd.split[0], ".*").downcase.to_sym

        case exe
        when :start
            params[:no_output] = true
            params[:cmd]       = cmd.split[1..-1].join(' ')
        when :exit
            params[:exit]      = true
        when :cd
            params[:cd]        = true
            params[:dir]       = cmd.split[1..-1].join(' ')
            handle_cd_dir(params)
        end

        print 'params  = '
        ap params

        return params
    end

    def handle_cd_dir(params)
        if params[:dir] == '-'
            params[:dir] = params[:session][:prev_dir]
        end

        params[:dir] = '~' if params[:dir].to_s.empty?    # use linux way
    end

    def get_file_list_info()
        Dir["*"].join("\0")
    end
end

if __FILE__ == $0
    Server.new(HOST, PORT).run
end
