-- ============================================
-- PATRIOT KEY SYSTEM (INTEGRADO)
-- ============================================
repeat task.wait() until game:IsLoaded()

local cloneref = cloneref or function(obj) return obj end
local gethui = gethui or function() return cloneref(game:GetService("CoreGui")) end

local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local Lighting = cloneref(game:GetService("Lighting"))
local Players = cloneref(game:GetService("Players"))

local hui = gethui()

if getgenv().PatriotLoaded and hui:FindFirstChild("PatriotKeySystem") then return getgenv().Patriot end
if getgenv().PatriotLoaded and hui:FindFirstChild("PatriotKeylessSystem") then return getgenv().Patriot end
getgenv().PatriotLoaded = true
getgenv().PatriotClosed = false

local Patriot = {}

Patriot.Appearance = {
    Title = "Water Hub",
    Subtitle = "Enter your key to continue",
    Icon = "rbxassetid://95721401302279",
    IconSize = UDim2.new(0, 30, 0, 30)
}

Patriot.Links = {
    GetKey = "https://jnkie.com/get-key/waterhubkey",
    Discord = ""
}

Patriot.Storage = {
    FileName = "WaterHub_Key",
    Remember = true,
    AutoLoad = true
}

Patriot.Options = {
    Keyless = false,
    KeylessUI = false,
    Blur = true,
    Draggable = true
}

Patriot.Theme = {
    Accent = Color3.fromRGB(139, 0, 0),
    AccentHover = Color3.fromRGB(170, 20, 20),
    Background = Color3.fromRGB(15, 15, 15),
    Header = Color3.fromRGB(20, 20, 20),
    Input = Color3.fromRGB(25, 25, 25),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(120, 120, 120),
    Success = Color3.fromRGB(50, 205, 110),
    Error = Color3.fromRGB(245, 70, 90),
    Warning = Color3.fromRGB(255, 180, 50),
    StatusIdle = Color3.fromRGB(180, 80, 80),
    Discord = Color3.fromRGB(88, 101, 242),
    DiscordHover = Color3.fromRGB(114, 137, 218),
    Divider = Color3.fromRGB(45, 45, 70),
    Pending = Color3.fromRGB(60, 60, 60)
}

Patriot.Callbacks = {
    OnVerify = nil,
    OnSuccess = nil,
    OnFail = nil,
    OnClose = nil
}

Patriot.Changelog = {}
Patriot.Shop = {Enabled = false}

-- ============================================
-- FUNCIONES INTERNAS DEL KEY SYSTEM (COMPACTADAS)
-- ============================================
local Internal = {Junkie = nil, BlurEffect = nil, NotificationList = {}, ValidateFunction = nil, IsJunkieMode = false, IconsLoaded = false}

local IconBaseURL = "https://raw.githubusercontent.com/SyndromeXph/expert-octo-doodle/main/Icons/"
local IconFiles = {key = "lucide--key.png", shield = "lucide--shield-minus.png", check = "prime--check-square.png", copy = "flowbite--clipboard-outline.png", discord = "qlementine-icons--discord-16.png", alert = "mdi--alert-octagon-outline.png", lock = "lucide--user-lock.png", loading = "nonicons--loading-16.png", close = "material-symbols--dangerous-outline.png", changelog = "ant-design--sync-outlined.png", logo = "Patriot.png", user = "U.png", clock = "Clock.png", cart = "Cart.png"}
local FallbackIcons = {key = "rbxassetid://96510194465420", shield = "rbxassetid://89965059528921", check = "rbxassetid://76078495178149", copy = "rbxassetid://125851897718493", discord = "rbxassetid://83278450537116", alert = "rbxassetid://140438367956051", lock = "rbxassetid://114355063515473", loading = "rbxassetid://116535712789945", close = "rbxassetid://6022668916", changelog = "rbxassetid://138133190015277", logo = "rbxassetid://95721401302279", user = "rbxassetid://77400125196692", clock = "rbxassetid://87505349362628", cart = "rbxassetid://114754518183872"}
local CachedIcons = {}
local FolderName = "WaterHub"
local IconsFolder = "Icons"
local DefaultLogoAsset = "rbxassetid://95721401302279"

local function isMobile() return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled end
local function getScale() local vp = Workspace.CurrentCamera.ViewportSize return math.clamp(math.min(vp.X, vp.Y) / 900, 0.65, 1.3) end
local function hasFileSystem() local ok = pcall(function() return type(writefile) == "function" end) return ok and pcall(function() return type(readfile) == "function" end) and pcall(function() return type(isfile) == "function" end) and pcall(function() return type(makefolder) == "function" end) and pcall(function() return type(isfolder) == "function" end) end
local fileSystemSupported = hasFileSystem()
local function getFileName() return FolderName .. "/" .. Patriot.Storage.FileName .. ".txt" end
local function saveKey(key) if not fileSystemSupported or not Patriot.Storage.Remember then return false end return pcall(function() writefile(getFileName(), key) end) end
local function loadKey() if not fileSystemSupported then return nil end local ok, c = pcall(function() if isfile(getFileName()) then return readfile(getFileName()) end return nil end) if ok and c and c ~= "" then return c end return nil end
local function clearKey() if not fileSystemSupported then return false end return pcall(function() delfile(getFileName()) end) end
local function ensureFolders() if not fileSystemSupported then return false end pcall(function() if not isfolder(FolderName) then makefolder(FolderName) end if not isfolder(FolderName .. "/" .. IconsFolder) then makefolder(FolderName .. "/" .. IconsFolder) end end) return true end
local function getIconPath(iconName) return FolderName .. "/" .. IconsFolder .. "/" .. IconFiles[iconName] end
local function isIconCached(iconName) if not fileSystemSupported then return false end local s,r = pcall(function() return isfile(getIconPath(iconName)) end) return s and r end
local function downloadIcon(iconName) if not fileSystemSupported then CachedIcons[iconName] = FallbackIcons[iconName] return false end local path = getIconPath(iconName) if isIconCached(iconName) then local s = pcall(function() CachedIcons[iconName] = getcustomasset(path) end) if s then return true end end local s = pcall(function() local r = game:HttpGet(IconBaseURL .. IconFiles[iconName]) if #r < 100 then error("Invalid") end writefile(path, r) CachedIcons[iconName] = getcustomasset(path) end) if not s then CachedIcons[iconName] = FallbackIcons[iconName] end return s end
local function getIcon(iconName) return CachedIcons[iconName] or FallbackIcons[iconName] end
local function getLogoIcon() if Patriot.Appearance.Icon == DefaultLogoAsset then return getIcon("logo") end return Patriot.Appearance.Icon end
local function shouldDownloadLogo() return Patriot.Appearance.Icon == DefaultLogoAsset end
local function getShopIcon() if Patriot.Shop.Icon == "" then return getLogoIcon() end return Patriot.Shop.Icon end
local function isShopEnabled() return Patriot.Shop.Enabled end
local function allIconsCached() if not fileSystemSupported then return false end local icons = {"key", "shield", "check", "copy", "discord", "alert", "lock", "loading", "close", "changelog", "user", "clock", "cart"} if shouldDownloadLogo() then table.insert(icons, "logo") end for _, n in ipairs(icons) do if not isIconCached(n) then return false end end return true end
local function loadAllIconsFromCache() ensureFolders() local icons = {"key", "shield", "check", "copy", "discord", "alert", "lock", "loading", "close", "changelog", "user", "clock", "cart"} if shouldDownloadLogo() then table.insert(icons, "logo") end for _, n in ipairs(icons) do downloadIcon(n) end Internal.IconsLoaded = true end
local function getExecutorName() local s,n = pcall(identifyexecutor) if s and n then return tostring(n) end return "Unknown" end
local function getDeviceType() local t = UserInputService.TouchEnabled local k = UserInputService.KeyboardEnabled local g = UserInputService.GamepadEnabled if g and not k and not t then return "Console" elseif t and not k then return "Mobile" elseif k and t then return "PC & Touch" elseif k then return "PC" else return "Unknown" end end
local function getHWID() local hwid = nil pcall(function() if gethwid then hwid = gethwid() end end) if not hwid then pcall(function() if getgenv().HWID then hwid = getgenv().HWID end end) end if not hwid then pcall(function() if game.RobloxHWID then hwid = tostring(game.RobloxHWID) end end) end if not hwid then local p = cloneref(Players.LocalPlayer) hwid = HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 32) if p then hwid = tostring(p.UserId) .. hwid:sub(1, 20) end end return hwid or "N/A" end
local function generateHiddenDots(aw, cw) cw = cw or 5 local c = math.floor(aw / cw) c = math.max(c, 8) return string.rep("•", c) end
local function formatTime12() local h = tonumber(os.date("%H")) local m = os.date("%M") local s = os.date("%S") local p = "AM" if h >= 12 then p = "PM" end if h > 12 then h = h - 12 end if h == 0 then h = 12 end return string.format("%d:%s:%s %s", h, m, s, p) end
local function formatDate() return os.date("%b %d, %Y") end
local function enableBlur() if not Patriot.Options.Blur then return end local e = Lighting:FindFirstChild("PatriotKeySystemBlur") if e then e:Destroy() end Internal.BlurEffect = Instance.new("BlurEffect") Internal.BlurEffect.Name = "PatriotKeySystemBlur" Internal.BlurEffect.Size = 0 Internal.BlurEffect.Parent = Lighting TweenService:Create(Internal.BlurEffect, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Size = 24}):Play() end
local function disableBlur() if Internal.BlurEffect and Internal.BlurEffect.Parent then TweenService:Create(Internal.BlurEffect, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = 0}):Play() task.delay(0.3, function() if Internal.BlurEffect and Internal.BlurEffect.Parent then Internal.BlurEffect:Destroy() Internal.BlurEffect = nil end end) else local e = Lighting:FindFirstChild("PatriotKeySystemBlur") if e then e:Destroy() end Internal.BlurEffect = nil end end
local function fullCleanup() getgenv().PatriotLoaded = false getgenv().PatriotClosed = true disableBlur() local g1 = hui:FindFirstChild("PatriotKeySystem") local g2 = hui:FindFirstChild("PatriotKeylessSystem") local g3 = hui:FindFirstChild("PatriotLoadingScreen") if g1 then g1:Destroy() end if g2 then g2:Destroy() end if g3 then g3:Destroy() end end
local function validateKey(key, validateFunc) if not validateFunc or not key or key == "" then return false end local s,r = pcall(validateFunc, key) if not s then return false end if type(r) == "table" then return r.valid == true end if type(r) == "boolean" then return r end return false end

-- Funciones UI (compactadas pero funcionales)
local function setupDragging(header, main) if not Patriot.Options.Draggable then return end local dragging, dragStart, startPos, dragInput header.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true dragStart = i.Position startPos = main.Position dragInput = i i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then if dragInput == i then dragging = false dragInput = nil end end end) end end) UserInputService.InputChanged:Connect(function(i) if not dragging or not dragInput then return end if i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dragStart main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) elseif i.UserInputType == Enum.UserInputType.Touch then if i == dragInput then local delta = i.Position - dragStart main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end end) end

local function ShowLoadingScreen(onComplete) local c = false local old = hui:FindFirstChild("PatriotLoadingScreen") if old then old:Destroy() end local oldBlur = Lighting:FindFirstChild("PatriotLoadingBlur") if oldBlur then oldBlur:Destroy() end local blur = Instance.new("BlurEffect") blur.Name = "PatriotLoadingBlur" blur.Size = 0 blur.Parent = Lighting local gui = Instance.new("ScreenGui") gui.Name = "PatriotLoadingScreen" gui.ResetOnSpawn = false gui.IgnoreGuiInset = true gui.Parent = hui local mobile = isMobile() local ls = Instance.new("Frame") ls.Size = UDim2.new(1,0,1,0) ls.BackgroundColor3 = Color3.fromRGB(0,0,0) ls.BackgroundTransparency = 1 ls.Parent = gui local lc = Instance.new("Frame") lc.Size = UDim2.new(1,0,1,0) lc.BackgroundTransparency = 1 lc.Parent = ls local lines = {} local linePos = {0.15,0.35,0.65,0.85} for i=1,4 do local line = Instance.new("Frame") line.Size = UDim2.new(0.3,0,0,mobile and 2 or 3) line.Position = UDim2.new(1.3,0,linePos[i],0) line.BackgroundColor3 = Patriot.Theme.Text line.BackgroundTransparency = 1 line.Parent = lc Instance.new("UICorner",line).CornerRadius = UDim.new(1,0) lines[i]=line end local shipSize = mobile and 18 or 28 local shipC = Instance.new("Frame") shipC.Size = UDim2.new(0,mobile and 100 or 150,0,mobile and 30 or 50) shipC.Position = UDim2.new(0.5,0,0.35,0) shipC.AnchorPoint = Vector2.new(0.5,0.5) shipC.BackgroundTransparency = 1 shipC.Parent = ls local shipB = Instance.new("Frame") shipB.Size = UDim2.new(0,shipSize,0,shipSize) shipB.Position = UDim2.new(0.5,10,0.5,0) shipB.AnchorPoint = Vector2.new(0.5,0.5) shipB.BackgroundColor3 = Patriot.Theme.Text shipB.BackgroundTransparency = 1 shipB.Parent = shipC Instance.new("UICorner",shipB).CornerRadius = UDim.new(1,0) local pointS = mobile and 10 or 16 local shipP = Instance.new("Frame") shipP.Size = UDim2.new(0,pointS,0,pointS) shipP.Position = UDim2.new(1,2,0.5,0) shipP.AnchorPoint = Vector2.new(0,0.5) shipP.BackgroundColor3 = Patriot.Theme.Text shipP.BackgroundTransparency = 1 shipP.Rotation = 45 shipP.Parent = shipB Instance.new("UICorner",shipP).CornerRadius = UDim.new(0,3) local trails = {} local trailC = {{y=0.20,w=mobile and 45 or 70},{y=0.38,w=mobile and 60 or 95},{y=0.62,w=mobile and 55 or 85},{y=0.80,w=mobile and 40 or 65}} for i,cfg in ipairs(trailC) do local t = Instance.new("Frame") t.Size = UDim2.new(0,cfg.w,0,mobile and 2 or 3) t.Position = UDim2.new(0.5,-15,cfg.y,0) t.AnchorPoint = Vector2.new(1,0.5) t.BackgroundColor3 = Patriot.Theme.Text t.BackgroundTransparency = 1 t.Parent = shipC local grad = Instance.new("UIGradient",t) grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.3,0.5),NumberSequenceKeypoint.new(1,0)}) Instance.new("UICorner",t).CornerRadius = UDim.new(1,0) trails[i] = {frame=t, config=cfg} end local phC = Instance.new("Frame") phC.Size = UDim2.new(0,mobile and 200 or 280,0,mobile and 150 or 180) phC.Position = UDim2.new(0.5,0,0.62,0) phC.AnchorPoint = Vector2.new(0.5,0.5) phC.BackgroundTransparency = 1 phC.Parent = ls local phL = Instance.new("UIListLayout",phC) phL.Padding = UDim.new(0,mobile and 8 or 12) phL.SortOrder = Enum.SortOrder.LayoutOrder phL.HorizontalAlignment = Enum.HorizontalAlignment.Center phL.VerticalAlignment = Enum.VerticalAlignment.Center local phases = {} local phaseNames = {"Initializing","Creating folders","Downloading assets","Preparing interface","Ready"} local pts = mobile and 14 or 18 for i,name in ipairs(phaseNames) do local row = Instance.new("Frame") row.Size = UDim2.new(1,0,0,mobile and 22 or 28) row.BackgroundTransparency = 1 row.LayoutOrder = i row.Parent = phC local ind = Instance.new("TextLabel") ind.Size = UDim2.new(0,mobile and 22 or 28,0,mobile and 22 or 28) ind.BackgroundTransparency = 1 ind.Text = "○" ind.TextColor3 = Patriot.Theme.Pending ind.TextSize = pts ind.Font = Enum.Font.ArimoBold ind.TextTransparency = 1 ind.Parent = row local lab = Instance.new("TextLabel") lab.Size = UDim2.new(1,mobile and -28 or -35,1,0) lab.Position = UDim2.new(0,mobile and 28 or 35,0,0) lab.BackgroundTransparency = 1 lab.Text = name lab.TextColor3 = Patriot.Theme.Pending lab.TextSize = pts lab.Font = Enum.Font.ArimoBold lab.TextXAlignment = Enum.TextXAlignment.Left lab.TextTransparency = 1 lab.Parent = row phases[i] = {indicator=ind, label=lab} end local animRun = true local curPhase = 0 local pulse = nil local function setPhase(num) if pulse then task.cancel(pulse) pulse=nil end for i=1,5 do local p = phases[i] if i<num then p.indicator.Text = "●" TweenService:Create(p.indicator,TweenInfo.new(0.2),{TextColor3=Patriot.Theme.Success,TextTransparency=0}):Play() TweenService:Create(p.label,TweenInfo.new(0.2),{TextColor3=Patriot.Theme.Success}):Play() elseif i==num then p.indicator.Text = "●" p.indicator.TextTransparency = 0 TweenService:Create(p.indicator,TweenInfo.new(0.2),{TextColor3=Patriot.Theme.Accent}):Play() TweenService:Create(p.label,TweenInfo.new(0.2),{TextColor3=Patriot.Theme.Text}):Play() curPhase = num pulse = task.spawn(function() while curPhase == num do TweenService:Create(p.indicator,TweenInfo.new(0.4),{TextTransparency=0.5}):Play() task.wait(0.4) if curPhase~=num then break end TweenService:Create(p.indicator,TweenInfo.new(0.4),{TextTransparency=0}):Play() task.wait(0.4) end end) else p.indicator.Text = "○" p.indicator.TextColor3 = Patriot.Theme.Pending p.label.TextColor3 = Patriot.Theme.Pending end end end task.spawn(function() TweenService:Create(blur,TweenInfo.new(0.6),{Size=24}):Play() TweenService:Create(ls,TweenInfo.new(0.5),{BackgroundTransparency=0.25}):Play() task.wait(0.3) TweenService:Create(shipB,TweenInfo.new(0.4,Enum.EasingStyle.Back),{BackgroundTransparency=0}):Play() TweenService:Create(shipP,TweenInfo.new(0.4,Enum.EasingStyle.Back),{BackgroundTransparency=0}):Play() task.wait(0.2) for i=1,5 do task.delay((i-1)*0.08,function() TweenService:Create(phases[i].indicator,TweenInfo.new(0.25),{TextTransparency=0}):Play() TweenService:Create(phases[i].label,TweenInfo.new(0.25),{TextTransparency=0}):Play() end) end task.wait(0.5) setPhase(1) task.wait(0.3) setPhase(2) ensureFolders() task.wait(0.25) setPhase(3) local icons = {"key","shield","check","copy","discord","alert","lock","loading","close","changelog","user","clock","cart"} if shouldDownloadLogo() then table.insert(icons,"logo") end for _,n in ipairs(icons) do downloadIcon(n) task.wait(0.06) end Internal.IconsLoaded = true setPhase(4) task.wait(0.25) setPhase(5) task.wait(0.5) animRun = false if pulse then task.cancel(pulse) end TweenService:Create(ls,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play() TweenService:Create(shipB,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play() TweenService:Create(shipP,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play() for _,t in pairs(trails) do TweenService:Create(t.frame,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play() end for _,l in pairs(lines) do TweenService:Create(l,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play() end for i=1,5 do TweenService:Create(phases[i].indicator,TweenInfo.new(0.25),{TextTransparency=1}):Play() TweenService:Create(phases[i].label,TweenInfo.new(0.25),{TextTransparency=1}):Play() end TweenService:Create(blur,TweenInfo.new(0.3),{Size=0}):Play() task.wait(0.5) gui:Destroy() blur:Destroy() if onComplete then onComplete() end c = true end) while not c do task.wait(0.05) end end

local function EnsureIconsReady(cb) if allIconsCached() then loadAllIconsFromCache() if cb then cb() end else ShowLoadingScreen(cb) end end

function Patriot:Notify(title, msg, dur, iconType) dur = dur or 5 iconType = iconType or "info" local s = getScale() local w = math.clamp(320*s,260,380) local h = math.clamp(80*s,75,105) local ng = Instance.new("ScreenGui") ng.ResetOnSpawn = false ng.DisplayOrder = 999999 ng.Parent = hui local f = Instance.new("Frame") f.Size = UDim2.new(0,w,0,h) f.Position = UDim2.new(1,w+20,1,-15) f.AnchorPoint = Vector2.new(1,1) f.BackgroundColor3 = Patriot.Theme.Header f.BorderSizePixel = 0 f.Parent = ng Instance.new("UICorner",f).CornerRadius = UDim.new(0,4) local st = Instance.new("UIStroke",f) st.Color = Patriot.Theme.Accent st.Thickness = 1 st.Transparency = 0.7 local pb = Instance.new("Frame") pb.Size = UDim2.new(1,0,0,2) pb.Position = UDim2.new(0,0,1,-2) pb.BackgroundColor3 = Color3.fromRGB(40,40,40) pb.Parent = f local pbar = Instance.new("Frame") pbar.Size = UDim2.new(1,0,1,0) pbar.BackgroundColor3 = Patriot.Theme.Accent pbar.Parent = pb local iconS = h-35 local icon = Instance.new("ImageLabel") icon.Size = UDim2.new(0,iconS,0,iconS) icon.Position = UDim2.new(0,14,0.5,-2) icon.AnchorPoint = Vector2.new(0,0.5) icon.BackgroundTransparency = 1 icon.ScaleType = Enum.ScaleType.Fit icon.Parent = f local imap = {success={"check",Patriot.Theme.Success},error={"alert",Patriot.Theme.Error},warning={"alert",Patriot.Theme.Warning},shield={"shield",Patriot.Theme.Accent},info={"shield",Patriot.Theme.Accent},key={"key",Patriot.Theme.Accent},copy={"copy",Patriot.Theme.Success},discord={"discord",Patriot.Theme.Discord},close={"close",Patriot.Theme.Error}} if imap[iconType] then icon.Image = getIcon(imap[iconType][1]) icon.ImageColor3 = imap[iconType][2] else icon.Image = getLogoIcon() icon.ImageColor3 = Patriot.Theme.Text end local tx = 14+iconS+14 local tl = Instance.new("TextLabel") tl.Size = UDim2.new(1,-(tx+14),0,24) tl.Position = UDim2.new(0,tx,0,12) tl.BackgroundTransparency = 1 tl.Font = Enum.Font.ArimoBold tl.TextSize = math.clamp(15*s,13,18) tl.TextXAlignment = Enum.TextXAlignment.Left tl.TextColor3 = Patriot.Theme.Text tl.Text = title tl.TextTruncate = Enum.TextTruncate.AtEnd tl.Parent = f local ml = Instance.new("TextLabel") ml.Size = UDim2.new(1,-(tx+14),0,22) ml.Position = UDim2.new(0,tx,0,38) ml.BackgroundTransparency = 1 ml.Font = Enum.Font.ArimoBold ml.TextSize = math.clamp(13*s,11,15) ml.TextXAlignment = Enum.TextXAlignment.Left ml.TextColor3 = Patriot.Theme.TextDim ml.Text = msg ml.TextTruncate = Enum.TextTruncate.AtEnd ml.Parent = f local id = tick()..HttpService:GenerateGUID(false) table.insert(Internal.NotificationList,{id=id,frame=f,gui=ng,height=h}) local function restack() local y = 0 for i=#Internal.NotificationList,1,-1 do local n = Internal.NotificationList[i] if n and n.frame and n.frame.Parent then TweenService:Create(n.frame,TweenInfo.new(0.3,Enum.EasingStyle.Quart),{Position = UDim2.new(1,-15,1,-15-y)}):Play() y = y + n.height + 12 end end end TweenService:Create(f,TweenInfo.new(0.4,Enum.EasingStyle.Quart),{Position=UDim2.new(1,-15,1,-15)}):Play() task.wait(0.1) restack() local function dismiss() for i,n in ipairs(Internal.NotificationList) do if n.id == id then table.remove(Internal.NotificationList,i) break end end TweenService:Create(f,TweenInfo.new(0.3,Enum.EasingStyle.Quart),{Position=UDim2.new(1,w+20,f.Position.Y.Scale,f.Position.Y.Offset)}):Play() task.wait(0.3) ng:Destroy() restack() end TweenService:Create(pbar,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,1,0)}):Play() task.delay(dur,dismiss) local cb = Instance.new("TextButton") cb.Size = UDim2.new(1,0,1,0) cb.BackgroundTransparency = 1 cb.Text = "" cb.Parent = f cb.MouseButton1Click:Connect(dismiss) end

-- Build UI simplificada (KeyUI)
local function BuildKeyUI()
    local old = hui:FindFirstChild("PatriotKeySystem")
    if old then old:Destroy() end
    local old2 = hui:FindFirstChild("PatriotKeylessSystem")
    if old2 then old2:Destroy() end
    enableBlur()
    local mobile = isMobile()
    local padding = 14
    local windowWidth = mobile and 400 or 400
    local windowHeight = mobile and 360 or 360
    local buttonHeight = mobile and 42 or 42
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PatriotKeySystem"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = hui
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0,windowWidth,0,windowHeight)
    container.Position = UDim2.new(0.5,0,1.5,0)
    container.AnchorPoint = Vector2.new(0.5,0.5)
    container.BackgroundTransparency = 1
    container.Parent = screenGui
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0,windowWidth,0,windowHeight)
    main.Position = UDim2.new(0.5,0,0,0)
    main.AnchorPoint = Vector2.new(0.5,0)
    main.BackgroundColor3 = Patriot.Theme.Background
    main.BorderSizePixel = 0
    main.Parent = container
    Instance.new("UICorner",main).CornerRadius = UDim.new(0,4)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1,0,0,50)
    header.BackgroundColor3 = Patriot.Theme.Header
    header.BorderSizePixel = 0
    header.Active = true
    header.Parent = main
    Instance.new("UICorner",header).CornerRadius = UDim.new(0,4)
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1,0,0,8)
    headerFix.Position = UDim2.new(0,0,1,-8)
    headerFix.BackgroundColor3 = Patriot.Theme.Header
    headerFix.Parent = header
    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.new(0,30,0,30)
    logo.Position = UDim2.new(0,padding,0.5,0)
    logo.AnchorPoint = Vector2.new(0,0.5)
    logo.BackgroundTransparency = 1
    logo.Image = getLogoIcon()
    logo.ImageColor3 = Patriot.Theme.Text
    logo.ScaleType = Enum.ScaleType.Fit
    logo.Parent = header
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-90,1,0)
    title.Position = UDim2.new(0,padding+40,0,0)
    title.BackgroundTransparency = 1
    title.Text = Patriot.Appearance.Title
    title.TextColor3 = Patriot.Theme.Text
    title.TextSize = mobile and 24 or 26
    title.Font = Enum.Font.ArimoBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    local close = Instance.new("ImageButton")
    close.Size = UDim2.new(0,22,0,22)
    close.Position = UDim2.new(1,-padding,0.5,0)
    close.AnchorPoint = Vector2.new(1,0.5)
    close.BackgroundTransparency = 1
    close.Image = getIcon("close")
    close.ImageColor3 = Patriot.Theme.TextDim
    close.ScaleType = Enum.ScaleType.Fit
    close.Parent = header
    close.MouseEnter:Connect(function() TweenService:Create(close,TweenInfo.new(0.15),{ImageColor3=Patriot.Theme.Error}):Play() end)
    close.MouseLeave:Connect(function() TweenService:Create(close,TweenInfo.new(0.15),{ImageColor3=Patriot.Theme.TextDim}):Play() end)
    local status = Instance.new("Frame")
    status.Size = UDim2.new(0.94,0,0,60)
    status.Position = UDim2.new(0.5,0,0,60)
    status.AnchorPoint = Vector2.new(0.5,0)
    status.BackgroundColor3 = Patriot.Theme.Input
    status.BorderSizePixel = 0
    status.Parent = main
    Instance.new("UICorner",status).CornerRadius = UDim.new(0,4)
    local statusIcon = Instance.new("ImageLabel")
    statusIcon.Size = UDim2.new(0,24,0,24)
    statusIcon.Position = UDim2.new(0,16,0.5,0)
    statusIcon.AnchorPoint = Vector2.new(0,0.5)
    statusIcon.BackgroundTransparency = 1
    statusIcon.Image = getIcon("lock")
    statusIcon.ImageColor3 = Patriot.Theme.StatusIdle
    statusIcon.Parent = status
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1,-60,1,0)
    statusText.Position = UDim2.new(0,52,0,0)
    statusText.BackgroundTransparency = 1
    statusText.Text = Patriot.Appearance.Subtitle
    statusText.TextColor3 = Patriot.Theme.StatusIdle
    statusText.TextSize = mobile and 17 or 18
    statusText.Font = Enum.Font.ArimoBold
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = status
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(0.94,0,0,56)
    inputFrame.Position = UDim2.new(0.5,0,0,130)
    inputFrame.AnchorPoint = Vector2.new(0.5,0)
    inputFrame.BackgroundColor3 = Patriot.Theme.Input
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = main
    Instance.new("UICorner",inputFrame).CornerRadius = UDim.new(0,4)
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1,-24,1,0)
    textBox.Position = UDim2.new(0,12,0.5,0)
    textBox.AnchorPoint = Vector2.new(0,0.5)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.TextColor3 = Patriot.Theme.Text
    textBox.PlaceholderText = "Enter your key..."
    textBox.PlaceholderColor3 = Patriot.Theme.TextDim
    textBox.TextSize = mobile and 17 or 18
    textBox.Font = Enum.Font.ArimoBold
    textBox.Parent = inputFrame
    local redeem = Instance.new("TextButton")
    redeem.Size = UDim2.new(0.75,0,0,buttonHeight)
    redeem.Position = UDim2.new(0.5,0,0,200)
    redeem.AnchorPoint = Vector2.new(0.5,0)
    redeem.BackgroundColor3 = Patriot.Theme.Accent
    redeem.BorderSizePixel = 0
    redeem.Text = "Verify Key"
    redeem.TextColor3 = Patriot.Theme.Text
    redeem.TextSize = mobile and 15 or 16
    redeem.Font = Enum.Font.ArimoBold
    redeem.Parent = main
    Instance.new("UICorner",redeem).CornerRadius = UDim.new(0,4)
    redeem.MouseEnter:Connect(function() TweenService:Create(redeem,TweenInfo.new(0.15),{BackgroundColor3=Patriot.Theme.AccentHover}):Play() end)
    redeem.MouseLeave:Connect(function() TweenService:Create(redeem,TweenInfo.new(0.15),{BackgroundColor3=Patriot.Theme.Accent}):Play() end)
    local spinConnection, dotsThread
    local function setStatus(state, customText)
        if spinConnection then spinConnection:Disconnect() spinConnection = nil statusIcon.Rotation = 0 end
        if dotsThread then task.cancel(dotsThread) dotsThread = nil end
        local color, icon, text = Patriot.Theme.StatusIdle, getIcon("lock"), customText or "No key detected"
        if state == "verifying" then
            color, icon, text = Patriot.Theme.Accent, getIcon("loading"), "Verifying key"
            spinConnection = RunService.Heartbeat:Connect(function(dt)
                if statusIcon and statusIcon.Parent then statusIcon.Rotation = (statusIcon.Rotation + dt * 360) % 360
                elseif spinConnection then spinConnection:Disconnect() end
            end)
            local dots, i = {".","..","...",""}, 1
            dotsThread = task.spawn(function()
                while statusText and statusText.Parent and statusText.Text:find("Verifying",1,true) do
                    statusText.Text = text .. dots[i] i = (i % #dots) + 1 task.wait(0.4)
                end
            end)
        elseif state == "success" then color, icon, text = Patriot.Theme.Success, getIcon("check"), customText or "Access Granted"
        elseif state == "error" then color, icon, text = Patriot.Theme.Error, getIcon("alert"), customText or "Invalid Key" end
        TweenService:Create(statusText,TweenInfo.new(0.3),{TextColor3=color}):Play()
        TweenService:Create(statusIcon,TweenInfo.new(0.3),{ImageColor3=color}):Play()
        statusText.Text = text statusIcon.Image = icon
    end
    local function closeUI(cb)
        TweenService:Create(container,TweenInfo.new(0.4,Enum.EasingStyle.Quart),{Position=UDim2.new(0.5,0,-0.5,0)}):Play()
        TweenService:Create(main,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
        task.wait(0.4) screenGui:Destroy() if cb then cb() end
    end
    close.MouseButton1Click:Connect(function()
        Patriot:Notify("Goodbye","Welcome to use it next time!",2,"close")
        closeUI(function() fullCleanup() if Patriot.Callbacks.OnClose then Patriot.Callbacks.OnClose() end end)
    end)
    local function handleRedeem()
        local key = textBox.Text:gsub("%s+","")
        if key == "" then Patriot:Notify("Error","Please enter your key",3,"warning") return end
        setStatus("verifying")
        redeem.Active = false
        task.wait(0.3)
        local valid, errorMsg = false, "Invalid key"
        if Internal.ValidateFunction then
            local s,r,m = pcall(Internal.ValidateFunction, key)
            if s then
                if type(r) == "table" then
                    valid = r.valid == true
                    local errMsgs = {KEY_INVALID="Key not found in system",KEY_EXPIRED="Key has expired",HWID_BANNED="Hardware banned",KEY_INVALIDATED="Key was revoked",ALREADY_USED="One-time key already used",HWID_MISMATCH="HWID limit reached",SERVICE_NOT_FOUND="Service not found",SERVICE_MISMATCH="Wrong service",PREMIUM_REQUIRED="Premium required",ERROR="Network error"}
                    local err = r.error or "Unknown"
                    errorMsg = errMsgs[err] or r.message or err
                    if err == "HWID_BANNED" then task.delay(2,function() cloneref(Players.LocalPlayer):Kick("Hardware banned") end) end
                elseif type(r) == "boolean" then valid = r errorMsg = m or "Invalid key" end
            end
        end
        redeem.Active = true
        if valid then
            saveKey(key) getgenv().SCRIPT_KEY = key getgenv().PatriotLoaded = false
            setStatus("success") Patriot:Notify("Success","Key validated successfully!",2,"success") task.wait(1)
            closeUI(function()
                disableBlur()
                if not Internal.IsJunkieMode and Patriot.Callbacks.OnSuccess then Patriot.Callbacks.OnSuccess() end
            end)
        else
            setStatus("error",errorMsg) Patriot:Notify("Invalid",errorMsg,4,"error")
            if Patriot.Callbacks.OnFail then Patriot.Callbacks.OnFail(errorMsg) end
        end
    end
    redeem.MouseButton1Click:Connect(handleRedeem)
    textBox.FocusLost:Connect(function(enter) if enter then handleRedeem() end end)
    setupDragging(header, container)
    TweenService:Create(container,TweenInfo.new(0.5,Enum.EasingStyle.Quart),{Position=UDim2.new(0.5,0,0.45,0)}):Play()
end

-- ============================================
-- LANZAMIENTO CON JUNKIE
-- ============================================
function Patriot:LaunchJunkie(config)
    Internal.IsJunkieMode = true
    local existingKey = getgenv().SCRIPT_KEY
    if existingKey and existingKey ~= "" then
        Patriot:Notify("Executed","Script loaded successfully!",2,"success")
        if Patriot.Callbacks.OnSuccess then Patriot.Callbacks.OnSuccess() end
        return
    end
    getgenv().PatriotClosed = false
    EnsureIconsReady(function()
        local success, Junkie = pcall(function() return loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))() end)
        if not success or not Junkie then
            Patriot:Notify("Error","Failed to load Junkie SDK",5,"error")
            return
        end
        Junkie.service = config.Service
        Junkie.identifier = config.Identifier
        Junkie.provider = config.Provider
        Internal.Junkie = Junkie
        if Patriot.Links.GetKey == "" then
            pcall(function() Patriot.Links.GetKey = Junkie.get_key_link() end)
        end
        Internal.ValidateFunction = function(key) return Junkie.check_key(key) end
        if Patriot.Storage.AutoLoad then
            local savedKey = loadKey()
            if savedKey and savedKey ~= "" then
                Patriot:Notify("Checking","Validating saved key...",2,"shield")
                task.wait(0.5)
                local vs, vr = pcall(function() return Junkie.check_key(savedKey) end)
                if vs and vr and vr.valid then
                    getgenv().SCRIPT_KEY = savedKey
                    Patriot:Notify("Welcome Back","Key validated!",2,"success")
                    if Patriot.Callbacks.OnSuccess then Patriot.Callbacks.OnSuccess() end
                    return
                else
                    clearKey()
                    Patriot:Notify("Expired","Saved key is no longer valid",3,"warning")
                    task.wait(1)
                end
            end
        end
        BuildKeyUI()
        while not getgenv().SCRIPT_KEY do task.wait(0.1) end
    end)
end

-- ============================================
-- CONFIGURACIÓN Y EJECUCIÓN
-- ============================================
Patriot.Links.GetKey = "https://jnkie.com/get-key/waterhubkey"
Patriot.Appearance.Title = "Water Hub"
Patriot.Appearance.Subtitle = "Enter your key to continue"
Patriot.Storage.FileName = "WaterHub_Key"
Patriot.Options.Keyless = false
Patriot.Options.KeylessUI = false

Patriot.Callbacks.OnSuccess = function()
    -- CARGAR WATER HUB DESDE JUNKIE
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/486002b77ce16680464be32b51b47af2b0978f2aa026a6c8ad41777b1312a3e4/download"))()
    end)
    if success and result then
        result()
    else
        Patriot:Notify("Error","Failed to load Water Hub",5,"error")
    end
end

Patriot:LaunchJunkie({
    Service = "waterhub",
    Identifier = "waterhubkey",
    Provider = "jnkie"
})

return Patriot
