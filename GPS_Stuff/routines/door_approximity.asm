; Door approximity
; Just a simple code which checks whether Mario is really inside the block.
; Ripped from the original SMW.
; Output:
; C: Clear when Mario is in approximity, set when not.

	LDA $94
	CLC : ADC #$04
	AND #$0F
	CMP #$08
RTL
