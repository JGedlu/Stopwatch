#include "hardware/regs/addressmap.h"
#include "hardware/regs/sio.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/pads_bank0.h"
#include "hardware/regs/timer.h"
#include "hardware/regs/m0plus.h"

.equ SEG_G, 16
.equ SEG_F, 17
.equ SEG_A, 18
.equ SEG_B, 19
.equ SEG_C, 20
.equ SEG_D, 21
.equ SEG_E, 22
.equ BUTTON, 23

.equ TIMER_IRQ, 0x10
.equ TIMER_ALARM0, 0x10
.equ TIMER_INTR, 0x24
.equ ALARM_TIME, 1000000  @ 1 second

.thumb_func
.global main
.align 4

main:
    @ Initializes GPIO for seven-segment display
    MOV R0, #SEG_G
    BL gpioinit
    MOV R0, #SEG_F
    BL gpioinit
    MOV R0, #SEG_A
    BL gpioinit
    MOV R0, #SEG_B
    BL gpioinit
    MOV R0, #SEG_C
    BL gpioinit
    MOV R0, #SEG_D
    BL gpioinit
    MOV R0, #SEG_E
    BL gpioinit

    MOV R0, #16

    @ Sets up the timer interrupt content (COMMENTED OUT FOR PROGRAM INTEGRITY)
    @ MOV R0, #ALARM_TIME
    @ BL set_alarm0
    @ BL set_alarm0_isr

display_loop:
    @ Adheres to timer interrupt content (COMMENTED OUT FOR PROGRAM INTEGRITY)
    @LDR R2, =run_flag
    @LDR R1, [R2]
    @CMP R1, #0
    @BEQ display_loop       @ If flag = 0, loop back to top (pause execution)

    MOV R5, #0b0111111  @ Digit 0
    BL gpio_on
    BL delay
    BL gpio_off

    MOV R5, #0b0001100  @ Digit 1
    BL gpio_on
    BL delay
    BL gpio_off

    MOV R5, #0b1011011  @ Digit 2
    BL gpio_on
    BL delay
    BL gpio_off

    MOV R5, #0b1011110  @ Digit 3
    BL gpio_on
    BL delay
    BL gpio_off

    MOV R5, #0b1101100  @ Digit 4
    BL gpio_on
    BL delay
    BL gpio_off

    MOV R5, #0b1110110  @ Digit 5
    BL gpio_on
    BL delay
    BL gpio_off

    MOV R5, #0b1110111  @ Digit 6
    BL gpio_on
    BL delay
    BL gpio_off

    MOV R5, #0b0011100  @ Digit 7
    BL gpio_on
    BL delay
    BL gpio_off

    MOV R5, #0b1111111  @ Digit 8
    BL gpio_on
    BL delay
    BL gpio_off

    MOV R5, #0b1111100  @ Digit 9
    BL gpio_on
    BL delay
    BL gpio_off

    B display_loop

@ Alarm Interrupt Setup
set_alarm0:
    LDR R2, =TIMER_BASE
    LDR R1, [R2, #TIMER_TIMELR_OFFSET]  @ Reads current time

    LDR R3, =ALARM_TIME                 @ Loads ALARM_TIME into R3
    ADD R1, R1, R3                      @ Sets alarm time (current time + delay)

    STR R1, [R2, #TIMER_ALARM0_OFFSET]  @ Writes to alarm register

    @ Enables alarm interrupt
    MOV R1, #1
    STR R1, [R2, #TIMER_INTE_OFFSET]    @ Enables alarm 0 interrupt
    BX LR

alarm_isr:
    PUSH {LR}

    LDR R2, =TIMER_BASE
    MOV R1, #1
    MOV R3, #1
    STR R1, [R2, #TIMER_INTR_OFFSET]    @ Clears interrupt flag

    @ Responds to button press
    BL read_gpio                        @ Checks if button is pressed
    CMP R1, #1                          @ If button is pressed
    BNE alarm_exit                      @ If not, exit ISR

    @ Toggles execution state
    LDR R2, =run_flag                   @ Loads flag address
    LDR R1, [R2]                        @ Reads current flag
    EOR R1, R1, R3                      @ Toggles current flag (0 -> 1 & 1 -> 0)
    STR R1, [R2]                        @ Stores new flag value

alarm_exit:
    POP {PC}

set_alarm0_isr:
    @ Sets IRQ Handler
    LDR R2, =PPB_BASE
    LDR R1, =M0PLUS_VTOR_OFFSET
    ADD R2, R1
    LDR R1, [R2]                        @ Loads IVT base address
    LDR R2, =alarm0_isr_offset          @ Loads offset
    ADD R2, R1                          @ Adds to IVT base
    LDR R0, =alarm_isr
    STR R0, [R2]                        @ Stores handler address

    @ Enables alarm 0 IRQ in NVIC
    MOV R0, #1
    LDR R2, =PPB_BASE
    LDR R1, =M0PLUS_NVIC_ICPR_OFFSET
    ADD R1, R2
    STR R0, [R1]                        @ Clears pending interrupt

    LDR R1, =M0PLUS_NVIC_ISER_OFFSET
    ADD R1, R2
    STR R0, [R1]                        @ Enables IRQ in NVIC

    BX LR

@ GPIO Operations
gpioinit:
    MOV R3, #1
    LSL R3, R0              @ Shifts to pin position
    LDR R2, gpiobase
    STR R3, [R2, #SIO_GPIO_OE_SET_OFFSET]
    STR R3, [R2, #SIO_GPIO_OUT_CLR_OFFSET]
    @ Enables I/O for the pin
    LDR R2, padsbank0
    LSL R3, R0, #2
    ADD R2, R3
    MOV R1, #PADS_BANK0_GPIO0_IE_BITS
    LDR R4, setoffset
    ORR R2, R4
    STR R1, [R2, #PADS_BANK0_GPIO0_OFFSET]
    @ Sets the function to SIO
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
    MOV R3, #0b1111111      @ Turns off all pins
    LSL R3, R0
    LDR R2, gpiobase
    STR R3, [R2, #SIO_GPIO_OUT_CLR_OFFSET]
    BX LR

read_gpio:
    LDR R2, gpiobase
    LDR R3, [R2, #SIO_GPIO_IN_OFFSET]
    LSR R3, #BUTTON
    MOV R4, #1
    AND R3, R4      @ Mask to isolate the value of the pin
    MOV R1, R3      @ Place the result in R1 (1 = HIGH , 0 = LOW)
    BX LR

delay:
    MOV R2, #0
    MOV R3, #0xFF
    LSL R3, #17

indelay:
    ADD R2, #1
    CMP R2, R3
    BCC indelay
    BX LR

.align 4
gpiobase:        .word SIO_BASE
iobank0:        .word IO_BANK0_BASE
padsbank0:      .word PADS_BANK0_BASE
setoffset:      .word REG_ALIAS_SET_BITS
timerbase:      .word TIMER_BASE
ppbbase:        .word PPB_BASE
vtoroffset:     .word M0PLUS_VTOR_OFFSET
clearint:       .word M0PLUS_NVIC_ICPR_OFFSET
setint:         .word M0PLUS_NVIC_ISER_OFFSET
alarmtime:      .word ALARM_TIME
alarm0_isr_offset: .word 0x40
run_flag: .space 4