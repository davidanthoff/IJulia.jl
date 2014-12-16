# return (ipython, version) tuple, where ipython is the string of the
# IPython executable, and version is the VersionNumber.
function find_ipython()
    if @windows? true : false
        ipycmds = (normpath(Pkg.dir("IJulia"),"deps", "usr", "python34", "scripts", "ipython.exe"),)
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

# set c.$s in prof file to val, or nothing if it is already set
# unless overwrite is true
function add_config(profdir::String, prof::String, s::String, val, overwrite=false)
    p = joinpath(profdir, prof)
    r = Regex(string("^[ \\t]*c\\.", replace(s, r"\.", "\\."), "\\s*=.*\$"), "m")
    if isfile(p)
        c = readall(p)
        if ismatch(r, c)
            m = replace(match(r, c).match, r"\s*$", "")
            if !overwrite || m[search(m,'c'):end] == "c.$s = $val"
                eprintln("(Existing $s setting in $prof is untouched.)")
            else
                eprintln("Changing $s to $val in $prof...")
                open(p, "w") do f
                    print(f, replace(c, r, old -> "# $old"))
                    print(f, """
c.$s = $val
""")
                end
            end
        else
            eprintln("Adding $s = $val to $prof...")
            open(p, "a") do f
                print(f, """

c.$s = $val
""")
            end
        end
    else
        eprintln("Creating $prof with $s = $val...")
        open(p, "w") do f
            print(f, """
c = get_config()
c.$s = $val
""")
        end
    end
end
