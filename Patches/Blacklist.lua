local blacklist = {
  "!PatchWerk",
  "PatchWerk",
}
for _, addon in ipairs(blacklist) do
  if C_AddOns.DoesAddOnExist(addon) then
    print(RED_FONT_COLOR:WrapTextInColorCode("Incompatible addon detected: ") .. addon)
    C_AddOns.DisableAddOn(addon)
  end
end
