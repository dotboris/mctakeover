Minecraft takeover
==================

This is a proof of concept exploit for the game Minecraft. This exploit does a basic man in the middle attack on a minecraft server. 
There are 2 components to this attack: a target server and a decoy.

The way the exploit works as follows. We start the exploit and we start a decoy minecraft server. The exploit poses as a minecraft
server. When a client connects to the exploit server we open a connection to the target server and the decoy server. Because of the
way minecraft servers handle authentication, it is possible for us to connect to a server as another user. The decoy server is
configured to be in offline mode and will accept any connection without checking the validity of the user. The client's connection
is tunneled to the decoy server while the connection to the target server is left untouched.

When a special user (identified by their name) connects to the exploit server, their connection is tunnelled to one of the already
open connections to the target server.

Why this works
==============

When a client connects to a minecraft server, they are asked by the server to authenticate themselves with the central minecraft
server. There, they are given a session id. They relay this session id to the minecraft server. The server checks with the central
minecraft server to validate the user's name.

When a client connects to the server, the exploit initiates a connection with both the decoy server and the target server. The
target server requests a session with minecraft's central servers. We relay this request to the client. The client sens back a
session. We relay that session to the target server. This concludes the handshake with the target server. We also do a handshake
with the decoy server. When we do this, we pretend to be the client. Since the decoy server is in private mode, they will not
check our identity claim.

At this point, the client is distracted by our decoy server and we have an open connection to the target server that already
passed the handshake process. All we have to do now, is tunnel connections.

Disclaimers
===========

This code is pretty old. I am not certain as to whether or not this exploit still works. I am also writing this readme long after
the initial creation of this proof of concept. I may have missed some details about the handshake process.

This code is pretty messy and ugly. This was one of my first ruby projects. At the time, I didn't know all the standards for ruby
code.

