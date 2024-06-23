# ComputerCraft Libs

Helper functions and programs for computers and turtles.

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
