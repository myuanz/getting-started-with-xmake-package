add_rules("mode.debug", "mode.release")

package("great-project")
    set_description("The great-project package")

    add_urls("file:///mnt/c/Users/myuan/project/xmake-package-example/great-project")
    add_configs("components", {description = "开关可选组件, 组件用逗号分隔, 可选内容参考https://arrow.apache.org/docs/developers/cpp/building.html#optional-components", default = "csv,parquet"})

    on_install(function (package)
        print("package:configs()", package:configs())
        local configs = {}
        if package:config("shared") then
            configs.kind = "shared"
        end
        for name in string.gmatch(package:config("components"), "[%w]+") do
            print('>', name, string.format("-DARROW_%s=ON", string.upper(name)))
            table.insert(configs, string.format("-DARROW_%s=ON", string.upper(name)))
        end


        import("package.tools.xmake").install(package, configs)
    end)

    on_test(function (package)
        -- TODO check includes and interfaces
        -- assert(package:has_cfuncs("foo", {includes = "foo.h"})
    end)
package_end()

add_requires("great-project", {configs = {asd = "zxc", shared = false , test = "zxc", cxflags = "-fPIC", swdergf="zdxfvc"}, test = "qwe"})


target("great-loader")
    set_kind("binary")
    add_packages("great-project")
    add_files("src/*.cpp")
