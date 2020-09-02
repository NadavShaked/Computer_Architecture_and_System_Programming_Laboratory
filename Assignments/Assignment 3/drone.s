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
	format_string_int:              db "%d", 10, 0				; string to print int value to screen
	format_string_float:            db "%f", 10, 0				; string to print float value to screen
    format_string:                  db "co_drone ID: %d", 10, 0

section .data
    extern result
    extern scheduler
    extern target
	extern maxDistance

section .bss
    global droneCURR

    extern CURR

    loser_co_routine_array:         resd    1
    winner_drone_id:                resd    1
    droneCURR:                      resd    1
    val1:                           resd    1
    val2:                           resd    1
    val3:                           resd    1
    val4:                           resd    1
    valQuad1:                       resq    1

section .text
    global drone_co

    extern resume
    extern get_random_change_speed
    extern get_random_change_angle
    extern printf
    extern printer_co

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

%macro print_floating 0
    pushad
    pushfd
    fst qword [valQuad1]
    push dword [valQuad1 + 4]
    push dword [valQuad1]
    push format_string_float
    call printf
    add esp, 12
    popfd
    popad
%endmacro

%macro keep_within 1
    fild %1
    fcomip
    ja %%check_neg
    fisub %1
    jmp %%end
    %%check_neg:
    fldz
    fcomip
    jb %%dont_change
    fiadd %1
    %%end:
%endmacro

drone_co:
    ; pushad
    ; pushfd
    ; mov ecx, [CURR]
    ; mov ebx, [ecx + droneIdOffset]
    ; push ebx
    ; push format_string
    ; call printf
    ;add esp, 8
    ;popfd
   ; popad



	call may_destroy
    ;call printer_co ;for debug


    mov ecx, [CURR]


    ; mov ebx, [ecx + droneIdOffset] 	; get drone current angle
    ; print_int ebx


update_angle:
    finit

    call get_random_change_angle

    mov ebx, [ecx + droneAngleOffset] 	; get drone current angle
    mov dword [val1], ebx				; 
    fld dword [val1]					; load cuurent angle
    fld dword [result]					; load angle change
    faddp								; add them up

check_angle_bounds:
    mov ebx, 360
    mov dword [val1], ebx
    fild dword [val1]
    fcomip
    ja checkIfNegativeDegree
    fisub dword [val1]
    jmp degreeInBound
checkIfNegativeDegree:
    fldz
    fcomip
    jb degreeInBound
    fiadd dword [val1]

degreeInBound:
    fstp dword [val1]
    mov ebx, dword [val1]
    mov dword [ecx + droneAngleOffset], ebx

update_speed:
    finit

    call get_random_change_speed

    mov ebx, [ecx + droneSpeedOffset]
    mov dword [val1], ebx
    fld dword [val1]
    fld dword [result]
    faddp
    fst dword [val1]
check_speed_bounds:
    mov ebx, 100
    mov dword [val2], ebx
    fild dword [val2]
    fcomip
    ja check_if_negative_speed
    mov ebx, 100
    mov dword [val2], ebx
    fild dword [val2]
    fstp dword [val1]
    jmp speed_in_bound
check_if_negative_speed:
    fldz
    fcomip
    jb speed_in_bound
    fldz
    fstp dword [val1]

speed_in_bound:
    mov edx, dword [val1]
    mov [ecx + droneSpeedOffset], edx

update_X_coordinate:
    finit
    
    mov ebx, [ecx + droneAngleOffset]
    mov dword [val1], ebx
    fld dword [val1]
    fldpi
    fmulp
    mov ebx, 180
    mov [val1], ebx
    fidiv dword [val1]
    fcos
    mov ebx, [ecx + droneSpeedOffset]
    mov dword [val1], ebx
    fld dword [val1]
    fmulp
    mov ebx, [ecx + droneCoordinateXOffset]
    mov dword [val1], ebx
    fld dword [val1]
    faddp

check_X_coordinate_bounds:
    mov ebx, 100
    mov dword [val1], ebx
    fild dword [val1]
    fcomip
    ja check_if_X_coordinate_negative
    fisub dword [val1]
    jmp X_coordinate_bound
check_if_X_coordinate_negative:
    fldz
    fcomip
    jb X_coordinate_bound
    fiadd dword [val1]

X_coordinate_bound:
    fstp dword [val1]
    mov ebx, dword [val1]
    mov dword [ecx + droneCoordinateXOffset], ebx




;     fst dword [val1]
; check_X_coordinate_bounds:
;     mov ebx, 100
;     mov dword [val2], ebx
;     fild dword [val2]
;     fcomip
;     ja check_if_negative_X_coordinate
;     mov ebx, 100
;     mov dword [val2], ebx
;     fild dword [val2]
;     fstp dword [val1]
;     jmp X_coordinate_in_bound
; check_if_negative_X_coordinate:
;     fldz
;     fcomip
;     jb X_coordinate_in_bound
;     fldz
;     fstp dword [val1]

; X_coordinate_in_bound:
;     mov edx, dword [val1]
;     mov [ecx + droneCoordinateXOffset], edx

update_Y_coordinate:
    finit
    
    mov ebx, [ecx + droneAngleOffset]
    mov dword [val1], ebx
    fld dword [val1]
    fldpi
    fmulp
    mov ebx, 180
    mov [val1], ebx
    fidiv dword [val1]
    fsin
    mov ebx, [ecx + droneSpeedOffset]
    mov dword [val1], ebx
    fld dword [val1]
    fmulp
    mov ebx, [ecx + droneCoordinateYOffset]
    mov dword [val1], ebx
    fld dword [val1]
    faddp


check_Y_coordinate_bounds:
    mov ebx, 100
    mov dword [val1], ebx
    fild dword [val1]
    fcomip
    ja check_if_Y_coordinate_negative
    fisub dword [val1]
    jmp Y_coordinate_bound
check_if_Y_coordinate_negative:
    fldz
    fcomip
    jb Y_coordinate_bound
    fiadd dword [val1]

Y_coordinate_bound:
    fstp dword [val1]
    mov ebx, dword [val1]
    mov dword [ecx + droneCoordinateYOffset], ebx

;     fst dword [val1]
; check_Y_coordinate_bounds:
;     mov ebx, 100
;     mov dword [val2], ebx
;     fild dword [val2]
;     fcomip
;     ja check_if_negative_Y_coordinate
;     mov ebx, 100
;     mov dword [val2], ebx
;     fild dword [val2]
;     fstp dword [val1]
;     jmp Y_coordinate_in_bound
; check_if_negative_Y_coordinate:
;     fldz
;     fcomip
;     jb Y_coordinate_in_bound
;     fldz
;     fstp dword [val1]

; Y_coordinate_in_bound:
;     mov edx, dword [val1]
;     mov [ecx + droneCoordinateYOffset], edx   

    mov ebx, scheduler           
    call resume              
    jmp drone_co


may_destroy:
	push ebp
	mov ebp, esp
	pushad

    finit

    mov eax, dword [target + 8]				
    mov dword [val1], eax					
    fld dword [val1]						
    mov ecx, [CURR]
    mov eax, dword [ecx + droneCoordinateXOffset]  
    mov dword [val1], eax                           
    fld dword [val1]						        
    fsubp											
    fst st1										    
    fmulp                                           
    fstp dword [val1]                               

    mov eax, dword [target + 12]				
    mov dword [val2], eax					    
    fld dword [val2]						    

    mov eax, dword [ecx + droneCoordinateYOffset]  
    mov dword [val2], eax                           
    fld dword [val2]						        
    fsubp											
    fst st1									
    fmulp                                          
    fstp dword [val2]                  

    fld dword [val1]					
    fld dword [val2]						
    faddp                     

    fsqrt                               

    fld dword [maxDistance]
    fcomip
    jb farAway



    ; fstp dword [val3]					

    ; mov eax, dword [maxDistance]				
    ; mov ebx, dword [val3]			
    ; cmp eax, ebx							
    ; ja farAway

destroying_point:
    mov eax, dword [ecx + droneScoreOffset]
    inc eax
    mov dword [ecx + droneScoreOffset], eax

    mov dword [droneCURR], ecx
    mov ebx, dword target			
    call resume

farAway:
    popad
	mov esp, ebp	
	pop ebp
	ret