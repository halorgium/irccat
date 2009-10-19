require 'lib/irc_cat'
require 'bundler'

@lib_module = IrcCat
@spec = Gem::Specification.new do |s|
  s.name = "irc_cat"
  s.version = IrcCat::VERSION::STRING
  s.platform = Gem::Platform::RUBY
  s.author = 'Jordan Bracco'
  s.email = "jordan@bracco.name"
  s.summary = "irccat is like `cat`, but here, the STDOUT is an IRC channel."
  s.description = s.summary
  s.homepage = "http://github.com/webs/irccat"

  manifest = Bundler::Environment.load(File.dirname(__FILE__) + '/Gemfile')
  manifest.dependencies.each do |d|
    next if d.only && d.only.include?('test')
    s.add_dependency(d.name, d.version)
  end

  s.executables = %w( icat iecho irccat irccat-config )

  s.require_path = 'lib'
  s.files = Dir.glob("lib/**/*.rb")
end

require 'rake/gempackagetask'
Rake::GemPackageTask.new(@spec) do |pkg|
  pkg.gem_spec = @spec
end
