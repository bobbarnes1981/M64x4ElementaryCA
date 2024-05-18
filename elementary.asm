
; *********************************************************************************************
; Elementary Cellular Automata (1 Dimensional CA)
; *********************************************************************************************

; *********************************************************************************************
; TODO:
;       > initialise first row with pattern (RRB/LRB seem to both shift not rotate)
;       > clean up code
;       > add comments
;       > maybe just use single pixels if we can not use ram to store cell state
; *********************************************************************************************

; *********************************************************************************************
; Start
; *********************************************************************************************

                #org 0x2000

                MIW 0x0190, screen_w                            ; 0x0190 (400)
                MIB 0xf0, screen_h                              ; 0xf0 (240)

                MIB 0x05, cell_size                             ; cell size is 5 pixels 80x48
                MIB 0x51, row_length                            ; 0x51 (81) one row and one cell back

                ; doesn't work
                ;MIB 0x04, cell_size                             ; cell size is 4 pixels 100x60
                ;MIB 0x65, row_length                            ; 0x65 (101) one row and one cell back

                ; doesn't work
                ;MIB 0x02, cell_size                             ; cell size is 4 pixels 100x60
                ;MIB 0xc9, row_length                            ; 0xc9 (201) one row and one cell back

                ; Rule 18 (0x12)
                ;  7   6   5   4   3   2   1   0 
                ; 111 110 101 100 011 010 001 000
                ;  0   0   0   1   0   0   1   0 
                MIB 0x12, rule                                  ;

                MIW 0x1100, cell_pointer

                JAS _Clear

                MIB 0x00, _XPos
                MIB 0x00, _YPos

                MIB 0x00, grid_current_y

                MIW 0x0000, grid_current_x

                ; hard coded pattern
                ;JAS initrow

                ; random pattern
                JAS initrowrnd

                ; pattern defined in byte
                ;MIB 0xaa, pattern
                ;JAS initrowpattern

                ABB cell_size, grid_current_y

loopy:
                MIW 0x0000, grid_current_x
                JAS processrow
                ABB cell_size, grid_current_y
                CBB screen_h, grid_current_y
                BNE loopy
                
                JPA _Prompt


; *********************************************************************************************
; fill cell and clear cell subroutines
; *********************************************************************************************

fill_cell:      MWV grid_current_x, xa                          ; copy x to pixel x
                CLZ xc                                          ; reset x counter
fill_loop_x:    MBZ grid_current_y, ya                          ; copy y to pixel y
                CLZ yc                                          ; reset y counter
fill_loop_y:    JPS _SetPixel                                   ; set pixel
                MIR 0x01, cell_pointer
                JPA fill_loop_end                               ; jump to end of loop
fill_loop_end:  INZ yc                                          ; increment y counter
                INZ ya                                          ; increment y pixel
                CBZ cell_size, yc                               ; check if reached cell_size
                BNE fill_loop_y                                 ; continue loop
                INZ xc                                          ; increment x counter
                INV xa                                          ; increment x pixel
                CBZ cell_size, xc                               ; check if reached cell_size
                BNE fill_loop_x                                 ; continue loop
fill_done:      RTS                                             ; return

clr_cell:       MWV grid_current_x, xa                          ; copy x to pixel x
                CLZ xc                                          ; reset x counter
clr_loop_x:     MBZ grid_current_y, ya                          ; copy y to pixel y
                CLZ yc                                          ; reset y counter
clr_loop_y:     JPS _ClearPixel                                 ; clear pixel
                MIR 0x00, cell_pointer
                JPA clr_loop_end                                ; jump to end of loop
clr_loop_end:   INZ yc                                          ; increment y counter
                INZ ya                                          ; increment y pixel
                CBZ cell_size, yc                               ; check if reached cell_size
                BNE clr_loop_y                                  ; continue loop
                INZ xc                                          ; increment x counter
                INV xa                                          ; increment x pixel
                CBZ cell_size, xc                               ; check if reached cell_size
                BNE clr_loop_x                                  ; continue loop
clr_done:       RTS                                             ; return

; *********************************************************************************************
; Init first row 10010
; *********************************************************************************************

initrow:
                JAS fill_cell
                INW cell_pointer
                ABW cell_size, grid_current_x

                JAS clr_cell
                INW cell_pointer
                ABW cell_size, grid_current_x

                JAS clr_cell
                INW cell_pointer
                ABW cell_size, grid_current_x

                JAS fill_cell
                INW cell_pointer
                ABW cell_size, grid_current_x

                JAS clr_cell
                INW cell_pointer
                ABW cell_size, grid_current_x

                CBB screen_w+1, grid_current_x+1
                BNE initrow
                CBB screen_w, grid_current_x
                BNE initrow

                RTS

; *********************************************************************************************
; Init first row random
; *********************************************************************************************

initrowrnd:
                JAS _Random
                CPI 0x80 ; 50/50
                BGT frrnd_set
                JAS clr_cell
                JPA frrnd_inc
frrnd_set:      JAS fill_cell
frrnd_inc:      INW cell_pointer
                ABW cell_size, grid_current_x
                CBB screen_w+1, grid_current_x+1
                BNE initrowrnd
                CBB screen_w, grid_current_x
                BNE initrowrnd
                RTS

; *********************************************************************************************
; Init first row pattern - need to figure out rotate opcode
; *********************************************************************************************

initrowpattern:
                LDI 0x01
                ANB pattern
                CPI 0x00
                BEQ frpat_set
                JAS clr_cell
                JPA frpat_inc
frpat_set:      JAS fill_cell
frpat_inc:      INW cell_pointer

                LDB pattern
                RRB pattern

                ABW cell_size, grid_current_x
                CBB screen_w+1, grid_current_x+1
                BNE initrowpattern
                CBB screen_w, grid_current_x
                BNE initrowpattern
                RTS

; *********************************************************************************************
; Process row
; *********************************************************************************************

processrow:
                MIB 0x00, prev_counter                          ; stores the number representing the state of the neighbours

                MBB cell_pointer+1, prev_pointer+1              ; check the neighbours on the row above
                MBB cell_pointer, prev_pointer
                SBW row_length, prev_pointer

nebleft:
                ; skip step one if we are at start of row as the left neighbour would always be zero
                CIB 0x00, grid_current_x+1
                BNE do_nebleft
                CIB 0x00, grid_current_x
                BNE do_nebleft
                JPA neb_prev
                ; check left neighbour
do_nebleft:     LDI 0x00
                CPR prev_pointer
                BEQ neb_prev
                AIB 0x04, prev_counter

neb_prev:
                ; check previous state
                INW prev_pointer
                LDI 0x00
                CPR prev_pointer
                BEQ nebright
                AIB 0x02, prev_counter

nebright:
                ; skip step 3 if we are at the end of row as the right neighbour would always be zero
                CBB screen_w+1, grid_current_x+1
                BNE do_nebright
                CBB screen_w, grid_current_x
                BNE do_nebright
                JPA neb_done
                ; check right neighbour
do_nebright:    INW prev_pointer
                LDI 0x00
                CPR prev_pointer
                BEQ neb_done
                AIB 0x01, prev_counter
neb_done:

                MIB 0x08, prev_comparison                       ; value to compare to the prev_counter to check which neighbour state
                MIB 0x80, rule_comparison                       ; bit mask to compare which state the cell should move to

checkloop:
                DEB prev_comparison
                CBB prev_comparison, prev_counter
                BNE cellcheck

                LDB rule
                ANB rule_comparison
                CPI 0x00
                BEQ clr
                JAS fill_cell
                JPA celldone
clr:            JAS clr_cell
                JPA celldone

cellcheck:      LRB rule_comparison                             ; shift right
                LDB rule_comparison                             ; load to 'A'
                CPI 0x00                                        ; compare to zero
                BNE checkloop                                   ; loop if not zero

celldone:       INW cell_pointer
                ABW cell_size, grid_current_x
                CBB screen_w+1, grid_current_x+1
                BNE processrow
                CBB screen_w, grid_current_x
                BNE processrow

                RTS

; *********************************************************************************************
; Data
; *********************************************************************************************

#mute

#org 0x0000

xc:                 0xff                                        ;
yc:                 0xff                                        ;

#org 0x1000

cell_size:          0xff                                        ;
row_length:         0xff                                        ;
screen_w:           0xffff                                      ;
screen_h:           0xff                                        ;

grid_current_x:     0xffff                                      ;
grid_current_y:     0xff                                        ;

cell_pointer:       0xffff                                      ;
prev_pointer:       0xffff                                      ;
prev_counter:       0xff                                        ;
pattern:            0xff                                        ;
rule:               0xff                                        ;
prev_comparison:    0xff                                        ;
rule_comparison:    0xff                                        ;

#org 0x1100     cells:   ;80x48 cells

; zero-page graphics interface (OS_SetPixel, OS_ClearPixel, OS_Line, OS_Rect)

#org 0x0080     xa: steps: 0xffff
                ya:        0xff
                xb:        0xffff
                yb:        0xff
                dx:        0xffff
                dy:        0xff
                bit:       0xff
                err:       0xffff

; API Function

#org 0xf000 _Start:                     ; Start vector of the OS in RAM
#org 0xf003 _Prompt:                    ; Hands back control to the input prompt
#org 0xf006 _MemMove:                   ; Moves memory area (may be overlapping)
#org 0xf009 _Random:                    ; Returns a pseudo-random byte (see _RandomState)
#org 0xf00c _ScanPS2:                   ; Scans the PS/2 register for new input
#org 0xf00f _ResetPS2:                  ; Resets the state of PS/2 SHIFT, ALTGR, CTRL
#org 0xf012 _ReadInput:                 ; Reads any input (PS/2 or serial)
#org 0xf015 _WaitInput:                 ; Waits for any input (PS/2 or serial)
#org 0xf018 _ReadLine:                  ; Reads a command line into _ReadBuffer
#org 0xf01b _SkipSpace:                 ; Skips whitespaces (<= 39) in command line
#org 0xf01e _ReadHex:                   ; Parses command line input for a HEX value
#org 0xf021 _SerialWait:                ; Waits for a UART transmission to complete
#org 0xf024 _SerialPrint:               ; Transmits a zero-terminated string via UART
#org 0xf027 _FindFile:                  ; Searches for file <name> given by _ReadPtr
#org 0xf02a _LoadFile:                  ; Loads a file <name> given by _ReadPtr
#org 0xf02d _SaveFile:                  ; Saves data to file <name> defined at _ReadPtr
#org 0xf030 _ClearVRAM:                 ; Clears the video RAM including blanking areas
#org 0xf033 _Clear:                     ; Clears the visible video RAM (viewport)
#org 0xf036 _ClearRow:                  ; Clears the current row from cursor pos onwards
#org 0xf039 _ScrollUp:                  ; Scrolls up the viewport by 8 pixels
#org 0xf03c _ScrollDn:                  ; Scrolls down the viewport by 8 pixels
#org 0xf03f _Char:                      ; Outputs a char at the cursor pos (non-advancing)
#org 0xf042 _PrintChar:                 ; Prints a char at the cursor pos (advancing)
#org 0xf045 _Print:                     ; Prints a zero-terminated immediate string
#org 0xf048 _PrintPtr:                  ; Prints a zero-terminated string at an address
#org 0xf04b _PrintHex:                  ; Prints a HEX number (advancing)
#org 0xf04e _SetPixel:                  ; Sets a pixel at position (x, y)
#org 0xf051 _Line:                      ; Draws a line using Bresenham's algorithm
#org 0xf054 _Rect:                      ; Draws a rectangle at (x, y) of size (w, h)
#org 0xf057 _ClearPixel:                ; Clears a pixel at position (x, y)

; API Data

#org 0x00c0 _XPos:                      ; 1 byte: Horizontal cursor position (see _Print)
#org 0x00c1 _YPos:                      ; 1 byte: Vertical cursor position (see _Print)
#org 0x00c2 _RandomState:               ; 4 bytes: _Random state seed
#org 0x00c6 _ReadNum:                   ; 3 bytes: Number parsed by _ReadHex
#org 0x00c9 _ReadPtr:                   ; 2 bytes: Command line parsing pointer
#org 0x00cb                             ; 2 bytes: unused
#org 0x00cd _ReadBuffer:                ; 2 bytes: Address of command line input buffer
