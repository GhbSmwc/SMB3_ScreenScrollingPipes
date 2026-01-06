;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This checks the player's bottom 16x16 (Small Mario's body, bottom half of Big Mario,
;Yoshi Saddle while riding)'s center position to see if it is inside the current block.
;
;This is used for screen scrolling pipes to prevent a horizontally-traveling player from
;interacting with pipe components that isn't on the same row of blocks as the player's
;bottom 16x16. Things like 2 corner turn blocks touching each other vertically would
;cause the player to get stuck in between without this check.
; - Input:
; -- $00~$01: X position offset from player's bottom 16x16 (#$0000 is exactly centered), signed.
; -- $02~$03: Y position offset from player's bottom 16x16 (#$0000 is exactly centered), signed.
; - Output:
; -- Carry: Set if the point is in the current block, clear otherwise.
;
;  Note that offsets are needed if the player can be exactly be in between 2 blocks, as
;  only one of them will be picked.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	?DistanceFromTurnCornerCheck:
	;Prevents such glitches where as the player leaves a special turn corner
	;and activates a special direction block while touching the previous corner
	;would cause the player to travel in the wrong direction.
	;
	;$00-$03 holds the position "point" on Mario/yoshi's feet:
	;$00-$01 is the X position in units of block
	;$02-$03 is Y position in units of block
	;
	;AND #$FFF0 rounds DOWN to the nearest #$0010 value
	;Carry is set if the player's position point is inside the block and clear if outside.
	
	LDA $187A|!addr		;\Yoshi Y positioning
	ASL			;|
	TAX			;/
	
	REP #$20
	LDA $94				;\Get X position
	CLC				;|
	ADC #$0008			;|
	CLC				;|
	ADC $00				;|
	AND #$FFF0			;|
	STA $00				;/
	LDA $96				;\Get Y position
	CLC				;|
	ADC.l FootDistanceYpos,x	;|
	CLC				;|
	ADC $02				;|
	AND #$FFF0			;|
	STA $02				;/
	
	LDA $9A				;\if X position point is within this block
	AND #$FFF0			;|
	CMP $00				;|
	BNE +				;/
	LDA $98				;\if Y position point is within this block
	AND #$FFF0			;|
	CMP $02				;|
	BNE +				;/
	SEC
	SEP #$20
	RTL
	+
	CLC	
	SEP #$20
	RTL
	FootDistanceYpos:
	dw $0018, $0028, $0028