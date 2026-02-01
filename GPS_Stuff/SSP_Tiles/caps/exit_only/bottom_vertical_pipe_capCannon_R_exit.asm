;~@sa1
;This is the bottom right-half cap cannon of a vertical 1-way pipe.
;(this cap is exit only).
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
	CMP #$03		;\exit of going down
	BEQ exit		;|
	CMP #$07		;|
	BEQ exit		;/
within_pipe:
	JSR passable
	RTL
exit:
	JSR passable
	%Get_Player_XPosition_RelativeToBlock()
	BPL return				;>If mario is too far from center, don't exit
	LDA #$02
	STA $02
	LDA #$04
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
print "Bottom-right exit cap cannon piece of a vertical pipe."
endif