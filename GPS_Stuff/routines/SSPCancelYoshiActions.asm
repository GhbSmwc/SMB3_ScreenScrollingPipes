incsrc "../SSPDef/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Cancels yoshi turnaround.
;Fixes issue where entering a screen scrolling door or pipe
;where the player simply travels vertically and still retain
;such an animation.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
?SSPCancelYoshiAction
	LDX.b #!sprite_slots-1
	?.Loop
		if !Setting_SSP_UsingCustomSprites != 0
			LDA !7FAB10,x	;\If custom sprite, next slot
			AND #$08	;|
			BNE ?..Next	;/
		endif
		LDA !9E,x		;\If not yoshi's sprite ID, next.
		CMP #$35		;|
		BNE ?..Next		;/
		?..IsYoshi
			STZ !15AC,x	;>Cancel turning around animation.
			STZ !1570,x	;>Cancel what seems to override the above.
			;Here, as a failsafe, must continue looping through remaining slot despite yoshi is found
			;in case of a double-yoshi glitch.
		?..Next
			DEX
			BPL ?.Loop
	RTL