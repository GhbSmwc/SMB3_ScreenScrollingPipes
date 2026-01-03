incsrc "../SSPDef/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Detect if sprite is being carried through a screen scrolling pipe, to go behind the layer with the player and
;preventing them from unstunning themselves during travel.
;
;Output:
; Carry: Clear = Draw normally in front of the layer, Set = To draw behind the layer.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?SSPDetectSpriteCarriedInPipe:
	;This to be used to determine if the sprite should be drawn behind the layer.
	;Carry: Clear if outside pipe, Set if inside pipe. This will determine should
	;the sprite being carried to go behind the layer while traveling through SSP.
	LDA !Freeram_SSP_PipeDir	;\Outside the pipe, then in front
	AND.b #%00001111		;|
	BEQ ?.OutsideOfPipe		;/
	LDA !14C8,x			;\If player inside the pipe but not carrying, also in front.
	CMP #$0B			;|
	BNE ?.OutsideOfPipe		;/
	
	?.InsideOfPipe
		SEC
		RTL
	?.OutsideOfPipe
		CLC
		RTL