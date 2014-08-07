# return (ipython, version) tuple, where ipython is the string of the
# IPython executable, and version is the VersionNumber.
function find_ipython()
    if @windows? true : false
        ipycmds = (normpath(Pkg.dir("IJulia"),"deps", "usr", "python27", "scripts", "ipython.exe"),)
    else
        ipycmds = ("ipython", "ipython2", "ipython3")
    end

    for ipy in ipycmds
        try
            return (ipy, convert(VersionNumber, chomp(readall(`$ipy --version`))))
        end
    end
    error("IPython is required for IJulia")
end
