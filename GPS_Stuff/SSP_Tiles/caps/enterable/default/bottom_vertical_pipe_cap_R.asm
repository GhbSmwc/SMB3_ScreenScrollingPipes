;~@sa1
;This is the bottom right-half cap of a vertical two-way pipe.
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
	if !Setting_SSP_CarryAllowed != 0
		CMP #$03			;\if going down..
		BEQ exit			;|then exit
		CMP #$07			;|
		BEQ exit			;/
		BRA within_pipe			;>other directions = pass
	else
		;Branch out of bounds with "BEQ exit"
		CMP #$03			;\if going down..
		BNE +
		JMP exit			;|then exit
		+
		CMP #$07			;|
		BNE +
		BEQ exit			;/
		+
		JMP within_pipe			;>other directions = pass
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
		CLC
		ADC.w #!Setting_SSP_VerticalCapsEnterableWidth-($0008+1)
	endif
	CMP $94			;|
	SEP #$20		;|
	BCS .MarioOnLeft	;/\Branch out of range.
	RTL			; /
.MarioOnLeft
	LDA $15			;\must press up
	AND #$08		;|\
	BNE .PressUp		;/|Branch out of range
	RTL			; /
.PressUp
	if !Setting_SSP_YoshiAllowed == 0
		LDA $187A|!addr
		BEQ .AllowEnter
		if !Setting_SSP_YoshiProhibitSFXNum != 0
			LDA.b #!Setting_SSP_YoshiProhibitSFXNum
			STA !Setting_SSP_YoshiProhibitSFXPort|!addr
			LDA #$20					;\Prevent SFX playing multiple times.
			STA $7D						;/
		endif
		RTL
		.AllowEnter
	endif
	LDA #$02
	STA $00
	%SSPEnterDownwardsFacingPipe()
within_pipe:
	JSR passable
	RTL
TopCorner:
MarioAbove:
MarioSide:
HeadInside:
BodyInside:
	LDA !Freeram_SSP_PipeDir	;\return for other offset
	AND.b #%00001111		;|
	BNE +
	RTL				;/when not in pipe
	+
	CMP #$03			;\exit of going down
	BEQ exit			;|
	CMP #$07			;|
	BEQ exit			;/
	BRA within_pipe
exit:
	JSR passable
	%Get_Player_XPosition_RelativeToBlock()
	BPL return				;>If mario is too far from center, don't exit
	LDA #$02
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

if !Setting_SSP_YoshiAllowed != 0
	YoshiTimersEnter:
	db !SSP_PipeTimer_Enter_Upwards_OffYoshi,!SSP_PipeTimer_Enter_Upwards_OnYoshi,!SSP_PipeTimer_Enter_Upwards_OnYoshi	;>Timers: 1st one = on foot, 2nd and 3rd one = on yoshi
endif
if !Setting_SSP_Description != 0
	print "Bottom-right cap piece of vertical 2-way pipe."
endif