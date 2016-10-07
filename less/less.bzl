# Copyright 2015 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LESS_FILETYPES = FileType([
    ".less",
    ])

def collect_transitive_sources(ctx):
    source_files = set(order="compile")
    for dep in ctx.attr.deps:
        source_files += dep.transitive_less_files
    return source_files

def _less_library_impl(ctx):
    transitive_sources = collect_transitive_sources(ctx)
    transitive_sources += LESS_FILETYPES.filter(ctx.files.srcs)
    return struct(
        files = set(),
        transitive_less_files = transitive_sources)

def _less_binary_impl(ctx):
    transitive_sources = collect_transitive_sources(ctx)

    lessc = ctx.executable._lessc

    options = []
    css_files = []

    if ctx.attr.compress:
        options.append("--compress")
    for src in ctx.files.srcs:
        css_path = src.path.rstrip("less") + "css";
        css_file = ctx.new_file(css_path)
        ctx.action(
            inputs = [lessc, src],
            executable = lessc,
            arguments = options + [ src.path, src.path ],
            mnemonic = "LessCompiler",
            progress_message = "Compiling " + src.basename + " to " + css_file.basename,
            outputs = [ css_file ],
        )
        css_files += [ css_file ]
    return struct(files=set(css_files))

less_deps_attr = attr.label_list(
    providers = ["transitive_less_files"],
    allow_files = False,
)

less_library = rule(
    attrs = {
        "srcs": attr.label_list(
            allow_files = LESS_FILETYPES,
            mandatory = True,
        ),
        "deps": less_deps_attr,
    },
    implementation = _less_library_impl,
)

less_binary = rule(
    attrs = {
        "srcs": attr.label_list(
            allow_files = LESS_FILETYPES,
            mandatory = True,
        ),
        "compress": attr.bool(default=True),
        "deps": less_deps_attr,
        "_lessc": attr.label(
            default = Label("@lessc//less-cli:lessc"),
            executable = True,
            cfg = "host",
        ),
    },
    implementation = _less_binary_impl,
)

def less_repositories():
    native.git_repository(
        name = "lessc",
        remote = "https://github.com/SalzzZ/less-compiler.git",
        commit = "ce9aa86ad2375856c4e0c24040799bb94fabad79",
    )
    native.maven_jar(
        name = "net_sourceforge_argparse4j_argparse4j",
        artifact = "net.sourceforge.argparse4j:argparse4j:0.7.0",
    )
