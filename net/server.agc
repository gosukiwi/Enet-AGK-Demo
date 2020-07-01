// server state
type tServerState
  players as tPlayer[]
endtype
global gServerState as tServerState
// end of server-state

function SyncServer(host as integer)
  do
    event = Enet.HostService(host) // polling
    if event = 0 then exit

    ServerParseEvent(host, event, Enet.GetEventType(event))
  loop

  if gElapsedSinceLastNetworkSend# > NETWORK_SEND_FREQUENCY
    ServerSend(host)
    gElapsedSinceLastNetworkSend# = 0
  endif
endfunction

// Private

function ServerSend(host as integer)
  packet$ = CreatePacket(PACKET_TYPE_WORLD_STATE, SerializeServerGameplayState(gServerState))
  Enet.HostBroadcast(host, packet$, "unreliable")
endfunction

function ServerParseEvent(host as integer, event as integer, type$ as string)
  select type$
    case "connect"
      address$ = Enet.GetEventPeerAddressHost(event) + ":" + Str(Enet.GetEventPeerAddressPort(event))
      Log("[SERVER] " + address$ + " connected")
      gServerState.players.insert(NewPlayer())
      packet$ = CreatePacket(PACKET_TYPE_PLAYER_ID, SerializeWelcomePacket(gServerState))
      Enet.EventPeerSend(event, packet$ , "reliable")
    endcase
    case "receive"
      HandleRecieveEventServer(host, Enet.GetEventData(event))
    endcase
    case "disconnect"
      address$ = Enet.GetEventPeerAddressHost(event) + ":" + Str(Enet.GetEventPeerAddressPort(event))
      Log("[SERVER] Disconnected: " + address$)
    endcase
  endselect
endfunction

function HandleRecieveEventServer(host as integer, packet$ as string)
  eventType = Val(GetStringToken(packet$, BACKSPACE,  1))
  message$ = GetStringToken(packet$, BACKSPACE, 2)
  select eventType
    case PACKET_TYPE_PLAYER_JOINED
      ServerHandlePlayerJoinedPacket(message$, host)
    endcase
    case PACKET_TYPE_PLAYER_STATE
      HandlePlayerStatePacket(message$)
    endcase
    case default
      Log("[SERVER] NOT HANDLED: " + Str(eventType))
    endcase
  endselect
endfunction

function HandlePlayerStatePacket(message$ as string)
  packet as tPlayerStatePacket
  packet = DeserializePlayerStatePacket(message$) // TODO: Rename to DeserializePlayerStatePacket
  index = packet.remoteIndex

  if index <= gServerState.players.length
    gServerState.players[index].x = packet.x
    gServerState.players[index].y = packet.y
  endif
endfunction

function ServerHandlePlayerJoinedPacket(message$ as string, host as integer)
  packet as tInitialPlayerDataPacket
  packet = DeserializeInitialPlayerDataPacket(message$)
  index = packet.remoteIndex

  // TODO: Validate index valid
  gServerState.players[index].initialized = 1
  gServerState.players[index].color = packet.color
  gServerState.players[index].x = packet.x
  gServerState.players[index].y = packet.y

  packet$ = CreatePacket(PACKET_TYPE_PLAYER_JOINED, packet.toJSON())
  Enet.HostBroadcast(host, packet$, "reliable")
endfunction
