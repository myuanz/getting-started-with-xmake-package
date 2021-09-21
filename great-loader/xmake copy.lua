add_rules("mode.debug", "mode.release")


target("great-loader")
    set_kind("binary")
    add_includedirs("../great-project/src/")
    if is_os("windows") then 
        add_linkdirs("../great-project/build/windows/x64/release/")
    elseif is_os("linux") then 
        add_linkdirs("../great-project/build/linux/x86_64/release/")
    end 
    add_links("great-project")

    add_files("src/*.cpp")
