# xmake 远程包管理入门

## 缘起

最近在使用 xmake 管理几个新开的 C/C++ 项目, 有一些自建包需求, 但是实话说官方文档里的描述实在太过简略, 或许因知识之诅咒, 有不少重要的东西没有明示, 还有一些最佳实践也只能读官方打包好的东西才能发现. 但是我觉得 xmake 确实是一个很棒的 C/C++ 项目管理工具, 因此在我花了很久大致明白如何使用 xmake 的包管理后, 遂有此文. 

但本文也只是盲人摸象, 作者也可能受到知识诅咒, 如有错误和过于简略之处, 请您指正. 

## 内容块儿

- 说明 xmake 包管理流程
- 提供从零开始的 xmake 远程包编纂流程
- 演示将 apache-arrow 包装为 xmake 远程包

## 概念澄清

> 此部分可以先略读, 等到实战时用到相关概念时再回来详看

### 项目编译方案和项目元信息描述方案

最初人们直接使用编译器命令行直接编译, 如`g++ test.cpp -o test`, 后来有了`makefile`方案, 可以稍微简单地使用`make`命令编译, 后来`make`表达力不足又有了`cmake`和`automake`. 这些东西都是只用来指导如何编译的, 统称做**项目编译方案**. 

但是关于如何获取这些包, 可以通过`手动下载/pacman/apt`等等, 手动下载太麻烦, 系统自带的包管理器不能在各个平台统一, 因此有了`vcpkg/conan/conda/clib`这样的统一的**项目元信息描述方案**, 它们至少描述了项目版本和版本对应的源代码地址. 

xmake 是一个使用 lua 语法的**项目编译方案**, xmake 官方所做的 xrepo 是一个用 xmake 式语法的**项目元信息描述方案**, 即通常所言的包管理方案. 

但是很怪异的是, xrepo 的包相关文档放在了 xmake 文档里, 以至于下面两个概念难以厘清. 


### 远程包和本地包

xmake 中包含两种看起来同级的包

- 远程包
- 本地包

在官方文档里看起来项目可以打包成本地包, 也能打包成远程包, 远程包也能本地使用, 但是远程包/本地包并不能算是同级的. 

在 xmake 语境下, 本地包是总是被一个正常的 xmake 项目生成的**元信息描述方案**, 其内包含: 

- xmake.lua 中包含一个`package(name)`块
- 包含引用时需要的头文件
- 包含编译好的 lib 文件

按官方文档, 其可能的一个文件结构如下

```console
$ tree build/packages/f/foo/
build/packages/f/foo/
├── macosx
│   └── x86_64
│       └── release
│           ├── include
│           │   └── foo.h
│           └── lib
│               └── libfoo.a
└── xmake.lua
```

本地包总是预编译过用 xmake 式语法描述的某个东西. 

但在 xmake 文档语境下, 远程包并不特指`使用 xmake 语法描述`的某种东西. 

远程包只是关于如何获得某个包的描述, 其描述方案可以是 xmake 式的, 也可以是`xrepo/homebrew/vcpkg/conan/conda/pacman/clib`等等等等, xrepo 是 xmake 官方出的一个`万包之包`式的包描述方案, 在安装 xmake 时已经自带. 远程包不包含源代码, 只包含如何获得源代码. xmake 式的远程包通常只包含一个`xmake.lua`文件. 

---

综合来讲, 其关系和工作流程是这样的: 

xmake 可以使用很多包管理器的包描述来辅助某个 `xmake 项目`的编译. 在谈到用 xrepo 安装一个包时, 是指如下过程: 

1. 在包索引中获取某个包的描述
2. 按照**元信息描述方案**(`xrepo/homebrew/vcpkg/conan/conda/pacman/clib`), 解析出元信息
3. 根据元信息下载其源代码
4. 根据元信息里的**编译方案**(`xmake/cmake/makefile/autoconf`)将源代码编译成 lib 文件

第一步中有一些包描述是用 xmake 式语法写出的, 即是 **xmake 远程包**, 也可能是 vcpkg 式描述的. 第四步中的编译流程可能明面上是 xmake 的, 实际上是 xmake 调用其他编译方案的, 也可能是纯 xmake 的或者其他编译方案的. 

例如

1. zlib 是一个古典的项目, 官方钦定编译流程是`./configure; make; make install`, 写得又臭又长, 有四百余行. 其在 xmake 远程包里对应的安装是这样的, 下载官方源代码, 把一个三十余行的 xmake.lua 文件写入源代码根目录, 将其视为一个普通的 xmake 项目预编译 lib 文件. 这个流程我们简称为`xrepo-xmake`系. 
2. 7z 是一个古典的项目, 官方钦定的官方流程是`make`, 在 xmake.lua 里关于此包的安装流程为, 直接调用`make -j -f makefile.gcc`, 可视为`xrepo-make`系. 
3. autoconf 是一个可以使用 autoconf 编译的软件, 因此在 xmake 远程包里安装一步里, 只简单写了`import("package.tools.autoconf").install(package)`, 使用 autoconf 安装, 这个流程我们简称为`xrepo-autoconf`系. 
4. apache-arrow 是一个最近几年出现的内存分析开发平台, 使用的**编译方案**为 cmake, 这个包在 xrepo 中还不存在, 不过可以使用 xrepo 调用 vcpkg 来安装, 因此这个流程可以称为`vcpkg-cmake`系. 

## 从零开始的项目实战


### 创建和编译可执行文件

标准起手式 `xmake create great-project` 来创建一个普通的 xmake 项目, 运行 `xmake` 将会自动检测工具链->下载依赖包->编译, 我分别在 Windows 和 WSL 中运行 xmake. 相关命令如下
```console
$ xmake create great-project
$ cd great-project
$ xmake
checking for platform ... linux
checking for architecture ... x86_64
[ 25%]: ccache compiling.release src/main.cpp
[ 50%]: linking.release great-project
[100%]: build ok!
---
checking for Microsoft Visual Studio (x64) version ... 2019
[ 25%]: compiling.release src\main.cpp
[ 50%]: linking.release great-project.exe
[100%]: build ok!
$ tree .
.
├── build
│   ├── linux
│   │   └── x86_64
│   │       └── release
│   │           └── great-project
│   └── windows
│       └── x64
│           └── release
│               └── great-project.exe
├── src
│   └── main.cpp
└── xmake.lua

8 directories, 4 files
$ ./build/linux/x86_64/release/great-project 
hello world!
$ ./build/windows/x64/release/great-project.exe 
hello world!
```
*以下默认相关操作都在双系统下进行.*


### 修改为库项目

对 xmake.lua 作如下修改
```diff
@@ -1,8 +1,9 @@
 add_rules("mode.debug", "mode.release")
 
 target("great-project")
-    set_kind("binary")
-    add_files("src/*.cpp")
+    set_kind("static")
+    add_headerfiles("src/great-project.h")
+    add_files("src/great-project.cpp")
```

并创建 `great-project.h`, `great-project.cpp`, 内容为:
``` cpp
// great-project.h
double solve(int x, int y);

// great-project.cpp
#include "great-project.h"


double solve(int x, int y) {
    return 1.0 * y / x;
}
```
之后有
```console
$ xmake
[ 25%]: ccache compiling.release src/great-project.cpp
[ 50%]: archiving.release libgreat-project.a
[100%]: build ok!

$ nm -C build/linux/x86_64/release/libgreat-project.a

great-project.cpp.o:
0000000000000000 T solve(int, int)
```

或者

```console
> xmake
[ 25%]: compiling.release src\great-project.cpp
[ 50%]: archiving.release great-project.lib
[100%]: build ok!
> dumpbin /SYMBOLS build\windows\x64\release\great-project.lib
Microsoft (R) COFF/PE Dumper Version 14.29.30038.1
Copyright (C) Microsoft Corporation.  All rights reserved.


Dump of file build\windows\x64\release\great-project.lib

File Type: LIBRARY

COFF SYMBOL TABLE
000 01057556 ABS    notype       Static       | @comp.id
001 80010190 ABS    notype       Static       | @feat.00
002 00000001 ABS    notype       Static       | @vol.md
003 00000000 SECT1  notype       Static       | .drectve
    Section length   2F, #relocs    0, #linenums    0, checksum        0
005 00000000 SECT2  notype       Static       | .debug$S
    Section length   D4, #relocs    0, #linenums    0, checksum        0
007 00000000 SECT3  notype       Static       | .text$mn
    Section length   15, #relocs    0, #linenums    0, checksum   A8C8E0
009 00000000 SECT3  notype ()    External     | ?solve@@YANHH@Z (double __cdecl solve(int,int))
00A 00000000 UNDEF  notype       External     | _fltused
00B 00000000 SECT4  notype       Static       | .chks64
    Section length   20, #relocs    0, #linenums    0, checksum        0

String Table Size = 0x14 bytes

  Summary

          20 .chks64
          D4 .debug$S
          2F .drectve
          15 .text$mn
```

都可以观察到 `solve(int,int)`

### 使用土法导入库

另在库同级之处创建一个项目 great-loader, 并书写如下代码: 
```console 
$ tail -n 100 src/main.cpp xmake.lua
==> src/main.cpp <==
#include <iostream>
#include <great-project.h>


using namespace std;

int main(int argc, char** argv)
{
    cout << "solve(2, 42) = " << solve(2, 42) << endl;
    return 0;
}

==> xmake.lua <==
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
```
土法土在手动`add_linkdirs`, 然后手动`add_links`.  
之后使用`xmake; xmake run` 已经可以看到正确结果了. 

> 此时有一个小技巧, 智能感知工具不会识别 xmake.lua, 但是能识别 CMakeLists, 因此可以运行`xmake project -k cmake`来生成 cmake 文件帮助补全. 

### 打包为本地库

`xmake package`即可, 但是个人感觉没必要使用本地库, 因此略过. 

### 使用远程包

按照官方文档可以直接运行打包命令
```console
$ xmake package -f remote
```
之后得到
```lua
-- build/packages/g/great-project/xmake.lua
package("great-project")
    set_description("The great-project package")

    add_urls("https://github.com/myrepo/foo.git")
    add_versions("1.0", "<shasum256 or gitcommit>")

    on_install(function (package)
        local configs = {}
        if package:config("shared") then
            configs.kind = "shared"
        end
        import("package.tools.xmake").install(package, configs)
    end)

    on_test(function (package)
        -- TODO check includes and interfaces
        -- assert(package:has_cfuncs("foo", {includes = "foo.h"})
    end)

```

原则上, 使用远程包需要两个基础信息, **元信息描述方案**存在哪? 源代码和**编译方案**存在哪? 一般来讲, 元信息在[xmake 官方 Github 仓库](https://github.com/xmake-io/xmake-repo), 源代码和编译方案放在作者的仓库或项目主页. 

现在就是要做一下填空题了, 首先要填`add_urls`, 这里面可以填 git 链接, 也可以填某些下载链接. 

在测试时, 元信息(上面要填空的一大段)也可以放到项目的`xmake.lua`文件中, 毕竟放到远端修改也挺麻烦的, 另外, 在 Linux 下, git 仓库也可以使用 `file://` 从本地克隆, 因此两个东西都可以放到本地去. 

在 great-project 中运行 
```console
git init
git add .
git commit -m "init"
```

给 add_urls 填入新增的 git 仓库的地址, 由于 file 协议里无法出现`..`, 因此将相对路径转为绝对路径, `add_urls("../great-project")`应为`add_urls("file:///mnt/c/Users/myuan/project/xmake-package-example/great-project")`. (Windows 下可以老老实实建一个 Github 仓库然后把 url 放进去)

将其放入 great-loader 项目中的 xmake.lua 中去, 得到如下 xmake.lua 文件:

```diff
@@ -1,14 +1,28 @@
 add_rules("mode.debug", "mode.release")
 
+package("great-project")
+    set_description("The great-project package")
+
+    add_urls("file:///mnt/c/Users/myuan/project/xmake-package-example/great-project")
+
+    on_install(function (package)
+        local configs = {}
+        if package:config("shared") then
+            configs.kind = "shared"
+        end
+        import("package.tools.xmake").install(package, configs)
+    end)
+
+    on_test(function (package)
+        -- TODO check includes and interfaces
+        -- assert(package:has_cfuncs("foo", {includes = "foo.h"})
+    end)
+package_end()
+
+add_requires("great-project")
+
 
 target("great-loader")
     set_kind("binary")
-    add_includedirs("../great-project/src/")
-    if is_os("windows") then 
-        add_linkdirs("../great-project/build/windows/x64/release/")
-    elseif is_os("linux") then 
-        add_linkdirs("../great-project/build/linux/x86_64/release/")
-    end 
-    add_links("great-project")
-
+    add_packages("great-project")
     add_files("src/*.cpp")
```

target 下面清爽了好多, 重新运行
```console
$ xmake 
[ 25%]: ccache compiling.release src/main.cpp
[ 50%]: linking.release great-loader
[100%]: build ok!
$ xmake run
solve(2, 42) = 21
```

## 简单打包 apache-arrow

首先按照官方文档的 cmake 编译流程测试, 完全没有任何额外需要的配置. 复制一份 great-loader, 起名为 arrow-test, C++ 对应的 CMakeLists 在 cpp 目录下, 因此 xmake.lua 文件修改为: 
```diff
@@ -1,17 +1,16 @@
 add_rules("mode.debug", "mode.release")
 
+package("apache-arrow")
+    set_description("Apache arrow")
-package("great-project")
-    set_description("The great-project package")
 
+    add_urls("https://github.com/apache/arrow.git")
-    add_urls("file:///mnt/c/Users/myuan/project/xmake-package-example/great-project")
 
     on_install(function (package)
         local configs = {}
         if package:config("shared") then
             configs.kind = "shared"
         end
+        os.cd("cpp")
+        import("package.tools.cmake").install(package, configs)
-        import("package.tools.xmake").install(package, configs)
     end)
 
     on_test(function (package)
@@ -20,10 +19,10 @@
     end)
 package_end()
 
+add_requires("apache-arrow")
-add_requires("great-project")
 
 
 target("great-loader")
     set_kind("binary")
+    add_packages("apache-arrow")
-    add_packages("great-project")
     add_files("src/*.cpp")
```

至此已经可以简单使用该包了, 从 arrow 的官方示例里找一个`arrow/cpp/examples/arrow/row_wise_conversion_example.cc`, 编译可正常通过, 也可正常运行. 

理论上现在只要把`package("apache-arrow")`到`package_end()`之间的东西提交到 xmake-repo 仓库里去, 别人就可以直接使用此包了. 

## 更多选择的 apache-arrow

在示例中, 一旦尝试更多功能(比如 parquet)就会发现找不到头文件了, 查看 arrow 文档可知, 官方提供了非常多的编译选项来打开或关闭小功能. 

```
-DARROW_COMPUTE=ON: Computational kernel functions and other support

-DARROW_CSV=ON: CSV reader module

-DARROW_CUDA=ON: CUDA integration for GPU development. Depends on NVIDIA CUDA toolkit. The CUDA toolchain used to build the library can be customized by using the $CUDA_HOME environment variable.

-DARROW_DATASET=ON: Dataset API, implies the Filesystem API

-DARROW_FILESYSTEM=ON: Filesystem API for accessing local and remote filesystems

-DARROW_FLIGHT=ON: Arrow Flight RPC system, which depends at least on gRPC

-DARROW_GANDIVA=ON: Gandiva expression compiler, depends on LLVM, Protocol Buffers, and re2

-DARROW_GANDIVA_JAVA=ON: Gandiva JNI bindings for Java

-DARROW_HDFS=ON: Arrow integration with libhdfs for accessing the Hadoop Filesystem

-DARROW_HIVESERVER2=ON: Client library for HiveServer2 database protocol

-DARROW_JSON=ON: JSON reader module

-DARROW_ORC=ON: Arrow integration with Apache ORC

-DARROW_PARQUET=ON: Apache Parquet libraries and Arrow integration

-DARROW_PLASMA=ON: Plasma Shared Memory Object Store

-DARROW_PLASMA_JAVA_CLIENT=ON: Build Java client for Plasma

-DARROW_PYTHON=ON: Arrow Python C++ integration library (required for building pyarrow). This library must be built against the same Python version for which you are building pyarrow. NumPy must also be installed. Enabling this option also enables ARROW_COMPUTE, ARROW_CSV, ARROW_DATASET, ARROW_FILESYSTEM, ARROW_HDFS, and ARROW_JSON.

-DARROW_S3=ON: Support for Amazon S3-compatible filesystems

-DARROW_WITH_BZ2=ON: Build support for BZ2 compression

-DARROW_WITH_ZLIB=ON: Build support for zlib (gzip) compression

-DARROW_WITH_LZ4=ON: Build support for lz4 compression

-DARROW_WITH_SNAPPY=ON: Build support for Snappy compression

-DARROW_WITH_ZSTD=ON: Build support for ZSTD compression

-DARROW_WITH_BROTLI=ON: Build support for Brotli compression

```

要想给 CMake 传递参数, 应当首先配置 add_configs, 之后使用 on_install 中的 config. 一个从官方包里拔出来的使用方式如下: 
```lua
on_install("macosx", "linux", "windows", function (package)
    local configs = {"-DCMAKE_CXX_STANDARD=17"}
    table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:debug() and "Debug" or "Release"))
    table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
    import("package.tools.cmake").install(package, configs, {buildir = os.tmpfile() .. ".dir"})
end)
```

至于在添加包时添加要求, 可以在此处添加
```lua
add_requires("fmt", {configs = {cxflags = "-fPIC"}})
```
之后可以通过
```lua
package:config(config_name)
```
来获取配置, 因此可得如下更新

```diff
@@ -4,12 +4,18 @@
     set_description("Apache arrow")
 
     add_urls("https://github.com/apache/arrow.git")
+    add_configs("components", {description = "开关可选组件, 组件用逗号分隔, 可选内容参考https://arrow.apache.org/docs/developers/cpp/building.html#optional-components", default = "csv,parquet"})
 
     on_install(function (package)
         local configs = {}
+
         if package:config("shared") then
             configs.kind = "shared"
         end
+        for name in string.gmatch(package:config("components"), "[%w|_]+") do
+            table.insert(configs, string.format("-DARROW_%s=ON", string.upper(name)))
+        end
+
         os.cd("cpp")
         import("package.tools.cmake").install(package, configs)
     end)
@@ -20,7 +26,7 @@
     end)
 package_end()
 
-add_requires("apache-arrow")
+add_requires("apache-arrow", {configs = {components = "parquet,csv,compute"}})
 
 
 target("great-loader")
```

至此已经可以指定各个组件了, 按照惯例还应该在 on_test 中添加一个测试用例, 保证安装成功, 给编译添加 debug release 选项等等, 这些已经与本文核心关联不大了, 忽略. 当前的 xmake.lua 内容为: 

```lua
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

```

文件结构为:
```console
$ tree .
.
├── arrow-test
│   ├── build
│   │   └── linux
│   │       └── x86_64
│   │           └── release
│   │               └── great-loader
│   ├── CMakeLists.txt
│   ├── src
│   │   └── main.cpp
│   └── xmake.lua
├── great-loader
│   ├── build
│   │   └── linux
│   │       └── x86_64
│   │           └── release
│   │               └── great-loader
│   ├── CMakeLists.txt
│   ├── source.tmp
│   │   └── great-project
│   │       ├── src
│   │       │   ├── great-project.cpp
│   │       │   └── great-project.h
│   │       ├── xmake copy.lua
│   │       └── xmake.lua
│   ├── src
│   │   └── main.cpp
│   └── xmake.lua
├── great-project
|   ├── .git 
│   ├── build
│   │   └── packages
│   │       └── g
│   │           └── great-project
│   │               └── xmake.lua
│   ├── src
│   │   ├── great-project.cpp
│   │   └── great-project.h
│   └── xmake.lua
└── readme.md

27 directories, 23 files
```