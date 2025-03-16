@ Registers Used:
@ R0 - Stores GPIO pin number (used for initialization and shifting for display)
@ R1 - Holds result from read_gpio (0 = not pressed, 1 = pressed)
@ R2 - Used for base address (SIO) and as a counter in delays
@ R3 - Temporary register (used for shifting/masking and in delays)
@ R4 - Used for pause state (0 = running, 1 = paused)
@ R5 - Holds binary pattern of the current digit
@ R7 - Throwaway register used to AND in read_gpio

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

.equ BUTTON_PIN, 23      @ Define the button pin number

.thumb_func @ Tell the assembler which type of ARM
.global main @ Provide program starting address to linker

.align 4
main:
    @ pin initialization for all pins corresponding to the pins for the seven segment display
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

    @ Initialize button pin (GPIO 23) as input
    MOV R0, #23
    
    MOV R4, #0           @ Initialize pause state to 0 (running)
    MOV R0, #16 @correct number of left shifts to get input into the corresponding gpio output

    loop:
        MOV R5, #0b0111111 @ loading data for the digit zero into register 5
        BL gpio_on @ uses the data in register 5 to stream the corresponding output in gpio
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

gpioinit:       @ initialize the GPIO
    MOV R3, #1
    LSL R3, R0 @ shift to pin position
    LDR R2, gpiobase
    STR R3, [R2, #SIO_GPIO_OE_SET_OFFSET]
    STR R3, [R2, #SIO_GPIO_OUT_CLR_OFFSET]
    @ enable I/O for the pin
    LDR R2, padsbank0
    LSL R3, R0, #2 @ pin * 4 for register address
    ADD R2, R3 @ actual registers for the pin
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
    BX LR @ return to caller , note that the caller must have

gpio_on:
    MOV R3, R5 @turns on pins specified in register 5
    LSL R3, R0
    LDR R2, gpiobase
    STR R3, [R2, #SIO_GPIO_OUT_SET_OFFSET]
    BX LR

gpio_off:
    MOV R3, #0b1111111 @turns all of the pins in the output off
    LSL R3, R0
    LDR R2, gpiobase
    STR R3, [R2, #SIO_GPIO_OUT_CLR_OFFSET]
    BX LR

delay:
    MOV R2, #0
    MOV R3, #0xFF
    LSL R3, R3, #15          @ Adjusted timing

indelay:
    ADD R2, #1
    
    @ Inline read_gpio logic using R7 (safe register)
    LDR R5, gpiobase
    LDR R7, [R5, #SIO_GPIO_IN_OFFSET]
    LSR R7, R7, #BUTTON_PIN
    MOV R6, #1
    AND R7, R6
    MOV R1, R7               @ Store GPIO state in R1 (safe)

    CMP R1, #1
    BEQ toggle_pause

    CMP R4, #1                  @ Check if paused
    BEQ delay_exit

    CMP R2, R3
    BCC indelay

delay_exit:
    BX LR

toggle_pause:
    @ Preserve display state before handling the button
    PUSH {R5}

wait_release:
    LDR R5, gpiobase
    LDR R7, [R5, #SIO_GPIO_IN_OFFSET]
    LSR R7, R7, #BUTTON_PIN
    AND R7, R6
    CMP R7, #1
    BEQ wait_release

    @ Small debounce delay to clean up input noise
    MOV R2, #0
    MOV R3, #0x7F              @ Shorter debounce
debounce_delay:
    ADD R2, #1
    CMP R2, R3
    BCC debounce_delay

    @ Restore state after button press handling
    POP {R5}

    CMP R4, #0
    BEQ set_paused
    B set_running

set_paused:
    MOV R4, #1
    B delay_exit

set_running:
    MOV R4, #0
    B delay_exit

.align 4
    gpiobase: .word SIO_BASE
    iobank0: .word IO_BANK0_BASE
    padsbank0: .word PADS_BANK0_BASE
    setoffset: .word REG_ALIAS_SET_BITS
