incsrc "../SSPDef/Defines.asm"

assert !Setting_SSP_HideDuringPipeStemTravel == 0, "Blocks toggling visibility is not needed if player will always turn invisible."
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Sets Mario visibility when centered into the block enough (avoids jarring player
;appearing/disappearing at edge of block) during a pipe travel.
;
;Input:
; - $00: visibility option:
; -- #$00 = Make player visible
; -- #$00 = Make player invisible
;Destroyed:
; - $01~$02: Mario's Y position of his lower 16x16.
; - $03~$04: Block's Y position (in pixels, rounded down to nearest 16th unit) of a
;   currently processed collision point
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?SSPSetVisibility:
	%Get_Player_YPosition_LowerHalf()
	REP #$20
	STA $01					;>$01~$02: Mario's Y position of his lower 16x16.
	LDA $98					;\$03~$04: Block's Y position (in pixels, rounded down to nearest 16th unit) of a currently processed collision point
	AND #$FFF0				;|
	STA $03					;/
	SEP #$20
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ ?.Done
	CMP #$09
	BCS ?.Done
	CMP #$05
	BCC ?.StemSpeedValues
	SEC
	SBC #$04
	?.StemSpeedValues
	ASL
	TAX
	JMP (?.DirectionPointers-2,x)
	
	?.DirectionPointers
		;Pointers based on Mario's current travel direction prior to changing visibility.
		dw ?.Up
		dw ?.Right
		dw ?.Down
		dw ?.Left
	?.Done
		SEP #$20
		RTL
	?.Up
		REP #$20
		LDA $01
		CMP $03
		BEQ ?.SetVisibility
		BMI ?.SetVisibility
		BRA ?.Done
	?.Right
		%Get_Player_XPosition_RelativeToBlock()
		BPL ?.SetVisibility
		BRA ?.Done
	?.Down
		REP #$20
		LDA $01
		CMP $03
		BPL ?.SetVisibility
		BRA ?.Done
	?.Left
		%Get_Player_XPosition_RelativeToBlock()
		BPL ?.Done
	?.SetVisibility
		SEP #$20
		LDA $00
		STA !Freeram_SSP_InvisbleFlag
		RTL