module Kontena
  class AcmeWorker
    include Celluloid
    include Celluloid::Logger
    include Celluloid::Notifications

    attr_reader :email, :domains, :debug

    ACME_CMD = "lego"
    ACME_CERT_DIR = "/var/lib/acme/"
    ACME_LOGS_DIR = ACME_CERT_DIR + "logs"
    ACME_LOG_FILE = "#{ACME_LOGS_DIR}/console.log".freeze

    # @param [String] email
    # @param [Array<String>] domains
    # @param [Boolean] debug
    # @param [Boolean] autostart
    def initialize(email, domains, debug = false, autostart = true)
      # Local copy of the incoming parameters
      @domains, @email, @debug = domains, email, debug
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
          sleep (60*60*24*7) unless debug # week
          sleep (60*2) if debug # 2 minutes
          domains.each{|d|
            reconcile_domain(d)
            copy_domain_cert(d)
          }
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
        success = system("#{ACME_CMD} -a -m #{email} -d #{domain} --http --http.port 127.0.0.1:402 --path #{ACME_CERT_DIR} --pem run >> #{ACME_LOG_FILE}")
        if success
          info "Fetched cert for domain #{domain}, expecting 'lego' to finish write operations by that time"
        else
          retries += 1
          raise "failed to fetch cert for domain #{domain}"
        end
      rescue => exc
        info exc.message
        # In case of an exception, display acme logs as well
        info File.read ACME_LOG_FILE
        wait = 10 * retries
        info "Retrying certificate fetch for '#{domain}' in #{wait} seconds"
        sleep wait
        retry
      end
    end

    # @param [String] domain
    def copy_domain_cert(domain)
      file_path = ACME_CERT_DIR + "certificates/#{domain}.pem"
      # Each pem file at the destination must have timestamp suffix
      ssl_path = "/etc/ssl/private/#{domain}.pem"
      if File.exist?(file_path)
        info "Copying #{domain} certificate to '#{ssl_path}'"
        system("cp -fv #{file_path} #{ssl_path} >> #{ACME_LOG_FILE}")
      elsif File.exist?(ssl_path)
        system("rm -fv #{ssl_path} >> #{ACME_LOG_FILE}")
        info "Removing certificate from #{domain} at '#{ssl_path}'"
      end
    end

    # @return [Boolean]
    def reconcile_domain(domain)
      retries = 0
      begin
        # lego -m <email> -d <domain> --http --path /var/lib/acme --pem renew
        success = system("#{ACME_CMD} -m #{email} -d #{domain} --http --http.port 127.0.0.1:402 --path #{ACME_CERT_DIR} --pem renew #{'--days 999' if debug} >> #{ACME_LOG_FILE}")
        if success
          info "Renewed cert for domain #{domain}, expecting 'lego' to finish write operations by that time"
        else
          retries += 1
          raise "Failed to renew cert for domain #{domain}"
        end
      rescue => exc
        info exc.message
        # In case of an exception, display acme logs as well
        info File.read ACME_LOG_FILE
        wait = 10 * retries
        info "Retrying certificate renewal for '#{domain}' in #{wait} seconds"
        sleep wait
        retry
      end
    end
  end
end
