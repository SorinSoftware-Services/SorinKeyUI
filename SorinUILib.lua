-- ================================================
--   SorinUILib.lua  –  Key System UI Library
--   Look: SorinUILib (GitHub-dark palette)
--   Structure: KirmandaUI / Arqel pattern
-- ================================================

local cloneref = cloneref or function(o) return o end
local TweenService     = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CoreGui          = cloneref(game:GetService("CoreGui"))
local RunService       = cloneref(game:GetService("RunService"))
local Lighting         = cloneref(game:GetService("Lighting"))
local Players          = cloneref(game:GetService("Players"))
local Workspace        = cloneref(game:GetService("Workspace"))
local HttpService      = cloneref(game:GetService("HttpService"))

if getgenv().SorinUILoaded and CoreGui:FindFirstChild("SorinKeyUI") then
    return getgenv().SorinUI
end
getgenv().SorinUILoaded = true

local SorinUI = {}

-- ════════════════════════════════════════════════
--  PUBLIC CONFIG TABLES
-- ════════════════════════════════════════════════

SorinUI.Appearance = {
    Title    = "Key System",
    Subtitle = "Enter your key to continue",
    Icon     = "",
    IconSize = UDim2.new(0, 26, 0, 26),
    Version  = "",
}

SorinUI.Links = {
    GetKey  = "",
    Discord = "",
    Shop    = "",
}

SorinUI.Storage = {
    FileName = "sorin_key",
    Remember = true,
    AutoLoad = true,
}

SorinUI.Options = {
    Blur            = true,
    Draggable       = true,
    LoadingEnabled  = true,
    UserInfoEnabled = true,
    WelcomeEnabled  = true,
    Keyless         = nil,   -- nil=auto, true=force keyless, false=force keyed
    KeylessUI       = true,
}

SorinUI.Theme = {
    Background   = Color3.fromRGB(13,  17,  23),
    Surface      = Color3.fromRGB(22,  27,  34),
    SurfaceLight = Color3.fromRGB(30,  36,  44),
    SurfaceMid   = Color3.fromRGB(26,  31,  39),
    Header       = Color3.fromRGB(18,  22,  30),
    Input        = Color3.fromRGB(26,  31,  39),
    Accent       = Color3.fromRGB(88,  166, 255),
    AccentHover  = Color3.fromRGB(120, 180, 255),
    AccentDark   = Color3.fromRGB(58,  136, 225),
    Secondary    = Color3.fromRGB(136, 87,  224),
    SecondaryL   = Color3.fromRGB(187, 134, 252),
    Success      = Color3.fromRGB(47,  183, 117),
    SuccessHover = Color3.fromRGB(67,  203, 137),
    SuccessDark  = Color3.fromRGB(37,  153, 97),
    Error        = Color3.fromRGB(248, 81,  73),
    Warning      = Color3.fromRGB(255, 180, 50),
    Text         = Color3.fromRGB(230, 237, 243),
    TextDim      = Color3.fromRGB(139, 148, 158),
    TextMuted    = Color3.fromRGB(110, 118, 129),
    Border       = Color3.fromRGB(48,  54,  61),
    Pending      = Color3.fromRGB(55,  60,  75),
    NeonBlue     = Color3.fromRGB(0,   229, 255),
    NeonPurple   = Color3.fromRGB(187, 134, 252),
    Discord      = Color3.fromRGB(88,  101, 242),
    DiscordHover = Color3.fromRGB(114, 137, 218),
    StatusIdle   = Color3.fromRGB(110, 118, 129),
}

SorinUI.Callbacks = {
    OnVerify  = nil,  -- function(key) -> {valid=bool, error="CODE", ...} or bool
    OnSuccess = nil,
    OnFail    = nil,
    OnClose   = nil,
}

SorinUI.Changelog = {}
-- Format: { {Version="v1.0", Date="2025-01-01", Changes={"fix 1","fix 2"}} }

SorinUI.Shop = {
    Enabled    = false,
    Icon       = "",
    Title      = "Get Premium Access",
    Subtitle   = "Instant delivery • 24/7 support",
    ButtonText = "Buy",
    Link       = "",
}

-- Multi-tier providers for LuaAuth style systems
-- Each: {name, duration, checkpoints, color, colorDark, link}
SorinUI.Providers = {}

-- ════════════════════════════════════════════════
--  INTERNAL STATE
-- ════════════════════════════════════════════════

local Internal = {
    BlurEffect       = nil,
    NotificationList = {},
    ValidateFunction = nil,
    IsJunkieMode     = false,
    IconsLoaded      = false,
}

-- ════════════════════════════════════════════════
--  ICON SYSTEM
-- ════════════════════════════════════════════════

local IconBaseURL = "https://raw.githubusercontent.com/Cobruhehe/expert-octo-doodle/main/Icons/"
local IconFiles = {
    key       = "lucide--key.png",
    shield    = "lucide--shield-minus.png",
    check     = "prime--check-square.png",
    copy      = "flowbite--clipboard-outline.png",
    discord   = "qlementine-icons--discord-16.png",
    alert     = "mdi--alert-octagon-outline.png",
    lock      = "lucide--user-lock.png",
    loading   = "nonicons--loading-16.png",
    close     = "material-symbols--dangerous-outline.png",
    changelog = "ant-design--sync-outlined.png",
    user      = "U.png",
    clock     = "Clock.png",
    cart      = "Cart.png",
}

local FallbackIcons = {
    key       = "rbxassetid://96510194465420",
    shield    = "rbxassetid://89965059528921",
    check     = "rbxassetid://76078495178149",
    copy      = "rbxassetid://125851897718493",
    discord   = "rbxassetid://83278450537116",
    alert     = "rbxassetid://140438367956051",
    lock      = "rbxassetid://114355063515473",
    loading   = "rbxassetid://116535712789945",
    close     = "rbxassetid://6022668916",
    changelog = "rbxassetid://138133190015277",
    user      = "rbxassetid://77400125196692",
    clock     = "rbxassetid://87505349362628",
    cart      = "rbxassetid://114754518183872",
}

local CachedIcons = {}
local FolderName  = "SorinUI"
local IconsFolder = "Icons"

local function hasFS()
    local ok1 = pcall(function() return type(writefile)  == "function" end)
    local ok2 = pcall(function() return type(readfile)   == "function" end)
    local ok3 = pcall(function() return type(isfile)     == "function" end)
    local ok4 = pcall(function() return type(makefolder) == "function" end)
    local ok5 = pcall(function() return type(isfolder)   == "function" end)
    return ok1 and ok2 and ok3 and ok4 and ok5
end
local fsOk = hasFS()

local function ensureFolders()
    if not fsOk then return end
    pcall(function()
        if not isfolder(FolderName) then makefolder(FolderName) end
        if not isfolder(FolderName.."/"..IconsFolder) then makefolder(FolderName.."/"..IconsFolder) end
    end)
end

local function getIconPath(name)
    return FolderName.."/"..IconsFolder.."/"..IconFiles[name]
end

local function downloadIcon(name)
    if not fsOk or not IconFiles[name] then
        CachedIcons[name] = FallbackIcons[name]; return
    end
    local path = getIconPath(name)
    local ok = pcall(function()
        if isfile(path) then CachedIcons[name] = getcustomasset(path) end
    end)
    if CachedIcons[name] then return end
    ok = pcall(function()
        local data = game:HttpGet(IconBaseURL..IconFiles[name])
        if #data < 100 then error("invalid") end
        writefile(path, data)
        CachedIcons[name] = getcustomasset(path)
    end)
    if not ok then CachedIcons[name] = FallbackIcons[name] end
end

local function getIcon(name)
    return CachedIcons[name] or FallbackIcons[name] or ""
end

local function loadAllIcons()
    ensureFolders()
    for name in pairs(IconFiles) do downloadIcon(name) end
    Internal.IconsLoaded = true
end

local function allIconsCached()
    if not fsOk then return false end
    for name in pairs(IconFiles) do
        local ok, exists = pcall(function() return isfile(getIconPath(name)) end)
        if not ok or not exists then return false end
    end
    return true
end

local function loadAllIconsFromCache()
    ensureFolders()
    for name in pairs(IconFiles) do downloadIcon(name) end
    Internal.IconsLoaded = true
end

-- ════════════════════════════════════════════════
--  UTILITY
-- ════════════════════════════════════════════════

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function getScale()
    local vp = Workspace.CurrentCamera.ViewportSize
    return math.clamp(math.min(vp.X, vp.Y) / 900, 0.65, 1.3)
end

local function saveKey(k)
    if not fsOk or not SorinUI.Storage.Remember then return end
    pcall(writefile, SorinUI.Storage.FileName..".txt", k)
end

local function loadKey()
    if not fsOk then return nil end
    local ok, v = pcall(function()
        if isfile(SorinUI.Storage.FileName..".txt") then
            return readfile(SorinUI.Storage.FileName..".txt")
        end
    end)
    return (ok and v and v ~= "") and v or nil
end

local function clearKey()
    if not fsOk then return end
    pcall(function() if delfile then delfile(SorinUI.Storage.FileName..".txt") end end)
end

local function getExecutorName()
    local ok, name = pcall(identifyexecutor)
    if ok and name then return tostring(name) end
    if rawget(_G,"syn") then return "Synapse X" end
    if rawget(_G,"KRNL_LOADED") then return "Krnl" end
    return "Unknown"
end

local function getDeviceType()
    if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then return "Console" end
    if UserInputService.TouchEnabled   and not UserInputService.KeyboardEnabled then return "Mobile"  end
    if UserInputService.KeyboardEnabled and UserInputService.TouchEnabled        then return "PC + Touch" end
    if UserInputService.KeyboardEnabled then return "PC" end
    return "Unknown"
end

local function getHWID()
    local hwid
    pcall(function() if gethwid then hwid = gethwid() end end)
    if not hwid then
        local p = Players.LocalPlayer
        hwid = p and (tostring(p.UserId).."-hwid") or "N/A"
    end
    return hwid or "N/A"
end

local function formatTime()
    local h = tonumber(os.date("%H"))
    local p = h >= 12 and "PM" or "AM"
    if h > 12 then h = h - 12 end; if h == 0 then h = 12 end
    return string.format("%d:%s:%s %s", h, os.date("%M"), os.date("%S"), p)
end

local function formatDate()
    return os.date("%b %d, %Y")
end

local function validateKey(key, fn)
    if not fn or not key or key == "" then return false end
    local ok, r = pcall(fn, key)
    if not ok then return false end
    if type(r) == "table" then return r.valid == true end
    return r == true
end

-- ════════════════════════════════════════════════
--  BLUR
-- ════════════════════════════════════════════════

local function enableBlur()
    if not SorinUI.Options.Blur then return end
    local ex = Lighting:FindFirstChild("SorinBlur"); if ex then ex:Destroy() end
    Internal.BlurEffect = Instance.new("BlurEffect")
    Internal.BlurEffect.Name = "SorinBlur"; Internal.BlurEffect.Size = 0
    Internal.BlurEffect.Parent = Lighting
    TweenService:Create(Internal.BlurEffect, TweenInfo.new(0.4,Enum.EasingStyle.Quart),{Size=20}):Play()
end

local function disableBlur()
    if Internal.BlurEffect and Internal.BlurEffect.Parent then
        TweenService:Create(Internal.BlurEffect, TweenInfo.new(0.3,Enum.EasingStyle.Quart),{Size=0}):Play()
        task.delay(0.3, function()
            if Internal.BlurEffect then Internal.BlurEffect:Destroy(); Internal.BlurEffect = nil end
        end)
    else
        local ex = Lighting:FindFirstChild("SorinBlur"); if ex then ex:Destroy() end
    end
end

-- ════════════════════════════════════════════════
--  CLEANUP
-- ════════════════════════════════════════════════

local function fullCleanup()
    getgenv().SorinUILoaded = false
    disableBlur()
    for _, n in ipairs({"SorinKeyUI","SorinKeylessUI","SorinLoadingScreen"}) do
        local g = CoreGui:FindFirstChild(n); if g then g:Destroy() end
    end
end

-- ════════════════════════════════════════════════
--  UI HELPERS
-- ════════════════════════════════════════════════

local function corner(p, r)
    local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 10); return c
end

local function stroke(p, col, thick, trans)
    local s = Instance.new("UIStroke", p)
    s.Color = col; s.Thickness = thick or 1; s.Transparency = trans or 0; return s
end

local function grad(p, cols, rot)
    local kp = {}
    for i, c in ipairs(cols) do kp[i] = ColorSequenceKeypoint.new((i-1)/math.max(#cols-1,1),c) end
    local g = Instance.new("UIGradient", p)
    g.Color = ColorSequence.new(kp); g.Rotation = rot or 0; return g
end

local function lbl(props, parent)
    local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1
    for k,v in pairs(props) do l[k] = v end
    if parent then l.Parent = parent end; return l
end

local function shimmer(parent, r)
    local g = Instance.new("Frame")
    g.Size = UDim2.new(1,0,1,0); g.BackgroundColor3 = Color3.new(1,1,1)
    g.BackgroundTransparency = 0.975; g.BorderSizePixel = 0; g.ZIndex = 1
    g.Parent = parent; corner(g, r or 12); return g
end

local function panelHeader(parent, title, iconKey)
    local T = SorinUI.Theme
    local ph = Instance.new("Frame")
    ph.Size = UDim2.new(1,0,0,46); ph.BackgroundColor3 = T.Header
    ph.BorderSizePixel = 0; ph.Parent = parent; corner(ph, 12)
    -- fill bottom gap of rounded top corners
    local fill = Instance.new("Frame"); fill.Size = UDim2.new(1,0,0,12)
    fill.Position = UDim2.new(0,0,1,-12); fill.BackgroundColor3 = T.Header
    fill.BorderSizePixel = 0; fill.Parent = ph
    -- accent line
    local line = Instance.new("Frame"); line.Size = UDim2.new(1,0,0,1)
    line.Position = UDim2.new(0,0,1,0); line.BackgroundColor3 = T.Accent
    line.BackgroundTransparency = 0.6; line.BorderSizePixel = 0; line.Parent = ph
    -- icon
    local ico = Instance.new("ImageLabel")
    ico.Size = UDim2.new(0,16,0,16); ico.Position = UDim2.new(0,12,0.5,0)
    ico.AnchorPoint = Vector2.new(0,0.5); ico.BackgroundTransparency = 1
    ico.Image = getIcon(iconKey or "shield"); ico.ImageColor3 = T.Accent
    ico.ScaleType = Enum.ScaleType.Fit; ico.Parent = ph
    -- title
    lbl({Size=UDim2.new(1,-70,1,0), Position=UDim2.new(0,34,0,0),
         Text=title, TextColor3=T.Text, TextSize=14, Font=Enum.Font.GothamBold,
         TextXAlignment=Enum.TextXAlignment.Left}, ph)
    -- close button
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Size = UDim2.new(0,18,0,18); closeBtn.Position = UDim2.new(1,-12,0.5,0)
    closeBtn.AnchorPoint = Vector2.new(1,0.5); closeBtn.BackgroundTransparency = 1
    closeBtn.Image = getIcon("close"); closeBtn.ImageColor3 = T.TextDim
    closeBtn.ScaleType = Enum.ScaleType.Fit; closeBtn.Parent = ph
    closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.15),{ImageColor3=T.Error}):Play() end)
    closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn,TweenInfo.new(0.15),{ImageColor3=T.TextDim}):Play() end)
    return ph, closeBtn
end

-- ════════════════════════════════════════════════
--  DRAGGING
-- ════════════════════════════════════════════════

local function setupDragging(header, container)
    if not SorinUI.Options.Draggable then return end
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true; dragStart = inp.Position; startPos = container.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = inp.Position - dragStart
        container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
                                       startPos.Y.Scale,  startPos.Y.Offset+d.Y)
    end)
end

-- ════════════════════════════════════════════════
--  PARTICLES
-- ════════════════════════════════════════════════

local function startParticles(host)
    local T = SorinUI.Theme
    local palette = {T.AccentHover, T.NeonPurple, T.NeonBlue, T.Secondary}
    task.spawn(function()
        while host and host.Parent do
            local p = Instance.new("Frame")
            p.Size = UDim2.new(0,math.random(2,4),0,math.random(2,4))
            p.Position = UDim2.new(math.random(),0,1,0)
            p.BackgroundColor3 = palette[math.random(#palette)]
            p.BackgroundTransparency = 0.55; p.BorderSizePixel = 0
            p.ZIndex = 6; p.Parent = host; corner(p, 10)
            local ft = TweenService:Create(p,
                TweenInfo.new(math.random(8,14),Enum.EasingStyle.Linear),
                {Position=UDim2.new(p.Position.X.Scale,0,-0.12,0),BackgroundTransparency=1})
            ft:Play(); ft.Completed:Connect(function() p:Destroy() end)
            task.wait(math.random()*1.5+0.8)
        end
    end)
end

-- ════════════════════════════════════════════════
--  NOTIFICATION SYSTEM
-- ════════════════════════════════════════════════

function SorinUI:Notify(title, message, duration, iconType)
    duration = duration or 4; iconType = iconType or "info"
    local T = SorinUI.Theme
    local sc = getScale()
    local W = math.clamp(300*sc, 250, 360)
    local H = math.clamp(76*sc, 68, 96)

    local notifGui = Instance.new("ScreenGui")
    notifGui.ResetOnSpawn = false; notifGui.DisplayOrder = 999999
    notifGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,W,0,H); frame.Position = UDim2.new(1,W+20,1,-15)
    frame.AnchorPoint = Vector2.new(1,1); frame.BackgroundColor3 = T.Surface
    frame.BorderSizePixel = 0; frame.Parent = notifGui; corner(frame, 10)
    shimmer(frame, 10)

    local iconMap = {
        success={"check",T.Success},   error={"alert",T.Error},
        warning={"alert",T.Warning},   info={"shield",T.Accent},
        key={"key",T.Accent},          copy={"copy",T.Success},
        discord={"discord",T.Discord}, close={"close",T.Error},
        shield={"shield",T.Accent},
    }
    local m = iconMap[iconType] or iconMap.info
    stroke(frame, m[2], 1, 0.6)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0,3,0.7,0); bar.AnchorPoint = Vector2.new(0,0.5)
    bar.Position = UDim2.new(0,0,0.5,0); bar.BackgroundColor3 = m[2]
    bar.BorderSizePixel = 0; bar.Parent = frame; corner(bar, 2)

    local pbBg = Instance.new("Frame")
    pbBg.Size = UDim2.new(1,0,0,2); pbBg.Position = UDim2.new(0,0,1,-2)
    pbBg.BackgroundColor3 = T.SurfaceLight; pbBg.BorderSizePixel = 0; pbBg.Parent = frame
    local pb = Instance.new("Frame"); pb.Size = UDim2.new(1,0,1,0)
    pb.BackgroundColor3 = m[2]; pb.BorderSizePixel = 0; pb.Parent = pbBg

    local isz = H - 34
    local ico = Instance.new("ImageLabel")
    ico.Size = UDim2.new(0,isz,0,isz); ico.Position = UDim2.new(0,12,0.5,-1)
    ico.AnchorPoint = Vector2.new(0,0.5); ico.BackgroundTransparency = 1
    ico.Image = getIcon(m[1]); ico.ImageColor3 = m[2]
    ico.ScaleType = Enum.ScaleType.Fit; ico.Parent = frame

    local tx = 12 + isz + 10
    lbl({Size=UDim2.new(1,-(tx+10),0,22), Position=UDim2.new(0,tx,0,8),
         Text=title, TextColor3=T.Text, TextSize=math.clamp(14*sc,12,16),
         Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
         TextTruncate=Enum.TextTruncate.AtEnd}, frame)
    lbl({Size=UDim2.new(1,-(tx+10),0,18), Position=UDim2.new(0,tx,0,32),
         Text=message, TextColor3=T.TextDim, TextSize=math.clamp(12*sc,10,13),
         Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
         TextTruncate=Enum.TextTruncate.AtEnd}, frame)

    local id = tick()
    table.insert(Internal.NotificationList, {id=id, frame=frame, gui=notifGui, height=H})

    local function restack()
        local yOff = 0
        for i = #Internal.NotificationList, 1, -1 do
            local n = Internal.NotificationList[i]
            if n and n.frame and n.frame.Parent then
                TweenService:Create(n.frame,TweenInfo.new(0.3,Enum.EasingStyle.Quart),
                    {Position=UDim2.new(1,-15,1,-15-yOff)}):Play()
                yOff = yOff + n.height + 10
            end
        end
    end

    TweenService:Create(frame,TweenInfo.new(0.4,Enum.EasingStyle.Quart),
        {Position=UDim2.new(1,-15,1,-15)}):Play()
    task.wait(0.1); restack()

    local function dismiss()
        for i,n in ipairs(Internal.NotificationList) do
            if n.id == id then table.remove(Internal.NotificationList,i); break end
        end
        TweenService:Create(frame,TweenInfo.new(0.3,Enum.EasingStyle.Quart),
            {Position=UDim2.new(1,W+20,frame.Position.Y.Scale,frame.Position.Y.Offset)}):Play()
        task.wait(0.3); notifGui:Destroy(); restack()
    end

    TweenService:Create(pb,TweenInfo.new(duration,Enum.EasingStyle.Linear),
        {Size=UDim2.new(0,0,1,0)}):Play()
    task.delay(duration, dismiss)

    local cb = Instance.new("TextButton"); cb.Size = UDim2.new(1,0,1,0)
    cb.BackgroundTransparency = 1; cb.Text = ""; cb.Parent = frame
    cb.MouseButton1Click:Connect(dismiss)
end

-- ════════════════════════════════════════════════
--  DOOR OVERLAY
-- ════════════════════════════════════════════════

local function createDoors(parent, W, H)
    local T = SorinUI.Theme
    local overlay = Instance.new("Frame")
    overlay.Name = "DoorOverlay"; overlay.Size = UDim2.new(1,0,1,0)
    overlay.BackgroundTransparency = 1; overlay.ClipsDescendants = true
    overlay.ZIndex = 50; overlay.Parent = parent
    corner(overlay, 12)  -- match main window radius so doors clip to rounded corners

    local left = Instance.new("Frame")
    left.Size = UDim2.new(0.5,0,1,0); left.BackgroundColor3 = T.Header
    left.BorderSizePixel = 0; left.ZIndex = 51; left.Parent = overlay
    grad(left, {T.Header, T.Surface}, 0)

    local right = Instance.new("Frame")
    right.Size = UDim2.new(0.5,0,1,0); right.Position = UDim2.new(0.5,0,0,0)
    right.BackgroundColor3 = T.Surface; right.BorderSizePixel = 0
    right.ZIndex = 51; right.Parent = overlay
    grad(right, {T.Surface, T.Header}, 0)

    local logoSz = math.min(W,H)*0.28
    local logoImg = Instance.new("ImageLabel")
    logoImg.Size = UDim2.new(0,logoSz,0,logoSz)
    logoImg.Position = UDim2.new(0.5,0,0.5,0); logoImg.AnchorPoint = Vector2.new(0.5,0.5)
    logoImg.BackgroundTransparency = 1; logoImg.ZIndex = 54
    logoImg.Image = (SorinUI.Appearance.Icon ~= "") and SorinUI.Appearance.Icon or getIcon("shield")
    logoImg.ImageColor3 = T.Text; logoImg.ScaleType = Enum.ScaleType.Fit
    logoImg.Parent = overlay

    local halfW = math.ceil(W/2)

    local function openDoors(cb)
        TweenService:Create(logoImg,TweenInfo.new(0.2,Enum.EasingStyle.Quart),{ImageTransparency=1}):Play()
        task.wait(0.25)
        TweenService:Create(left,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=UDim2.new(0,-halfW,0,0)}):Play()
        TweenService:Create(right,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.In),{Position=UDim2.new(1,0,0,0)}):Play()
        task.wait(0.45); overlay.Visible = false; if cb then cb() end
    end

    local function closeDoors(cb)
        overlay.Visible = true
        left.Position = UDim2.new(0,-halfW,0,0); right.Position = UDim2.new(1,0,0,0)
        logoImg.ImageTransparency = 1
        TweenService:Create(left,TweenInfo.new(0.35,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,0,0)}):Play()
        TweenService:Create(right,TweenInfo.new(0.35,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,0,0,0)}):Play()
        task.wait(0.38)
        TweenService:Create(logoImg,TweenInfo.new(0.25,Enum.EasingStyle.Quart),{ImageTransparency=0}):Play()
        task.wait(0.3); if cb then cb() end
    end

    return {overlay=overlay, open=openDoors, close=closeDoors}
end

-- ════════════════════════════════════════════════
--  CHANGELOG PANEL  (slides right)
-- ════════════════════════════════════════════════

local function createChangelogPanel(container, winW, panelH, panelW, mainFrame, gap)
    local T = SorinUI.Theme
    panelW = panelW or 210
    local isOpen = false

    local panel = Instance.new("Frame")
    panel.Name = "ChangelogPanel"; panel.Size = UDim2.new(0,0,0,panelH)
    panel.Position = UDim2.new(1,gap,0,0); panel.BackgroundColor3 = T.Surface
    panel.BorderSizePixel = 0; panel.ClipsDescendants = true
    panel.Parent = mainFrame; corner(panel, 12)
    local pStroke = stroke(panel, T.Accent, 1.5, 1)
    shimmer(panel, 12)

    local ph, phClose = panelHeader(panel, "Changelog", "changelog")

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,-52); scroll.Position = UDim2.new(0,0,0,52)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = T.Accent
    scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel
    local pad = Instance.new("UIPadding",scroll)
    pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10)
    pad.PaddingTop=UDim.new(0,6);   pad.PaddingBottom=UDim.new(0,6)
    local layout = Instance.new("UIListLayout",scroll)
    layout.Padding = UDim.new(0,8); layout.SortOrder = Enum.SortOrder.LayoutOrder

    for i, entry in ipairs(SorinUI.Changelog) do
        local ef = Instance.new("Frame"); ef.BackgroundTransparency = 1
        ef.Size = UDim2.new(1,0,0,0); ef.AutomaticSize = Enum.AutomaticSize.Y
        ef.LayoutOrder = i*2; ef.Parent = scroll
        local el = Instance.new("UIListLayout",ef); el.Padding = UDim.new(0,4)
        el.SortOrder = Enum.SortOrder.LayoutOrder
        lbl({
            Size=UDim2.new(1,0,0,16), LayoutOrder=1,
            Text=tostring(entry.Version or entry.version or "?"),
            TextColor3=T.Accent, TextSize=12, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left
        }, ef)
        lbl({
            Size=UDim2.new(1,0,0,13), LayoutOrder=2,
            Text=tostring(entry.Date or entry.date or ""),
            TextColor3=T.TextMuted, TextSize=10, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left
        }, ef)
        for j, ch in ipairs(entry.Changes or entry.changes or {}) do
            lbl({
                Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=j+2,
                Text="  •  "..ch, TextColor3=T.TextDim, TextSize=11, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true
            }, ef)
        end
        if i < #SorinUI.Changelog then
            local dw = Instance.new("Frame"); dw.Size=UDim2.new(1,0,0,2)
            dw.BackgroundTransparency=1; dw.LayoutOrder=i*2+1; dw.Parent=scroll
            local d = Instance.new("Frame"); d.Size=UDim2.new(1,0,0,1)
            d.BackgroundColor3=T.Border; d.BorderSizePixel=0; d.Parent=dw
        end
    end

    local function toggle(icon, cont, baseW)
        isOpen = not isOpen
        if isOpen then
            TweenService:Create(pStroke,TweenInfo.new(0.2),{Transparency=0.3}):Play()
            TweenService:Create(panel,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
                {Size=UDim2.new(0,panelW,0,panelH)}):Play()
            TweenService:Create(cont,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
                {Size=UDim2.new(0,baseW+gap+panelW,0,panelH)}):Play()
            if icon then TweenService:Create(icon,TweenInfo.new(0.3),{Rotation=180}):Play() end
        else
            TweenService:Create(pStroke,TweenInfo.new(0.2),{Transparency=1}):Play()
            TweenService:Create(panel,TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
                {Size=UDim2.new(0,0,0,panelH)}):Play()
            TweenService:Create(cont,TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
                {Size=UDim2.new(0,baseW,0,panelH)}):Play()
            if icon then TweenService:Create(icon,TweenInfo.new(0.3),{Rotation=0}):Play() end
        end
    end

    phClose.MouseButton1Click:Connect(function()
        if isOpen then toggle(nil, container, winW) end
    end)

    return panel, toggle, function() return isOpen end, panelW
end

-- ════════════════════════════════════════════════
--  USER INFO PANEL  (slides left)
-- ════════════════════════════════════════════════

local function createUserInfoPanel(container, winW, panelH, panelW, mainFrame, gap)
    local T = SorinUI.Theme
    panelW = panelW or 180
    local isOpen = false

    local panel = Instance.new("Frame")
    panel.Name = "UserInfoPanel"; panel.Size = UDim2.new(0,0,0,panelH)
    panel.Position = UDim2.new(0,-gap,0,0); panel.AnchorPoint = Vector2.new(1,0)
    panel.BackgroundColor3 = T.Surface; panel.BorderSizePixel = 0
    panel.ClipsDescendants = true; panel.Parent = mainFrame; corner(panel, 12)
    local pStroke = stroke(panel, T.Accent, 1.5, 1)
    shimmer(panel, 12)

    local ph, phClose = panelHeader(panel, "User Info", "user")

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,0,1,-52); content.Position = UDim2.new(0,0,0,52)
    content.BackgroundTransparency = 1; content.Parent = panel
    local cPad = Instance.new("UIPadding",content)
    cPad.PaddingLeft=UDim.new(0,10); cPad.PaddingRight=UDim.new(0,10)
    cPad.PaddingTop=UDim.new(0,8); cPad.PaddingBottom=UDim.new(0,6)
    local cLayout = Instance.new("UIListLayout",content)
    cLayout.Padding = UDim.new(0,6); cLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local player = Players.LocalPlayer

    -- Avatar
    local avWrapper = Instance.new("Frame")
    avWrapper.Size = UDim2.new(0,60,0,60); avWrapper.BackgroundTransparency = 1
    avWrapper.LayoutOrder = 1; avWrapper.Parent = content
    local avGlow = Instance.new("Frame"); avGlow.Size = UDim2.new(1,0,1,0)
    avGlow.Position = UDim2.new(0.5,0,0.5,0); avGlow.AnchorPoint = Vector2.new(0.5,0.5)
    avGlow.BackgroundColor3 = T.Accent; avGlow.BackgroundTransparency = 0.55
    avGlow.BorderSizePixel = 0; avGlow.Parent = avWrapper; corner(avGlow, 6)
    stroke(avGlow, T.Accent, 1.5, 0.3)
    local avCont = Instance.new("Frame"); avCont.Size = UDim2.new(0,54,0,54)
    avCont.Position = UDim2.new(0.5,0,0.5,0); avCont.AnchorPoint = Vector2.new(0.5,0.5)
    avCont.BackgroundColor3 = T.SurfaceLight; avCont.BorderSizePixel = 0
    avCont.ClipsDescendants = true; avCont.Parent = avWrapper; corner(avCont, 5)
    local avImg = Instance.new("ImageLabel"); avImg.Size = UDim2.new(1,0,1,0)
    avImg.BackgroundTransparency = 1; avImg.ScaleType = Enum.ScaleType.Crop
    avImg.Parent = avCont
    pcall(function()
        avImg.Image = Players:GetUserThumbnailAsync(
            player and player.UserId or 0,
            Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    end)

    -- Name
    lbl({Size=UDim2.new(1,0,0,16), LayoutOrder=2,
         Text=player and player.DisplayName or "User",
         TextColor3=T.Text, TextSize=13, Font=Enum.Font.GothamBold,
         TextTruncate=Enum.TextTruncate.AtEnd,
         TextXAlignment=Enum.TextXAlignment.Center}, content)

    -- Divider
    local div1 = Instance.new("Frame"); div1.Size = UDim2.new(1,0,0,1)
    div1.BackgroundColor3 = T.Border; div1.BorderSizePixel = 0
    div1.LayoutOrder = 3; div1.Parent = content

    -- Info rows
    local function infoRow(order, label, value, valueColor)
        local rf = Instance.new("Frame"); rf.Size = UDim2.new(1,0,0,32)
        rf.BackgroundTransparency = 1; rf.LayoutOrder = order; rf.Parent = content
        lbl({Size=UDim2.new(1,0,0,13), Position=UDim2.new(0,0,0,0),
             Text=label, TextColor3=T.TextMuted, TextSize=9, Font=Enum.Font.Gotham,
             TextXAlignment=Enum.TextXAlignment.Left}, rf)
        lbl({Size=UDim2.new(1,0,0,15), Position=UDim2.new(0,0,0,14),
             Text=value, TextColor3=valueColor or T.Accent, TextSize=11, Font=Enum.Font.GothamBold,
             TextXAlignment=Enum.TextXAlignment.Left,
             TextTruncate=Enum.TextTruncate.AtEnd}, rf)
    end

    infoRow(4, "Executor", getExecutorName())
    infoRow(5, "Device",   getDeviceType())

    -- HWID row with copy button
    local hwid = getHWID()
    local hwRow = Instance.new("Frame"); hwRow.Size = UDim2.new(1,0,0,32)
    hwRow.BackgroundTransparency = 1; hwRow.LayoutOrder = 6; hwRow.Parent = content
    lbl({Size=UDim2.new(1,-22,0,13), Position=UDim2.new(0,0,0,0),
         Text="HWID", TextColor3=T.TextMuted, TextSize=9, Font=Enum.Font.Gotham,
         TextXAlignment=Enum.TextXAlignment.Left}, hwRow)
    lbl({Size=UDim2.new(1,-22,0,15), Position=UDim2.new(0,0,0,14),
         Text=string.rep("•",12), TextColor3=T.TextDim, TextSize=10, Font=Enum.Font.GothamBold,
         TextXAlignment=Enum.TextXAlignment.Left}, hwRow)
    local copyBtn = Instance.new("ImageButton")
    copyBtn.Size = UDim2.new(0,18,0,18); copyBtn.Position = UDim2.new(1,0,0.5,0)
    copyBtn.AnchorPoint = Vector2.new(1,0.5); copyBtn.BackgroundTransparency = 1
    copyBtn.Image = getIcon("copy"); copyBtn.ImageColor3 = T.TextDim
    copyBtn.ScaleType = Enum.ScaleType.Fit; copyBtn.Parent = hwRow
    copyBtn.MouseEnter:Connect(function() TweenService:Create(copyBtn,TweenInfo.new(0.15),{ImageColor3=T.Accent}):Play() end)
    copyBtn.MouseLeave:Connect(function() TweenService:Create(copyBtn,TweenInfo.new(0.15),{ImageColor3=T.TextDim}):Play() end)
    copyBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(hwid) end)
        TweenService:Create(copyBtn,TweenInfo.new(0.1),{ImageColor3=T.Success}):Play()
        task.delay(0.5,function() TweenService:Create(copyBtn,TweenInfo.new(0.15),{ImageColor3=T.TextDim}):Play() end)
        SorinUI:Notify("Copied","HWID copied to clipboard",2,"copy")
    end)

    -- Clock
    local div2 = Instance.new("Frame"); div2.Size = UDim2.new(1,0,0,1)
    div2.BackgroundColor3 = T.Border; div2.BorderSizePixel = 0
    div2.LayoutOrder = 7; div2.Parent = content

    local clockCont = Instance.new("Frame"); clockCont.Size = UDim2.new(1,0,0,36)
    clockCont.BackgroundTransparency = 1; clockCont.LayoutOrder = 8; clockCont.Parent = content
    local clockIco = Instance.new("ImageLabel")
    clockIco.Size = UDim2.new(0,14,0,14); clockIco.Position = UDim2.new(0,0,0,2)
    clockIco.BackgroundTransparency = 1; clockIco.Image = getIcon("clock")
    clockIco.ImageColor3 = T.Accent; clockIco.ScaleType = Enum.ScaleType.Fit
    clockIco.Parent = clockCont
    local timeLbl = lbl({Size=UDim2.new(1,-18,0,16), Position=UDim2.new(0,18,0,0),
         Text=formatTime(), TextColor3=T.Accent, TextSize=14, Font=Enum.Font.GothamBold,
         TextXAlignment=Enum.TextXAlignment.Left}, clockCont)
    local dateLbl = lbl({Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,20),
         Text=formatDate(), TextColor3=T.TextMuted, TextSize=10, Font=Enum.Font.Gotham,
         TextXAlignment=Enum.TextXAlignment.Left}, clockCont)

    local clockRunning = true
    task.spawn(function()
        while clockRunning do
            if not timeLbl.Parent then clockRunning = false; break end
            timeLbl.Text = formatTime(); dateLbl.Text = formatDate()
            task.wait(1)
        end
    end)
    panel.Destroying:Connect(function() clockRunning = false end)

    local function toggle(icon, cont, baseW)
        isOpen = not isOpen
        if isOpen then
            TweenService:Create(pStroke,TweenInfo.new(0.2),{Transparency=0.3}):Play()
            TweenService:Create(panel,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
                {Size=UDim2.new(0,panelW,0,panelH)}):Play()
            TweenService:Create(cont,TweenInfo.new(0.4,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
                {Size=UDim2.new(0,baseW+gap+panelW,0,panelH)}):Play()
        else
            TweenService:Create(pStroke,TweenInfo.new(0.2),{Transparency=1}):Play()
            TweenService:Create(panel,TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
                {Size=UDim2.new(0,0,0,panelH)}):Play()
            TweenService:Create(cont,TweenInfo.new(0.3,Enum.EasingStyle.Quart,Enum.EasingDirection.In),
                {Size=UDim2.new(0,baseW,0,panelH)}):Play()
        end
    end

    phClose.MouseButton1Click:Connect(function()
        if isOpen then toggle(nil, container, winW) end
    end)

    return panel, toggle, function() return isOpen end, panelW
end

-- ════════════════════════════════════════════════
--  CENTERED LAYOUT BUILDER
-- ════════════════════════════════════════════════

local function buildCenteredUI(screenGui, winW, winH, userPW, clPW, gap)
    local panelH = winH  -- panels match window height

    local container = Instance.new("Frame")
    container.Name = "Container"; container.Size = UDim2.new(0,winW,0,panelH)
    container.Position = UDim2.new(0.5,0,1.5,0); container.AnchorPoint = Vector2.new(0.5,0.5)
    container.BackgroundTransparency = 1; container.Parent = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"; mainFrame.Size = UDim2.new(0,winW,0,winH)
    mainFrame.Position = UDim2.new(0.5,0,0,0); mainFrame.AnchorPoint = Vector2.new(0.5,0)
    mainFrame.BackgroundColor3 = SorinUI.Theme.Surface
    mainFrame.BorderSizePixel = 0; mainFrame.Parent = container; corner(mainFrame, 12)
    stroke(mainFrame, SorinUI.Theme.Accent, 1.5, 0.45)
    shimmer(mainFrame, 12)

    local userPanel, toggleUser, isUserOpen, userPW2 =
        createUserInfoPanel(container, winW, panelH, userPW, mainFrame, gap)
    local clPanel, toggleCL, isCLOpen, clPW2 =
        createChangelogPanel(container, winW, panelH, clPW, mainFrame, gap)

    local function getContainerWidth()
        local w = winW
        if isUserOpen() then w = w + gap + userPW2 end
        if isCLOpen()   then w = w + gap + clPW2  end
        return w
    end

    local function doToggleUser(icon)
        local cur = getContainerWidth()
        if isUserOpen() then toggleUser(icon, container, cur - gap - userPW2)
        else                 toggleUser(icon, container, cur) end
    end

    local function doToggleCL(icon)
        local cur = getContainerWidth()
        if isCLOpen() then toggleCL(icon, container, cur - gap - clPW2)
        else               toggleCL(icon, container, cur) end
    end

    local function closeAllPanels(uIcon, cIcon, cb)
        if isCLOpen()   then doToggleCL(cIcon);   task.wait(0.35) end
        if isUserOpen() then doToggleUser(uIcon);  task.wait(0.35) end
        if cb then cb() end
    end

    return {
        container    = container,
        mainFrame    = mainFrame,
        toggleUser   = doToggleUser,
        toggleCL     = doToggleCL,
        isUserOpen   = isUserOpen,
        isCLOpen     = isCLOpen,
        closeAllPanels = closeAllPanels,
    }
end

-- ════════════════════════════════════════════════
--  LOADING SCREEN  (phase-based, like Kirmada)
-- ════════════════════════════════════════════════

local function showLoadingScreen(onComplete)
    local T = SorinUI.Theme
    local mobile = isMobile()
    local oldGui = CoreGui:FindFirstChild("SorinLoadingScreen"); if oldGui then oldGui:Destroy() end
    local oldBlur = Lighting:FindFirstChild("SorinLoadingBlur");  if oldBlur then oldBlur:Destroy() end

    local blurFx = Instance.new("BlurEffect")
    blurFx.Name = "SorinLoadingBlur"; blurFx.Size = 0; blurFx.Parent = Lighting

    local gui = Instance.new("ScreenGui"); gui.Name = "SorinLoadingScreen"
    gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = CoreGui

    local bg = Instance.new("Frame"); bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = T.Background; bg.BackgroundTransparency = 1
    bg.BorderSizePixel = 0; bg.Parent = gui

    -- Sweep lines — multiple at different Y positions, widths, colors, rotations
    local sweepConfigs = {
        {y=0.18, w=0.28, rot=0,   col=T.Accent,     spd=1.0},
        {y=0.35, w=0.18, rot=-4,  col=T.Secondary,  spd=0.75},
        {y=0.50, w=0.32, rot=0,   col=T.Accent,     spd=1.3},
        {y=0.65, w=0.20, rot=4,   col=T.SecondaryL, spd=0.9},
        {y=0.82, w=0.24, rot=-2,  col=T.AccentHover,spd=1.1},
    }
    local sweepLines = {}
    for i, cfg in ipairs(sweepConfigs) do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(cfg.w, 0, 0, mobile and 1 or 2)
        line.Position = UDim2.new(1.4, 0, cfg.y, 0)
        line.Rotation = cfg.rot
        line.BackgroundColor3 = cfg.col
        line.BackgroundTransparency = 1
        line.BorderSizePixel = 0
        line.Parent = bg
        Instance.new("UICorner", line).CornerRadius = UDim.new(1, 0)
        local g = Instance.new("UIGradient", line)
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.35, 0.2),
            NumberSequenceKeypoint.new(1, 0),
        })
        sweepLines[i] = {frame=line, y=cfg.y, spd=cfg.spd}
    end

    -- Logo
    local logoSz = mobile and 48 or 64
    local logoImg = Instance.new("ImageLabel")
    logoImg.Size = UDim2.new(0,logoSz,0,logoSz)
    logoImg.Position = UDim2.new(0.5,0,0.32,0); logoImg.AnchorPoint = Vector2.new(0.5,0.5)
    logoImg.BackgroundTransparency = 1
    logoImg.Image = (SorinUI.Appearance.Icon ~= "") and SorinUI.Appearance.Icon or getIcon("shield")
    logoImg.ImageColor3 = T.Text; logoImg.ScaleType = Enum.ScaleType.Fit
    logoImg.ImageTransparency = 1; logoImg.Parent = bg

    -- Phases container
    local phaseNames = {"Initializing", "Creating folders", "Downloading assets", "Preparing interface", "Ready"}
    local phasesSz = mobile and 14 or 17
    local phCont = Instance.new("Frame")
    phCont.Size = UDim2.new(0, mobile and 200 or 260, 0, mobile and 140 or 170)
    phCont.Position = UDim2.new(0.5,0,0.62,0); phCont.AnchorPoint = Vector2.new(0.5,0.5)
    phCont.BackgroundTransparency = 1; phCont.Parent = bg
    local phLayout = Instance.new("UIListLayout",phCont)
    phLayout.Padding = UDim.new(0, mobile and 8 or 11); phLayout.SortOrder = Enum.SortOrder.LayoutOrder
    phLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local phases = {}
    for i, name in ipairs(phaseNames) do
        local row = Instance.new("Frame"); row.Size = UDim2.new(1,0,0, mobile and 20 or 26)
        row.BackgroundTransparency = 1; row.LayoutOrder = i; row.Parent = phCont
        local ind = Instance.new("TextLabel")
        ind.Size = UDim2.new(0, mobile and 22 or 28, 1, 0)
        ind.BackgroundTransparency = 1; ind.Text = "○"
        ind.TextColor3 = T.Pending; ind.TextSize = phasesSz
        ind.Font = Enum.Font.GothamBold; ind.TextTransparency = 1; ind.Parent = row
        local lab = Instance.new("TextLabel")
        lab.Size = UDim2.new(1, mobile and -26 or -32, 1, 0)
        lab.Position = UDim2.new(0, mobile and 26 or 32, 0, 0)
        lab.BackgroundTransparency = 1; lab.Text = name
        lab.TextColor3 = T.Pending; lab.TextSize = phasesSz
        lab.Font = Enum.Font.GothamBold; lab.TextXAlignment = Enum.TextXAlignment.Left
        lab.TextTransparency = 1; lab.Parent = row
        phases[i] = {ind=ind, lab=lab}
    end

    local currentPhase = 0
    local pulseThread = nil

    local function setPhase(num)
        if pulseThread then task.cancel(pulseThread); pulseThread = nil end
        for i = 1, 5 do
            local ph = phases[i]
            if i < num then
                ph.ind.Text = "●"
                TweenService:Create(ph.ind,TweenInfo.new(0.2),{TextColor3=T.Success,TextTransparency=0}):Play()
                TweenService:Create(ph.lab,TweenInfo.new(0.2),{TextColor3=T.Success}):Play()
            elseif i == num then
                ph.ind.Text = "●"; ph.ind.TextTransparency = 0
                TweenService:Create(ph.ind,TweenInfo.new(0.2),{TextColor3=T.Accent}):Play()
                TweenService:Create(ph.lab,TweenInfo.new(0.2),{TextColor3=T.Text}):Play()
                currentPhase = num
                pulseThread = task.spawn(function()
                    while currentPhase == num do
                        TweenService:Create(ph.ind,TweenInfo.new(0.4),{TextTransparency=0.5}):Play()
                        task.wait(0.4)
                        if currentPhase ~= num then break end
                        TweenService:Create(ph.ind,TweenInfo.new(0.4),{TextTransparency=0}):Play()
                        task.wait(0.4)
                    end
                end)
            else
                ph.ind.Text = "○"; ph.ind.TextColor3 = T.Pending
                ph.lab.TextColor3 = T.Pending
            end
        end
    end

    local completed = false
    task.spawn(function()
        TweenService:Create(blurFx,TweenInfo.new(0.5),{Size=20}):Play()
        TweenService:Create(bg,TweenInfo.new(0.4),{BackgroundTransparency=0.22}):Play()
        task.wait(0.3)
        TweenService:Create(logoImg,TweenInfo.new(0.4,Enum.EasingStyle.Back),{ImageTransparency=0}):Play()

        -- start sweep line loop — each line runs independently at its own speed
        local sweepRunning = true
        for _, sl in ipairs(sweepLines) do
            task.spawn(function()
                while sweepRunning do
                    sl.frame.Position = UDim2.new(1.4, 0, sl.y, 0)
                    sl.frame.BackgroundTransparency = 0.3
                    TweenService:Create(sl.frame, TweenInfo.new(sl.spd, Enum.EasingStyle.Linear),
                        {Position = UDim2.new(-0.45, 0, sl.y, 0), BackgroundTransparency = 0.85}):Play()
                    task.wait(sl.spd + math.random(0, 30) * 0.01)
                end
                sl.frame.BackgroundTransparency = 1
            end)
        end

        task.wait(0.25)
        for i = 1,5 do
            task.delay((i-1)*0.07, function()
                TweenService:Create(phases[i].ind,TweenInfo.new(0.25),{TextTransparency=0}):Play()
                TweenService:Create(phases[i].lab,TweenInfo.new(0.25),{TextTransparency=0}):Play()
            end)
        end
        task.wait(0.5)
        setPhase(1) task.wait(0.3)
        setPhase(2) ensureFolders() task.wait(0.25)
        setPhase(3)
        do
            local iconsDone = false
            task.spawn(function() loadAllIcons(); iconsDone = true end)
            local t0 = tick()
            while not iconsDone and (tick() - t0) < 8 do task.wait(0.1) end
            Internal.IconsLoaded = true  -- proceed even if timed out, fallbacks cover the rest
        end
        task.wait(0.2)
        setPhase(4) task.wait(0.3)
        setPhase(5) task.wait(0.55)
        if pulseThread then task.cancel(pulseThread) end
        sweepRunning = false
        -- fade out
        TweenService:Create(bg,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play()
        TweenService:Create(logoImg,TweenInfo.new(0.3),{ImageTransparency=1}):Play()
        for i=1,5 do
            TweenService:Create(phases[i].ind,TweenInfo.new(0.25),{TextTransparency=1}):Play()
            TweenService:Create(phases[i].lab,TweenInfo.new(0.25),{TextTransparency=1}):Play()
        end
        TweenService:Create(blurFx,TweenInfo.new(0.3),{Size=0}):Play()
        task.wait(0.5); gui:Destroy(); blurFx:Destroy()
        if onComplete then onComplete() end
        completed = true
    end)

    local t0 = tick()
    while not completed and (tick() - t0) < 20 do task.wait(0.05) end
end

local function ensureIconsReady(cb)
    if Internal.IconsLoaded then
        if cb then cb() end
    elseif allIconsCached() then
        -- all icon files already on disk — load silently, skip intro
        loadAllIconsFromCache()
        if cb then cb() end
    else
        showLoadingScreen(cb)
    end
end

-- ════════════════════════════════════════════════
--  HEADER BUTTON HELPER
-- ════════════════════════════════════════════════

local function headerIconBtn(parent, iconKey, color, xRight, zidx)
    local T = SorinUI.Theme
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,28,0,28); btn.AnchorPoint = Vector2.new(1,0.5)
    btn.Position = UDim2.new(1,-xRight,0.5,0)
    btn.BackgroundColor3 = T.SurfaceLight; btn.BackgroundTransparency = 0.4
    btn.BorderSizePixel = 0; btn.Text = ""; btn.AutoButtonColor = false
    btn.ZIndex = zidx or 11; btn.Parent = parent; corner(btn, 7)
    stroke(btn, color or T.Border, 1, 0.55)
    local ico = Instance.new("ImageLabel")
    ico.Size = UDim2.new(0,16,0,16); ico.AnchorPoint = Vector2.new(0.5,0.5)
    ico.Position = UDim2.new(0.5,0,0.5,0); ico.BackgroundTransparency = 1
    ico.Image = getIcon(iconKey); ico.ImageColor3 = color or T.TextDim
    ico.ScaleType = Enum.ScaleType.Fit; ico.ZIndex = (zidx or 11)+1; ico.Parent = btn
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundTransparency=0.1}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundTransparency=0.4}):Play()
    end)
    return btn, ico
end

-- ════════════════════════════════════════════════
--  DISCORD INVITE  (RPC → clipboard fallback)
-- ════════════════════════════════════════════════

local function openDiscordInvite(url)
    -- extract invite code from URL
    local code = url:match("discord%.gg/([^/%s]+)") or url:match("discord%.com/invite/([^/%s]+)")
    -- resolve http request function (executor-dependent)
    local httpReq = (typeof(httpRequest) == "function" and httpRequest)
                 or (typeof(request)     == "function" and request)
                 or (syn and typeof(syn.request) == "function" and syn.request)
                 or nil

    if code and httpReq then
        local ports = {6463,6464,6465,6466,6467,6468,6469,6470,6471,6472}
        for _, port in ipairs(ports) do
            local ok, res = pcall(httpReq, {
                Url    = ("http://127.0.0.1:%d/rpc?v=1"):format(port),
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Origin"]       = "https://discord.com",
                },
                Body = HttpService:JSONEncode({
                    cmd   = "INVITE_BROWSER",
                    args  = { code = code },
                    nonce = HttpService:GenerateGUID(false),
                }),
            })
            if ok and res and (res.Success or (res.StatusCode and res.StatusCode >= 200 and res.StatusCode < 300)) then
                return true, "rpc"
            end
        end
    end

    -- fallback: copy to clipboard
    local copied = false
    if typeof(setclipboard) == "function" then
        copied = pcall(setclipboard, url)
    elseif typeof(toclipboard) == "function" then
        copied = pcall(toclipboard, url)
    end
    return false, copied and "clipboard" or "none"
end

-- ════════════════════════════════════════════════
--  BUILD KEY UI
-- ════════════════════════════════════════════════

local function buildKeyUI()
    local T = SorinUI.Theme
    local mobile   = isMobile()
    local sc       = getScale()
    local hasShop  = SorinUI.Shop.Enabled
    local hasCL    = #SorinUI.Changelog > 0
    local hasUser  = SorinUI.Options.UserInfoEnabled and not mobile
    local hasProviders = #SorinUI.Providers > 0

    local shopH    = hasShop and 55 or 0
    local winW     = mobile and math.clamp(380*sc,310,430) or 400
    local winH     = 360 + shopH
    local userPW   = 180
    local clPW     = 210
    local gap      = 12

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SorinKeyUI"; screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false; screenGui.IgnoreGuiInset = true
    screenGui.Parent = CoreGui

    local ui = buildCenteredUI(screenGui, winW, winH, userPW, clPW, gap)
    local container = ui.container
    local main      = ui.mainFrame

    -- ── TOP BAR ──────────────────────────────────────
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1,0,0,46); topBar.BackgroundColor3 = T.Header
    topBar.BorderSizePixel = 0; topBar.ZIndex = 10; topBar.Parent = main; corner(topBar, 12)
    local tbFill = Instance.new("Frame"); tbFill.Size = UDim2.new(1,0,0,12)
    tbFill.Position = UDim2.new(0,0,1,-12); tbFill.BackgroundColor3 = T.Header
    tbFill.BorderSizePixel = 0; tbFill.Parent = topBar
    local tbLine = Instance.new("Frame"); tbLine.Size = UDim2.new(1,0,0,1)
    tbLine.Position = UDim2.new(0,0,1,0); tbLine.BackgroundColor3 = T.Accent
    tbLine.BackgroundTransparency = 0.6; tbLine.BorderSizePixel = 0
    tbLine.ZIndex = 11; tbLine.Parent = topBar

    -- Brand
    local brand = Instance.new("Frame")
    brand.Size = UDim2.new(0,220,1,0); brand.Position = UDim2.new(0,12,0,0)
    brand.BackgroundTransparency = 1; brand.ZIndex = 11; brand.Parent = topBar

    if SorinUI.Appearance.Icon ~= "" then
        local li = Instance.new("ImageLabel"); li.BackgroundTransparency = 1
        li.Size = SorinUI.Appearance.IconSize; li.AnchorPoint = Vector2.new(0,0.5)
        li.Position = UDim2.new(0,0,0.5,0); li.Image = SorinUI.Appearance.Icon
        li.ScaleType = Enum.ScaleType.Fit; li.ZIndex = 11; li.Parent = brand
    else
        local logoBox = Instance.new("Frame"); logoBox.Size = UDim2.new(0,24,0,24)
        logoBox.AnchorPoint = Vector2.new(0,0.5); logoBox.Position = UDim2.new(0,0,0.5,0)
        logoBox.BackgroundColor3 = T.Accent; logoBox.BorderSizePixel = 0
        logoBox.ZIndex = 11; logoBox.Parent = brand; corner(logoBox, 6)
        grad(logoBox, {T.Accent, T.Secondary}, 135)
        lbl({Size=UDim2.new(1,0,1,0),Text="◈",TextColor3=Color3.new(1,1,1),
             TextSize=12,Font=Enum.Font.GothamBold,ZIndex=12,
             TextXAlignment=Enum.TextXAlignment.Center}, logoBox)
    end

    local iconOff = (SorinUI.Appearance.Icon ~= "") and (SorinUI.Appearance.IconSize.X.Offset+8) or 32
    lbl({Name="TitleLabel", Size=UDim2.new(1,-iconOff-46,1,0), Position=UDim2.new(0,iconOff,0,0),
         Text=SorinUI.Appearance.Title, TextColor3=T.Text, TextSize=14,
         Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
         TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=11}, brand)

    if SorinUI.Appearance.Version ~= "" then
        local vb = Instance.new("TextLabel"); vb.BackgroundColor3 = T.Secondary
        vb.BackgroundTransparency = 0.68; vb.Size = UDim2.new(0,38,0,14)
        vb.AnchorPoint = Vector2.new(0,0.5); vb.Position = UDim2.new(0,iconOff+100,0.5,0)
        vb.Text = SorinUI.Appearance.Version; vb.TextColor3 = T.SecondaryL
        vb.TextSize = 9; vb.Font = Enum.Font.GothamBold; vb.ZIndex = 11
        vb.Parent = brand; corner(vb, 4)
    end

    -- Right-side header buttons
    local closeBtn, closeIco = headerIconBtn(topBar, "close", T.Error, 8)
    closeBtn.BackgroundColor3 = T.Error; closeBtn.BackgroundTransparency = 0.75
    stroke(closeBtn, T.Error, 1, 0.5)

    local discordBtn, discordIco
    if SorinUI.Links.Discord ~= "" then
        discordBtn, discordIco = headerIconBtn(topBar, "discord", T.Discord, 44)
    end

    local clBtn, clIco
    if hasCL then clBtn, clIco = headerIconBtn(topBar, "changelog", T.Accent, discordBtn and 80 or 44) end

    local userBtn, userIco
    if hasUser then
        local off = 44 + (discordBtn and 36 or 0) + (clBtn and 36 or 0)
        userBtn, userIco = headerIconBtn(topBar, "user", T.Accent, off)
    end

    -- ── CONTENT AREA ────────────────────────────────
    local content = Instance.new("Frame")
    content.Name = "Content"; content.BackgroundTransparency = 1
    content.Size = UDim2.new(1,-28,1,-46-shopH); content.Position = UDim2.new(0,14,0,54)
    content.Parent = main

    -- Status frame
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1,0,0,58); statusFrame.BackgroundColor3 = T.Input
    statusFrame.BorderSizePixel = 0; statusFrame.ClipsDescendants = true
    statusFrame.Parent = content; corner(statusFrame, 8)
    local statusStroke = stroke(statusFrame, T.Accent, 1, 0.78)

    local statusIco = Instance.new("ImageLabel")
    statusIco.Size = UDim2.new(0,24,0,24); statusIco.Position = UDim2.new(0,14,0.5,0)
    statusIco.AnchorPoint = Vector2.new(0,0.5); statusIco.BackgroundTransparency = 1
    statusIco.Image = getIcon("lock"); statusIco.ImageColor3 = T.StatusIdle
    statusIco.ScaleType = Enum.ScaleType.Fit; statusIco.Parent = statusFrame

    local statusTitle = lbl({
        Size=UDim2.new(1,-60,0,20), Position=UDim2.new(0,48,0,8),
        Text=SorinUI.Appearance.Title, TextColor3=T.Text, TextSize=15,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd
    }, statusFrame)
    local statusSub = lbl({
        Size=UDim2.new(1,-60,0,16), Position=UDim2.new(0,48,0,30),
        Text=SorinUI.Appearance.Subtitle, TextColor3=T.StatusIdle, TextSize=11,
        Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd
    }, statusFrame)

    -- Divider
    local div1 = Instance.new("Frame"); div1.Size = UDim2.new(1,0,0,1)
    div1.Position = UDim2.new(0,0,0,68); div1.BackgroundColor3 = T.Border
    div1.BackgroundTransparency = 0.5; div1.BorderSizePixel = 0; div1.Parent = content

    -- Section: providers or Get Key
    local sectionY = 76
    lbl({Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,sectionY),
         Text= hasProviders and "Select key duration" or "Get your key",
         TextColor3=T.TextMuted, TextSize=10, Font=Enum.Font.GothamSemibold,
         TextXAlignment=Enum.TextXAlignment.Left}, content)

    local acquireY = sectionY + 16
    if hasProviders then
        local provRow = Instance.new("Frame"); provRow.Name = "ProvRow"
        provRow.Size = UDim2.new(1,0,0,52); provRow.Position = UDim2.new(0,0,0,acquireY)
        provRow.BackgroundTransparency = 1; provRow.Parent = content

        local gap2 = 0.018
        local bw = (1 - gap2*(#SorinUI.Providers-1)) / #SorinUI.Providers
        for i, prov in ipairs(SorinUI.Providers) do
            local xp = (i-1)*(bw+gap2)
            local btn = Instance.new("TextButton"); btn.Name = "Prov_"..prov.name
            btn.Size = UDim2.new(bw,0,1,0); btn.Position = UDim2.new(xp,0,0,0)
            btn.BackgroundColor3 = T.SurfaceLight; btn.BorderSizePixel = 0
            btn.Text = ""; btn.AutoButtonColor = false; btn.Parent = provRow; corner(btn, 6)
            local ps = stroke(btn, T.Border, 1, 0.4)
            local la = Instance.new("Frame"); la.Size = UDim2.new(0,2,0.6,0)
            la.AnchorPoint = Vector2.new(0,0.5); la.Position = UDim2.new(0,0,0.5,0)
            la.BackgroundColor3 = prov.color or T.Accent; la.BackgroundTransparency = 0.25
            la.BorderSizePixel = 0; la.ZIndex = 3; la.Parent = btn; corner(la, 1)
            lbl({Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,0,4),
                 Text=prov.duration or prov.name, TextColor3=prov.color or T.Accent,
                 TextSize=15, Font=Enum.Font.GothamBold,
                 TextXAlignment=Enum.TextXAlignment.Center}, btn)
            local dots = string.rep("●", prov.checkpoints or 1, " ")
            lbl({Size=UDim2.new(1,0,0,11), Position=UDim2.new(0,0,0,26),
                 Text=dots, TextColor3=prov.color or T.Accent, TextSize=8,
                 Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Center}, btn)
            lbl({Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,38),
                 Text=prov.checkpoints and (tostring(prov.checkpoints).." CP") or "",
                 TextColor3=T.TextMuted, TextSize=8, Font=Enum.Font.Gotham,
                 TextXAlignment=Enum.TextXAlignment.Center}, btn)
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=T.SurfaceMid}):Play()
                TweenService:Create(ps,TweenInfo.new(0.15),{Color=prov.color or T.Accent,Transparency=0.1,Thickness=1.5}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=T.SurfaceLight}):Play()
                TweenService:Create(ps,TweenInfo.new(0.15),{Color=T.Border,Transparency=0.4,Thickness=1}):Play()
            end)
            btn.MouseButton1Click:Connect(function()
                if setclipboard and prov.link then setclipboard(prov.link) end
                SorinUI:Notify("Link Copied", prov.name.." link copied!", 3, "copy")
            end)
        end
    else
        -- Single "Get Key" button
        local gkBtn = Instance.new("TextButton")
        gkBtn.Size = UDim2.new(1,0,0,42); gkBtn.Position = UDim2.new(0,0,0,acquireY)
        gkBtn.BackgroundColor3 = T.SurfaceLight; gkBtn.BorderSizePixel = 0
        gkBtn.Text = ""; gkBtn.AutoButtonColor = false; gkBtn.Parent = content; corner(gkBtn, 7)
        local gkStroke = stroke(gkBtn, T.Accent, 1, 0.6)
        local gkContent = Instance.new("Frame"); gkContent.Size = UDim2.new(1,0,1,0)
        gkContent.BackgroundTransparency = 1; gkContent.Parent = gkBtn
        local gkLayout = Instance.new("UIListLayout",gkContent)
        gkLayout.FillDirection = Enum.FillDirection.Horizontal
        gkLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        gkLayout.VerticalAlignment = Enum.VerticalAlignment.Center; gkLayout.Padding = UDim.new(0,8)
        local gkIco = Instance.new("ImageLabel"); gkIco.Size = UDim2.new(0,18,0,18)
        gkIco.BackgroundTransparency = 1; gkIco.Image = getIcon("key")
        gkIco.ImageColor3 = T.Accent; gkIco.ScaleType = Enum.ScaleType.Fit
        gkIco.LayoutOrder = 1; gkIco.Parent = gkContent
        local gkLab = Instance.new("TextLabel"); gkLab.Size = UDim2.new(0,0,0,18)
        gkLab.AutomaticSize = Enum.AutomaticSize.X; gkLab.BackgroundTransparency = 1
        gkLab.Text = "Get Key"; gkLab.TextColor3 = T.Text; gkLab.TextSize = 14
        gkLab.Font = Enum.Font.GothamBold; gkLab.LayoutOrder = 2; gkLab.Parent = gkContent
        gkBtn.MouseEnter:Connect(function()
            TweenService:Create(gkBtn,TweenInfo.new(0.15),{BackgroundColor3=T.SurfaceMid}):Play()
            TweenService:Create(gkStroke,TweenInfo.new(0.15),{Transparency=0.2}):Play()
        end)
        gkBtn.MouseLeave:Connect(function()
            TweenService:Create(gkBtn,TweenInfo.new(0.15),{BackgroundColor3=T.SurfaceLight}):Play()
            TweenService:Create(gkStroke,TweenInfo.new(0.15),{Transparency=0.6}):Play()
        end)
        gkBtn.MouseButton1Click:Connect(function()
            if SorinUI.Links.GetKey ~= "" then
                pcall(function() setclipboard(SorinUI.Links.GetKey) end)
                SorinUI:Notify("Copied", "Key link copied!", 3, "copy")
            else
                SorinUI:Notify("Error", "No key link configured", 3, "warning")
            end
        end)
    end

    local inputY = acquireY + (hasProviders and 60 or 50)

    -- Divider
    local div2 = Instance.new("Frame"); div2.Size = UDim2.new(1,0,0,1)
    div2.Position = UDim2.new(0,0,0,inputY-8); div2.BackgroundColor3 = T.Border
    div2.BackgroundTransparency = 0.5; div2.BorderSizePixel = 0; div2.Parent = content

    -- Section: input
    lbl({Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,inputY),
         Text="Paste your key below", TextColor3=T.TextMuted, TextSize=10,
         Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left}, content)

    local inputFrame = Instance.new("Frame")
    inputFrame.Name = "InputFrame"; inputFrame.Size = UDim2.new(1,0,0,46)
    inputFrame.Position = UDim2.new(0,0,0,inputY+14); inputFrame.BackgroundColor3 = T.Input
    inputFrame.BorderSizePixel = 0; inputFrame.Parent = content; corner(inputFrame, 7)
    local inputStroke = stroke(inputFrame, T.Accent, 1, 0.78)

    local keyInput = Instance.new("TextBox"); keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1,-24,1,0); keyInput.Position = UDim2.new(0,12,0,0)
    keyInput.BackgroundTransparency = 1; keyInput.PlaceholderText = "Enter your key..."
    keyInput.PlaceholderColor3 = T.TextMuted; keyInput.Text = ""
    keyInput.TextColor3 = T.Text; keyInput.TextSize = 14
    keyInput.Font = Enum.Font.Gotham; keyInput.ClearTextOnFocus = false
    keyInput.TextXAlignment = Enum.TextXAlignment.Left
    keyInput.TextTruncate = Enum.TextTruncate.AtEnd; keyInput.Parent = inputFrame
    keyInput.Focused:Connect(function()
        TweenService:Create(inputStroke,TweenInfo.new(0.15),{Color=T.Accent,Thickness=1.5,Transparency=0.25}):Play()
    end)
    keyInput.FocusLost:Connect(function(enter)
        TweenService:Create(inputStroke,TweenInfo.new(0.15),{Color=T.Accent,Thickness=1,Transparency=0.78}):Play()
    end)

    local redeemY = inputY + 14 + 46 + 10

    -- Redeem Key button
    local redeemBtn = Instance.new("TextButton"); redeemBtn.Name = "RedeemBtn"
    redeemBtn.Size = UDim2.new(0.78,0,0,42); redeemBtn.AnchorPoint = Vector2.new(0.5,0)
    redeemBtn.Position = UDim2.new(0.5,0,0,redeemY); redeemBtn.BackgroundColor3 = T.Success
    redeemBtn.BorderSizePixel = 0; redeemBtn.Text = ""; redeemBtn.AutoButtonColor = false
    redeemBtn.Parent = content; corner(redeemBtn, 7)
    local rGlow = stroke(redeemBtn, T.SuccessHover, 1, 0.5)
    grad(redeemBtn, {T.Success, T.SuccessDark}, 90)
    local rContent = Instance.new("Frame"); rContent.Size = UDim2.new(1,0,1,0)
    rContent.BackgroundTransparency = 1; rContent.Parent = redeemBtn
    local rLayout = Instance.new("UIListLayout",rContent)
    rLayout.FillDirection = Enum.FillDirection.Horizontal
    rLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    rLayout.VerticalAlignment = Enum.VerticalAlignment.Center; rLayout.Padding = UDim.new(0,8)
    local rIco = Instance.new("ImageLabel"); rIco.Size = UDim2.new(0,18,0,18)
    rIco.BackgroundTransparency = 1; rIco.Image = getIcon("shield")
    rIco.ImageColor3 = Color3.new(1,1,1); rIco.ScaleType = Enum.ScaleType.Fit
    rIco.LayoutOrder = 1; rIco.Parent = rContent
    local rLab = Instance.new("TextLabel"); rLab.Name = "ButtonText"
    rLab.Size = UDim2.new(0,0,0,18); rLab.AutomaticSize = Enum.AutomaticSize.X
    rLab.BackgroundTransparency = 1; rLab.Text = "Redeem Key"
    rLab.TextColor3 = Color3.new(1,1,1); rLab.TextSize = 14
    rLab.Font = Enum.Font.GothamBold; rLab.LayoutOrder = 2; rLab.Parent = rContent
    redeemBtn.MouseEnter:Connect(function()
        TweenService:Create(redeemBtn,TweenInfo.new(0.15),{BackgroundColor3=T.SuccessHover}):Play()
        TweenService:Create(rGlow,TweenInfo.new(0.15),{Thickness=1.5,Transparency=0.25}):Play()
    end)
    redeemBtn.MouseLeave:Connect(function()
        TweenService:Create(redeemBtn,TweenInfo.new(0.15),{BackgroundColor3=T.Success}):Play()
        TweenService:Create(rGlow,TweenInfo.new(0.15),{Thickness=0,Transparency=0.8}):Play()
    end)

    -- Footer icon row
    local footY = redeemY + 42 + 10
    local footDiv = Instance.new("Frame"); footDiv.Size = UDim2.new(1,0,0,1)
    footDiv.Position = UDim2.new(0,0,0,footY); footDiv.BackgroundColor3 = T.Border
    footDiv.BackgroundTransparency = 0.45; footDiv.BorderSizePixel = 0; footDiv.Parent = content

    local footRow = Instance.new("Frame"); footRow.Size = UDim2.new(1,0,0,30)
    footRow.Position = UDim2.new(0,0,0,footY+8); footRow.BackgroundTransparency = 1
    footRow.Parent = content
    local footLayout = Instance.new("UIListLayout",footRow)
    footLayout.FillDirection = Enum.FillDirection.Horizontal
    footLayout.VerticalAlignment = Enum.VerticalAlignment.Center; footLayout.Padding = UDim.new(0,8)


    -- Shop banner (bottom)
    if hasShop then
        local shopDiv = Instance.new("Frame"); shopDiv.Size = UDim2.new(1,0,0,1)
        shopDiv.Position = UDim2.new(0,0,1,-shopH); shopDiv.BackgroundColor3 = T.Accent
        shopDiv.BackgroundTransparency = 0.65; shopDiv.BorderSizePixel = 0; shopDiv.Parent = main

        local shopF = Instance.new("Frame"); shopF.Size = UDim2.new(1,0,0,shopH-1)
        shopF.Position = UDim2.new(0,0,1,-shopH+1); shopF.BackgroundColor3 = T.Header
        shopF.BorderSizePixel = 0; shopF.Parent = main
        local shopFix = Instance.new("Frame"); shopFix.Size = UDim2.new(1,0,0,4)
        shopFix.Position = UDim2.new(0,0,1,-4); shopFix.BackgroundColor3 = T.Header
        shopFix.BorderSizePixel = 0; shopFix.Parent = main

        local shopIcoSz = 28
        local shopIcoW = Instance.new("Frame")
        shopIcoW.Size = UDim2.new(0,shopIcoSz+4,0,shopIcoSz+4)
        shopIcoW.Position = UDim2.new(0,12,0.5,0); shopIcoW.AnchorPoint = Vector2.new(0,0.5)
        shopIcoW.BackgroundColor3 = T.Secondary; shopIcoW.BackgroundTransparency = 0.7
        shopIcoW.BorderSizePixel = 0; shopIcoW.Parent = shopF; corner(shopIcoW, 6)
        stroke(shopIcoW, T.Secondary, 1, 0.5)
        local shopIco = Instance.new("ImageLabel")
        shopIco.Size = UDim2.new(0,shopIcoSz,0,shopIcoSz)
        shopIco.Position = UDim2.new(0.5,0,0.5,0); shopIco.AnchorPoint = Vector2.new(0.5,0.5)
        shopIco.BackgroundTransparency = 1
        shopIco.Image = (SorinUI.Shop.Icon ~= "") and SorinUI.Shop.Icon or getIcon("cart")
        shopIco.ImageColor3 = T.Text; shopIco.ScaleType = Enum.ScaleType.Fit; shopIco.Parent = shopIcoW

        local buyBtnW = 100  -- reserve layout space; button auto-grows to fit text
        local txOff = 12 + shopIcoSz + 4 + 8
        local txW = winW - txOff - buyBtnW - 12 - 8
        lbl({Size=UDim2.new(0,txW,0,18), Position=UDim2.new(0,txOff,0,6),
             Text=SorinUI.Shop.Title, TextColor3=T.Text, TextSize=13, Font=Enum.Font.GothamBold,
             TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, shopF)
        lbl({Size=UDim2.new(0,txW,0,13), Position=UDim2.new(0,txOff,0,26),
             Text=SorinUI.Shop.Subtitle, TextColor3=T.TextDim, TextSize=10, Font=Enum.Font.Gotham,
             TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, shopF)

        local buyBtn = Instance.new("TextButton")
        buyBtn.Size = UDim2.new(0,0,0,30); buyBtn.AutomaticSize = Enum.AutomaticSize.X
        buyBtn.AnchorPoint = Vector2.new(1,0.5)
        buyBtn.Position = UDim2.new(1,-12,0.5,0); buyBtn.BackgroundColor3 = T.Secondary
        buyBtn.BorderSizePixel = 0; buyBtn.Text = SorinUI.Shop.ButtonText
        buyBtn.TextColor3 = Color3.new(1,1,1); buyBtn.TextSize = 12
        buyBtn.Font = Enum.Font.GothamBold; buyBtn.AutoButtonColor = false
        buyBtn.Parent = shopF; corner(buyBtn, 7)
        local buyPad = Instance.new("UIPadding", buyBtn)
        buyPad.PaddingLeft = UDim.new(0,14); buyPad.PaddingRight = UDim.new(0,14)
        grad(buyBtn, {T.Secondary, Color3.fromRGB(106,63,224)}, 90)
        buyBtn.MouseEnter:Connect(function() TweenService:Create(buyBtn,TweenInfo.new(0.15),{BackgroundColor3=T.SecondaryL}):Play() end)
        buyBtn.MouseLeave:Connect(function() TweenService:Create(buyBtn,TweenInfo.new(0.15),{BackgroundColor3=T.Secondary}):Play() end)
        buyBtn.MouseButton1Click:Connect(function()
            if SorinUI.Shop.Link ~= "" then
                pcall(function() setclipboard(SorinUI.Shop.Link) end)
                SorinUI:Notify("Shop","Shop link copied!",2,"copy")
            end
        end)
    end

    -- Particles
    startParticles(main)

    -- Door overlay
    local doors = createDoors(main, winW, winH)

    -- ── STATUS & SPINNER LOGIC ───────────────────────
    local spinConn, dotsThread
    local function setStatus(state, customText)
        if spinConn   then spinConn:Disconnect(); spinConn = nil; statusIco.Rotation = 0 end
        if dotsThread then task.cancel(dotsThread); dotsThread = nil end

        local color, icon, mainText, subText =
            T.StatusIdle, getIcon("lock"),
            SorinUI.Appearance.Title, SorinUI.Appearance.Subtitle

        if state == "verifying" then
            color = T.Accent; icon = getIcon("loading")
            mainText = "Verifying key"; subText = ""
            spinConn = RunService.Heartbeat:Connect(function(dt)
                if statusIco and statusIco.Parent then
                    statusIco.Rotation = (statusIco.Rotation + dt*360) % 360
                else if spinConn then spinConn:Disconnect() end end
            end)
            local dots, di = {".", "..", "...", ""}, 1
            dotsThread = task.spawn(function()
                while statusSub and statusSub.Parent and statusSub.Text:find("Verifying",1,true) do
                    statusSub.Text = mainText..dots[di]; di = (di % #dots)+1; task.wait(0.4)
                end
            end)
        elseif state == "success" then
            color = T.Success; icon = getIcon("check")
            mainText = customText or "Access Granted"; subText = "Key validated successfully"
        elseif state == "error" then
            color = T.Error; icon = getIcon("alert")
            mainText = customText or "Invalid Key"; subText = "Please try again"
        end

        TweenService:Create(statusIco,TweenInfo.new(0.25),{ImageColor3=color}):Play()
        TweenService:Create(statusSub,TweenInfo.new(0.25),{TextColor3=color}):Play()
        TweenService:Create(statusStroke,TweenInfo.new(0.25),{Color=color,Transparency=0.55}):Play()
        statusIco.Image = icon
        if state ~= "verifying" then
            statusTitle.Text = mainText; statusSub.Text = subText
        end
    end

    -- ── VERIFY / REDEEM LOGIC ────────────────────────
    local function shakeInput()
        local o = inputFrame.Position
        for _ = 1,3 do
            TweenService:Create(inputFrame,TweenInfo.new(0.05),
                {Position=UDim2.new(o.X.Scale,o.X.Offset-8,o.Y.Scale,o.Y.Offset)}):Play(); task.wait(0.05)
            TweenService:Create(inputFrame,TweenInfo.new(0.05),
                {Position=UDim2.new(o.X.Scale,o.X.Offset+8,o.Y.Scale,o.Y.Offset)}):Play(); task.wait(0.05)
        end
        inputFrame.Position = o
    end

    local function closeDoorsThenExit(cb)
        ui.closeAllPanels(userIco, clIco, function()
            doors.close(function() task.wait(0.3); if cb then cb() end end)
        end)
    end

    local function handleRedeem()
        local key = keyInput.Text:gsub("%s+","")
        if key == "" then
            SorinUI:Notify("Error","Please enter your key",3,"warning"); shakeInput(); return
        end
        setStatus("verifying"); redeemBtn.Active = false; task.wait(0.3)

        local valid, errorMsg = false, "Invalid key"
        if Internal.ValidateFunction then
            local ok, result, msg = pcall(Internal.ValidateFunction, key)
            if ok then
                if type(result) == "table" then
                    valid = result.valid == true
                    -- LuaAuth-style status codes
                    if result.status == "key_valid" then valid = true
                    elseif result.status then
                        local map = {
                            invalid_key         = "Key not found – check spelling",
                            key_expired         = "Key has expired",
                            key_blacklisted     = "Key is blacklisted",
                            invalid_fingerprint = "HWID mismatch – reset via Discord",
                            invalid_script_id   = "Config error – contact developers",
                        }
                        errorMsg = map[result.status] or result.status
                    end
                    -- Junkie-style error codes
                    if not valid and result.error then
                        local eMap = {
                            KEY_INVALID     = "Key not found in system",
                            KEY_EXPIRED     = "Key has expired",
                            HWID_BANNED     = "Hardware banned",
                            KEY_INVALIDATED = "Key was revoked",
                            ALREADY_USED    = "One-time key already used",
                            HWID_MISMATCH   = "HWID limit reached",
                        }
                        errorMsg = eMap[result.error] or result.message or result.error
                        if result.error == "HWID_BANNED" then
                            task.delay(2, function() pcall(function() game.Players.LocalPlayer:Kick("Hardware banned") end) end)
                        end
                    end
                elseif type(result) == "boolean" then
                    valid = result; errorMsg = msg or "Invalid key"
                end
            end
        end

        redeemBtn.Active = true

        if valid then
            saveKey(key); getgenv().SORIN_KEY = key
            if Internal.IsJunkieMode then getgenv().SCRIPT_KEY = key end
            setStatus("success")
            SorinUI:Notify("Success","Key validated successfully!",3,"success")

            if SorinUI.Options.WelcomeEnabled then
                task.wait(0.8)
            end

            task.wait(0.5)
            closeDoorsThenExit(function()
                disableBlur()
                TweenService:Create(container,TweenInfo.new(0.4,Enum.EasingStyle.Quart),
                    {Position=UDim2.new(0.5,0,-0.5,0)}):Play()
                TweenService:Create(main,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
                task.wait(0.4); screenGui:Destroy()
                if SorinUI.Callbacks.OnSuccess then SorinUI.Callbacks.OnSuccess() end
            end)
        else
            setStatus("error", errorMsg)
            SorinUI:Notify("Invalid", errorMsg, 4, "error")
            shakeInput()
            if SorinUI.Callbacks.OnFail then SorinUI.Callbacks.OnFail(errorMsg) end
        end
    end

    redeemBtn.MouseButton1Click:Connect(handleRedeem)
    keyInput.FocusLost:Connect(function(enter) if enter then handleRedeem() end end)

    -- Close button
    closeBtn.MouseButton1Click:Connect(function()
        -- set KEYLESS immediately so Junkie's wait loop exits before fullCleanup destroys the GUI
        if Internal.IsJunkieMode then getgenv().SCRIPT_KEY = "KEYLESS" end
        SorinUI:Notify("Goodbye","See you next time!",2,"close")
        closeDoorsThenExit(function()
            fullCleanup()
            TweenService:Create(container,TweenInfo.new(0.4,Enum.EasingStyle.Quart),
                {Position=UDim2.new(0.5,0,-0.5,0)}):Play()
            TweenService:Create(main,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
            task.wait(0.4); screenGui:Destroy()
            if SorinUI.Callbacks.OnClose then SorinUI.Callbacks.OnClose() end
        end)
    end)

    if discordBtn then
        discordBtn.MouseButton1Click:Connect(function()
            local ok, mode = openDiscordInvite(SorinUI.Links.Discord)
            if ok then
                SorinUI:Notify("Discord","Invite opened in Discord!",2,"discord")
            elseif mode == "clipboard" then
                SorinUI:Notify("Discord","Invite link copied!",2,"discord")
            else
                SorinUI:Notify("Discord","Could not open invite",2,"alert")
            end
        end)
    end
    if clBtn   then clBtn.MouseButton1Click:Connect(function()   ui.toggleCL(clIco)     end) end
    if userBtn then userBtn.MouseButton1Click:Connect(function() ui.toggleUser(userIco)  end) end

    setupDragging(topBar, container)

    -- Entrance animation
    TweenService:Create(container,TweenInfo.new(0.5,Enum.EasingStyle.Quart),
        {Position=UDim2.new(0.5,0,0.45,0)}):Play()
    task.wait(0.55)
    doors.open(function()
        if hasUser  then task.wait(0.2); ui.toggleUser(userIco) end
        if hasCL    then task.wait(0.3); ui.toggleCL(clIco)     end
    end)
end

-- ════════════════════════════════════════════════
--  LAUNCH
-- ════════════════════════════════════════════════

function SorinUI:Launch()
    Internal.IsJunkieMode = false
    Internal.ValidateFunction = SorinUI.Callbacks.OnVerify

    local existing = getgenv().SORIN_KEY
    if existing and existing ~= "" then
        if Internal.ValidateFunction and validateKey(existing, Internal.ValidateFunction) then
            SorinUI:Notify("Welcome Back","Key validated!",2,"success")
            if SorinUI.Callbacks.OnSuccess then SorinUI.Callbacks.OnSuccess() end
            return
        end
        getgenv().SORIN_KEY = nil
    end

    enableBlur()

    if not SorinUI.Options.LoadingEnabled then
        Internal.IconsLoaded = false
    end

    ensureIconsReady(function()
        if SorinUI.Storage.AutoLoad and Internal.ValidateFunction then
            local saved = loadKey()
            if saved and saved ~= "" then
                SorinUI:Notify("Checking","Validating saved key...",2,"shield"); task.wait(0.5)
                if validateKey(saved, Internal.ValidateFunction) then
                    getgenv().SORIN_KEY = saved
                    if Internal.IsJunkieMode then getgenv().SCRIPT_KEY = saved end
                    SorinUI:Notify("Welcome Back","Key validated!",2,"success")
                    disableBlur()
                    if SorinUI.Callbacks.OnSuccess then SorinUI.Callbacks.OnSuccess() end
                    return
                else
                    clearKey()
                    SorinUI:Notify("Expired","Saved key is no longer valid",3,"warning")
                    task.wait(1)
                end
            end
        end
        buildKeyUI()
        while not getgenv().SORIN_KEY and CoreGui:FindFirstChild("SorinKeyUI") do
            task.wait(0.1)
        end
    end)
end

-- ════════════════════════════════════════════════
--  LAUNCH JUNKIE  (Junkie key system integration)
-- ════════════════════════════════════════════════

function SorinUI:LaunchJunkie(config)
    assert(config and config.Service and config.Identifier and config.Provider,
        "LaunchJunkie requires: Service, Identifier, Provider")
    Internal.IsJunkieMode = true

    local existing = getgenv().SORIN_KEY
    if existing and existing ~= "" then
        SorinUI:Notify("Executed","Script loaded successfully!",2,"success")
        if SorinUI.Callbacks.OnSuccess then SorinUI.Callbacks.OnSuccess() end; return
    end

    enableBlur()

    ensureIconsReady(function()
        local ok, Junkie = pcall(function()
            return loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
        end)
        if not ok or not Junkie then
            SorinUI:Notify("Error","Failed to load Junkie SDK",5,"error"); return
        end
        Junkie.service    = config.Service
        Junkie.identifier = config.Identifier
        Junkie.provider   = config.Provider

        if SorinUI.Links.GetKey == "" then
            pcall(function() SorinUI.Links.GetKey = Junkie.get_key_link() end)
        end
        Internal.ValidateFunction = function(key) return Junkie.check_key(key) end

        if SorinUI.Storage.AutoLoad then
            local saved = loadKey()
            if saved and saved ~= "" then
                SorinUI:Notify("Checking","Validating saved key...",2,"shield"); task.wait(0.5)
                local vs, vr = pcall(function() return Junkie.check_key(saved) end)
                if vs and vr and vr.valid then
                    getgenv().SORIN_KEY = saved; getgenv().SCRIPT_KEY = saved
                    SorinUI:Notify("Welcome Back","Key validated!",2,"success")
                    disableBlur()
                    if SorinUI.Callbacks.OnSuccess then SorinUI.Callbacks.OnSuccess() end; return
                else clearKey(); SorinUI:Notify("Expired","Saved key is no longer valid",3,"warning"); task.wait(1) end
            end
        end

        buildKeyUI()
        while not getgenv().SCRIPT_KEY and CoreGui:FindFirstChild("SorinKeyUI") do
            task.wait(0.1)
        end
    end)
end

-- ════════════════════════════════════════════════
--  CONVENIENCE METHODS
-- ════════════════════════════════════════════════

function SorinUI:GetSavedKey() return loadKey() end
function SorinUI:ClearSavedKey() clearKey() end

-- ════════════════════════════════════════════════
--  BACKWARD COMPAT  (.new(cfg):run())
-- ════════════════════════════════════════════════

function SorinUI.new(cfg)
    -- Map old flat-config to new table-based config
    SorinUI.Appearance.Title    = cfg.Title    or "Key System"
    SorinUI.Appearance.Icon     = cfg.LogoImage or ""
    SorinUI.Appearance.Version  = cfg.Version  or ""
    SorinUI.Appearance.Subtitle = cfg.Subtitle or "Enter your key to continue"

    SorinUI.Links.Discord = cfg.DiscordLink or ""
    SorinUI.Links.Shop    = cfg.ShopLink    or ""

    SorinUI.Options.LoadingEnabled  = cfg.LoadingEnabled  ~= false
    SorinUI.Options.UserInfoEnabled = cfg.UserInfoEnabled ~= false
    SorinUI.Options.WelcomeEnabled  = cfg.WelcomeEnabled  ~= false

    SorinUI.Providers = cfg.Providers or {}
    SorinUI.Changelog = cfg.Changelog or {}

    if cfg.ShopBanner then
        SorinUI.Shop.Enabled    = cfg.ShopBanner.Enabled  == true
        SorinUI.Shop.Title      = cfg.ShopBanner.Title    or ""
        SorinUI.Shop.Subtitle   = cfg.ShopBanner.Sub      or ""
        SorinUI.Shop.Link       = cfg.ShopBanner.Link     or ""
        SorinUI.Shop.ButtonText = cfg.ShopBanner.BuyText  or "Buy Now"
        SorinUI.Shop.Icon       = cfg.ShopBanner.Image    or ""
    end

    SorinUI.Callbacks.OnVerify = cfg.CheckKey

    return {
        run = function(_self)
            getgenv().SORIN_KEY    = nil
            getgenv().SORIN_CLOSED = false

            SorinUI.Callbacks.OnSuccess = function()
                getgenv().SORIN_CLOSED = true
            end
            SorinUI.Callbacks.OnClose = function()
                getgenv().SORIN_KEY    = nil
                getgenv().SORIN_CLOSED = true
            end

            SorinUI:Launch()

            while not getgenv().SORIN_CLOSED do task.wait(0.1) end

            if cfg.LoadScript then
                cfg.LoadScript(getgenv().SORIN_KEY)
            end
        end
    }
end

-- ════════════════════════════════════════════════

getgenv().SorinUI = SorinUI
return SorinUI
