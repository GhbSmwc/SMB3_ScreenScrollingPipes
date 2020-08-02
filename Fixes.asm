;This patch fixes:
;-Hdma issue and message box problems when first hitting it after exiting a pipe.
;--I had to do this rather than hijacking $00CDE8 (the routine that clears $9D, the freeze
;  flag, part of the camera scroll routine from L/R, runs every frame) because (1), its
;  intrusive, and (2) uberasm's hijacks are located AFTER the routine that makes mario react
;  to the controls (some controls like jumping won't get disabled).
;-Entering yoshi automatically if you enter left, right, or up facing pipes while
; overlapping its saddle hitbox of yoshi.
;-Since $72 is bad to use in interactive layer 2 levels (it assumes mario is falling
; during a block routine EVEN if you are on ground), so the only way for horizontal pipes
; to detect if mario is on the ground is to use $77 (the blocked status). Too bad $00EAA9
; (this clears out blocked and slope status as well as decompressed graphics flag) runs before
; the custom blocks routine, causing blocks to always assume $77 is #$00. So I had to hijack
; it and save it to a freeram and let it clear $77 right after (so that it clears when mario
; is touching nothing). Do note that the backup version is a frame late.
;-Centers properly if entering horizontal pipes while standing on solid sprites.
;--Do note that this only applies to smw sprites, in all custom sprites that sets the player's
;  x and y position ($94-$97), add a check before it to skip that code so it doesn't disalign
;  the player character when entering the pipe.
;-Various sprite related issues. Note: This will ONLY apply to SMW sprites! Meaning custom sprites,
; especially if they use their own code (or their shared subroutines) and not SMW's vanilla subroutines,
; may not follow this change. So you have to edit those manually.
;--Solid sprites and platform sprites setting the player's coordinate (mainly the Y position)
;  which can cause the player not to be centered with horizontal pipes.
;--Side-solid sprites like the turn block bridge can block the player's horizontal pipe traveling.
;--Carried sprites may interact with other sprites even when carried by player through pipes when
;  freeze flag is set.
;--When utilizing "invisible pipe connectors", carried sprites into pipes don't turn invisible
;  with the player, which will reveal the player's animation traveling through.
;
;To tell if the player is in the pipe, use this code:
;	LDA !Freeram_SSP_PipeDir
;	AND.b #%00001111
;	;^After the above, A will be nonzero should the player be inside the pipe. Use BEQ/BNE
;	; after this.

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SA1 detector:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	!dp = $0000
	!addr = $0000
	!sa1 = 0
	!gsu = 0

if read1($00FFD6) == $15
	sfxrom
	!dp = $6000
	!addr = !dp
	!gsu = 1
elseif read1($00FFD5) == $23
	sa1rom
	!dp = $3000
	!addr = $6000
	!sa1 = 1
endif

incsrc "SSPDef/Defines.asm"

	macro define_sprite_table(name, addr, addr_sa1)
		if !sa1 == 0
			!<name> = <addr>
		else
			!<name> = <addr_sa1>
		endif
	endmacro

%define_sprite_table("9E", $9E, $3200)
%define_sprite_table("AA", $AA, $9E)
%define_sprite_table("B6", $B6, $B6)
%define_sprite_table("C2", $C2, $D8)
%define_sprite_table("D8", $D8, $3216)
%define_sprite_table("E4", $E4, $322C)
%define_sprite_table("14C8", $14C8, $3242)
%define_sprite_table("14D4", $14D4, $3258)
%define_sprite_table("14E0", $14E0, $326E)
%define_sprite_table("14EC", $14EC, $74C8)
%define_sprite_table("14F8", $14F8, $74DE)
%define_sprite_table("1504", $1504, $74F4)
%define_sprite_table("1510", $1510, $750A)
%define_sprite_table("151C", $151C, $3284)
%define_sprite_table("1528", $1528, $329A)
%define_sprite_table("1534", $1534, $32B0)
%define_sprite_table("1540", $1540, $32C6)
%define_sprite_table("154C", $154C, $32DC)
%define_sprite_table("1558", $1558, $32F2)
%define_sprite_table("1564", $1564, $3308)
%define_sprite_table("1570", $1570, $331E)
%define_sprite_table("157C", $157C, $3334)
%define_sprite_table("1588", $1588, $334A)
%define_sprite_table("1594", $1594, $3360)
%define_sprite_table("15A0", $15A0, $3376)
%define_sprite_table("15AC", $15AC, $338C)
%define_sprite_table("15B8", $15B8, $7520)
%define_sprite_table("15C4", $15C4, $7536)
%define_sprite_table("15D0", $15D0, $754C)
%define_sprite_table("15DC", $15DC, $7562)
%define_sprite_table("15EA", $15EA, $33A2)
%define_sprite_table("15F6", $15F6, $33B8)
%define_sprite_table("1602", $1602, $33CE)
%define_sprite_table("160E", $160E, $33E4)
%define_sprite_table("161A", $161A, $7578)
%define_sprite_table("1626", $1626, $758E)
%define_sprite_table("1632", $1632, $75A4)
%define_sprite_table("163E", $163E, $33FA)
%define_sprite_table("164A", $164A, $75BA)
%define_sprite_table("1656", $1656, $75D0)
%define_sprite_table("1662", $1662, $75EA)
%define_sprite_table("166E", $166E, $7600)
%define_sprite_table("167A", $167A, $7616)
%define_sprite_table("1686", $1686, $762C)
%define_sprite_table("186C", $186C, $7642)
%define_sprite_table("187B", $187B, $3410)
%define_sprite_table("190F", $190F, $7658)
%define_sprite_table("1FD6", $1FD6, $766E)
%define_sprite_table("1FE2", $1FE2, $7FD6)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Fix player-related glitches
	org $00C5CE				;\fix hdma issues (like message box) when setting
		autoclean JSL FixHDMA		;/$7E0071 to #$0B ($00cde8 constantly sets $9D to $00 when $71 is $00.).
		NOP #4
	
	org $01ED44				;\fix getting on yoshi automatically when entering
		autoclean JML GetOnYoshiExcept	;/horizontal pipes while ovelapping yoshi's saddle.
	
	org $00EAA9				;\This is why blocks always assume $77, $13E1 and $13EE
		autoclean JSL BlockedFix	;/are stored as zero (this runs every frame).
		nop #1
;Fix various springboard glitches.
	org $01E650
		autoclean JML Sprite_Springboard_CancelLaunch	;>So after exiting pipe, doesn't continue bouncing the player up
	
	org $01E6F0
		autoclean JSL Sprite_Springboard_ImageFix	;>If you enter a pipe while on a springboard when pressed down, will revert its image to unpressed.
		nop #2
;Fix misc glitches
	org $01B8D5
		autoclean JML Sprite_TurnBlockHV_SideSolidFix		;>Fix a bug that if mario moves horizontally into a turn block bridge, would block him.
	org $01A417
		autoclean JML SpriteSub_CarryInteractWithOtherSpr
	org $02CDD5
		autoclean JML Sprite_Peabounceer_FirstFrameBounce
		;^Fixes a bug if the player holds jump, and on the
		; first frame the pea bouncer rises up from the
		; lowest point (and pushes the player up), enters
		; a pipe, causes mario to to fly upwards at the
		; other end of the pipe should that bouncer is
		; onscreen.
;Prevent platforms from setting the player's Y position (which that create problems with entering horizontal pipe caps.)
	org $01AAD8
		autoclean JML Sprite_Key_pos			;>Prevent Key from setting mario position (also p-switch).
	
	org $01B882
		autoclean JML Sprite_TurnBlockHV_pos		;>Same as above (turnblock bridge, vertical and horizontal)
		;^Happens by entering the pipe while expanding vertically.
	org $02CFA5
		autoclean JML Sprite_Peabouncer_pos
	
	org $01B47F
		autoclean JML Sprite_InvisibleBlock_pos
		;breakpoints at $01B48F:
		;-Invisible solid block
		;-creating/eating block
		;-Sprite question blocks
		;-message block
		;-flying grey turnblocks)
		;-Dark room light switch.
		;-Dolphins (all types)
		;-Grow/shrink pipe end
		;-Sprite platforms (checker, rock, wooden, including grey chained platform)
		;-pretty much all other platform sprites (solid top, like boo block and lakitu cloud)?
	org $01E666
		autoclean JML Sprite_springboard_Pos		;>Springboard will not set player's Y position during entering.
	org $01CA3C
		autoclean JML Sprite_ChainedPlatform_pos
	
	org $02EE77
		autoclean JML Sprite_SkullRaft_pos
	
	org $0387F6
		autoclean JML Sprite_Megamole_pos
	
	org $038CA7
		autoclean JML Sprite_CarrotLft_Pos
;Just in case tides can move the player in pipe.
	org $00DA6C
		autoclean JML Layer3TideDisablePush
;Makes carried sprites in SSPs invisible with the player.
	org $01981B
		autoclean JSL MakeShellsInvisible	;>Makes sprite invisible with the player when they are carried in pipes.
		nop #2
			;Works on:
			;-All 4 colors of koopa shells.
			;-Buzzy Beetles.
	org $01A1F3
		autoclean JSL MakeKeyInvisible	;>Key.
		nop #2
	org $01A162
		autoclean JSL MakeMechaKoopaInvisible	;>Mechakoopa
	org $01A14D
		autoclean JML MakeGoombaInvisible
		nop #2
	;org $01A187
	;	autoclean JML MakeMostCarryableSpritesInvisible
	;this handles pretty much most of the carryable sprite, sadly, this also have non-graphic-related stuff (such as physics),
	;so potential bugs could happen if I modify to skip this entire subroutine when invisible with the player.
freecode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FixHDMA: ;>JSL from $00C5CE
	LDA $0D9B|!addr
	CMP #$C1
	BNE .NormalLevel

	.BowserFight
	;Restore code
	STZ.W $0D9F|!addr		;>no HDMA!
	LDA.B #$01			;\
	STA.W $1B88|!addr		;/ message box is expanding

	.NormalLevel
	RTL
;---------------------------------------------------------------------------------
GetOnYoshiExcept: ;>JML from $01ED44
	LDA $7D				;\Restore speed check in order to get on yoshi.
	BMI .NoYoshi			;/
	LDA !Freeram_SSP_PipeDir	;\if in pipe mode, don't get on yoshi while entering.
	AND.b #%00001111		;/
	BNE .NoYoshi
	JML $01ED48		;>Get on yoshi

	.NoYoshi
	JML $01ED70		;>Don't get on yoshi.

;---------------------------------------------------------------------------------
BlockedFix: ;>JSL from $00EAA9
;	LDA $13E1|!addr		;\In case you also wanted blocks to detect slope, remove
;	STA $xxxxxx		;/the semicolons (";") before it and add a freeram in place of xxxxxx
	STZ $13E1|!addr		;>Restore code (clears slope type)

	LDA $77				;\backup/save block status for use for blocks...
	STA !Freeram_BlockedStatBkp	;/
	STZ $77				;>...before its cleared.

	;^This (or both) freeram will get cleared when $77 and/or $13E1
	; gets cleared on the next frame due to a whole big loop SMW runs.
	; when mario isn't touching a solid object.

	;So after executing $00EAA9, you should use the freeram that has
	;the blocked and/or slope status saved in them. If before $00EAA9,
	;then use the original ($77 and/or $13E1). Do not write a value on
	;this freeram, it will do nothing, write on those default ram address.
	RTL
;---------------------------------------------------------------------------------
SpriteSub_CarryInteractWithOtherSpr: ;>JML from $01A417
	LDA.w !14C8,x		;>Sprite status
	CMP.b #$08		;\If sprite is "alive"
	BCS .CODE_01A421	;/Go to where the loop starts on and handle sprite <-> sprite interaction
	JML $01A4B0		;>Otherwise go to next sprite to check.

	.CODE_01A421
		..CheckIfSpriteCarredInSSP
			LDA !14C8,x			;\Sprite A gets assigned to X and sprite B gets assigned to Y. Then test if the 2 touches each other.
			CMP.b #$0B			;|>If either or both sprite A and B are carried, then check if player in pipe.
			BEQ ...Carried			;|
			LDA !14C8,y			;|
			CMP.b #$0B			;|
			BEQ ...Carried			;/
			...NotCarried
				BRA ...OutOfPipe
			...Carried
				LDA !Freeram_SSP_PipeDir	;\and/or player is outside of pipe, then enable interaction
				AND.b #%00001111		;|with other sprites.
				BEQ ...OutOfPipe		;/
			
			...InPipe
				JML $01A4B0		;>Ignore interaction should carried sprite is in pipe.
			...OutOfPipe
				JML $01A421
;---------------------------------------------------------------------------------
Sprite_Springboard_CancelLaunch:         ;>JML from $01E650
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .NotInPipe

	.InPipe
	STZ !1540,x
	JML $01E6B0

	.NotInPipe
	LDA !1540,x
	BEQ .Addr_01E6B0

	JML $01E655

	.Addr_01E6B0
	JML $01E6B0
;---------------------------------------------------------------------------------
Sprite_springboard_Pos:         ;>JML from $01E666

	LDA.w $01E611,Y			;\restore code.
	STA !1602,x			;/

	LDA !Freeram_SSP_PipeDir	;\If mario is entering a pipe, don't set his y position
	AND.b #%00001111		;|
	BNE .DontSetPos			;/

	.SetPos
	JML $01E66C

	.DontSetPos
	JML $01E683
;---------------------------------------------------------------------------------
Sprite_Springboard_ImageFix:     ;>JSL from $01E6F0
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	LDY #$00
	STZ !1602,x			;>Do note that if you did a yoshi-springboard bug, pipes would fix this.

	.Restore
	LDY.w !1602,x
	LDA.w $01E6FD,Y
	RTL
;---------------------------------------------------------------------------------
Sprite_Key_pos:                 ;>JML from $01AAD8
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $01AAF1

	.Restore
	LDA #$1F
	LDY $187A|!addr
	JML $01AADD
;---------------------------------------------------------------------------------
Sprite_TurnBlockHV_pos:         ;>JML from $01B882
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $01B8B1

	.Restore
	LDA $0D
	CLC
	ADC #$1F
	JML $01B887 ;>Continue onwards
;---------------------------------------------------------------------------------
Sprite_TurnBlockHV_SideSolidFix:     ;>JML from $01B8D5
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore
	
	JML $01B8FE
	
	.Restore
	LDA $0E
	CLC
	ADC.b #$10
	JML $01B8DA
	
;---------------------------------------------------------------------------------
Sprite_Peabounceer_FirstFrameBounce:           ;>JML from $02CDD5
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	;STZ !151C,x		;\State that indicates should mario launch upwards
	STZ !1534,x		;|
	;STZ !1528,x		;|
	JML $02CDF1		;/

	.Restore
	LDA !1534,x
	BEQ ..CODE_02CDF1
	JML $02CDDA

	..CODE_02CDF1
	JML $02CDF1
;---------------------------------------------------------------------------------
Sprite_Peabouncer_pos:          ;>JML from $02CFA5
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $02CFFD

	.Restore
	LDA #$1F
	PHX
	LDX $187A|!addr
	JML $02CFAB
;---------------------------------------------------------------------------------
Sprite_InvisibleBlock_pos:         ;>JML from $01B47F
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $01B4B1

	.Restore
	LDA #$1F
	LDY $187A|!addr
	JML $01B484
;---------------------------------------------------------------------------------
Sprite_ChainedPlatform_pos:        ;>JML from $01CA3C
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $01CA6E

	.Restore
	LDA #$28
	LDY $187A|!addr
	JML $01CA41
;---------------------------------------------------------------------------------
Sprite_SkullRaft_pos:              ;>JML from $02EE77
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $02EEA8

	.Restore
	LDA #$1C
	LDY $187A|!addr
	JML $02EE7C
;---------------------------------------------------------------------------------
Sprite_Megamole_pos:               ;>JML from $0387F6
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $03881D

	.Restore
	LDA #$D6
	LDY $187A|!addr
	JML $0387FB
;---------------------------------------------------------------------------------
Sprite_CarrotLft_Pos:              ;>JML from $038CA7
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $038CE3

	.Restore
		LDA $187A|!addr
		CMP #$01
		JML $038CAC
;---------------------------------------------------------------------------------
Layer3TideDisablePush:             ;>JML from $00DA6C
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore
	BRA +
	
	.Restore
	LDA $1403|!addr
	BEQ +
	JML $00DA71
	+
	JML $00DA79
;---------------------------------------------------------------------------------
MakeShellsInvisible:            ;>JSL from $01981B
	.Restore
		STA !15EA,x
	.CheckPipeState
		JSL CheckIfSpriteIsInsideSSPWhenInvisible
		BCC ..Visible
	..Invisible
		RTL
	..Visible
		PHK
		PEA.w ...jslrtsreturn-1
		PEA.w $9D66-1
		JML $019F0D
		...jslrtsreturn
	RTL
;---------------------------------------------------------------------------------
MakeKeyInvisible:                  ;>JSL from $01A1F3 (key)
	.Restore
		PHK
		PEA.w ..jslrtsreturn-1
		PEA.w $9D66-1
		JML $01A169
		..jslrtsreturn
	.CheckPipeState
		JSL CheckIfSpriteIsInsideSSPWhenInvisible
		BCC ..Visible
		..Invisible
			RTL
		..Visible
			PHK
			PEA.w ...jslrtsreturn-1
			PEA.w $9D66-1
			JML $019F0D
			...jslrtsreturn
		RTL
;---------------------------------------------------------------------------------
MakeMechaKoopaInvisible:           ;>JSL from $01A162
	JSL CheckIfSpriteIsInsideSSPWhenInvisible
	BCC .Visible
	
	.Invisible
		RTL
	.Visible
		JSL $03B307
		RTL
;---------------------------------------------------------------------------------
MakeGoombaInvisible:    ;>JML from $01A14D
	JSL CheckIfSpriteIsInsideSSPWhenInvisible
	BCS .Invisible
	
	.Visible
		LDA #$80
		JML $019F09
	.Invisible
		JML $019F5A
;---------------------------------------------------------------------------------
MakeMostCarryableSpritesInvisible:              ;>JML from $01A187
	.CheckFirst
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Subroutines.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckIfSpriteIsInsideSSPWhenInvisible:
	;Carry: Clear if outside pipe, Set if inside pipe. This will determine should
	;the sprite being carried turn invisible with the player traveling through SSP.
	.PlayerPipeStatus
		LDA !Freeram_SSP_PipeDir	;\If player is outside...
		AND.b #%00001111		;|
		BEQ .Visible			;/
		LDA !Freeram_SSP_EntrExtFlg	;\...or is in a pipe, but not in his stem phase
		CMP #$01			;|
		BNE .Visible			;/
		LDA !Freeram_SSP_PipeTmr	;\...or in a pipe, entering, but before Mario turns invisible.
		BNE .Visible			;/
	.SpriteCarried
		LDA !14C8,x			;\...or if sprite not carried
		CMP #$0B			;|then make sprite visible.
		BNE .Visible			;/
	.Invisible
		SEC
		RTL
	.Visible
		CLC
		RTL