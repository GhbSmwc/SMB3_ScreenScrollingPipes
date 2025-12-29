;~@sa1
;This is the corner piece of the pipe that changes mario's
;direction from left to up or down to right.
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
	REP #$20
	LDA #$FFFE			;\2 pixels to the left from center because player being halfway between 2 horizontally placed blocks
	STA $00				;/would have his center picking the right block
	STZ $02
	SEP #$20
	%CheckIfPlayerBottom16x16CenterIsInBlock()
	BCC Return
	
	LDA !Freeram_SSP_PipeDir	;\Get current direction
	AND.b #%00001111		;/
	CMP #$04			;\If going left, translate to up
	BEQ left_to_up			;|
	CMP #$08			;|
	BEQ left_to_up			;/
	CMP #$03			;\If going down, translate to right
	BEQ down_to_right		;|
	CMP #$07			;|
	BEQ down_to_right		;/
Return:
	RTL
left_to_up:
	LDA #$00
	STA $00
	LDA #$01
	STA $01
	%SSPChangeDirection()
	RTL
down_to_right:
	%Get_Player_XPosition_RelativeToBlock()
	BMI Return
	STZ $00
	LDA #$02
	STA $01
	%SSPChangeDirection()
	RTL

if !Setting_SSP_Description != 0
	print "Changes the pipe direction from left to up or down to right."
endif