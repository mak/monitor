; Cuckoo Sandbox - Automated Malware Analysis.
; Copyright (C) 2010-2014 Cuckoo Foundation.
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

%include "misc.inc"

global asm_tramp
global asm_tramp_size
global asm_tramp_hook_alloc_off
global asm_tramp_hook_handler_off
global asm_tramp_orig_func_stub_off
global asm_tramp_retaddr_off
global asm_tramp_retaddr_add_off

%define TLS_HOOK_INFO 0x80
%define TLS_LASTERR 0x34

%define HOOKCNT_OFF 0
%define LASTERR_OFF 8

_asm_tramp:

    ; fetch hook-info
    mov rax, qword [gs:TLS_HOOK_INFO]
    jmp _tramp_addresses

_tramp_hook_alloc:
    dq 0xcccccccccccccccc

_tramp_hook_handler:
    dq 0xcccccccccccccccc

_tramp_orig_func_stub:
    dq 0xcccccccccccccccc

_tramp_retaddr:
    dq 0xcccccccccccccccc

_tramp_retaddr_add:
    dq 0xcccccccccccccccc

_tramp_addresses:

    test rax, rax
    jnz _tramp_check_count

    ; create hook-info
    call _tramp_getpc

_tramp_getpc:
    pop rax

    pushad
    call qword [rax+_tramp_hook_alloc-_tramp_getpc]
    popad

    mov rax, qword [gs:TLS_HOOK_INFO]

_tramp_check_count:

%ifndef tramp_special

    cmp qword [rax+HOOKCNT_OFF], 0
    jz _tramp_do_it

    ; we're already in a hook - abort
    call _tramp_getpc2

_tramp_getpc2:
    pop rax

    ; jump to the original function stub
    jmp qword [rax+_tramp_orig_func_stub-_tramp_getpc2]

%endif

_tramp_do_it:

    ; increase hook count
    inc qword [rax+HOOKCNT_OFF]

    ; save last error
    push qword [gs:TLS_LASTERR]
    pop qword [rax+LASTERR_OFF]

    call _tramp_getpc3

_tramp_getpc3:
    pop rax

    ; save the return address
    pushad
    push qword [rsp+128]
    call qword [rax+_tramp_retaddr_add-_tramp_getpc3]
    popad

    ; fetch the new return address
    push qword [rax+_tramp_retaddr-_tramp_getpc3]

    ; actually patch the return address
    pop qword [rsp]

    ; jump to the hook handler
    jmp qword [rax+_tramp_hook_handler-_tramp_getpc3]

_tramp_end:


asm_tramp dq _asm_tramp
asm_tramp_size dd _tramp_end - _asm_tramp
asm_tramp_hook_alloc_off dd _tramp_hook_alloc - _asm_tramp
asm_tramp_hook_handler_off dd _tramp_hook_handler - _asm_tramp
asm_tramp_orig_func_stub_off dd _tramp_orig_func_stub - _asm_tramp
asm_tramp_retaddr_off dd _tramp_retaddr - _asm_tramp
asm_tramp_retaddr_add_off dd _tramp_retaddr_add - _asm_tramp