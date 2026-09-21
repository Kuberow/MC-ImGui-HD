# MC-ImGui
An Immediate Mode Gui system in CC. Looks inspired by Dear ImGui

## HD remake

`mc-imgui-hd.lua` is the CraftOS-PC graphics-mode renderer. It keeps the original
object and event API, but draws a compact 3x5 bitmap font in 4x6 pixel slots so
controls are easier to read. Use it in CraftOS-PC with:

```lua
local imgui = require("mc-imgui-hd")
imgui.init(window.create(term.current(), 1, 1, term.getSize()), term.current())
```

The module enables graphics mode when the terminal provides it and uses
`drawPixels` for filled rectangles. The original `mc-imgui.lua` remains
available for standard ComputerCraft terminals.

HD frames are buffered and only changed pixel runs are sent to the terminal.
Clicking a frame brings it to the front. Click the left edge of a title bar to
minimize or restore its body, and drag the rest of the title bar to move it.
