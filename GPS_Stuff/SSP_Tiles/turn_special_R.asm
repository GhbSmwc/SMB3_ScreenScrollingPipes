;A turn corner that changes the direction the player is going
;based on the "prepare corner direction blocks".
;Behaves $25 or $130

incsrc "../../SSPDef/Defines.asm"

db $42
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside

MarioBelow:
MarioAbove:
MarioSide:
TopCorner:
BodyInside:
HeadInside:
	;Check pipe state
		LDA !Freeram_SSP_PipeDir	;\If not in pipe mode, Return as being a solid block
		AND.b #%00001111		;|
		BEQ Return			;/
	;Render passable
		LDY #$00			;\Become passable when in pipe.
		LDX #$25			;|
		STX $1693|!addr			;/
	;Check if the block should be merely passable.
		CMP #$09			;\If traveling in any direction, do nothing except be passable.
		BCS Return			;/
	;Adjust player pipe travel direction and centering
		JSR DistanceFromTurnCornerCheck
		BCC Return
	
	;Going straight check
	LDA !Freeram_SSP_PipeDir
	CMP #$11				;\%00010001 if player is going up when set to go up
	BEQ Return				;/
	CMP #$22				;\%00100010 same as above but rightwards, the following are similar
	BEQ Return				;/
	CMP #$33				;\%00110011 downwards
	BEQ Return				;/
	CMP #$44				;\%01000100 leftwards
	BEQ Return				;/
	CMP #$15				;\Same as above, but when comparing cap speeds.
	BEQ Return				;|
	CMP #$26				;|
	BEQ Return				;|
	CMP #$37				;|
	BEQ Return				;|
	CMP #$48				;|
	BEQ Return				;/
	AND.b #%11110000			;\%00000000 if set not to change direction
	BEQ Return				;/
	
	JSR PastCornerDetection
	BCC Return
	JSR CenterAlignment
	
	;Transfer high nibble to low nibble
	LDA !Freeram_SSP_PipeDir
	LSR #4
	STA $00
	LDA !Freeram_SSP_PipeDir
	AND.b #%11110000
	ORA $00
	STA !Freeram_SSP_PipeDir
SpriteV:
SpriteH:
MarioCape:
MarioFireball:
Return:
	RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	DistanceFromTurnCornerCheck:
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
	LDA $94				;\Get X position (due to some positioning lag a frame behind, this is 2 pixels to the right from center)
	CLC				;|
	ADC #$000A			;|
	AND #$FFF0			;|
	STA $00				;/
	LDA $96				;\Get Y position
	CLC				;|
	ADC FootDistanceYpos,x		;|
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
	RTS
	+
	CLC
	SEP #$20
	RTS
	FootDistanceYpos:
	dw $0018, $0028, $0028

	CenterAlignment:
;	LDA $187A|!addr		;\Yoshi Y positioning
;	ASL			;|
;	TAX			;/
	REP #$20		;
	LDA $98			;\Center the player vertically
	AND #$FFF0		;|
	SEC			;|
	SBC VerticalAlignment,x	;|
	STA $96			;/
	LDA $9A			;\Center the player horizontally
	AND #$FFF0		;|
	SEC			;|
	SBC #$0008		;|
	STA $94			;/
	SEP #$20
	RTS
	
	VerticalAlignment:
	dw $0011, $0021, $0021

	PastCornerDetection:
	;Snap player to center when going past in a specified direction
	;(this enables smooth change of direction)
	;
	;Carry set if the player goes at or past the position he should change direction,
	;clear if the player doesn't go far into the corner enough.
;	LDA $187A|!addr				;\Yoshi vertical positioning check index
;	ASL					;|
;	TAX					;/
	LDA !Freeram_SSP_PipeDir		;\Check current direction and not the planned
	AND.b #%00001111			;/
	CMP #$05				;\Merge corresponding directions into one
	BCC +					;|(i.g: directions 1 and 5 (both upwards) treated the same)
	SEC					;|
	SBC #$04				;/
	+
	CMP #$01				;\Determine what position the player has to be in relation to his direction
	BEQ Upwards				;|(for example, going upwards will check if mario's Y position is at a certain height)
	CMP #$02				;|
	BEQ Rightwards				;|
	CMP #$03				;|
	BEQ Downwards				;|
	CMP #$04				;|
	BEQ Leftwards				;/
	CLC					;>failsafe protection
	RTS
	
	Upwards:
	REP #$20			;\Only snap the player should the player's feet or yoshi touches the bottom of the turning left part.
	LDA $98				;|
	AND #$FFF0			;|
	SEC				;|
	SBC YoshiPositioningUpwards,x	;|
	CMP $96				;|
	SEP #$20			;|
	BPL +				;|
	CLC				;|
	RTS				;/
	+
	SEC
	RTS
	
	YoshiPositioningUpwards:
	dw $0010,$0020,$0020
	
	Rightwards:
	REP #$20		;\Don't center and change direction until the player is centered close enough (about to go past it).
	LDA $9A			;|
	AND #$FFF0		;|
	SEC			;|
	SBC #$0008		;|
	CMP $94			;|
	SEP #$20		;|
	BMI +			;|
	CLC			;|
	RTS			;/
	+
	SEC
	RTS
	
	Downwards:
	REP #$20			;\Only snap the player should the player's feet or yoshi touches the bottom of the turning left part.
	LDA $98				;|
	AND #$FFF0			;|
	SEC				;|
	SBC YoshiPositioningDownwards,x	;|
	CMP $96				;|
	SEP #$20			;|
	BMI +				;|
	CLC				;|
	RTS				;/
	+
	SEC
	RTS
	
	YoshiPositioningDownwards:
	dw $0010,$0028,$0028
	;^You might've noticed that this is different compared to all other turn pipes.
	; this is because there is a problem with yoshi's collision points when big
	; mario is on yoshi traveling downwards on this block when there is a solid
	; platform below it to not  trigger this block (which causes the player to get
	; stuck trying to head downwards before turning).
	
	Leftwards:
	REP #$20		;\Don't center and change direction until the player is centered close enough (about to go past it).
	LDA $9A			;|
	AND #$FFF0		;|
	SEC			;|
	SBC #$0008		;|
	CMP $94			;|
	SEP #$20		;|
	BPL +			;|
	CLC			;|
	RTS			;/
	+
	SEC
	RTS
if !Setting_SSP_Description != 0
print "The bottom-right of a 32x32 intersection of a special turn."
endif