incsrc "../SSPDef/Defines.asm"
;This handles entering a screen scrolling door.
;
;Input:
; - $00: Direction to set to:
; -- #$00 = Up
; -- #$01 = Right
; -- #$02 = Down
; -- #$03 = Left
; -- #$09 = Warp/drag mode
; - $01: Top or bottom part of the regular-sized door?
; -- #$00 = Bottom
; -- #$02 = Top (Will place player so his lower 16x16 part of the body is below the block)
?SSPEnterDoor:
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
	LDX $01							;|
	REP #$20						;|
	LDA $96							;|
	if !Setting_SSP_YPositionOffset != 0			;|
		CLC						;|
		ADC.w #!Setting_SSP_YPositionOffset		;|
	endif							;|
	CLC							;|
	ADC.l ?.DoorPartOffsets,x				;|
	STA $96							;|
	SEP #$20						;|
	if !Setting_SSP_SetXYFractionBits			;|
		LDA.b #!Setting_SSP_YPositionFractionSetTo	;|
		STA $13DC|!addr					;|
	endif							;/
	LDA #$0F						;\SFX
	STA $1DFC|!addr						;/
	LDA !Freeram_SSP_PipeDir				;\Set direction
	AND.b #%11110000					;|
	ORA $00							;|
	STA !Freeram_SSP_PipeDir				;/
	LDA #$00
	STA !Freeram_SSP_PipeTmr				;>Set timer (0 frames to prevent noticeable player riding yoshi going behind layer before disappearing)
	LDA #$02
	STA !Freeram_SSP_EntrExtFlg				;>And entering mode
	if !Setting_SSP_HideDuringPipeStemTravel == 0
		LDA #$01					;\Make player invisible
		STA !Freeram_SSP_InvisbleFlag			;/
	endif
	%SSPCancelYoshiActions()
	RTL
	?.DoorPartOffsets
		dw $0000
		dw $0010