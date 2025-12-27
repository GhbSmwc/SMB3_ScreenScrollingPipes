;A turn corner that changes the direction the player is going
;based on the "prepare corner direction blocks".
;Behaves $25 or $130

incsrc "../../SSPDef/Defines.asm"

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside

MarioBelow:
MarioAbove:
MarioSide:
TopCorner:
BodyInside:
HeadInside:
	LDA !Freeram_SSP_PipeDir	;\If not in pipe mode, Return as being a solid block
	AND.b #%00001111		;|
	BEQ Return			;/
	LDY #$00			;\Become passable when in pipe.
	LDX #$25			;|
	STX $1693|!addr			;/
	CMP #$09			;\If traveling in any direction, do nothing except be passable.
	BCS Return			;/
	REP #$20					;\Check if player is lined up with the block
	STZ $00						;|
	STZ $02						;|
	SEP #$20					;|
	%CheckIfPlayerBottom16x16CenterIsInBlock()	;|
	BCC Return					;/
	
	LDA !Freeram_SSP_PipeDir			;\Change direction to prep direction
	LSR #4						;|
	STA $01						;|
	STZ $00						;|
	%SSPChangeDirection()				;/
SpriteV:
SpriteH:
MarioCape:
MarioFireball:
Return:
	RTL

if !Setting_SSP_Description != 0
	print "The bottom-left of a 32x32 intersection of a special turn."
endif