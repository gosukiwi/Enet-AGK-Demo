// world-state for the server
global gServerState as tPlayer[]

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
  address$ = Enet.GetEventPeerAddressHost(event) + ":" + Str(Enet.GetEventPeerAddressPort(event))
  select type$
    case "connect"
      Log("[SERVER] " + address$ + " connected")
      gServerState.insert(NewPlayer())

      welcomePacket$ = Str(PACKET_TYPE_PLAYER_ID) + BACKSPACE + Str(gServerState.length) + "$"
      for i = 0 to gServerState.length - 1 // world state but the last added
        // index,color,x,y:
        welcomePacket$ = welcomePacket$ + Str(i) + "," + Str(gServerState[i].color) + "," + Str(gServerState[i].x) + "," + Str(gServerState[i].y) + ":"
      next i
      Enet.EventPeerSend(event, welcomePacket$ , "reliable")
    endcase
    case "receive"
      ServerParseReceiveEventPacket(host, Enet.GetEventData(event))
    endcase
    case "disconnect"
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
      gServerState[index].initialized = 1
      gServerState[index].color = color
      gServerState[index].x = x
      gServerState[index].y = y

      packet$ = Str(PACKET_TYPE_PLAYER_JOINED) + BACKSPACE + Str(index) + "," + Str(color) + "," + Str(x) + "," + Str(y)
      Enet.HostBroadcast(host, packet$, "reliable")
    endcase
    case PACKET_TYPE_PLAYER_STATE
      receivedIndex = Val(GetStringToken(message$, ",",  1))
      receivedX = Val(GetStringToken(message$, ",",  2))
      receivedY = Val(GetStringToken(message$, ",",  3))

      if receivedIndex <= gServerState.length
        gServerState[receivedIndex].x = receivedX
        gServerState[receivedIndex].y = receivedY
      endif
    endcase
    case default
      Log("[SERVER] NOT HANDLED: " + Str(eventType))
    endcase
  endselect
endfunction

function ServerSend(host as integer)
  // Broadcast a packet with all player states
  // format:   PACKET_TYPE-INDEX,X,Y:INDEX2,X2,Y2:...
  // example:  1-0,100,100:1,200,123:
  packet$ = Str(PACKET_TYPE_WORLD_STATE) + BACKSPACE
  for i = 0 to gServerState.length
    packet$ = packet$ + Str(i) + "," + Str(gServerState[i].x) + "," + Str(gServerState[i].y) + ":"
  next i
  Enet.HostBroadcast(host, packet$, "unreliable")
endfunction
