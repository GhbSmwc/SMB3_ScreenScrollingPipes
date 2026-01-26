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
	LDA #$09				;\Clear out the prep direction (we treat the warp drag subroutine as if direction #$00 for both entering and exiting)
	STA !Freeram_SSP_PipeDir		;/
	LDA #$09
	STA $00
	LDA #$02
	STA $01
	%SSPEnterDoor()
	REP #$20				;\We only take the position of the bottom 16x16 part of the door.
	LDA $98					;|
	PHA					;|
	CLC					;|
	ADC #$0010				;|
	STA $98					;|
	SEP #$20				;/
	%SSPDragMarioMode()			;>Perform warp/drag mode. C flag here indicates 0 = success, 1 = fail
	REP #$20
	PLA
	STA $98
	SEP #$20
	BCC Done
	.WarpDragNotFoundHandler
		;Here is the failsafe. Cancels out pipe state and plays the incorrect SFX.
		LDA !Freeram_SSP_PipeDir
		AND.b #%11110000
		STA !Freeram_SSP_PipeDir
		LDA #$00
		STA !Freeram_SSP_EntrExtFlg
		LDA #$2A
		STA $1DFC|!addr
	RTL
ExitingDoor:
	CMP #$04
	BEQ Exit
	CMP #$08			;>Failsafe
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
	print "A warp/drag screen-scrolling door."
endif