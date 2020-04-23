section .data                     		
		format: db "%d", 10, 0

section .text                  
         global assFunc        
         extern c_checkValidity
         extern printf

assFunc:
		push ebp              				; save Base Pointer (bp) original value
        mov ebp, esp         				; use Base Pointer to access stack contents (do_Str(...) activation frame)
		pushad								; push all signficant registers onto stack (backup registers values)
		mov ecx, [ebp + 12]					; get 2nd function argument on stack
		push ecx							; push the argument from ecx register to stack
		mov ebx, [ebp + 8]					; get 1st function argument on stack
		push ebx							; push the argument from ebx register to stack
		call c_checkValidity				; call c_checkValidity from c code
		add esp, 8							; pop the arguments from stack
		cmp eax, 0							; compare the eax (the value that return from c_checkValidity) register to '0'
		je plus								; go to plus sector if the eax is 0
		sub ebx, ecx						; subtract ecx register value to register ebx 
		jmp bottom							; go to bottom sector

plus:
		add ebx, ecx						; add ecx register value to register ebx 

bottom:
		push ebx							; push the argument from ebx register to stack
		push dword format					; push the argument from format data to stack
		call printf							; call printf c function
		add esp, 8							; pop the arguments from stack
		popad                    			; restore all previously used registers
        mov esp, ebp						; free function activation frame
        pop ebp								; restore Base Pointer previous value (to returnt to the activation frame of main(...))
        ret									; returns from do_Str(...) function