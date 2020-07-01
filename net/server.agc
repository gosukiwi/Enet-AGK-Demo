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
      ServerParseReceiveEventPacket(host, Enet.GetEventData(event))
    endcase
    case "disconnect"
      address$ = Enet.GetEventPeerAddressHost(event) + ":" + Str(Enet.GetEventPeerAddressPort(event))
      Log("[SERVER] Disconnected: " + address$)
    endcase
  endselect
endfunction

function ServerParseReceiveEventPacket(host as integer, packet$ as string)
  eventType = Val(GetStringToken(packet$, BACKSPACE,  1))
  message$ = GetStringToken(packet$, BACKSPACE, 2)
  select eventType
    case PACKET_TYPE_PLAYER_JOINED
      index = Val(GetStringToken(message$, ",",  1))
      color = Val(GetStringToken(message$, ",",  2))
      x = Val(GetStringToken(message$, ",",  3))
      y = Val(GetStringToken(message$, ",",  4))

      // TODO: Validate index valid
      gServerState.players[index].initialized = 1
      gServerState.players[index].color = color
      gServerState.players[index].x = x
      gServerState.players[index].y = y

      packet$ = Str(PACKET_TYPE_PLAYER_JOINED) + BACKSPACE + Str(index) + "," + Str(color) + "," + Str(x) + "," + Str(y)
      Enet.HostBroadcast(host, packet$, "reliable")
    endcase
    case PACKET_TYPE_PLAYER_STATE
      receivedIndex = Val(GetStringToken(message$, ",",  1))
      receivedX = Val(GetStringToken(message$, ",",  2))
      receivedY = Val(GetStringToken(message$, ",",  3))

      if receivedIndex <= gServerState.players.length
        gServerState.players[receivedIndex].x = receivedX
        gServerState.players[receivedIndex].y = receivedY
      endif
    endcase
    case default
      Log("[SERVER] NOT HANDLED: " + Str(eventType))
    endcase
  endselect
endfunction

function ServerSend(host as integer)
  packet$ = CreatePacket(PACKET_TYPE_WORLD_STATE, SerializeServerGameplayState(gServerState))
  Enet.HostBroadcast(host, packet$, "unreliable")
endfunction
