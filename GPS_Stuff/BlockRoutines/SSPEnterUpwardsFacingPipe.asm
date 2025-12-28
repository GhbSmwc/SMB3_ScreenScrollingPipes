incsrc "../SSPDef/Defines.asm"
;This handles mario entering an upwards-facing screen-scrolling pipe.
;Handles centering, animation, SFX, etc.
;
;Note that this code alone does not check for the requirements to enter
;a pipe.
;
;Input:
; - $00 (1 byte): Centering. #$00 = 8 pixel to the right (left half cap), #$02 = 8 pixel to the left (right half cap),
;   #$04 = block-centered (for small pipe caps)
?SSPEnterUpwardsPipe:
	LDA !Freeram_SSP_EntrExtFlg	;\Failsafe
	CMP #$01			;|
	BEQ ?.Done			;/
	if !Setting_SSP_CarryAllowed != 0
		LDA $1470|!addr			;\if mario not carrying anything
		ORA $148F|!addr			;|then skip
		BEQ ?.NotCarry			;/
		LDA #$01			;\set carrying flag
		STA !Freeram_SSP_CarrySpr	;/
	endif
	?.NotCarry
	if !Setting_SSP_YoshiAllowed != 0
		LDY $187A|!addr
		LDA.l ?.YoshiTimersEnter,x
	else
		LDA.b #!SSP_PipeTimer_Enter_Downwards_OffYoshi
	endif
	STA !Freeram_SSP_PipeTmr
	LDA #$04			;\pipe sound
	STA $1DF9|!addr			;/
	STZ $7B				;\Prevent centering, and then displaced by xy speeds.
	STZ $7D				;/
	LDA !Freeram_SSP_PipeDir	;\Set his direction (Will only force the low nibble (bits 0-3) to have the value 7)
	AND.b #%11110000		;|>Force low nibble clear
	ORA.b #%00000111		;|>Force low nibble set
	STA !Freeram_SSP_PipeDir	;/
	LDA #$01			;\set flag to "entering"
	STA !Freeram_SSP_EntrExtFlg	;/
	?.Center
		LDX $00
		REP #$20
		LDA $9A
		AND #$FFF0
		CLC
		ADC.l ?.CenterHorizontalOffset,x
		STA $94
		SEP #$20
		if !Setting_SSP_SetXYFractionBits
			LDA.b #!Setting_SSP_XPositionFractionSetTo
			STA $13DA|!addr
		endif
	?.Done
	RTL

?.CenterHorizontalOffset
	dw $0008
	dw $FFF8
	dw $0000
if !Setting_SSP_YoshiAllowed != 0
	?.YoshiTimersEnter
	db !SSP_PipeTimer_Enter_Downwards_OffYoshi,!SSP_PipeTimer_Enter_Downwards_OnYoshi,!SSP_PipeTimer_Enter_Downwards_OnYoshi
endif
