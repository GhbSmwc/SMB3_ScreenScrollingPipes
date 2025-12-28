;~@sa1
;this is the right bottom-half cap cannon of a horizontal 1-way pipe, can
;be used as a small pipe and normal-sized pipe cap.
;behaves $25 or $130

incsrc "../../../../SSPDef/Defines.asm"

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP return : JMP return : JMP return
JMP return : JMP TopCorner : JMP BodyInside : JMP HeadInside


MarioSide:
	LDA !Freeram_SSP_PipeDir	;\for other offsets if mario
	AND.b #%00001111		;|not in pipe
	BEQ return			;/
	CMP #$02			;\if going right
	BEQ exit			;|then exit
	CMP #$06			;|
	BEQ exit			;/
TopCorner:
MarioAbove:
HeadInside:
BodyInside:
MarioBelow:
within_pipe:
	JSR passable
	RTL
exit:
	JSR passable
	LDA #$02
	STA $00
	LDA #$03
	STA $01
	%SSPExitHorizontalPipes()
return:
	RTL
passable:
	LDA !Freeram_SSP_PipeDir	;\not in pipe = solid
	AND.b #%00001111		;|
	BEQ solid_out			;/
	LDY #$00		;\mario passes through the block
	LDA #$25		;|
	STA $1693|!addr		;/
solid_out:
	RTS
if !Setting_SSP_Description != 0
	print "Bottom-right/right cap cannon exit piece of horizontal pipe."
endif