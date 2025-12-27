;~@sa1
;This is the corner piece of the pipe that changes mario's direction
;from up to right or left to down, for small pipes.
;Behaves $25 or $130

incsrc "../../SSPDef/Defines.asm"

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP Return : JMP Return : JMP Return
JMP Return : JMP TopCorner : JMP BodyInside : JMP HeadInside

TopCorner:
MarioAbove:
MarioSide:
HeadInside:
MarioBelow:
BodyInside:
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

	LDA !Freeram_SSP_PipeDir	;\Get current direction
	AND.b #%00001111		;/
	CMP #$01			;\If going up, translate to right
	BEQ up_to_right			;|
	CMP #$05			;|
	BEQ up_to_right			;/
	CMP #$04			;\If going left, translate to down
	BEQ left_to_down		;|
	CMP #$08			;|
	BEQ left_to_down		;/
Return:
	RTL
up_to_right:
	LDA #$04
	STA $00
	LDA #$02
	STA $01
	%SSPChangeDirection()
	RTL
left_to_down:
	LDA #$04
	STA $00
	LDA #$03
	STA $01
	%SSPChangeDirection()
	RTL
	
if !Setting_SSP_Description != 0
	print "Changes the pipe direction from up to right or left to down."
endif