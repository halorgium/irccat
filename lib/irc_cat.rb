require 'socket'
require 'rack'
require 'json'

current_dir = File.dirname(__FILE__)

require current_dir + '/irc_cat/version'
require current_dir + '/irc_cat/indifferent_access'
require current_dir + '/irc_cat/bot'
