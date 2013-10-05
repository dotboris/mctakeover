#!/usr/bin/env ruby

require 'socket'
require_relative 'mc_conn'

# config
TARGET_HOST = 'localhost'
TARGET_PORT = 25565
DECOY_HOST = '127.0.0.1'
DECOY_PORT = 6000
LISTEN_PORT = 7000
TAKEOVER_USER = 'Player'

# start server
puts "Listening on port #{LISTEN_PORT}"
puts "Target: #{TARGET_HOST}:#{TARGET_PORT}"
puts "Decoy: #{DECOY_HOST}:#{DECOY_PORT}"
server = TCPServer.new LISTEN_PORT

# threads
threads = []

# start accepting connections
loop do
  threads << Thread.start(server.accept) do |sock|
    begin
      _, port, host = *sock.peeraddr(false)
      puts "Got commection from #{host}:#{port}"
      connection = McConn.new sock
      connection.run
    rescue => e
      puts 'Crashed :('
      puts e.message
      puts e.backtrace.join "\n\t"
    ensure
      sock.close
    end
  end
end
