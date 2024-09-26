# Copyright 2024 The Bazel Authors. All rights reserved.
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
"""Implementation of PyInfo provider and PyInfo-specific utilities."""

load(":util.bzl", "define_bazel_6_provider")

def _check_arg_type(name, required_type, value):
    """Check that a value is of an expected type."""
    value_type = type(value)
    if value_type != required_type:
        fail("parameter '{}' got value of type '{}', want '{}'".format(
            name,
            value_type,
            required_type,
        ))

def _PyInfo_init(
        *,
        transitive_sources,
        uses_shared_libraries = False,
        imports = depset(),
        has_py2_only_sources = False,
        has_py3_only_sources = False,
        direct_pyc_files = depset(),
        transitive_pyc_files = depset()):
    _check_arg_type("transitive_sources", "depset", transitive_sources)

    # Verify it's postorder compatible, but retain is original ordering.
    depset(transitive = [transitive_sources], order = "postorder")

    _check_arg_type("uses_shared_libraries", "bool", uses_shared_libraries)
    _check_arg_type("imports", "depset", imports)
    _check_arg_type("has_py2_only_sources", "bool", has_py2_only_sources)
    _check_arg_type("has_py3_only_sources", "bool", has_py3_only_sources)
    _check_arg_type("direct_pyc_files", "depset", direct_pyc_files)
    _check_arg_type("transitive_pyc_files", "depset", transitive_pyc_files)

    return {
        "direct_pyc_files": direct_pyc_files,
        "has_py2_only_sources": has_py2_only_sources,
        "has_py3_only_sources": has_py2_only_sources,
        "imports": imports,
        "transitive_pyc_files": transitive_pyc_files,
        "transitive_sources": transitive_sources,
        "uses_shared_libraries": uses_shared_libraries,
    }

PyInfo, _unused_raw_py_info_ctor = define_bazel_6_provider(
    doc = "Encapsulates information provided by the Python rules.",
    init = _PyInfo_init,
    fields = {
        "direct_pyc_files": """
:type: depset[File]

Precompiled Python files that are considered directly provided
by the target and **must be included**.

These files usually come from, e.g., a library setting {attr}`precompile=enabled`
to forcibly enable precompiling for itself. Downstream binaries are expected
to always include these files, as the originating target expects them to exist.
""",
        "has_py2_only_sources": """
:type: bool

Whether any of this target's transitive sources requires a Python 2 runtime.
""",
        "has_py3_only_sources": """
:type: bool

Whether any of this target's transitive sources requires a Python 3 runtime.
""",
        "imports": """\
:type: depset[str]

A depset of import path strings to be added to the `PYTHONPATH` of executable
Python targets. These are accumulated from the transitive `deps`.
The order of the depset is not guaranteed and may be changed in the future. It
is recommended to use `default` order (the default).
""",
        "transitive_pyc_files": """
:type: depset[File]

The transitive set of precompiled files that must be included.

These files usually come from, e.g., a library setting {attr}`precompile=enabled`
to forcibly enable precompiling for itself. Downstream binaries are expected
to always include these files, as the originating target expects them to exist.
""",
        "transitive_sources": """\
:type: depset[File]

A (`postorder`-compatible) depset of `.py` files appearing in the target's
`srcs` and the `srcs` of the target's transitive `deps`.
""",
        "uses_shared_libraries": """
:type: bool

Whether any of this target's transitive `deps` has a shared library file (such
as a `.so` file).

This field is currently unused in Bazel and may go away in the future.
""",
    },
)