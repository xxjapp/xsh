#!/usr/bin/env ruby
# encoding: UTF-8
#
# register, unregister and start, stop service 'xsh_server'
#

require 'win32/service'
require 'win32/daemon'
include Win32

THIS_FILE     = File.expand_path(__FILE__)
THIS_FILE_DIR = File.dirname(THIS_FILE)

SERVICE       = 'xsh_server'
DESCRIPTION   = 'xsh server'
DISPLAY_NAME  = 'xsh server'

class ServiceManager
    def ServiceManager.register
        Service.create({
            service_name:         SERVICE,
            host:                 nil,
            service_type:         Service::WIN32_OWN_PROCESS,
            description:          DESCRIPTION,
            start_type:           Service::AUTO_START,
            error_control:        Service::ERROR_NORMAL,
            binary_path_name:     "#{ruby_path} -C #{THIS_FILE_DIR} #{THIS_FILE}",
            load_order_group:     'Network',
            dependencies:         nil,
            display_name:         DISPLAY_NAME
        })
    end

    def ServiceManager.start
        Service.start(SERVICE)
    end

    def ServiceManager.stop
        Service.stop(SERVICE) if Service.status(SERVICE).controls_accepted.include? 'stop'
    rescue
    end

    def ServiceManager.unregister
        Service.delete(SERVICE)
    end

private
    def ServiceManager.ruby_path
        unless @ruby_path
            bin  = RbConfig::CONFIG["RUBY_INSTALL_NAME"] || RbConfig::CONFIG["ruby_install_name"]
            bin += RbConfig::CONFIG['EXEEXT'] || RbConfig::CONFIG['exeext'] || ''
            @ruby_path = File.join(RbConfig::CONFIG['bindir'], bin)
        end

        @ruby_path
    end
end

class XshServiceDaemon < Daemon
    def service_main
        require './xsh_server'
        Server.new(HOST, PORT).run
    end

    def service_stop
        exit!
    end
end

ARGV[0] ? ServiceManager.send(ARGV[0]) : XshServiceDaemon.mainloop
