# This is the bot.
# Original code by Madx (yapok.org)

module IrcCat
  class Bot
    def self.run(host, port, nick, nick_pass = nil, &block)
      new(host, port, nick, nick_pass, &block).run
    end

    def initialize(host, port, nick, nick_pass, &block)
      @host, @port, @nick, @nick_pass = host, port, nick, nick_pass
      @connect_block = block

      @realname = "irccat v#{VERSION::STRING}"
      @refresh_rate = 10
      @channels = {}

      puts "Connecting to IRC #{@host}:#{@port}"
    end

    def run(&block)
      @socket = TCPSocket.open(@host, @port)
      login

      trap(:INT) {
        puts "Bye bye."
        sexit('God^WConsole killed me')
        sleep 1
        @socket.close
        exit
      }

      threads = []

      threads << Thread.new {
        begin
          while line = @socket.gets do
            # Remove all formatting
            line.gsub!(/[\x02\x1f\x16\x0f]/,'')
            # Remove CTCP ASCII
            line.gsub!(/\001/,'')
            # Send to event handler
            handle line
            # Handle Pings from Server
            sendln "PONG #{$1}" if /^PING\s(.*)/ =~ line
          end
        rescue EOFError
          err 'Server Reset Connection'
        rescue Exception => e
          err e
        end
      }
      threads << Thread.new {
      }
      threads.each { |th| th.join }
    end

    # Announces states
    def announce(msg)
      @channels.each do |channel,key|
        say(channel, msg)
      end
    end

    # Say something funkeh
    def say(chan, msg)
      sendln "PRIVMSG #{chan} :#{msg}"
    end

    # Send EXIT
    def sexit(message = 'quit')
      sendln "QUIT :#{message}"
    end

    # Sends a message to the server

    def sendln(cmd)
      puts "Send: #{cmd}"
      if cmd.size <= 510
        @socket.write("#{cmd}\r\n")
        STDOUT.flush
      else
      end
    end

    # Handle a received message

    def handle(line)
      puts "Got: #{line}"
      case line
      when /^:.+\s376/
        puts "We're online"
        @connect_block.call(self)
      when /^:.+KICK (#[^\s]+)/
        auto_rejoin($1)
      end
    end

    # Automatic events

    def join_channel(channel, key)
      @channels[channel] = key
      $stdout.flush
      if key
        sendln "JOIN #{channel} #{key}"
      else
        sendln "JOIN #{channel}"
      end
    end

    def auto_rejoin(channel)
      join_channel(channel, @channels[channel])
    end

    def login
      begin
        sendln "NICK #{@nick}"
        sendln "USER irc_cat . . :#{@realname}"
        if @nick_pass
          puts "logging in to NickServ"
          sendln "PRIVMSG NICKSERV :identify #{@nick_pass}"
        end
      rescue Exception => e
        err e
      end
    end

    # Logging methods

    def log(str)
      $stdout.puts "DEBUG: #{str}"
    end

    def err(exception)
      $stderr.puts "ERROR: #{exception}"
      $stderr.puts "TRACE: #{exception.backtrace}"
    end
  end
end
