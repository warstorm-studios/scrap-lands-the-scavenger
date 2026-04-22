```
List of maintainers
===================

This list contains the maintainers for this repo. Please use this list to find
the correct person to review your code.

Submissions must follow the style described in the CONTRIBUTING.md.
Maintainers are encouraged to reject any code that violates the official style
guidelines.

Description of section entries and preferred order
--------------------------------------------------

        M: Mail patches to: Full Name <address@domain>
        R: Desginated reviewer: Full Name <address@domain>
           These reviewers should be CCed on patches.
        S: Status, one of:
           Supported:  Someone is paid to look after this.
           Maintained: Someone looks after this.
           Odd Fixes:  It has a maintainer but they don't have time to do much
                       much other than throw the odd patch in.
           Orphan:     No current maintainer (but maybe you could take the role
                       as you write your new code).
           Obsolete:   Old code. Something tagged obsolete generally means it
                       has been replaced by a better system and you should be
                       using that.
        F: Files and directories wildcard patterns.
           A trailing slash includes all files and subdirectory files.
           F: assets/music/   all files in and below assets/music.
           F: assets/music/*  all files in assets/music, but not below.
           F: */music/*       all files in "any top level directory"/music.
           F: src/**/*foo*.gd all *foo*.gd files in any subdirectory of src.
           One pattern per line. Multiple F: lines acceptable.
        X: Excluded files and directories that are NOT maintained, same rules as
           F:. Files exclusions are tested before file matches.
           Can be useful for excluding a specific subdirectory, for instance:
           F: src/
           X: src/perf/

Maintainers list
----------------

NOTE: When reading this file, please look for the most precise areas first. When
      adding to this list, please keep the entries in alphabetical order.

GAMEPLAY
M: Lior Gonda <Lior.Gonda@gmail.com>
S: Maintained
F: assets/

OPTIMIZATIONS AND FFI
M: Muhammad Al-Sarraf <m1829js@gmail.com>
S: Maintained
F: src/perf/
F: src/ffi/
```
