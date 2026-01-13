incsrc "../../../SSPDef/Defines.asm"
;Act as $0025

db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

MarioBelow:
MarioAbove:
MarioSide:
TopCorner:
BodyInside:
HeadInside:
Exit:
	STZ $00
	%SSPExitDoor()
;WallFeet:	; when using db $37
;WallBody:

SpriteV:
SpriteH:

MarioCape:
MarioFireball:
Done:
RTL

if !Setting_SSP_Description != 0
	print "An exit-only screen-scrolling door. Any direction on this tile will exit."
endif