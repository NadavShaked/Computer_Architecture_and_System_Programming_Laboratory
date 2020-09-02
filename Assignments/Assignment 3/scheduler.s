	; Definitions
	STKSZ 		                    equ 	16*1024				; Co-routine stack size 16k
	DroneStructSize         		equ		37					; Size of one drone struct
    INTEGER_MAX_VALUE         		equ		2147483647	
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
	droneIsActive		            equ		36					; Offser in array for active flag

section .rodata
	format_string_int:                      db "%d", 10, 0				; string to print int value to screen
    winner_drone_string_format:             db "The Winner Drone Is: %d", 10, 0
    winner_drone_id_1_string_format:        db "The Winner Drone Is: 1", 10, 0

    debug_init_drone:     db "scheduler starting drone %d", 10, 0
    debug_inSched: db "scheduler starting drone%c", 10, 0
    debug_curr:                     db "curr is %d", 10, 0


section .data
    i:                              dd      0
    loser_score:                    dd      INTEGER_MAX_VALUE
    extern printer

section .bss
    loser_co_routine_array:         resd    1
    winner_drone_id:                resd    1
    val1:                           resd    1
    val2:                           resd    1
    val3:                           resd    1
    val4:                           resd    1

    extern numOfDrones
    extern numOfActiveDrones
    extern droneArray
    extern numOfRoundsToEliminate
    extern numOfRoundsToPrint
    extern CURR

section .text
    global scheduler_co

    extern free
    extern printf
    extern resume

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

scheduler_co:
    ;print_int 11
	;print_debug debug_curr, dword[CURR]

    ;print_debug debug_inSched, 46

    pushad
    pushfd
    mov ebx, dword [numOfDrones]
    cmp ebx, 1
    jne cont
    mov ebx, printer                    ; ebx = printer (co-routine) 
    call resume                         ; contex switch to printer
        
    push winner_drone_id_1_string_format
    call printf
    add esp, 4
    popfd
    popad
    jmp free_and_exit

cont:
    popfd
    popad

    xor edx, edx                                    ; edx = 0
    mov eax, dword [i]                              ;  /
    mov ebx, dword [numOfDrones]                    ; | edx = i % N      (N = numOfDrowns)
    cdq                                             ; |
    div ebx                                         ;  \

    mov ecx, [droneArray]               ; ecx = droneArray

    mov ecx, [ecx + 4 * edx]            ; ecx = droneArray[currentDrone]
    mov eax, [ecx + droneIsActive]      ; / check if drone is active
    cmp eax, dword 1                    ; \
    jne skip_drone                      ; if not active dont resume it

    mov ebx, ecx                        ; ebx = next drone (co-routine)

    ;print_debug debug_init_drone, dword [ebx + droneIdOffset]

    call resume                         ; contex switch to next drone

    skip_drone:
    xor edx, edx                        ; edx = 0
    mov eax, [i]                        ;  /
    mov ebx, [numOfRoundsToPrint]       ; | edx = i % K      (K = numOfRoundsToPrint)
    cdq                                 ; |
    div ebx                             
    
    cmp edx, 0
    jne skip_printing

    mov ebx, printer                    ; ebx = printer (co-routine) 
    call resume                         ; contex switch to printer

    skip_printing:
    xor edx, edx                        ; edx = 0
    mov eax, [i]                        ;  /
    mov ebx, [numOfDrones]              ; | eax = i / N ; edx = i % N      (N = numOfDrowns)
    cdq                                 ; |
    div ebx                             ;  \

    cmp edx, 0
    jne skip_second_condition

    xor edx, edx                        ; edx = 0
    mov ebx, [numOfRoundsToEliminate]   ; / eax = (i / N) / R ; edx = (i / N) % R (ebx = R = numOfRoundsToEliminate)
    cdq                                 ;|
    div ebx                             ; \
    
    cmp edx, 0
    jne skip_second_condition

    mov dword [loser_score], INTEGER_MAX_VALUE                ; / initialize values
    mov dword [loser_co_routine_array], 0                     ; \

    xor ecx, ecx                                  ; j = 0
    find_loser:
    ; loop through all drones and get lowest scorer among the active ones
        cmp ecx, dword [numOfDrones]            ; / j < numOfDrones
        je end_loser_loop                       ; \ if (j == numOfDrones) break loop
        mov eax, [droneArray]                   ;
        mov eax, [eax + 4 * ecx]                ; eax = droneArray[currentDrone]
        mov edx, [eax + droneIsActive]          ; edx = droneArray[currentDrone].isActive
        cmp edx, 1                              ; / check if droneArray[currentDrone] is active
        jne not_loser                           ; \ if not skip current drone
        mov edx, [eax + droneScoreOffset]       ; edx = droneArray[currentDrone].score
        cmp edx, dword [loser_score]            ; / check if droneArray[currentDrone].score > minimum score
        jnl not_loser                           ; \ if bigger skip current drone
        mov dword [loser_score], edx            ; loser_score = droneArray[currentDrone].score
        mov dword [loser_co_routine_array], eax ; loser_drone = droneArray[currentDrone]
    
        not_loser:
        inc ecx
        jmp find_loser
        
    end_loser_loop:
        mov eax, dword [loser_co_routine_array]                   ; / disactivate the looser drone
        mov dword [eax + droneIsActive], 0                        ; \ 
        mov eax, dword [numOfActiveDrones]                        ; /
        dec eax                                                   ;| decrease number of active drones
        mov dword [numOfActiveDrones], eax                        ; \

    skip_second_condition:
        mov eax, dword [i]                        ; /
        inc eax                                   ;| i++
        mov dword [i], eax                        ; \

        mov eax, dword [numOfActiveDrones]
        cmp eax, 1
        jne scheduler_co

        mov ecx, 0                                  ; j = 0
        find_winner_loop:
        ; loop through all drones and get the ONLY active one
            cmp ecx, dword [numOfDrones]            ; / j < numOfDrones
            je winner                               ; \ if (j == numOfDrones) break loop

            mov eax, [droneArray]                   ; /
            mov eax, [eax + 4 * ecx]                ; \ eax = droneArray[currentDrone]
            mov edx, [eax + droneIsActive]          ; edx = droneArray[currentDrone].isActive
            cmp edx, 1                              ; / check if droneArray[currentDrone] is active
            je winner                               ; \ if not skip current drone
            inc ecx
            jmp find_winner_loop
    
        winner:
            mov ecx, [eax + droneIdOffset]
            pushad
            push ecx
            push winner_drone_string_format
            call printf
            add esp, 8
            popad
            jmp free_and_exit
            
        free_and_exit:

            mov ecx, 0

            free_loop:
                cmp ecx, dword [numOfDrones]
                je end_free_loop

                mov ebx, [droneArray]
                mov ebx, [ebx + 4 * ecx]
                mov edx, [ebx + stackPointer]

                pushad
                pushfd

                push edx
                call free
                add esp, 4

                popfd
                popad

                pushad
                pushfd

                push ebx
                call free
                add esp, 4

                popfd
                popad

                inc ecx
                jmp free_loop
            
            end_free_loop:

            mov edx, [droneArray]
            pushad
            pushfd

            push edx
            call free
            add esp, 4

            popfd
            popad

            mov	eax, 1		; system call number (sys_exit)
            int	0x80		; call kernel
        ; free and

    ; mov eax, [i]
    ; mov val1, eax                       ; val1 = i
    ; mov ebx, [numOfDrones]              ; / val2 = N = numOfDrowns
    ; mov val2, ebx                       ; \
