-- ================================================
--   SorinUILib.lua  –  UI Library
--   Host on GitHub raw, load via loadstring
--   Returns a table with .new(config) constructor
-- ================================================

local SorinUILib = {}
SorinUILib.__index = SorinUILib

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")

-- ── Palette ───────────────────────────────────────────────────────────────
local C = {
    bg          = Color3.fromRGB(13,  17,  23),
    surface     = Color3.fromRGB(22,  27,  34),
    surfaceL    = Color3.fromRGB(30,  36,  44),
    surfaceM    = Color3.fromRGB(26,  31,  39),
    primary     = Color3.fromRGB(88,  166, 255),
    primaryD    = Color3.fromRGB(58,  136, 225),
    primaryG    = Color3.fromRGB(120, 180, 255),
    accent      = Color3.fromRGB(136, 87,  224),
    accentL     = Color3.fromRGB(187, 134, 252),
    success     = Color3.fromRGB(47,  183, 117),
    successD    = Color3.fromRGB(37,  153, 97),
    successG    = Color3.fromRGB(67,  203, 137),
    err         = Color3.fromRGB(248, 81,  73),
    txtP        = Color3.fromRGB(230, 237, 243),
    txtS        = Color3.fromRGB(139, 148, 158),
    txtM        = Color3.fromRGB(110, 118, 129),
    border      = Color3.fromRGB(48,  54,  61),
    neonB       = Color3.fromRGB(0,   229, 255),
    neonP       = Color3.fromRGB(187, 134, 252),
    discord     = Color3.fromRGB(88,  101, 242),
}

-- ── Helper constructors ───────────────────────────────────────────────────
local function corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 10)
    return c
end

local function stroke(p, col, thick, trans)
    local s = Instance.new("UIStroke", p)
    s.Color = col; s.Thickness = thick or 1; s.Transparency = trans or 0
    return s
end

local function grad(p, cols, rot)
    local kp = {}
    for i, col in ipairs(cols) do
        kp[i] = ColorSequenceKeypoint.new((i-1)/math.max(#cols-1,1), col)
    end
    local g = Instance.new("UIGradient", p)
    g.Color = ColorSequence.new(kp); g.Rotation = rot or 0
    return g
end

local function lbl(props, parent)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    for k, v in pairs(props) do l[k] = v end
    if parent then l.Parent = parent end
    return l
end

-- ── File helpers ──────────────────────────────────────────────────────────
local function hasFS()
    local ok1, v1 = pcall(function() return type(writefile)=="function" end)
    local ok2, v2 = pcall(function() return type(readfile) =="function" end)
    return ok1 and v1 and ok2 and v2
end
local fsOk = hasFS()
local function saveKey(k)  if fsOk then pcall(writefile, "sorin_key.txt", k) end end
local function loadKey()
    if not fsOk then return nil end
    local ok, v = pcall(readfile, "sorin_key.txt")
    return (ok and v and v ~= "") and v or nil
end
local function clearKey()
    if fsOk then pcall(function() if delfile then delfile("sorin_key.txt") end end) end
end

-- ── Executor / device helpers ─────────────────────────────────────────────
local function getExecutor()
    for _, fn in ipairs({"identifyexecutor","getexecutorname"}) do
        if getfenv and type(getfenv()[fn])=="function" then
            local ok, v = pcall(getfenv()[fn]); if ok and v then return tostring(v) end
        end
    end
    if rawget(_G,"syn")          then return "Synapse X" end
    if rawget(_G,"KRNL_LOADED")  then return "Krnl"     end
    return "Unknown"
end

local function getHWID()
    for _, fn in ipairs({"gethwid","get_hwid","getuniqueid"}) do
        if getfenv and type(getfenv()[fn])=="function" then
            local ok, v = pcall(getfenv()[fn])
            if ok and v then return tostring(v) end
        end
    end
    return "N/A"
end

-- ── Constructor ───────────────────────────────────────────────────────────
function SorinUILib.new(cfg)
    local self = setmetatable({}, SorinUILib)
    self.cfg      = cfg
    self.gui      = nil
    self._conns   = {}
    self.el       = {}
    self._closed  = false
    self._hdDef   = cfg.Title or "Key System"
    self._hdTimer = nil
    return self
end

-- ── Particle loop ─────────────────────────────────────────────────────────
function SorinUILib:_particles(host)
    local palette = {C.primaryG, C.neonP, C.neonB, C.accent}
    task.spawn(function()
        while host and host.Parent and not self._closed do
            local p = Instance.new("Frame")
            p.Size              = UDim2.new(0, math.random(2,4), 0, math.random(2,4))
            p.Position          = UDim2.new(math.random(), 0, 1, 0)
            p.BackgroundColor3  = palette[math.random(#palette)]
            p.BackgroundTransparency = 0.55
            p.BorderSizePixel   = 0
            p.ZIndex            = 6
            p.Parent            = host
            corner(p, 10)
            local ft = TweenService:Create(p,
                TweenInfo.new(math.random(8,14), Enum.EasingStyle.Linear),
                {Position=UDim2.new(p.Position.X.Scale,0,-0.12,0), BackgroundTransparency=1})
            ft:Play(); ft.Completed:Connect(function() p:Destroy() end)
            task.wait(math.random()*1.5 + 0.8)
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════════════
--   BUILD
-- ════════════════════════════════════════════════════════════════════════════
function SorinUILib:build()
    if self.gui then self.gui:Destroy() end
    local cfg     = self.cfg
    local loading = cfg.LoadingEnabled
    local mobile  = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local vp      = workspace.CurrentCamera.ViewportSize
    local hasInfo = cfg.UserInfoEnabled ~= false and not mobile
    local hasCL   = cfg.ChangelogEnabled and cfg.Changelog and #cfg.Changelog > 0
    local hasBanner = cfg.ShopBanner and cfg.ShopBanner.Enabled

    getgenv().SORIN_KEY    = nil
    getgenv().SORIN_CLOSED = false

    -- ── ScreenGui ────────────────────────────────────────────────────────
    self.gui = Instance.new("ScreenGui")
    self.gui.Name           = "SorinKeyUI"
    self.gui.ResetOnSpawn   = false
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.gui.IgnoreGuiInset = true

    -- Backdrop
    local backdrop = Instance.new("Frame")
    backdrop.Size                    = UDim2.new(1,0,1,0)
    backdrop.BackgroundColor3        = Color3.new(0,0,0)
    backdrop.BackgroundTransparency  = loading and 1 or 0.42
    backdrop.BorderSizePixel         = 0
    backdrop.Parent                  = self.gui

    -- Blur
    local blurFx = Instance.new("BlurEffect")
    blurFx.Size = 16; blurFx.Name = "SorinBlur"; blurFx.Parent = Lighting

    -- ── Window sizing (3-panel layout) ────────────────────────────────────
    -- Changelog lives as a permanent right panel, not a tab.
    -- clW=0 on mobile or when changelog disabled.
    local clW      = (hasCL and not mobile) and 192 or 0
    local leftW    = hasInfo and 178 or 0
    local bannerH  = hasBanner and 58 or 0
    local mainAreaH = 369   -- content rows between topBar and banner
    local baseH    = 46 + mainAreaH + bannerH  -- topBar + content + banner

    -- Key panel gets whatever space is left between leftW and clW
    local baseW
    if hasInfo and clW > 0 then
        baseW = leftW + 450 + clW   -- 178 + 450 + 192 = 820
    elseif hasInfo then
        baseW = leftW + 472         -- 178 + 472 = 650
    elseif clW > 0 then
        baseW = 440 + clW           -- 440 + 192 = 632
    else
        baseW = 468
    end
    local keyW = baseW - leftW - clW  -- width of the key content area

    local container = Instance.new("Frame")
    container.BackgroundColor3       = C.surface
    container.BorderSizePixel        = 0
    container.AnchorPoint            = Vector2.new(0.5, 0.5)
    container.Position               = UDim2.new(0.5, 0, 0.5, 0)
    container.ClipsDescendants       = true
    container.BackgroundTransparency = loading and 1 or 0
    container.Size = mobile
        and UDim2.new(0.93,0,0,math.min(baseH, vp.Y*0.93))
        or  UDim2.new(0,baseW,0,baseH)
    container.Parent = backdrop
    corner(container, 14)
    stroke(container, C.border, 1, 0.28)

    -- Glass shimmer
    local glass = Instance.new("Frame")
    glass.Size = UDim2.new(1,0,1,0); glass.BackgroundColor3 = Color3.new(1,1,1)
    glass.BackgroundTransparency = 0.975; glass.BorderSizePixel = 0
    glass.ZIndex = 1; glass.Parent = container; corner(glass, 14)

    -- ── TOP BAR ──────────────────────────────────────────────────────────
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1,0,0,46); topBar.BackgroundColor3 = C.bg
    topBar.BorderSizePixel = 0; topBar.ZIndex = 10; topBar.Parent = container
    corner(topBar, 14)
    local tbFill = Instance.new("Frame")
    tbFill.Size = UDim2.new(1,0,0,10); tbFill.Position = UDim2.new(0,0,1,-10)
    tbFill.BackgroundColor3 = C.bg; tbFill.BorderSizePixel = 0; tbFill.Parent = topBar

    -- Brand
    local brand = Instance.new("Frame")
    brand.Size = UDim2.new(0,240,1,0); brand.Position = UDim2.new(0,14,0,0)
    brand.BackgroundTransparency = 1; brand.ZIndex = 11; brand.Parent = topBar

    if cfg.LogoImage and cfg.LogoImage ~= "" then
        local li = Instance.new("ImageLabel")
        li.BackgroundTransparency = 1; li.Size = UDim2.new(0,26,0,26)
        li.AnchorPoint = Vector2.new(0,0.5); li.Position = UDim2.new(0,0,0.5,0)
        li.Image = cfg.LogoImage; li.ScaleType = Enum.ScaleType.Fit
        li.ZIndex = 11; li.Parent = brand
    else
        local logoBox = Instance.new("Frame")
        logoBox.Size = UDim2.new(0,26,0,26); logoBox.AnchorPoint = Vector2.new(0,0.5)
        logoBox.Position = UDim2.new(0,0,0.5,0); logoBox.BackgroundColor3 = C.primary
        logoBox.BorderSizePixel = 0; logoBox.ZIndex = 11; logoBox.Parent = brand
        corner(logoBox, 7); grad(logoBox, {C.primary, C.accent}, 135)
        lbl({Size=UDim2.new(1,0,1,0),Text="◈",TextColor3=Color3.new(1,1,1),
             TextSize=14,Font=Enum.Font.GothamBold,ZIndex=12,
             TextXAlignment=Enum.TextXAlignment.Center}, logoBox)
    end

    lbl({Name="HeaderText", Size=UDim2.new(1,-34,1,0), Position=UDim2.new(0,32,0,0),
         Text=cfg.Title or "Key System", TextColor3=C.txtP, TextSize=14,
         Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11}, brand)

    -- Version badge
    if cfg.Version and cfg.Version ~= "" then
        local vb = Instance.new("TextLabel")
        vb.BackgroundColor3 = C.accent; vb.BackgroundTransparency = 0.65
        vb.Size = UDim2.new(0,40,0,15); vb.AnchorPoint = Vector2.new(0,0.5)
        vb.Position = UDim2.new(0,195,0.5,0); vb.Text = cfg.Version
        vb.TextColor3 = C.neonP; vb.TextSize = 9; vb.Font = Enum.Font.GothamBold
        vb.ZIndex = 11; vb.Parent = brand; corner(vb, 4)
    end

    -- ── Discord button ────────────────────────────────────────────────────
    if cfg.DiscordLink and cfg.DiscordLink ~= "" then
        local db = Instance.new("TextButton")
        db.Size = UDim2.new(0,30,0,30); db.Position = UDim2.new(1,-80,0.5,0)
        db.AnchorPoint = Vector2.new(0,0.5); db.BackgroundColor3 = C.discord
        db.BackgroundTransparency = 0.72; db.BorderSizePixel = 0
        db.AutoButtonColor = false; db.ZIndex = 11; db.Parent = topBar
        corner(db, 8); stroke(db, C.discord, 1, 0.5)

        if cfg.DiscordIcon and cfg.DiscordIcon ~= "" then
            db.Text = ""
            local dImg = Instance.new("ImageLabel")
            dImg.BackgroundTransparency = 1; dImg.Size = UDim2.new(0,18,0,18)
            dImg.AnchorPoint = Vector2.new(0.5,0.5); dImg.Position = UDim2.new(0.5,0,0.5,0)
            dImg.Image = cfg.DiscordIcon; dImg.ScaleType = Enum.ScaleType.Fit
            dImg.ZIndex = 12; dImg.Parent = db
        else
            db.Text = "D"; db.TextColor3 = Color3.new(1,1,1)
            db.TextSize = 15; db.Font = Enum.Font.GothamBold
        end

        db.MouseEnter:Connect(function()
            TweenService:Create(db,TweenInfo.new(0.15),{BackgroundTransparency=0.3}):Play()
        end)
        db.MouseLeave:Connect(function()
            TweenService:Create(db,TweenInfo.new(0.15),{BackgroundTransparency=0.72}):Play()
        end)
        db.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(cfg.DiscordLink) end
        end)
    end

    -- ── Close button ─────────────────────────────────────────────────────
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,30,0,30); closeBtn.Position = UDim2.new(1,-42,0.5,0)
    closeBtn.AnchorPoint = Vector2.new(0,0.5); closeBtn.BackgroundColor3 = C.err
    closeBtn.BackgroundTransparency = 0.75; closeBtn.BorderSizePixel = 0
    closeBtn.Text = "X"; closeBtn.TextColor3 = Color3.new(1,1,1); closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 11; closeBtn.Parent = topBar; corner(closeBtn, 8)
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn,TweenInfo.new(0.15),{BackgroundTransparency=0.05}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn,TweenInfo.new(0.15),{BackgroundTransparency=0.75}):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function() self:close() end)

    -- ── LEFT PANEL (User Info) ────────────────────────────────────────────
    if hasInfo then
        local fullHWID = getHWID()
        local hwIDvisible = false

        local lp = Instance.new("Frame")
        lp.Name = "UserPanel"; lp.Size = UDim2.new(0,leftW,0,mainAreaH)
        lp.Position = UDim2.new(0,0,0,46); lp.BackgroundColor3 = C.bg
        lp.BorderSizePixel = 0; lp.ZIndex = 5; lp.Parent = container
        corner(lp, 14)
        local lpTopFill = Instance.new("Frame")
        lpTopFill.Size = UDim2.new(1,0,0,14); lpTopFill.BackgroundColor3 = C.bg
        lpTopFill.BorderSizePixel = 0; lpTopFill.Parent = lp
        local sep = Instance.new("Frame"); sep.Size = UDim2.new(0,1,1,-14)
        sep.Position = UDim2.new(1,-1,0,14); sep.BackgroundColor3 = C.border
        sep.BackgroundTransparency = 0.45; sep.BorderSizePixel = 0; sep.Parent = lp

        local inner = Instance.new("Frame"); inner.BackgroundTransparency = 1
        inner.Size = UDim2.new(1,-20,1,-14); inner.Position = UDim2.new(0,10,0,10)
        inner.Parent = lp

        -- Avatar
        local avFrame = Instance.new("Frame"); avFrame.Size = UDim2.new(0,58,0,58)
        avFrame.AnchorPoint = Vector2.new(0.5,0); avFrame.Position = UDim2.new(0.5,0,0,6)
        avFrame.BackgroundColor3 = C.surfaceL; avFrame.BorderSizePixel = 0
        avFrame.Parent = inner; corner(avFrame, 29)
        stroke(avFrame, C.primary, 2, 0.3)
        local avImg = Instance.new("ImageLabel"); avImg.BackgroundTransparency = 1
        avImg.Size = UDim2.new(1,0,1,0); avImg.ScaleType = Enum.ScaleType.Crop
        avImg.ZIndex = 2; avImg.Parent = avFrame; corner(avImg, 29)
        task.spawn(function()
            local ok, img = pcall(function()
                return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId,
                    Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            if ok then avImg.Image = img end
        end)
        local dot = Instance.new("Frame"); dot.Size = UDim2.new(0,13,0,13)
        dot.Position = UDim2.new(1,-13,1,-13); dot.BackgroundColor3 = C.success
        dot.BorderSizePixel = 0; dot.ZIndex = 3; dot.Parent = avFrame; corner(dot, 7)
        stroke(dot, C.bg, 2, 0)
        TweenService:Create(dot,TweenInfo.new(1.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
            {BackgroundTransparency=0.4}):Play()

        lbl({Size=UDim2.new(1,0,0,17),Position=UDim2.new(0,0,0,72),
             Text=Players.LocalPlayer.DisplayName, TextColor3=C.txtP,
             TextSize=14,Font=Enum.Font.GothamBold,
             TextXAlignment=Enum.TextXAlignment.Center,
             TextTruncate=Enum.TextTruncate.AtEnd}, inner)
        lbl({Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,90),
             Text="@"..Players.LocalPlayer.Name, TextColor3=C.txtM,
             TextSize=11,Font=Enum.Font.Gotham,
             TextXAlignment=Enum.TextXAlignment.Center}, inner)

        local div = Instance.new("Frame"); div.Size = UDim2.new(0.8,0,0,1)
        div.Position = UDim2.new(0.1,0,0,112); div.BackgroundColor3 = C.border
        div.BackgroundTransparency = 0.3; div.BorderSizePixel = 0; div.Parent = inner

        local infoRows = {
            {"💻", "Executor", getExecutor()},
            {"🖥️",  "Device",   "PC"},
        }
        local rowY = 120
        for _, r in ipairs(infoRows) do
            local rf = Instance.new("Frame"); rf.BackgroundTransparency = 1
            rf.Size = UDim2.new(1,0,0,34); rf.Position = UDim2.new(0,0,0,rowY)
            rf.Parent = inner
            local ibg = Instance.new("Frame"); ibg.Size = UDim2.new(0,28,0,28)
            ibg.AnchorPoint = Vector2.new(0,0.5); ibg.Position = UDim2.new(0,0,0.5,0)
            ibg.BackgroundColor3 = C.surfaceL; ibg.BorderSizePixel = 0; ibg.Parent = rf
            corner(ibg, 7); stroke(ibg, C.border, 1, 0.5)
            lbl({Size=UDim2.new(1,0,1,0),Text=r[1],TextSize=12,Font=Enum.Font.Gotham,
                 TextXAlignment=Enum.TextXAlignment.Center}, ibg)
            lbl({Size=UDim2.new(1,-36,0,13),Position=UDim2.new(0,34,0,3),
                 Text=r[2],TextColor3=C.txtM,TextSize=10,Font=Enum.Font.Gotham,
                 TextXAlignment=Enum.TextXAlignment.Left}, rf)
            lbl({Size=UDim2.new(1,-36,0,15),Position=UDim2.new(0,34,0,17),
                 Text=r[3],TextColor3=C.txtP,TextSize=12,Font=Enum.Font.GothamSemibold,
                 TextXAlignment=Enum.TextXAlignment.Left,
                 TextTruncate=Enum.TextTruncate.AtEnd}, rf)
            rowY = rowY + 38
        end

        -- HWID row
        local hwRow = Instance.new("Frame"); hwRow.BackgroundTransparency = 1
        hwRow.Size = UDim2.new(1,0,0,34); hwRow.Position = UDim2.new(0,0,0,rowY)
        hwRow.Parent = inner

        local hwIcoBg = Instance.new("Frame"); hwIcoBg.Size = UDim2.new(0,28,0,28)
        hwIcoBg.AnchorPoint = Vector2.new(0,0.5); hwIcoBg.Position = UDim2.new(0,0,0.5,0)
        hwIcoBg.BackgroundColor3 = C.surfaceL; hwIcoBg.BorderSizePixel = 0; hwIcoBg.Parent = hwRow
        corner(hwIcoBg, 7); stroke(hwIcoBg, C.border, 1, 0.5)
        lbl({Size=UDim2.new(1,0,1,0),Text="🔐",TextSize=12,Font=Enum.Font.Gotham,
             TextXAlignment=Enum.TextXAlignment.Center}, hwIcoBg)
        lbl({Size=UDim2.new(1,-36,0,13),Position=UDim2.new(0,34,0,3),
             Text="HWID",TextColor3=C.txtM,TextSize=10,Font=Enum.Font.Gotham,
             TextXAlignment=Enum.TextXAlignment.Left}, hwRow)
        local hwVal = lbl({Size=UDim2.new(1,-64,0,15),Position=UDim2.new(0,34,0,17),
             Text="••••••••••••",TextColor3=C.txtS,TextSize=11,Font=Enum.Font.GothamSemibold,
             TextXAlignment=Enum.TextXAlignment.Left,
             TextTruncate=Enum.TextTruncate.AtEnd}, hwRow)
        local eyeBtn = Instance.new("TextButton")
        eyeBtn.Size = UDim2.new(0,22,0,22); eyeBtn.AnchorPoint = Vector2.new(1,0.5)
        eyeBtn.Position = UDim2.new(1,0,0.5,0); eyeBtn.BackgroundColor3 = C.surfaceL
        eyeBtn.BackgroundTransparency = 0.3; eyeBtn.BorderSizePixel = 0
        eyeBtn.Text = "👁"; eyeBtn.TextSize = 12; eyeBtn.Font = Enum.Font.Gotham
        eyeBtn.AutoButtonColor = false; eyeBtn.ZIndex = 8; eyeBtn.Parent = hwRow
        corner(eyeBtn, 6)
        eyeBtn.MouseButton1Click:Connect(function()
            hwIDvisible = not hwIDvisible
            hwVal.Text = hwIDvisible and fullHWID or "••••••••••••"
            hwVal.TextColor3 = hwIDvisible and C.primary or C.txtS
            eyeBtn.BackgroundTransparency = hwIDvisible and 0.05 or 0.3
        end)
        eyeBtn.MouseEnter:Connect(function()
            TweenService:Create(eyeBtn,TweenInfo.new(0.12),{BackgroundTransparency=0.05}):Play()
        end)
        eyeBtn.MouseLeave:Connect(function()
            TweenService:Create(eyeBtn,TweenInfo.new(0.12),{BackgroundTransparency= hwIDvisible and 0.05 or 0.3}):Play()
        end)
        rowY = rowY + 42

        -- Date + Time card
        local dtCard = Instance.new("Frame")
        dtCard.Size = UDim2.new(1,0,0,52); dtCard.Position = UDim2.new(0,0,0,rowY)
        dtCard.BackgroundColor3 = C.surfaceL; dtCard.BorderSizePixel = 0; dtCard.Parent = inner
        corner(dtCard, 9); stroke(dtCard, C.border, 1, 0.5)
        grad(dtCard, {C.surfaceM, C.bg}, 90)

        local dtInner = Instance.new("Frame"); dtInner.BackgroundTransparency=1
        dtInner.Size = UDim2.new(1,-16,1,0); dtInner.Position = UDim2.new(0,8,0,0)
        dtInner.Parent = dtCard

        local calBg = Instance.new("Frame"); calBg.Size = UDim2.new(0,26,0,26)
        calBg.AnchorPoint = Vector2.new(0,0.5); calBg.Position = UDim2.new(0,0,0.5,0)
        calBg.BackgroundColor3 = C.accent; calBg.BackgroundTransparency = 0.65
        calBg.BorderSizePixel = 0; calBg.Parent = dtInner; corner(calBg, 7)
        lbl({Size=UDim2.new(1,0,1,0),Text="📅",TextSize=12,Font=Enum.Font.Gotham,
             TextXAlignment=Enum.TextXAlignment.Center}, calBg)

        local dateLbl = lbl({Size=UDim2.new(1,-32,0,15),Position=UDim2.new(0,32,0,5),
             Text="",TextColor3=C.txtP,TextSize=11,Font=Enum.Font.GothamSemibold,
             TextXAlignment=Enum.TextXAlignment.Left}, dtInner)
        local timeLbl = lbl({Size=UDim2.new(1,-32,0,15),Position=UDim2.new(0,32,0,24),
             Text="",TextColor3=C.primary,TextSize=13,Font=Enum.Font.GothamBold,
             TextXAlignment=Enum.TextXAlignment.Left}, dtInner)

        local MONTH_ABBR = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}
        local DAY_ABBR   = {"Sun","Mon","Tue","Wed","Thu","Fri","Sat"}
        task.spawn(function()
            while lp and lp.Parent and not self._closed do
                local t = os.date("*t")
                dateLbl.Text = string.format("%s, %02d %s %d",
                    DAY_ABBR[t.wday], t.day, MONTH_ABBR[t.month], t.year)
                timeLbl.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
                task.wait(1)
            end
        end)
    end

    -- ── SHOP BANNER (bottom of window) ────────────────────────────────────
    if hasBanner then
        local sb = cfg.ShopBanner
        local banSep = Instance.new("Frame")
        banSep.Size = UDim2.new(1,0,0,1); banSep.AnchorPoint = Vector2.new(0,1)
        banSep.Position = UDim2.new(0,0,1,-bannerH); banSep.BackgroundColor3 = C.border
        banSep.BackgroundTransparency = 0.4; banSep.BorderSizePixel = 0; banSep.Parent = container

        local banFrame = Instance.new("TextButton")
        banFrame.Name = "ShopBanner"
        banFrame.Size = UDim2.new(1,0,0,bannerH); banFrame.AnchorPoint = Vector2.new(0,1)
        banFrame.Position = UDim2.new(0,0,1,0); banFrame.BackgroundColor3 = C.bg
        banFrame.BorderSizePixel = 0; banFrame.Text = ""; banFrame.AutoButtonColor = false
        banFrame.ZIndex = 8; banFrame.Parent = container
        corner(banFrame, 14)
        local banTopFill = Instance.new("Frame"); banTopFill.Size = UDim2.new(1,0,0,14)
        banTopFill.BackgroundColor3 = C.bg; banTopFill.BorderSizePixel = 0; banTopFill.Parent = banFrame
        grad(banFrame, {C.surfaceM, C.bg}, 90)
        local bStr = stroke(banFrame, C.accent, 0, 1)

        local banInner = Instance.new("Frame"); banInner.BackgroundTransparency=1
        banInner.Size = UDim2.new(1,-24,1,0); banInner.Position = UDim2.new(0,12,0,0)
        banInner.Parent = banFrame

        if sb.Image and sb.Image ~= "" then
            local bImg = Instance.new("ImageLabel"); bImg.BackgroundTransparency = 1
            bImg.Size = UDim2.new(0,30,0,30); bImg.AnchorPoint = Vector2.new(0,0.5)
            bImg.Position = UDim2.new(0,0,0.5,0); bImg.Image = sb.Image
            bImg.ScaleType = Enum.ScaleType.Fit; bImg.ZIndex = 9; bImg.Parent = banInner
        end
        local txOff = (sb.Image and sb.Image ~= "") and 38 or 0
        lbl({Size=UDim2.new(1,-txOff-110,0,17),Position=UDim2.new(0,txOff,0,8),
             Text=sb.Title or "Shop",TextColor3=C.txtP,TextSize=12,
             Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9}, banInner)
        lbl({Size=UDim2.new(1,-txOff-110,0,13),Position=UDim2.new(0,txOff,0,28),
             Text=sb.Sub or "",TextColor3=C.txtM,TextSize=10,
             Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9}, banInner)

        local buyBtn = Instance.new("TextButton")
        buyBtn.Size = UDim2.new(0,100,0,30); buyBtn.AnchorPoint = Vector2.new(1,0.5)
        buyBtn.Position = UDim2.new(1,0,0.5,0); buyBtn.BackgroundColor3 = C.accent
        buyBtn.BorderSizePixel = 0; buyBtn.Text = sb.BuyText or "Buy Now"
        buyBtn.TextColor3 = Color3.new(1,1,1); buyBtn.TextSize = 11
        buyBtn.Font = Enum.Font.GothamBold; buyBtn.AutoButtonColor = false
        buyBtn.ZIndex = 9; buyBtn.Parent = banInner; corner(buyBtn, 9)
        grad(buyBtn, {C.accent, Color3.fromRGB(106,63,224)}, 90)
        local bBtnGlow = stroke(buyBtn, C.accentL, 0, 1)
        buyBtn.MouseEnter:Connect(function()
            TweenService:Create(bBtnGlow,TweenInfo.new(0.15),{Thickness=1.5,Transparency=0.3}):Play()
        end)
        buyBtn.MouseLeave:Connect(function()
            TweenService:Create(bBtnGlow,TweenInfo.new(0.15),{Thickness=0,Transparency=1}):Play()
        end)
        buyBtn.MouseButton1Click:Connect(function()
            if setclipboard and sb.Link then setclipboard(sb.Link) end
        end)
        banFrame.MouseEnter:Connect(function()
            TweenService:Create(bStr,TweenInfo.new(0.2),{Transparency=0.5,Thickness=1}):Play()
        end)
        banFrame.MouseLeave:Connect(function()
            TweenService:Create(bStr,TweenInfo.new(0.2),{Transparency=1,Thickness=0}):Play()
        end)
        banFrame.MouseButton1Click:Connect(function()
            if setclipboard and sb.Link then setclipboard(sb.Link) end
        end)
    end

    -- ════════ KEY AREA ════════════════════════════════════════════════════
    -- The key panel fills the space between the left panel and changelog panel.
    local mainArea = Instance.new("Frame")
    mainArea.Name = "MainArea"; mainArea.BackgroundTransparency = 1
    mainArea.ClipsDescendants = true
    mainArea.Size = UDim2.new(0,keyW,0,mainAreaH)
    mainArea.Position = UDim2.new(0,leftW,0,46)
    mainArea.Parent = container

    local keyTab = Instance.new("Frame"); keyTab.Name = "KeyTab"
    keyTab.Size = UDim2.new(1,0,1,0); keyTab.BackgroundTransparency = 1
    keyTab.Parent = mainArea

    -- Content frame (inner padding)
    local content = Instance.new("Frame"); content.Name = "KeyContent"
    content.Size = UDim2.new(1,-44,1,-32); content.Position = UDim2.new(0,22,0,18)
    content.BackgroundTransparency = 1; content.Parent = keyTab

    -- ── Compact panel header (Arquel-style: small icon + title, left-aligned) ──
    -- No large bouncing icon. Just an inline icon tile and text.
    local hIconBg = Instance.new("Frame"); hIconBg.Name = "HeaderIcon"
    hIconBg.Size = UDim2.new(0,28,0,28)
    hIconBg.Position = UDim2.new(0,0,0,0)
    hIconBg.BackgroundColor3 = C.surfaceL
    hIconBg.BackgroundTransparency = loading and 1 or 0
    hIconBg.BorderSizePixel = 0; hIconBg.ZIndex = 3
    hIconBg.Parent = content
    corner(hIconBg, 8)
    stroke(hIconBg, C.primary, 1, 0.5)

    if cfg.LogoImage and cfg.LogoImage ~= "" then
        local hIco = Instance.new("ImageLabel")
        hIco.BackgroundTransparency = 1
        hIco.Size = UDim2.new(0,20,0,20)
        hIco.AnchorPoint = Vector2.new(0.5,0.5)
        hIco.Position = UDim2.new(0.5,0,0.5,0)
        hIco.Image = cfg.LogoImage; hIco.ScaleType = Enum.ScaleType.Fit
        hIco.ZIndex = 4; hIco.Parent = hIconBg
    end

    local hTitleLbl = lbl({
        Size=UDim2.new(1,-36,0,28), Position=UDim2.new(0,34,0,0),
        Text="Key Verification", TextColor3=C.txtP, TextSize=15,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
        TextTransparency=loading and 1 or 0}, content)

    -- Subtitle (muted, left-aligned like Arquel)
    local subLbl = lbl({
        Size=UDim2.new(1,0,0,13), Position=UDim2.new(0,0,0,34),
        Text="Enter your key to continue",
        TextColor3=C.txtM, TextSize=10, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTransparency=loading and 1 or 0}, content)

    -- Divider under header
    local hDiv = Instance.new("Frame"); hDiv.Name = "HeaderDivider"
    hDiv.Size = UDim2.new(1,0,0,1); hDiv.Position = UDim2.new(0,0,0,54)
    hDiv.BackgroundColor3 = C.border; hDiv.BackgroundTransparency = 0.4
    hDiv.BorderSizePixel = 0; hDiv.Parent = content

    -- ── Section: Duration selection ───────────────────────────────────────
    local s1Lbl = lbl({
        Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,65),
        Text="Select key duration",
        TextColor3=C.txtM, TextSize=10, Font=Enum.Font.GothamSemibold,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTransparency=loading and 1 or 0}, content)

    -- Provider buttons
    local providers = cfg.Providers or {}
    local provRow = Instance.new("Frame"); provRow.Name = "ProvRow"
    provRow.Size = UDim2.new(1,0,0,58); provRow.Position = UDim2.new(0,0,0,80)
    provRow.BackgroundTransparency = 1; provRow.Parent = content

    if #providers > 0 then
        local gap = 0.022
        local bw  = (1 - gap*(#providers-1)) / #providers
        for i, prov in ipairs(providers) do
            local xp = (i-1)*(bw+gap)
            local btn = Instance.new("TextButton"); btn.Name = "Prov_"..prov.name
            btn.Size = UDim2.new(bw,0,1,0); btn.Position = UDim2.new(xp,0,0,0)
            btn.BackgroundColor3 = C.surfaceL; btn.BorderSizePixel = 0
            btn.Text = ""; btn.AutoButtonColor = false
            btn.BackgroundTransparency = loading and 1 or 0
            btn.Parent = provRow; corner(btn, 9)
            local ps = stroke(btn, C.border, 1, 0.4)

            -- Colored top accent bar (gives each button a unique identity)
            local topBar2 = Instance.new("Frame")
            topBar2.Size = UDim2.new(0.55,0,0,2)
            topBar2.AnchorPoint = Vector2.new(0.5,0)
            topBar2.Position = UDim2.new(0.5,0,0,0)
            topBar2.BackgroundColor3 = prov.color or C.primary
            topBar2.BackgroundTransparency = 0.25
            topBar2.BorderSizePixel = 0; topBar2.ZIndex = 3
            topBar2.Parent = btn; corner(topBar2, 1)

            lbl({Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,8),
                 Text=prov.duration or prov.name,TextColor3=prov.color or C.primary,
                 TextSize=15,Font=Enum.Font.GothamBold,
                 TextXAlignment=Enum.TextXAlignment.Center,
                 TextTransparency=loading and 1 or 0}, btn)

            local dots = string.rep("●", prov.checkpoints or 1, " ")
            lbl({Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,0,30),
                 Text=dots,TextColor3=prov.color or C.primary,TextSize=8,
                 Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Center,
                 TextTransparency=loading and 1 or 0}, btn)

            local cpText = prov.checkpoints and
                (tostring(prov.checkpoints).." Checkpoint"..((prov.checkpoints>1) and "s" or "")) or ""
            lbl({Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,0,44),
                 Text=cpText,TextColor3=C.txtM,TextSize=9,Font=Enum.Font.Gotham,
                 TextXAlignment=Enum.TextXAlignment.Center,
                 TextTransparency=loading and 1 or 0}, btn)

            local cd = prov.colorDark or prov.color or C.primaryD
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.surfaceM}):Play()
                TweenService:Create(ps,TweenInfo.new(0.15),{Color=prov.color or C.primary,Transparency=0.08,Thickness=1.5}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.surfaceL}):Play()
                TweenService:Create(ps,TweenInfo.new(0.15),{Color=C.border,Transparency=0.4,Thickness=1}):Play()
            end)
            btn.MouseButton1Down:Connect(function()
                TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=cd}):Play()
            end)
            btn.MouseButton1Up:Connect(function()
                TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=C.surfaceM}):Play()
            end)
            btn.MouseButton1Click:Connect(function() self:_getKey(prov) end)
        end
    end

    -- ── Section: Key input ────────────────────────────────────────────────
    local s2Lbl = lbl({
        Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,148),
        Text="Paste your key below",
        TextColor3=C.txtM, TextSize=10, Font=Enum.Font.GothamSemibold,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTransparency=loading and 1 or 0}, content)

    local inputSec = Instance.new("Frame"); inputSec.Name = "InputSection"
    inputSec.Size = UDim2.new(1,0,0,42); inputSec.Position = UDim2.new(0,0,0,163)
    inputSec.BackgroundColor3 = C.surfaceL; inputSec.BorderSizePixel = 0
    inputSec.BackgroundTransparency = loading and 1 or 0
    inputSec.Parent = content; corner(inputSec, 9)
    local inputStroke = stroke(inputSec, C.border, 1, 0.5)

    lbl({Size=UDim2.new(0,28,1,0),Position=UDim2.new(0,6,0,0),
         Text="🔑",TextSize=14,Font=Enum.Font.Gotham,
         TextTransparency=loading and 1 or 0}, inputSec)

    local keyInput = Instance.new("TextBox"); keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1,-42,1,0); keyInput.Position = UDim2.new(0,38,0,0)
    keyInput.BackgroundTransparency = 1; keyInput.PlaceholderText = "Paste your key here..."
    keyInput.PlaceholderColor3 = C.txtM; keyInput.Text = ""
    keyInput.TextColor3 = C.txtP; keyInput.TextSize = 13
    keyInput.TextXAlignment = Enum.TextXAlignment.Left
    keyInput.TextTruncate = Enum.TextTruncate.AtEnd
    keyInput.Font = Enum.Font.Gotham; keyInput.ClearTextOnFocus = false
    keyInput.TextTransparency = loading and 1 or 0
    keyInput.Parent = inputSec
    keyInput.Focused:Connect(function()
        TweenService:Create(inputStroke,TweenInfo.new(0.18),{Color=C.primary,Thickness=2,Transparency=0}):Play()
    end)
    keyInput.FocusLost:Connect(function(enter)
        TweenService:Create(inputStroke,TweenInfo.new(0.18),{Color=C.border,Thickness=1,Transparency=0.5}):Play()
        if enter then self:_verify() end
    end)

    -- Verify button (clean, no gradient — less AI-looking)
    local verifyBtn = Instance.new("TextButton"); verifyBtn.Name = "VerifyButton"
    verifyBtn.Size = UDim2.new(1,0,0,42); verifyBtn.Position = UDim2.new(0,0,0,213)
    verifyBtn.BackgroundColor3 = C.success; verifyBtn.BorderSizePixel = 0
    verifyBtn.Text = ""; verifyBtn.AutoButtonColor = false
    verifyBtn.BackgroundTransparency = loading and 1 or 0
    verifyBtn.Parent = content; corner(verifyBtn, 9)
    local vGlow = stroke(verifyBtn, C.successG, 0, 0.8)
    lbl({Size=UDim2.new(0,26,1,0),Position=UDim2.new(0,10,0,0),
         Text="✓",TextColor3=Color3.new(1,1,1),TextSize=17,Font=Enum.Font.GothamBold,
         TextXAlignment=Enum.TextXAlignment.Center,
         TextTransparency=loading and 1 or 0}, verifyBtn)
    lbl({Name="ButtonText",Size=UDim2.new(1,0,1,0),Text="Verify Key",
        TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamSemibold,TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Center,
        TextTransparency=loading and 1 or 0}, verifyBtn)
    verifyBtn.MouseEnter:Connect(function()
        TweenService:Create(verifyBtn,TweenInfo.new(0.15),{BackgroundColor3=C.successG}):Play()
        TweenService:Create(vGlow,TweenInfo.new(0.15),{Thickness=2,Transparency=0.3}):Play()
    end)
    verifyBtn.MouseLeave:Connect(function()
        TweenService:Create(verifyBtn,TweenInfo.new(0.15),{BackgroundColor3=C.success}):Play()
        TweenService:Create(vGlow,TweenInfo.new(0.15),{Thickness=0,Transparency=0.8}):Play()
    end)
    verifyBtn.MouseButton1Down:Connect(function()
        TweenService:Create(verifyBtn,TweenInfo.new(0.08),{BackgroundColor3=C.successD}):Play()
    end)
    verifyBtn.MouseButton1Up:Connect(function()
        TweenService:Create(verifyBtn,TweenInfo.new(0.08),{BackgroundColor3=C.success}):Play()
    end)
    verifyBtn.MouseButton1Click:Connect(function() self:_verify() end)

    -- ── Footer icon row (fills space below verify, mirrors Arquel's icon strip) ──
    local footDiv = Instance.new("Frame"); footDiv.Name = "FooterDivider"
    footDiv.Size = UDim2.new(1,0,0,1); footDiv.Position = UDim2.new(0,0,0,266)
    footDiv.BackgroundColor3 = C.border; footDiv.BackgroundTransparency = 0.45
    footDiv.BorderSizePixel = 0; footDiv.Parent = content

    local footRow = Instance.new("Frame"); footRow.Name = "FooterIcons"
    footRow.Size = UDim2.new(1,0,0,28); footRow.Position = UDim2.new(0,0,0,276)
    footRow.BackgroundTransparency = 1; footRow.Parent = content

    local footX = 0
    -- Discord button
    if cfg.DiscordLink and cfg.DiscordLink ~= "" then
        local fDisc = Instance.new("TextButton")
        fDisc.Size = UDim2.new(0,28,0,28); fDisc.Position = UDim2.new(0,footX,0,0)
        fDisc.BackgroundColor3 = C.discord; fDisc.BackgroundTransparency = 0.68
        fDisc.BorderSizePixel = 0; fDisc.AutoButtonColor = false; fDisc.ZIndex = 4
        fDisc.Parent = footRow; corner(fDisc, 7)
        stroke(fDisc, C.discord, 1, 0.55)
        if cfg.DiscordIcon and cfg.DiscordIcon ~= "" then
            fDisc.Text = ""
            local fi = Instance.new("ImageLabel"); fi.BackgroundTransparency = 1
            fi.Size = UDim2.new(0,16,0,16); fi.AnchorPoint = Vector2.new(0.5,0.5)
            fi.Position = UDim2.new(0.5,0,0.5,0); fi.Image = cfg.DiscordIcon
            fi.ScaleType = Enum.ScaleType.Fit; fi.ZIndex = 5; fi.Parent = fDisc
        else
            fDisc.Text = "D"; fDisc.TextColor3 = Color3.new(1,1,1)
            fDisc.TextSize = 13; fDisc.Font = Enum.Font.GothamBold
        end
        fDisc.MouseEnter:Connect(function()
            TweenService:Create(fDisc,TweenInfo.new(0.15),{BackgroundTransparency=0.25}):Play()
        end)
        fDisc.MouseLeave:Connect(function()
            TweenService:Create(fDisc,TweenInfo.new(0.15),{BackgroundTransparency=0.68}):Play()
        end)
        fDisc.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(cfg.DiscordLink) end
        end)
        footX = footX + 36
    end
    -- Shop link button
    if cfg.ShopLink and cfg.ShopLink ~= "" then
        local fShop = Instance.new("TextButton")
        fShop.Size = UDim2.new(0,28,0,28); fShop.Position = UDim2.new(0,footX,0,0)
        fShop.BackgroundColor3 = C.surfaceL; fShop.BackgroundTransparency = 0.3
        fShop.BorderSizePixel = 0; fShop.AutoButtonColor = false; fShop.ZIndex = 4
        fShop.Text = "🛒"; fShop.TextSize = 13; fShop.Font = Enum.Font.Gotham
        fShop.Parent = footRow; corner(fShop, 7)
        stroke(fShop, C.border, 1, 0.5)
        fShop.MouseEnter:Connect(function()
            TweenService:Create(fShop,TweenInfo.new(0.15),{BackgroundTransparency=0.05}):Play()
        end)
        fShop.MouseLeave:Connect(function()
            TweenService:Create(fShop,TweenInfo.new(0.15),{BackgroundTransparency=0.3}):Play()
        end)
        fShop.MouseButton1Click:Connect(function()
            if setclipboard then setclipboard(cfg.ShopLink) end
        end)
    end

    -- ════════ CHANGELOG PANEL (right side, always visible — Arquel style) ═══
    local clTab = nil
    if hasCL and not mobile then
        -- Vertical separator on the left edge of the CL panel
        local clSep = Instance.new("Frame")
        clSep.Size = UDim2.new(0,1,0,mainAreaH)
        clSep.Position = UDim2.new(1,-clW,0,46)
        clSep.BackgroundColor3 = C.border
        clSep.BackgroundTransparency = 0.3
        clSep.BorderSizePixel = 0; clSep.ZIndex = 6
        clSep.Parent = container

        clTab = Instance.new("Frame"); clTab.Name = "ChangelogPanel"
        clTab.Size = UDim2.new(0,clW-1,0,mainAreaH)
        clTab.Position = UDim2.new(1,-(clW-1),0,46)
        clTab.BackgroundColor3 = C.bg
        clTab.BorderSizePixel = 0; clTab.ZIndex = 5
        clTab.Parent = container

        -- Fill top-left corner (rounded container clips it otherwise)
        local clCornerFill = Instance.new("Frame")
        clCornerFill.Size = UDim2.new(1,0,0,14)
        clCornerFill.BackgroundColor3 = C.bg
        clCornerFill.BorderSizePixel = 0; clCornerFill.Parent = clTab

        -- Panel header
        local clHeadRow = Instance.new("Frame")
        clHeadRow.Size = UDim2.new(1,-16,0,22)
        clHeadRow.Position = UDim2.new(0,8,0,12)
        clHeadRow.BackgroundTransparency = 1; clHeadRow.Parent = clTab

        lbl({Size=UDim2.new(1,0,1,0), Text="Changelog",
             TextColor3=C.txtS, TextSize=11, Font=Enum.Font.GothamBold,
             TextXAlignment=Enum.TextXAlignment.Left}, clHeadRow)

        -- Divider under CL header
        local clHDiv = Instance.new("Frame")
        clHDiv.Size = UDim2.new(1,-16,0,1)
        clHDiv.Position = UDim2.new(0,8,0,38)
        clHDiv.BackgroundColor3 = C.border
        clHDiv.BackgroundTransparency = 0.4
        clHDiv.BorderSizePixel = 0; clHDiv.Parent = clTab

        -- Scrollable changelog entries
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1,-8,1,-50)
        scroll.Position = UDim2.new(0,4,0,44)
        scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 2; scroll.ScrollBarImageColor3 = C.surfaceL
        scroll.CanvasSize = UDim2.new(0,0,0,0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = clTab
        local sLayout = Instance.new("UIListLayout", scroll)
        sLayout.Padding = UDim.new(0,5); sLayout.SortOrder = Enum.SortOrder.LayoutOrder

        for idx, entry in ipairs(cfg.Changelog) do
            local ef = Instance.new("Frame"); ef.BackgroundColor3 = C.surfaceL
            ef.BorderSizePixel = 0; ef.Size = UDim2.new(1,0,0,0)
            ef.AutomaticSize = Enum.AutomaticSize.Y; ef.LayoutOrder = idx
            ef.Parent = scroll
            corner(ef, 7); stroke(ef, C.border, 1, 0.55)

            local ep = Instance.new("UIPadding",ef)
            ep.PaddingLeft=UDim.new(0,8); ep.PaddingRight=UDim.new(0,8)
            ep.PaddingTop=UDim.new(0,7);  ep.PaddingBottom=UDim.new(0,7)

            local ec = Instance.new("Frame"); ec.BackgroundTransparency=1
            ec.Size=UDim2.new(1,0,0,0); ec.AutomaticSize=Enum.AutomaticSize.Y
            ec.Parent=ef
            local el2 = Instance.new("UIListLayout",ec)
            el2.Padding=UDim.new(0,3); el2.SortOrder=Enum.SortOrder.LayoutOrder

            -- Version + date header row
            local hr = Instance.new("Frame"); hr.BackgroundTransparency=1
            hr.Size=UDim2.new(1,0,0,17); hr.LayoutOrder=1; hr.Parent=ec
            lbl({Size=UDim2.new(0.55,0,1,0), Text="v"..(entry.version or "?"),
                 TextColor3=C.primary, TextSize=11, Font=Enum.Font.GothamBold,
                 TextXAlignment=Enum.TextXAlignment.Left}, hr)
            lbl({Size=UDim2.new(0.45,0,1,0), Position=UDim2.new(0.55,0,0,0),
                 Text=entry.date or "", TextColor3=C.txtM, TextSize=9, Font=Enum.Font.Gotham,
                 TextXAlignment=Enum.TextXAlignment.Right}, hr)

            for ci, change in ipairs(entry.changes or {}) do
                lbl({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                     Text="• "..change, TextColor3=C.txtS, TextSize=10, Font=Enum.Font.Gotham,
                     TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
                     LayoutOrder=ci+1}, ec)
            end
        end
    end

    -- ── Store elements ────────────────────────────────────────────────────
    self.el = {
        backdrop    = backdrop,
        container   = container,
        mainArea    = mainArea,
        keyTab      = keyTab,
        clTab       = clTab,
        content     = content,
        iconFrame   = hIconBg,   -- small header icon, used by _pulse
        iconImg     = nil,
        inputFrame  = inputSec,
        keyInput    = keyInput,
        inputStroke = inputStroke,
        verifyButton= verifyBtn,
        headerText  = brand:FindFirstChild("HeaderText"),
        closeButton = closeBtn,
        tabBtns     = {},        -- no tabs; kept for compat
        s1Lbl       = s1Lbl,
        provRow     = provRow,
        s2Lbl       = s2Lbl,
        titleLbl    = hTitleLbl,
        subLbl      = subLbl,
    }

    -- ── Particles ─────────────────────────────────────────────────────────
    self:_particles(container)

    -- ── Parent ────────────────────────────────────────────────────────────
    self.gui.Parent = game:GetService("CoreGui")
    self.gui.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            local bl = Lighting:FindFirstChild("SorinBlur"); if bl then bl:Destroy() end
        end
    end)

    -- ── Entrance / loading ────────────────────────────────────────────────
    if loading then
        task.spawn(function() self:_loadAnim() end)
    else
        backdrop.BackgroundTransparency = 1; container.BackgroundTransparency = 1
        TweenService:Create(backdrop,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{BackgroundTransparency=0.42}):Play()
        TweenService:Create(container,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{BackgroundTransparency=0}):Play()
    end
end

-- ── Loading animation ─────────────────────────────────────────────────────
-- Simplified: no bouncing icon. Clean staggered fade-in.
function SorinUILib:_loadAnim()
    local e = self.el
    TweenService:Create(e.backdrop, TweenInfo.new(0.45,Enum.EasingStyle.Quad),{BackgroundTransparency=0.42}):Play()
    TweenService:Create(e.container,TweenInfo.new(0.45,Enum.EasingStyle.Quad),{BackgroundTransparency=0}):Play()
    task.wait(0.5)
    -- Fade in header icon
    if e.iconFrame then
        TweenService:Create(e.iconFrame,TweenInfo.new(0.3),{BackgroundTransparency=0}):Play()
    end
    -- Fade in text labels (header title, subtitle, section labels)
    for i, el in ipairs({e.titleLbl, e.subLbl, e.s1Lbl, e.s2Lbl}) do
        if el then
            task.delay((i-1)*0.07, function()
                TweenService:Create(el,TweenInfo.new(0.3),{TextTransparency=0}):Play()
            end)
        end
    end
    task.wait(0.45)
    -- Fade in provider buttons
    for _, btn in ipairs(e.provRow:GetChildren()) do
        if btn:IsA("TextButton") then
            TweenService:Create(btn,TweenInfo.new(0.25),{BackgroundTransparency=0}):Play()
            for _, d in ipairs(btn:GetDescendants()) do
                if d:IsA("TextLabel") then
                    pcall(function() TweenService:Create(d,TweenInfo.new(0.25),{TextTransparency=0}):Play() end)
                end
            end
        end
    end
    task.wait(0.2)
    -- Fade in input
    TweenService:Create(e.inputFrame,TweenInfo.new(0.3),{BackgroundTransparency=0}):Play()
    for _, d in ipairs(e.inputFrame:GetDescendants()) do
        pcall(function()
            if d:IsA("TextLabel") or d:IsA("TextBox") then
                TweenService:Create(d,TweenInfo.new(0.3),{TextTransparency=0}):Play()
            end
        end)
    end
    -- Fade in verify button
    TweenService:Create(e.verifyButton,TweenInfo.new(0.3),{BackgroundTransparency=0}):Play()
    for _, d in ipairs(e.verifyButton:GetDescendants()) do
        pcall(function()
            if d:IsA("TextLabel") then
                TweenService:Create(d,TweenInfo.new(0.3),{TextTransparency=0}):Play()
            end
        end)
    end
end

-- ── Tab switching (no-op: changelog is now a permanent side panel) ─────────
function SorinUILib:_switchTab(_id)
    -- Tabs have been replaced by a 3-panel layout. Nothing to switch.
end

-- ── Status ────────────────────────────────────────────────────────────────
function SorinUILib:_status(msg, color, duration)
    local ht = self.el.headerText; if not ht then return end
    if not msg or msg == "" then
        TweenService:Create(ht,TweenInfo.new(0.2),{TextColor3=C.txtP}):Play()
        ht.Text = self._hdDef; return
    end
    TweenService:Create(ht,TweenInfo.new(0.15),{TextColor3=color or C.txtS}):Play()
    ht.Text = msg
    if self._hdTimer then task.cancel(self._hdTimer) end
    if duration and duration > 0 then
        self._hdTimer = task.delay(duration, function()
            if ht and ht.Text == msg then
                TweenService:Create(ht,TweenInfo.new(0.3),{TextColor3=C.txtP}):Play()
                ht.Text = self._hdDef
            end
        end)
    end
end

-- ── Shake ─────────────────────────────────────────────────────────────────
function SorinUILib:_shake()
    local f = self.el.inputFrame; if not f then return end
    local o = f.Position
    for _ = 1, 3 do
        TweenService:Create(f,TweenInfo.new(0.05),{Position=UDim2.new(o.X.Scale,o.X.Offset-8,o.Y.Scale,o.Y.Offset)}):Play(); task.wait(0.05)
        TweenService:Create(f,TweenInfo.new(0.05),{Position=UDim2.new(o.X.Scale,o.X.Offset+8,o.Y.Scale,o.Y.Offset)}):Play(); task.wait(0.05)
    end
    f.Position = o
end

-- ── Success pulse (pulses the compact header icon) ────────────────────────
function SorinUILib:_pulse()
    local iF = self.el.iconFrame; if not iF then return end
    TweenService:Create(iF,TweenInfo.new(0.18,Enum.EasingStyle.Back),{Size=UDim2.new(0,36,0,36)}):Play()
    task.wait(0.2)
    TweenService:Create(iF,TweenInfo.new(0.14),{Size=UDim2.new(0,28,0,28)}):Play()
end

-- ── Spinner ───────────────────────────────────────────────────────────────
function SorinUILib:_spinner(btn, text, on)
    local bt = btn:FindFirstChild("ButtonText"); if bt then bt.Text = text end
    btn.Interactable = not on
    local sp = btn:FindFirstChild("Spinner")
    if on and not sp then
        sp = Instance.new("Frame"); sp.Name="Spinner"
        sp.Size=UDim2.new(0,13,0,13); sp.Position=UDim2.new(0,14,0.5,-6)
        sp.BackgroundColor3=C.txtP; sp.BackgroundTransparency=0.65
        sp.BorderSizePixel=0; sp.Parent=btn; corner(sp,10)
        TweenService:Create(sp,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),{Rotation=360}):Play()
    elseif not on and sp then sp:Destroy() end
end

-- ── Get key link ──────────────────────────────────────────────────────────
function SorinUILib:_getKey(prov)
    if setclipboard and prov.link then
        setclipboard(prov.link)
        self:_status("🎮 "..prov.name.." link copied! Open it in your browser ✓", prov.color or C.primary, 5)
    else
        self:_status("Link: "..(prov.link or ""), prov.color or C.primary, 10)
    end
end

-- ── Welcome card ──────────────────────────────────────────────────────────
function SorinUILib:_welcome(username)
    local e = self.el; if not (self.cfg.WelcomeEnabled and e.content) then return end
    local card = Instance.new("Frame"); card.Name="WelcomeCard"
    card.Size=UDim2.new(1,0,0,0); card.Position=UDim2.new(0,0,0.5,0)
    card.AnchorPoint=Vector2.new(0,0.5); card.BackgroundColor3=C.primary
    card.BorderSizePixel=0; card.ClipsDescendants=true; card.ZIndex=25
    card.Parent=e.content; corner(card,12)
    grad(card,{C.primary,C.accent},90); stroke(card,C.primaryG,1,0.35)
    TweenService:Create(card,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Size=UDim2.new(1,0,0,80)}):Play()
    task.wait(0.12)
    lbl({Size=UDim2.new(0,50,1,0),Text="🎉",TextSize=30,Font=Enum.Font.Gotham,ZIndex=26}, card)
    lbl({Size=UDim2.new(1,-56,0,26),Position=UDim2.new(0,52,0,11),
         Text="Welcome back, "..tostring(username).."!",TextColor3=Color3.new(1,1,1),
         TextSize=15,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=26}, card)
    lbl({Size=UDim2.new(1,-56,0,18),Position=UDim2.new(0,52,0,40),
         Text="Your key has been verified successfully ✓",
         TextColor3=Color3.fromRGB(200,230,255),TextSize=11,Font=Enum.Font.Gotham,
         TextXAlignment=Enum.TextXAlignment.Left,ZIndex=26}, card)
    task.delay(2.2, function()
        TweenService:Create(card,TweenInfo.new(0.3),{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1}):Play()
        task.wait(0.3); pcall(function() card:Destroy() end)
    end)
end

-- ── Key info card ─────────────────────────────────────────────────────────
function SorinUILib:_keyInfo(data, _key)
    local e = self.el
    local function fmt(s)
        if s<=0 then return "Expired" end
        local d=math.floor(s/86400); local h=math.floor((s%86400)/3600); local m=math.floor((s%3600)/60)
        if d>0 then return d.."d "..h.."h "..m.."m" elseif h>0 then return h.."h "..m.."m" end
        return m.."m"
    end
    local secsLeft = (data and data.key_expires and data.key_expires>0) and math.max(0, data.key_expires-os.time()) or nil
    local toHide = {e.s1Lbl,e.provRow,e.s2Lbl,e.inputFrame,e.verifyButton}
    for _, el in ipairs(toHide) do
        if el then
            TweenService:Create(el,TweenInfo.new(0.25),{BackgroundTransparency=1}):Play()
            if el:IsA("TextLabel") then TweenService:Create(el,TweenInfo.new(0.25),{TextTransparency=1}):Play() end
            for _, ch in ipairs(el:GetDescendants()) do
                pcall(function() TweenService:Create(ch,TweenInfo.new(0.2),{TextTransparency=1,BackgroundTransparency=1,ImageTransparency=1}):Play() end)
            end
        end
    end
    task.wait(0.28)
    for _, el in ipairs(toHide) do if el then el.Visible=false end end
    local ctr = e.container
    TweenService:Create(ctr,TweenInfo.new(0.45,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),
        {Size=UDim2.new(ctr.Size.X.Scale,ctr.Size.X.Offset,0,295)}):Play()
    task.wait(0.12)
    local card = Instance.new("Frame"); card.Name="KeyInfoCard"
    card.Size=UDim2.new(1,0,0,0); card.Position=UDim2.new(0,0,0,100)
    card.BackgroundColor3=C.surfaceL; card.BorderSizePixel=0
    card.ClipsDescendants=true; card.Parent=e.content
    corner(card,12); stroke(card,C.success,1,0.45)
    TweenService:Create(card,TweenInfo.new(0.45,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),
        {Size=UDim2.new(1,0,0,126)}):Play()
    task.wait(0.16)
    local rows = {
        {"✅","Status",    "Key active",                                   C.success},
        {"⏳","Valid for", secsLeft and fmt(secsLeft) or "Lifetime",       C.primary},
        {"🔢","Executions",tostring(data and data.executions or 0),        C.txtS},
        {"📋","Type",      (data and data.note) or "—",                    C.txtM},
    }
    for i, row in ipairs(rows) do
        local rf=Instance.new("Frame"); rf.BackgroundTransparency=1
        rf.Size=UDim2.new(1,-24,0,28); rf.Position=UDim2.new(0,12,0,5+(i-1)*30); rf.Parent=card
        local iL=lbl({Size=UDim2.new(0,22,1,0),Text=row[1],TextSize=14,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextTransparency=1},rf)
        local lL=lbl({Size=UDim2.new(0,110,1,0),Position=UDim2.new(0,26,0,0),Text=row[2],TextColor3=C.txtM,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextTransparency=1},rf)
        local vL=lbl({Size=UDim2.new(1,-136,1,0),Position=UDim2.new(0,136,0,0),Text=row[3],TextColor3=row[4],TextSize=12,Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Right,TextTransparency=1},rf)
        task.delay(i*0.07,function()
            TweenService:Create(iL,TweenInfo.new(0.3),{TextTransparency=0}):Play()
            TweenService:Create(lL,TweenInfo.new(0.3),{TextTransparency=0}):Play()
            TweenService:Create(vL,TweenInfo.new(0.3),{TextTransparency=0}):Play()
        end)
    end
    task.wait(2.2); self:close()
end

-- ── Verify ────────────────────────────────────────────────────────────────
function SorinUILib:_verify()
    local cfg = self.cfg
    local key = self.el.keyInput.Text:gsub("%s+","")
    if key=="" then self:_status("Please enter a key",C.err,3); self:_shake(); return end
    self:_spinner(self.el.verifyButton,"Verifying...",true)
    self:_status("Verifying key...",C.primary,0)
    self.el.keyInput.Interactable=false
    local ok,result=pcall(function()
        if cfg.CheckKey then return cfg.CheckKey(key) end
        error("CheckKey not configured")
    end)
    if ok and result then
        if result.status=="key_valid" then
            saveKey(key); getgenv().SORIN_KEY=key
            self:_status("Key verified!",C.success,0); self:_pulse(); task.wait(0.42)
            if cfg.WelcomeEnabled then
                self:_welcome((result.user and result.user.username) or Players.LocalPlayer.Name)
                task.wait(2.6)
            end
            self:_keyInfo(result.user,key); return
        elseif result.status=="invalid_fingerprint" then
            self:_status("Fingerprint mismatch - reset via Discord bot",C.err,6)
        elseif result.status=="key_expired" then
            self:_status("Key expired! Get a new one above",C.err,5)
        elseif result.status=="key_blacklisted" then
            self:_status("Blacklisted: "..(result.user and result.user.blacklist_reason or "?"),C.err,6)
        elseif result.status=="invalid_key" then
            self:_status("Key not found - check spelling",C.err,4)
        elseif result.status=="invalid_script_id" then
            self:_status("Config error - contact devs",C.err,5)
        else
            self:_status("Error: "..tostring(result.status),C.err,4)
        end
    else
        self:_status("Connection error - try again",C.err,4)
    end
    self:_shake()
    self:_spinner(self.el.verifyButton,"Verify Key",false)
    self.el.keyInput.Interactable=true
end

-- ── Close ─────────────────────────────────────────────────────────────────
function SorinUILib:close()
    self._closed=true; getgenv().SORIN_CLOSED=true
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    self._conns={}
    if not self.gui then return end
    TweenService:Create(self.el.container,TweenInfo.new(0.22),{BackgroundTransparency=1}):Play()
    TweenService:Create(self.el.backdrop, TweenInfo.new(0.22),{BackgroundTransparency=1}):Play()
    task.wait(0.24)
    local bl=Lighting:FindFirstChild("SorinBlur"); if bl then bl:Destroy() end
    self.gui:Destroy(); self.gui=nil
end

-- ── run() – builds, waits, calls LoadScript ───────────────────────────────
function SorinUILib:run()
    self:build()
    task.spawn(function()
        if self.cfg.LoadingEnabled then task.wait(2.0) end
        local saved = loadKey()
        if saved and saved ~= "" then
            self:_status("Checking saved key...", C.primary, 0)
            local ok, result = pcall(function()
                if self.cfg.CheckKey then return self.cfg.CheckKey(saved) end
                error("no CheckKey")
            end)
            if ok and result and result.status=="key_valid" then
                getgenv().SORIN_KEY=saved
                self:_status("Key verified!",C.success,0); self:_pulse(); task.wait(0.42)
                if self.cfg.WelcomeEnabled then
                    self:_welcome((result.user and result.user.username) or Players.LocalPlayer.Name)
                    task.wait(2.6)
                end
                self:_keyInfo(result.user,saved)
            else
                clearKey(); self:_status("",nil,0)
            end
        end
    end)
    while not getgenv().SORIN_CLOSED do task.wait(0.1) end
    if self.cfg.LoadScript then self.cfg.LoadScript(getgenv().SORIN_KEY) end
end

return SorinUILib
