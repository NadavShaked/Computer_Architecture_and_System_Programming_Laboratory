	; Definitions
	STKSZ 		                    equ 	16*1024				; Co-routine stack size 16k
	DroneStructSize         		equ		37					; Size of one drone struct
	; Defines for all the co-routines
	CODEP		                    equ		0					; Offset of pointer to co-routine function in co-routine struct 
	SPP		                        equ		4					; Offset of pointer to co-routine stack in co-routine struct 
	stackPointer    			    equ		8					; Offset of pointer to co-routine stack for free in co-routine struct 
	; Define for drones array
	droneIdOffset		            equ		12					; Offset in array for drone Id
	droneCoordinateXOffset		    equ		16					; Offset in array for x
	droneCoordinateYOffset		    equ		20					; Offset in array for y
	droneSpeedOffset		        equ		24					; Offset in array for speed
	droneAngleOffset		        equ		28					; Offset in array for angle
	droneScoreOffset        		equ		32					; Offset in array for number of destroyed targers
	droneIsActive		            equ		36

section .rodata
	format_string_int:              db "%d", 10, 0				; string to print int value to screen
    debug_curr:                     db "curr is %d", 10, 0

	debug_target:              db "target being destroyed%c", 10, 0				; string to print int value to screen

section .data
	extern target		; check same name OK

	index:				dd 	0						; temporary var1


section .bss
    extern CURR
    extern result
	extern droneCURR
	

section .text
    global target_co
	extern do_resume

    extern get_random_coordinate
    extern resume
    extern printf
	extern scheduler

; A safe registers macro for printing an int
%macro print_int 1
	pushfd
	pushad			                                ; Save registers
    push %1                                         ; push value to print
    push format_string_int                          ; 
    call printf
    add esp, 8                                      ; remove pushed values
    popad										    ; restore state 
	popfd
%endmacro

; printf(string, int)
%macro print_debug 2
	pushfd
	pushad			                                ; Save registers
    push %2                                         ; push value to print
    push %1
    call printf
    add esp, 8                                      ; remove pushed values
    popad										    ; restore state 
	popfd
%endmacro

target_co:
	
;	print_debug debug_curr, dword[CURR]
	
;	print_debug debug_target, 46 


    call get_random_coordinate
    mov eax, dword [result]
    mov dword [target + 8], eax

    call get_random_coordinate
    mov eax, dword [result]
    mov dword [target + 12], eax

    mov ebx, scheduler
    call resume
	
	jmp target_co

finish: