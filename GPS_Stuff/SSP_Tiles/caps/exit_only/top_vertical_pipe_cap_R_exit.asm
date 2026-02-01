;~@sa1
;This is the top right-half cap of a vertical
;1-way pipe (exit only).
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
	AND.b #%00001111		;|when not in pipe
	BEQ return			;/
	CMP #$01		;\exit if going up
	BEQ exit		;|
	CMP #$05		;|
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
	LDA #$03
	STA $03
	%SSPExitUpwardsFacingPipe()
return:
	RTL
passable:
	LDY #$00		;\mario passes through the block
	LDA #$25		;|
	STA $1693|!addr		;/
	RTS

if !Setting_SSP_Description != 0
	print "Top-right exit cap piece of a vertical pipe."
endif