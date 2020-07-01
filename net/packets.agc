#constant PACKET_TYPE_PLAYER_ID     1 // dont start at 0 because `Val(str)` uses 0 for failure
#constant PACKET_TYPE_PLAYER_STATE  2
#constant PACKET_TYPE_PLAYER_JOINED 3
#constant PACKET_TYPE_WORLD_STATE   4
#constant BACKSPACE Chr(8)

type tPlayerStatePacket
  remoteIndex as integer
  x as integer
  y as integer
endtype

type tWorldStatePacket
  players as tPlayerStatePacket[]
endtype

type tInitialPlayerDataPacket
  x as integer
  y as integer
  color as integer
  remoteIndex as integer
endtype

type tWelcomePacket
  remoteIndex as integer
  players as tInitialPlayerDataPacket[]
endtype

function CreatePacket(packetType as integer, message$ as string)
  packet$ = Str(packetType) + BACKSPACE + message$
endfunction packet$

function SerializeServerGameplayState(state ref as tServerState)
  packet as tWorldStatePacket
  for i = 0 to state.players.length
    player as tPlayerStatePacket
    player.remoteIndex = i
    player.x = state.players[i].x
    player.y = state.players[i].y
    packet.players.insert(player)
  next i
  packet$ = packet.toJSON()
endfunction packet$

function DeserializeServerGameplayState(message$ as string)
  packet as tWorldStatePacket
  packet.fromJSON(message$)
endfunction packet

function SerializeWelcomePacket(state ref as tServerState)
  packet as tWelcomePacket
  packet.remoteIndex = gServerState.players.length
  for i = 0 to gServerState.players.length - 1 // world state but the last added
    player as tInitialPlayerDataPacket
    player.remoteIndex = i
    player.color = gServerState.players[i].color
    player.x = gServerState.players[i].x
    player.y = gServerState.players[i].y
    packet.players.insert(player)
  next i
  packet$ = packet.toJSON()
endfunction packet$

function DeserializeWelcomePacket(packet$ as string)
  packet as tWelcomePacket
  packet.fromJSON(packet$)
endfunction packet

function SerializePlayerStatePacket(player ref as tPlayer)
  packet as tPlayerStatePacket
  packet.remoteIndex = player.remoteIndex
  packet.x = player.x
  packet.y = player.y
  packet$ = packet.toJSON()
endfunction packet$

function DeserializePlayerStatePacket(packet$ as string)
  packet as tPlayerStatePacket
  packet.fromJSON(packet$)
endfunction packet

function SerializeInitialPlayerDataPacket(localPlayer as tPlayer)
  packet as tInitialPlayerDataPacket
  packet.remoteIndex = localPlayer.remoteIndex
  packet.color = localPlayer.color
  packet.x = localPlayer.x
  packet.y = localPlayer.y
  packet$ = packet.toJSON()
endfunction packet$

function DeserializeInitialPlayerDataPacket(packet$ as string)
  packet as tInitialPlayerDataPacket
  packet.fromJSON(packet$)
endfunction packet
