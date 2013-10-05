#!/usr/bin/env ruby
# encoding: utf-8

# deps
require 'socket'
load 'McConn.class.rb'

# config
TARGET_HOST = 'localhost'
TARGET_PORT = 25565
DECOY_HOST = '127.0.0.1'
DECOY_PORT = 6000
LISTEN_PORT = 7000
TAKEOVER_USER = 'Player'

# start server
puts 'Listening on port ' + LISTEN_PORT.to_s
puts 'Target: ' + TARGET_HOST + ':' + TARGET_PORT.to_s
puts 'Decoy: ' + DECOY_HOST + ':' + DECOY_PORT.to_s
server = TCPServer.new('', LISTEN_PORT)

# threads
threads = []

# start accepting connections
loop do
  threads << Thread::start(server.accept()) do |sock|
    begin
      puts 'Got connection from ' + sock.peeraddr(false)[2] + 
        ':' + sock.peeraddr(false)[1].to_s
      connection = McConn.new(sock)
      connection.run
    rescue => e
      puts 'Crashed :('
      puts e.message
      puts e.backtrace.inspect
    ensure
      sock.close
    end
  end
end
