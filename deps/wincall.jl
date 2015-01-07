const INFINITE = 0xFFFFFFFF

typealias HANDLE Ptr{Void}
typealias DWORD Culong
typealias WORD Cushort
typealias LPCTSTR Ptr{Cwchar_t}
typealias LPTSTR Ptr{Cwchar_t}
typealias LPBYTE Ptr{Cuchar}
typealias MSIHANDLE Culong
 
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
 
immutable PROCESS_INFORMATION
    hProcess::HANDLE
    hThread::HANDLE
    dwProcessId::DWORD
    dwThreadId::DWORD
    PROCESS_INFORMATION() = new(C_NULL,C_NULL,C_NULL,C_NULL)
end
 
CreateProcess(cmd) = begin
    si = STARTUPINFO[STARTUPINFO()]
    pi = PROCESS_INFORMATION[PROCESS_INFORMATION()]
    ccall(:CreateProcessW, stdcall, Cint,
         (LPCTSTR, LPTSTR , Ptr{Int}, Ptr{Int}, Cint, DWORD,
          Ptr{Void}, LPCTSTR, Ptr{PROCESS_INFORMATION}, Ptr{STARTUPINFO}),
         C_NULL,
         wstring(cmd),
         C_NULL,
         C_NULL,
         0,
         0,
         C_NULL, C_NULL,
         convert(Ptr{STARTUPINFO}, pointer(si)),
         convert(Ptr{PROCESS_INFORMATION}, pointer(pi)))

    ccall(:WaitForSingleObject, stdcall, Cuint, (Cuint,Cuint), pi[1].hProcess, INFINITE)
end
