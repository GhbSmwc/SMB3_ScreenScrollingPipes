incsrc "../SSPDef/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Carry: Clear if outside pipe (should be visible), Set if inside pipe (should be invisible). This will determine
;;should the sprite being carried turn invisible with the player traveling through SSP.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?CheckIfSpriteIsInsideSSPWhenInvisible:
	?.PlayerPipeStatus
		LDA !Freeram_SSP_PipeDir	;\Get player pipe direction
		AND.b #%00001111		;/
		BEQ .Visible			;>If player is outside...
		CMP #$09			;\
		BEQ .Invisible			;/>Not in drag mode
		LDA !Freeram_SSP_PipeTmr	;\...or in a pipe, entering, but before Mario turns invisible.
		BNE .Visible			;/
	?.SpriteCarried
		LDA !14C8,x			;\...or if sprite not carried
		CMP #$0B			;|then make sprite visible.
		BNE .Visible			;/
		if !Setting_SSP_HideDuringPipeStemTravel == 0
			LDA !Freeram_SSP_InvisbleFlag
			BEQ .Visible
		endif
	?.Invisible
		SEC
		RTL
	?.Visible
		CLC
		RTL
?CheckIfSpriteCarriedInPipe:
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .OutsideOfPipe
	LDA !14C8,x
	CMP #$0B
	BNE .OutsideOfPipe
	
	?.InsideOfPipe
		SEC
		RTL
	?.OutsideOfPipe
		CLC
		RTL