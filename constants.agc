// Keys
#constant KEY_ENTER 13
#constant KEY_SPACE 32
#constant KEY_A     65
#constant KEY_D     68
#constant KEY_S     83
#constant KEY_W     87
// Message Types ENUM
#constant PACKET_TYPE_PLAYER_ID     1 // dont start at 0 because `Val(str)` uses 0 for failure
#constant PACKET_TYPE_PLAYER_STATE  2
#constant PACKET_TYPE_PLAYER_JOINED 3
#constant PACKET_TYPE_WORLD_STATE   4
// Other
#constant NETWORK_SEND_FREQUENCY 0.1 // 10 times per second
#constant MAX_PLAYERS 4
#constant BACKSPACE Chr(8)
