;Remember: The file naming in this folder is named:
;[<SwitchState0><Direction1>_<SwitchStateNonzero><Direction2>]
;
;SwitchState0 means if the RAM is 0 and SwitchStateNonzero means if the RAM is nonzero.
;Direction1 and Direction2 indicates one of the two directions to use depending on the RAM:
; N = NULL ($00). This is mainly used for 3-way intersection to make the player go straight.
; U = Up ($01)
; R = Right ($02)
; D = Down ($03)
; L = Left ($04)
;Example:
;[0U_1D.asm] means "0 = up, Nonzero = down". Using the on/off switch example, if $14AF
;is 0 ("ON"), means it will set the prep direction to UP, otherwise ("OFF"), would
;set his prep direction to down.
;

!SSP_RamSwitch = $14AF|!addr
 ;^What RAM influences the prep turn tiles to use a different direction.
 ; Note: The prep turn tiles only uses 2 values:
 ; $00 = Direction 1
 ; $01-$FF = Direction 2.
 ; Mostly, the prep turn directions in each prep turn tiles are either opposites, or
 ; simply will not set to a specific direction and the player will keep going straight
 ; and not turn.