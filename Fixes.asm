;This patch fixes:
;-Hdma issue and message box problems when first hitting it after exiting a pipe.
;--I had to do this rather than hijacking $00CDE8 (the routine that clears $9D, the freeze
;  flag, part of the camera scroll routine from L/R, runs every frame) because (1), its
;  intrusive, and (2) uberasm's hijacks are located AFTER the routine that makes mario react
;  to the controls (some controls like jumping won't get disabled).
;-Entering yoshi automatically if you enter left, right, or up facing pipes while
; overlapping its saddle hitbox.
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
;
;
;To tell if the player is in the pipe, use this code:
;	LDA !Freeram_SSP_PipeDir
;	AND.b #%00001111
;	;^After the above, A will be nonzero should the player be inside the pipe. Use BEQ/BNE
;	; here.

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
org $00C5CE				;\fix hdma issues (like message box) when setting
	autoclean JSL FixHDMA		;/$7E0071 to #$0B ($00cde8 constantly sets $9D to $00 when $71 is $00.).
	NOP #4

org $01ED44				;\fix getting on yoshi automatically when entering
	autoclean JML GetOnYoshiExcept	;/horizontal pipes while ovelapping yoshi's saddle.

org $00EAA9				;\This is why blocks always assume $77, $13E1 and $13EE
	autoclean JSL BlockedFix	;/are stored as zero (this runs every frame).
	nop #1

org $01E650
	autoclean JML Sprite_Springboard_CancelLaunch	;>So after exiting pipe, doesn't continue bouncing the player up

org $01E666
	autoclean JML Sprite_springboard_Pos		;>Springboard will not set player's Y position during entering.

org $01E6F0
	autoclean JSL Sprite_Springboard_ImageFix	;>If you enter a pipe while on a springboard when pressed down, will revert its image to unpressed.
	nop #2

org $01AAD8
	autoclean JML Sprite_Key_pos			;>Prevent Key from setting mario position (also p-switch).

org $01B882
	autoclean JML Sprite_TurnBlockHV_pos		;>Same as above (turnblock bridge, vertical and horizontal)
	;^Happens by entering the pipe while expanding vertically.

org $02CDD5
	autoclean JML Sprite_Peabounceer_FirstFrameBounce
	;^Fixes a bug if the player holds jump, and on the
	; first frame the pea bouncer rises up from the
	; lowest point (and pushes the player up), enters
	; a pipe, causes mario to to fly upwards at the
	; other end of the pipe should that bouncer is
	; onscreen.

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

org $01CA3C
	autoclean JML Sprite_ChainedPlatform_pos

org $02EE77
	autoclean JML Sprite_SkullRaft_pos

org $0387F6
	autoclean JML Sprite_Megamole_pos

org $038CA7
	autoclean JML Sprite_CarrotLft_Pos

org $00DA6C
	autoclean JML Layer3TideDisablePush
freecode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FixHDMA:
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
GetOnYoshiExcept:
	LDA $7D				;\Restore speed check in order to get on yoshi.
	BMI .NoYoshi			;/
	LDA !Freeram_SSP_PipeDir	;\if in pipe mode, don't get on yoshi while entering.
	AND.b #%00001111		;/
	BNE .NoYoshi
	JML $01ED48		;>Get on yoshi

	.NoYoshi
	JML $01ED70		;>Don't get on yoshi.

;---------------------------------------------------------------------------------
BlockedFix:
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
Sprite_Springboard_CancelLaunch:         ;>$01E650
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
Sprite_springboard_Pos:         ;>$01E666

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
Sprite_Springboard_ImageFix:     ;>$01E6F0
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
Sprite_Key_pos:                 ;>$01AAD8
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $01AAF1

	.Restore
	LDA #$1F
	LDY $187A|!addr
	JML $01AADD
;---------------------------------------------------------------------------------
Sprite_TurnBlockHV_pos:         ;>$01B882
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $01B8B1

	.Restore
	LDA $0D
	CLC
	ADC #$1F
	JML $01B887
;---------------------------------------------------------------------------------
Sprite_Peabounceer_FirstFrameBounce:           ;>$02CDD5
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
Sprite_Peabouncer_pos:          ;>$02CFA5
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
Sprite_InvisibleBlock_pos:         ;>$01B47F
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $01B4B1

	.Restore
	LDA #$1F
	LDY $187A|!addr
	JML $01B484
;---------------------------------------------------------------------------------
Sprite_ChainedPlatform_pos:        ;>$01CA3C
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $01CA6E

	.Restore
	LDA #$28
	LDY $187A|!addr
	JML $01CA41
;---------------------------------------------------------------------------------
Sprite_SkullRaft_pos:              ;>$02EE77
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $02EEA8

	.Restore
	LDA #$1C
	LDY $187A|!addr
	JML $02EE7C
;---------------------------------------------------------------------------------
Sprite_Megamole_pos:               ;>$0387F6
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $03881D

	.Restore
	LDA #$D6
	LDY $187A|!addr
	JML $0387FB
;---------------------------------------------------------------------------------
Sprite_CarrotLft_Pos:              ;>$038CA7
	LDA !Freeram_SSP_PipeDir
	AND.b #%00001111
	BEQ .Restore

	JML $038CE3

	.Restore
	LDA $187A|!addr
	CMP #$01
	JML $038CAC
;---------------------------------------------------------------------------------
Layer3TideDisablePush:             ;>$00DA6C
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