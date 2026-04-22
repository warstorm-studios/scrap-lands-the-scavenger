# Guidelines

This file will document how to format your code for this repo.  
Before starting, just know that you should always sign your commits. This can be
done in git with the `-s` flag.

## 1) Legal info

Before we start talking about actual code, there are 2 things you need to make
sure you never forget to do:

1. Put a license header on top of a file if you created it, or add your name to
   the file if you only edited it. The license header can be found in the
   `LICENSE_HEADER` file.
2. Put your username in `CONTRIBUTORS.md`

## 2) Usage of AI/LLMs

If you ever for some reason decide to use an AI or an LLM to "help" you in your
code, you must put a comment at the top of the file (under the license header
directly) that should look like this:

```
An AI/LLM with the name of <NAME OF AI/LLM> has been used in the
development/maintenance of this file. Specifically:
func1()
func2()
...
var1
var2
...
```

Where `func1()`, `func2()`, `var1`, `var2` are the symbols that the AI/LLM
created and/or edited.

## 3) Comments

First of all, in the GDScript source, multi-line comments are not allowed. I'm
talking about these:

```
"""
...
"""
```

Always use single-line comments `# ...`. Be sure to follow these rules:

1. A single space must be inserted after the hash `#`.
2. The column limit for each comment is **80 columns**, if your comment is any
   longer then you must create another comment under it continuing it.
3. Comments with differnet topics must have a line between them. Comments that
   are directly under each other must be of the same paragraph/sentence. If they
   have an empty comment between them, they are still considered of the same
   topic.
4. Comments must always be on their own lines, do not put a comment next to code
   `a := 0 # init a`.

One last thing you should know when doing comments is documentation. If you had
a function `f()` you must have this style of comment on the top to explain the
function, its parameters, its return, and what it does:

```gdscript
# function_name(): brief explanation of what the function does.
# arg1: Describe the first arg.
# arg2: Describe the second arg.
# return: Describe the returned value of the function
#
# A longer, more detailed explanation of the function and its side effects here.
```

```gdscript
# add(): Adds two integers.
# a: The first integer to add.
# b: The second integer to add.
# return: The sum of the two integers provided.
#
# This function will add the two integers provided and will set the global
# variable 'res_buf' to their sum.
func add(a: int, b: int) -> int:
        res_buf = a + b
        return a + b
```

## 4) Formatting

There isn't much to say here, just follow these rules:

1. Tabs must be tabs. Not spaces.
2. All code must never go over the 80 column limit, if it does, break it down
   into multiple lines. This does not apply, however, to strings. No string must
   be broken up.
3. If you have multiple initializations on the same line, align them. The equals
   `=`/`:=` character must be aligned:

```gdscript
short_name               := 0
very_very_very_long_name := ":3"
```

4. If your function has so many arguments they go over the column limit, align
   them too:

```gdscript
func function(a: int, b: int, c: int, d: int, e: int, f: int, g: int, h: int,
              i: int, j: int) -> void:
        ...
```

5. All code must make use of GDScript's **static typing**, avoid dynamic typing
   at all costs. Every variable declaration must use `:=` for type inference or
   `: type = ` for explicit typing, every function must have a `->` to indicate
   the return type.
6. Make sure there are no lines with trailing space in them.
7. Do not add spaces around function calls. E.g.,
```gdscript
a := myfunc( 1, 3 )
```

## 5) How to submit

You NEVER want to commit to `main`. Instead, you do one of these depending on
who you are:

- If you're a random contributor: First of all, thanks, we appreciate it.
    Second, what you want to do to contribute is to fork the repo and do what
    you want there.
- If you're a maintainer: You will be given permission to create branches, you
    should create a branch with this style of naming:

1. If you're adding a feature, the branch should be named `feature/`
2. If you're doing a bug fix, the branch should be named `bug/`
3. If you're editing documentation, the branch should be named `docs/`
4. If you're refactoring a part of the project, the branch should be named
   `refactor/`
5. If you're rewriting some parts to increase performance, the branch should be
   named `perf/`.

After the `/`, you should put a description of whatever you're doing. Examples:

- `feature/add-level-90`
- `bug/projectiles-phase-through-blocks`
- `docs/edit-readme`
- `refactor/simplify-player-objects`
- `perf/optimize-projectile-generation`

Once you finished doing what you wanted to do, make a PR (Pull Request) and
someone will review it and give you feedback.
