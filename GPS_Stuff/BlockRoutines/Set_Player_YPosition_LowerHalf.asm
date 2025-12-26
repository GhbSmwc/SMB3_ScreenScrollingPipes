;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Set's player's Y position so that his lower-half is aligned with the currently touched
;block's bottom (if Small Mario touches a block executing this subroutine, he'll be
;vertically centered as usual, for 2-tile high mario, then only his bottom half would be
;in this block, and for riding yoshi, then the saddle part of yoshi would be in this
;block).
;
;The game treats the player's position as if its always a 16x32px box (with the XY being
;on the top-left corner) regardless of powerup or riding yoshi. When Small Mario and not
;riding yoshi, his body occupies the bottom half of this box.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?SetPlayerYPositionLowerHalf:
	REP #$20
	LDA $187A|!addr
	AND #$00FF		;>Just in case
	ASL
	TAX
	LDA $98
	AND #$FFF0		;>Clear out the low nybble (low 4 bits), effectively rounding down to nearest 16 units, this is now the block position in pixels.
	SEC			;\Subtract upwards from the block to where Mario's origin should be
	SBC ?.YoshiOffsetY,x	;/
	STA $96			;>And set to there
	SEP #$20
	RTL
	
	?.YoshiOffsetY
	dw $0010		;>When off yoshi, from feet to XY origin is 32 pixels high
	dw $0020		;\When on yoshi, from yoshi's feet to XY origin is 48 pixels high
	dw $0020		;/