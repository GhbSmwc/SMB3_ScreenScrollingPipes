;~@sa1
;this is the right cap of a horizontal 2-way pipe that is
;only enterable as small mario (yoshi always not allowed).
;behaves $130

incsrc "../../../../../SSPDef/Defines.asm"
incsrc "cap_defines.asm"

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP return : JMP return : JMP return
JMP return : JMP TopCorner : JMP BodyInside : JMP HeadInside


MarioSide:
	LDA !Freeram_SSP_PipeDir	;\If mario isn't in a pipe, the run the enter routine
	AND.b #%00001111		;|
	BEQ enter			;/
	CMP #$02			;\if going right
	BEQ exit			;|then exit
	CMP #$06			;|
	BEQ exit			;/
	BRA within_pipe			;>Other directions, allow player to pass through without exiting.
enter:
	REP #$20		;\Prevent triggering the block from the left side (if you press left away from block)
	LDA $9A			;|
	AND #$FFF0		;|
	CMP $94			;|
	SEP #$20		;|
	BPL +			;/
	LDA $187A|!addr		;>no yoshi.
	ORA $19			;>no powerup
;	ORA $1471|!addr		;>so vertical centering code works
	ORA $76			;>must face left
	BEQ .SmallNoYoshi
	+
	RTL			;>otherwise return
.SmallNoYoshi
if !Setting_SSP_CarryAllowed == 0
	LDA $1470|!addr		;\no carrying item
	ORA $148F|!addr		;|
	BNE Return0		;/
endif
	LDA $15			;\must press left
	AND #$02		;|
	BEQ Return0		;/
	STZ $00
	%SSPEnterHorizontalPipes()
TopCorner:
MarioAbove:
HeadInside:
BodyInside:
MarioBelow:
within_pipe:
	JSR passable
	Return0:
	RTL
exit:
	JSR passable
	LDA #$02
	STA $00
	LDA #$02
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
	print "Right cap piece of horizontal pipe for small mario."
endif