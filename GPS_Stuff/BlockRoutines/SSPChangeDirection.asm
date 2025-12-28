incsrc "../SSPDef/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Handles turns from horizontal to vertical for screen scrolling pipes (often for turn
;corners). Also supports dragmode (direction == $09) as well. This also handles making
;Mario needs to be far in the block deep enough to avoid noticiable snapping (sets XY if
;player is on or past a point he needs to switch direction).
;
;Input:
; - $00: Position relative to the block to change direction: #$00 = 8 pixels to the right,
;   #$02 = 8 pixels to the left, #$04 = block-centered (small turn corner).
; - $01: Direction to set to:
; -- #$01 = Up
; -- #$02 = Right
; -- #$03 = Down
; -- #$04 = Left
; -- #$05~#$08 = Same as above but cap speeds (you probably wouldn't want to use though)
; -- #$09 = Warp drag mode
;Output:
; - Carry = Set if player is in the block far enough to switch states, clear otherwise
;   (useful for warp drag mode by after this subroutine, check carry, if set, then run
;   "%SSPDragMarioMode()")
;
;
;Destroyed:
; - $02~$03: Used for block's position to compare with the player's movement if the player
;   have moved far enough to change direction.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?SSPChangeDirection:
	LDA $01				;\If set to exit pipe, then no.
	AND.b #%00001111		;|
	BEQ ?.Done			;/
	LDA !Freeram_SSP_PipeDir	;\Get direction bits
	AND.b #%00001111		;/
	BEQ ?.Done			;>$00 = no
	CMP #$05			;\$01~$04 = stem speeds
	BCC ?.StemSpeeds		;/
	CMP #$09			;\$05~$08 = cap speeds
	BCC ?.CapSpeeds			;/
	;BEQ ?.Done			;>$09 = warp drag mode (do nothing)
	BRA ?.Done			;>$0A+ = Failsafe (do nothing)
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
		JSR ?.CompareYPositionToCheck
		BEQ ?.SwitchDirection
		BMI ?.SwitchDirection
	?.Done
		RTL
	?.Right
		JSR ?.CompareXPositionToCheck
		BPL ?.SwitchDirection
		RTL
	?.Down
		JSR ?.CompareYPositionToCheck
		BPL ?.SwitchDirection
		RTL
	?.Left
		JSR ?.CompareXPositionToCheck
		BEQ ?.SwitchDirection
		BMI ?.SwitchDirection
		RTL

	?.SwitchDirection
		LDA !Freeram_SSP_PipeDir			;\Change direction
		AND.b #%11110000				;|
		ORA $01						;|
		STA !Freeram_SSP_PipeDir			;/
		REP #$20
		LDX $00							;\Center horizontally
		LDA $9A							;|
		AND #$FFF0						;|
		CLC							;|
		ADC.l ?.XPositionToChangeDirection,x			;|
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
		RTL
	?.CompareXPositionToCheck
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
		RTS
	?.CompareYPositionToCheck
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
		RTS
	?.XPositionToChangeDirection
		dw $0008
		dw $FFF8
		dw $0000