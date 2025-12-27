;~@sa1
;This is the top right-half cap of a vertical two-way pipe.
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
	BEQ enter			;/then enter
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
		CLC
		ADC.w #!Setting_SSP_VerticalCapsEnterableWidth-($0008+1)
	endif
	CMP $94			;|
	SEP #$20		;|
	BCS .MarioOnLeft	;>Branch out of bounds.
	RTL			;/
.MarioOnLeft
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
	if !Setting_SSP_CarryAllowed != 0
		LDA $1470|!addr			;\if mario not carrying anything
		ORA $148F|!addr			;|then skip
		BEQ .not_carry			;/
		LDA #$01			;\set carrying flag
		STA !Freeram_SSP_CarrySpr	;/
	endif
.not_carry
	if !Setting_SSP_YoshiAllowed != 0
		PHY
		LDY $187A|!addr
		LDA YoshiTimersEnter,y
	else
		LDA.b #!SSP_PipeTimer_Enter_Downwards_OffYoshi
	endif
	STA !Freeram_SSP_PipeTmr
	if !Setting_SSP_YoshiAllowed != 0
		PLY
	endif
	LDA #$04		;\pipe sound
	STA $1DF9|!addr		;/
	STZ $7B			;\Prevent centering, and then displaced by xy speeds.
	STZ $7D			;/
	LDA !Freeram_SSP_PipeDir	;\Set his direction (Will only force the low nibble (bits 0-3) to have the value 7)
	AND.b #%11110000		;|>Force low nibble clear
	ORA.b #%00000111		;|>Force low nibble set
	STA !Freeram_SSP_PipeDir	;/
	LDA #$01		;\set flag to "entering"
	STA !Freeram_SSP_EntrExtFlg	;/
	JSR center_horiz	;>center the player to pipe
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
	LDA #$02
	STA $02
	%SSPExitUpwardsPipe()
return:
	RTL

center_horiz:
	REP #$20		;\center player to pipe horizontally.
	LDA $9A			;|
	AND #$FFF0		;|
	SEC : SBC #$0008	;|
	STA $94			;|
	SEP #$20		;/
	if !Setting_SSP_SetXYFractionBits
		LDA.b #!Setting_SSP_XPositionFractionSetTo
		STA $13DA|!addr
	endif
	RTS
passable:
	LDY #$00		;\mario passes through the block
	LDA #$25		;|
	STA $1693|!addr		;/
	RTS
	if !Setting_SSP_YoshiAllowed != 0
		YoshiTimersExit:
		db !SSP_PipeTimer_Exit_Upwards_OffYoshi,!SSP_PipeTimer_Exit_Upwards_OnYoshi,!SSP_PipeTimer_Exit_Upwards_OnYoshi		;>Timers: 1st one = on foot, 2nd and 3rd one = on yoshi
		YoshiTimersEnter:
		db !SSP_PipeTimer_Enter_Downwards_OffYoshi,!SSP_PipeTimer_Enter_Downwards_OnYoshi,!SSP_PipeTimer_Enter_Downwards_OnYoshi
	endif
if !Setting_SSP_Description != 0
print "Top-right cap piece of vertical 2-way pipe."
endif