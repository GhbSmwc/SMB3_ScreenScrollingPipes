;~@sa1
;Note that ram address $7FAB10 ($400040 SA-1) are uninitialized when not using a custom sprite.
;Thus certain emulators may fail on running this code.
?CorrectYoshiFacingDirection

	LDA $187A|!addr		;\If not riding yoshi, return
	BEQ ?Return		;/
	PHX			;\Push stack
	PHA			;|
	PHY			;/

	LDX.b #(!sprite_slots-1)
	?.Loop
		if !Setting_SSP_UsingCustomSprites != 0
			LDA !7FAB10,x	;\If custom sprite, next slot
			AND #$08	;|
			BNE ?..Next	;/
		endif
		LDA !9E,x	;\If other than yoshi, next slot
		CMP #$35	;|
		BNE ?..Next	;/
		?..SlotFound
			STZ !157C,x			;>default facing direction right
;			LDA $007B+!dp			;\If going foward in the direction yoshi facing,
;			BPL ++				;/don't alter facing
			LDA !Freeram_SSP_PipeDir	;>Direction
			CMP #$02			;\Rightwards
			BEQ ?..FaceRight		;|
			CMP #$06			;|
			BEQ ?..FaceRight		;/
			CMP #$04			;\Leftwards
			BEQ ?..FaceLeft			;|
			CMP #$08			;|
			BEQ ?..FaceLeft			;/
			;(still checks all slots in case if a double yoshi glitch...)
			BRA ?..Next			;>Other directions

		?..FaceRight
			STZ !157C,x		;>Face right
			BRA ?..Next

		?..FaceLeft
			LDA #$01		;\Face left
			STA !157C,x		;/
		?..Next
			DEX		;>Next slot/index
			BPL ?.Loop	;>If zero or positive, loop back

	PLY		;\Pull stack
	PLA		;|
	PLX		;/
	?Return
	RTL