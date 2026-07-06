# ComputerCraft Applications

There are many applications including prototypes, in development and legacy
scripts. Not all are documented.

If applications are running from this repo, use the `cc-apps/` prefix. If
applications are installed using the installer script, use the `cc/` prefix.

All commands that use argparse (take any arguments) have hidden `-h` and
`--help` flags to print the usage without executing the script.

## [_template.lua](_template.lua)

Template for application scrips.

1. Setup path for package import
2. Configure logger
3. Create argument parser
4. Parse arguments
5. Init actions and motion controller
6. Call the main function with logger wrapper for errors

### Usage

```
Usage: cc/_template <n>

Fill this in with your program
Args:
    n: count
```

## [branch_mine](branch_mine.lua)

This application is the reason `cc-libs` was created. It is the most complex
(at the time of writing) and utilizes most of the library.

With the turtle starting on the floor, it will mine 3 block high branches to the
left and right every 3 blocks. Torches will also be placed along the path. If
`skip` is provided, that number of branches are skipped before starting the
first branch. This is useful for resuming mining or extending an existing
branch mine.

### Usage

```
Usage: cc/branch_mine <shafts> <length> [torch|8] [skip|0]

Starting on the floor, mine 3 block high branches to the left / right and place torches
Args:
    shafts: number of shafts to mine
    length: length of each shaft
    torch: interval to place torches
    skip: number of shafts to skip
```

## [bridge](bridge.lua)

Construct a bridge (or dig a tunnel) with optional ceiling at 2 blocks high.
Specify the length of the bridge / tunnel, the block used as the bridge floor
and optionally a block used for the ceiling. Use -r or --replace_floor to
replace blocks under the turtle with the bridge block.

Blocks are specified with minecraft block ids (eg. `minecraft:cobblestone`).

### Usage

```
Usage: cc/bridge [options] <length> <block_floor> [block_ceiling]

Dig forwards and lay a bridge on the way back if there isn't one already
Args:
    length: length of bridge/tunnel
    block_floor: name of block to place as floor
    block_ceiling: name of block to place as ceiling (defaults to no ceiling)
Options:
    -r/--replace_floor: Replace existing floor if it does not match
```

## [demo_logging](demo_logging.lua)

Demonstrate usage of `cc-libs.logging`

### Usage

```
Usage: cc/demo_logging
```

## [dig_down](dig_down.lua)

Dig down `n` blocks.

### Usage

```
Usage: cc/dig_down <n>

Dig a vertical shaft straight down
Args:
    n: number of blocks to mine down
```

## [harvest_crops](harvest_crops.lua)

**TODO**

## [inspect](inspect.lua)

Inspect the block in front of the turtle. If the block is an inventory, also
inspect the inventory contents.

Block inspection is written to `inspect.json` if a block exists and inventory
inspection is written to `inventory.json` if the block is an inventory.

### Usage

```
Usage: cc/inspect
```

## [ladder_up](ladder_up.lua)

Create a ladder from the turtles location. Ladders are placed bellow the turtle
with support blocks placed in front.

### Usage

```
Usage: ladder_up <height> [block_fill]

Build a ladder, placing ladder blocks bellow the turtle
Args:
    height: height of the ladder
    block_fill: name of block to place as column if there is an air gap
```

## [lumber](lumber.lua)

Mine logs in front of the turtle starting at the base of a tree. The turtle will
move up until the block in front is not a log.

### Usage

```
Usage: cc/lumber
```

## [mainframe](mainframe.lua)

Collect logging and telemetry data over rednet.

### Usage

```
Usage: cc/mainframe
```

### Protocol `remote_log`

Receive remote logging message. These messages must be valid json with at least
`level` and `host` fields. Messages are filtered by `level` and appended to
`logs/remote/{host}.json`.

**Request** payload should be a json packet

```
{
    level: string - log level
    host: string - hostname
    [string]: any - any other data in the json log message
}
```

There is no response

### Protocol `telemetry`

Receive telemetry data. These messages must be a valid json object. Telemetry
data can be retrieved at any time over the `report` protocol. This data is
stored in memory, so information will be reset for each execution of the script.

**Request** payload should be a json packet

```
{
    [string]: any
}
```

There is no response

### Protocol `report`

Report telemetry data for a computer or turtle.

**Request** payload should be a json packet

```
{
    id: number - computer or turtle to request telemetry for
}
```

**Response** payload is a json object using the `mainframe_response` protocol

```
{
    ok: boolean - id was found and has telemetry data
    err: string | nil - reason if ok is false
    id: number - computer or turtle id, same as id from request
    status: { [string]: any } - telemetry data for the computer or turtle
}
```


## [portal_takedown](portal_takedown.lua)

Remove an obsidian portal. The order is counter clockwise with the turtle
starting on the right side of the portal.

```
9 7 6 5
8     4
a     3
b     1 start
c d e 2
```

### Usage

```
Usage: cc/portal_takedown
```

## [remote_log_monitor](remote_log_monitor.lua)

Listen to the `remote_log` protocol and print messages to the console.

### Usage

```
Usage: cc/remote_log_monitor
```

## [shaft_down](shaft_down.lua)

Mine a 1x1 shaft down and construct walls around it if any are missing.

### Usage

```
Usage: cc/shaft_down [options] <n> <block_walls>

Dig a shaft down and add walls if they are missing
Args:
    n: number of blocks to mine down
    block_wall: name of block to place as wall
Options:
    -l/--ladder: place a ladder on the way back up
```

## [stairs](stairs.lua)

Mine a staircase down. Stairs can also be placed from slot 1 on the return.
Mining will account for stair placement and mines an extra block if enabled.

### Usage

```
Usage: cc/stairs [options] <n>

Mine a staircase down optionally placing stairs from slot 1 on the return
Args:
    n: number of steps
Options:
    -p/--place_stairs: place stairs from slot 1 on the return
```

## [strip](strip.lua)

Clear an area of length, width and height. Mining can be up or down. Because
this script is used for clearing areas, the inventory is not checked. If it
becomes full, blocks will be dropped on the ground.

> [!WARNING]
> This program does not have motion checks. If the motion controller fails to
> move, the mining will be offset.

### Usage

```
Usage: cc/strip [options] <length> <width> <height>

Mine a region to the front and right of the turtle
WARNING this is for clearing areas, inventory will not be checked or dumped when full
Args:
    length: length of area to mine
    width: width of area to mine
    height: height of area to mine
Options:
    -u/--up: mine up instead of down.
```

## [structure](structure.lua)

**TODO**

## [tunnel2](tunnel2.lua)

**TODO**

## [watch_lava](watch_lava.lua)

**TODO**
