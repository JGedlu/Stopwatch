#include "hardware/regs/addressmap.h"
#include "hardware/regs/sio.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/pads_bank0.h"

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

.thumb_func
.global main
.align 4

main:
    @ Initialize seven-segment display pins
    MOV R0, #16 @ Pin G
    BL gpioinit
    MOV R0, #17 @ Pin F
    BL gpioinit
    MOV R0, #18 @ Pin A
    BL gpioinit
    MOV R0, #19 @ Pin B
    BL gpioinit
    MOV R0, #20 @ Pin C
    BL gpioinit
    MOV R0, #21 @ Pin D
    BL gpioinit
    MOV R0, #22 @ Pin E
    BL gpioinit

    @ Initialize button input on pin 15
    MOV R0, #15
    BL gpioinit_input

    loop:
        @ Read button state
        BL read_button
        CMP R4, #1         @ Check if button is pressed
        BEQ skip_update    @ Skip number update if pressed

        @ Normal number cycling
        MOV R5, #0b0111111
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b0001100
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1011011
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1011110
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1101100
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1110110
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1110111
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b0011100
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1111111
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1111100
        BL gpio_on
        BL delay
        BL gpio_off

skip_update:
    B loop

gpioinit:
    @ Initialize GPIO pin for output
    MOV R3, #1
    LSL R3, R0
    LDR R2, gpiobase
    STR R3, [R2, #SIO_GPIO_OE_SET_OFFSET]
    STR R3, [R2, #SIO_GPIO_OUT_CLR_OFFSET]
    @ Enable I/O for the pin
    LDR R2, padsbank0
    LSL R3, R0, #2
    ADD R2, R3
    MOV R1, #PADS_BANK0_GPIO0_IE_BITS
    LDR R4, setoffset
    ORR R2, R4
    STR R1, [R2, #PADS_BANK0_GPIO0_OFFSET]
    @ Set function to SIO
    LSL R0, #3
    LDR R2, iobank0
    ADD R2, R0
    MOV R1, #IO_BANK0_GPIO3_CTRL_FUNCSEL_VALUE_SIO_3
    STR R1, [R2, #IO_BANK0_GPIO0_CTRL_OFFSET]
    BX LR

gpioinit_input:
    @ Initialize GPIO for input
    MOV R3, #1
    LSL R3, R0
    LDR R2, padsbank0
    LSL R3, R0, #2
    ADD R2, R3
    MOV R1, #PADS_BANK0_GPIO0_IE_BITS
    STR R1, [R2, #PADS_BANK0_GPIO0_OFFSET]
    BX LR

gpio_on:
    @ Turn on the corresponding seven-segment display segments
    MOV R3, R5
    LSL R3, R0
    LDR R2, gpiobase
    STR R3, [R2, #SIO_GPIO_OUT_SET_OFFSET]
    BX LR

gpio_off:
    @ Turn off all segments
    MOV R3, #0b1111111
    LSL R3, R0
    LDR R2, gpiobase
    STR R3, [R2, #SIO_GPIO_OUT_CLR_OFFSET]
    BX LR

read_button:
    LDR R2, gpiobase
    LDR R3, [R2, #SIO_GPIO_IN_OFFSET]  @ Read all GPIO inputs

    @ Shift right manually to check PIN 15 (adjust if using another pin)
    MOVS R4, #0          @ Clear R4
    MOVS R1, #15         @ Set counter for shifting

shift_loop:
    ASR R3, #1           @ Shift right by 1 bit
    SUB R1, #1          @ Decrement counter
    BNE shift_loop       @ Repeat until bit is isolated

    @ Perform manual AND with 1 (since Thumb-1 doesn't allow AND with immediate)
    MOVS R1, #1          @ Load mask value
    TST R3, R1           @ Test if bit is set
    BEQ clear_r4         @ If bit is 0, clear R4
    MOVS R4, #1          @ If bit is 1, set R4
    BX LR

clear_r4:
    MOVS R4, #0          @ Ensure R4 is cleared
    BX LR

delay:
    @ Simple delay loop
    MOV R2, #0
    MOV R3, #0xFF
    LSL R3, #17 @ Adjust delay length
    indelay:
    ADD R2, #1
    CMP R2, R3
    BCC indelay
    BX LR

.align 4
    gpiobase: .word SIO_BASE
    iobank0: .word IO_BANK0_BASE
    padsbank0: .word PADS_BANK0_BASE
    setoffset: .word REG_ALIAS_SET_BITS
