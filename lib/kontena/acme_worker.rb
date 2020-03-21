module Kontena
  class AcmeWorker
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    attr_reader :email, :domains

    ACME_CMD = "lego"
    ACME_CERT_DIR = "/var/lib/acme/"
    ACME_LOGS_DIR = ACME_CERT_DIR + "logs"

    # @param [String] email
    # @param [Array<String>] domains
    # @param [Boolean] debug
    # @param [Boolean] autostart
    def initialize(email, domains, debug = false, autostart = true)
      # Local copy of the incoming parameters
      @domains, @email = domains, email
      # Ensure logs folder exists before using it
      FileUtils.mkdir_p(ACME_LOGS_DIR) unless Dir.exist?(ACME_LOGS_DIR)
      # Switch to use staging endpoint to avoid hitting LE's prod rate limits
      ACME_CMD << " -s https://acme-staging-v02.api.letsencrypt.org/directory" if debug
      # Kick-start the main routine in case of auto-start
      async.start! if autostart
    end

    def start!
      defer {
        domains.each{|d|
          want_domain(d)
          copy_domain_cert(d)
        }
        publish 'haproxy:config_updated'
        loop do
          sleep (60*60*24*7) # week
          reconcile_domains
          publish 'haproxy:config_updated'
        end
      }
    end

    # @param [String] domain
    # @return [Boolean]
    def want_domain(domain)
      retries = 0
      begin
        # lego -a -m <email> -d <domain> --http --http.port 127.0.0.1:402 --path <state> run
        success = system("#{ACME_CMD} -a -m #{email} -d #{domain} --http --http.port 127.0.0.1:402 --path #{ACME_CERT_DIR} --pem run >> #{ACME_LOGS_DIR}/console.log")
        if success
          info "fetched cert for domain #{domain}"
        else
          retries += 1
          raise "failed to fetch cert for domain #{domain}"
        end
      rescue => exc
        info exc.message
        # In case of an exception, display acme logs as well
        info File.read("#{ACME_LOGS_DIR}/console.log")
        wait = 10 * retries
        info "retrying in #{wait} seconds"
        sleep wait
        retry
      end
    end

    # @param [String] domain
    def copy_domain_cert(domain)
      file_path = ACME_CERT_DIR + "certificates/#{domain}.pem"
      ssl_path = "/etc/ssl/private/#{domain}.pem"
      if File.exist?(file_path)
        info "copying #{domain} certificate"
        FileUtils.copy(file_path, ssl_path)
      elsif File.exist?(ssl_path)
        File.unlink(ssl_path)
        info "removing certificate from #{domain}"
      end
    end

    # @return [Boolean]
    def reconcile_domains
      # system("#{ACME_CMD} reconcile")
    end
  end
end
