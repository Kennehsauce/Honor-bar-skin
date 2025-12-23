-- HonorBar_ElvUI
-- ElvUI skin plugin for HonorBar (Classic Era / Anniversary)
-- Skins:
--   * Main bar frame
--   * Detached session stats frame
--   * Bar Config dialog
--   * Help dialog

local addonName = ...

-- ElvUI is a required dependency
local E = unpack(ElvUI or {})
if not E then return end

local okSkins, S = pcall(function() return E:GetModule('Skins') end)
if not okSkins then S = nil end

local _G = _G
local unpack = unpack
local ipairs = ipairs
local next = next
local type = type
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame

local function GetChildren(frame)
  if not frame or not frame.GetChildren then return {} end
  return { frame:GetChildren() }
end

local function GetRegions(frame)
  if not frame or not frame.GetRegions then return {} end
  return { frame:GetRegions() }
end

local function SetElvUIFont(fs, sizeOverride, flagsOverride)
  if not fs or not fs.SetFont then return end

  local _, size, flags = fs:GetFont()
  size = sizeOverride or size or 12
  flags = flagsOverride or flags or 'OUTLINE'

  if E.media and E.media.normFont then
    fs:SetFont(E.media.normFont, size, flags)
  end

  if fs.SetShadowOffset then
    fs:SetShadowOffset(0, 0)
  end
end

local function FontifyAllFontStrings(frame, sizeOverride, flagsOverride)
  if not frame then return end

  for _, r in ipairs(GetRegions(frame)) do
    if r and r.GetObjectType and r:GetObjectType() == 'FontString' then
      SetElvUIFont(r, sizeOverride, flagsOverride)
    end
  end

  for _, c in ipairs(GetChildren(frame)) do
    FontifyAllFontStrings(c, sizeOverride, flagsOverride)
  end
end

local function FindFirstStatusBar(parent)
  for _, c in ipairs(GetChildren(parent)) do
    if c and c.GetObjectType and c:GetObjectType() == 'StatusBar' then
      return c
    end
  end
end

local function HandleFrame(frame, template)
  if not frame then return end
  template = template or 'Transparent'

  if S and S.HandleFrame then
    S:HandleFrame(frame, true, template)
    return
  end

  if frame.SetTemplate then
    frame:SetTemplate(template)
  elseif frame.CreateBackdrop then
    frame:CreateBackdrop(template)
  end
end

local function HandleButton(btn)
  if not btn then return end
  if S and S.HandleButton then
    S:HandleButton(btn)
  end
end

local function HandleCheckBox(cb)
  if not cb then return end
  if S and S.HandleCheckBox then
    S:HandleCheckBox(cb)
  end
end

local function HandleSlider(sl)
  if not sl then return end
  if S and S.HandleSliderFrame then
    S:HandleSliderFrame(sl)
  end
end

local function HandleEditBox(eb)
  if not eb then return end
  if S and S.HandleEditBox then
    S:HandleEditBox(eb)
  end
end

local function HandleScrollBar(scrollBar)
  if not scrollBar then return end
  if S and S.HandleScrollBar then
    S:HandleScrollBar(scrollBar)
  end
end

local function SkinColorSwatchButton(btn)
  -- HonorBar color swatches intentionally hide UIPanelButtonTemplate art and draw a full-size color texture.
  -- Do NOT StripTextures() or HandleButton() here, may nuke the color fill.
  if not btn or btn.__HBElvSwatch then return end

  if btn.CreateBackdrop then
    btn:CreateBackdrop('Default')
    if btn.backdrop and btn.backdrop.SetAllPoints == nil then
      -- keep default points created by ElvUI
    end
    if btn.backdrop and btn.backdrop.Point then
      btn.backdrop:Point('TOPLEFT', -2, 2)
      btn.backdrop:Point('BOTTOMRIGHT', 2, -2)
    end
  elseif btn.SetTemplate then
    btn:SetTemplate('Default')
  end

  -- Make the label readable
  SetElvUIFont(btn.Text or _G[btn:GetName() .. 'Text'], 11, 'OUTLINE')

  btn.__HBElvSwatch = true
end

local function SkinHonorBarFrame()
  local frame = _G.HonorBarFrame
  if not frame or frame.__HBElvSkinnedMain then return end

  -- Hide HonorBar's own background texture (ElvUI backdrop provides the panel look)
  if frame.bg and frame.bg.SetAlpha then
    frame.bg:SetAlpha(0)
  end

  -- Apply ElvUI panel template to the outer frame
  if frame.CreateBackdrop then
    frame:CreateBackdrop('Transparent')
  elseif frame.SetTemplate then
    frame:SetTemplate('Transparent')
  end

  -- StatusBar texture
  local bar = FindFirstStatusBar(frame)
  if bar and bar.SetStatusBarTexture and E.media and E.media.normTex then
    bar:SetStatusBarTexture(E.media.normTex)
  end

  -- Fontstrings on the main frame + overlays
  FontifyAllFontStrings(frame, nil, 'OUTLINE')

  frame.__HBElvSkinnedMain = true
end

local function SkinStatsFrame()
  local f = _G.HonorBarSessionStatsFrame
  if not f or f.__HBElvSkinnedStats then return end

  HandleFrame(f, 'Transparent')
  FontifyAllFontStrings(f, 12, 'OUTLINE')

  f.__HBElvSkinnedStats = true
end

local function SkinAdjustDialog()
  local f = _G.HonorBarAdjustDlg
  if not f or f.__HBElvSkinnedConfig then return end

  HandleFrame(f, 'Transparent')
  FontifyAllFontStrings(f, nil, 'OUTLINE')

  -- Skin all UI controls inside config
  for _, c in ipairs(GetChildren(f)) do
    if c and c.GetObjectType then
      local ot = c:GetObjectType()

      if ot == 'CheckButton' then
        HandleCheckBox(c)

      elseif ot == 'Slider' then
        HandleSlider(c)

      elseif ot == 'EditBox' then
        HandleEditBox(c)

      elseif ot == 'Button' then
        local name = c.GetName and c:GetName()

        -- Color swatches
        if name == 'HB_Adjust_BarColor'
          or name == 'HB_Adjust_BarBgColor'
          or name == 'HB_Adjust_TickColor'
          or name == 'HB_Adjust_MilestoneColor'
        then
          SkinColorSwatchButton(c)
        else
          HandleButton(c)
        end
      end
    end
  end

  -- Close button
  for _, c in ipairs(GetChildren(f)) do
    if c and c.GetObjectType and c:GetObjectType() == 'Button' and (not c.GetName or not c:GetName()) then
      if c.GetText and c:GetText() == 'Close' then
        HandleButton(c)
      end
    end
  end

  f.__HBElvSkinnedConfig = true
end

local function SkinHelpDialog()
  local f = _G.HonorBarHelpDialog
  if not f or f.__HBElvSkinnedHelp then return end

  HandleFrame(f, 'Transparent')
  FontifyAllFontStrings(f, nil, 'OUTLINE')

  local scroll = _G.HonorBarHelpScrollFrame or f.scroll
  if scroll then
    local sb = scroll.ScrollBar or (scroll.GetName and scroll:GetName() and _G[scroll:GetName() .. 'ScrollBar'])
    if sb then
      HandleScrollBar(sb)
    end
  end

  f.__HBElvSkinnedHelp = true
end

local function TrySkin()
  if not E or E.initialized == false then return end

  SkinHonorBarFrame()
  SkinStatsFrame()
  SkinAdjustDialog()
  SkinHelpDialog()
end

local function HookOpeners()
  -- Right-click opener on the bar itself
  local frame = _G.HonorBarFrame
  if frame and frame.HookScript and not frame.__HBElvHookedMouse then
    frame:HookScript('OnMouseDown', function()
      if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, TrySkin)
      else
        TrySkin()
      end
    end)
    frame.__HBElvHookedMouse = true
  end

  -- Help dialog is opened via these globals
  if type(_G.HB_ShowHelpPopup) == 'function' and not _G.__HBElvHookedHelpPopup then
    hooksecurefunc('HB_ShowHelpPopup', function()
      if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, TrySkin) else TrySkin() end
    end)
    _G.__HBElvHookedHelpPopup = true
  end

  if type(_G.HB_ToggleHelpDialog) == 'function' and not _G.__HBElvHookedHelpToggle then
    hooksecurefunc('HB_ToggleHelpDialog', function()
      if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, TrySkin) else TrySkin() end
    end)
    _G.__HBElvHookedHelpToggle = true
  end

  -- /hb config and other commands run a post-pass so frames are skinned immediately
  if _G.SlashCmdList and type(_G.SlashCmdList.HBROOT) == 'function' and not _G.__HBElvHookedSlash then
    local orig = _G.SlashCmdList.HBROOT
    _G.SlashCmdList.HBROOT = function(msg, ...)
      orig(msg, ...)
      if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, TrySkin) else TrySkin() end
    end
    _G.__HBElvHookedSlash = true
  end
end

local function HookElvUIUpdates()
  if not E or not hooksecurefunc then return end
  if _G.__HBElvHookedElvUI then return end

  if type(E.UpdateAll) == 'function' then
    hooksecurefunc(E, 'UpdateAll', function()
      if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, TrySkin) else TrySkin() end
    end)
  end

  if type(E.UpdateMedia) == 'function' then
    hooksecurefunc(E, 'UpdateMedia', function()
      if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, TrySkin) else TrySkin() end
    end)
  end

  _G.__HBElvHookedElvUI = true
end

local driver = CreateFrame('Frame')
driver:RegisterEvent('PLAYER_LOGIN')
driver:RegisterEvent('ADDON_LOADED')
driver:RegisterEvent('PLAYER_ENTERING_WORLD')
driver:RegisterEvent('UI_SCALE_CHANGED')
driver:RegisterEvent('DISPLAY_SIZE_CHANGED')

driver:SetScript('OnEvent', function(_, event, arg1)
  if event == 'ADDON_LOADED' then
    if arg1 ~= 'HonorBar' and arg1 ~= 'ElvUI' then return end
  end

  -- Delay one tick so HonorBar + ElvUI have had a chance to build frames
  if _G.C_Timer and _G.C_Timer.After then
    _G.C_Timer.After(0, function()
      HookElvUIUpdates()
      HookOpeners()
      TrySkin()
    end)
  else
    HookElvUIUpdates()
    HookOpeners()
    TrySkin()
  end
end)
