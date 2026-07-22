# Turtle Script Language

The turtle script language is a small, token-based scripting language used by the turtle runtime. Programs are written as whitespace-separated tokens and are executed from left to right.

## Program structure

A script is made of commands and control-flow markers. Each command is either:

- a built-in/native command registered by the runtime, or
- a user-defined procedure.

## Simple commands

A single command is written as a plain word:

```text
foo
```

A command can be repeated by appending a count:

```text
foo 2
```

This runs `foo` twice.

If a command is registered to take one argument, it can be called like this:

```text
foo bar
```

The argument is passed to the command as a single token. A command can also be called with both an argument and a count:

```text
foo bar 2
```

This runs `foo` twice, passing `bar` as the argument each time.

## Definitions

You can define a procedure with `:name ... ;`:

```text
:f foo ;
f
```

The body of the definition runs until the matching `;`.

## Blocks and repetition

A block is written with square brackets:

```text
[ foo ]
```

A count can follow the block to repeat it:

```text
[ foo ] 2
```

This runs `foo` twice.

## Failure-aware control flow

The language has a few modifiers that change how commands behave when they fail.

### Optional execution

Use `?` to make a command optional:

```text
foo ?
```

If `foo` fails, execution continues as though the failure were ignored.

### Repeat until failure

Use `!` to repeat a command until it fails:

```text
foo ! bar
```

This runs `foo` repeatedly until it fails. If the failure happens, execution stops and later commands (such as `bar`) are not executed.

### Count iterations until failure

Use `#name` to repeat a command until it fails and store the number of successful iterations in a variable:

```text
foo #a bar
```

If `foo` succeeds twice and then fails, the variable `a` gets the value `2`. Unlike `!`, the failure does not stop the following execution, so `bar` will still run after the counting loop completes.

## Variables

Variables are stored by name. To read a variable value, prefix the name with `$`:

```text
inc a 2
foo $a
```

The first line stores `2` in `a`; the second passes that value to `foo`.

## Math commands

The runtime can register a small math library with these commands:

- `clear name` — set a variable to `0`
- `inc name [value]` — add `value` (default `1`)
- `dec name [value]` — subtract `value` (default `1`)
- `div name value` — divide the variable by `value`
- `floor name` — round the variable down to an integer

Example:

```text
inc a 6
div a 3
inc a 9
div a 2
floor a
```

Available math functions:

Single-argument helpers (they operate on the named variable):

- `clear` — set the named variable to `0`.
- `inc` — add the current repeat count to the named variable.
- `dec` — subtract the current repeat count from the named variable.
- `mul` — multiply the named variable by the current repeat count.
- `div` — divide the named variable by the current repeat count.
- `abs` — replace the variable with its absolute value.
- `asin` — replace the variable with the arc sine of its current value.
- `atan` — replace the variable with the arc tangent of its current value.
- `ceil` — round the variable up to the next integer.
- `cos` — replace the variable with the cosine of its current value.
- `cosh` — replace the variable with the hyperbolic cosine of its current value.
- `deg` — convert the variable from radians to degrees.
- `exp` — replace the variable with $e^x$.
- `floor` — round the variable down to the nearest integer.
- `rad` — convert the variable from degrees to radians.
- `sin` — replace the variable with the sine of its current value.
- `sinh` — replace the variable with the hyperbolic sine of its current value.
- `sqrt` — replace the variable with its square root.
- `tan` — replace the variable with the tangent of its current value.
- `tanh` — replace the variable with the hyperbolic tangent of its current value.

Two-operand helpers (they combine the current variable value with the current repeat count):

- `atan2` — compute $	ext{atan2}(	ext{current}, 	ext{count})$ and store the result in the named variable.
- `max` — store the larger of the current variable value and the current repeat count.
- `min` — store the smaller of the current variable value and the current repeat count.
- `pow` — compute $	ext{pow}(	ext{current}, 	ext{count})$ and store the result in the named variable.

## Example

```text
:step forward ;
:loop [ step ] 4 ;
loop
```

This defines a procedure named `step`, then repeats it four times.
