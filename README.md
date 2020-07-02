# Enet-AGK-Demo
This repo is just a demo of using [ENet Plugin for AGK Tier 1](https://github.com/gosukiwi/enet-agk). It uses JSON packets to sync game state between a client-server and many clients.

The core idea is this:

1. Player loads up the game, presses `ENTER` to create a server
1. The same player also creates a client and connects to itself, this makes it much easier to code the sync logic
1. Other players can join by opening the game and pressing `SPACE`
1. The server has it's own server state which then broadcasts to all it's clients (all other players)
1. Each player takes the state and updates the remote players accordingly (they don't update themselves)

The code is purposely rather simplistic (many things are not taken care of), but hopefully it helps show the main idea on how to network with the ENet library.
