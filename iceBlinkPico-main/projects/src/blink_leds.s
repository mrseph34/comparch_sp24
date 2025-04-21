.data
led_value: .byte 0  # Variable to hold the LED state

.text
.global main
main:
    li a0, 1          # Load immediate value for LED state
    li a1, 2000       # Load delay count (2000 milliseconds)

loop:
    sb a0, 0x30000000 # Turn on LED
    
    # Delay loop
    li t0, 0          
delay_on:
    addi t0, t0, 1    
    blt t0, a1, delay_on  
    
    sb zero, 0x30000000 # Turn off LED
    
    # Delay loop
    li t0, 0        
delay_off:
    addi t0, t0, 1    
    blt t0, a1, delay_off  
   
    j loop            # Repeat the loop