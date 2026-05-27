const std = @import("std");

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    // Standard target options allow the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    // It's also possible to define more custom flags to toggle optional features
    // of this build script using `b.option()`. All defined flags (including
    // target and optimize options) will be listed when running `zig build --help`
    // in this directory.

    // This creates a module, which represents a collection of source files alongside
    // some compilation options, such as optimization mode and linked system libraries.
    // Zig modules are the preferred way of making Zig code available to consumers.
    // addModule defines a module that we intend to make available for importing
    // to our consumers. We must give it a name because a Zig package can expose
    // multiple modules and consumers will need to be able to specify which
    // module they want to access.

    const mod = b.addModule("GapBuffer", .{
        .root_source_file = b.path("src/GapBuffer.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const lib_static = b.addLibrary(.{
        .linkage = .static,
        .name = "gapbuffer",
        .root_module = mod,
    });

    b.installArtifact(lib_static);

    const lib_shared = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "gapbuffer",
        .root_module = mod,
    });

    b.installArtifact(lib_shared);

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    const examples_step = b.step("examples", "Build all examples");

    // 1. C Example (使用 Zig 内置的 C 编译器)
    const c_example = b.addExecutable(.{
        .name = "c_example",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    c_example.root_module.addCSourceFile(.{
        .file = b.path("examples/c/main.c"),
        .flags = &.{},
    });
    c_example.root_module.linkLibrary(lib_static);
    const install_c_example = b.addInstallArtifact(c_example, .{});
    examples_step.dependOn(&install_c_example.step);

    // 2. C++ Example (使用 Zig 内置的 C++ 编译器)
    const cpp_example = b.addExecutable(.{
        .name = "cpp_example",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        }),
    });
    cpp_example.root_module.addCSourceFile(.{
        .file = b.path("examples/cpp/main.cpp"),
        .flags = &.{"-std=c++11"},
    });
    cpp_example.root_module.linkLibrary(lib_static);
    const install_cpp_example = b.addInstallArtifact(cpp_example, .{});
    examples_step.dependOn(&install_cpp_example.step);

    // 3. Rust Example (通过系统命令调用 rustc)
    const rustc_cmd = b.addSystemCommand(&.{
        "rustc",
        "examples/rust/main.rs",
        "--crate-name",
        "rust_example",
        "-L",
        "zig-out/lib",
        "-l",
        "gapbuffer",
        "--out-dir",
        "zig-out/bin",
    });
    // 确保静态库先被安装到 zig-out/lib，然后再跑 rustc
    rustc_cmd.step.dependOn(b.getInstallStep());
    examples_step.dependOn(&rustc_cmd.step);
}
