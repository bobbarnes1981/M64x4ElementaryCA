; Elementary Cellular Automata (1 Dimensional CA)

; TODO:
;       maybe just use single pixels if we can not use ram to store cell state
;       allow specify rule in a memory location instead of hard coded
;       clean up code
;       add comments

                #org 0x2000

                MIW 0x0190, screen_w                            ; 0x0190 (400)
                MIB 0xf0, screen_h                              ; 0xf0 (240)

                MIB 0x05, cell_size                             ; cell size is 5 pixels 80x48

                MIW 0x1100, cell_pointer

                JAS _Clear

                MIB 0x00, _XPos
                MIB 0x00, _YPos

                MIB 0x00, grid_current_y

                MIW 0x0000, grid_current_x
                JAS initfirstrow
                ABB cell_size, grid_current_y

loopy:
                MIW 0x0000, grid_current_x
                JAS processrow
                ABB cell_size, grid_current_y
                CBB screen_h, grid_current_y
                BNE loopy

                JPA _Prompt

; *********************************************************************************

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

; *********************************************************************************

initfirstrow:
                JAS _Random
                CPI 0x80 ; 50/50
                BGT fr_set
                JAS clr_cell
                JPA fr_inc
fr_set:         JAS fill_cell
fr_inc:         INW cell_pointer
                ABW cell_size, grid_current_x
                CBB screen_w+1, grid_current_x+1
                BNE initfirstrow
                CBB screen_w, grid_current_x
                BNE initfirstrow
                RTS

; *********************************************************************************

processrow:
                MIB 0x00, prev_counter

                ; 0x51 (81) one row and one cell back
                MBB cell_pointer+1, prev_pointer+1
                MBB cell_pointer, prev_pointer
                SIW 0x51, prev_pointer

step1:
                ; skip step one if we are at start of row
                CIB 0x00, grid_current_x+1
                BNE dostep1
                CIB 0x00, grid_current_x
                BNE dostep1
                JPA step2

dostep1:        LDI 0x00
                CPR prev_pointer
                BEQ step2
                AIB 0x04, prev_counter

step2:
                INW prev_pointer
                LDI 0x00
                CPR prev_pointer
                BEQ step3
                AIB 0x02, prev_counter

step3:
                ; skip step 3 if we are at the end of row
                CIB 0x01, grid_current_x
                BNE dostep3
                CIB 0x90, grid_current_x
                BNE dostep3
                JPA step4

dostep3:        INW prev_pointer
                LDI 0x00
                CPR prev_pointer
                BEQ step4
                AIB 0x01, prev_counter
step4:

; Hard code RULE 18 for testing
;  7   6   5   4   3   2   1   0 
; 111 110 101 100 011 010 001 000
;  0   0   0   1   0   0   1   0 

check7:
                CIB 0x07, prev_counter
                BNE check6
                JAS clr_cell
                JPA celldone
check6:
                CIB 0x06, prev_counter
                BNE check5
                JAS clr_cell
                JPA celldone
check5:
                CIB 0x05, prev_counter
                BNE check4
                JAS clr_cell
                JPA celldone
check4:
                CIB 0x04, prev_counter
                BNE check3
                JAS fill_cell
                JPA celldone
check3:
                CIB 0x03, prev_counter
                BNE check2
                JAS clr_cell
                JPA celldone
check2:
                CIB 0x02, prev_counter
                BNE check1
                JAS clr_cell
                JPA celldone
check1:
                CIB 0x01, prev_counter
                BNE check0
                JAS fill_cell
                JPA celldone
check0:
                CIB 0x00, prev_counter
                BNE celldone
                JAS clr_cell
                JPA celldone
celldone:

                INW cell_pointer
                ABW cell_size, grid_current_x
                CBB screen_w+1, grid_current_x+1
                BNE processrow
                CBB screen_w, grid_current_x
                BNE processrow

                RTS

; *********************************************************************************

#mute

#org 0x0000

xc:             0xff                                            ;
yc:             0xff                                            ;

#org 0x1000

cell_size:      0xff                                            ;
screen_w:       0xffff                                          ;
screen_h:       0xff                                            ;

grid_current_x: 0xffff                                          ;
grid_current_y: 0xff                                            ;

cell_pointer:   0xffff                                          ;
prev_pointer:   0xffff                                          ;
prev_counter:   0xff                                            ;

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
