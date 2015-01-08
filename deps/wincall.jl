const INFINITE = 0xFFFFFFFF

typealias BOOL Cint
typealias HANDLE Ptr{Void}
typealias DWORD Culong
typealias WORD Cushort
typealias LPCTSTR Ptr{Cwchar_t}
typealias LPTSTR Ptr{Cwchar_t}
typealias LPBYTE Ptr{Cuchar}
typealias LPSECURITY_ATTRIBUTES Ptr{Int}
typealias LPVOID Ptr{Void}

immutable STARTUPINFO
    cb::DWORD
    lpReserved::LPTSTR
    lpDesktop::LPTSTR
    lpTitle::LPTSTR
    dwX::DWORD
    dwY::DWORD
    dwXSize::DWORD
    dwYSize::DWORD
    dwXCountChars::DWORD
    dwYCountChars::DWORD
    dwFillAttribute::DWORD
    dwFlags::DWORD
    wShowWindow::WORD
    cbReserved2::WORD
    lpReserved2::LPBYTE
    hStdInput::HANDLE
    hStdOutput::HANDLE
    hStdError::HANDLE
    STARTUPINFO() = new(
        sizeof(STARTUPINFO),
        C_NULL,
        C_NULL,
        C_NULL,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        C_NULL,
        C_NULL,
        C_NULL,
        C_NULL)
end

typealias LPSTARTUPINFO Ptr{STARTUPINFO}

immutable PROCESS_INFORMATION
    hProcess::HANDLE
    hThread::HANDLE
    dwProcessId::DWORD
    dwThreadId::DWORD
    PROCESS_INFORMATION() = new(C_NULL,C_NULL,C_NULL,C_NULL)
end

typealias LPPROCESS_INFORMATION Ptr{PROCESS_INFORMATION}

function CreateProcess(cmd)
    si = STARTUPINFO[STARTUPINFO()]
    pi = PROCESS_INFORMATION[PROCESS_INFORMATION()]
    ret1 = ccall(:CreateProcessW, stdcall, BOOL,
         (LPCTSTR, LPTSTR, LPSECURITY_ATTRIBUTES, LPSECURITY_ATTRIBUTES, BOOL, DWORD,
          LPVOID, LPCTSTR, LPSTARTUPINFO, LPPROCESS_INFORMATION),
         C_NULL,
         wstring(cmd),
         C_NULL,
         C_NULL,
         0,
         0,
         C_NULL, C_NULL,
         convert(LPSTARTUPINFO, pointer(si)),
         convert(LPPROCESS_INFORMATION, pointer(pi)))
    ret1 == 0 && error("CreateProcess call failed.")

    ret2 = ccall(:WaitForSingleObject, stdcall, DWORD, (HANDLE,DWORD), pi[1].hProcess, INFINITE)
    ret2 != 0 && error("WaitForSingleObject call failed.")
end
