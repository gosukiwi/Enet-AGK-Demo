// Project: enet-demo
// Created: 2020-06-27
#import_plugin EnetAGK as Enet
#include "constants.agc"
#include "net/packets.agc"
#include "net/server.agc"
#include "net/client.agc"

// show all errors
SetErrorMode(2)

// set window properties
SetWindowTitle("ENet Demo")
SetWindowSize(1024, 768, 0)
SetWindowAllowResize(1) // allow the user to resize the window

// set display properties
SetVirtualResolution(1024, 768) // doesn't have to match the window
SetOrientationAllowed(1, 1, 1, 1) // allow both portrait and landscape on mobile devices
SetSyncRate(60, 0) // 60 FPS
SetScissor(0,0,0,0) // use the maximum available screen space, no black borders
UseNewDefaultFonts(1) // since version 2.0.22 we can use nicer default fonts

type tPlayer
  initialized as integer
  remoteIndex as integer
  x as integer
  y as integer
  color as integer
endtype

function NewPlayer()
  player as tPlayer
  player.initialized = 0
  player.remoteIndex = -1
  player.x = Random(0, 900)
  player.y = Random(0, 600)
  player.color = MakeColor(Random(128, 256), Random(128, 256), Random(128, 256))
endfunction player

global gCurrentScene as string
global gMode as string
global gLocalPlayer as tPlayer
global gElapsedSinceLastNetworkSend# = 0
global gElapsedSinceLastNetworkSendClient# = 0
global gSpeed = 200
gCurrentScene = "MENU"
gLocalPlayer = NewPlayer()

// TODO: Move to game scene
function DrawRemotePlayers()
  // draw remote players
  for i = 0 to gRemotePlayers.length
    player as tPlayer
    player = gRemotePlayers[i]
    if not player.initialized then continue

    DrawBox(player.x, player.y, player.x + 100,  player.y + 100, player.color, player.color, player.color, player.color,  1)
  next i
endfunction

elapsed# = Timer()
do
  new# = Timer()
  delta# = new# - elapsed#
  elapsed# = new#
  gElapsedSinceLastNetworkSend# = gElapsedSinceLastNetworkSend# + delta#
  gElapsedSinceLastNetworkSendClient# = gElapsedSinceLastNetworkSendClient# + delta#

  Print("FPS: " + Str(ScreenFPS()))

  if gCurrentScene = "MENU"
    Print("Press [ENTER] to create server.")
    Print("Press [SPACE] to join server.")

    if GetRawKeyReleased(KEY_ENTER)
      Enet.Initialize()
      server = Enet.CreateServer(6400, MAX_PLAYERS) // port 6400, max 4 connections
      client = Enet.CreateClient()
      Enet.SetHostCompressWithRangeCoder(server) // use default compressor for packets
      Enet.SetHostCompressWithRangeCoder(client)
      Enet.HostConnectAsync(client, "localhost", 6400) // this would be the remote IP

      do
        SyncServer(server)
        result$ = Enet.HostConnectAsyncPoll() // check for client connect
        if result$ = "failed" then exit
        if result$ = "succeeded"
            peer = Enet.HostConnectAsyncPeerId()
            exit
        endif
      loop

      if server > 0 and peer > 0 and client > 0
        gCurrentScene = "GAME"
        gMode = "SERVER"
      else
        gCurrentScene = "CLIENT_ERROR"
      endif
    endif

    if GetRawKeyReleased(KEY_SPACE)
      Enet.Initialize()
      client = Enet.CreateClient()
      Enet.SetHostCompressWithRangeCoder(client) // use default compressor
      peer = Enet.HostConnect(client, "localhost", 6400) // this would be the remote IP
      if client > 0 and peer > 0
        gCurrentScene = "GAME"
        gMode = "CLIENT"
      else
        gCurrentScene = "CLIENT_ERROR"
      endif
    endif
  elseif gCurrentScene = "GAME"
    Print("MODE: " + gMode)

    // Networking
    if gMode = "SERVER" then SyncServer(server)
    SyncClient(client, peer)
    // End of Networking

    // update local player
    if GetRawKeyState(KEY_S)
      gLocalPlayer.y = gLocalPlayer.y + gSpeed * delta#
    endif
    if GetRawKeyState(KEY_W)
      gLocalPlayer.y = gLocalPlayer.y - gSpeed * delta#
    endif
    if GetRawKeyState(KEY_A)
      gLocalPlayer.x = gLocalPlayer.x - gSpeed * delta#
    endif
    if GetRawKeyState(KEY_D)
      gLocalPlayer.x = gLocalPlayer.x + gSpeed * delta#
    endif

    // draw local player
    DrawBox(gLocalPlayer.x, gLocalPlayer.y, gLocalPlayer.x + 100,  gLocalPlayer.y + 100, gLocalPlayer.color, gLocalPlayer.color, gLocalPlayer.color, gLocalPlayer.color,  1)
    DrawRemotePlayers()
  elseif gCurrentScene = "CLIENT_ERROR"
    Print("Could not connect to server.")
  else
    Log("Invalid scene!")
  endif

  Sync()
loop

if server then Enet.DestroyHost(server)
if client then Enet.DestroyHost(client)
Enet.Deinitialize()
