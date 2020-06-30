// an array of remote players which are updated from server data
// used by the client only
global gRemotePlayers as tPlayer[]

function InitializeClient()
  for i = 1 to MAX_PLAYERS - 1
    gRemotePlayers.insert(NewPlayer())
  next i
endfunction

function SyncClient(host as integer, peer as integer)
  do
    event = Enet.HostService(host) // polling
    if event = 0 then exit

    ClientRead(peer, event, Enet.GetEventType(event))
  loop

  if gElapsedSinceLastNetworkSendClient# > NETWORK_SEND_FREQUENCY
    ClientSend(peer)
    gElapsedSinceLastNetworkSendClient# = 0
  endif
endfunction

function ClientRead(peer as integer, event as integer, type$ as string)
  select type$
    case "receive"
      ClientParseReceiveEventPacket(peer, Enet.GetEventData(event))
    endcase
    case "disconnect"
      address$ = Enet.GetEventPeerAddressHost(event) + ":" + Str(Enet.GetEventPeerAddressPort(event))
      Log("[CLIENT] Disconnected: " + address$)
    endcase
  endselect
endfunction

function ClientSend(peer as integer)
  if gLocalPlayer.remoteIndex = -1 then exitfunction

  Enet.PeerSend(peer, Str(PACKET_TYPE_PLAYER_STATE) + BACKSPACE + Str(gLocalPlayer.remoteIndex) + "," + Str(gLocalPlayer.x) + "," + Str(gLocalPlayer.y), "unreliable")
endfunction

// Private

function ClientParseReceiveEventPacket(peer as integer, packet$ as string)
  eventType = Val(GetStringToken(packet$, BACKSPACE,  1))
  message$ = GetStringToken(packet$, BACKSPACE, 2)
  select eventType // get packet type
    case PACKET_TYPE_PLAYER_ID
      index = Val(GetStringToken(message$, "$",  1))
      world$ = GetStringToken(message$, "$",  2)
      gLocalPlayer.remoteIndex = index

      // The first time we need to build the world we might send more data than
      // we usually do, for example, the color is needed just once
      for i = 0 to CountStringTokens(world$, ":") - 1
        playerData$ = GetStringToken(world$, ":", i + 1)
        index = Val(GetStringToken(playerData$, ",",  1))
        color = Val(GetStringToken(playerData$, ",",  2))
        x = Val(GetStringToken(playerData$, ",",  3))
        y = Val(GetStringToken(playerData$, ",",  4))

        // TODO: Check indexes
        gRemotePlayers[index].initialized = 1
        gRemotePlayers[index].color = color
        gRemotePlayers[index].x = x
        gRemotePlayers[index].y = y
      next i

      // Send initial data to server
      packet$ = Str(PACKET_TYPE_PLAYER_JOINED) + BACKSPACE + Str(gLocalPlayer.remoteIndex) + "," + Str(gLocalPlayer.color) + "," + Str(gLocalPlayer.x) + "," + Str(gLocalPlayer.y)
      Enet.PeerSend(peer, packet$, "reliable")
    endcase
    case PACKET_TYPE_PLAYER_JOINED
      index = Val(GetStringToken(message$, ",",  1))
      if index = gLocalPlayer.remoteIndex then exitfunction // do not update my own info

      color = Val(GetStringToken(message$, ",",  2))
      x = Val(GetStringToken(message$, ",",  3))
      y = Val(GetStringToken(message$, ",",  4))

      // TODO: Validate index valid
      gRemotePlayers[index].initialized = 1
      gRemotePlayers[index].color = color
      gRemotePlayers[index].x = x
      gRemotePlayers[index].y = y
    endcase
    case PACKET_TYPE_WORLD_STATE
      packet as tWorldStatePacket
      packet = DeserializeServerGameplayState(message$)
      for i = 0 to packet.players.length
        index = packet.players[i].remoteIndex
        if index = gLocalPlayer.remoteIndex then continue

        gRemotePlayers[index].x = packet.players[i].x
        gRemotePlayers[index].y = packet.players[i].y
      next i
    endcase
    case default
      Log("[CLIENT][WARNING] EVENT TYPE NOT HANDLED: " + Str(eventType))
    endcase
  endselect
endfunction

function DrawRemotePlayers()
  // draw remote players
  for i = 0 to gRemotePlayers.length
    player as tPlayer
    player = gRemotePlayers[i]
    if not player.initialized then continue

    DrawBox(player.x, player.y, player.x + 100,  player.y + 100, player.color, player.color, player.color, player.color,  1)
  next i
endfunction
