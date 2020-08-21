incsrc "../SSPDef/Defines.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Drag mario mode handler.
;;
;;When hitting [DragToDestination.asm], it will execute this
;;code to set the player's destination position.
;;
;;Each warp to a specific point is each index ID.
;;
;;Output:
;;-Carry: Set if no warp index found.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	PHB							;>Preserve bank
	PHK							;\Adjust bank for any $xxxx,y
	PLB							;/
	REP #$30
	LDX.w #(?LevelNumberTable_End-?LevelNumberTable)-2
	LDY.w #((?LevelNumberTable_End-?LevelNumberTable)/2)-1
	?.Loop
		;Find if current level matches
			LDA $010B|!addr
			CMP ?LevelNumberTable,x
			BNE ?.Next
		;Level matched, now the XY start position
			;Is Xposition matched?
				REP #$20
				LDA $9A
				LSR #4			;>Convert pixel coordinates to 16x16 block coordinate
				CMP ?StartPositionX,x
				SEP #$20
				BNE ?.Next
			;What about Y?
				REP #$20
				LDA $98
				LSR #4			;>Convert pixel coordinates to 16x16 block coordinate
				CMP ?StartPositionY,x
				SEP #$20
				BNE ?.Next
		;Now obtain the destination XY pos and direction from there
			;But first, get the relative position between player and the block he hits the start point
			;so that his half-block offset traveling through regular-sized vertical pipes applies at the
			;destination.
				;X position offset from block
					REP #$20
					LDA $9A
					AND #$FFF0
					STA $00
					LDA $94
					SEC
					SBC $00
					STA $00
				;Y position offset from block
					LDA $98
					AND #$FFF0
					STA $02
					LDA $96
					SEC
					SBC $02
					STA $02
			;Now take the destination position, offset it, and then write it to
			;!Freeram_SSP_DragWarpPipeDestinationXPos and !Freeram_SSP_DragWarpPipeDestinationYPos
			
			;And finally the direction
			
			;Done.
				BRA ?Done
	?.Next
		DEY
		DEX #2
		BPL ?.Loop
		SEC
		BRA ?Done
	
	
	
	?Done
		SEP #$30
		PLB
		RTL











;Level the start wrap points are in.
	?LevelNumberTable
		dw $0105		;>Index 0 (Index 0 * 2)
		dw $0105		;>Index 2 (Index 1 * 2)
		?.End

;These is the current block position (block coordinates, in units of 16x16, not pixels)
;needed to determine which destination to drag Mario to.
	?StartPositionX
		dw $0005		;>Index 0 (Index 0 * 2)
		dw $000C		;>Index 2 (Index 1 * 2)
	?StartPositionY
		dw $0018		;>Index 0 (Index 0 * 2)
		dw $0010		;>Index 2 (Index 1 * 2)
;These are the destination (relative to (or offset from) start position). Numbers here are 2-complement signed.
	?EndPositionX
		dw $000C		;>Index 0 (Index 0 * 2)
		dw $0005		;>Index 2 (Index 1 * 2)
	?EndPositionY
		dw $000F		;>Index 0 (Index 0 * 2)
		dw $0017		;>Index 2 (Index 1 * 2)
;This is the prep direction to set to that the player will start moving in that direction
;upon reaching his destination.
;Only use these values
;-$00 = Revert to normal mode (“exit” the pipe with no animation nor sound)
;-$10 = up
;-$20 = right
;-$30 = down
;-$40 = left
	?DestinationDirection
		db $10			;>Index 0
		db $10			;>Index 1