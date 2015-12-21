require_relative 'server'
require 'logger'


MAX_THREADS  = 10
STUDENT_ID   = 'a04dcb0fee025f2b48663ba413d0b8d481db11b65b254d41e3611b834c17d6d5'
DEFAULT_PORT = 5000
port_number = ARGV[0] || DEFAULT_PORT

Thread.current['id'] = 0

# Make a logger
logger = Logger.new('log/server.log')
logger.formatter = proc do |severity, datetime, progname, msg|
  "#{severity} [#{Time.now.strftime('%H:%M:%S')}] T#{Thread.current['id']}: #{msg}\n"
end
logger.info 'made logger'
puts 'made logger'
puts "using port: #{port_number}"


# Make server
server = Server.new(logger, STUDENT_ID)
server.run(port_number, MAX_THREADS)

