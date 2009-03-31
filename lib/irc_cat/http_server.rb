# The HTTP Server

require 'rack'
#require 'json'

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
      Thread.new {
        Rack::Handler::Mongrel.run(self, :Host => host, :Port => port)
      }
    end

    def call(env)
      auth = Rack::Auth::Basic::Request.new(env)

      raise Unauthorized unless auth.provided?
      raise BadRequest unless auth.basic?
      username, password = auth.credentials
      raise Unauthorized unless @config["user"] == username && @config["pass"] == password

      request = Rack::Request.new(env)

      case request.path_info
      when "/"
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

        require 'json'
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
