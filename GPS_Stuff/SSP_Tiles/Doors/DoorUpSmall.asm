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
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BNE ExitingDoor
	
EnteringDoor:
	LDA $19				;\Not big mario
	BNE Done			;/
	LDA $16				;\Not pressing up
	BIT.b #%00001000		;|
	BEQ Done			;/
	LDA !Freeram_BlockedStatBkp	;\If you are not on ground, return
	AND.b #%00000100		;|
	BEQ Done			;/
	LDA #$01
	STA $00
	%SSPEnterDoor()
	RTL
ExitingDoor:
	CMP #$03
	BEQ Exit
	CMP #$07			;>Failsafe
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
	print "An upwards screen-scrolling door for Small Mario. Exits when going downwards."
endif