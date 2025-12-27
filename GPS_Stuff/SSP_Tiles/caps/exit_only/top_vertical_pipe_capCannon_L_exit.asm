;~@sa1
;This is the top left-half cap cannon of a vertical 1-way pipe.
;(this cap is exit only)
;behaves $25 or $130

incsrc "../../../../SSPDef/Defines.asm"

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP return : JMP return : JMP return
JMP return : JMP TopCorner : JMP BodyInside : JMP HeadInside

MarioAbove:
TopCorner:
MarioSide:
HeadInside:
BodyInside:
MarioBelow:
	LDA !Freeram_SSP_PipeDir	;\return for other offsets
	AND.b #%00001111		;/	
	BEQ return		;/when not in pipe
	CMP #$01		;\exit if going up
	BEQ exit		;|
	CMP #$05		;|
	BEQ exit		;/
within_pipe:
	LDY #$00		;\mario passes through the block
	LDA #$25		;|
	STA $1693|!addr		;/
	RTL
exit:
	JSR passable
	STZ $02
	%SSPExitUpwardsPipe()
return:
	RTL
passable:
	LDY #$00		;\mario passes through the block
	LDA #$25		;|
	STA $1693|!addr		;/
	RTS

if !Setting_SSP_Description != 0
print "Top-left exit cap cannon piece of a vertical pipe."
endif