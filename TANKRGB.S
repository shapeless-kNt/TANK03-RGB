.intel_syntax noprefix

.equ WM_DESTROY,       0x0002
.equ WM_CLOSE,         0x0010
.equ WM_PAINT,         0x000F
.equ WM_TIMER,         0x0113
.equ WM_USER,          0x0400
.equ WM_TRAY,          0x0401
.equ WM_LBUTTONUP,     0x0202
.equ WM_RBUTTONUP,     0x0205

.equ NIM_ADD,          0x00000000
.equ NIM_MODIFY,       0x00000001
.equ NIM_DELETE,       0x00000002
.equ NIF_MESSAGE,      0x00000001
.equ NIF_ICON,         0x00000002
.equ NIF_TIP,          0x00000004
.equ NID_SIZE,         88

.equ MF_STRING,        0x00000000
.equ MF_GRAYED,        0x00000001
.equ MF_CHECKED,       0x00000008
.equ MF_DEFAULT,       0x00001000
.equ MF_SEPARATOR,     0x00000800
.equ TPM_RIGHTBUTTON,  0x00000002
.equ TPM_RETURNCMD,    0x00000100

.equ IDI_APPLICATION,  32512
.equ HKCU,             0x80000001
.equ KEY_QUERY_VALUE,  0x00000001
.equ KEY_SET_VALUE,    0x00000002
.equ REG_SZ,           1
.equ REG_DWORD,        4
.equ BI_RGB,           0
.equ DIB_RGB_COLORS,   0
.equ ERROR_SUCCESS,    0
.equ WS_POPUP,         0x80000000
.equ WS_VISIBLE,       0x10000000
.equ WS_EX_TOOLWINDOW, 0x00000080
.equ SM_CXSCREEN,      0
.equ SM_CYSCREEN,      1
.equ TRANSPARENT,      1
.equ DT_CENTER,        0x00000001
.equ DT_VCENTER,       0x00000004
.equ DT_WORDBREAK,     0x00000010
.equ DT_SINGLELINE,    0x00000020
.equ DT_NOPREFIX,      0x00000800

.equ ID_RGB_AUTO,      1000
.equ ID_RGB_OFF,       1001
.equ ID_RGB_RAINBOW,   1002
.equ ID_RGB_BREATH,    1003
.equ ID_RGB_CYCLE,     1004
.equ ID_HEADER_TITLE,  1400
.equ ID_HEADER_SUB,    1401
.equ ID_HEADER_GITHUB, 1402
.equ ID_POWER_STATUS,  1500
.equ ID_BOOT_TOGGLE,   2000
.equ ID_EXIT,          3000

.equ TIMER_POWER_ID,   1
.equ TIMER_POWER_MS,   2000
.equ ABOUT_W,          260
.equ ABOUT_H,          120

.equ RGB_AUTO_EC_VALUE,    0
.equ RGB_OFF_EC_VALUE,     1
.equ RGB_RAINBOW_EC_VALUE, 2
.equ RGB_BREATH_EC_VALUE,  3
.equ RGB_CYCLE_EC_VALUE,   4

.text
.global _mainCRTStartup
_mainCRTStartup:
    push 0
    call dword ptr [__imp__GetModuleHandleA@4]
    mov [hInst], eax
    mov [wc + 20], eax

    lea eax, [wc]
    push eax
    call dword ptr [__imp__RegisterClassExA@4]

    push 0
    push dword ptr [hInst]
    push 0
    push 0
    push 0
    push 0
    push 0
    push 0
    push 0
    lea eax, [wndTitle]
    push eax
    lea eax, [className]
    push eax
    push 0
    call dword ptr [__imp__CreateWindowExA@48]
    test eax, eax
    jnz have_window
    push 1
    call dword ptr [__imp__ExitProcess@4]

have_window:
    mov [hWndMain], eax
    mov [nid + 4], eax

    call load_rgb_state
    call query_power_state
    call create_tray_icon
    mov [hIcon], eax
    mov [nid + 20], eax

    lea eax, [nid]
    push eax
    push NIM_ADD
    call shell_notify_icon

    push 0
    push TIMER_POWER_MS
    push TIMER_POWER_ID
    push dword ptr [hWndMain]
    call dword ptr [__imp__SetTimer@16]

    cmp byte ptr [rgbKnown], 0
    je startup_trim
    call apply_saved_rgb

startup_trim:
    call trim_working_set

message_loop:
    lea eax, [msg]
    push 0
    push 0
    push 0
    push eax
    call dword ptr [__imp__GetMessageA@16]
    cmp eax, 0
    jle app_exit
    lea eax, [msg]
    push eax
    call dword ptr [__imp__TranslateMessage@4]
    lea eax, [msg]
    push eax
    call dword ptr [__imp__DispatchMessageA@4]
    jmp message_loop

app_exit:
    lea eax, [nid]
    push eax
    push NIM_DELETE
    call shell_notify_icon
    call destroy_current_icon
    push 0
    call dword ptr [__imp__ExitProcess@4]

.global _WndProc@16
_WndProc@16:
    mov eax, [esp + 8]
    cmp eax, WM_TRAY
    je wnd_tray
    cmp eax, WM_TIMER
    je wnd_timer
    cmp eax, WM_DESTROY
    je wnd_destroy
    push dword ptr [esp + 16]
    push dword ptr [esp + 16]
    push dword ptr [esp + 16]
    push dword ptr [esp + 16]
    call dword ptr [__imp__DefWindowProcA@16]
    ret 16

wnd_tray:
    mov eax, [esp + 16]
    cmp eax, WM_LBUTTONUP
    je show_it
    cmp eax, WM_RBUTTONUP
    je show_it
    xor eax, eax
    ret 16
show_it:
    push dword ptr [esp + 4]
    call show_menu
    call trim_working_set
    xor eax, eax
    ret 16

wnd_timer:
    mov eax, [esp + 12]
    cmp eax, TIMER_POWER_ID
    jne wnd_timer_done
    mov al, [powerState]
    mov [oldPowerState], al
    call query_power_state
    mov al, [powerState]
    cmp al, [oldPowerState]
    je wnd_timer_done
    call update_tray_icon
    call update_open_menu_power_text
    call trim_working_set
wnd_timer_done:
    xor eax, eax
    ret 16

wnd_destroy:
    lea eax, [nid]
    push eax
    push NIM_DELETE
    call shell_notify_icon
    call destroy_current_icon
    push 0
    call dword ptr [__imp__PostQuitMessage@4]
    xor eax, eax
    ret 16

show_menu:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    mov esi, [ebp + 8]

    call query_autorun
    call query_power_state
    call update_tray_icon
    call dword ptr [__imp__CreatePopupMenu@0]
    mov ebx, eax
    test ebx, ebx
    jz sm_done
    mov [hPopupMenu], ebx
    mov byte ptr [menuOpen], 1

    lea edx, [txtHeaderTitle]
    push edx
    push ID_HEADER_TITLE
    push (MF_STRING | MF_GRAYED | MF_DEFAULT)
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    lea edx, [txtHeaderSub]
    push edx
    push ID_HEADER_SUB
    push (MF_STRING | MF_GRAYED)
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    lea edx, [txtHeaderGithub]
    push edx
    push ID_HEADER_GITHUB
    push (MF_STRING | MF_GRAYED)
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    push 0
    push 0
    push MF_SEPARATOR
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    call get_power_text_ptr
    push eax
    push ID_POWER_STATUS
    push (MF_STRING | MF_GRAYED)
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    push 0
    push 0
    push MF_SEPARATOR
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    mov eax, MF_STRING
    cmp byte ptr [rgbKnown], 0
    je sm_auto_nocheck
    cmp dword ptr [rgbState], RGB_AUTO_EC_VALUE
    jne sm_auto_nocheck
    or eax, MF_CHECKED
sm_auto_nocheck:
    lea edx, [txtRgbAuto]
    push edx
    push ID_RGB_AUTO
    push eax
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    mov eax, MF_STRING
    cmp byte ptr [rgbKnown], 0
    je sm_off_nocheck
    cmp dword ptr [rgbState], RGB_OFF_EC_VALUE
    jne sm_off_nocheck
    or eax, MF_CHECKED
sm_off_nocheck:
    lea edx, [txtRgbOff]
    push edx
    push ID_RGB_OFF
    push eax
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    mov eax, MF_STRING
    cmp byte ptr [rgbKnown], 0
    je sm_rainbow_nocheck
    cmp dword ptr [rgbState], RGB_RAINBOW_EC_VALUE
    jne sm_rainbow_nocheck
    or eax, MF_CHECKED
sm_rainbow_nocheck:
    lea edx, [txtRgbRainbow]
    push edx
    push ID_RGB_RAINBOW
    push eax
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    mov eax, MF_STRING
    cmp byte ptr [rgbKnown], 0
    je sm_breath_nocheck
    cmp dword ptr [rgbState], RGB_BREATH_EC_VALUE
    jne sm_breath_nocheck
    or eax, MF_CHECKED
sm_breath_nocheck:
    lea edx, [txtRgbBreath]
    push edx
    push ID_RGB_BREATH
    push eax
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    mov eax, MF_STRING
    cmp byte ptr [rgbKnown], 0
    je sm_cycle_nocheck
    cmp dword ptr [rgbState], RGB_CYCLE_EC_VALUE
    jne sm_cycle_nocheck
    or eax, MF_CHECKED
sm_cycle_nocheck:
    lea edx, [txtRgbCycle]
    push edx
    push ID_RGB_CYCLE
    push eax
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    push 0
    push 0
    push MF_SEPARATOR
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    mov eax, MF_STRING
    cmp byte ptr [bootState], 0
    je sm_boot_toggle_nocheck
    or eax, MF_CHECKED
sm_boot_toggle_nocheck:
    lea edx, [txtBootToggle]
    push edx
    push ID_BOOT_TOGGLE
    push eax
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    push 0
    push 0
    push MF_SEPARATOR
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    lea edx, [txtExit]
    push edx
    push ID_EXIT
    push MF_STRING
    push ebx
    call dword ptr [__imp__AppendMenuA@16]

    lea eax, [pt]
    push eax
    call dword ptr [__imp__GetCursorPos@4]

    push esi
    call dword ptr [__imp__SetForegroundWindow@4]

    push 0
    push esi
    push 0
    push dword ptr [pt + 4]
    push dword ptr [pt]
    push (TPM_RETURNCMD | TPM_RIGHTBUTTON)
    push ebx
    call dword ptr [__imp__TrackPopupMenu@28]
    mov edi, eax

    push ebx
    call dword ptr [__imp__DestroyMenu@4]
    mov byte ptr [menuOpen], 0
    mov dword ptr [hPopupMenu], 0

    cmp edi, ID_RGB_AUTO
    je cmd_rgb_auto
    cmp edi, ID_RGB_OFF
    je cmd_rgb_off
    cmp edi, ID_RGB_RAINBOW
    je cmd_rgb_rainbow
    cmp edi, ID_RGB_BREATH
    je cmd_rgb_breath
    cmp edi, ID_RGB_CYCLE
    je cmd_rgb_cycle
    cmp edi, ID_BOOT_TOGGLE
    je cmd_boot_toggle
    cmp edi, ID_EXIT
    je cmd_exit
    jmp sm_done

cmd_rgb_auto:
    mov dword ptr [rgbState], RGB_AUTO_EC_VALUE
    mov byte ptr [rgbKnown], 1
    call save_rgb_state
    mov al, RGB_AUTO_EC_VALUE
    call apply_rgb_value
    call update_tray_icon
    jmp sm_done

cmd_rgb_off:
    mov dword ptr [rgbState], RGB_OFF_EC_VALUE
    mov byte ptr [rgbKnown], 1
    call save_rgb_state
    mov al, RGB_OFF_EC_VALUE
    call apply_rgb_value
    call update_tray_icon
    jmp sm_done

cmd_rgb_rainbow:
    mov dword ptr [rgbState], RGB_RAINBOW_EC_VALUE
    mov byte ptr [rgbKnown], 1
    call save_rgb_state
    mov al, RGB_RAINBOW_EC_VALUE
    call apply_rgb_value
    call update_tray_icon
    jmp sm_done

cmd_rgb_breath:
    mov dword ptr [rgbState], RGB_BREATH_EC_VALUE
    mov byte ptr [rgbKnown], 1
    call save_rgb_state
    mov al, RGB_BREATH_EC_VALUE
    call apply_rgb_value
    call update_tray_icon
    jmp sm_done

cmd_rgb_cycle:
    mov dword ptr [rgbState], RGB_CYCLE_EC_VALUE
    mov byte ptr [rgbKnown], 1
    call save_rgb_state
    mov al, RGB_CYCLE_EC_VALUE
    call apply_rgb_value
    call update_tray_icon
    jmp sm_done

cmd_boot_toggle:
    cmp byte ptr [bootState], 0
    je cmd_boot_enable
    call set_autorun_off
    mov byte ptr [bootState], 0
    jmp sm_done
cmd_boot_enable:
    call set_autorun_on
    mov byte ptr [bootState], 1
    jmp sm_done

cmd_exit:
    push 0
    call dword ptr [__imp__PostQuitMessage@4]

sm_done:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4

get_power_text_ptr:
    lea eax, [txtPowerUnknown]
    cmp byte ptr [powerState], 1
    jne gpt_not_silent
    lea eax, [txtPowerSilent]
    ret
gpt_not_silent:
    cmp byte ptr [powerState], 2
    jne gpt_not_auto
    lea eax, [txtPowerAuto]
    ret
gpt_not_auto:
    cmp byte ptr [powerState], 3
    jne gpt_done
    lea eax, [txtPowerPerformance]
gpt_done:
    ret

update_open_menu_power_text:
    cmp byte ptr [menuOpen], 0
    je uom_done
    mov eax, [hPopupMenu]
    test eax, eax
    jz uom_done
    call get_power_text_ptr
    push eax
    push ID_POWER_STATUS
    push (MF_STRING | MF_GRAYED)
    push ID_POWER_STATUS
    push dword ptr [hPopupMenu]
    call dword ptr [__imp__ModifyMenuA@20]
uom_done:
    ret

destroy_current_icon:
    mov eax, [hIcon]
    test eax, eax
    jz dci_done
    push eax
    call dword ptr [__imp__DestroyIcon@4]
    mov dword ptr [hIcon], 0
dci_done:
    ret

update_tray_icon:
    push ebx
    call create_tray_icon
    test eax, eax
    jz uti_done
    mov ebx, eax
    mov eax, [hIcon]
    mov [oldIcon], eax
    mov [hIcon], ebx
    mov [nid + 20], ebx
    lea eax, [nid]
    push eax
    push NIM_MODIFY
    call shell_notify_icon
    mov eax, [oldIcon]
    test eax, eax
    jz uti_done
    push eax
    call dword ptr [__imp__DestroyIcon@4]
uti_done:
    pop ebx
    ret

create_tray_icon:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov dword ptr [iconBitsPtr], 0
    lea eax, [iconBitsPtr]
    push 0
    push 0
    push eax
    push DIB_RGB_COLORS
    lea eax, [bmiIcon]
    push eax
    push 0
    call dword ptr [__imp__CreateDIBSection@24]
    test eax, eax
    jz cti_fail
    mov [hColorBmp], eax

    call fill_icon_pixels

    lea eax, [maskBits]
    push eax
    push 1
    push 1
    push 16
    push 16
    call dword ptr [__imp__CreateBitmap@20]
    test eax, eax
    jz cti_fail_color
    mov [hMaskBmp], eax

    mov dword ptr [iconInfo], 1
    mov dword ptr [iconInfo + 4], 0
    mov dword ptr [iconInfo + 8], 0
    mov eax, [hMaskBmp]
    mov [iconInfo + 12], eax
    mov eax, [hColorBmp]
    mov [iconInfo + 16], eax
    lea eax, [iconInfo]
    push eax
    call dword ptr [__imp__CreateIconIndirect@4]
    mov ebx, eax

    push dword ptr [hMaskBmp]
    call dword ptr [__imp__DeleteObject@4]
    push dword ptr [hColorBmp]
    call dword ptr [__imp__DeleteObject@4]
    mov eax, ebx
    jmp cti_done

cti_fail_color:
    push dword ptr [hColorBmp]
    call dword ptr [__imp__DeleteObject@4]
cti_fail:
    xor eax, eax
cti_done:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

fill_icon_pixels:
    push ebx
    push esi
    push edi
    mov edi, [iconBitsPtr]
    xor ebx, ebx
fip_y_loop:
    xor esi, esi
fip_x_loop:
    mov eax, esi
    shl eax, 1
    sub eax, 15
    mov [dxTmp], eax
    imul eax, eax
    mov ecx, eax

    mov eax, ebx
    shl eax, 1
    sub eax, 15
    mov [dyTmp], eax
    imul eax, eax
    add eax, ecx

    cmp eax, 225
    ja fip_transparent
    cmp eax, 100
    jbe fip_inner

fip_ring:
    cmp byte ptr [rgbKnown], 0
    je fip_ring_dark
    cmp dword ptr [rgbState], RGB_OFF_EC_VALUE
    je fip_ring_dark

    mov eax, [dyTmp]
    cmp eax, -5
    jl fip_top
    cmp eax, 5
    jg fip_bottom
    mov eax, [dxTmp]
    cmp eax, 0
    jl fip_left_mid
    mov eax, 0xFFFFD000
    jmp fip_store
fip_left_mid:
    mov eax, 0xFF006CFF
    jmp fip_store
fip_top:
    mov eax, [dxTmp]
    cmp eax, 0
    jl fip_top_left
    mov eax, 0xFFFF7A00
    jmp fip_store
fip_top_left:
    mov eax, 0xFFFF007A
    jmp fip_store
fip_bottom:
    mov eax, [dxTmp]
    cmp eax, 0
    jl fip_bottom_left
    mov eax, 0xFF7CFF00
    jmp fip_store
fip_bottom_left:
    mov eax, 0xFF00C8FF
    jmp fip_store

fip_ring_dark:
    mov eax, 0xFF202020
    jmp fip_store

fip_inner:
    mov eax, 0xFF707070
    cmp byte ptr [powerState], 1
    jne fip_inner_not_silent
    mov eax, 0xFF0078FF
    jmp fip_store
fip_inner_not_silent:
    cmp byte ptr [powerState], 2
    jne fip_inner_not_auto
    mov eax, 0xFF00C853
    jmp fip_store
fip_inner_not_auto:
    cmp byte ptr [powerState], 3
    jne fip_store
    mov eax, 0xFFFF1A1A
    jmp fip_store

fip_transparent:
    xor eax, eax

fip_store:
    mov [edi], eax
    add edi, 4
    inc esi
    cmp esi, 16
    jl fip_x_loop
    inc ebx
    cmp ebx, 16
    jl fip_y_loop
    pop edi
    pop esi
    pop ebx
    ret

trim_working_set:
    push 0xFFFFFFFF
    push 0xFFFFFFFF
    call dword ptr [__imp__GetCurrentProcess@0]
    push eax
    call dword ptr [__imp__SetProcessWorkingSetSize@12]
    ret

shell_notify_icon:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    lea eax, [dllShell32]
    push eax
    call dword ptr [__imp__LoadLibraryA@4]
    test eax, eax
    jz sni_fail
    mov ebx, eax
    lea eax, [fnShellNotifyIconA]
    push eax
    push ebx
    call dword ptr [__imp__GetProcAddress@8]
    test eax, eax
    jz sni_free_fail
    mov esi, eax
    push dword ptr [ebp + 12]
    push dword ptr [ebp + 8]
    call esi
    jmp sni_free
sni_free_fail:
    xor eax, eax
sni_free:
    push ebx
    call dword ptr [__imp__FreeLibrary@4]
    jmp sni_done
sni_fail:
    xor eax, eax
sni_done:
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 8

query_power_state:
    mov byte ptr [powerState], 0

    push 0
    push 0
    push 3
    push 0
    push 0
    push 0x40000000
    lea eax, [driverPath]
    push eax
    call dword ptr [__imp__CreateFileA@28]
    cmp eax, 0xFFFFFFFF
    je qps_done
    mov [hDev], eax

    mov ax, 0x004E
    mov dl, 0x2E
    call send_out32_ioctl
    mov ax, 0x004F
    mov dl, 0x11
    call send_out32_ioctl

    mov ax, 0x004E
    mov dl, 0x2F
    call send_out32_ioctl
    mov ax, 0x004F
    mov dl, 0xC4
    call send_out32_ioctl

    mov ax, 0x004E
    mov dl, 0x2E
    call send_out32_ioctl
    mov ax, 0x004F
    mov dl, 0x10
    call send_out32_ioctl

    mov ax, 0x004E
    mov dl, 0x2F
    call send_out32_ioctl
    mov ax, 0x004F
    mov dl, 0xFD
    call send_out32_ioctl

    mov ax, 0x004E
    mov dl, 0x2E
    call send_out32_ioctl
    mov ax, 0x004F
    mov dl, 0x12
    call send_out32_ioctl

    mov ax, 0x004E
    mov dl, 0x2F
    call send_out32_ioctl
    mov ax, 0x004F
    call send_inp32_ioctl

    cmp al, 1
    jb qps_close
    cmp al, 3
    ja qps_close
    mov [powerState], al

qps_close:
    push dword ptr [hDev]
    call dword ptr [__imp__CloseHandle@4]
    mov dword ptr [hDev], 0
qps_done:
    ret

apply_saved_rgb:
    mov eax, [rgbState]
    and eax, 0xFF
    cmp eax, RGB_CYCLE_EC_VALUE
    ja asr_done
    call apply_rgb_value
asr_done:
    ret

apply_rgb_value:
    mov [rgbByte], al

    push 0
    push 0
    push 3
    push 0
    push 0
    push 0x40000000
    lea eax, [driverPath]
    push eax
    call dword ptr [__imp__CreateFileA@28]
    cmp eax, 0xFFFFFFFF
    je arv_done
    mov [hDev], eax

    mov ax, 0x004F
    mov dl, 0x11
    call send_out32_ioctl

    mov ax, 0x004E
    mov dl, 0x2F
    call send_out32_ioctl

    mov ax, 0x004F
    mov dl, 0xC4
    call send_out32_ioctl

    mov ax, 0x004E
    mov dl, 0x2E
    call send_out32_ioctl

    mov ax, 0x004F
    mov dl, 0x10
    call send_out32_ioctl

    mov ax, 0x004E
    mov dl, 0x2F
    call send_out32_ioctl

    mov ax, 0x004F
    mov dl, 0xFC
    call send_out32_ioctl

    mov ax, 0x004E
    mov dl, 0x2E
    call send_out32_ioctl

    mov ax, 0x004F
    mov dl, 0x12
    call send_out32_ioctl

    mov ax, 0x004E
    mov dl, 0x2F
    call send_out32_ioctl

    mov ax, 0x004F
    mov dl, [rgbByte]
    call send_out32_ioctl

    push dword ptr [hDev]
    call dword ptr [__imp__CloseHandle@4]
    mov dword ptr [hDev], 0
arv_done:
    ret

send_out32_ioctl:
    mov [cmdBuf], ax
    mov [cmdBuf + 2], dl
    mov dword ptr [bytesReturned], 0
    push 0
    lea eax, [bytesReturned]
    push eax
    push 0
    push 0
    push 3
    lea eax, [cmdBuf]
    push eax
    push 0x9C402008
    push dword ptr [hDev]
    call dword ptr [__imp__DeviceIoControl@32]
    ret

send_inp32_ioctl:
    mov [cmdBuf], ax
    mov byte ptr [inpByte], 0
    mov dword ptr [bytesReturned], 0
    push 0
    lea eax, [bytesReturned]
    push eax
    push 1
    lea eax, [inpByte]
    push eax
    push 2
    lea eax, [cmdBuf]
    push eax
    push 0x9C402004
    push dword ptr [hDev]
    call dword ptr [__imp__DeviceIoControl@32]
    mov al, [inpByte]
    ret

query_autorun:
    mov byte ptr [bootState], 0
    lea eax, [regRunKey]
    lea edx, [hReg]
    push edx
    push KEY_QUERY_VALUE
    push 0
    push eax
    push HKCU
    call dword ptr [__imp__RegOpenKeyExA@20]
    test eax, eax
    jne qa_done
    mov dword ptr [regDataSize], 0
    lea eax, [regDataSize]
    push eax
    push 0
    push 0
    push 0
    lea eax, [runValueName]
    push eax
    push dword ptr [hReg]
    call dword ptr [__imp__RegQueryValueExA@24]
    test eax, eax
    jne qa_close
    mov byte ptr [bootState], 1
qa_close:
    push dword ptr [hReg]
    call dword ptr [__imp__RegCloseKey@4]
qa_done:
    ret

set_autorun_on:
    push 260
    lea eax, [exePath]
    push eax
    push 0
    call dword ptr [__imp__GetModuleFileNameA@12]
    test eax, eax
    jz sao_done
    call make_quoted_path
    call strlen_autorun
    inc eax
    mov [autoLen], eax
    lea eax, [hReg]
    push 0
    push eax
    push 0
    push KEY_SET_VALUE
    push 0
    push 0
    push 0
    lea eax, [regRunKey]
    push eax
    push HKCU
    call dword ptr [__imp__RegCreateKeyExA@36]
    test eax, eax
    jne sao_done
    push dword ptr [autoLen]
    lea eax, [autorunData]
    push eax
    push REG_SZ
    push 0
    lea eax, [runValueName]
    push eax
    push dword ptr [hReg]
    call dword ptr [__imp__RegSetValueExA@24]
    push dword ptr [hReg]
    call dword ptr [__imp__RegCloseKey@4]
sao_done:
    ret

set_autorun_off:
    lea eax, [regRunKey]
    lea edx, [hReg]
    push edx
    push KEY_SET_VALUE
    push 0
    push eax
    push HKCU
    call dword ptr [__imp__RegOpenKeyExA@20]
    test eax, eax
    jne saro_done
    lea eax, [runValueName]
    push eax
    push dword ptr [hReg]
    call dword ptr [__imp__RegDeleteValueA@8]
    push dword ptr [hReg]
    call dword ptr [__imp__RegCloseKey@4]
saro_done:
    ret

make_quoted_path:
    lea esi, [exePath]
    lea edi, [autorunData]
    mov byte ptr [edi], '"'
    inc edi
mqp_loop:
    lodsb
    stosb
    test al, al
    jne mqp_loop
    dec edi
    mov byte ptr [edi], '"'
    inc edi
    mov byte ptr [edi], 0
    ret

strlen_autorun:
    lea edi, [autorunData]
    xor eax, eax
sla_loop:
    cmp byte ptr [edi + eax], 0
    je sla_done
    inc eax
    jmp sla_loop
sla_done:
    ret

save_rgb_state:
    lea eax, [hReg]
    push 0
    push eax
    push 0
    push KEY_SET_VALUE
    push 0
    push 0
    push 0
    lea eax, [regAppKey]
    push eax
    push HKCU
    call dword ptr [__imp__RegCreateKeyExA@36]
    test eax, eax
    jne srs_done
    push 4
    lea eax, [rgbState]
    push eax
    push REG_DWORD
    push 0
    lea eax, [rgbValueName]
    push eax
    push dword ptr [hReg]
    call dword ptr [__imp__RegSetValueExA@24]
    push dword ptr [hReg]
    call dword ptr [__imp__RegCloseKey@4]
srs_done:
    ret

load_rgb_state:
    mov byte ptr [rgbKnown], 0
    mov dword ptr [regDataSize], 4
    lea eax, [regAppKey]
    lea edx, [hReg]
    push edx
    push KEY_QUERY_VALUE
    push 0
    push eax
    push HKCU
    call dword ptr [__imp__RegOpenKeyExA@20]
    test eax, eax
    jne lrs_done
    lea eax, [regDataSize]
    push eax
    lea eax, [rgbState]
    push eax
    push 0
    push 0
    lea eax, [rgbValueName]
    push eax
    push dword ptr [hReg]
    call dword ptr [__imp__RegQueryValueExA@24]
    test eax, eax
    jne lrs_close
    cmp dword ptr [rgbState], RGB_CYCLE_EC_VALUE
    ja lrs_close
    mov byte ptr [rgbKnown], 1
lrs_close:
    push dword ptr [hReg]
    call dword ptr [__imp__RegCloseKey@4]
lrs_done:
    ret

.data
hInst:       .long 0
hWndMain:    .long 0
hIcon:       .long 0
oldIcon:    .long 0
hDev:        .long 0
hReg:        .long 0
autoLen:     .long 0
rgbState:    .long 0
rgbKnown:    .byte 0
bootState:   .byte 0
powerState:  .byte 0
oldPowerState: .byte 0
rgbByte:     .byte 0
inpByte:     .byte 0
bytesReturned: .long 0
regDataSize: .long 4
cmdBuf:      .byte 0,0,0,0
iconBitsPtr: .long 0
hColorBmp:   .long 0
hMaskBmp:    .long 0
hPopupMenu:  .long 0
menuOpen:    .byte 0
dxTmp:        .long 0
dyTmp:        .long 0

bmiIcon:
    .long 40
    .long 16
    .long -16
    .short 1
    .short 32
    .long BI_RGB
    .long 1024
    .long 0
    .long 0
    .long 0
    .long 0

iconInfo:
    .long 1,0,0,0,0

maskBits:
    .space 32, 0

wc:
    .long 48
    .long 0
    .long _WndProc@16
    .long 0
    .long 0
    .long 0
    .long 0
    .long 0
    .long 0
    .long 0
    .long className
    .long 0

nid:
    .long NID_SIZE
    .long 0
    .long 1
    .long (NIF_MESSAGE | NIF_ICON | NIF_TIP)
    .long WM_TRAY
    .long 0
    .ascii "TANK03 RGB\0"
    .space 64 - 11, 0

msg: .space 28, 0
pt:  .space 8, 0
exePath:     .space 260, 0
autorunData: .space 264, 0

.section .rdata,"dr"
className:    .asciz "T3R"
wndTitle:     .asciz "T3R"
driverPath:   .asciz "\\\\.\\inpoutx64"
txtHeaderTitle: .asciz "TANK03 RGB Controller"
txtHeaderSub:   .asciz "with Boot Persistence"
txtHeaderGithub:.asciz "github.com/shapeless-kNt"
txtRgbAuto:   .asciz "AUTO"
txtRgbOff:    .asciz "OFF"
txtRgbRainbow:.asciz "RAINBOW"
txtRgbBreath: .asciz "BREATHING"
txtRgbCycle:  .asciz "COLOR CYCLE"
txtPowerSilent:      .asciz "Mode: SILENT"
txtPowerAuto:        .asciz "Mode: AUTO"
txtPowerPerformance: .asciz "Mode: PERFORMANCE"
txtPowerUnknown:     .asciz "Mode: UNKNOWN"
txtBootToggle:       .asciz "Boot Persistence"
txtExit:             .asciz "Exit"
regRunKey:    .asciz "Software\\Microsoft\\Windows\\CurrentVersion\\Run"
regAppKey:    .asciz "Software\\Tank03RgbTray"
runValueName: .asciz "Tank03RgbTray"
rgbValueName: .asciz "RgbState"
dllShell32:   .asciz "SHELL32.dll"
fnShellNotifyIconA: .asciz "Shell_NotifyIconA"

.section .idata$2,"dr"
    .rva ilt_kernel32
    .long 0,0
    .rva name_kernel32
    .rva iat_kernel32

    .rva ilt_user32
    .long 0,0
    .rva name_user32
    .rva iat_user32

    .rva ilt_gdi32
    .long 0,0
    .rva name_gdi32
    .rva iat_gdi32

    .rva ilt_advapi32
    .long 0,0
    .rva name_advapi32
    .rva iat_advapi32

    .long 0,0,0,0,0

.section .idata$4,"dr"
ilt_kernel32:
    .rva hint_ExitProcess
    .rva hint_GetModuleHandleA
    .rva hint_GetModuleFileNameA
    .rva hint_CreateFileA
    .rva hint_DeviceIoControl
    .rva hint_CloseHandle
    .rva hint_GetCurrentProcess
    .rva hint_SetProcessWorkingSetSize
    .rva hint_LoadLibraryA
    .rva hint_GetProcAddress
    .rva hint_FreeLibrary
    .long 0
ilt_user32:
    .rva hint_RegisterClassExA
    .rva hint_CreateWindowExA
    .rva hint_DefWindowProcA
    .rva hint_PostQuitMessage
    .rva hint_GetMessageA
    .rva hint_TranslateMessage
    .rva hint_DispatchMessageA
    .rva hint_SetTimer
    .rva hint_CreateIconIndirect
    .rva hint_DestroyIcon
    .rva hint_CreatePopupMenu
    .rva hint_AppendMenuA
    .rva hint_ModifyMenuA
    .rva hint_SetForegroundWindow
    .rva hint_GetCursorPos
    .rva hint_TrackPopupMenu
    .rva hint_DestroyMenu
    .long 0
ilt_gdi32:
    .rva hint_CreateDIBSection
    .rva hint_CreateBitmap
    .rva hint_DeleteObject
    .long 0
ilt_advapi32:
    .rva hint_RegOpenKeyExA
    .rva hint_RegCreateKeyExA
    .rva hint_RegSetValueExA
    .rva hint_RegDeleteValueA
    .rva hint_RegCloseKey
    .rva hint_RegQueryValueExA
    .long 0

.section .idata$5,"dw"
.global __imp__ExitProcess@4
__imp__ExitProcess@4:
iat_kernel32:
    .rva hint_ExitProcess
.global __imp__GetModuleHandleA@4
__imp__GetModuleHandleA@4:
    .rva hint_GetModuleHandleA
.global __imp__GetModuleFileNameA@12
__imp__GetModuleFileNameA@12:
    .rva hint_GetModuleFileNameA
.global __imp__CreateFileA@28
__imp__CreateFileA@28:
    .rva hint_CreateFileA
.global __imp__DeviceIoControl@32
__imp__DeviceIoControl@32:
    .rva hint_DeviceIoControl
.global __imp__CloseHandle@4
__imp__CloseHandle@4:
    .rva hint_CloseHandle
.global __imp__GetCurrentProcess@0
__imp__GetCurrentProcess@0:
    .rva hint_GetCurrentProcess
.global __imp__SetProcessWorkingSetSize@12
__imp__SetProcessWorkingSetSize@12:
    .rva hint_SetProcessWorkingSetSize
.global __imp__LoadLibraryA@4
__imp__LoadLibraryA@4:
    .rva hint_LoadLibraryA
.global __imp__GetProcAddress@8
__imp__GetProcAddress@8:
    .rva hint_GetProcAddress
.global __imp__FreeLibrary@4
__imp__FreeLibrary@4:
    .rva hint_FreeLibrary
    .long 0

.global __imp__RegisterClassExA@4
__imp__RegisterClassExA@4:
iat_user32:
    .rva hint_RegisterClassExA
.global __imp__CreateWindowExA@48
__imp__CreateWindowExA@48:
    .rva hint_CreateWindowExA
.global __imp__DefWindowProcA@16
__imp__DefWindowProcA@16:
    .rva hint_DefWindowProcA
.global __imp__PostQuitMessage@4
__imp__PostQuitMessage@4:
    .rva hint_PostQuitMessage
.global __imp__GetMessageA@16
__imp__GetMessageA@16:
    .rva hint_GetMessageA
.global __imp__TranslateMessage@4
__imp__TranslateMessage@4:
    .rva hint_TranslateMessage
.global __imp__DispatchMessageA@4
__imp__DispatchMessageA@4:
    .rva hint_DispatchMessageA
.global __imp__SetTimer@16
__imp__SetTimer@16:
    .rva hint_SetTimer
.global __imp__CreateIconIndirect@4
__imp__CreateIconIndirect@4:
    .rva hint_CreateIconIndirect
.global __imp__DestroyIcon@4
__imp__DestroyIcon@4:
    .rva hint_DestroyIcon
.global __imp__CreatePopupMenu@0
__imp__CreatePopupMenu@0:
    .rva hint_CreatePopupMenu
.global __imp__AppendMenuA@16
__imp__AppendMenuA@16:
    .rva hint_AppendMenuA
.global __imp__ModifyMenuA@20
__imp__ModifyMenuA@20:
    .rva hint_ModifyMenuA
.global __imp__SetForegroundWindow@4
__imp__SetForegroundWindow@4:
    .rva hint_SetForegroundWindow
.global __imp__GetCursorPos@4
__imp__GetCursorPos@4:
    .rva hint_GetCursorPos
.global __imp__TrackPopupMenu@28
__imp__TrackPopupMenu@28:
    .rva hint_TrackPopupMenu
.global __imp__DestroyMenu@4
__imp__DestroyMenu@4:
    .rva hint_DestroyMenu
.global __imp__GetSystemMetrics@4
__imp__GetSystemMetrics@4:
.global __imp__DestroyWindow@4
__imp__DestroyWindow@4:
.global __imp__BeginPaint@8
__imp__BeginPaint@8:
.global __imp__EndPaint@8
__imp__EndPaint@8:
.global __imp__FillRect@12
__imp__FillRect@12:
.global __imp__DrawTextA@20
__imp__DrawTextA@20:
    .long 0

.global __imp__CreateDIBSection@24
__imp__CreateDIBSection@24:
iat_gdi32:
    .rva hint_CreateDIBSection
.global __imp__CreateBitmap@20
__imp__CreateBitmap@20:
    .rva hint_CreateBitmap
.global __imp__DeleteObject@4
__imp__DeleteObject@4:
    .rva hint_DeleteObject
.global __imp__CreateSolidBrush@4
__imp__CreateSolidBrush@4:
.global __imp__SetBkMode@8
__imp__SetBkMode@8:
.global __imp__SetTextColor@8
__imp__SetTextColor@8:
    .long 0

.global __imp__RegOpenKeyExA@20
__imp__RegOpenKeyExA@20:
iat_advapi32:
    .rva hint_RegOpenKeyExA
.global __imp__RegCreateKeyExA@36
__imp__RegCreateKeyExA@36:
    .rva hint_RegCreateKeyExA
.global __imp__RegSetValueExA@24
__imp__RegSetValueExA@24:
    .rva hint_RegSetValueExA
.global __imp__RegDeleteValueA@8
__imp__RegDeleteValueA@8:
    .rva hint_RegDeleteValueA
.global __imp__RegCloseKey@4
__imp__RegCloseKey@4:
    .rva hint_RegCloseKey
.global __imp__RegQueryValueExA@24
__imp__RegQueryValueExA@24:
    .rva hint_RegQueryValueExA
    .long 0

.section .idata$6,"dr"
hint_ExitProcess:          .short 0; .asciz "ExitProcess";          .p2align 1,0
hint_GetModuleHandleA:     .short 0; .asciz "GetModuleHandleA";     .p2align 1,0
hint_GetModuleFileNameA:   .short 0; .asciz "GetModuleFileNameA";   .p2align 1,0
hint_CreateFileA:          .short 0; .asciz "CreateFileA";          .p2align 1,0
hint_DeviceIoControl:      .short 0; .asciz "DeviceIoControl";      .p2align 1,0
hint_CloseHandle:          .short 0; .asciz "CloseHandle";          .p2align 1,0
hint_GetCurrentProcess:    .short 0; .asciz "GetCurrentProcess";    .p2align 1,0
hint_SetProcessWorkingSetSize: .short 0; .asciz "SetProcessWorkingSetSize"; .p2align 1,0
hint_LoadLibraryA:         .short 0; .asciz "LoadLibraryA";         .p2align 1,0
hint_GetProcAddress:       .short 0; .asciz "GetProcAddress";       .p2align 1,0
hint_FreeLibrary:          .short 0; .asciz "FreeLibrary";          .p2align 1,0

hint_RegisterClassExA:     .short 0; .asciz "RegisterClassExA";     .p2align 1,0
hint_CreateWindowExA:      .short 0; .asciz "CreateWindowExA";      .p2align 1,0
hint_DefWindowProcA:       .short 0; .asciz "DefWindowProcA";       .p2align 1,0
hint_PostQuitMessage:      .short 0; .asciz "PostQuitMessage";      .p2align 1,0
hint_GetMessageA:          .short 0; .asciz "GetMessageA";          .p2align 1,0
hint_TranslateMessage:     .short 0; .asciz "TranslateMessage";     .p2align 1,0
hint_DispatchMessageA:     .short 0; .asciz "DispatchMessageA";     .p2align 1,0
hint_SetTimer:             .short 0; .asciz "SetTimer";             .p2align 1,0
hint_CreateIconIndirect:   .short 0; .asciz "CreateIconIndirect";   .p2align 1,0
hint_DestroyIcon:          .short 0; .asciz "DestroyIcon";          .p2align 1,0
hint_CreatePopupMenu:      .short 0; .asciz "CreatePopupMenu";      .p2align 1,0
hint_AppendMenuA:          .short 0; .asciz "AppendMenuA";          .p2align 1,0
hint_ModifyMenuA:          .short 0; .asciz "ModifyMenuA";          .p2align 1,0
hint_SetForegroundWindow:  .short 0; .asciz "SetForegroundWindow";  .p2align 1,0
hint_GetCursorPos:         .short 0; .asciz "GetCursorPos";         .p2align 1,0
hint_TrackPopupMenu:       .short 0; .asciz "TrackPopupMenu";       .p2align 1,0
hint_DestroyMenu:          .short 0; .asciz "DestroyMenu";          .p2align 1,0

hint_CreateDIBSection:     .short 0; .asciz "CreateDIBSection";     .p2align 1,0
hint_CreateBitmap:         .short 0; .asciz "CreateBitmap";         .p2align 1,0
hint_DeleteObject:         .short 0; .asciz "DeleteObject";         .p2align 1,0

hint_RegOpenKeyExA:        .short 0; .asciz "RegOpenKeyExA";        .p2align 1,0
hint_RegCreateKeyExA:      .short 0; .asciz "RegCreateKeyExA";      .p2align 1,0
hint_RegSetValueExA:       .short 0; .asciz "RegSetValueExA";       .p2align 1,0
hint_RegDeleteValueA:      .short 0; .asciz "RegDeleteValueA";      .p2align 1,0
hint_RegCloseKey:          .short 0; .asciz "RegCloseKey";          .p2align 1,0
hint_RegQueryValueExA:     .short 0; .asciz "RegQueryValueExA";     .p2align 1,0

name_kernel32: .asciz "KERNEL32.dll"
name_user32:   .asciz "USER32.dll"
name_gdi32:    .asciz "GDI32.dll"
name_advapi32: .asciz "ADVAPI32.dll"

.section .rsrc,"dr"
.p2align 2
rsrc_start:
    .long 0,0
    .short 0,0
    .short 0,1
    .long 24
    .long 0x80000000 | (rsrc_type_manifest - rsrc_start)
rsrc_type_manifest:
    .long 0,0
    .short 0,0
    .short 0,1
    .long 1
    .long 0x80000000 | (rsrc_name_manifest - rsrc_start)
rsrc_name_manifest:
    .long 0,0
    .short 0,0
    .short 0,1
    .long 1033
    .long rsrc_data_entry - rsrc_start
rsrc_data_entry:
    .rva manifest_data
    .long manifest_end - manifest_data
    .long 0
    .long 0
.p2align 2
manifest_data:
    .ascii "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\r\n"
    .ascii "<assembly xmlns=\"urn:schemas-microsoft-com:asm.v1\" manifestVersion=\"1.0\">\r\n"
    .ascii "<dependency><dependentAssembly><assemblyIdentity type=\"win32\" name=\"Microsoft.Windows.Common-Controls\" version=\"6.0.0.0\" processorArchitecture=\"*\" publicKeyToken=\"6595b64144ccf1df\" language=\"*\"/></dependentAssembly></dependency>\r\n"
    .ascii "</assembly>\r\n"
manifest_end:
.p2align 2
