;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This handles exiting horizontal pipe caps for screen
;scrolling pipes.
;
;Input:
; - $00: Exiting direction:
; -- #$00 = Exiting leftwards
; -- #$02 = Exiting rightwards
; - $01: How the player exits the pipe:
; -- $02 = Exit normally
; -- $03 = Cannon exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?SSPExitHorizontalPipes:
	PHB
	PHK
	PLB
	LDA !Freeram_SSP_EntrExtFlg			;\If already exiting, return
	CMP $01						;|
	BEQ ?.Return					;/
	LDX $00
	BEQ ?.HeadingLeft
	
	?.HeadingRight
		JSR ?.GetExitingThreshold
		BPL ?.Return
		BRA ?.Exiting
	?.HeadingLeft
		JSR ?.GetExitingThreshold
		BMI ?.Return
	?.Exiting
		LDA $00
		LSR
		TAX
		LDA $01				;\Exiting mode
		STA !Freeram_SSP_EntrExtFlg	;/
		LDA !Freeram_SSP_PipeDir	;\Set his direction (Will only force the low nibble (bits 0-3) to have the value 8)
		AND.b #%11110000		;|>Force low nibble clear
		ORA ?.ExitingDirection,x	;|>Force low nibble set
		STA !Freeram_SSP_PipeDir	;/
		LDA ?.ExitTimers,x		;\Set exiting timer
		STA !Freeram_SSP_PipeTmr	;/
		LDA #$04			;\pipe sound
		STA $1DF9|!addr			;/
		STZ $7B				;\Prevent centering, and then displaced by xy speeds.
		STZ $7D				;/
		STX $76				;/Face in the correct direction
		%SSPFaceYoshi()			;>When riding yoshi, make him also face correct direction
		REP #$20						;\Center horizontally
		LDA $9A							;|
		AND #$FFF0						;|
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
			LDA #!Setting_SSP_YPositionFractionSetTo	;|
			STA $13DC|!addr					;|
		endif							;/
	?.Return
		PLB
		RTL
	?.GetExitingThreshold
		REP #$20
		LDA $9A
		AND #$FFF0
		CLC
		ADC ?.OffsetRequiredToEnter,x
		CMP $94
		SEP #$20
		RTS
	?.OffsetRequiredToEnter
		dw $0004
		dw $FFFC
	?.ExitingDirection
		db %00001000
		db %00000110
	?.ExitTimers
		db !SSP_PipeTimer_Exit_Leftwards
		db !SSP_PipeTimer_Exit_Rightwards
		