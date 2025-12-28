incsrc "../SSPDef/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Handles turns from horizontal to vertical for screen scrolling pipes (often for turn
;corners).
;
;Input:
; - $00: Position relative to the block to change direction: #$00 = 8 pixels to the right,
;   #$02 = 8 pixels to the left, #$04 = block-centered (small turn corner).
; - $01: Direction to set to:
; -- #$01 = Up
; -- #$02 = Right
; -- #$03 = Down
; -- #$04 = Left
;Destroyed:
; - $02~$03: Used for block's position to compare with the player's movement if the player
;   have moved far enough to change direction.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?SSPTravelRightThenUpOrDown:
	LDA $01				;\If set to exit pipe, then no.
	AND.b #%00001111		;|
	BEQ ?.Done			;/
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ ?.Done			;>$00 = no
	CMP #$09			;\$09+ = no
	BCS ?.Done			;/
	CMP #$05			;\$01~$04 = stem speeds
	BCC ?.StemSpeeds		;/
	
	?.CapSpeeds
		SEC			;\$05~$08 = cap speeds (to convert to stem speeds of the same direction)
		SBC #$04		;/
	?.StemSpeeds
	CMP $01				;\If Mario's current direction and the intended direction equal, no need to change.
	BEQ ?.Done			;/
	ASL				;>Times 2 because each item in the table are 2 bytes long
	TAX				;>Index
	JMP (?.DirectionPointers-2,x)	;>Jump based on the index
	
	?.DirectionPointers
		;Pointers based on Mario's current travel direction prior to changing.
		dw ?.Up
		dw ?.Right
		dw ?.Down
		dw ?.Left
	?.Up
		REP #$20
		LDA $98
		AND #$FFF0
		if !Setting_SSP_YPositionOffset != 0
			CLC
			ADC.w #!Setting_SSP_YPositionOffset
		endif
		STA $02
		SEP #$20
		%Get_Player_YPosition_LowerHalf()
		REP #$20
		CMP $02
		SEP #$20
		BEQ ?.SwitchDirection
		BMI ?.SwitchDirection
	?.Done
		RTL
	?.Right
		LDX $00
		REP #$20
		LDA $9A
		AND #$FFF0
		CLC
		ADC.l ?.XPositionToChangeDirection,x
		STA $02
		LDA $94
		CMP $02
		SEP #$20
		BPL ?.SwitchDirection
		RTL
	?.Down
		REP #$20
		LDA $98
		AND #$FFF0
		if !Setting_SSP_YPositionOffset != 0
			CLC
			ADC.w #!Setting_SSP_YPositionOffset
		endif
		STA $02
		SEP #$20
		%Get_Player_YPosition_LowerHalf()
		REP #$20
		CMP $02
		SEP #$20
		BPL ?.SwitchDirection
		RTL
	?.Left
		LDX $00
		REP #$20
		LDA $9A
		AND #$FFF0
		CLC
		ADC.l ?.XPositionToChangeDirection,x
		STA $02
		LDA $94
		CMP $02
		SEP #$20
		BEQ ?.SwitchDirection
		BMI ?.SwitchDirection
		SEP #$20
		RTL

	?.SwitchDirection
		LDA !Freeram_SSP_PipeDir			;\Change direction
		AND.b #%11110000				;|
		ORA $01						;|
		STA !Freeram_SSP_PipeDir			;/
		REP #$20
		LDX $00						;\Center horizontally
		LDA $9A						;|
		AND #$FFF0					;|
		CLC						;|
		ADC.l ?.XPositionToChangeDirection,x		;|
		STA $94						;/
		SEP #$20					;
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
		RTL
?.XPositionToChangeDirection
	dw $0008
	dw $FFF8
	dw $0000