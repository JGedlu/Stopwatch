#include "hardware/regs/addressmap.h"
#include "hardware/regs/sio.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/pads_bank0.h"
@ Include for button

.thumb_func @ Tell the assembler which type of ARM
.global main @ Provide program starting address to linker
.align 4

@ Registers and Pins Used
@ R0 - Temporary storage for GPIO operations
@ R2 - Counter for delay function
@ R3 - Value for delay function (~1)
@ R4 - Stores button state (0-1)
@ R5 - Stores the stopwatch state (0-1)
@ R6 - Stores the stopwatch counter (0-9)
@ LR - Link Register
@ Pin 15 - Button State
@ Pins 16-22 - Seven-Segment Display

main:
    BL gpio_init_all       @ Initialize GPIO pins
    BL stopwatch_init      @ Initialize stopwatch

    loop:
        BL check_buttons       @ Check if button is pressed
        CMP R4, #1             @ If button pressed,
        BEQ toggle_state       @ Toggle stopwatch state
        CMP R5, #1             @ If stopwatch is running,
        BEQ run_stopwatch
        B loop

toggle_state:
    EOR R5, R5, #1         @ Toggle stopwatch state
    B loop

run_stopwatch:
    BL update_display      @ Update the display
    BL delay               @ Delay for 1 second
    ADD R6, #1             @ Increment display by one
    CMP R6, #9             @ If ones place reaches 9, reset to 0
    BNE loop
    MOV R6, #0             @ Reset display
    B loop

stopwatch_init:
    MOV R6, #0            @ Reset ones place counter
    MOV R5, #0            @ Stopwatch state (0 = paused, 1 = running)
    BX LR

gpio_init_all:            @ Initialize GPIO pins for seven-segment display (pins 16-22)
    MOV R0, #16
    BL gpio_init
    MOV R0, #17
    BL gpio_init
    MOV R0, #18
    BL gpio_init
    MOV R0, #19
    BL gpio_init
    MOV R0, #20
    BL gpio_init
    MOV R0, #21
    BL gpio_init
    MOV R0, #22
    BL gpio_init
    
    @ Initialize button (pin 15)
    MOV R0, #15
    BL gpio_init_input
    BX LR

update_display:
    MOV R5, R6            @ Load ones place digit
    BL display_digit
    BX LR

display_digit:
    CMP R5, #0
    BEQ digit_0
    CMP R5, #1
    BEQ digit_1
    CMP R5, #2
    BEQ digit_2
    CMP R5, #3
    BEQ digit_3
    CMP R5, #4
    BEQ digit_4
    CMP R5, #5
    BEQ digit_5
    CMP R5, #6
    BEQ digit_6
    CMP R5, #7
    BEQ digit_7
    CMP R5, #8
    BEQ digit_8
    CMP R5, #9
    BEQ digit_9
    BX LR  @ Return if out of range

digit_0:
    MOV R5, #0b0111111
    B display_digit_done

digit_1:
    MOV R5, #0b0001100
    B display_digit_done

digit_2:
    MOV R5, #0b1011011
    B display_digit_done

digit_3:
    MOV R5, #0b1011110
    B display_digit_done

digit_4:
    MOV R5, #0b1101100
    B display_digit_done

digit_5:
    MOV R5, #0b1110110
    B display_digit_done

digit_6:
    MOV R5, #0b1110111
    B display_digit_done

digit_7:
    MOV R5, #0b0011100
    B display_digit_done

digit_8:
    MOV R5, #0b1111111
    B display_digit_done

digit_9:
    MOV R5, #0b1111100

display_digit_done:
    BL gpio_on
    BX LR

check_buttons:
    @ Read button state (pin 15)
    @ If pressed, store 1 in R4, else store 0
    BX LR

delay:
    MOV R2, #0
    MOV R3, #0xFF
    LSL R3, #17            @ Approx. 1 second delay
    indelay:
    ADD R2, #1
    CMP R2, R3
    BCC indelay
    BX LR