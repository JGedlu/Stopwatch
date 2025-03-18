@ Registers Used:
@ R0 - Stores GPIO pin number (used for initialization and shifting for display)
@ R1 - Holds result from GPIO read (0 = not pressed, 1 = pressed)
@ R2 - General purpose counter for loops and delays
@ R3 - General purpose register for shifting/masking and delays
@ R4 - Pause state (0 = running, 1 = paused)
@ R5 - Binary pattern of the current digit
@ R6 - Temporary register used for GPIO operations
@ R7 - Temporary register used for GPIO reads

@ GPIO Pins:
@ GPIO 16 - Segment G
@ GPIO 17 - Segment F
@ GPIO 18 - Segment A
@ GPIO 19 - Segment B
@ GPIO 20 - Segment C
@ GPIO 21 - Segment D
@ GPIO 22 - Segment E
@ GPIO 23 - Button Input (pauses/resumes the counter)

#include "hardware/regs/addressmap.h"
#include "hardware/regs/sio.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/pads_bank0.h"

.equ BUTTON_PIN, 23

.thumb_func
.global main

.align 4
main:
    @ Pin initialization for all pins corresponding to the pins for the seven segment display
    MOV R0, #16 @pin G
    BL gpioinit
    MOV R0, #17 @pin F
    BL gpioinit
    MOV R0, #18 @pin A
    BL gpioinit
    MOV R0, #19 @pin B
    BL gpioinit
    MOV R0, #20 @pin C
    BL gpioinit
    MOV R0, #21 @pin D
    BL gpioinit
    MOV R0, #22 @pin E
    BL gpioinit

    MOV R0, #23
    
    MOV R4, #0
    MOV R0, #16

    loop:
        MOV R5, #0b0111111 @ loading data for the digit zero into register 5
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b0001100 @ loading data for the digit one into register 5
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1011011 @ loading data for the digit two into register 5
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1011110 @ loading data for the digit three into register 5
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1101100 @ loading data for the digit four into register 5
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1110110 @ loading data for the digit five into register 5
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1110111 @ loading data for the digit six into register 5
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b0011100 @ loading data for the digit seven into register 5
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1111111 @ loading data for the digit eight into register 5
        BL gpio_on
        BL delay
        BL gpio_off

        MOV R5, #0b1111100 @ loading data for the digit nine into register 5
        BL gpio_on
        BL delay
        BL gpio_off

        B loop

gpioinit:
    MOV R3, #1
    LSL R3, R0
    LDR R2, gpiobase
    STR R3, [R2, #SIO_GPIO_OE_SET_OFFSET]
    STR R3, [R2, #SIO_GPIO_OUT_CLR_OFFSET]
    LDR R2, padsbank0
    LSL R3, R0, #2
    ADD R2, R3
    MOV R1, #PADS_BANK0_GPIO0_IE_BITS
    LDR R4, setoffset
    ORR R2, R4
    STR R1, [R2, #PADS_BANK0_GPIO0_OFFSET]
    LSL R0, #3
    LDR R2, iobank0
    ADD R2, R0
    MOV R1, #IO_BANK0_GPIO3_CTRL_FUNCSEL_VALUE_SIO_3
    STR R1, [R2, #IO_BANK0_GPIO0_CTRL_OFFSET]
    BX LR

gpio_on:
    MOV R3, R5
    LSL R3, R0
    LDR R2, gpiobase
    STR R3, [R2, #SIO_GPIO_OUT_SET_OFFSET]
    BX LR

gpio_off:
    MOV R3, #0b1111111
    LSL R3, R0
    LDR R2, gpiobase
    STR R3, [R2, #SIO_GPIO_OUT_CLR_OFFSET]
    BX LR

delay:
    MOV R2, #0
    MOV R3, #0x23             @ Load base value (ADJUST FOR SPEED?)
    LSL R3, R3, #18          @ 0x1 << 18 = 0x40000 (~1M loops)

indelay:
    ADD R2, #1

    @ read GPIO
    LDR R6, gpiobase
    LDR R7, [R6, #SIO_GPIO_IN_OFFSET]
    LSR R7, R7, #BUTTON_PIN
    MOV R6, #1
    AND R7, R6
    MOV R1, R7

    @ Handles pause after loop completion
    CMP R1, #1
    BEQ handle_pause_check

    CMP R4, #1               @ Checks if paused
    BEQ delay_exit

    CMP R2, R3
    BCC indelay

delay_exit:
    BX LR

handle_pause_check:
    @ Ensures button is stable before toggling
    PUSH {R2, R3}

wait_release:
    LDR R6, gpiobase
    LDR R7, [R6, #SIO_GPIO_IN_OFFSET]
    LSR R7, R7, #BUTTON_PIN
    MOV R6, #1
    AND R7, R6
    CMP R7, #1
    BEQ wait_release
    MOV R2, #0
    MOV R3, #0xFF
debounce_delay:
    ADD R2, #1
    CMP R2, R3
    BCC debounce_delay
    CMP R4, #0
    BEQ set_paused
    B set_running

set_paused:
    MOV R4, #1                  @ Set pause state to 1 (paused)
    B restore_state

set_running:
    MOV R4, #0                  @ Set pause state to 0 (running)
    B restore_state

restore_state:
    POP {R2, R3}
    B delay_exit

.align 4
    gpiobase: .word SIO_BASE
    iobank0: .word IO_BANK0_BASE
    padsbank0: .word PADS_BANK0_BASE
    setoffset: .word REG_ALIAS_SET_BITS
