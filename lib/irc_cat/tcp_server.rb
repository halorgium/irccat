# The TCP Server
module IrcCat
  class TcpServer
    def self.run(bot, config)
      new(bot, config).run
    end

    def initialize(bot, config)
      @bot, @config = bot, config
    end

    def run
      Thread.new do
        socket = TCPserver.new(ip, port)
        puts "Starting TCP (#{ip}:#{port})"

        loop do
          Thread.start(socket.accept) do |s|
            str = s.recv(@config['size'])
            sstr = str.split(/\n/)
            sstr.each do |l|
              @bot.announce("#{l}")
            end
            s.close
          end
        end
      end
    end

    def ip
      @config["ip"] || '127.0.0.1'
    end

    def port
      @config["port"] || '8080'
    end
  end
end
