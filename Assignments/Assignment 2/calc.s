section	.rodata								; we define (global) read-only variables in .rodata section
	format_string_int: db "%d", 10, 0			; format string/
	format_string_string: db "%s", 0			    ; format string/
	format_string_string_with_new_line: db "%s", 10, 0			    ; format string/
    format_debug: db "deb", 10,0
    calc_prompt: db "calc: ", 0


    format_new_line: db "", 10, 0
    format_num_of_operations: db "Number of operations performed : ", 0
    ;format_seperate: db "-> ", 0
    format_print_hexa_value_1_digit: db "%1X", 0
    format_print_hexa_value_2_digits: db "%02X", 0
    overflow_error_prompt: db "Error: Operand Stack Overflow", 10, 0
    empty_error_prompt: db "Error: Insufficient Number of Arguments on Stack", 10, 0
    empty_user_inpur_error_prompt: db "Error: User input is empty", 10, 0
section .data
    stack_capacity: dd 0x05
    debug_flag: dd 0x00

section .bss
    eflags_buffer: resd 1
    stack_pointer: resd 1
    stack_size: resd 1
    number_of_operations: resd 1
    user_input: resb 80

section .text
	align 16
  	global main
	extern printf
    extern fprintf
    extern calloc
    extern free
    extern fgets
    extern stdin
    extern stderr

;------------------------------------------------------------------------
%macro print_num_of_operations 0
    pushad
    pushfd
    push dword [number_of_operations]
    push format_print_hexa_value_1_digit
    call printf
    newline
    add esp, 8
    popfd
    popad
%endmacro


%macro free_stack 0
    pushad
    pushfd

    mov eax, [stack_pointer]
    mov ebx, [stack_size]

    %%while_stack_not_empty:
        cmp ebx, 0
        je  %%free_empty_stack                        ; if it points below the begining
        dec ebx
        freeList dword [eax + ebx * 4]            ; free the list on top
        jmp %%while_stack_not_empty

    %%free_empty_stack:
        push dword [stack_pointer]
        call free
        add esp, 4
    popfd
    popad

%endmacro

%macro decrease_operation 0
    pushad
    pushfd

    mov eax, dword[number_of_operations];
    dec eax
    mov [number_of_operations], eax

    popfd
    popad
%endmacro 



%macro add_operation 0
    pushad
    pushfd

    mov eax, dword[number_of_operations];
    inc eax
    mov [number_of_operations], eax

    popfd
    popad
%endmacro 

%macro bitwise_or 2
    push ebx
    push ecx
    push edx
    mov ebx, %2 ; set ebx as cur1
    mov ecx, %1 ; set ecx as cur2


    cmp ebx, 0                  ; if both next nodes not null
    je %%at_least_one_pointer_equal_to_null
    cmp ecx, 0
    je %%at_least_one_pointer_equal_to_null

    pushfd
    push ebx
    push ecx                ; save state of ecx because calloc changes all regs besides ebx
    push edx
    push 1                  ; allocation object size: 1 byte
    push 5                  ; allocate 5 bytes
    call calloc
    add esp, 8              ; remove pushed values
    pop edx                 ; return state
    pop ecx
    pop ebx
    popfd
        
    mov dl, byte [ebx]
    or dl, byte [ecx]             ; calculate bitwise or

    mov byte [eax], dl             ; put or value in new node
    mov dword [eax + 1], 0         ; newNode.next = null

    push eax                        ; save list's head
    mov ebx, dword [ebx + 1]        ; cur1 = cur1.next
    mov ecx, dword [ecx + 1]        ; cur2 = cur2.next

    mov edx, eax                    ; prev = head

    %%while_cur1_and_cur2_not_equal_to_null:
        cmp ebx, 0                                  ; if both next nodes not null
        je %%at_least_one_pointer_equal_to_null
        cmp ecx, 0
        je %%at_least_one_pointer_equal_to_null

        pushfd
        push ebx
        push ecx                ; save state of ecx because calloc changes all regs besides ebx
        push edx
        push 1                  ; allocation object size: 1 byte
        push 5                  ; allocate 5 bytes
        call calloc
        add esp, 8              ; remove pushed values
        pop edx                 ; return state
        pop ecx
        pop ebx
        popfd
        
        push edx                ; save prev node
        
        mov dl, byte [ebx]
        or dl, byte [ecx]             ; calculate bitwise or

        mov byte [eax], dl             ; put or val in newNode
        mov dword [eax + 1], 0         ; newNode.next = null

        pop edx                        ; get prev
        mov dword [edx + 1], eax       ; prev.next = cur
        mov edx, dword [edx + 1]       ; prev = prev.next = cur
        mov dword [edx + 1], 0         ; prev.next = null

        mov ebx, dword [ebx + 1]            ; cur1 = cur1.next
        mov ecx, dword [ecx + 1]            ; cur2 = cur2.next
        jmp %%while_cur1_and_cur2_not_equal_to_null

    %%at_least_one_pointer_equal_to_null:
        cmp ebx, 0
        jne %%while_bigger_not_equal_to_null
        cmp ecx, 0
        je %%skip
        mov ebx, ecx
        %%while_bigger_not_equal_to_null:
            duplicateList ebx
            mov dword [edx + 1], eax

    %%skip:
        pop eax
        pop edx
        pop ecx
        pop ebx
%endmacro

%macro bitwise_and 2
    push ebx
    push ecx
    push edx
    mov ebx, %2 ; set ebx as cur1
    mov ecx, %1 ; set ecx as cur2


    cmp ebx, 0                  ; if both next nodes not null
    je %%at_least_one_pointer_equal_to_null
    cmp ecx, 0
    je %%at_least_one_pointer_equal_to_null

    pushfd
    push ebx
    push ecx                ; save state of ecx because calloc changes all regs besides ebx
    push edx
    push 1                  ; allocation object size: 1 byte
    push 5                  ; allocate 5 bytes
    call calloc
    add esp, 8              ; remove pushed values
    pop edx                 ; return state
    pop ecx
    pop ebx
    popfd
        
    mov dl, byte [ebx]
    and dl, byte [ecx]             ; calculate bitwise and

    mov byte [eax], dl             ; put and value in new node
    mov dword [eax + 1], 0         ; newNode.next = null

    push eax                        ; save list's head
    mov ebx, dword [ebx + 1]        ; cur1 = cur1.next
    mov ecx, dword [ecx + 1]        ; cur2 = cur2.next

    mov edx, eax                    ; prev = head

    %%while_cur1_and_cur2_not_equal_to_null:
        cmp ebx, 0                                  ; if both next nodes not null
        je %%at_least_one_pointer_equal_to_null
        cmp ecx, 0
        je %%at_least_one_pointer_equal_to_null

        pushfd
        push ebx
        push ecx                ; save state of ecx because calloc changes all regs besides ebx
        push edx
        push 1                  ; allocation object size: 1 byte
        push 5                  ; allocate 5 bytes
        call calloc
        add esp, 8              ; remove pushed values
        pop edx                 ; return state
        pop ecx
        pop ebx
        popfd
        
        push edx                ; save prev node
        
        mov dl, byte [ebx]
        and dl, byte [ecx]             ; calculate bitwise and

        mov byte [eax], dl             ; put and val in newNode
        mov dword [eax + 1], 0         ; newNode.next = null

        pop edx                        ; get prev
        mov dword [edx + 1], eax       ; prev.next = cur
        mov edx, dword [edx + 1]       ; prev = prev.next = cur
        mov dword [edx + 1], 0         ; prev.next = null

        mov ebx, dword [ebx + 1]            ; cur1 = cur1.next
        mov ecx, dword [ecx + 1]            ; cur2 = cur2.next
        jmp %%while_cur1_and_cur2_not_equal_to_null

    %%at_least_one_pointer_equal_to_null:
        pop eax
        pop edx
        pop ecx
        pop ebx
%endmacro

%macro number_of_digits_in_list 1

    push ebx
    push ecx
    push edx

    mov ebx, %1
    mov ecx, 0 ;counter = 0

    %%while_cur_not_null:
        cmp dword [ebx + 1], 0    ; if cur == null
        je %%last_node
        add ecx, 2 ; counter += 2
        mov ebx, dword [ebx + 1] ; cur = cur.next
        jmp %%while_cur_not_null
    
    %%last_node:
        cmp byte [ebx], 16
        jb %%one_digit
        add ecx, 2 ; counter += 2
        jmp %%hexaConventor
    
    %%one_digit:
        add ecx, 1 ; counter += 1


    %%hexaConventor:
	    mov ebx, 256			; divisor can be any register or memory

        pushfd
        push ebx
        push ecx                ; save state of ecx because calloc changes all regs besides ebx
        push edx
        push 1                  ; allocation object size: 1 byte
        push 5                  ; allocate 5 bytes
        call calloc
        add esp, 8              ; remove pushed values
        pop edx                 ; return 
        pop ecx
        pop ebx
        popfd

        push eax

        mov eax, ecx            ; eax = number of digits
        mov edx, 0             	; eax / ebx
	    div ebx                 ; reminder -> edx
        
        pop ecx
        mov byte [ecx], dl

        mov dword [ecx + 1], 0
        push ecx    ;save list head

        %%whie_devided_number_not_zero:
            cmp eax, 0                  ; if divided number is zero finish
            je %%end

            push eax                    ; save divided number value

            pushfd
            push ebx
            push ecx                ; save state of ecx because calloc changes all regs besides ebx
            push edx
            push 1                  ; allocation object size: 1 byte
            push 5                  ; allocate 5 bytes
            call calloc
            add esp, 8              ; remove pushed values
            pop edx                 ; return 
            pop ecx
            pop ebx
            popfd

            mov edx, eax                 ; ptr to link in edx now
            pop eax                      ; eax is the divided number now
            push edx                     ; save ptr to new link              

            mov edx, 0                	 ;  init edx value
	        div ebx                      ;  eax = eax / ebx , reminder -> edx

            pop ebx                      ; ptr to link in ebx now 
            mov byte [ebx], dl           ; put number in link
            mov dword [ebx + 1], 0       ; cur.next = null (just in case)
            mov dword [ecx + 1], ebx      ; prev.next = cur
            mov ecx, ebx                 ; prev = cur
            mov ebx, 256                 ; restore division value
            jmp %%whie_devided_number_not_zero

    %%end: 
        pop eax         ; head value -> eax
        pop edx
        pop ecx
        pop ebx         ; return state
%endmacro


; A safe registers macro for printing an int in hexa
%macro print_link_hexa_value_1_digit 1
	pushad			                              ; Save registers
    push %1                                      ; push value to print
    push format_print_hexa_value_1_digit
    call printf
    add esp, 8                                      ; remove pushed values
    popad
%endmacro

; A safe registers macro for printing an int in hexa
%macro print_link_hexa_value_1_digit_debug_mode 1
    pushfd
	pushad			              ; Save registers
    push %1                       ; push value to print
    push format_print_hexa_value_1_digit
    push dword [stderr]
    call fprintf
    add esp, 12                       ; remove pushed values
    popad
    popfd
%endmacro

; A safe registers macro for printing an int in hexa
%macro print_link_hexa_value_2_digits 1
	pushad			                              ; Save registers
    push %1                                      ; push value to print
    push format_print_hexa_value_2_digits
    call printf
    add esp, 8                                      ; remove pushed values
    popad
%endmacro

; A safe registers macro for printing an int in hexa
%macro print_link_hexa_value_2_digits_debug_mode 1
    pushfd
	pushad			              ; Save registers
    push %1                       ; push value to print
    push format_print_hexa_value_2_digits
    push dword [stderr]
    call fprintf
    add esp, 12                       ; remove pushed values
    popad
    popfd
%endmacro

%macro newline 0
	pushad			                              ; Save registers
    push format_new_line
    call printf
    add esp, 4                                      ; remove pushed values
    popad
%endmacro

; A safe registers macro for printing an int
%macro print_int 1
	pushad			                              ; Save registers
    push %1                                      ; push value to print
    push format_string_int                       ; 
    call printf
    add esp, 8                                      ; remove pushed values
    popad
%endmacro

; A safe registers macro for printing an int given a ptr to it
%macro print_int_from_ptr 1
	pushad	
    mov eax, %1		                              ; Save registers
    mov ebx, dword[eax]
    push ebx                                      ; push value to print
    push format_string_int
    call printf
    add esp, 8                                      ; remove pushed values
    popad
%endmacro

; A safe registers macro for printing a string
%macro print_string 1
	pushad			              ; Save registers
    push %1                       ; push value to print
    push format_string_string       
    call printf
    add esp, 8                       ; remove pushed values
    popad
%endmacro

; A safe registers macro for printing a string
%macro print_debug_string 1
    pushfd
	pushad			              ; Save registers
    push %1                       ; push value to print
    push format_string_string_with_new_line
    push dword [stderr]
    call fprintf
    add esp, 12                       ; remove pushed values
    popad
    popfd
%endmacro

; A macro for entering a function
%macro ENTER_FUNCTION 0
	push	ebp
	mov	ebp, esp	; Entry code - set up ebp and esp
	pushad			; Save registers
%endmacro

; A macro for leaving a function
%macro LEAVE_FUNCTION 1
	popad				; Restore registers
	mov		esp, ebp	; Function exit code
	pop		ebp
    mov eax, %1
	ret
%endmacro

%macro function_prolog 0
    push ebp                     ; save state    
	mov ebp, esp	             ; save state
	pushad			             ; save state
    pushfd                       ; save state
%endmacro

%macro function_epilog 0
    popfd
    popad			
	mov esp, ebp	
	pop ebp
%endmacro
                                        ; 1 = pointer to a string representing a number ; save the converted number in eax
%macro string_to_decimal_int_convertor 1
    mov ecx, %1			                ; get function argument (pointer to string)
	mov eax, 0					       	; set the decimal value of the converted string to 0
    %%getIntLoop: 
        movzx edx, byte [ecx]			; move the char value of the i-th char to edx register
        cmp edx, 0                      ; delimiter 
        je %%end
        cmp edx, 10                     ; end of line 
        je %%end
        cmp edx, '9'					; check if edx value equal to the char '0'
        ja %%convert_letter				; if edx value is above '9' jump to hexaConventor
        sub edx, '0'
        jmp %%bottom
    %%convert_letter:	
        sub edx, 'A'
        add edx, 10
    %%bottom:
        imul eax, 16					; multiply "result so far" by 10
        add eax, edx					; add in current digit
        inc ecx							; increament the ecx by one for iterate the next char in the string
        jmp %%getIntLoop				; jump to getIntLoop
    %%end: 
%endmacro

; input: ptr to string
; output: in edx. hexa value of first 2 chars in string
; registers use: 1) ebx 
;                2) ecx
;                3) edx 
%macro getPairCharsValue 1
    push ebx
    push ecx
    mov ebx, %1
    movzx edx, byte [ebx]			; move the char value of the i-th char to edx register
    cmp edx, '9'                    ; check if edx is '9'
    ja %%getLetterValue1            ; if above so the edx is letter
    sub edx, '0'                    ; convert the digit char to the int value in hexa decimal
    jmp %%nextChar
    %%getLetterValue1:
        sub edx, 'A'                ; convert the letter char to the int value in hexa decimal
        add edx, 10                 ; 
    
    %%nextChar:
        inc ebx
        cmp byte [ebx], 0           ; check if char at [ebx] is delimiter
        je %%end
        cmp byte [ebx], 10          ; check if char at [ebx] is '\n'
        je %%end
        movzx ecx, byte [ebx]			; move the char value of the i-th char to edx register
        cmp ecx, '9'
        ja %%getLetterValue2
        sub ecx, '0'
        jmp %%skip
        %%getLetterValue2:
            sub ecx, 'A'
            add ecx, 10

        %%skip:
            shl edx, 4
            add edx, ecx
    %%end:
        pop ecx
        pop ebx
%endmacro

; input: head of first list, head of second list
; ouptput: in eax. a ptr to list representing the summation value of these 2 lists
; register use: 1) ebx first list
;               2) ecx second list
%macro addLists 2
    pushfd  ; save state
    push ebx    ; save state
    push ecx    ; save state
    push edx    ; save state
    clc         ; set carry flag to zero

    mov ebx, %2 ; set ebx as cur1
    mov ecx, %1 ; set ecx as cur2

                            ; calloc
    pushfd
    push ebx
    push ecx                ; save state of ecx because calloc changes all regs besides ebx
    push edx
    push 1                  ; allocation object size: 1 byte
    push 5                  ; allocate 5 bytes
    call calloc
    add esp, 8              ; remove pushed values
    pop edx                 ; return 
    pop ecx
    pop ebx
    popfd

    push eax
    mov eax, 0
    mov edx, 0
    mov al, byte [ebx]
    mov dl, byte [ecx]
    adc dl, al

    push eax                            ; save the eflags - start
    pushfd    
    pop eax
    mov dword [eflags_buffer], eax
    pop eax                             ; save the eflags - end

    pop eax
    mov byte [eax], dl
    mov dword [eax + 1], 0

    push eax                            ; head in stack

    mov ebx, dword [ebx + 1]                        ; cur1 = cur1.next
    mov ecx, dword [ecx + 1]                        ; cur2 = cur2.next
    mov edx, eax            ; prev = edx

    %%while_cur1_and_cur2_not_equal_to_null:
        cmp ebx, 0          ; if both next nodes not null
        je %%at_least_one_pointer_equal_to_null
        cmp ecx, 0
        je %%at_least_one_pointer_equal_to_null

        pushfd
        push ebx
        push ecx                ; save state of ecx because calloc changes all regs besides ebx
        push edx
        push 1                  ; allocation object size: 1 byte
        push 5                  ; allocate 5 bytes
        call calloc
        add esp, 8              ; remove pushed values
        pop edx                 ; return state
        pop ecx
        pop ebx
        popfd
        
        push edx                ; save state
        push eax                ; save state
 
        push dword [eflags_buffer]
        popfd

        mov edx, 0              ;  
        mov al, byte [ebx]      ;
        mov dl, byte [ecx]      ;
        adc dl, al              ; cur.val = cur1.val + cur2.val + carry

        push eax                            ; save the eflags - start
        pushfd    
        pop eax
        mov dword [eflags_buffer], eax
        pop eax                             ; save the eflags - end

        pop eax                             ; return state 
        mov byte [eax], dl      
        pop edx                             ; return state 
        mov dword [edx + 1], eax            ; prev.next = cur
        mov edx, dword [edx + 1]            ; prev = prev.next = cur

        mov ebx, dword [ebx + 1]            ; cur1 = cur1.next
        mov ecx, dword [ecx + 1]            ; cur2 = cur2.next
        jmp %%while_cur1_and_cur2_not_equal_to_null

    %%at_least_one_pointer_equal_to_null:
        cmp ecx, 0
        je %%while_bigger_not_equal_to_null
        mov ebx, ecx
        %%while_bigger_not_equal_to_null:
            cmp ebx, 0
            je %%check_if_carry_equal_to_one
            
            pushfd
            push ebx
            push ecx                ; save state of ecx because calloc changes all regs besides ebx
            push edx
            push 1                  ; allocation object size: 1 byte
            push 5                  ; allocate 5 bytes
            call calloc
            add esp, 8              ; remove pushed values
            pop edx                 ; return state
            pop ecx
            pop ebx
            popfd

            mov ecx, 0
            mov cl, byte [ebx]

            push dword [eflags_buffer]
            popfd
            adc cl, 0               ; ecx = bigger.value + carry
            push eax
            pushfd    
            pop eax
            mov dword [eflags_buffer], eax
            pop eax

            mov byte [eax], cl        ; tmp.value =  ecx
            mov dword [edx + 1], eax    ; prev.next = tmp
            mov edx, dword [edx + 1]    ; prev = prev.next
            mov ebx, dword [ebx + 1]    ; bigger = bigger.next
            
            jmp %%while_bigger_not_equal_to_null

        %%check_if_carry_equal_to_one:
            push dword [eflags_buffer]
            popfd
            jnc %%end
                        
            pushfd
            push ebx
            push ecx                ; save state of ecx because calloc changes all regs besides ebx
            push edx
            push 1                  ; allocation object size: 1 byte
            push 5                  ; allocate 5 bytes
            call calloc
            add esp, 8              ; remove pushed values
            pop edx                 ; return state
            pop ecx
            pop ebx
            popfd

            mov byte [eax], 1       ; tmp.val = 1
            mov dword [edx + 1], eax    ; prev.next = tmp
            mov edx, dword [edx + 1]    ; prev = prev.next = tmp

    %%end:
        mov dword [edx + 1], 0
        pop eax
        pop edx             ; return state
        pop ecx
        pop ebx
        popfd

%endmacro


; input: ptr to begining of list
; output: in eax. ptr to begining of new duplicated list
; registers use: 1) eax as output 
;                2) ebx as a temp variable for moving values
;                3) ecx as curent node in original list
;                4) edx as previous duplicated node
;                 
; Pseudo code:
;       begin = new (cur)
;       prevDup = begin
;       cur = cur.next
;       while(cur != null){
;          dup = new (cur)
;          prevDup.next = dup
;          prevDup = dup 
;           cur = cur.next
;       }
;       prevDup.next = null
;       return begin
;
%macro duplicateList 1
    push ebx
    push ecx
    push edx        ; save state
    mov ecx, %1     ; set ecx to head pointer of original list

    cmp ecx, 0
    je %%end


    push ebx
    push ecx                ; save state of ecx because calloc changes all regs besides ebx
    push edx
    push 1                  ; allocation object size: 1 byte
    push 5                  ; allocate 5 bytes
    call calloc
    add esp, 8              ; remove pushed values
    pop edx                 ; return 
    pop ecx
    pop ebx

    push eax                ; pointer to begin
    
    mov edx, 0
    mov dl, byte [ecx]     ; edx = cur.value
    mov byte [eax], dl      ; begin.value = edx = cur.value
    mov edx, eax            ; prevDup = begin
    mov ecx, dword [ecx + 1]    ; cur = cur.next

    %%while_cur_not_equal_to_null:
        cmp ecx, 0
        je %%end

        push ebx
        push ecx                ; save state of ecx because calloc changes all regs besides ebx
        push edx
        push 1                  ; allocation object size: 1 byte
        push 5                  ; allocate 5 bytes
        call calloc
        add esp, 8              ; remove pushed values
        pop edx                 ; return 
        pop ecx
        pop ebx

        mov bl, byte [ecx]                 ; 
        mov byte [eax], bl                 ; dup.val = cur.val

        mov dword [edx + 1], eax          ; prevDup.next = dup 
        mov edx, eax                      ; prevDup = dup
        mov ecx, dword [ecx + 1]          ; cur = cur.next
        jmp %%while_cur_not_equal_to_null ; jump to loop start

    %%end:
        mov dword [edx + 1], 0 ; prevDup.next = null
        pop eax                ;  return begin in eax
        pop edx
        pop ecx
        pop ebx                ; return state
        

%endmacro

; bring ptr of string to first place that is not zero. if only zero leave one zero in string
; the return value will be in eax
%macro handleLeadingZeros 1
    pushad
    mov ebx, %1         ; user_input pointer
    mov ecx, ebx          ; pointer to msb

    %%iterate_list:
        cmp ebx, 0
        je %%free_leading_zero
        cmp byte [ebx], 0
        je %%end1
        mov ecx, ebx
        %%end1:
            mov ebx, dword [ebx + 1]
            jmp %%iterate_list

    %%free_leading_zero:
        cmp dword [ecx + 1], 0
        je %%end
        freeList dword [ecx + 1]
        mov dword [ecx + 1], 0
        
   %%end:
        popad
%endmacro


; returns string size in edx
%macro stringLength 1
    push eax
    push ebx
    push ecx
    mov ecx, %1 ; ecx = ptr to string begining
    mov edx, 0 ; counter = 0

    %%counting_loop: 
        cmp byte[ecx], 0        ;
        je %%end             ;
        cmp byte[ecx], 10       ;
        je %%end             ; all above checks if reached end of string
        inc ecx
        inc edx
        jmp %%counting_loop
    %%end:
        pop ecx
        pop ebx
        pop eax
%endmacro

; input: ptr to string to make list from (list of heap allocated 5 bytes links with int value of string pair chars at start of each link)
; output: in eax. ptr to list head
; registers use: 1) ebx - as iteration ptr for string  
;                2) ecx - as prev link
;                3) edx - as placeholder for int value in each iteration
%macro createList 1

    mov ebx, %1         ;
    push ecx            ; save state
    push edx            ; save state
    mov ecx, 0          ; prev = null

    stringLength ebx
    and edx, 1
    cmp edx, 0
    je %%loopStart
    
    ; take first alone
        push ebx
        push ecx                ; save state of ecx because calloc changes all regs besides ebx
        push edx
        push 1                  ; allocation object size: 1 byte
        push 5                  ; allocate 5 bytes
        call calloc
        add esp, 8              ; remove pushed values
        pop edx                 ; return 
        pop ecx
        pop ebx
        mov edx, 0
        mov dl, byte [ebx]
        cmp edx, '9'
        ja %%letter
        sub edx, '0'
        jmp %%skip
        %%letter:
            sub edx, 'A'
            add edx, 10
        %%skip: 
            mov byte [eax], dl
            mov dword [eax + 1], ecx
            mov ecx, eax
            inc ebx

    %%loopStart:
        cmp byte[ebx], 0        ;
        je %%finish             ;
        cmp byte[ebx], 10       ;
        je %%finish             ; all above checks if reached end of string



        push ebx
        push ecx                ; save state of ecx because calloc changes all regs besides ebx
        push edx
        push 1                  ; allocation object size: 1 byte
        push 5                  ; allocate 5 bytes
        call calloc
        add esp, 8              ; remove pushed values
        pop edx                 ; return 
        pop ecx
        pop ebx
       ; print_int eax
        getPairCharsValue ebx   ; get int value of next two chars
        mov [eax], dl          ; link[0] = edx (int val of current 2 chars)
        mov [eax + 1], ecx      ; curr.next = prev
        ;mov edx,0
        ;mov dl, [eax]
       ; print_int edx           ; see whats inside number's place
       ; print_string dword[ecx]
        mov ecx, eax            ; prev = curr
        
        inc ebx                 ; i += 2 
        cmp ebx, 0              ;   
        je %%finish             ;   
        cmp byte[ebx], 10       ;
        je %%finish             ;
        inc ebx                 ;
        cmp byte[ebx], 0        ;
        je %%finish             ;
        cmp byte[ebx], 10       ;
        je %%finish             ; all above checks if reached end of string
        
        jmp %%loopStart

    %%finish:
        pop edx                 ; return state
        pop ecx                 ; return state
%endmacro


; print a list given its heads ptr
; 
%macro printList 1
    pushad
    mov eax, %1 ;set eax to be the pointer of the cur link
    mov ecx, 0  ; ecx is the size of list counter

    cmp eax, 0  ; if cur == null
    je %%end
    
    %%push_list:
        mov edx, 0                    ; initialize edx to 0
        mov dl, [eax]                 ; edx = number value from cur link
        push edx                      ; push edx value to stack
        inc ecx                       ; counter++
        cmp dword [eax + 1], 0            ; check if cur.next == null
        je %%pop_first                          ; jump to print the list values
        mov eax, [eax + 1]                ; cur = cur.next
        jmp %%push_list                    ; jump for push the next link value

    

    %%pop_first:
        pop edx                                 ; edx = last link value
        dec ecx
        cmp edx, 15                             ; check if above 15 so there are 2 digits
        ja %%two_digits                         ; print the 2 digits format string
        print_link_hexa_value_1_digit edx       ; else so print the 1 digit format string
        jmp %%pop_and_print                               ; jump to end
    
    %%two_digits:
        print_link_hexa_value_2_digits edx

    %%pop_and_print:
        ;print_string format_seperate
        cmp ecx, 0                              ; check if last link to print
        je %%end                    ; print last (consider one digit)
        pop edx                                 ; edx = link value
        print_link_hexa_value_2_digits edx      ; print value
        dec ecx                                 ; counter --
        jmp %%pop_and_print                     ; jump to print next value

    %%end:
        newline
        popad
%endmacro

; print a list given its heads ptr
; 
%macro printList_debug_mode 1
    pushad
    mov eax, %1 ;set eax to be the pointer of the cur link
    mov ecx, 0  ; ecx is the size of list counter

    cmp eax, 0  ; if cur == null
    je %%end
    
    %%push_list:
        mov edx, 0                    ; initialize edx to 0
        mov dl, [eax]                 ; edx = number value from cur link
        push edx                      ; push edx value to stack
        inc ecx                       ; counter++
        cmp dword [eax + 1], 0            ; check if cur.next == null
        je %%pop_first                          ; jump to print the list values
        mov eax, [eax + 1]                ; cur = cur.next
        jmp %%push_list                    ; jump for push the next link value

    

    %%pop_first:
        pop edx                                 ; edx = last link value
        dec ecx
        cmp edx, 15                             ; check if above 15 so there are 2 digits
        ja %%two_digits                         ; print the 2 digits format string
        print_link_hexa_value_1_digit_debug_mode edx       ; else so print the 1 digit format string
        jmp %%pop_and_print                               ; jump to end
    
    %%two_digits:
        print_link_hexa_value_2_digits_debug_mode edx

    %%pop_and_print:
        cmp ecx, 0                              ; check if last link to print
        je %%end                    ; print last (consider one digit)
        pop edx                                 ; edx = link value
        print_link_hexa_value_2_digits_debug_mode edx      ; print value
        dec ecx                                 ; counter --
        jmp %%pop_and_print                     ; jump to print next value

    %%end:
        newline
        popad
%endmacro

; print a list given its heads ptr
; 
%macro prin 1
    pushad
    mov eax, %1 ;set eax to be the pointer of the cur link
    mov ecx, 0  ; ecx is the size of list counter

    cmp eax, 0  ; if cur == null
    je %%end
    
    %%loop:
        mov edx, 0                    ; initialize edx to 0
        mov dl, [eax]                 ; edx = number value from cur link
        push edx                      ; push edx value to stack
        inc ecx                       ; counter++
        cmp dword [eax + 1], 0            ; check if cur.next == null
        je %%pop_and_print                          ; jump to print the list values
        mov eax, [eax + 1]                ; cur = cur.next
        jmp %%loop                    ; jump for push the next link value

    %%pop_and_print:
        print_string format_seperate
        cmp ecx, 1                              ; check if last link to print
        je %%print_last_link                    ; print last (consider one digit)
        pop edx                                 ; edx = link value
        print_link_hexa_value_2_digits edx      ; print value
        dec ecx                                 ; counter --
        jmp %%pop_and_print                     ; jump to print next value

    %%print_last_link:
        pop edx                                 ; edx = last link value
        cmp edx, 15                             ; check if above 15 so there are 2 digits
        ja %%two_digits                         ; print the 2 digits format string
        print_link_hexa_value_1_digit edx       ; else so print the 1 digit format string
        jmp %%end                               ; jump to end
    
    %%two_digits:
        print_link_hexa_value_2_digits edx

    %%end:
        newline
        popad
%endmacro

%macro freeList 1
    pushad
    mov eax, %1

    %%loop:
        cmp eax, 0
        je %%end
        mov ebx, [eax + 1]
        push ebx
        push eax
        call free
        add esp, 4
        pop ebx
        mov eax, ebx
        jmp %%loop

    %%end:
        popad
%endmacro

;----------------------------------------------------- MAIN -------------------------------------------------------------
main:
	push ebp                                ; save state    
	mov ebp, esp	                        ; save state
	pushad	
    call myCalc

main_end:
    print_string format_num_of_operations 
    ;print_int dword [number_of_operations]
    print_num_of_operations
    popad
	mov esp, ebp	
	pop ebp
    ret

myCalc:
;---------------------------------------------- GET FUNCTION ARGUMENTS -------------------------------------------------------------
    mov dword [number_of_operations], 0      ; init number of operarions to 0
    mov dword [stack_size], 0               ; set the stack size to 0
    mov eax, dword [ebp + 12]					; get **argv
    cmp dword [ebp + 8], 1                    ; check if input exist ; argc = 1 
    je no_input
    cmp dword [ebp + 8], 2                    ; check if input exist ; argc = 2 
    je one_input
    cmp dword [ebp + 8], 3                    ; check if input exist ; argc = 2 
    je two_inputs

    one_input:
        mov ebx, [eax + 4]						; get argv[1]
        cmp byte [ebx], '-'
        je handle_debug
        push eax
        string_to_decimal_int_convertor ebx
        mov dword [stack_capacity], eax
        pop eax
        jmp no_input

    handle_debug:
        inc ebx
        cmp byte [ebx], 'd'
        jne no_input
        mov dword [debug_flag], 1
        jmp no_input

    two_inputs:
        mov ebx, [eax + 4]						; get argv[1]
        push eax
        string_to_decimal_int_convertor ebx
        mov dword [stack_capacity], eax
        pop eax
        mov ebx, [eax + 8]						; get argv[2]
        cmp byte [ebx], '-'
        jne no_input
        inc ebx
        cmp byte [ebx], 'd'
        jne no_input
        mov dword [debug_flag], 1

no_input:
    push 4                                  ; size of pointer
    push dword [stack_capacity]             ; push default stack size
    call calloc                             ; initialize place for stack size

    add esp, 8                              ; remove the pushed arguments
    mov dword [stack_pointer], eax          ; stack pointer = calloc() 

    mov ebx, [stack_pointer]                ; get the calloced pointer and saved at [stack_pointer]
    mov dword [ebx], 0
    add ebx, 4
    mov dword [ebx], 1
    add ebx, 4
    mov dword [ebx], 2
;----------------------------------------------- GET USER INPUT -----------------------------------------------

get_user_input:
    

    push calc_prompt                        ; print calc pattern
	call printf
	add esp, 4                              ; remove pushed values

    pushad
    push dword [stdin]                      ; read from stdin to user_input buffer
	push 80                                 ; input max size
	push dword user_input
	call fgets
	add esp, 12                             ; remove pushed values
    popad

;----------------------------------------------- OPERATORS IDENTIFY -----------------------------------------------

    cmp dword [debug_flag], 1
    jne defult_mode
    print_debug_string user_input

defult_mode:
    add_operation
    cmp byte [user_input], 'q';need to free  the stack when quit!!!!
    je bottom
    cmp byte [user_input], 'p'
    je pop_and_print
    cmp byte [user_input], 'n'
    je number_of_hexadecimal_digits
    cmp byte [user_input], 'd'
    je duplicate
    cmp byte [user_input], '+'
    je add_lists
    cmp byte [user_input], '&'
    je bitwise_AND
    cmp byte [user_input], '|'
    je bitwise_OR

;---------------------------------------------------- NUMBER ------------------------------------------------------
user_input_is_number:
    decrease_operation
    cmp dword [debug_flag], 1
    jne number_defult_mode
    print_debug_string user_input

number_defult_mode:
    mov ecx, [stack_size]                       ; set ecx to stack size value
    cmp ecx, [stack_capacity]                  ; check if stack is full
    jne stack_not_full
	print_string overflow_error_prompt
    jmp end

stack_not_full:                                 ; eax is the pushed register
    cmp byte [user_input], 0
    je empty_user_input_error
    cmp byte [user_input], 10
    je empty_user_input_error

    createList user_input                       ; set eax to be the List pointer
    handleLeadingZeros eax

    mov edx, [stack_pointer]                    ; get stack place
    mov dword [edx + 4 * ecx], eax              ; put list in stack
    inc ecx
    mov [stack_size], ecx
    jmp end

empty_user_input_error:
    print_string empty_user_inpur_error_prompt
    jmp end
;---------------------------------------------------- POP AND PRINT ------------------------------------------------------
pop_and_print:
    mov ecx, [stack_size]
    cmp ecx, 0
    jne PAP_stack_not_empty
	print_string empty_error_prompt
    jmp end

PAP_stack_not_empty:
    ;add_operation
    mov edx, [stack_pointer]       ; get stack place
    dec ecx
    mov [stack_size], ecx
    mov eax, dword [edx + 4 * ecx]         ; get the popped pointer
    printList eax
    freeList eax
    jmp end
;----------------------------------------------- NUMBER OF HEXADECIMAL DIGITS ------------------------------------------------------
number_of_hexadecimal_digits:
    mov ecx, [stack_size]
    cmp ecx, 0
    je NOHD_empty_stack
    ;add_operation
    mov edx, [stack_pointer]
    dec ecx
    mov eax, dword [edx + 4 * ecx]         ; get the popped pointer
    number_of_digits_in_list eax
    mov dword [edx + 4 * ecx], eax         ; get the popped pointer
    inc ecx
    mov [stack_size], ecx

    cmp dword [debug_flag], 1
    jne end
    printList_debug_mode eax

    jmp end

    NOHD_empty_stack:
        print_string empty_error_prompt
        jmp end

;----------------------------------------------- DUPLICATE ------------------------------------------------------
duplicate:
    mov ecx, [stack_size]
    cmp ecx, 0
    je dup_empty_stack
    cmp ecx, [stack_capacity]
    je dup_full_stack
    jmp dup_popped_value

    dup_empty_stack:
        print_string empty_error_prompt
        jmp end
    dup_full_stack:
        print_string overflow_error_prompt
        jmp end

dup_popped_value:
    ;add_operation
    mov edx, [stack_pointer]       ; get stack place
    dec ecx
    mov ebx, dword [edx + 4 * ecx]         ; get the popped pointer
    duplicateList ebx
    inc ecx
    mov dword [edx + 4 * ecx], eax         ; get the popped pointer
    inc ecx
    mov [stack_size], ecx

    cmp dword [debug_flag], 1
    jne end
    printList_debug_mode eax

    jmp end

;----------------------------------------------- ADD ------------------------------------------------------
add_lists:
    mov ecx, [stack_size]                       ; set ecx to stack size value
    cmp ecx, 2
    jb add_less_than_two
    ;add_operation
    mov edx, [stack_pointer]       ; get stack place
    dec ecx
    mov eax, dword [edx + 4 * ecx]         ; get the popped pointer
    dec ecx
    mov ebx, dword [edx + 4 * ecx]         ; get the popped pointer

    push eax
    push ebx

    addLists eax, ebx

    mov dword [edx + 4 * ecx], eax ; put new list in top of stack
    inc ecx
    mov dword [stack_size], ecx


    cmp dword [debug_flag], 1
    jne add_debug_not_mode
    printList_debug_mode eax

add_debug_not_mode:
    pop ebx
    pop eax
    freeList ebx
    freeList eax
    jmp end

add_less_than_two:
    print_string empty_error_prompt
    jmp end

;----------------------------------------------- Bitwise AND ------------------------------------------------------
bitwise_AND:
   ; add_operation
    mov ecx, [stack_size]                       ; set ecx to stack size value
    cmp ecx, 2
    jb bitwise_and_less_than_two
    mov edx, [stack_pointer]       ; get stack place
    dec ecx
    mov eax, dword [edx + 4 * ecx]         ; get the popped pointer
    dec ecx
    mov ebx, dword [edx + 4 * ecx]         ; get the popped pointer

    push eax
    push ebx

    bitwise_and eax, ebx
    handleLeadingZeros eax
    mov dword [edx + 4 * ecx], eax ; put new list in top of stack
    inc ecx
    mov dword [stack_size], ecx

    cmp dword [debug_flag], 1
    jne and_debug_not_mode
    printList_debug_mode eax

and_debug_not_mode:
    pop ebx
    pop eax
    freeList ebx
    freeList eax
    jmp end

bitwise_and_less_than_two:
    print_string empty_error_prompt
    jmp end

;----------------------------------------------- Bitwise OR ------------------------------------------------------
bitwise_OR:
    ;add_operation
    mov ecx, [stack_size]                       ; set ecx to stack size value
    cmp ecx, 2
    jb bitwise_or_less_than_two
    mov edx, [stack_pointer]       ; get stack place
    dec ecx
    mov eax, dword [edx + 4 * ecx]         ; get the popped pointer
    dec ecx
    mov ebx, dword [edx + 4 * ecx]         ; get the popped pointer

    push eax
    push ebx

    bitwise_or eax, ebx

    mov dword [edx + 4 * ecx], eax ; put new list in top of stack
    inc ecx
    mov dword [stack_size], ecx

    cmp dword [debug_flag], 1
    jne or_debug_not_mode
    printList_debug_mode eax

or_debug_not_mode:
    pop ebx
    pop eax
    freeList ebx
    freeList eax
    jmp end

bitwise_or_less_than_two:
    print_string empty_error_prompt
    jmp end

end:
    jmp get_user_input

bottom:
    decrease_operation
    mov eax, [number_of_operations];
    free_stack
    ret