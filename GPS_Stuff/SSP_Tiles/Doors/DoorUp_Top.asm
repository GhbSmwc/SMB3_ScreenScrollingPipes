incsrc "../../../SSPDef/Defines.asm"
;Act as $0025

db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

BodyInside:
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BNE ExitingDoor
	
EnteringDoor:
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
	LDA #$01
	STA $00
	LDA #$02
	STA $01
	%SSPEnterDoor()
	RTL
ExitingDoor:
	CMP #$03
	BEQ Exit
	CMP #$07			;>Failsafe
	BEQ Exit
	RTL
Exit:
	LDA #$02
	STA $00
	%SSPExitDoor()
;WallFeet:	; when using db $37
;WallBody:
MarioBelow:
MarioAbove:
MarioSide:
TopCorner:
HeadInside:
SpriteV:
SpriteH:

MarioCape:
MarioFireball:
Done:
RTL

if !Setting_SSP_Description != 0
	print "An upwards screen-scrolling door. Exits when going downwards."
endif