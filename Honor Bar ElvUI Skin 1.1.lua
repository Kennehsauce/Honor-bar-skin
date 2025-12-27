-- HonorBar_ElvUI
-- ElvUI skin plugin for HonorBar (Classic Era / Anniversary)

local addonName = ...

-- ElvUI is a required dependency
local E = unpack(ElvUI or {})
if not E then return end

local okSkins, S = pcall(function() return E:GetModule('Skins') end)
if not okSkins then S = nil end

local _G = _G
local ipairs = ipairs
local type = type
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame
local math_abs = math.abs
local math_max = math.max

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
  elseif frame.SetTemplate then
    frame:SetTemplate(template)
  elseif frame.CreateBackdrop then
    frame:CreateBackdrop(template)
  end
end

local function HandleButton(btn)
  if not btn then return end
  if S and S.HandleButton then S:HandleButton(btn) end
end

local function HandleCheckBox(cb)
  if not cb then return end
  if S and S.HandleCheckBox then S:HandleCheckBox(cb) end
end

local function HandleSlider(sl)
  if not sl then return end
  if S and S.HandleSliderFrame then S:HandleSliderFrame(sl) end
end

local function HandleEditBox(eb)
  if not eb then return end
  if S and S.HandleEditBox then S:HandleEditBox(eb) end
end

local function HandleScrollBar(scrollBar)
  if not scrollBar then return end
  if S and S.HandleScrollBar then S:HandleScrollBar(scrollBar) end
end

local function HandleDropDown(dd, width)
  if not dd or dd.__HBElvDropDown then return end

  if S and S.HandleDropDownBox then
    local ok = pcall(function()
      local w = width
      if (not w or w <= 0) and dd.GetWidth then
        w = dd:GetWidth()
      end
      if not w or w <= 0 then
        -- HonorBar sets UIDropDownMenu_SetWidth(dd, 145)
        w = 145
      end

      -- Use old=true so ElvUI skins and re-anchors the actual clickable Button.
      S:HandleDropDownBox(dd, w, 'Transparent', true)
    end)
    if ok then
      dd.__HBElvDropDown = true
      return
    end
  end

  -- Add a backdrop and style the clickable arrow/button without moving it.
  HandleFrame(dd, 'Transparent')

  local name = dd.GetName and dd:GetName()
  local btn = dd.Button or (name and (_G[name .. 'Button'] or _G[name .. '_Button']))
  if btn then

    HandleButton(btn)
  end

  dd.__HBElvDropDown = true
end

local function SkinColorSwatchButton(btn)
  -- HonorBar swatches draw their own full-size color texture. Avoid StripTextures/HandleButton here.
  if not btn or btn.__HBElvSwatch then return end

  if btn.CreateBackdrop then
    btn:CreateBackdrop('Default')
    if btn.backdrop and btn.backdrop.Point then
      btn.backdrop:Point('TOPLEFT', -2, 2)
      btn.backdrop:Point('BOTTOMRIGHT', 2, -2)
    end
  elseif btn.SetTemplate then
    btn:SetTemplate('Default')
  end

  -- Label readability
  SetElvUIFont(btn.Text or (btn.GetName and btn:GetName() and _G[btn:GetName() .. 'Text']), 11, 'OUTLINE')

  btn.__HBElvSwatch = true
end

-- Stats frame
local function EnsureBackdropPanel(frame, template)
  if not frame then return end
  template = template or 'Transparent'

  if frame.CreateBackdrop or frame.SetTemplate or (S and S.HandleFrame) then
    HandleFrame(frame, template)
    return
  end

  if frame.__HBElvPanel and frame.__HBElvPanel.SetAllPoints then
    return
  end

  local panel = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
  panel:SetAllPoints(frame)
  panel:SetFrameLevel(math_max((frame.GetFrameLevel and frame:GetFrameLevel() or 1) - 1, 0))

  local edgeTex = (E.media and E.media.blankTex) or 'Interface\\ChatFrame\\ChatFrameBackground'
  panel:SetBackdrop({
    edgeFile = edgeTex,
    bgFile = edgeTex,
    edgeSize = (E and E.Scale and E:Scale(1)) or 1,
  })

  local db = (E.db and E.db.general) or nil
  local bc = db and (db.bordercolor or db.backdropfadecolor) or nil
  local bg = db and (db.backdropfadecolor or db.backdropcolor) or nil

  if bg and type(bg) == 'table' then
    panel:SetBackdropColor(bg.r or 0, bg.g or 0, bg.b or 0, bg.a or 0.45)
  else
    panel:SetBackdropColor(0, 0, 0, 0.45)
  end

  if bc and type(bc) == 'table' then
    panel:SetBackdropBorderColor(bc.r or 0, bc.g or 0, bc.b or 0, bc.a or 1)
  else
    panel:SetBackdropBorderColor(0, 0, 0, 1)
  end

  frame.__HBElvPanel = panel
end

-- Locate HonorBar's bar background texture
local function FindBarBackgroundTexture(bar)
  if not bar or not bar.GetStatusBarTexture then return nil end

  local st = bar:GetStatusBarTexture()

  local function IsTexture(obj)
    return obj and obj.GetObjectType and obj:GetObjectType() == 'Texture'
  end

  local function Candidate(tex)
    if not IsTexture(tex) then return nil end
    if tex == st then return nil end
    if tex.GetParent and tex:GetParent() ~= bar then return nil end
    return tex
  end

  -- Commons
  local direct = Candidate(bar.bg) or Candidate(bar.background) or Candidate(bar.BG) or Candidate(bar.Bg)
  if direct then return direct end

  local best, bestScore = nil, -1
  local bw, bh = 0, 0
  if bar.GetSize then bw, bh = bar:GetSize() end

  for _, r in ipairs(GetRegions(bar)) do
    local tex = Candidate(r)
    if tex then
      local score = 0

      local layer = tex.GetDrawLayer and tex:GetDrawLayer() or nil
      if layer == 'BACKGROUND' then score = score + 2 end

      local name = tex.GetName and tex:GetName() or nil
      if name then
        local ln = name:lower()
        if ln:find('barbg') then
          score = score + 4
        elseif ln:find('background') or ln:find('bg') then
          score = score + 3
        end
      end

      local tw, th = 0, 0
      if tex.GetSize then tw, th = tex:GetSize() end
      if bw and bh and tw and th and bw > 0 and bh > 0 and tw > 0 and th > 0 then
        if math_abs(bw - tw) < 2 and math_abs(bh - th) < 2 then
          score = score + 2
        end
      end

      if score > bestScore then
        best = tex
        bestScore = score
      end
    end
  end

  return best
end

local function StyleBarBackground(bar)
  local bg = FindBarBackgroundTexture(bar)
  if not bg then return end

  if not bg.__HBElvStyled then
    if bg.SetTexture then
      bg:SetTexture((E.media and E.media.blankTex) or 'Interface\\ChatFrame\\ChatFrameBackground')
    end
    if bg.SetDrawLayer then
      bg:SetDrawLayer('BACKGROUND', 0)
    end
    -- Does no call :Show(), :Hide(), :SetAlpha(), :SetVertexColor() here.
    bg.__HBElvStyled = true
  end
end

local function SkinHonorBarFrame_Once()
  local frame = _G.HonorBarFrame
  if not frame then return end
  if frame.__HBElvSkinnedMain then return end

  local bar = FindFirstStatusBar(frame)

  -- Outer frame template
  if frame.CreateBackdrop then
    if not frame.backdrop then
      frame:CreateBackdrop('Transparent', nil, nil, nil, nil, nil, nil, true)
    end
    if frame.backdrop and frame.backdrop.SetTemplate then
      frame.backdrop:SetTemplate('Transparent')
    end
  elseif frame.SetTemplate then
    frame:SetTemplate('Transparent')
  else
    HandleFrame(frame, 'Transparent')
  end

  -- Statusbar fill texture
  if bar and bar.SetStatusBarTexture and E.media and E.media.normTex then
    bar:SetStatusBarTexture(E.media.normTex)
  end

  -- Background texture style does not touch color/alpha.
  if bar then
    StyleBarBackground(bar)
  end

  -- Fonts
  FontifyAllFontStrings(frame, nil, 'OUTLINE')

  frame.__HBElvSkinnedMain = true
end

local function SkinStatsFrame()
  local f = _G.HonorBarSessionStatsFrame
  if not f then return end

  -- The stats frame Hook
  if f.HookScript and not f.__HBElvHookedOnShow then
    f:HookScript('OnShow', function()
      if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, SkinStatsFrame)
      else
        SkinStatsFrame()
      end
    end)
    f.__HBElvHookedOnShow = true
  end

  if not f.__HBElvSkinnedStats then
    EnsureBackdropPanel(f, 'Transparent')
    f.__HBElvSkinnedStats = true
  end

  FontifyAllFontStrings(f, 12, 'OUTLINE')
  if f.text then
    SetElvUIFont(f.text, 12, 'OUTLINE')
  end
end

local function SkinAdjustDialog()
  local f = _G.HonorBarAdjustDlg
  if not f then return end

  if not f.__HBElvSkinnedConfig then
    HandleFrame(f, 'Transparent')

    local function Walk(container)
      for _, c in ipairs(GetChildren(container)) do
        if c and c.GetObjectType then
          local ot = c:GetObjectType()
          if ot == 'CheckButton' then
            HandleCheckBox(c)


            if c.HookScript and not c.__HBElvHookedStatsClick then
              c:HookScript('OnClick', function()
                if _G.C_Timer and _G.C_Timer.After then
                  _G.C_Timer.After(0, SkinStatsFrame)
                else
                  SkinStatsFrame()
                end
              end)
              c.__HBElvHookedStatsClick = true
            end
          elseif ot == 'Slider' then
            HandleSlider(c)
          elseif ot == 'EditBox' then
            HandleEditBox(c)
          elseif ot == 'Frame' then

            local n = c.GetName and c:GetName() or nil
            if n == 'HB_Adjust_BarOptionsDD' or n == 'HB_Adjust_StatsOptionsDD' then
              HandleDropDown(c)
            end
          elseif ot == 'Button' then
            local name = c.GetName and c:GetName()
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

        if c and c.GetChildren then
          Walk(c)
        end
      end
    end

    Walk(f)

    f.__HBElvSkinnedConfig = true
  end

  FontifyAllFontStrings(f, nil, 'OUTLINE')
end

local function HookStatsToggles()
  local candidates = {
    'HB_ToggleSessionStatsFrame',
    'HB_ToggleStatsFrame',
    'HB_ShowSessionStatsFrame',
    'HB_ShowStatsFrame',
    'HonorBar_ToggleSessionStatsFrame',
    'HonorBar_ToggleStatsFrame',
  }

  for _, fn in ipairs(candidates) do
    if type(_G[fn]) == 'function' and not _G['__HBElvHooked_' .. fn] then
      hooksecurefunc(fn, function()
        if _G.C_Timer and _G.C_Timer.After then
          _G.C_Timer.After(0, SkinStatsFrame)
        else
          SkinStatsFrame()
        end
      end)
      _G['__HBElvHooked_' .. fn] = true
    end
  end
end

local function SkinHelpDialog()
  local f = _G.HonorBarHelpDialog
  if not f then return end

  if not f.__HBElvSkinnedHelp then
    HandleFrame(f, 'Transparent')

    local scroll = _G.HonorBarHelpScrollFrame or f.scroll
    if scroll then
      local sb = scroll.ScrollBar or (scroll.GetName and scroll:GetName() and _G[scroll:GetName() .. 'ScrollBar'])
      if sb then
        HandleScrollBar(sb)
      end
    end

    f.__HBElvSkinnedHelp = true
  end

  FontifyAllFontStrings(f, nil, 'OUTLINE')
end

-- Only skins the bar once
local function SkinMain()
  if not E or E.initialized == false then return end
  SkinHonorBarFrame_Once()
  SkinStatsFrame()
end

-- Dialog pass
local function SkinDialogs()
  if not E or E.initialized == false then return end
  SkinAdjustDialog()
  SkinHelpDialog()
  SkinStatsFrame()
end

local function HookOpeners()
  -- Right-click opens config
  local frame = _G.HonorBarFrame
  if frame and frame.HookScript and not frame.__HBElvHookedMouse then
    frame:HookScript('OnMouseDown', function()
      if _G.C_Timer and _G.C_Timer.After then
        _G.C_Timer.After(0, SkinDialogs)
      else
        SkinDialogs()
      end
    end)
    frame.__HBElvHookedMouse = true
  end

  -- Dialog openers
  if type(_G.HB_ShowHelpPopup) == 'function' and not _G.__HBElvHookedHelpPopup then
    hooksecurefunc('HB_ShowHelpPopup', function()
      if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, SkinDialogs) else SkinDialogs() end
    end)
    _G.__HBElvHookedHelpPopup = true
  end

  if type(_G.HB_ToggleHelpDialog) == 'function' and not _G.__HBElvHookedHelpToggle then
    hooksecurefunc('HB_ToggleHelpDialog', function()
      if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, SkinDialogs) else SkinDialogs() end
    end)
    _G.__HBElvHookedHelpToggle = true
  end

  HookStatsToggles()

  -- /hb config and other slash commands
  if _G.SlashCmdList and type(_G.SlashCmdList.HBROOT) == 'function' and not _G.__HBElvHookedSlash then
    local orig = _G.SlashCmdList.HBROOT
    _G.SlashCmdList.HBROOT = function(msg, ...)
      orig(msg, ...)
      if _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(0, SkinDialogs) else SkinDialogs() end
    end
    _G.__HBElvHookedSlash = true
  end
end

local function Init()
  SkinMain()
  HookOpeners()

  -- Retry main skin to catch late frames
  if _G.C_Timer and _G.C_Timer.After then
    _G.C_Timer.After(0.2, SkinMain)
    _G.C_Timer.After(1.0, SkinMain)
    _G.C_Timer.After(3.0, SkinMain)
  end
end

local driver = CreateFrame('Frame')
driver:RegisterEvent('PLAYER_LOGIN')
driver:RegisterEvent('ADDON_LOADED')

driver:SetScript('OnEvent', function(_, event, arg1)
  if event == 'ADDON_LOADED' then
    if arg1 ~= 'HonorBar' and arg1 ~= 'ElvUI' then return end
  end

  if _G.C_Timer and _G.C_Timer.After then
    _G.C_Timer.After(0, Init)
  else
    Init()
  end
end)
