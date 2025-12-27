;~@sa1
;This is the bottom left-half cap of a vertical 1-way pipe.
;(this cap is exit only)
;behaves $25 or $130

incsrc "../../../../SSPDef/Defines.asm"

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP return : JMP return : JMP return
JMP return : JMP TopCorner : JMP BodyInside : JMP HeadInside

ReturnShort:
	RTL

MarioBelow:
TopCorner:
MarioAbove:
MarioSide:
HeadInside:
BodyInside:
	LDA !Freeram_SSP_PipeDir	;\do nothing if outside
	AND.b #%00001111		;|
	BEQ ReturnShort			;/when not in pipe
	CMP #$03			;\exit of going down
	BEQ exit			;|
	CMP #$07			;|
	BEQ exit			;/
within_pipe:
	JSR passable
	RTL
exit:
	JSR passable
	LDA #$04
	STA $02
	LDA #$02
	STA $03
	%SSPExitDownwardsPipe()
return:
	RTL
passable:
	LDY #$00		;\mario passes through the block
	LDA #$25		;|
	STA $1693|!addr		;/
	RTS

if !Setting_SSP_Description != 0
	print "A bottom small pipe cap that Mario of any powerup can only exit out of."
endif