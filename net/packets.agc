#constant PACKET_TYPE_PLAYER_ID     1 // dont start at 0 because `Val(str)` uses 0 for failure
#constant PACKET_TYPE_PLAYER_STATE  2
#constant PACKET_TYPE_PLAYER_JOINED 3
#constant PACKET_TYPE_WORLD_STATE   4
#constant BACKSPACE Chr(8)

type tWorldStatePacketPlayer
  x as integer
  y as integer
  remoteIndex as integer
endtype

type tWorldStatePacket
  players as tWorldStatePacketPlayer[]
endtype

type tWelcomePacketPlayer
  x as integer
  y as integer
  color as integer
  remoteIndex as integer
endtype

type tWelcomePacket
  remoteIndex as integer
  players as tWelcomePacketPlayer[]
endtype

function CreatePacket(packetType as integer, message$ as string)
  packet$ = Str(packetType) + BACKSPACE + message$
endfunction packet$

// function CreatePlayerIdPacket()
// endfunction

// function DeserializePlayerIdPacket(packet$ as string, id ref as id)
// endfunction

// Serializes the server state for gameplay, this is a subset of the whole state.
// Format:
//   playerId,x,y:
function SerializeServerGameplayState(state ref as tServerState)
  packet as tWorldStatePacket
  for i = 0 to state.players.length
    player as tWorldStatePacketPlayer
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
    player as tWelcomePacketPlayer
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
