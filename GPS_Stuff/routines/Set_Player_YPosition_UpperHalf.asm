;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Set's the player positioned so his upper half of his 16x32 are in this block
;
;The game treats the player's position as if its always a 16x32px box (with the XY being
;on the top-left corner) regardless of powerup or riding yoshi. When Small Mario and not
;riding yoshi, his body occupies the bottom half of this box.
;
;Note: If you have custom powerups, hitboxes, and other position/hitbox shenanigans,
;you might need to edit this code to properly find the right position.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	!BigMarioOffset = $0000 ;>Change this if you have modified the player's hitbox/positioning
?SetPlayerYPositionUpperHalf:
	LDA $187A|!addr
	BNE ?.RidingYoshi
	REP #$30
	LDA $19
	AND #$00FF
	ASL
	TAX
	LDA $98
	AND #$FFF0		;>Clear out the low nybble (low 4 bits), effectively rounding down to nearest 16 units, this is now the block position in pixels.
	CLC
	ADC.l ?.PowerupOffset,x
	STA $96
	SEP #$30
	RTL
	?.RidingYoshi
		REP #$20
		LDA $98
		AND #$FFF0		;>Clear out the low nybble (low 4 bits), effectively rounding down to nearest 16 units, this is now the block position in pixels.
		CLC
		ADC #$FFF0
		STA $96
		SEP #$20
		RTL
	?.PowerupOffset
		;Distance from Y position origin to the top
		;16x16 tile of player (you can use negative number as you wish).
		;Since index is 16-bit, you can use all 256 values of the $19's
		;powerup states.
		dw $FFF0		;>$00 = Small Mario (16x16)
		dw !BigMarioOffset	;>$01 = Big Mario (16x32)
		dw !BigMarioOffset	;>$02 = Cape (16x32)
		dw !BigMarioOffset	;>$03 = Fire (16x32)
		;Add more values here for more powerup states