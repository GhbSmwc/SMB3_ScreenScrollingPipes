;This itself does not changes the player direction, but merely changes
;the planned direction when Mario hits a turn special.
;Behaves $25 or $130

incsrc "../../SSPDef/Defines.asm"

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
	
	LDA !Freeram_SSP_PipeDir		;\Set planned direction to down.
	AND.b #%00001111			;|
	ORA.b #%00110000			;|
	STA !Freeram_SSP_PipeDir		;/

WallFeet:
WallBody:
SpriteV:
SpriteH:
MarioCape:
MarioFireball:
Return:
	RTL
if !Setting_SSP_Description != 0
	print "Directs the next upcoming special turn downwards."
endif