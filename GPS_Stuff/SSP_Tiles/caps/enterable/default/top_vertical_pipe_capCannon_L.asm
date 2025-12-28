;~@sa1
;This is the top left-half cap cannon of a vertical two-way pipe.
;behaves $130

incsrc "../../../../../SSPDef/Defines.asm"
incsrc "cap_defines.asm"

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide : JMP return : JMP return : JMP return
JMP return : JMP TopCorner : JMP BodyInside : JMP HeadInside

TopCorner:
MarioAbove:			;>mario above only so he cannot enter edge and glitch
	LDA !Freeram_SSP_PipeDir	;\if not in pipe
	AND.b #%00001111		;/
	BEQ enter		;/then enter
	if !Setting_SSP_CarryAllowed != 0
		CMP #$01		;\exit if going up
		BEQ exit		;|
		CMP #$05		;|
		BEQ exit		;/
		BRA within_pipe		;>other directions = pass
	else
		;Branch out of bounds with "BEQ exit"
		CMP #$01		;\exit if going up
		BNE +
		JMP exit		;|
		+
		CMP #$05		;|
		BNE +
		JMP exit		;/
		+
		BRA within_pipe		;>other directions = pass
	endif
enter:
	if !Setting_SSP_CarryAllowed == 0
		LDA $1470|!addr		;\no carrying item
		ORA $148F|!addr		;|
		BEQ +
		RTL			;/
		+
	endif
	REP #$20		;\Must be on the correct side to enter.
	LDA $9A			;|
	AND #$FFF0		;|
	if !Setting_SSP_VerticalCapsEnterableWidth != $0008
		SEC
		SBC.w #!Setting_SSP_VerticalCapsEnterableWidth-($0008-1)
	endif
	CMP $94			;|
	SEP #$20		;|
	BCC .MarioOnRight	;>Branch out of bounds.
	RTL			;/
.MarioOnRight
	LDA $15			;\must press down
	AND #$04		;|
	BNE .PressDown		;>Branch out of bounds.
	RTL			;/
.PressDown
	if !Setting_SSP_YoshiAllowed == 0
		LDA $187A|!addr
		BEQ +
		if !Setting_SSP_YoshiProhibitSFXNum != 0
			LDA $16						;\Use 1-frame controller to prevent sound replaying each frame.
			AND #$04					;|(you have to let go the button and tap to trigger this though)
			BEQ ++						;/
			LDA.b #!Setting_SSP_YoshiProhibitSFXNum
			STA !Setting_SSP_YoshiProhibitSFXPort|!addr
			++
		endif
		RTL
		+
	endif
	STZ $00
	%SSPEnterUpwardsFacingPipe()
within_pipe:
	JSR passable
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
	%Get_Player_XPosition_RelativeToBlock()
	BMI return				;>If mario is too far from center, don't exit
	STZ $02
	LDA #$03
	STA $03
	%SSPExitUpwardsPipe()
return:
	RTL
passable:
	LDY #$00		;\mario passes through the block
	LDA #$25		;|
	STA $1693|!addr		;/
	RTS
if !Setting_SSP_Description != 0
	print "Top-left cap cannon piece of vertical 2-way pipe."
endif