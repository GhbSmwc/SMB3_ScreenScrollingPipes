;~@sa1
;This is the bottom left-half cap of a vertical two-way pipe.
;behaves $130

incsrc "../../../../../SSPDef/Defines.asm"
incsrc "cap_defines.asm"

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP return : JMP return : JMP return
JMP return : JMP TopCorner : JMP BodyInside : JMP HeadInside

MarioBelow:
	LDA !Freeram_SSP_PipeDir	;\if not in pipe
	AND.b #%00001111		;|
	BEQ enter			;/then enter
	if !Setting_SSP_CarryAllowed != 0
		CMP #$03			;\if going down..
		BEQ exit			;|then exit
		CMP #$07			;|
		BEQ exit			;/
		BRA within_pipe			;>other directions = pass
	else
		;Branch out of bounds with "BEQ exit"
		CMP #$03			;\if going down..
		BNE +
		JMP exit			;|then exit
		+
		CMP #$07			;|
		BNE +
		BEQ exit			;/
		+
		JMP within_pipe			;>other directions = pass
	endif
enter:
	if !Setting_SSP_CarryAllowed == 0
		LDA $1470|!addr		;\no carrying item
		ORA $148F|!addr		;|
		BEQ +
		RTL			;/
		+
	endif
	LDA $15			;\must press up
	AND #$08		;|\
	BNE .PressUp		;/|Branch out of range
	RTL			; /
.PressUp
	if !Setting_SSP_YoshiAllowed == 0
		LDA $187A|!addr
		BEQ .AllowEnter
		if !Setting_SSP_YoshiProhibitSFXNum != 0
			LDA.b #!Setting_SSP_YoshiProhibitSFXNum
			STA !Setting_SSP_YoshiProhibitSFXPort|!addr
			LDA #$20					;\Prevent SFX playing multiple times.
			STA $7D						;/
		endif
		RTL
		.AllowEnter
	endif
	LDA #$04
	STA $00
	%SSPEnterDownwardsFacingPipe()
within_pipe:
	JSR passable
	RTL
TopCorner:
MarioAbove:
MarioSide:
HeadInside:
BodyInside:
	LDA !Freeram_SSP_PipeDir	;\return for other offset
	AND.b #%00001111		;|
	BNE +
	RTL			;/when not in pipe
	+
	CMP #$03			;\exit of going down
	BEQ exit			;|
	CMP #$07			;|
	BEQ exit			;/
	BRA within_pipe
exit:
	JSR passable
	LDA #$04
	STA $02
	LDA #$03
	STA $03
	%SSPExitDownwardsFacingPipe()
return:
	RTL
passable:
	LDY #$00		;\mario passes through the block
	LDA #$25		;|
	STA $1693|!addr		;/
	RTS
if !Setting_SSP_Description != 0
	print "A bottom small pipe cap that Mario of any powerup can enter and exit."
endif