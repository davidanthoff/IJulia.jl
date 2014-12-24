include("wincall.jl")
# TODO: Build IPython 1.0 dependency? (wait for release?)

#######################################################################

# print to stderr, since that is where Pkg prints its messages
eprintln(x...) = println(STDERR, x...)

juliaprofiles = Array(String,0)

if @windows? true : false
    downloadsdir = "downloads"
    pyinstalldir = normpath(pwd(),"usr","python34")

    if ispath(downloadsdir)
        run(`cmd /C RD "$(normpath(pwd(),downloadsdir))" /S /Q`)
    end
    mkdir(downloadsdir)

    minicondafilename = normpath(downloadsdir,"Miniconda3-3.7.0-Windows-x86.exe")
    getpipfilename = normpath(downloadsdir,"get-pip.py")
    download("http://repo.continuum.io/miniconda/Miniconda3-3.7.0-Windows-x86.exe", "$minicondafilename")
    download("https://bootstrap.pypa.io/get-pip.py", "$getpipfilename")

    if ispath(pyinstalldir)
        run(`cmd /C RD "$(normpath(pwd(),"usr"))" /S /Q`)
    end
    #CreateProcess("$minicondafilename /AddToPath=0 /RegisterPython=0 /S /D=\"$pyinstalldir\"")
    run(`$minicondafilename /AddToPath=0 /RegisterPython=0 /S /D=$pyinstalldir`)

    pythonexepath = normpath(pyinstalldir,"python.exe")

    piperrorlogfile = normpath(pwd(),"usr","logs","piperrorlog.txt")
    piplogfile = normpath(pwd(),"usr","logs","piplog.txt")
    mkdir(normpath(pwd(),"usr","logs"))
    run(`$pythonexepath $getpipfilename`)
    run(`$pythonexepath -m pip install -qqq --log-file $piperrorlogfile --log $piplogfile pyzmq==14.4.1`)
    run(`$pythonexepath -m pip install -qqq --log-file $piperrorlogfile --log $piplogfile Jinja2==2.7.3`)
    run(`$pythonexepath -m pip install -qqq --log-file $piperrorlogfile --log $piplogfile tornado==4.0.2`)
    run(`$pythonexepath -m pip install -qqq --log-file $piperrorlogfile --log $piplogfile ipython==2.3.1`)

    ijuliaprofiledir = "$(pwd())\\usr\\.ijulia"
    ipythonexepath = "$pyinstalldir\\scripts\\ipython.exe"
    run(`$ipythonexepath profile create --ipython-dir="$ijuliaprofiledir"`)

    internaljuliaprof = chomp(readall(`$ipythonexepath locate profile --ipython-dir="$ijuliaprofiledir"`))
    push!(juliaprofiles, internaljuliaprof)
end

include("ipython.jl")
const ipython, ipyvers = find_ipython()

if ipython==nothing
    if length(juliaprofiles)==0
        error("IPython 1.0 or later is required for IJulia")
    else
        eprintln("No system IPython found, using private IPython.")
    end
elseif ipyvers < v"1.0.0-dev"
    if length(juliaprofiles)==0
        error("IPython 1.0 or later is required for IJulia")
    else
        eprintln("IPython 1.0 or later is required for system IJulia, got $ipyvers instead. Skipped integration with system IPython.")
    end
else
    eprintln("Found IPython version $ipyvers ... ok.")

    # create julia profile (no-op if we already have one)
    eprintln("Creating julia profile in IPython...")
    run(`$ipython profile create julia`)

    systemjuliaprof = chomp(readall(`$ipython locate profile julia`))
    push!(juliaprofiles, systemjuliaprof)
end

rb(filename::String) = open(readbytes, filename)
eqb(a::Vector{Uint8}, b::Vector{Uint8}) =
    length(a) == length(b) && all(a .== b)


# copy IJulia/deps/src to destpath/destname if it doesn't
# already exist at the destination, or if it has changed (if overwrite=true).
function copy_config(src::String, destpath::String,
                     destname::String=src, overwrite=true)
    mkpath(destpath)
    dest = joinpath(destpath, destname)
    srcbytes = rb(joinpath(Pkg.dir("IJulia"), "deps", src))
    if !isfile(dest) || (overwrite && !eqb(srcbytes, rb(dest)))
        eprintln("Copying $src to Julia IPython profile.")
        open(dest, "w") do f
            write(f, srcbytes)
        end
    else
        eprintln("(Existing $destname file untouched.)")
    end
end

function createijuliaprofile(juliaprof::String)

    # add Julia kernel manager if we don't have one yet
    if VERSION >= v"0.3-"
        binary_name = "julia"
    else
        binary_name = "julia-basic"
    end

    add_config(juliaprof, "ipython_config.py", "KernelManager.kernel_cmd",
           VERSION >= v"0.3"?
            """["$(escape_string(joinpath(JULIA_HOME,(@windows? "julia.exe":"$binary_name"))))", "-i", "-F", "$(escape_string(joinpath(Pkg.dir("IJulia"),"src","kernel.jl")))", "{connection_file}"]""":
            """["$(escape_string(joinpath(JULIA_HOME,(@windows? "julia.bat":"$binary_name"))))", "-F", "$(escape_string(joinpath(Pkg.dir("IJulia"),"src","kernel.jl")))", "{connection_file}"]""",
           true)

    # make qtconsole require shift-enter to complete input
    add_config(juliaprof, "ipython_qtconsole_config.py",
           "IPythonWidget.execute_on_complete_input", "False")

    add_config(juliaprof, "ipython_qtconsole_config.py",
           "FrontendWidget.lexer_class", "'pygments.lexers.JuliaLexer'")

    # set Julia notebook to use a different port than IPython's 8888 by default
    add_config(juliaprof, "ipython_notebook_config.py", "NotebookApp.port", 8998)

    #######################################################################
    # Copying files into the correct paths in the profile lets us override
    # the files of the same name in IPython.

    # copy IJulia icon to profile so that IPython will use it
    for T in ("png", "svg")
        copy_config("ijulialogo.$T",
                joinpath(juliaprof, "static", "base", "images"),
                "ipynblogo.$T")
    end

    # copy IJulia favicon to profile
    copy_config("ijuliafavicon.ico",
            joinpath(juliaprof, "static", "base", "images"),
            "favicon.ico")

    # custom.js can contain custom js login that will be loaded
    # with the notebook to add info and/or monkey-patch some javascript
    # -- e.g. we use it to add .ipynb metadata that this is a Julia notebook
    copy_config("custom.js", joinpath(juliaprof, "static", "custom"))

    # julia.js implements a CodeMirror mode for Julia syntax highlighting in the notebook.
    # Eventually this will ship with CodeMirror and hence IPython, but for now we manually bundle it.

    copy_config("julia.js", joinpath(juliaprof, "static", "components", "codemirror", "mode", "julia"))
end

#######################################################################
# Create Julia profiles for IPython and fix the config options.

for profiledir in juliaprofiles
    createijuliaprofile(profiledir)
end
