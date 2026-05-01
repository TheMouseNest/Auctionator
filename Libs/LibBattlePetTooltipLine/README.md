# LibBattlePetTooltipLine

This library applies to retail versions of World of Warcraft. Leaving the
library unused but loaded won't error in classic editons of WoW.

This library exists to add lines with a left and right component of unlimited
length to a battle pet tooltip without having to wrap the text or have multiple
lines not match up.

```lua
local LibBattlePetTooltipLine = LibStub("LibBattlePetTooltipLine-1-0")

hooksecurefunc("BattlePetToolTip_Show", function(...)
  LibBattlePetTooltipLine:AddDoubleLine(BattlePetTooltip, "Special Detail",
RED_FONT_COLOR:WrapTextInColorCode("Me"))
end)
```
