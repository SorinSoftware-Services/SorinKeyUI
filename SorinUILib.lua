
local SorinUILib = {}
SorinUILib.__index = SorinUILib

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")

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
}

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
        kp[i] = ColorSequenceKeypoint.new((i-1)/(math.max(#cols-1,1)), col)
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
local function clearKey() if fsOk then pcall(function() if delfile then delfile("sorin_key.txt") end end) end end

local function getExecutor()
    for _, fn in ipairs({"identifyexecutor","getexecutorname"}) do
        if getfenv and type(getfenv()[fn])=="function" then
            local ok, v = pcall(getfenv()[fn]); if ok and v then return tostring(v) end
        end
    end
    if rawget(_G,"syn")       then return "Synapse X" end
    if rawget(_G,"KRNL_LOADED") then return "Krnl"     end
    return "Unknown"
end

local function getHWID()
    for _, fn in ipairs({"gethwid","get_hwid","getuniqueid"}) do
        if getfenv and type(getfenv()[fn])=="function" then
            local ok, v = pcall(getfenv()[fn]); if ok and v then return tostring(v):sub(1,14).."…" end
        end
    end
    return "N/A"
end

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

    self.gui = Instance.new("ScreenGui")
    self.gui.Name           = "SorinKeyUI"
    self.gui.ResetOnSpawn   = false
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.gui.IgnoreGuiInset = true

    local backdrop = Instance.new("Frame")
    backdrop.Size                 = UDim2.new(1,0,1,0)
    backdrop.BackgroundColor3     = Color3.new(0,0,0)
    backdrop.BackgroundTransparency = loading and 1 or 0.42
    backdrop.BorderSizePixel      = 0
    backdrop.Parent               = self.gui

    local blurFx = Instance.new("BlurEffect")
    blurFx.Size = 16; blurFx.Name = "SorinBlur"; blurFx.Parent = Lighting

    local winW = hasInfo and 800 or 620
    local winH = hasBanner and 470 or 415
    local container = Instance.new("Frame")
    container.BackgroundColor3      = C.surface
    container.BorderSizePixel       = 0
    container.AnchorPoint           = Vector2.new(0.5,0.5)
    container.Position              = UDim2.new(0.5,0,0.5,0)
    container.ClipsDescendants      = true
    container.BackgroundTransparency = loading and 1 or 0
    container.Size = mobile
        and UDim2.new(0.93,0,0,math.min(winH, vp.Y*0.93))
        or  UDim2.new(0,winW,0,winH)
    container.Parent = backdrop
    corner(container, 14)
    stroke(container, C.border, 1, 0.28)

    local glass = Instance.new("Frame")
    glass.Size = UDim2.new(1,0,1,0); glass.BackgroundColor3 = Color3.new(1,1,1)
    glass.BackgroundTransparency = 0.975; glass.BorderSizePixel = 0
    glass.ZIndex = 1; glass.Parent = container; corner(glass, 14)

    local outerGlow = Instance.new("Frame")
    outerGlow.Size = UDim2.new(1,90,1,90); outerGlow.AnchorPoint = Vector2.new(0.5,0.5)
    outerGlow.Position = UDim2.new(0.5,0,0.5,0); outerGlow.BackgroundColor3 = C.accent
    outerGlow.BackgroundTransparency = 0.91; outerGlow.BorderSizePixel = 0
    outerGlow.ZIndex = -1; outerGlow.Parent = backdrop; corner(outerGlow, 32)
    TweenService:Create(outerGlow, TweenInfo.new(4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
        {BackgroundTransparency=0.86, Size=UDim2.new(1,110,1,110)}):Play()

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1,0,0,46); topBar.BackgroundColor3 = C.bg
    topBar.BorderSizePixel = 0; topBar.ZIndex = 10; topBar.Parent = container
    corner(topBar, 14)
    local tbFill = Instance.new("Frame")
    tbFill.Size = UDim2.new(1,0,0,10); tbFill.Position = UDim2.new(0,0,1,-10)
    tbFill.BackgroundColor3 = C.bg; tbFill.BorderSizePixel = 0; tbFill.Parent = topBar

    local brand = Instance.new("Frame")
    brand.Size = UDim2.new(0,260,1,0); brand.Position = UDim2.new(0,14,0,0)
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

    local headerTxt = lbl({
        Name="HeaderText", Size=UDim2.new(1,-34,1,0), Position=UDim2.new(0,32,0,0),
        Text=cfg.Title or "Key System", TextColor3=C.txtP, TextSize=14,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=11
    }, brand)

    if cfg.Version and cfg.Version ~= "" then
        local vb = Instance.new("TextLabel")
        vb.BackgroundColor3 = C.accent; vb.BackgroundTransparency = 0.65
        vb.Size = UDim2.new(0,38,0,15); vb.AnchorPoint = Vector2.new(0,0.5)
        vb.Position = UDim2.new(0,200,0.5,0); vb.Text = cfg.Version
        vb.TextColor3 = C.neonP; vb.TextSize = 9; vb.Font = Enum.Font.GothamBold
        vb.ZIndex = 11; vb.Parent = brand; corner(vb, 4)
    end

    local tabCount = hasCL and 2 or 1
    local tabBarW  = tabCount * 108 + (tabCount-1)*4
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(0,tabBarW,0,30); tabBar.AnchorPoint = Vector2.new(0.5,0.5)
    tabBar.Position = UDim2.new(0.5,0,0.5,0); tabBar.BackgroundColor3 = C.surfaceL
    tabBar.BorderSizePixel = 0; tabBar.ZIndex = 11; tabBar.Parent = topBar
    corner(tabBar, 8)
    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0,4)
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabLayout.VerticalAlignment   = Enum.VerticalAlignment.Center

    local tabDefs = { {id="key", label="Key System", icon="🔑"} }
    if hasCL then table.insert(tabDefs, {id="changelog", label="Changelog", icon="📋"}) end

    local tabBtns = {}
    for _, td in ipairs(tabDefs) do
        local active = td.id == "key"
        local tb = Instance.new("TextButton")
        tb.Name = "Tab_"..td.id; tb.Size = UDim2.new(0,106,1,-6)
        tb.BackgroundColor3 = active and C.surfaceM or C.surfaceL
        tb.BackgroundTransparency = active and 0 or 1
        tb.BorderSizePixel = 0; tb.Text = td.icon.."  "..td.label
        tb.TextColor3 = active and C.txtP or C.txtM
        tb.TextSize = 11; tb.Font = Enum.Font.GothamSemibold
        tb.AutoButtonColor = false; tb.ZIndex = 12; tb.Parent = tabBar
        corner(tb, 6)
        if active then
            local ind = Instance.new("Frame"); ind.Name = "Indicator"
            ind.Size = UDim2.new(0.65,0,0,2); ind.Position = UDim2.new(0.175,0,1,-1)
            ind.BackgroundColor3 = C.primary; ind.BorderSizePixel = 0; ind.ZIndex = 13
            ind.Parent = tb; corner(ind, 1)
        end
        tabBtns[td.id] = tb
        tb.MouseButton1Click:Connect(function() self:_switchTab(td.id) end)
    end

    if cfg.DiscordLink and cfg.DiscordLink ~= "" then
        local db = Instance.new("TextButton")
        db.Size = UDim2.new(0,30,0,30); db.Position = UDim2.new(1,-80,0.5,0)
        db.AnchorPoint = Vector2.new(0,0.5); db.BackgroundColor3 = C.accentL
        db.BackgroundTransparency = 0.78; db.BorderSizePixel = 0
        db.Text = "💬"; db.TextSize = 14; db.TextColor3 = C.accentL
        db.Font = Enum.Font.GothamBold; db.AutoButtonColor = false
        db.ZIndex = 11; db.Parent = topBar; corner(db, 8)
        db.MouseEnter:Connect(function() TweenService:Create(db,TweenInfo.new(0.15),{BackgroundTransparency=0.35}):Play() end)
        db.MouseLeave:Connect(function() TweenService:Create(db,TweenInfo.new(0.15),{BackgroundTransparency=0.78}):Play() end)
        db.MouseButton1Click:Connect(function() if setclipboard then setclipboard(cfg.DiscordLink) end end)
    end

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,30,0,30); closeBtn.Position = UDim2.new(1,-42,0.5,0)
    closeBtn.AnchorPoint = Vector2.new(0,0.5); closeBtn.BackgroundColor3 = C.err
    closeBtn.BackgroundTransparency = 0.78; closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"; closeBtn.TextColor3 = C.txtP; closeBtn.TextSize = 13
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 11; closeBtn.Parent = topBar; corner(closeBtn, 8)
    closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.15),{BackgroundTransparency=0.1}):Play() end)
    closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.15),{BackgroundTransparency=0.78}):Play() end)
    closeBtn.MouseButton1Click:Connect(function() self:close() end)

    local leftW = hasInfo and 178 or 0
    if hasInfo then
        local lp = Instance.new("Frame")
        lp.Name = "UserPanel"; lp.Size = UDim2.new(0,leftW,1,-46)
        lp.Position = UDim2.new(0,0,0,46); lp.BackgroundColor3 = C.bg
        lp.BorderSizePixel = 0; lp.ZIndex = 5; lp.Parent = container
        stroke(lp, C.border, 1, 0.5)
        local sep = Instance.new("Frame"); sep.Size = UDim2.new(0,1,1,0)
        sep.Position = UDim2.new(1,0,0,0); sep.BackgroundColor3 = C.border
        sep.BackgroundTransparency = 0.3; sep.BorderSizePixel = 0; sep.Parent = lp

        local inner = Instance.new("Frame"); inner.BackgroundTransparency = 1
        inner.Size = UDim2.new(1,-20,1,-14); inner.Position = UDim2.new(0,10,0,10)
        inner.Parent = lp

        local avFrame = Instance.new("Frame"); avFrame.Size = UDim2.new(0,56,0,56)
        avFrame.AnchorPoint = Vector2.new(0.5,0); avFrame.Position = UDim2.new(0.5,0,0,8)
        avFrame.BackgroundColor3 = C.surfaceL; avFrame.BorderSizePixel = 0
        avFrame.Parent = inner; corner(avFrame, 28)
        stroke(avFrame, C.primary, 2, 0.3)
        local avImg = Instance.new("ImageLabel"); avImg.BackgroundTransparency = 1
        avImg.Size = UDim2.new(1,0,1,0); avImg.ScaleType = Enum.ScaleType.Crop
        avImg.ZIndex = 2; avImg.Parent = avFrame; corner(avImg, 28)
        task.spawn(function()
            local ok, img = pcall(function()
                return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId,
                    Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            end)
            if ok then avImg.Image = img end
        end)
        local dot = Instance.new("Frame"); dot.Size = UDim2.new(0,12,0,12)
        dot.Position = UDim2.new(1,-12,1,-12); dot.BackgroundColor3 = C.success
        dot.BorderSizePixel = 0; dot.ZIndex = 3; dot.Parent = avFrame; corner(dot, 6)
        stroke(dot, C.bg, 2, 0)
        TweenService:Create(dot,TweenInfo.new(1.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),
            {BackgroundTransparency=0.4}):Play()

        lbl({Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,70),
             Text=Players.LocalPlayer.DisplayName, TextColor3=C.txtP,
             TextSize=13,Font=Enum.Font.GothamBold,
             TextXAlignment=Enum.TextXAlignment.Center,
             TextTruncate=Enum.TextTruncate.AtEnd}, inner)
        lbl({Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,0,87),
             Text="@"..Players.LocalPlayer.Name, TextColor3=C.txtM,
             TextSize=10,Font=Enum.Font.Gotham,
             TextXAlignment=Enum.TextXAlignment.Center}, inner)

        local div = Instance.new("Frame"); div.Size = UDim2.new(0.8,0,0,1)
        div.Position = UDim2.new(0.1,0,0,107); div.BackgroundColor3 = C.border
        div.BackgroundTransparency = 0.3; div.BorderSizePixel = 0; div.Parent = inner

        local rows = {
            {"💻","Executor", getExecutor()},
            {"⌨️","Device",   "PC"},
            {"🔐","HWID",     getHWID()},
        }
        for i, r in ipairs(rows) do
            local rf = Instance.new("Frame"); rf.BackgroundTransparency = 1
            rf.Size = UDim2.new(1,0,0,30); rf.Position = UDim2.new(0,0,0,114+(i-1)*32)
            rf.Parent = inner
            lbl({Size=UDim2.new(0,20,1,0),Text=r[1],TextSize=12,Font=Enum.Font.Gotham,
                 TextXAlignment=Enum.TextXAlignment.Left}, rf)
            lbl({Size=UDim2.new(1,-22,0,12),Position=UDim2.new(0,22,0,2),
                 Text=r[2],TextColor3=C.txtM,TextSize=9,Font=Enum.Font.Gotham,
                 TextXAlignment=Enum.TextXAlignment.Left}, rf)
            lbl({Size=UDim2.new(1,-22,0,14),Position=UDim2.new(0,22,0,15),
                 Text=r[3],TextColor3=C.txtS,TextSize=10,Font=Enum.Font.GothamSemibold,
                 TextXAlignment=Enum.TextXAlignment.Left,
                 TextTruncate=Enum.TextTruncate.AtEnd}, rf)
        end

        local clkLbl = lbl({
            Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,114+#rows*32+4),
            Text="🕐  --:--:--", TextColor3=C.txtM, TextSize=10,
            Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left
        }, inner)
        task.spawn(function()
            while lp and lp.Parent and not self._closed do
                local t = os.date("*t")
                clkLbl.Text = string.format("🕐  %02d:%02d:%02d", t.hour, t.min, t.sec)
                task.wait(1)
            end
        end)
    end

    local mainArea = Instance.new("Frame")
    mainArea.Name = "MainArea"; mainArea.BackgroundTransparency = 1
    mainArea.ClipsDescendants = true
    mainArea.Size = UDim2.new(1,-leftW,1,-46); mainArea.Position = UDim2.new(0,leftW,0,46)
    mainArea.Parent = container

    local keyTab = Instance.new("Frame"); keyTab.Name = "KeyTab"
    keyTab.Size = UDim2.new(1,0,1,0); keyTab.BackgroundTransparency = 1
    keyTab.Parent = mainArea

    local content = Instance.new("Frame"); content.Name = "KeyContent"
    content.Size = UDim2.new(1,-48,1,-20); content.Position = UDim2.new(0,24,0,10)
    content.BackgroundTransparency = 1; content.Parent = keyTab

    local yOff = 0

    if hasBanner then
        local sb = cfg.ShopBanner
        local ban = Instance.new("TextButton")
        ban.Name = "ShopBanner"; ban.Size = UDim2.new(1,0,0,48)
        ban.Position = UDim2.new(0,0,0,0); ban.BackgroundColor3 = C.surfaceM
        ban.BorderSizePixel = 0; ban.Text = ""; ban.AutoButtonColor = false
        ban.ZIndex = 2; ban.Parent = content; corner(ban, 10)
        local bStr = stroke(ban, C.accent, 1, 0.55)
        grad(ban, {C.surfaceM, C.bg}, 0)

        if sb.Image and sb.Image ~= "" then
            local bImg = Instance.new("ImageLabel"); bImg.BackgroundTransparency = 1
            bImg.Size = UDim2.new(0,34,0,34); bImg.AnchorPoint = Vector2.new(0,0.5)
            bImg.Position = UDim2.new(0,8,0.5,0); bImg.Image = sb.Image
            bImg.ScaleType = Enum.ScaleType.Fit; bImg.ZIndex = 3; bImg.Parent = ban
        end
        lbl({Size=UDim2.new(1,-100,0,17),Position=UDim2.new(0,48,0,7),
             Text=sb.Title or "Shop",TextColor3=C.txtP,TextSize=12,
             Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3}, ban)
        lbl({Size=UDim2.new(1,-100,0,13),Position=UDim2.new(0,48,0,25),
             Text=sb.Sub or "",TextColor3=C.txtM,TextSize=10,
             Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3}, ban)
        local buyL = Instance.new("TextLabel"); buyL.BackgroundColor3 = C.accent
        buyL.BackgroundTransparency = 0.35; buyL.Size = UDim2.new(0,0,0,22)
        buyL.AutomaticSize = Enum.AutomaticSize.X; buyL.AnchorPoint = Vector2.new(1,0.5)
        buyL.Position = UDim2.new(1,-6,0.5,0); buyL.Text = "  "..(sb.BuyText or "Buy Now").."  "
        buyL.TextColor3 = Color3.new(1,1,1); buyL.TextSize = 10; buyL.Font = Enum.Font.GothamBold
        buyL.ZIndex = 3; buyL.Parent = ban; corner(buyL, 6)
        ban.MouseEnter:Connect(function()
            TweenService:Create(bStr,TweenInfo.new(0.15),{Transparency=0,Thickness=1.5}):Play()
        end)
        ban.MouseLeave:Connect(function()
            TweenService:Create(bStr,TweenInfo.new(0.15),{Transparency=0.55,Thickness=1}):Play()
        end)
        ban.MouseButton1Click:Connect(function()
            if setclipboard and sb.Link then setclipboard(sb.Link) end
        end)
        yOff = 56
    end

    local iconFrame = Instance.new("Frame"); iconFrame.Name = "IconFrame"
    iconFrame.Size = UDim2.new(0,46,0,46); iconFrame.AnchorPoint = Vector2.new(0.5,0)
    iconFrame.Position = UDim2.new(0.5,0,0,yOff+2)
    iconFrame.BackgroundColor3 = C.surfaceL; iconFrame.BorderSizePixel = 0
    iconFrame.ZIndex = 3; iconFrame.Parent = content; corner(iconFrame, 12)
    grad(iconFrame, {C.primary, C.primaryG, C.accent}, 45)
    local ist = stroke(iconFrame, C.primary, 2, 0.35)
    local sg = Instance.new("UIGradient")
    sg.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,C.neonB), ColorSequenceKeypoint.new(0.5,C.primary),
        ColorSequenceKeypoint.new(1,C.neonP)}; sg.Parent = ist
    TweenService:Create(sg,TweenInfo.new(3,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),{Rotation=360}):Play()

    local iconImg = Instance.new("ImageLabel"); iconImg.BackgroundTransparency = 1
    iconImg.Size = UDim2.new(0,36,0,36); iconImg.AnchorPoint = Vector2.new(0.5,0.5)
    iconImg.Position = UDim2.new(0.5,0,0.5,0); iconImg.ScaleType = Enum.ScaleType.Fit
    iconImg.ZIndex = 4
    iconImg.Image = (cfg.LogoImage and cfg.LogoImage ~= "") and cfg.LogoImage or "rbxassetid://84637769762084"
    iconImg.Parent = iconFrame

    if loading then
        iconFrame.Size = UDim2.new(0,0,0,0); iconFrame.BackgroundTransparency = 1
        iconImg.ImageTransparency = 1
    end

    local titleLbl = lbl({Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,yOff+54),
        Text="Key Verification System",TextColor3=C.txtP,TextSize=16,
        Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center,
        TextTransparency=loading and 1 or 0}, content)

    local subLbl = lbl({Size=UDim2.new(1,0,0,15),Position=UDim2.new(0,0,0,yOff+75),
        Text="Choose your key duration, complete the steps, then enter your key",
        TextColor3=C.txtS,TextSize=11,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Center,
        TextTransparency=loading and 1 or 0}, content)

    local s1Lbl = lbl({Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,0,yOff+98),
        Text="STEP 1  –  Choose your key duration",TextColor3=C.txtM,TextSize=10,
        Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left,
        TextTransparency=loading and 1 or 0}, content)

    local providers = cfg.Providers or {}
    local provRow = Instance.new("Frame"); provRow.Name = "ProvRow"
    provRow.Size = UDim2.new(1,0,0,56); provRow.Position = UDim2.new(0,0,0,yOff+114)
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
            btn.Parent = provRow; corner(btn, 10)
            local ps = stroke(btn, C.border, 1, 0.4)

            lbl({Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,4),
                 Text=prov.duration or prov.name, TextColor3=prov.color or C.primary,
                 TextSize=15,Font=Enum.Font.GothamBold,
                 TextXAlignment=Enum.TextXAlignment.Center,
                 TextTransparency=loading and 1 or 0}, btn)

            local dots = string.rep("●", prov.checkpoints or 1, " ")
            lbl({Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,26),
                 Text=dots,TextColor3=prov.color or C.primary,TextSize=9,
                 Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Center,
                 TextTransparency=loading and 1 or 0}, btn)

            local cpText = prov.checkpoints and
                (tostring(prov.checkpoints).." Checkpoint"..((prov.checkpoints>1) and "s" or "")) or ""
            lbl({Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,0,40),
                 Text=cpText,TextColor3=C.txtM,TextSize=9,Font=Enum.Font.Gotham,
                 TextXAlignment=Enum.TextXAlignment.Center,
                 TextTransparency=loading and 1 or 0}, btn)

            local cd = prov.colorDark or prov.color or C.primaryD
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.surfaceM}):Play()
                TweenService:Create(ps, TweenInfo.new(0.15),{Color=prov.color or C.primary,Transparency=0.08,Thickness=1.5}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=C.surfaceL}):Play()
                TweenService:Create(ps, TweenInfo.new(0.15),{Color=C.border,Transparency=0.4,Thickness=1}):Play()
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

    local s2Lbl = lbl({Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,0,yOff+179),
        Text="STEP 2  –  Paste your key below and verify",TextColor3=C.txtM,TextSize=10,
        Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left,
        TextTransparency=loading and 1 or 0}, content)

    local inputSec = Instance.new("Frame"); inputSec.Name = "InputSection"
    inputSec.Size = UDim2.new(1,0,0,42); inputSec.Position = UDim2.new(0,0,0,yOff+195)
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

    local verifyBtn = Instance.new("TextButton"); verifyBtn.Name = "VerifyButton"
    verifyBtn.Size = UDim2.new(1,0,0,38); verifyBtn.Position = UDim2.new(0,0,0,yOff+247)
    verifyBtn.BackgroundColor3 = C.success; verifyBtn.BorderSizePixel = 0
    verifyBtn.Text = ""; verifyBtn.AutoButtonColor = false
    verifyBtn.BackgroundTransparency = loading and 1 or 0
    verifyBtn.Parent = content; corner(verifyBtn, 9)
    local vGrad = Instance.new("UIGradient")
    vGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,C.success),ColorSequenceKeypoint.new(1,C.successD)}
    vGrad.Rotation = 90; vGrad.Parent = verifyBtn
    local vGlow = stroke(verifyBtn, C.successG, 0, 0.8)
    lbl({Size=UDim2.new(0,26,1,0),Position=UDim2.new(0,10,0,0),
         Text="✓",TextColor3=Color3.new(1,1,1),TextSize=17,Font=Enum.Font.GothamBold,
         TextXAlignment=Enum.TextXAlignment.Center,
         TextTransparency=loading and 1 or 0}, verifyBtn)
    local vTxt = lbl({Name="ButtonText",Size=UDim2.new(1,0,1,0),Text="Verify Key",
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

    local clTab = nil
    if hasCL then
        clTab = Instance.new("Frame"); clTab.Name = "ChangelogTab"
        clTab.Size = UDim2.new(1,0,1,0); clTab.BackgroundTransparency = 1
        clTab.Visible = false; clTab.Parent = mainArea

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1,-28,1,-16); scroll.Position = UDim2.new(0,14,0,8)
        scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = C.border
        scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.Parent = clTab
        local sLayout = Instance.new("UIListLayout", scroll)
        sLayout.Padding = UDim.new(0,8); sLayout.SortOrder = Enum.SortOrder.LayoutOrder

        for idx, entry in ipairs(cfg.Changelog) do
            local ef = Instance.new("Frame"); ef.BackgroundColor3 = C.surfaceL
            ef.BorderSizePixel = 0; ef.Size = UDim2.new(1,0,0,0)
            ef.AutomaticSize = Enum.AutomaticSize.Y; ef.LayoutOrder = idx; ef.Parent = scroll
            corner(ef, 8); stroke(ef, C.border, 1, 0.5)
            local ep = Instance.new("UIPadding",ef)
            ep.PaddingLeft=UDim.new(0,12); ep.PaddingRight=UDim.new(0,12)
            ep.PaddingTop=UDim.new(0,9);   ep.PaddingBottom=UDim.new(0,9)
            local ec = Instance.new("Frame"); ec.BackgroundTransparency=1
            ec.Size=UDim2.new(1,0,0,0); ec.AutomaticSize=Enum.AutomaticSize.Y; ec.Parent=ef
            local el = Instance.new("UIListLayout",ec); el.Padding=UDim.new(0,3)
            el.SortOrder=Enum.SortOrder.LayoutOrder

            local hr = Instance.new("Frame"); hr.BackgroundTransparency=1
            hr.Size=UDim2.new(1,0,0,20); hr.LayoutOrder=1; hr.Parent=ec
            lbl({Size=UDim2.new(0.5,0,1,0),Text="v"..(entry.version or "?"),
                 TextColor3=C.primary,TextSize=13,Font=Enum.Font.GothamBold,
                 TextXAlignment=Enum.TextXAlignment.Left}, hr)
            lbl({Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0.5,0,0,0),
                 Text=entry.date or "",TextColor3=C.txtM,TextSize=10,Font=Enum.Font.Gotham,
                 TextXAlignment=Enum.TextXAlignment.Right}, hr)

            for ci, change in ipairs(entry.changes or {}) do
                lbl({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
                     Text="  •  "..change,TextColor3=C.txtS,TextSize=11,Font=Enum.Font.Gotham,
                     TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,
                     LayoutOrder=ci+1}, ec)
            end
        end
    end

    self.el = {
        backdrop=backdrop, container=container, mainArea=mainArea,
        keyTab=keyTab, clTab=clTab, content=content,
        iconFrame=iconFrame, iconImg=iconImg,
        inputFrame=inputSec, keyInput=keyInput, inputStroke=inputStroke,
        verifyButton=verifyBtn, headerText=headerTxt,
        closeButton=closeBtn, tabBtns=tabBtns,
        s1Lbl=s1Lbl, provRow=provRow, s2Lbl=s2Lbl,
        titleLbl=titleLbl, subLbl=subLbl,
    }

    self:_particles(container)

    self.gui.Parent = game:GetService("CoreGui")
    self.gui.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            local bl = Lighting:FindFirstChild("SorinBlur"); if bl then bl:Destroy() end
        end
    end)

    if loading then
        task.spawn(function() self:_loadAnim() end)
    else
        backdrop.BackgroundTransparency = 1; container.BackgroundTransparency = 1
        TweenService:Create(backdrop, TweenInfo.new(0.3,Enum.EasingStyle.Quad),{BackgroundTransparency=0.42}):Play()
        TweenService:Create(container,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{BackgroundTransparency=0}):Play()
    end
end

function SorinUILib:_loadAnim()
    local e = self.el
    TweenService:Create(e.backdrop, TweenInfo.new(0.45,Enum.EasingStyle.Quad),{BackgroundTransparency=0.42}):Play()
    TweenService:Create(e.container,TweenInfo.new(0.45,Enum.EasingStyle.Quad),{BackgroundTransparency=0}):Play()
    task.wait(0.55)

    e.iconFrame.BackgroundTransparency = 0
    TweenService:Create(e.iconFrame, TweenInfo.new(0.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Size=UDim2.new(0,46,0,46)}):Play()
    TweenService:Create(e.iconImg, TweenInfo.new(0.4),{ImageTransparency=0}):Play()
    task.wait(0.6)

    local texts = {e.titleLbl, e.subLbl, e.s1Lbl, e.s2Lbl}
    for i, el in ipairs(texts) do
        if el then
            task.delay((i-1)*0.09, function()
                TweenService:Create(el,TweenInfo.new(0.35),{TextTransparency=0}):Play()
            end)
        end
    end
    task.wait(0.55)

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
    task.wait(0.15)

    TweenService:Create(e.inputFrame,TweenInfo.new(0.3),{BackgroundTransparency=0}):Play()
    for _, d in ipairs(e.inputFrame:GetDescendants()) do
        pcall(function()
            if d:IsA("TextLabel") then TweenService:Create(d,TweenInfo.new(0.3),{TextTransparency=0}):Play() end
            if d:IsA("TextBox")   then TweenService:Create(d,TweenInfo.new(0.3),{TextTransparency=0}):Play() end
        end)
    end
    TweenService:Create(e.verifyButton,TweenInfo.new(0.3),{BackgroundTransparency=0}):Play()
    for _, d in ipairs(e.verifyButton:GetDescendants()) do
        pcall(function()
            if d:IsA("TextLabel") then TweenService:Create(d,TweenInfo.new(0.3),{TextTransparency=0}):Play() end
        end)
    end
end

function SorinUILib:_switchTab(id)
    local e = self.el
    for tabId, btn in pairs(e.tabBtns) do
        local active = (tabId == id)
        TweenService:Create(btn,TweenInfo.new(0.15),{
            TextColor3=active and C.txtP or C.txtM,
            BackgroundTransparency=active and 0 or 1,
            BackgroundColor3=active and C.surfaceM or C.surfaceL
        }):Play()
        local ind = btn:FindFirstChild("Indicator")
        if ind then
            TweenService:Create(ind,TweenInfo.new(0.15),{BackgroundTransparency=active and 0 or 1}):Play()
        end
    end
    if e.keyTab    then e.keyTab.Visible    = (id=="key")       end
    if e.clTab     then e.clTab.Visible     = (id=="changelog") end
end

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

function SorinUILib:_shake()
    local f = self.el.inputFrame; if not f then return end
    local o = f.Position
    for _ = 1, 3 do
        TweenService:Create(f,TweenInfo.new(0.05),{Position=UDim2.new(o.X.Scale,o.X.Offset-8,o.Y.Scale,o.Y.Offset)}):Play()
        task.wait(0.05)
        TweenService:Create(f,TweenInfo.new(0.05),{Position=UDim2.new(o.X.Scale,o.X.Offset+8,o.Y.Scale,o.Y.Offset)}):Play()
        task.wait(0.05)
    end
    f.Position = o
end

function SorinUILib:_pulse()
    local iF = self.el.iconFrame; if not iF then return end
    TweenService:Create(iF,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Size=UDim2.new(0,60,0,60)}):Play()
    task.wait(0.22)
    TweenService:Create(iF,TweenInfo.new(0.15),{Size=UDim2.new(0,46,0,46)}):Play()
end

function SorinUILib:_spinner(btn, text, on)
    local bt = btn:FindFirstChild("ButtonText"); if bt then bt.Text = text end
    btn.Interactable = not on
    local sp = btn:FindFirstChild("Spinner")
    if on and not sp then
        sp = Instance.new("Frame"); sp.Name = "Spinner"
        sp.Size = UDim2.new(0,13,0,13); sp.Position = UDim2.new(0,14,0.5,-6)
        sp.BackgroundColor3 = C.txtP; sp.BackgroundTransparency = 0.65
        sp.BorderSizePixel = 0; sp.Parent = btn; corner(sp, 10)
        TweenService:Create(sp,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),{Rotation=360}):Play()
    elseif not on and sp then sp:Destroy() end
end

function SorinUILib:_getKey(prov)
    if setclipboard and prov.link then
        setclipboard(prov.link)
        self:_status("🎮 "..prov.name.." link copied! Open it in your browser ✓", prov.color or C.primary, 5)
    else
        self:_status("Link: "..(prov.link or ""), prov.color or C.primary, 10)
    end
end

function SorinUILib:_welcome(username)
    local e = self.el; if not (self.cfg.WelcomeEnabled and e.content) then return end
    local card = Instance.new("Frame"); card.Name = "WelcomeCard"
    card.Size = UDim2.new(1,0,0,0); card.Position = UDim2.new(0,0,0.5,0)
    card.AnchorPoint = Vector2.new(0,0.5); card.BackgroundColor3 = C.primary
    card.BorderSizePixel = 0; card.ClipsDescendants = true; card.ZIndex = 25
    card.Parent = e.content; corner(card, 12)
    grad(card, {C.primary, C.accent}, 90)
    stroke(card, C.primaryG, 1, 0.35)
    TweenService:Create(card,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Size=UDim2.new(1,0,0,80)}):Play()
    task.wait(0.12)
    lbl({Size=UDim2.new(0,50,1,0),Text="🎉",TextSize=30,Font=Enum.Font.Gotham,
         TextTransparency=0,ZIndex=26}, card)
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

function SorinUILib:_keyInfo(data, _key)
    local e = self.el

    local function fmt(s)
        if s<=0 then return "Expired" end
        local d=math.floor(s/86400); local h=math.floor((s%86400)/3600); local m=math.floor((s%3600)/60)
        if d>0 then return d.."d "..h.."h "..m.."m" elseif h>0 then return h.."h "..m.."m" end
        return m.."m"
    end

    local secsLeft = (data and data.key_expires and data.key_expires>0)
        and math.max(0, data.key_expires - os.time()) or nil

    local toHide = {e.s1Lbl, e.provRow, e.s2Lbl, e.inputFrame, e.verifyButton}
    for _, el in ipairs(toHide) do
        if el then
            TweenService:Create(el,TweenInfo.new(0.25),{BackgroundTransparency=1}):Play()
            if el:IsA("TextLabel") then
                TweenService:Create(el,TweenInfo.new(0.25),{TextTransparency=1}):Play()
            end
            for _, ch in ipairs(el:GetDescendants()) do
                pcall(function()
                    TweenService:Create(ch,TweenInfo.new(0.2),{
                        TextTransparency=1,BackgroundTransparency=1,ImageTransparency=1}):Play()
                end)
            end
        end
    end
    task.wait(0.28)
    for _, el in ipairs(toHide) do if el then el.Visible = false end end

    local ctr = e.container
    TweenService:Create(ctr,TweenInfo.new(0.45,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),
        {Size=UDim2.new(ctr.Size.X.Scale,ctr.Size.X.Offset, 0,295)}):Play()
    task.wait(0.12)

    local card = Instance.new("Frame"); card.Name = "KeyInfoCard"
    card.Size = UDim2.new(1,0,0,0); card.Position = UDim2.new(0,0,0,100)
    card.BackgroundColor3 = C.surfaceL; card.BorderSizePixel = 0
    card.ClipsDescendants = true; card.Parent = e.content
    corner(card, 12); stroke(card, C.success, 1, 0.45)
    TweenService:Create(card,TweenInfo.new(0.45,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),
        {Size=UDim2.new(1,0,0,126)}):Play()
    task.wait(0.16)

    local rows = {
        {"✅","Status",     "Key active",                                    C.success},
        {"⏳","Valid for",  secsLeft and fmt(secsLeft) or "Lifetime",        C.primary},
        {"🔢","Executions", tostring(data and data.executions or 0),         C.txtS},
        {"📋","Type",       (data and data.note) or "—",                     C.txtM},
    }
    for i, row in ipairs(rows) do
        local rf = Instance.new("Frame"); rf.BackgroundTransparency=1
        rf.Size=UDim2.new(1,-24,0,28); rf.Position=UDim2.new(0,12,0,5+(i-1)*30)
        rf.Parent=card
        local icoL=lbl({Size=UDim2.new(0,22,1,0),Text=row[1],TextSize=14,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,TextTransparency=1}, rf)
        local labL=lbl({Size=UDim2.new(0,110,1,0),Position=UDim2.new(0,26,0,0),
            Text=row[2],TextColor3=C.txtM,TextSize=12,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,TextTransparency=1}, rf)
        local valL=lbl({Size=UDim2.new(1,-136,1,0),Position=UDim2.new(0,136,0,0),
            Text=row[3],TextColor3=row[4],TextSize=12,Font=Enum.Font.GothamSemibold,
            TextXAlignment=Enum.TextXAlignment.Right,TextTransparency=1}, rf)
        task.delay(i*0.07, function()
            TweenService:Create(icoL,TweenInfo.new(0.3),{TextTransparency=0}):Play()
            TweenService:Create(labL,TweenInfo.new(0.3),{TextTransparency=0}):Play()
            TweenService:Create(valL,TweenInfo.new(0.3),{TextTransparency=0}):Play()
        end)
    end

    task.wait(2.2)
    self:close()
end

function SorinUILib:_verify()
    local cfg = self.cfg
    local key = self.el.keyInput.Text:gsub("%s+","")
    if key == "" then self:_status("Please enter a key", C.err, 3); self:_shake(); return end

    self:_spinner(self.el.verifyButton, "Verifying...", true)
    self:_status("Verifying key...", C.primary, 0)
    self.el.keyInput.Interactable = false

    local ok, result = pcall(function()
        if cfg.CheckKey then return cfg.CheckKey(key) end
        error("CheckKey not configured")
    end)

    if ok and result then
        if result.status == "key_valid" then
            saveKey(key); getgenv().SORIN_KEY = key
            self:_status("✅ Key verified!", C.success, 0)
            self:_pulse(); task.wait(0.42)
            if cfg.WelcomeEnabled then
                self:_welcome((result.user and result.user.username) or Players.LocalPlayer.Name)
                task.wait(2.6)
            end
            self:_keyInfo(result.user, key); return
        elseif result.status == "invalid_fingerprint" then
            self:_status("Fingerprint mismatch – reset via Discord bot", C.err, 6)
        elseif result.status == "key_expired" then
            self:_status("Key expired! Get a new one above ↑", C.err, 5)
        elseif result.status == "key_blacklisted" then
            local reason = result.user and result.user.blacklist_reason or "?"
            self:_status("Key is blacklisted! Reason: "..reason, C.err, 6)
        elseif result.status == "invalid_key" then
            self:_status("Key not found – check spelling", C.err, 4)
        elseif result.status == "invalid_script_id" then
            self:_status("Config error – contact devs", C.err, 5)
        else
            self:_status("Unknown error ("..tostring(result.status)..")", C.err, 4)
        end
    else
        self:_status("Connection error – try again", C.err, 4)
    end

    self:_shake()
    self:_spinner(self.el.verifyButton, "Verify Key", false)
    self.el.keyInput.Interactable = true
end

function SorinUILib:close()
    self._closed = true
    getgenv().SORIN_CLOSED = true
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    self._conns = {}
    if not self.gui then return end
    TweenService:Create(self.el.container,TweenInfo.new(0.22),{BackgroundTransparency=1}):Play()
    TweenService:Create(self.el.backdrop, TweenInfo.new(0.22),{BackgroundTransparency=1}):Play()
    task.wait(0.24)
    local bl = Lighting:FindFirstChild("SorinBlur"); if bl then bl:Destroy() end
    self.gui:Destroy(); self.gui = nil
end

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
            if ok and result and result.status == "key_valid" then
                getgenv().SORIN_KEY = saved
                self:_status("✅ Key verified!", C.success, 0)
                self:_pulse(); task.wait(0.42)
                if self.cfg.WelcomeEnabled then
                    self:_welcome((result.user and result.user.username) or Players.LocalPlayer.Name)
                    task.wait(2.6)
                end
                self:_keyInfo(result.user, saved)
            else
                clearKey(); self:_status("", nil, 0)
            end
        end
    end)

    while not getgenv().SORIN_CLOSED do task.wait(0.1) end

    if self.cfg.LoadScript then
        self.cfg.LoadScript(getgenv().SORIN_KEY)
    end
end

return SorinUILib
