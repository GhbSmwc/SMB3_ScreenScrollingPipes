incsrc "../SSPDef/Defines.asm"
;This handles mario exiting a downwards-facing screen-scrolling pipe.
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
	STA $00					;>$00~$01: Block pixel Y position, rounded down to nearest block
	SEP #$20
	%Get_Player_YPosition_LowerHalf()
	REP #$20
	CMP $00
	SEP #$20
	BMI ?.Return				;If mario is not far enough into the cap, return
	
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
	if !Setting_SSP_SetXYFractionBits			;|
		LDA.b #!Setting_SSP_YPositionFractionSetTo	;|
		STA $13DC|!addr					;|
	endif							;/
	LDA #$04						;\pipe sound
	STA $1DF9|!addr						;/
	STZ $7B							;\Prevent centering, and then displaced by xy speeds.
	STZ $7D							;/
	;Set exiting timer
		if !Setting_SSP_YoshiAllowed != 0
			LDA $187A|!addr
			BNE ?.YoshiExit
		endif
		LDA $19
		BNE ?.BigMario
		
		?.SmallMario
			LDA.b #!SSP_PipeTimer_Exit_Downwards_OffYoshi_SmallMario
			BRA ?.StoreTimer
		?.BigMario
			LDA.b #!SSP_PipeTimer_Exit_Downwards_OffYoshi_BigMario
			if !Setting_SSP_YoshiAllowed != 0
				BRA ?.StoreTimer							;/
				
				?.YoshiExit
				LDA $19			;\powerup
				BNE ?.BigMarioYoshi	;/
		
				LDA.b #!SSP_PipeTimer_Exit_Downwards_OnYoshi_SmallMario		;\Small on yoshi's timer
				BRA ?.StoreTimer							;/
				
				?.BigMarioYoshi
				LDA.b #!SSP_PipeTimer_Exit_Downwards_OnYoshi_BigMario		;>big on yoshi's timer
			endif
		?.StoreTimer
			STA !Freeram_SSP_PipeTmr
	
	?.AlreadyExiting
	?.Return
	RTL
	
	?.CenterHorizontalOffset
		dw $0008
		dw $FFF8
		dw $0000