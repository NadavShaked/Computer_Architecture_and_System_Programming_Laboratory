	; Definitions
	STKSZ 		                    equ 	16*1024				; Co-routine stack size 16k
	DroneStructSize         		equ		40					; Size of one drone struct
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

section .data
    ; global data section data
    global scheduler
    global target
    global printer
    global maxDistance
    global result

	maxDistance:        dd  0.0						; max distance from target to destroy it initialized to 0
	var1:				dd 	0.0						; temporary var1
	var2: 				dd 	0.0						; temporary var2
	var3:				dd	0.0						; temporary var3
	var4:				dd	0.0						; temporary var4
    result:             dd  0.0                     ; return result value
    
    scheduler:          dd scheduler_co
                        dd sched_stack + STKSZ

    printer:            dd printer_co
                        dd printer_stack + STKSZ

    target:             dd target_co
                        dd target_stack + STKSZ
                        dd 0                        ; target x coordinate
                        dd 0                        ; target y coordinate

section .rodata
	format_decimal_int: db "%d", 0 				    ; string to get int value from sscanf
	format_decimal_float: db "%f", 0 				; string to get int value from sscanf
	format_string_int: db "%d", 10, 0				; string to print int value to screen
	format_string_float: db "%f", 10, 0				; string to print float value to screen

section .bss								        ; we define (global) uninitialized variables in .bss section
    ; bss global data
    global droneArray
    global numOfDrones
    global numOfActiveDrones
    global numOfRoundsToEliminate
    global numOfRoundsToPrint
    global CURR

	numOfDrones: 				resd 	1			; N<int> – number of drones
    numOfActiveDrones:          resd    1           ; number of active drones
    numOfRoundsToEliminate: 	resd 	1			; R<int> - number of full scheduler cycles between each elimination
    numOfRoundsToPrint: 		resd 	1			; K<int> – how many drone steps between game board printings
	lfsr: 				  		resw 	1			; lfsr<short> - seed for initialization of LFSR shift register
    droneArray:                 resd    1           ; pointer to drone array
    sched_stack:                resb    STKSZ
    printer_stack:              resb    STKSZ
    target_stack:               resb    STKSZ
    CURR:                       resd    1           ; current co-routine
    SPT:                        resd    1           ; temporary stack pointer
    SPMAIN:                     resd    1           ; main's stack pointer

section .text
	global main
    global get_random_change_speed
    global get_random_change_angle
    global resume
    global do_resume
    global get_random_coordinate

    extern drone_co
    extern scheduler_co
    extern target_co
    extern printer_co

;   extern function from c
    extern printf
    extern sscanf
    extern calloc

; A safe registers macro for printing an int
%macro print_float 1
	pushfd
	pushad			                              ; Save registers
    push %1                                       ; push value to print
    push format_string_int       
    call printf
    add esp, 8                                    ; remove pushed values
    popad										  ; restore state 
	popfd
%endmacro

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

main:
	push ebp             				; Save caller state
	mov ebp, esp
	mov ecx, dword [ebp+12]					; get **argv

    finit                                   ; initialize the floating point
    
get_number_of_drones:
    pushad
	mov ebx, [ecx + 4]						; ebx = number of drones string
    push numOfDrones						; store value in numOfDrones
    push format_decimal_int					; get decimal value
    push ebx								;
    call sscanf
    add esp, 12								; restore stack state

set_numOfActiveDrones:
    mov eax, dword [numOfDrones]            ; get number of drones
    mov dword [numOfActiveDrones], eax      ; number of active drones = num of drones (at start)
    popad

get_number_of_rounds_to_eliminate:
    pushad
	mov ebx, [ecx + 8]						; ebx = number of rounds to eliminate string
    push numOfRoundsToEliminate				; store value in numOfDrones
    push format_decimal_int						; get decimal value
    push ebx								;
    call sscanf
    add esp, 12								; restore stack state
	popad

get_number_of_rounds_to_print:
    pushad
	mov ebx, [ecx + 12]						; ebx = number of rounds to print string
    push numOfRoundsToPrint					; store value in numOfDrones
    push format_decimal_int						; get decimal value
    push ebx								;
    call sscanf
    add esp, 12								; restore stack state
	popad

get_max_distance:
    pushad
	mov ebx, [ecx + 16]						; ebx = Number of drones string
    push maxDistance				    	; store value in numOfDrones
    push format_decimal_float				; get decimal value
    push ebx								;
    call sscanf
    add esp, 12								; restore stack state
	popad

get_lfsr:
    pushad
	mov ebx, [ecx + 20]						; ebx = lfsr string
    push lfsr           					; store value in numOfDrones
    push format_decimal_int					; get decimal value
    push ebx								;
    call sscanf
    add esp, 12								; restore stack state
	popad

; Create the drone co-routine array
create_drone_co_routines_array:
    pushad                                  ; / save caller state
    pushfd                                  ; \ save caller state

    mov eax, dword [numOfDrones]            ; get num of drowns
    push eax                                ;  / 
    push dword 4                            ; | calloc(4, numOfDrowns)
    call calloc                             ;  \
    add esp, 8                              ; restore stack 
    mov dword [droneArray], eax             ; save the allocated space pointer in droneArray
   
    popfd                                   ; / save caller state
    popad                                   ; \ save caller state

    mov ecx, dword [numOfDrones]            ; initialize counter upper limit

; Initialize the drones co-routines
initialize_drone_co_routines_loop:
    pushad
    push ecx

    push dword DroneStructSize
    push dword 1
    call calloc
    add esp, 8

    pop ecx
    dec ecx
    mov ebx, dword [droneArray]             ; ebx = drownArr[]

    mov dword [ebx + 4 * ecx], eax          ; drownArr[i - 1] = allocated drone co-routnie array
    
    inc ecx                                 ; ecx = i
    push ecx                                ; save register state  
    push eax                                ; beckup allocated drone array

    push dword STKSZ                        ; /
    push dword 1                            ;| calloc(1, STKSZ)
    call calloc                             ; \   
    add esp, 8                              ; restore stack state
    
    pop edx                                 ; edx = allocated drone array
    pop ecx                                 ; ecx = i

set_the_drone_co_routine:
    mov dword [edx + CODEP], drone_co       ; set co routine func
    mov dword [edx + SPP], eax              ; pointer to start of allocated stack
    add dword [edx + SPP], STKSZ            ; set the pointer to end of allocated stack
    mov dword [edx + stackPointer], eax     ; pointer to start of allocated stack
    mov dword [edx + droneIdOffset], ecx    ; set the id of the drone

    call get_random_coordinate                      ; /
    mov ebx, dword [result]                         ;| set x coordinate
    mov dword [edx + droneCoordinateXOffset], ebx   ; \

    call get_random_coordinate                      ; /
    mov ebx, dword [result]                         ;| set y coordinate
    mov dword [edx + droneCoordinateYOffset], ebx   ; \

    call get_random_speed                           ; /
    mov ebx, dword [result]                         ;| set speed
    mov dword [edx + droneSpeedOffset], ebx         ; \

    call get_random_angle                           ; /
    mov ebx, dword [result]                         ;| set angle
    mov dword [edx + droneAngleOffset], ebx         ; \

    mov dword [edx + droneScoreOffset], 0           ; set score to 0
    mov dword [edx + droneIsActive], 1              ; set active flag to true

    push edx                                        ; /
    call co_init                                    ;| initialize drone's co-routine stack
    add esp, 4                                      ; \

    popad
    dec ecx
    cmp ecx, 0
    jne initialize_drone_co_routines_loop
;    loop initialize_drone_co_routines_loop, ecx

set_the_other_co_routines:
    push scheduler                                  ; /
    call co_init                                    ;| initialize scheduler's co-routine stack
    add esp, 4                                      ; \
    
    push printer                                    ; /
    call co_init                                    ;| initialize printer's co-routine stack
    add esp, 4                                      ; \


    call get_random_coordinate                      ; /
    mov ebx, dword [result]                         ;| set initial x coordinate
    mov dword [target + 8], ebx                     ; \

    call get_random_coordinate                      ; /
    mov ebx, dword [result]                         ;| set initial y coordinate
    mov dword [target + 12], ebx                    ; \

    push target                                     ; /
    call co_init                                    ;| initialize target's co-routine stack
    add esp, 4                                      ; \



; call printer_co ;debug
    jmp start_co

pop ebp                           			; Restore caller state
ret                              			; Back to caller

generate_a_pseudo_random_number:
	push ebp
	mov ebp, esp
	pushad

    mov ecx, 16                                 ; set ecx to 16 for 16 repetition
    shift_rigth_loop:
        xor eax, eax                            ; set eax to 0
        mov ax, 1                               ; set eax to 1

        and ax, [lfsr]                          ; get the 16'th bit of lfsr

        shl ax, 2                               ; mov ax bit val to the 14'th bit in ax
        mov bx, 4                               ; / get the 14'th bit from lfsr
        and bx, [lfsr]                          ; \ get the 14'th bit from lfsr
        xor ax, bx                              ; get the val of 14'th xor 16'th bits of lfsr

        shl ax, 1                               ; mov ax bit val to the 13'th bit in ax
        mov bx, 8                               ; / get the 13'th bit from lfsr
        and bx, [lfsr]                          ; \ get the 13'th bit from lfsr
        xor ax, bx                              ; get the val of 13'th xor 14'th xor 16'th bits of lfsr

        shl ax, 2                               ; mov ax bit val to the 11'th bit in ax
        mov bx, 32                              ; / get the 11'th bit from lfsr
        and bx, [lfsr]                          ; \ get the 11'th bit from lfsr
        xor ax, bx                              ; get the val of 11'th xor 13'th xor 14'th xor 16'th bits of lfsr

        shl ax, 10                              ; mov the xor bit to the MSB

        mov bx, [lfsr]                          ; duplicate to bx the lfsr value
        shr bx, 1								; shift all bits one cell to the right and make room for first

        or bx, ax                               ; add ax (the xor solution) to the msb bit
        mov [lfsr], bx
        loop shift_rigth_loop, ecx              ; decrement ecx by 1, and cmpare to 0, if not equal to 0 jmp to shift_rigth_loop label

	popad
	mov esp, ebp	
	pop ebp
	ret

get_random_coordinate:
;   get_random_coordinate value will be save in result
	push ebp
	mov ebp, esp
	pushad

	call generate_a_pseudo_random_number
;   generate_a_pseudo_random_number value will be save in lfsr

	xor eax, eax				                ; init eax to 0
    mov dword [var1], 0			                ; init var1 to 0

    mov ax, [lfsr]                              ; init ax to lfsr value
    mov word [var1], ax 						; load value to float stack
    fild dword [var1]                            ; load var1 to floating stack
    
    mov dword [var2], 0                         ; init var2 to 0
    mov dword [var2], 65535						; max short value
    fidiv dword [var2]							; push to floating stack the value of var1 / var2
    
    mov dword [var3], 0                         ; init var3 to 0
    mov dword [var3], 100                       ; init var3 to 100 for the range [0 - 100] in board
    fimul dword [var3]                          ; push to floating stack the value of (var1 / var2) * var3
	
    mov dword [result], 0                       ; init result to 0
    fstp dword [result]                         ; init result to the popped value of floating stack

    popad
	mov esp, ebp	
	pop ebp
	ret

get_random_angle:
	push ebp
	mov ebp, esp
	pushad

	call generate_a_pseudo_random_number
;   generate_a_pseudo_random_number value will be save in lfsr

	xor eax, eax				                ; init eax to 0
    mov dword [var1], 0			                ; init var1 to 0

    mov ax, [lfsr]                              ; init var2 to 0
    mov word [var1], ax						    ; load value to float stack
    fild dword [var1]                            ; load var1 to floating stack
    
    mov dword [var2], 0
    mov dword [var2], 65535						; max short value
    fidiv dword [var2]							; push to floating stack the value of var1 / var2
    
    mov dword [var3], 0                         ; init var3 to 0
    mov dword [var3], 360                       ; init var3 to 360 for the range [0 - 360] in board
    fimul dword [var3]                          ; push to floating stack the value of (var1 / var2) * var3
	
    mov dword [result], 0                       ; init result to 0
    fstp dword [result]							; init result to the popped value of floating stack

    popad
	mov esp, ebp	
	pop ebp
	ret

get_random_change_angle:
	push ebp
	mov ebp, esp
	pushad

	call generate_a_pseudo_random_number
;   generate_a_pseudo_random_number value will be save in lfsr

	xor eax, eax				                ; init eax to 0
    mov dword [var1], 0			                ; init var1 to 0

    mov ax, [lfsr]                              ; init var2 to 0
    mov word [var1], ax						    ; load value to float stack
    fild dword [var1]                            ; load var1 to floating stack
    
    mov dword [var2], 0
    mov dword [var2], 65535						; max short value
    fidiv dword [var2]							; push to floating stack the value of var1 / var2
    
    mov dword [var3], 0                         ; init var3 to 0
    mov dword [var3], 120                       ; init var3 to 120 for the range [0 - 120] in board
    fimul dword [var3]                          ; push to floating stack the value of (var1 / var2) * var3
	mov dword [var4],  60                       ; /
    fisub dword [var4]                          ; \ create value within [-60, 60]
    
    mov dword [result], 0                       ; init result to 0
    fstp dword [result]							; init result to the popped value of floating stack

    popad
	mov esp, ebp	
	pop ebp
	ret

get_random_speed:
	push ebp
	mov ebp, esp
	pushad

	call generate_a_pseudo_random_number
;   generate_a_pseudo_random_number value will be save in lfsr

	xor eax, eax				                ; init eax to 0
    mov dword [var1], 0			                ; init var1 to 0

    mov ax, [lfsr]                              ; init var2 to 0
    mov word [var1], ax		    				; load value to float stack
    fild dword [var1]                            ; load var1 to floating stack
    
    mov dword [var2], 0
    mov dword [var2], 65535						; max short value
    fidiv dword [var2]							; push to floating stack the value of var1 / var2
    
    mov dword [var3], 0                         ; init var3 to 0
    mov dword [var3], 100                       ; init var3 to 100 for the range [0 - 100] in board
    fimul dword [var3]                          ; push to floating stack the value of (var1 / var2) * var3
	
    mov dword [result], 0                       ; init result to 0
    fstp dword [result]							; init result to the popped value of floating stack

    popad
	mov esp, ebp	
	pop ebp
	ret

get_random_change_speed:
	push ebp
	mov ebp, esp
	pushad

	call generate_a_pseudo_random_number
;   generate_a_pseudo_random_number value will be save in lfsr

	xor eax, eax				                ; init eax to 0
    mov dword [var1], 0			                ; init var1 to 0

    mov ax, [lfsr]                              ; init var2 to 0
    mov word [var1], ax		    				; load value to float stack
    fild dword [var1]                            ; load var1 to floating stack
    
    mov dword [var2], 0
    mov dword [var2], 65535						; max short value
    fidiv dword [var2]							; push to floating stack the value of var1 / var2
    
    mov dword [var3], 0                         ; init var3 to 0
    mov dword [var3], 20                        ; init var3 to 100 for the range [0 - 100] in board
    fimul dword [var3]                          ; push to floating stack the value of (var1 / var2) * var3
	
    mov dword [var4],  10                       ; /
    fisub dword [var4]                          ; \ create value between [-10, 10]

    mov dword [result], 0                       ; init result to 0
    fstp dword [result]							; init result to the popped value of floating stack

    popad
	mov esp, ebp	
	pop ebp
	ret

co_init:
	push ebp
    mov ebp, esp
    pushad

    mov ebx, [ebp + 8]                          ; get co-routine drone id pointer
    mov eax, [ebx + CODEP]                      ; eax = co routine func
    mov [SPT], ESP                              ; save esp
    mov esp, [EBX + SPP]                        ; switch to co-routine stack
    push eax                                    ; push return address
    pushfd                                      ; push flags
    pushad                                      ; push registers
    mov [ebx + SPP], esp                        ; save esp 
    mov ESP, [SPT]
    
    popad
    pop ebp
    ret

start_co:
    pushad                                      ; save state of registers in function main 
    mov dword [SPMAIN], esp                     ; save ESP of function main 
    mov ebx, scheduler                          ; ebx = pointer to scheduler struct
    jmp do_resume                               ; resume a scheduler co-routine

; endCo:
; mov ESP, [SPMAIN]                               ; restore ESP of main()
; ret
; popad

resume:
    pushfd                                      ; save the flags of the co-routine
    pushad                                      ; save the registers of the co-routine
   ; print_int scheduler

    mov edx, dword [CURR]                       ; get the current co-routine
    mov [edx + SPP], esp                        ; save current ESP
do_resume:                                      
    mov esp, [ebx + SPP]                        ; switch to co-routine's stack
    mov dword [CURR], ebx                       ; update the current co-routine
    popad                                       ; / restore resumed co-routine state
    popfd                                       ; \ restore resumed co-routine state

    ret