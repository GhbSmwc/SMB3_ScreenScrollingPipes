incsrc "../SSPDef/Defines.asm"
;Handles exiting the door.
;
;Destroyed:
; $00~$01: Used for vertical positioning checks
?SSPExitDoor
	LDA !Freeram_SSP_EntrExtFlg
	BEQ ?.Done
	CMP #$03			;\If already exiting, skip
	BCS ?.Done			;|
	LDA !Freeram_SSP_PipeDir	;|
	AND.b #%00001111		;|
	BEQ ?.Done			;/
	CMP #$05
	BCC ?.States1To4
	CMP #$09
	BCS ?.Done
	?.States5To8
		SEC
		SBC #$04
	?.States1To4
	ASL
	TAX
	JMP (?.Directions-2,x)

	?.Directions
	dw ?.Up
	dw ?.Right
	dw ?.Down
	dw ?.Left
	
	?.Up
		JSR ?.CompareYPositionToCheck
		BEQ ?.ReachedToExit
		BMI ?.ReachedToExit
		RTL
	?.Right
		%Get_Player_XPosition_RelativeToBlock()
		BEQ ?.ReachedToExit
		BPL ?.ReachedToExit
		RTL
	?.Down
		JSR ?.CompareYPositionToCheck
		BEQ ?.ReachedToExit
		BPL ?.ReachedToExit
		RTL
	?.Left
		%Get_Player_XPosition_RelativeToBlock()
		BEQ ?.ReachedToExit
		BMI ?.ReachedToExit
		RTL
	?.ReachedToExit
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
		if !Setting_SSP_SetXYFractionBits			;|
			LDA.b #!Setting_SSP_YPositionFractionSetTo	;|
			STA $13DC|!addr					;|
		endif							;/
		LDA #$09						;\SFX
		STA $1DFC|!addr						;/
		LDA #$01						;\Exiting timer
		STA !Freeram_SSP_PipeTmr				;/
		LDA #$03						;\Exiting state
		STA !Freeram_SSP_EntrExtFlg				;/
		if !Setting_SSP_HideDuringPipeStemTravel == 0
			LDA #$00
			STA !Freeram_SSP_InvisbleFlag
		endif
	?.Done
		RTL
	?.CompareYPositionToCheck
		REP #$20
		LDA $98
		AND #$FFF0
		if !Setting_SSP_YPositionOffset != 0
			CLC
			ADC.w #!Setting_SSP_YPositionOffset
		endif
		STA $00
		SEP #$20
		%Get_Player_YPosition_LowerHalf()
		REP #$20
		CMP $00
		SEP #$20
		RTS