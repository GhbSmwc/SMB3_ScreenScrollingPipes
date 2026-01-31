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
	LDA !Freeram_SSP_EntrExtFlg		;\If already entering, done
	CMP #$01				;|
	BEQ ?.Done				;/
	if !Setting_SSP_YoshiAllowed != 0
		LDY $187A|!addr
		LDA.l ?.YoshiTimersEnter,x
	else
		LDA.b #!Setting_SSP_PipeTimer_Enter_Downwards_OffYoshi
	endif
	STA !Freeram_SSP_PipeTmr
	LDA #$04						;\pipe sound
	STA $1DF9|!addr						;/
	if !Setting_SSP_SFX_EnterPipe_SoundNumb
		LDA.b #!Setting_SSP_SFX_EnterPipe_SoundNumb
		STA !Setting_SSP_SFX_EnterPipe_Port
	endif
	STZ $7B							;\Prevent centering, and then displaced by xy speeds.
	STZ $7D							;/
	LDA !Freeram_SSP_PipeDir				;\Set his direction (Will only force the low nibble (bits 0-3) to have the value 7)
	AND.b #%11110000					;|>Force low nibble clear
	ORA.b #%00000111					;|>Force low nibble set
	STA !Freeram_SSP_PipeDir				;/
	LDA #$01						;\set flag to "entering"
	STA !Freeram_SSP_EntrExtFlg				;/
	LDX $00							;\Center horizontally
	REP #$20						;|
	LDA $9A							;|
	AND #$FFF0						;|
	CLC							;|
	ADC.l ?.CenterHorizontalOffset,x			;|
	STA $94							;|
	SEP #$20						;|
	if !Setting_SSP_SetXYFractionBits			;|
		LDA.b #!Setting_SSP_XPositionFractionSetTo	;|
		STA $13DA|!addr					;|
	endif							;/
	%Set_Player_YPosition_LowerHalf()			;\Set Y position (in case player is moved vertically by a solid sprite or layer 2)
	REP #$20						;|
	LDA $96							;|
	SEC							;|
	SBC #$0010						;|
	STA $96							;|
	SEP #$20						;|
	if !Setting_SSP_SetXYFractionBits			;|
		LDA.b #!Setting_SSP_YPositionFractionSetTo	;|
		STA $13DC|!addr					;|
	endif							;/
	%SSPCancelYoshiActions()
	?.Done
	RTL

?.CenterHorizontalOffset
	dw $0008
	dw $FFF8
	dw $0000
if !Setting_SSP_YoshiAllowed != 0
	?.YoshiTimersEnter
	db !Setting_SSP_PipeTimer_Enter_Downwards_OffYoshi,!Setting_SSP_PipeTimer_Enter_Downwards_OnYoshi,!Setting_SSP_PipeTimer_Enter_Downwards_OnYoshi
endif
