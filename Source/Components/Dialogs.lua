local counter = 0
local function GenerateDialog()
  counter = counter + 1
  local dialog = CreateFrame("Frame", "AuctionatorDialog" .. counter, UIParent)
  dialog:SetToplevel(true)
  table.insert(UISpecialFrames, "AuctionatorDialog" .. counter)
  dialog:SetPoint("TOP", 0, -135)
  dialog:EnableMouse(true)
  dialog:SetFrameStrata("DIALOG")

  dialog.NineSlice = CreateFrame("Frame", nil, dialog, "NineSlicePanelTemplate")
  NineSliceUtil.ApplyLayoutByName(dialog.NineSlice, "Dialog", dialog.NineSlice:GetFrameLayoutTextureKit())

  local bg = dialog:CreateTexture(nil, "BACKGROUND", nil, -1)
  bg:SetColorTexture(0, 0, 0, 0.8)
  bg:SetPoint("TOPLEFT", 11, -11)
  bg:SetPoint("BOTTOMRIGHT", -11, 11)

  dialog:SetSize(500, 110)

  dialog.text = dialog:CreateFontString(nil, nil, "GameFontHighlight")
  dialog.text:SetPoint("TOP", 0, -20)
  dialog.text:SetPoint("LEFT", 20, 0)
  dialog.text:SetPoint("RIGHT", -20, 0)
  dialog.text:SetJustifyH("CENTER")

  return dialog
end

local editBoxDialogsBySkin = {}
function Auctionator.Dialogs.ShowEditBox(text, acceptText, cancelText, confirmCallback)
  local currentSkinKey = ""
  if not editBoxDialogsBySkin[currentSkinKey] then
    local dialog = GenerateDialog()
    dialog:SetWidth(350)
    dialog.editBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    dialog.editBox:SetAutoFocus(false)
    dialog.editBox:SetSize(200, 30)
    dialog.editBox:SetPoint("CENTER")

    dialog.acceptButton = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")
    dialog.cancelButton = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")

    dialog.acceptButton:SetPoint("TOPRIGHT", dialog, "CENTER", -5, -18)
    dialog.cancelButton:SetPoint("TOPLEFT", dialog, "CENTER", 5, -18)
    dialog.cancelButton:SetScript("OnClick", function()
      dialog:Hide()
    end)

    editBoxDialogsBySkin[currentSkinKey] = dialog
  end

  local dialog = editBoxDialogsBySkin[currentSkinKey]
  dialog:Hide()

  dialog.text:SetText(text)
  dialog.acceptButton:SetText(acceptText)
  DynamicResizeButton_Resize(dialog.acceptButton)
  dialog.cancelButton:SetText(cancelText)
  DynamicResizeButton_Resize(dialog.cancelButton)
  dialog.acceptButton:SetScript("OnClick", function() confirmCallback(dialog.editBox:GetText()); dialog:Hide() end)
  dialog.editBox:SetScript("OnEnterPressed", function() confirmCallback(dialog.editBox:GetText()); dialog:Hide() end)
  dialog.editBox:SetText("")

  dialog:Show()
  dialog.editBox:SetFocus()
end

local confirmDialogsBySkin = {}
function Auctionator.Dialogs.ShowConfirm(text, yesText, noText, confirmCallback)
  local currentSkinKey = ""
  if not confirmDialogsBySkin[currentSkinKey] then
    local dialog = GenerateDialog()
    dialog:SetSize(450, 100)
    dialog.text:SetPoint("TOP", 0, -30)

    dialog.acceptButton = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")
    dialog.cancelButton = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")

    dialog.acceptButton:SetPoint("TOPRIGHT", dialog, "CENTER", -5, -10)
    dialog.cancelButton:SetPoint("TOPLEFT", dialog, "CENTER", 5, -10)
    dialog.cancelButton:SetScript("OnClick", function()
      dialog:Hide()
    end)

    confirmDialogsBySkin[currentSkinKey] = dialog
  end

  local dialog = confirmDialogsBySkin[currentSkinKey]
  dialog:Hide()

  dialog.text:SetText(text)
  dialog.acceptButton:SetText(yesText)
  DynamicResizeButton_Resize(dialog.acceptButton)
  dialog.cancelButton:SetText(noText)
  DynamicResizeButton_Resize(dialog.cancelButton)
  dialog.acceptButton:SetScript("OnClick", function() confirmCallback(); dialog:Hide() end)

  dialog:Show()
end

local confirmDialogsBySkin = {}
function Auctionator.Dialogs.ShowConfirmAlt(text, yesText, altText, noText, confirmCallback, altCallback)
  local currentSkinKey = ""
  if not confirmDialogsBySkin[currentSkinKey] then
    local dialog = GenerateDialog()
    dialog:SetSize(450, 100)
    dialog.text:SetPoint("TOP", 0, -30)

    dialog.acceptButton = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")
    dialog.altButton = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")
    dialog.cancelButton = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")

    dialog.altButton:SetPoint("TOP", dialog, "CENTER", 0, -10)
    dialog.acceptButton:SetPoint("RIGHT", dialog.altButton, "LEFT", -10, 0)
    dialog.cancelButton:SetPoint("LEFT", dialog.altButton, "RIGHT", 10, 0)
    dialog.cancelButton:SetScript("OnClick", function()
      dialog:Hide()
    end)

    confirmDialogsBySkin[currentSkinKey] = dialog
  end

  local dialog = confirmDialogsBySkin[currentSkinKey]
  dialog:Hide()

  dialog.text:SetText(text)
  dialog.acceptButton:SetText(yesText)
  DynamicResizeButton_Resize(dialog.acceptButton)
  dialog.altButton:SetText(altText)
  DynamicResizeButton_Resize(dialog.altButton)
  dialog.cancelButton:SetText(noText)
  DynamicResizeButton_Resize(dialog.cancelButton)
  dialog.acceptButton:SetScript("OnClick", function() confirmCallback(); dialog:Hide() end)
  dialog.altButton:SetScript("OnClick", function() altCallback(); dialog:Hide() end)

  dialog:Show()
end

local moneyShowDialogsBySkin = {}
function Auctionator.Dialogs.ShowMoney(text, value, acceptText, cancelText, confirmCallback)
  local currentSkinKey = ""
  if not moneyShowDialogsBySkin[currentSkinKey] then
    local dialog = GenerateDialog()
    dialog:SetWidth(400)

    dialog.acceptButton = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")
    dialog.cancelButton = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")

    dialog.acceptButton:SetPoint("TOPRIGHT", dialog, "CENTER", -5, -18)
    dialog.cancelButton:SetPoint("TOPLEFT", dialog, "CENTER", 5, -18)
    dialog.cancelButton:SetScript("OnClick", function()
      dialog:Hide()
    end)

    moneyShowDialogsBySkin[currentSkinKey] = dialog
  end

  local dialog = moneyShowDialogsBySkin[currentSkinKey]
  dialog:Hide()

  dialog.text:SetText(text .. "\n\n" .. GetMoneyString(value, true))
  dialog.acceptButton:SetText(acceptText)
  DynamicResizeButton_Resize(dialog.acceptButton)
  dialog.cancelButton:SetText(cancelText)
  DynamicResizeButton_Resize(dialog.cancelButton)

  local callback = function() confirmCallback(); dialog:Hide() end
  dialog.acceptButton:SetScript("OnClick", callback)

  dialog:Show()
end
