;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This gets the Y position of the player's "upper-half", which are:
; - Small Mario's hat Y position (since when Small Mario, his origin remains 32 pixels up
;   from his feet).
; - Big Mario's upper 16x16 tile.
; - If Riding yoshi, then it's the space above player's head
;
;Effectively, the game essentially always treats the player's bounding box as a 16x32px
;box, regardless of the powerup and yoshi status.
;
;Output: A (16-bit): Y position of the 16x16 tile that is the upper half of the 16x32.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	!BigMarioOffset = $0000 ;>Change this if you have modified the player's hitbox/positioning
?GetPlayerYPositionUpperHalf:
	LDA $187A|!addr
	BNE ?.RidingYoshi
	REP #$30
	LDA $19
	AND #$00FF
	ASL
	TAX
	LDA $96
	CLC
	ADC.l ?.PowerupOffset,x
	SEP #$30
	RTL
	?.RidingYoshi
		REP #$20
		LDA $96
		CLC
		ADC #$0010
		SEP #$20
		RTL
	?.PowerupOffset
		;Offset from Y position origin to Mario's visible 16x16 tile
		;(you can use negative number as you wish).
		;Since index is 16-bit, you can use all 256 values of the $19's
		;powerup states.
		dw $0010		;>$00 = Small Mario (16x16)
		dw !BigMarioOffset	;>$01 = Big Mario (16x32)
		dw !BigMarioOffset	;>$02 = Cape (16x32)
		dw !BigMarioOffset	;>$03 = Fire (16x32)
		;Add more values here for more powerup states