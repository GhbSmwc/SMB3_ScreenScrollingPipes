;~@sa1
;This is the corner piece of the pipe that changes mario's
;direction from right to down or up to left.
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
	CMP #$02			;\If going right, translate to down
	BEQ right_to_down		;|
	CMP #$06			;|
	BEQ right_to_down		;/
	CMP #$01			;\If going up, translate to left
	BEQ up_to_left			;|
	CMP #$05			;|
	BEQ up_to_left			;/
Return:
	RTL
right_to_down:
	LDA #$02
	STA $00
	LDA #$03
	STA $01
	%SSPChangeDirection()
	RTL
up_to_left:
	%Get_Player_XPosition_RelativeToBlock()
	BEQ .Allow
	BPL Return
	.Allow
	LDA #$02
	STA $00
	LDA #$04
	STA $01
	%SSPChangeDirection()
	RTL

if !Setting_SSP_Description != 0
	print "Changes the pipe direction from right to down or up to left."
endif