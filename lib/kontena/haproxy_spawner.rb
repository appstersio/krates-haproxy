
module Kontena
  class HaproxySpawner
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    ##
    # @param [String] config_file
    def initialize(haproxy_bin = '/usr/local/sbin/haproxy', config_file = '/usr/local/etc/haproxy/haproxy.cfg')
      @current_pid = nil
      @haproxy_cmd = [haproxy_bin, '-f', config_file, '-db', '-d']
      subscribe 'haproxy:config_updated', :update_haproxy
      info '~~ Starting Krates HAProxy ~~'
    end

    def update_haproxy(*args)
      if current_pid
        reload_haproxy
      else
        start_haproxy
      end
    end

    def start_haproxy
      info "Starting HAProxy process ~> '#{@haproxy_cmd.join(' ')}'"
      @current_pid = Process.spawn(@haproxy_cmd.join(' '))
    end

    def reload_haproxy
      info "Requesting graceful HAProxy configuration reload via SIGUSR2 (PID: #{@current_pid})"
      Process.kill("USR2", @current_pid)
      info "Graceful HAProxy configuration reload is done (PID: #{@current_pid})"
    end

    private

    def current_pid
      @current_pid
    end
  end
end
