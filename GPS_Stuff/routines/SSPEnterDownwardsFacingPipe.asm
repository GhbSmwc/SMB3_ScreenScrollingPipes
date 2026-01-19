incsrc "../SSPDef/Defines.asm"
;This handles mario entering a downwards-facing screen-scrolling pipe.
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
	if !Setting_SSP_YoshiAllowed != 0
		LDY $187A|!addr
		LDA.l ?.YoshiTimersEnter,x
	else
		LDA.b #!Setting_SSP_PipeTimer_Enter_Upwards_OffYoshi
	endif
	STA !Freeram_SSP_PipeTmr
	LDA #$04			;\pipe sound
	STA $1DF9|!addr			;/
	STZ $7B				;\Prevent centering, and then displaced by xy speeds.
	STZ $7D				;/
	LDA !Freeram_SSP_PipeDir	;\Set his direction (Will only force the low nibble (bits 0-3) to have the value 7)
	AND.b #%11110000		;|>Force low nibble clear
	ORA.b #%00000101		;|>Force low nibble set
	STA !Freeram_SSP_PipeDir	;/
	LDA #$01			;\set flag to "entering"
	STA !Freeram_SSP_EntrExtFlg	;/
	if !Setting_SSP_HideDuringPipeStemTravel == 0
		LDA #$00						;\Make player visible
		STA !Freeram_SSP_InvisbleFlag				;/
	endif
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
	?.HandleVerticalPositioning						;\Position vertically
		LDA $19								;|
		ASL								;|
		TAX								;|
		LDA $187A|!addr							;|
		BNE ?..VerticalCenterOnYoshi					;|
		?..VerticalCenterOffYoshi					;|
			REP #$20						;|
			LDA $98							;|
			CLC							;|
			ADC.l ?.CenterVerticallyPowerupOffYoshi,x		;|
			STA $96							;|
			SEP #$20						;|
			BRA ?..ClearYSubpixels					;|
		?..VerticalCenterOnYoshi					;|
			REP #$20						;|
			LDA $98							;|
			CLC							;|
			ADC.l ?.CenterVerticallyPowerupOnYoshi,x		;|
			STA $96							;|
			SEP #$20						;|
		?..ClearYSubpixels						;|
			if !Setting_SSP_SetXYFractionBits			;|
				LDA.b #!Setting_SSP_YPositionFractionSetTo	;|
				STA $13DC|!addr					;|
			endif							;/
	?.Done
	RTL

?.CenterHorizontalOffset
	dw $0008
	dw $FFF8
	dw $0000
	;Note: These is powerup-indexd. Indexed by RAM $19 and doubled.
	;Up to 256 items allowed. Make changes here if you use custom powerups
	;or any form of custom hitboxes.
		?.CenterVerticallyPowerupOffYoshi
		;Offset from the block's Y position (units of pixels, not 16x16) to set the player's Y position.
			dw $FFF0 ;>$19 = #$00 (*2 = #$00)
			dw $FFF8 ;>$19 = #$01 (*2 = #$02)
			dw $FFF8 ;>$19 = #$02 (*2 = #$04)
			dw $FFF8 ;>$19 = #$03 (*2 = #$06)
		?.CenterVerticallyPowerupOnYoshi
		;Same as above but on yoshi
			dw $FFEC ;>$19 = #$00 (*2 = #$00)
			dw $FFF0 ;>$19 = #$01 (*2 = #$02)
			dw $FFF0 ;>$19 = #$02 (*2 = #$04)
			dw $FFF0 ;>$19 = #$03 (*2 = #$06)
if !Setting_SSP_YoshiAllowed != 0
	?.YoshiTimersEnter
	db !Setting_SSP_PipeTimer_Enter_Upwards_OffYoshi,!Setting_SSP_PipeTimer_Enter_Upwards_OnYoshi,!Setting_SSP_PipeTimer_Enter_Upwards_OnYoshi	;>Timers: 1st one = on foot, 2nd and 3rd one = on yoshi
endif
