add_rules("mode.debug", "mode.release")

package("apache-arrow")
    set_description("Apache arrow")

    add_urls("https://github.com/apache/arrow.git")
    add_configs("components", {description = "开关可选组件, 组件用逗号分隔, 可选内容参考https://arrow.apache.org/docs/developers/cpp/building.html#optional-components", default = "csv,parquet"})

    on_install(function (package)
        local configs = {}

        if package:config("shared") then
            configs.kind = "shared"
        end
        for name in string.gmatch(package:config("components"), "[%w|_]+") do
            table.insert(configs, string.format("-DARROW_%s=ON", string.upper(name)))
        end

        os.cd("cpp")
        import("package.tools.cmake").install(package, configs)
    end)

    on_test(function (package)
        -- TODO check includes and interfaces
        -- assert(package:has_cfuncs("foo", {includes = "foo.h"})
    end)
package_end()

add_requires("apache-arrow", {configs = {components = "parquet,csv,compute"}})


target("great-loader")
    set_kind("binary")
    add_packages("apache-arrow")
    add_files("src/*.cpp")
