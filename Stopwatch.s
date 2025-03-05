@ Registers Used:
@ R0 - Stores GPIO pin number       (used for initialization and reading input)
@ R1 - Holds result from read_gpio  (0 = not pressed, 1 = pressed)
@ R2 - Base address for SIO         (GPIO control)
@ R3 - Temporary register           (shifting and masking)
@ R4 - Stores pause state           (0 = running, 1 = paused)
@ R5 - Holds binary pattern of digit

@ GPIO Pins:
@ GPIO 16 - Segment G
@ GPIO 17 - Segment F
@ GPIO 18 - Segment A
@ GPIO 19 - Segment B
@ GPIO 20 - Segment C
@ GPIO 21 - Segment D
@ GPIO 22 - Segment E
@ GPIO 15 - Button Input            (Pauses the counter)

#include "hardware/regs/addressmap.h"
#include "hardware/regs/sio.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/pads_bank0.h"

.thumb_func         @ Tell the assembler which type of ARM
.global main        @ Provide program starting address to linker
.align 4

main:
    @ pin initialization for all pins corresponding to the pins for the seven segment display
    MOV R0, #16     @ Pin G
    BL gpioinit
    MOV R0, #17     @ Pin F
    BL gpioinit
    MOV R0, #18     @ Pin A
    BL gpioinit
    MOV R0, #19     @ Pin B
    BL gpioinit
    MOV R0, #20     @ Pin C
    BL gpioinit
    MOV R0, #21     @ Pin D
    BL gpioinit
    MOV R0, #22     @ Pin E
    BL gpioinit

    MOV R0, #16     @ correct number of left shifts for GPIO output
    MOV R4, #0      @ State variable to track pause (0 = running, 1 = paused)

@  0           1           2           3            4          5           6           7           8           9
@ #0b0111111, #0b0001100, #0b1011011, #0b0011110, #0b1101100, #0b1110110 ,#0b1110111, #0b0011100, #0b1111111, #0b1111100
@  GFABCDE

display_loop:
    MOV R5, #0b0111111          @ Loading data for digit 0
    BL show_digit
    MOV R5, #0b0001100          @ Digit 1
    BL show_digit
    MOV R5, #0b1011011          @ Digit 2
    BL show_digit
    MOV R5, #0b1011110          @ Digit 3
    BL show_digit
    MOV R5, #0b1101100          @ Digit 4
    BL show_digit
    MOV R5, #0b1110110          @ Digit 5
    BL show_digit
    MOV R5, #0b1110111          @ Digit 6
    BL show_digit
    MOV R5, #0b0011100          @ Digit 7
    BL show_digit
    MOV R5, #0b1111111          @ Digit 8
    BL show_digit
    MOV R5, #0b1111100          @ Digit 9
    BL show_digit
    B display_loop              @ Repeat

show_digit:
    BL gpio_on                  @ Display digit
    BL delay                    @ Wait
    BL gpio_off                 @ Clear display

pause_check:
    MOV R0, #15                 @ Assuming button is on GPIO 15
    BL read_gpio                @ Check button state
    CMP R1, #1                  @ Is the button pressed?
    BEQ pause_loop              @ Then, enter pause mode
    BX LR                       @ Otherwise, return to continue loop

pause_loop:
    BL read_gpio
    CMP R1, #1                  @ Still pressed?
    BEQ pause_loop              @ Stay in loop
    BX LR                       @ Otherwise, resume counting

gpioinit:
@ initialize the GPIO
        MOV R3, #1
        LSL R3, R0              @ Shift to pin position
        LDR R2, gpiobase
        STR R3, [R2, #SIO_GPIO_OE_SET_OFFSET]
        STR R3, [R2, #SIO_GPIO_OUT_CLR_OFFSET]
        @ enable I/O for the pin
        LDR R2, padsbank0
        LSL R3, R0, #2 @ pin * 4 for register address
        ADD R2, R3              @ Actual registers for the pin
        MOV R1, #PADS_BANK0_GPIO0_IE_BITS
        LDR R4, setoffset
        ORR R2, R4
        STR R1, [R2, #PADS_BANK0_GPIO0_OFFSET]
        @ set the function to SIO
        LSL R0, #3
        LDR R2, iobank0
        ADD R2, R0
        MOV R1, #IO_BANK0_GPIO3_CTRL_FUNCSEL_VALUE_SIO_3
        STR R1, [R2, #IO_BANK0_GPIO0_CTRL_OFFSET]
        BX LR

gpio_on:
        MOV R3, R5 @turns on pins specified in register 5
        LSL R3, R0
        LDR R2, gpiobase
        STR R3, [R2, #SIO_GPIO_OUT_SET_OFFSET]
        BX LR

gpio_off:
        MOV R3, #0b1111111      @ Turns all of the pins in the output off
        LSL R3, R0
        LDR R2, gpiobase
        STR R3, [R2, #SIO_GPIO_OUT_CLR_OFFSET]
        BX LR

.equ PIN, 15                    @ Define the button pin number
read_gpio:
    LDR R2, gpiobase                    @ Load base address of SIO
    LDR R3, [R2, #SIO_GPIO_IN_OFFSET]   @ Read GPIO input register
    LSR R3, R3, #PIN                    @ Shift right by 15 bits; now bit 15 is in bit 0
    MOV R1, R3                          @ Copy R3 into R1
    LSL R1, R1, #31                     @ Shift left by 31 bits: (moves bit0 to bit31)
    LSR R1, R1, #31                     @ Shift right by 31 bits: (isolates bit 0 in R1) (all other bits cleared)
    BX LR

delay:
    MOV R2, #0
    MOV R3, #0xFF
    LSL R3, #17                 @ Changes the end of the timer to 0xFF * 2^17 so it lasts longer (about a second)
    indelay:
    ADD R2, #1
    CMP R2, R3
    BCC indelay                 @ loop until R2 hits a value of 0 xFF
    BX LR

.align 4
    gpiobase: .word SIO_BASE
    iobank0: .word IO_BANK0_BASE
    padsbank0: .word PADS_BANK0_BASE
    setoffset: .word REG_ALIAS_SET_BITS
