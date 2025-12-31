;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This gets the Y position of the player's "lower-half", which are:
; - Small Mario's hat Y position (since when Small Mario, his origin remains 32 pixels up
;   from his feet).
; - Big Mario's lower 16x16 tile.
; - If Riding yoshi, then it's the saddle part
;
;Effectively, the game essentially always treats the player's bounding box as a 16x32px
;box, regardless of the powerup and yoshi status.
;
;Output: A (16-bit): Y position of the 16x16 tile that is the lower half of the 16x32.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?GetPlayerYPositionLowerHalf:
	REP #$20
	LDA $187A|!addr
	AND #$00FF
	ASL
	TAX
	LDA $96
	CLC
	ADC.l ?.YoshiOffset,x
	SEP #$20
	RTL
	
	?.YoshiOffset
	dw $0010
	dw $0020
	dw $0020