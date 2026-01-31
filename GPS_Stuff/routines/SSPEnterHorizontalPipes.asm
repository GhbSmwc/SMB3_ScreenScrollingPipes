incsrc "../SSPDef/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This handles entering horizontal pipe caps for screen
;scrolling pipes. Note that conditions to enter a horizontal
;pipe is not handled here. Add checks before it to perform so.
;
;Input:
; - $00: Entering direction:
; -- #$00 = Entering leftwards
; -- #$02 = Entering rightwards
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?SSPEnterHorizontalPipes:
	LDA !Freeram_SSP_EntrExtFlg				;\If already entering, don't do anything
	CMP #$01						;|
	BEQ ?.Return						;/
	LDA $00
	LSR
	TAX
	LDA.l ?.EnteringTimers,x
	STA !Freeram_SSP_PipeTmr
	if !Setting_SSP_SFX_EnterPipe_SoundNumb
		LDA.b #!Setting_SSP_SFX_EnterPipe_SoundNumb
		STA !Setting_SSP_SFX_EnterPipe_Port
	endif
	STZ $7B							;\Prevent centering, and then displaced by xy speeds.
	STZ $7D							;/
	LDA !Freeram_SSP_PipeDir				;\Set his direction (Will only force the low nibble (bits 0-3) to have the value 6)
	AND.b #%11110000					;|
	ORA.l ?.EnteringDirections,x				;|
	STA !Freeram_SSP_PipeDir				;/
	LDA #$01						;\set flag to "entering"
	STA !Freeram_SSP_EntrExtFlg				;/
	LDX $00
	REP #$20						;\Position horizontally (places mario horizontally next to cap should something like sprite pushes player into cap then entering)
	LDA $9A							;|(this keeps the player turning invisible at a consistent spot)
	AND #$FFF0						;|
	CLC							;|
	ADC.l ?.EnteringXPositions,x				;|
	STA $94							;|
	SEP #$20						;|
	if !Setting_SSP_SetXYFractionBits			;|
		LDA.b #!Setting_SSP_XPositionFractionSetTo	;|
		STA $13DA|!addr					;|
	endif							;/
	%Set_Player_YPosition_LowerHalf()			;\Center vertically
	if !Setting_SSP_YPositionOffset != 0			;|
		REP #$20					;|
		LDA $96						;|
		CLC						;|
		ADC.w #!Setting_SSP_YPositionOffset		;|
		STA $96						;|
		SEP #$20					;|
	endif							;|
	if !Setting_SSP_SetXYFractionBits			;|
		LDA.b #!Setting_SSP_YPositionFractionSetTo	;|
		STA $13DC|!addr					;|
	endif							;/
	?.Return
	RTL
	
	?.EnteringXPositions
		dw $000D		;>Mario at X = +$000D (13) pixels to the right from the block he's touching without clipping
		dw $FFF2		;>Mario at X = -$000E (-14) pixels to the left from the block he's touching without clipping
	?.EnteringTimers
		db !Setting_SSP_PipeTimer_Enter_Leftwards
		db !Setting_SSP_PipeTimer_Enter_Rightwards
	?.EnteringDirections
		db %00001000
		db %00000110