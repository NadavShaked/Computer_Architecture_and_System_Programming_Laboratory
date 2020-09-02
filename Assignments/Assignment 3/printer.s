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
	droneIsActive		            equ		36					; Offser in array for active flag

section .rodata
	target_coordinates_string_format: db "%.2f, %.2f", 10, 0
	target_coordinates_string_format_debug: db "Target: %.2f, %.2f", 10, 0
	drone_info_string_format: db "%d, %.2f, %.2f, %.2f, %.2f, %d", 10, 0
	drone_info_string_format_debug: db "Id: %d, X: %.2f, Y: %.2f, Angle: %.2f, Speed: %.2f, Score: %d", 10, 0

    drone_id_string_format: db "%d, ", 0
    drone_x_coordinate_string_format: db "%.2f, ", 0
    drone_y_coordinate_string_format: db "%.2f, ", 0
    drone_angle_string_format: db "%.2f, ", 0
    drone_speed_coordinate_string_format: db "%.2f, ", 0
    drone_score_string_format: db "%d", 10, 0

    drone_id_string_format_debug: db "ID: %d, ", 0
    drone_x_coordinate_string_format_debug: db "X Coordinate: %.2f, ", 0
    drone_y_coordinate_string_format_debug: db "Y Coordinate: %.2f, ", 0
    drone_angle_string_format_debug: db "Angle: %.2f, ", 0
    drone_speed_coordinate_string_format_debug: db "Speed: %.2f, ", 0
    drone_score_string_format_debug: db "Score: %d", 10, 0

	format_string_int: db "%d", 10, 0				; string to print int value to screen

section .bss
	floatNumberDword:			resd 1
	floatNumberQword:		    resq 1

    extern numOfDrones
    extern droneArray

section .data
    extern scheduler
    extern target

section .text
    global printer_co

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

printer_co:

print_target:
    mov eax, [target + 8]                   ; get target X coordinate
    mov ebx, [target + 12]                  ; get target Y coordinateget
    
	pushad
    ; convert Y coordinate value to quadword and push to stack
	mov [floatNumberDword], ebx             ; load the Y coordinate value to floatNumberDword
	fld dword [floatNumberDword]            ; push the Y coordinate value to floating stack
    fstp qword [floatNumberQword]           ; pop the Y coordinate value from floating stack
	push dword [floatNumberQword + 4]       ; pushing 32 bits - the MSB
    push dword [floatNumberQword]           ; pushing 32 bits - LSB

    ; convert X coordinate value to quadword and push to stack
	mov [floatNumberDword], eax             ; load the X coordinate value to floatNumberDword
	fld dword [floatNumberDword]            ; push the X coordinate value to floating stack
    fstp qword [floatNumberQword]           ; pop the X coordinate value from floating stack
	push dword [floatNumberQword + 4]       ; pushing 32 bits - the MSB
    push dword [floatNumberQword]           ; pushing 32 bits - LSB

	push target_coordinates_string_format
	call printf
	add esp, 20
	popad

    mov ecx, 0                              ; ecx = i = 0
print_drones_details_loop:
    mov ebx, dword [droneArray]             ; ebx = drowns Array
    mov ebx, [ebx + 4 * ecx]                ; ebx = drowns Array [i]

   ; print_int dword [ebx + droneIdOffset]

    mov edx, dword [ebx + droneIsActive]      ; / check if drown is active
    cmp edx, 1                                ; \ check if drown is active
    jne skip                                  ; if not active continue

    pushad
    push dword [ebx + droneIdOffset]     ; push the drone score to stack
    push drone_id_string_format
    call printf
    add esp, 8
    popad

    ; convert drone X coordinate value to quadword and push to stack
    pushad
    mov edx, dword [ebx + droneCoordinateXOffset] ; ebx = X coordinate
	mov [floatNumberDword], edx             ; load the X coordinate value to floatNumberDword
	fld dword [floatNumberDword]            ; push the X coordinate value to floating stack
    fstp qword [floatNumberQword]           ; pop the X coordinate value from floating stack
	push dword [floatNumberQword + 4]       ; pushing 32 bits - the MSB
    push dword [floatNumberQword]           ; pushing 32 bits - LSB
    push drone_x_coordinate_string_format
    call printf
    add esp, 12
    popad

    pushad
    ; convert drone Y coordinate value to quadword and push to stack
    mov edx, dword [ebx + droneCoordinateYOffset]
	mov [floatNumberDword], edx             ; load the X coordinate value to floatNumberDword
	fld dword [floatNumberDword]            ; push the X coordinate value to floating stack
    fstp qword [floatNumberQword]           ; pop the X coordinate value from floating stack
	push dword [floatNumberQword + 4]       ; pushing 32 bits - the MSB
    push dword [floatNumberQword]           ; pushing 32 bits - LSB
    
    push drone_y_coordinate_string_format
    call printf
    add esp, 12
    popad

    pushad
    ; convert drone angle value to quadword and push to stack
    mov edx, dword [ebx + droneAngleOffset] ; ebx = angle
	mov [floatNumberDword], edx             ; load the angle value to floatNumberDword
	fld dword [floatNumberDword]            ; push the angle value to floating stack
    fstp qword [floatNumberQword]           ; pop the angle value from floating stack
	push dword [floatNumberQword + 4]       ; pushing 32 bits - the MSB
    push dword [floatNumberQword]           ; pushing 32 bits - LSB

    push drone_angle_string_format
    call printf
    add esp, 12
    popad

    pushad
    ; convert drone speed value to quadword and push to stack
    mov edx, dword [ebx + droneSpeedOffset] ; ebx = drown speed
	mov [floatNumberDword], edx             ; load the speed value to floatNumberDword
	fld dword [floatNumberDword]            ; push the speed value to floating stack
    fstp qword [floatNumberQword]           ; pop the speed value from floating stack
	push dword [floatNumberQword + 4]       ; pushing 32 bits - the MSB
    push dword [floatNumberQword]           ; pushing 32 bits - LSB
    
    push drone_speed_coordinate_string_format
    call printf
    add esp, 12
    popad

    pushad
    push dword [ebx + droneScoreOffset]     ; push the drone score to stack
    push drone_score_string_format
    call printf
    add esp, 8
    popad

    skip:
        inc ecx                                 ; i++
        cmp ecx, dword [numOfDrones]            ; if (i == numOfDrowns) break loop
        jne print_drones_details_loop           ; else print next drown

    end_print:
         mov ebx, scheduler            ; ebx = scheduler function (scheduler[0])
         call resume                             ; resume scheduler
         jmp printer_co                          ; return to infinite loop