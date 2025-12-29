incsrc "../SSPDef/Defines.asm"
;This handles mario exiting an upwards-facing screen-scrolling pipe.
;Handles centering, animation, SFX, etc.
;
;Input:
; - $02 (1 byte): Centering. #$00 = 8 pixel to the right (left half cap), #$02 = 8 pixel to the left (right half cap),
;   #$04 = block-centered (for small pipe caps)
; - $03 (1 byte): Exit mode: 
; -- #$03 = regular exit
; -- #$04 = Cannon exit.
?SSPExitUpwardsPipe:
	LDA !Freeram_SSP_EntrExtFlg
	CMP $03
	BEQ ?.AlreadyExiting
	REP #$20
	LDA $98
	AND #$FFF0
	CLC
	ADC #$0010
	STA $00					;>$00~$01: Block pixel Y position, rounded down to nearest block
	SEP #$20
	%Get_Player_YPosition_LowerHalf()
	REP #$20
	CMP $00
	SEP #$20
	BPL ?.Return				;If mario is not far enough into the cap, return
	
	LDA $03
	STA !Freeram_SSP_EntrExtFlg
	LDX $02							;\Center Horizontally
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
	%Set_Player_YPosition_LowerHalf()			;\Center Vertically
	REP #$20						;|
	LDA $96							;|
	CLC							;|
	ADC #$0010						;|
	STA $96							;|
	SEP #$20						;|
	if !Setting_SSP_SetXYFractionBits			;|
		LDA.b #!Setting_SSP_YPositionFractionSetTo	;|
		STA $13DC|!addr					;|
	endif							;/
	LDA #$04						;\pipe sound
	STA $1DF9|!addr						;/
	STZ $7B							;\Prevent centering, and then displaced by xy speeds.
	STZ $7D							;/
	if !Setting_SSP_YoshiAllowed != 0			;\Set exiting timer
		LDX $187A|!addr					;|
		LDA.l ?.YoshiTimersExit,x			;|
	else							;|
		LDA.b #!SSP_PipeTimer_Exit_Upwards_OffYoshi	;|
	endif							;|
	STA !Freeram_SSP_PipeTmr				;/
	
	?.AlreadyExiting
	?.Return
	RTL
	if !Setting_SSP_YoshiAllowed != 0
		?.YoshiTimersExit:
		db !SSP_PipeTimer_Exit_Upwards_OffYoshi,!SSP_PipeTimer_Exit_Upwards_OnYoshi,!SSP_PipeTimer_Exit_Upwards_OnYoshi		;>Timers: 1st one = on foot, 2nd and 3rd one = on yoshi
	endif
	?.CenterHorizontalOffset
		dw $0008
		dw $FFF8
		dw $0000