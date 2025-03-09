# ComputerCraft Libs

Helper functions and programs for computers and turtles.

- [CC:Tweaked Wiki](https://tweaked.cc/)
- [Computer Craft Wiki](https://computercraft.info/wiki/Main_Page)

## Usage

Clone the repo into a computer or turtle directory (`cc-libs` should be in the
root directory). Lua scripts in the project root can be executed on a turtle or
computer, or the `cc-libs` directory can be used in other projects.

```sh
git clone git@github.com:twh2898/cc-libs.git # <computer_or_turtle_dir>
```

## Development

### Test

Testing is performed by the builtin `tests/runtest.lua` using `mock.lua` and
`asserts.lua` for support.

```sh
make test
```

### Linting & Formatting

Linting is performed by a combination of luacheck and stylua.

- [luacheck](https://github.com/mpeterv/luacheck)
- [stylua](https://github.com/JohnnyMorganz/StyLua)

```sh
make lint
```

Stylua is used for formatting in cli and vs-code.

```sh
make format
```

## Planning

- Need a motion controller independent of rgps
- Motion controller needs to take optional gps or relative gps to track position
- GPS module should be able to operate in place of rgps if a gps signal is available
  - Maybe GPS could have fallback to rgps if signal is lost
- Motion controller needs to have retries of actions up to some limit
- Motion controller should update rgps if in use
- Navigation could take motion controller
  - mocon would have functions for movement
  - navigation would have functions for waypoints and such (no direct motion)

Possible names

- Motion
- MotionController
- MC
- Actions
- TurtleController
- Driver
- Interface
- TurtleInterface


## Motion (Controller)

- Includes max retries
- Motion has optional parameter to allow digging
