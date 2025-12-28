;Output:
; - A (8-bit signed): X position relative to block ($0000 = perfectly centered)
	LDA $9A
	AND #$F0
	SEC
	SBC $94
	EOR #$FF
	INC A
	RTL