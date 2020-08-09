;This patch removes (reverts the changes) the hijack at $00EA18. This is in case you wanted to install the walljump patch
;AFTER installing Fixes.asm.

	!Fixes_Hijack_00EA18_Restored = 0
	if read4($00EA18) == $791894A5 ;[A5 94 18 79 - LDA $94 : CLC : ADC.w $E90D,Y : STA $94]
		!Fixes_Hijack_00EA18_Restored = 1
	endif
	
	if !Fixes_Hijack_00EA18_Restored == 0
		autoclean read3($00EA18+1)
		org $00EA18
			LDA $94
			CLC
			ADC.w $00E90D,y
		print "Restore successful. You can now safely install the walljump/note block fix patch"
	else
		print "Restore is already done or you haven't installed fixes.asm yet"
	endif