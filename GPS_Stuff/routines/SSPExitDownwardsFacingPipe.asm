incsrc "../SSPDef/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This handles mario exiting a downwards-facing
;screen-scrolling pipe. Handles centering, animation, SFX,
;etc.
;
;Input:
; - $02 (1 byte): Centering:
; -- #$00 = 8 pixel to the right (left half cap)
; -- #$02 = 8 pixel to the left (right half cap)
; -- #$04 = block-centered (for small pipe caps)
; - $03 (1 byte): Exit mode: 
; -- #$03 = regular exit
; -- #$04 = Cannon exit.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?SSPExitUpwardsPipe:
	PHB
	PHK
	PLB
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
	ADC ?.CenterHorizontalOffset,x				;|
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
	if !Setting_SSP_SFX_ExitPipe_SoundNumb
		LDA.b #!Setting_SSP_SFX_ExitPipe_SoundNumb
		STA !Setting_SSP_SFX_ExitPipe_Port
	endif
	STZ $7B							;\Prevent centering, and then displaced by xy speeds.
	STZ $7D							;/
	%SSPCancelYoshiActions()
	;Set exiting timer
		LDA $03
		CMP #$03
		BEQ ?.RegularExit
		CMP #$04
		BEQ ?.CannonExit
		BRA ?.Return
		
		?.RegularExit
			if !Setting_SSP_YoshiAllowed != 0
				LDX $187A|!addr
			endif
			LDA $19
			BNE ?..BigMario
			
			?..SmallMario
				if !Setting_SSP_YoshiAllowed == 0
					LDA.b #!Setting_SSP_PipeTimer_Exit_Downwards_OffYoshi_SmallMario
					BRA ?.StoreTimer
				else
					LDA ?.SmallMarioRegularExitTimes,x
					BRA ?.StoreTimer
				endif
			?..BigMario
				if !Setting_SSP_YoshiAllowed == 0
					LDA.b #!Setting_SSP_PipeTimer_Exit_Downwards_OffYoshi_BigMario
					BRA ?.StoreTimer
				else
					LDA ?.BigMarioRegularExitTimes,x
					BRA ?.StoreTimer
				endif
		?.CannonExit
			if !Setting_SSP_YoshiAllowed != 0
				LDX $187A|!addr
			endif
			LDA $19
			BNE ?..BigMario
			
			?..SmallMario
				if !Setting_SSP_YoshiAllowed == 0
					LDA.b #!SSP_PipeTimer_CannonExit_Downwards_OffYoshi_SmallMario
					BRA ?.StoreTimer
				else
					LDA ?.SmallMarioCannonExitTimes,x
					BRA ?.StoreTimer
				endif
			?..BigMario
				if !Setting_SSP_YoshiAllowed == 0
					LDA.b #!SSP_PipeTimer_CannonExit_Downwards_OffYoshi_BigMario
					BRA ?.StoreTimer
				else
					LDA ?.BigMarioCannonExitTimes,x
					;BRA ?.StoreTimer
				endif
		?.StoreTimer
			STA !Freeram_SSP_PipeTmr
	
	?.AlreadyExiting
	?.Return
	PLB
	RTL
	?.CenterHorizontalOffset
		dw $0008
		dw $FFF8
		dw $0000
	if !Setting_SSP_YoshiAllowed != 0
		?.SmallMarioRegularExitTimes
			db !Setting_SSP_PipeTimer_Exit_Downwards_OffYoshi_SmallMario
			db !Setting_SSP_PipeTimer_Exit_Downwards_OnYoshi_SmallMario
			db !Setting_SSP_PipeTimer_Exit_Downwards_OnYoshi_SmallMario
		?.BigMarioRegularExitTimes
			db !Setting_SSP_PipeTimer_Exit_Downwards_OffYoshi_BigMario
			db !Setting_SSP_PipeTimer_Exit_Downwards_OnYoshi_BigMario
			db !Setting_SSP_PipeTimer_Exit_Downwards_OnYoshi_BigMario
		?.SmallMarioCannonExitTimes
			db !SSP_PipeTimer_CannonExit_Downwards_OffYoshi_SmallMario
			db !SSP_PipeTimer_CannonExit_Downwards_OnYoshi_SmallMario
			db !SSP_PipeTimer_CannonExit_Downwards_OnYoshi_SmallMario
		?.BigMarioCannonExitTimes
			db !SSP_PipeTimer_CannonExit_Downwards_OffYoshi_BigMario
			db !SSP_PipeTimer_CannonExit_Downwards_OnYoshi_BigMario
			db !SSP_PipeTimer_CannonExit_Downwards_OnYoshi_BigMario
	endif