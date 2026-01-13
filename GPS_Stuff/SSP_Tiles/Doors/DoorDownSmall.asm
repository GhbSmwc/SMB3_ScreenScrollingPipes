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
HeadInside:
BodyInside:
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BNE ExitingDoor
	
EnteringDoor:
	LDA $19				;\Not big mario
	BNE Done			;/
	LDA $16				;\Not pressing up
	BIT.b #%00001000		;|
	BEQ Done			;/
	if !Setting_SSP_CopyRAM77
		LDA !Freeram_BlockedStatBkp		;\If you are not on ground, return
		AND.b #%00000100		;|
		BEQ Done			;/
	else
		LDA $8F
		BNE Done
	endif
	if !Setting_SSP_DoorsProximity
		%door_approximity()
		BCS Done
	endif
	LDA #$03
	STA $00
	%SSPEnterDoor()
	RTL
ExitingDoor:
	CMP #$01
	BEQ Exit
	CMP #$05			;>Failsafe
	BEQ Exit
	RTL
Exit:
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
	print "An downwards screen-scrolling door for Small Mario. Exit when going upwards."
endif