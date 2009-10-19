module IrcCat
  class HttpServer
    class Unauthorized < StandardError; end
    class BadRequest < StandardError; end

    def self.run(bot, config)
      new(bot, config).run
    end

    def initialize(bot, config)
      @bot, @config = bot, config
    end

    def run
      host, port = @config['host'], @config['port']
      if handler = Rack::Handler.get(handler_name)
        Thread.new {
          handler.run(app, :Host => host, :Port => port)
        }
      else
        raise "Could not find a valid Rack handler for #{handler_name.inspect}"
      end
    end

    def handler_name
      @config["server"] || "mongrel"
    end

    def app
      endpoint = self
      builder = Rack::Builder.new
      if requires_auth?
        builder.use Rack::Auth::Basic, "irccat" do |user,pass|
          auth_user == user && auth_pass == pass
        end
      end
      if prefix = @config["prefix"]
        builder.map prefix do
          run endpoint
        end
      else
        builder.run endpoint
      end
      builder
    end

    def auth_user
      @config["user"]
    end

    def auth_pass
      @config["pass"]
    end

    def requires_auth?
      if auth_user
        if auth_pass
          if auth_pass.empty?
            raise "Empty HTTP password in config"
          end
          true
        end
      end
    end

    def call(env)
      request = Rack::Request.new(env)

      case request.path_info
      when "/"
        [200, {"Content-Type" => "text/plain"}, "OK"]
      when "/topic"
        message = request.params["message"]
        if channel = request.params["channel"]
          @bot.join_channel("##{channel}", request.params["key"])
          @bot.topic("##{channel}", message)
        else
          raise "Need a channel"
        end

        [200, {"Content-Type" => "text/plain"}, "OK"]
      when "/send"
        raise "Send support is not enabled" unless @config["send"]

        message = request.params["message"]
        if channel = request.params["channel"]
          @bot.join_channel("##{channel}", request.params["key"])
          @bot.say("##{channel}", message)
        elsif nick = request.params["nick"]
          @bot.say(nick, message)
        else
          raise "Unknown action"
        end

        [200, {"Content-Type" => "text/plain"}, "OK"]
      when "/github"
        raise "GitHub support is not enabled" unless @config["github"]

        data = JSON.parse(request.POST['payload'])

        repository = data['repository']['name']
        data['commits'].each do |commit|
          topic = commit['message'].split("\n").first
          ref =   commit['id'][0,7]
          author = commit['author']['name']
          @bot.announce "#{topic} - #{ref} - #{author}"
        end

        [200, {"Content-Type" => "text/plain"}, "OK"]
      else
        [404, {}, ""]
      end
    rescue Unauthorized
      [401, {'WWW-Authenticate' => %(Basic realm="IrcCat")}, 'Authorization Required']
    rescue BadRequest
      [400, {}, 'Bad Request']
    rescue Exception => e
      puts "Got an error: #{e.class}, #{e.message}"
      e.backtrace.each do |b|
        puts "- #{b}"
      end
      [503, {}, "ERR"]
    end
  end
end
