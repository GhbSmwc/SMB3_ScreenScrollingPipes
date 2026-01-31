;~@sa1
;This is the top cap of a vertical two-way pipe that is only
;enterable as small mario (note that yoshi isn't allowed).
;behaves $130

incsrc "../../../../../SSPDef/Defines.asm"
incsrc "cap_defines.asm"

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP return : JMP return : JMP return
JMP return : JMP TopCorner : JMP BodyInside : JMP HeadInside

TopCorner:
MarioAbove:			;>mario above only so he cannot enter edge and warp all the way to middle.
	LDA !Freeram_SSP_PipeDir	;\if not in pipe
	AND.b #%00001111		;|then enter
	BEQ enter			;/
	CMP #$01		;\exit if going up
	BEQ exit		;|
	CMP #$05		;|
	BEQ exit		;/
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
	LDA $15			;\must press down
	AND #$04		;|
	BEQ return		;/
	LDA #$04
	STA $00
	%SSPEnterUpwardsFacingPipe()
within_pipe:
	JSR passable
return:
	RTL
MarioSide:
HeadInside:
BodyInside:
MarioBelow:
	LDA !Freeram_SSP_PipeDir	;\return for other offsets
	AND.b #%00001111		;|when not in pipe
	BEQ return			;/
	CMP #$01			;\exit if going up
	BEQ exit			;|
	CMP #$05			;|
	BEQ exit			;/
	BRA within_pipe
exit:
	JSR passable
	LDA #$04
	STA $02
	LDA #$03
	STA $03
	%SSPExitUpwardsFacingPipe()
	RTL
passable:
	LDY #$00		;\mario passes through the block
	LDA #$25		;|
	STA $1693|!addr		;/
	RTS
if !Setting_SSP_Description != 0
	print "Top cap of 2-way pipe for small mario."
endif