;~@sa1
;This is the bottom cap of a vertical two-way pipe that is only
;enterable as small mario (note that yoshi always not allowed).
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
	CMP #$03			;\if going down..
	BEQ exit			;|then exit
	CMP #$07			;|
	BEQ exit			;/
	BRA within_pipe		;>other directions = pass
enter:
	LDA $187A|!addr		;>no yoshi.
	ORA $19			;>no powerup
	BNE return		;>otherwise return
	if !Setting_SSP_CarryAllowed == 0
		LDA $1470|!addr		;\no carrying item
		ORA $148F|!addr		;|
		BNE return		;/
	endif
	LDA $15			;\must press up
	AND #$08		;|
	BEQ return		;/
	LDA #$04
	STA $00
	%SSPEnterDownwardsFacingPipe()
within_pipe:
	JSR passable
return:
	RTL
TopCorner:
MarioAbove:
MarioSide:
HeadInside:
BodyInside:
	LDA !Freeram_SSP_PipeDir	;\return for other offset
	AND.b #%00001111		;|
	BEQ return			;/when not in pipe
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
	RTL
passable:
	LDY #$00		;\mario passes through the block
	LDA #$25		;|
	STA $1693|!addr		;/
	RTS
if !Setting_SSP_Description != 0
	print "Bottom cap of 2-way pipe for small mario (carrying items not allowed)."
endif