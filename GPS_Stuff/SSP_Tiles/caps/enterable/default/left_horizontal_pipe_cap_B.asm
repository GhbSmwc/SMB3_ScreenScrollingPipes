;~@sa1
;this is the left bottom-half cap of a horizontal 2-way pipe.
;behaves $130

incsrc "../../../../../SSPDef/Defines.asm"
incsrc "cap_defines.asm"

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP return : JMP return : JMP return
JMP return : JMP TopCorner : JMP BodyInside : JMP HeadInside


MarioSide:
BodyInside:
	LDA !Freeram_SSP_PipeDir	;\If mario isn't in a pipe, the run the enter routine
	AND.b #%00001111		;|
	BEQ enter			;/
	CMP #$04			;\If mario is going outwards from the cap heading left,
	BEQ exit			;|then exit
	CMP #$08			;|
	BEQ exit			;/
	BRA within_pipe			;>Other directions, allow player to pass through without exiting.
enter:
	REP #$20		;\Prevent triggering the block from the right side (if you press right away from block)
	LDA $9A			;|
	AND #$FFF0		;|
	CMP $94			;|
	SEP #$20		;|
	BMI return		;/
	if !Setting_SSP_CarryAllowed == 0
		LDA $1470|!addr		;\no carrying item
		ORA $148F|!addr		;|
		BNE return		;/
	endif
	LDA $187A|!addr		;\do not enter pipe when turning
	CMP #$02		;|around on yoshi.
	BEQ return		;/
;	LDA $1471|!addr		;>so vertical centering code works
;	BNE return
	LDA !Freeram_BlockedStatBkp	;\If you are not on ground, return
	AND.b #%00000100		;|
	BEQ return			;/
	LDA $15				;\must press right
	AND #$01			;|
	BEQ return			;/
	LDA $76				;\must face right
	BEQ return			;/
	if !Setting_SSP_YoshiAllowed == 0
		LDA $187A|!addr
		BEQ +
		if !Setting_SSP_YoshiProhibitSFXNum != 0
			LDA $16						;\Use 1-frame controller to prevent sound replaying each frame.
			AND #$01					;|(you have to let go the button and tap to trigger this though)
			BEQ return					;/
			LDA.b #!Setting_SSP_YoshiProhibitSFXNum
			STA !Setting_SSP_YoshiProhibitSFXPort|!addr
		endif
		RTL
		+
	endif
	LDA #$02
	STA $00
	%SSPEnterHorizontalPipes()
within_pipe:
	JSR passable
return:
	RTL
TopCorner:
MarioAbove:
MarioBelow:
HeadInside:
	LDA !Freeram_SSP_PipeDir	;\for other offsets if mario
	AND.b #%00001111		;/
	BEQ return			;/not in pipe
	BRA within_pipe
exit:
	JSR passable
	STZ $00
	LDA #$02
	STA $01
	%SSPExitHorizontalPipes()
return1:
	RTL
passable:
	LDY #$00		;\mario passes through the block
	LDA #$25		;|
	STA $1693|!addr		;/
	RTS
if !Setting_SSP_Description != 0
	print "Bottom-left cap piece of horizontal 2-way pipe."
endif