--[[ VannHUB (MINE A ANTARCTICA)
  Auto Collect, ESP custom, TP Player/Crystal, Auto Sell interval
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local function tw(obj, sec, props)
    pcall(function()
        TweenService:Create(obj, TweenInfo.new(sec or 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
    end)
end

local player = Players.LocalPlayer

local S = {
    AutoCollect = false,
    AutoRune = false,
    InstantPrompt = true,
    AutoSell = false,
    AutoFavorite = false,
    ESP = false,

    CollectRadius = 28,
    CollectInterval = 0.4,
    MinLuck = 0,
    MinCoin = 0,
    MinBerat = 0,
    DropQty = 1,
    FavMode = "coin",
    FavMin = 0,

    -- ESP custom
    EspMinLuck = 0,
    EspMinCoin = 0,
    EspMinBerat = 0,
    EspShowLuck = true,
    EspShowCoin = true,
    EspShowBerat = true,
    EspMaxDist = 400,
    BoulderMaxDist = 1200,
    EspPlayer = false,
    EspBoulder = false,
    AutoBoulderRadar = false,
    BoulderRadarInterval = 35,
    EspBoulderKinds = {
        Mossite = true, Voltite = true, Gildrite = true,
        Rimeveil = true, Nocturnite = true,
    },
    EspRarity = {
        Umum = true, ["Tidak Biasa"] = true, Langka = true,
        Epic = true, Legendaris = true, Mitos = true, Exotic = true, Zenith = true,
    },

    Rarity = {
        Umum = true, ["Tidak Biasa"] = true, Langka = true,
        Epic = true, Legendaris = true, Mitos = true, Exotic = true, Zenith = true,
    },

    -- Auto Sell
    SellInterval = 15, -- detik 10-30
    speedOn = false,
    speed = 28,
    infJump = false,
    antiRagdoll = false,
    noFall = false,
    antiKB = false,
    uiLocked = false,
    antiAFK = true,
    autoReconnect = false,
    autoLoadConfig = true,
    autoWarmth = false,
    autoCarry = false,
    AutoBuyBombs = false,
    AutoBuyRadars = false,
    BuyBombs = {
        ClassicBomb=true, IceBomb=true, FireBomb=true, PoisonBomb=true,
        LightningBomb=true, WindBomb=true, DivineBomb=true, VoidBomb=true, NebulaBomb=true,
    },
    BuyRadars = {
        CrystalRadar=true, BoulderRadar=true, RuneRadar=true,
        RarityRadar=true, MeteorRadar=true, ZenithRadar=true,
    },
    warmthAmount = 10, -- 10 / 50 / max
    carryAmount = 1,
    HomeCF = nil,
    PlotCF = nil,

    -- GFX
    gfxFlat = false,
    gfxAntiLag = false,
    gfxHidePlayers = false,
    gfxHideEffects = false,
    gfxWhite = false,
    gfxBlack = false,
    showPerf = false,
}

local claimed, dropIgnore = {}, {}

local function deepFind(root, name)
    if not root then return nil end
    local r = root:FindFirstChild(name)
    if r then return r end
    local ok, f = pcall(function() return root:FindFirstChild(name, true) end)
    return ok and f or nil
end

local Remotes = {
    DropCrystal = (function()
        local g = ReplicatedStorage:FindFirstChild("GemSignals")
        return g and (g:FindFirstChild("DropCrystal") or g:FindFirstChild("DropGem"))
    end)(),
    PlaceCrystal = ReplicatedStorage:FindFirstChild("PlotRemotes") and ReplicatedStorage.PlotRemotes:FindFirstChild("PlaceCrystal"),
    Sell = deepFind(ReplicatedStorage, "SellRequest") or deepFind(ReplicatedStorage, "Sell"),
    Favorite = deepFind(ReplicatedStorage, "ToggleFavorite") or deepFind(ReplicatedStorage, "Favorite"),
    GoHome = deepFind(ReplicatedStorage, "GoHome"),
    Hold = deepFind(ReplicatedStorage, "CrystalHoldComplete") or deepFind(ReplicatedStorage, "HoldComplete"),
}

-- theme
local BG = Color3.fromRGB(10, 11, 14)
local CARD = Color3.fromRGB(22, 26, 34)
local SIDE = Color3.fromRGB(16, 18, 24)
local ACC = Color3.fromRGB(255, 176, 72)
local GRN = Color3.fromRGB(62, 168, 122)
local RED = Color3.fromRGB(196, 78, 64)
local TXT = Color3.fromRGB(236, 240, 246)
local MUT = Color3.fromRGB(150, 160, 176)

local function notify(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "VannHUB", Text = tostring(msg), Duration = 2 })
    end)
end

local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getAttr(i, n)
    local ok, v = pcall(function() return i:GetAttribute(n) end)
    return ok and v or nil
end
local function numAttr(inst, names)
    if not inst then return 0 end
    for _, n in ipairs(names) do
        local v = getAttr(inst, n)
        if v ~= nil then
            local t = tonumber(v)
            if not t and type(v) == "string" then
                t = tonumber((tostring(v):gsub("[^%d%.]", "")))
            end
            if t then return t end
        end
        local ch = inst:FindFirstChild(n, true)
        if ch then
            if ch:IsA("ValueBase") then
                local t = tonumber(ch.Value)
                if t then return t end
            elseif ch:IsA("TextLabel") or ch:IsA("TextBox") then
                local t = tonumber((tostring(ch.Text):gsub("[^%d%.eE%+%-]", "")))
                if t then return t end
            end
        end
    end
    -- scan attributes
    local ok, attrs = pcall(function() return inst:GetAttributes() end)
    if ok and attrs then
        for an, av in pairs(attrs) do
            local al = string.lower(an)
            for _, n in ipairs(names) do
                if al == string.lower(n) or al:find(string.lower(n), 1, true) then
                    local t = tonumber(av)
                    if t then return t end
                end
            end
        end
    end
    return 0
end

-- Parse angka game: 3.3 kg, $2,112, +0.3%, 1.2B
local function parseStatNumber(v, mode)
    if v == nil then return nil end
    if type(v) == "number" then return v end
    local raw = tostring(v)
    local s = raw:gsub(",", ""):gsub("%s+", " ")
    if mode == "weight" then
        local n = s:lower():match("([%d%.]+)%s*kg")
        if n then return tonumber(n) end
        n = s:lower():match("([%d%.]+)%s*kilogram")
        if n then return tonumber(n) end
        -- pure number only if small-ish (weight rarely > 1e6)
        n = s:match("^%s*([%d%.]+)%s*$")
        if n then
            n = tonumber(n)
            if n and n < 1e7 then return n end
        end
        return nil
    elseif mode == "coin" then
        local n, suf = s:upper():match("%$%s*([%d%.]+)%s*([KMBT]?)")
        if not n then n, suf = s:upper():match("([%d%.]+)%s*([KMBT])") end
        if not n then n = s:match("%$%s*([%d%.]+)") end
        if n then
            n = tonumber(n) or 0
            suf = suf or ""
            if suf == "K" then n = n * 1e3
            elseif suf == "M" then n = n * 1e6
            elseif suf == "B" then n = n * 1e9
            elseif suf == "T" then n = n * 1e12 end
            return n
        end
        n = s:match("^%s*([%d%.]+)%s*$")
        return n and tonumber(n) or nil
    elseif mode == "luck" then
        local n = s:match("([%+%-]?[%d%.]+)%s*%%")
        if n then return tonumber(n) end
        n = s:match("([%+%-]?[%d%.]+)")
        if n then
            n = tonumber(n)
            -- luck biasanya kecil
            if n and math.abs(n) < 100000 then return n end
        end
        return nil
    end
    -- generic
    local n, suf = s:upper():match("([%d%.]+)%s*([KMBT]?)")
    if n then
        n = tonumber(n) or 0
        if suf == "K" then n = n * 1e3
        elseif suf == "M" then n = n * 1e6
        elseif suf == "B" then n = n * 1e9
        elseif suf == "T" then n = n * 1e12 end
        return n
    end
    return nil
end

local EXACT_WEIGHT = {"Weight", "Berat", "WeightKg", "CrystalWeight", "KgWeight"}
local EXACT_COIN = {"Value", "Coin", "Coins", "Price", "Cash", "Money", "SellValue", "Worth"}
local EXACT_LUCK = {"Luck", "LuckBonus", "BonusLuck", "CrystalLuck", "Keberuntungan"}

local function attrExact(inst, names, mode)
    if not inst then return nil end
    for _, n in ipairs(names) do
        local v = getAttr(inst, n)
        local p = parseStatNumber(v, mode)
        if p ~= nil then return p end
        local ch = inst:FindFirstChild(n)
        if ch then
            if ch:IsA("ValueBase") then
                p = parseStatNumber(ch.Value, mode)
                if p ~= nil then return p end
            elseif ch:IsA("TextLabel") or ch:IsA("TextBox") then
                p = parseStatNumber(ch.Text, mode)
                if p ~= nil then return p end
            end
        end
    end
    return nil
end

local function scanPromptText(inst, mode)
    if not inst then return nil end
    local best = nil
    local function consider(text)
        local p = parseStatNumber(text, mode)
        if p == nil then return end
        if best == nil then best = p
        elseif mode == "coin" and p > best then best = p
        elseif mode == "weight" and p > 0 and (best == 0 or p < 1e6) then best = p
        elseif mode == "luck" then best = p
        end
    end
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            consider(d.ObjectText)
            consider(d.ActionText)
        elseif d:IsA("TextLabel") or d:IsA("TextBox") then
            local tx = tostring(d.Text or "")
            local low = string.lower(tx)
            if mode == "weight" and (low:find("kg", 1, true) or low:find("berat", 1, true) or low:find("weight", 1, true)) then
                consider(tx)
            elseif mode == "coin" and (low:find("$", 1, true) or low:find("value", 1, true) or low:find("coin", 1, true)) then
                consider(tx)
            elseif mode == "luck" and (low:find("luck", 1, true) or low:find("%%") or low:find("keberuntung", 1, true)) then
                consider(tx)
            end
        end
    end
    return best
end

local function luck(i)
    local v = attrExact(i, EXACT_LUCK, "luck")
    if v ~= nil then return v end
    v = scanPromptText(i, "luck")
    return v or 0
end
local function coin(i)
    local v = attrExact(i, EXACT_COIN, "coin")
    if v ~= nil then return v end
    v = scanPromptText(i, "coin")
    return v or 0
end
local function berat(i)
    if not i then return 0 end
    local v = attrExact(i, EXACT_WEIGHT, "weight")
    if v ~= nil then return v end
    -- scan semua attribute yang namanya mengandung weight/berat/kg
    local ok, attrs = pcall(function() return i:GetAttributes() end)
    if ok and attrs then
        for an, av in pairs(attrs) do
            local al = string.lower(tostring(an))
            if al:find("weight", 1, true) or al:find("berat", 1, true) or al == "kg" or al:find("mass", 1, true) then
                local p = parseStatNumber(av, "weight")
                if p == nil and type(av) == "number" and av > 0 and av < 1e6 then p = av end
                if p and p > 0 then return p end
            end
        end
    end
    -- StringValue / NumberValue descendants
    for _, d in ipairs(i:GetDescendants()) do
        local dn = string.lower(d.Name)
        if dn:find("weight", 1, true) or dn:find("berat", 1, true) or dn == "kg" then
            if d:IsA("ValueBase") then
                local p = parseStatNumber(d.Value, "weight")
                if p == nil and type(d.Value) == "number" then p = d.Value end
                if p and p > 0 and p < 1e6 then return p end
            end
        end
    end
    v = scanPromptText(i, "weight")
    if v and v > 0 then return v end
    -- nama tool kadang berisi "3.3kg"
    local p = parseStatNumber(i.Name, "weight")
    if p and p > 0 then return p end
    return 0
end

local function parseMoney(s)
    if s == nil then return 0 end
    if type(s) == "number" then return s end
    s = tostring(s):gsub("[%$,%s]", ""):upper()
    local n, suf = s:match("^([%d%.]+)([KMBT]?)$")
    if not n then
        n = s:match("([%d%.]+)")
        suf = ""
    end
    n = tonumber(n) or 0
    if suf == "K" then n = n * 1e3
    elseif suf == "M" then n = n * 1e6
    elseif suf == "B" then n = n * 1e9
    elseif suf == "T" then n = n * 1e12 end
    return n
end

local function fmt(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.1fT", n/1e12) end
    if n >= 1e9 then return string.format("%.1fB", n/1e9) end
    if n >= 1e6 then return string.format("%.1fM", n/1e6) end
    if n >= 1e3 then return string.format("%.1fK", n/1e3) end
    return tostring(math.floor(n))
end

local RUNE_NAMES = {
    luck=true, haste=true, storm=true, weight=true, fortune=true,
    detonation=true, preservation=true, warmth=true, excavator=true, colossus=true,
}

local function isRune(obj)
    if not obj then return false end
    if getAttr(obj, "IsRune") == true then return true end
    if getAttr(obj, "RuneType") ~= nil or getAttr(obj, "RuneName") ~= nil or getAttr(obj, "Rune") ~= nil then
        return true
    end
    local n = string.lower(tostring(obj.Name or ""))
    if n:find("rune", 1, true) then return true end
    if RUNE_NAMES[n] then return true end
    local ok, full = pcall(function() return string.lower(obj:GetFullName()) end)
    if ok and full and (full:find("rune", 1, true)) then
        if not full:find("crystal", 1, true) then return true end
    end
    return false
end

local function isCrystal(obj)
    if not obj then return false end
    if isRune(obj) then return false end
    local n = string.lower(tostring(obj.Name or ""))
    if n:find("rune", 1, true) then return false end
    if n == "mossite" or n == "voltite" or n == "gildrite" or n == "rimeveil" or n == "nocturnite" then return false end
    if n:find("crystal", 1, true) or n:find("gem", 1, true) or n:find("amethyst", 1, true) or n:find("kristal", 1, true) then return true end
    if getAttr(obj, "IsCrystal") == true then return true end
    local hasStat = getAttr(obj, "Value") ~= nil or getAttr(obj, "Luck") ~= nil or getAttr(obj, "Weight") ~= nil or getAttr(obj, "WeightKg") ~= nil
    if not hasStat then return false end
    local full = string.lower(obj:GetFullName())
    if full:find("button", 1, true) or full:find("shop", 1, true) or full:find("npc", 1, true) or full:find("prompt", 1, true) then
        return false
    end
    if full:find("crystal", 1, true) or full:find("dropped", 1, true) or full:find("gem", 1, true) or full:find("loot", 1, true) then
        return true
    end
    return obj:IsA("Model") or obj:IsA("Tool")
end

-- rarity dari Attribute Tier/Rarity (bukan cuma nama)
local RARITY_KEYS = { "Umum", "Tidak Biasa", "Langka", "Epic", "Legendaris", "Mitos", "Exotic", "Zenith" }

local function normalizeRarityKey(raw)
    if raw == nil then return "Umum" end
    local n = tonumber(raw)
    if n then
        if n <= 1 then return "Umum" end
        if n == 2 then return "Tidak Biasa" end
        if n == 3 then return "Langka" end
        if n == 4 then return "Epic" end
        if n == 5 then return "Legendaris" end
        if n == 6 then return "Mitos" end
        if n == 7 then return "Exotic" end
        if n >= 8 then return "Zenith" end
        return "Exotic"
    end
    local s = string.lower(tostring(raw))
    if s:find("zenith", 1, true) then return "Zenith" end
    if s:find("exotic", 1, true) or s:find("secret", 1, true) then return "Exotic" end
    if s:find("mito", 1, true) or s:find("mythic", 1, true) or s:find("myth", 1, true) then return "Mitos" end
    if s:find("legend", 1, true) or s:find("legendar", 1, true) then return "Legendaris" end
    if s:find("epic", 1, true) then return "Epic" end
    if s:find("rare", 1, true) or s:find("langka", 1, true) then return "Langka" end
    if s:find("uncommon", 1, true) or s:find("tidak", 1, true) then return "Tidak Biasa" end
    if s:find("common", 1, true) or s:find("umum", 1, true) or s:find("normal", 1, true) then return "Umum" end
    return "Umum"
end

local function getCrystalRarity(obj)
    if not obj then return "Umum" end
    -- prioritaskan attribute
    local candidates = {
        getAttr(obj, "Rarity"),
        getAttr(obj, "RarityName"),
        getAttr(obj, "Tier"),
        getAttr(obj, "TierName"),
        getAttr(obj, "Grade"),
        getAttr(obj, "Quality"),
    }
    for _, c in ipairs(candidates) do
        if c ~= nil and tostring(c) ~= "" then
            return normalizeRarityKey(c)
        end
    end
    -- child values
    for _, nm in ipairs({"Rarity", "RarityName", "Tier", "TierName"}) do
        local ch = obj:FindFirstChild(nm, true)
        if ch then
            local v = ch:IsA("ValueBase") and ch.Value or (ch:IsA("TextLabel") and ch.Text)
            if v ~= nil then return normalizeRarityKey(v) end
        end
    end
    -- nama object terakhir
    return normalizeRarityKey(obj.Name)
end

local function rarityOK(obj)
    local key = getCrystalRarity(obj)
    return S.Rarity[key] == true
end

local function rarityOKEsp(obj)
    local key = getCrystalRarity(obj)
    return S.EspRarity[key] == true
end

local function meetsCollect(obj)
    if not rarityOK(obj) then return false end
    if luck(obj) < (tonumber(S.MinLuck) or 0) then return false end
    if coin(obj) < (tonumber(S.MinCoin) or 0) then return false end
    if berat(obj) < (tonumber(S.MinBerat) or 0) then return false end
    return true
end

local function meetsESP(obj)
    if not rarityOKEsp(obj) then return false end
    if luck(obj) < (tonumber(S.EspMinLuck) or 0) then return false end
    if coin(obj) < (tonumber(S.EspMinCoin) or 0) then return false end
    if berat(obj) < (tonumber(S.EspMinBerat) or 0) then return false end
    return true
end

local function getPart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        local ok, cf = pcall(function() return obj:GetBoundingBox() end)
        -- prefer handle / largest part
        local best, bestVol = nil, -1
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("BasePart") then
                local vol = d.Size.X * d.Size.Y * d.Size.Z
                if d.Name == "Handle" then return d end
                if vol > bestVol then bestVol, best = vol, d end
            end
        end
        return best
    end
    return obj:FindFirstAncestorWhichIsA("BasePart")
end

local function getWorldPos(obj)
    if not obj then return nil end
    if obj:IsA("Model") then
        local ok, cf = pcall(function() return obj:GetPivot() end)
        if ok and cf then return cf.Position end
        local ok2, cf2, size = pcall(function() return obj:GetBoundingBox() end)
        if ok2 and cf2 then return cf2.Position end
    end
    local p = getPart(obj)
    return p and p.Position or nil
end

local function isOnPlot(obj)
    if not obj then return true end
    local pos = getWorldPos(obj)
    if not pos then return true end
    local full = string.lower(tostring(obj:GetFullName()))
    -- path jelas plot/base/garden
    if full:find("/plot", 1, true) or full:find(".plot", 1, true)
        or full:find("plots", 1, true) or full:find("tycoon", 1, true)
        or full:find("garden", 1, true) or full:find("placed", 1, true)
        or full:find("baseplate", 1, true) then
        return true
    end
    if S.PlotCF and (pos - S.PlotCF.Position).Magnitude < 45 then return true end
    if S.HomeCF and (pos - S.HomeCF.Position).Magnitude < 30 then return true end
    -- dekat spawn/plot folder di workspace
    for _, name in ipairs({"Plots", "Plot", "Bases", "Tycoons", "Farms"}) do
        local f = Workspace:FindFirstChild(name)
        if f then
            for _, pl in ipairs(f:GetDescendants()) do
                if pl:IsA("BasePart") and (pl.Position - pos).Magnitude < 28 then
                    local pn = string.lower(pl:GetFullName())
                    if pn:find("plot", 1, true) or pn:find("base", 1, true) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function isLootableWorldCrystal(obj)
    if not obj or not obj.Parent then return false end
    if not isCrystal(obj) then return false end
    -- skip backpack tools
    if obj:IsA("Tool") then
        local p = obj.Parent
        if p and (p:IsA("Backpack") or p:IsA("Model") and Players:GetPlayerFromCharacter(p)) then
            return false
        end
    end
    if isOnPlot(obj) then return false end
    return true
end

local function findPrompt(obj)
    if not obj then return nil end
    if obj:IsA("ProximityPrompt") then return obj end
    local p = obj:FindFirstChildOfClass("ProximityPrompt")
    if p then return p end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") then return d end
    end
    return nil
end

local function enablePrompt(p)
    if not p then return end
    pcall(function()
        p.Enabled = true
        p.HoldDuration = 0
        p.MaxActivationDistance = math.max(p.MaxActivationDistance, S.CollectRadius + 10)
        p.RequiresLineOfSight = false
    end)
end

local function firePrompt(p)
    if not p then return end
    enablePrompt(p)
    pcall(function()
        if fireproximityprompt then
            for _ = 1, 3 do
                fireproximityprompt(p)
            end
        end
    end)
    pcall(function()
        p:InputHoldBegin()
        task.wait(0.03)
        p:InputHoldEnd()
    end)
end

local function promptIsCollect(p)
    if not p or not p:IsA("ProximityPrompt") then return false end
    local blob = string.lower(tostring(p.ActionText or "") .. " " .. tostring(p.ObjectText or "") .. " " .. tostring(p.Name or ""))
    if blob:find("buy",1,true) or blob:find("sell",1,true) or blob:find("shop",1,true)
        or blob:find("upgrade",1,true) or blob:find("dig",1,true) or blob:find("bomb",1,true)
        or blob:find("radar",1,true) or blob:find("talk",1,true) or blob:find("open",1,true) then
        return false
    end
    return true
end

local function grab(obj)
    if not obj or not obj.Parent or dropIgnore[obj] then return end
    if Remotes.Hold then
        pcall(function()
            if Remotes.Hold:IsA("RemoteEvent") then
                Remotes.Hold:FireServer(obj)
            else
                Remotes.Hold:InvokeServer(obj)
            end
        end)
    end
    local pr = findPrompt(obj)
    if pr and promptIsCollect(pr) then firePrompt(pr) end
end

-- Auto Collect no TP
local function autoCollect()
    if not (S.AutoCollect or S.AutoRune or S.InstantPrompt) then return end
    local hrp = getHRP()
    if not hrp then return end
    local origin = hrp.Position
    local radius = math.max(tonumber(S.CollectRadius) or 28, 8)
    local now = os.clock()
    for k, tm in pairs(claimed) do
        if now - tm > 2.2 then claimed[k] = nil end
    end

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    if player.Character then params.FilterDescendantsInstances = { player.Character } end
    local parts = {}
    pcall(function() parts = Workspace:GetPartBoundsInRadius(origin, radius, params) end)

    local seen = {}
    local function tryGrab(target)
        if not target or seen[target] then return end
        if dropIgnore[target] then return end
        if isOnPlot(target) then return end
        local id = tostring(target)
        if claimed[id] and (now - claimed[id]) < 1.2 then return end
        seen[target] = true
        claimed[id] = now
        grab(target)
    end

    -- 1) radius parts
    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model") or part
        if S.AutoCollect then
            local target = (isCrystal(model) and model) or (isCrystal(part) and part)
            if target and meetsCollect(target) then tryGrab(target) end
        end
        if S.AutoRune then
            local rt = (isRune(model) and model) or (isRune(part) and part)
            if rt then tryGrab(rt) end
        end
    end

    -- Instant Prompt: hanya part di radius, tanpa scan seluruh map
    if S.InstantPrompt then
        local touched = {}
        for _, part in ipairs(parts) do
            local model = part:FindFirstAncestorOfClass("Model") or part
            if touched[model] then continue end
            touched[model] = true
            if isOnPlot(model) then continue end
            local crystal = isCrystal(model) or isCrystal(part)
            local rune = isRune(model) or isRune(part)
            if not crystal and not rune then continue end
            if crystal and not meetsCollect(model) and not meetsCollect(part) then
                if not rune then continue end
            end
            local list = {}
            if part:IsA("ProximityPrompt") then table.insert(list, part) end
            local p1 = part:FindFirstChildOfClass("ProximityPrompt")
            if p1 then table.insert(list, p1) end
            local p2 = model:FindFirstChildOfClass("ProximityPrompt")
            if p2 then table.insert(list, p2) end
            for _, d in ipairs(model:GetChildren()) do
                if d:IsA("ProximityPrompt") then table.insert(list, d) end
                if d:IsA("BasePart") then
                    local p3 = d:FindFirstChildOfClass("ProximityPrompt")
                    if p3 then table.insert(list, p3) end
                end
            end
            for _, pr in ipairs(list) do
                enablePrompt(pr)
            end
        end
    end
end

local function instantTick()
    -- skip full-map scan (FPS)
end


local function lightStat(inst, names, mode)
    if not inst then return 0 end
    for _, n in ipairs(names) do
        local v = getAttr(inst, n)
        if v ~= nil then
            local p = parseStatNumber(v, mode)
            if p ~= nil then return p end
            if type(v) == "number" then return v end
        end
    end
    local ok, attrs = pcall(function() return inst:GetAttributes() end)
    if ok and attrs then
        for an, av in pairs(attrs) do
            local al = string.lower(tostring(an))
            for _, n in ipairs(names) do
                if al == string.lower(n) then
                    local p = parseStatNumber(av, mode)
                    if p ~= nil then return p end
                    if type(av) == "number" then return av end
                end
            end
        end
    end
    return 0
end
local function lightLuck(i) return lightStat(i, EXACT_LUCK, "luck") end
local function lightCoin(i) return lightStat(i, EXACT_COIN, "coin") end
local function lightBerat(i) return lightStat(i, EXACT_WEIGHT, "weight") end

-- ESP custom
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "CrystalESP"
pcall(function() ESPFolder.Parent = CoreGui end)

local function clearESP() ESPFolder:ClearAllChildren() end

local function createESP(obj)
    local part = getPart(obj)
    if not part then return end
    local my = getHRP()
    local dist = my and math.floor((part.Position - my.Position).Magnitude + 0.5) or 0
    local bits = { tostring(obj.Name), tostring(getCrystalRarity(obj)) }
    if S.EspShowCoin then table.insert(bits, "$" .. fmt(lightCoin(obj))) end
    if S.EspShowLuck then table.insert(bits, "L" .. fmt(lightLuck(obj))) end
    if S.EspShowBerat then table.insert(bits, fmt(lightBerat(obj)) .. "kg") end
    table.insert(bits, dist .. "m")
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 210, 0, 22)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.MaxDistance = tonumber(S.EspMaxDist) or 400
    bb.StudsOffset = Vector3.new(0, 2.2, 0)
    bb.Adornee = part
    bb.Parent = ESPFolder
    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1, 0, 1, 0)
    lab.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    lab.BackgroundTransparency = 0.22
    lab.Text = table.concat(bits, "  ·  ")
    lab.TextColor3 = Color3.fromRGB(230, 240, 255)
    lab.Font = Enum.Font.GothamMedium
    lab.TextSize = 12
    lab.Parent = bb
    Instance.new("UICorner", lab).CornerRadius = UDim.new(0, 6)
    local st = Instance.new("UIStroke")
    st.Thickness = 1.4
    st.Color = ACC
    st.Transparency = 0.35
    st.Parent = lab
    pcall(function()
        local adornee = obj
        if not (obj:IsA("Model") or obj:IsA("BasePart")) then
            adornee = part
        end
        local hl = Instance.new("Highlight")
        hl.Name = "ACCrystalHL"
        hl.Adornee = adornee
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = 0.72
        hl.OutlineTransparency = 0
        hl.FillColor = ACC
        hl.OutlineColor = Color3.fromRGB(255, 220, 140)
        hl.Parent = ESPFolder
        local link = Instance.new("ObjectValue")
        link.Name = "HLLink"
        link.Value = hl
        link.Parent = bb
    end)
end

local BOULDER_KIND_LIST = {"Mossite","Voltite","Gildrite","Rimeveil","Nocturnite"}
local BOULDER_COLORS = {
    Mossite = Color3.fromRGB(110, 220, 90),
    Voltite = Color3.fromRGB(80, 170, 255),
    Gildrite = Color3.fromRGB(255, 200, 70),
    Rimeveil = Color3.fromRGB(180, 235, 255),
    Nocturnite = Color3.fromRGB(170, 100, 255),
}
local RadarBoulderCache = {}

local function colorToBoulderKind(col)
    if typeof(col) ~= "Color3" then return nil end
    local samples = {
        Mossite = {0.43, 0.86, 0.35},
        Voltite = {0.31, 0.67, 1.00},
        Gildrite = {1.00, 0.78, 0.27},
        Rimeveil = {0.71, 0.92, 1.00},
        Nocturnite = {0.67, 0.39, 1.00},
    }
    local best, bestD = nil, 0.38
    for kind, rgb in pairs(samples) do
        local d = math.abs(col.R - rgb[1]) + math.abs(col.G - rgb[2]) + math.abs(col.B - rgb[3])
        if d < bestD then bestD = d best = kind end
    end
    return best
end

local function matchBoulderKind(str)
    if str == nil then return nil end
    local low = string.lower(tostring(str))
    if low:find("crystal", 1, true) or low:find("gem", 1, true) then return nil end
    for _, k in ipairs(BOULDER_KIND_LIST) do
        local kl = string.lower(k)
        if low == kl or low:find(kl, 1, true) then return k end
    end
    return nil
end

local function buyBoulderRadar()
    local fired = false
    pcall(function()
        local folder = ReplicatedStorage:FindFirstChild("RadarRemotes")
        local ev = folder and (folder:FindFirstChild("BuyRadar") or folder:FindFirstChild("UseRadar"))
        if not ev then ev = deepFind(ReplicatedStorage, "BuyRadar") end
        if not ev then return end
        for _, name in ipairs({"BoulderRadar","Boulder","RadarBoulder"}) do
            pcall(function()
                if ev:IsA("RemoteEvent") then
                    ev:FireServer(name)
                    ev:FireServer(name, "cash")
                elseif ev:IsA("RemoteFunction") then
                    ev:InvokeServer(name)
                end
            end)
            fired = true
        end
    end)
    return fired
end

local function createBoulderESP(obj, kind, useHL)
    local part = getPart(obj)
    if not part then return end
    local col = BOULDER_COLORS[kind] or Color3.fromRGB(200, 200, 200)
    local my = getHRP()
    local dist = my and math.floor((part.Position - my.Position).Magnitude + 0.5) or 0
    local bb = Instance.new("BillboardGui")
    bb.Name = "BoulderESP"
    bb.Size = UDim2.new(0, 150, 0, 22)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.MaxDistance = tonumber(S.BoulderMaxDist) or 1200
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.Adornee = part
    bb.Parent = ESPFolder
    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1, 0, 1, 0)
    lab.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    lab.BackgroundTransparency = 0.18
    lab.Text = kind .. "  ·  " .. dist .. "m"
    lab.TextColor3 = col
    lab.Font = Enum.Font.GothamMedium
    lab.TextSize = 13
    lab.Parent = bb
    Instance.new("UICorner", lab).CornerRadius = UDim.new(0, 6)
    local st = Instance.new("UIStroke")
    st.Thickness = 1.2
    st.Color = col
    st.Transparency = 0.25
    st.Parent = lab
    if useHL then
        pcall(function()
            local adornee = (obj:IsA("Model") or obj:IsA("BasePart")) and obj or part
            local hl = Instance.new("Highlight")
            hl.Name = "ACBoulderHL"
            hl.Adornee = adornee
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillTransparency = 0.45
            hl.OutlineTransparency = 0
            hl.FillColor = col
            hl.OutlineColor = col
            hl.Parent = ESPFolder
            local link = Instance.new("ObjectValue")
            link.Name = "HLLink"
            link.Value = hl
            link.Parent = bb
        end)
    end
end

local function collectBoulders()
    -- Boulder baru ada setelah jalur digali. ESP hanya object kind yang sudah muncul di world, dalam jarak render.
    local out, seen = {}, {}
    local my = getHRP()
    local maxb = tonumber(S.BoulderMaxDist) or 1200
    local function consider(obj, kind)
        if not obj or not kind then return end
        if S.EspBoulderKinds and S.EspBoulderKinds[kind] == false then return end
        if isCrystal(obj) or isRune(obj) then return end
        local part = getPart(obj)
        if not part then return end
        local dist = my and (part.Position - my.Position).Magnitude or 0
        if dist > maxb then return end
        local key = kind .. ":" .. math.floor(part.Position.X / 8) .. ":" .. math.floor(part.Position.Y / 8) .. ":" .. math.floor(part.Position.Z / 8)
        if seen[key] then return end
        seen[key] = true
        table.insert(out, { obj = obj, kind = kind, dist = dist })
    end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") or d:IsA("BasePart") or d:IsA("MeshPart") then
            local kind = matchBoulderKind(d.Name)
            if kind then consider(d, kind) end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

local function createPlayerESP(plr)
    if not plr or plr == player then return end
    local char = plr.Character
    if not char then return end
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    local root = char:FindFirstChild("HumanoidRootPart") or head
    if not head then return end
    local my = getHRP()
    local dist = "?"
    if my and root then
        dist = string.format("%.0fm", (root.Position - my.Position).Magnitude)
    end
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 150, 0, 36)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.Adornee = head
    bb.Parent = ESPFolder
    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1, 0, 1, 0)
    lab.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    lab.BackgroundTransparency = 0.35
    lab.Text = string.format("%s\n%s", plr.DisplayName or plr.Name, dist)
    lab.TextColor3 = Color3.fromRGB(255, 120, 120)
    lab.Font = Enum.Font.GothamBold
    lab.TextSize = 11
    lab.Parent = bb
    Instance.new("UICorner", lab).CornerRadius = UDim.new(0, 4)
    pcall(function()
        local hl = Instance.new("Highlight")
        hl.FillTransparency = 0.75
        hl.OutlineColor = Color3.fromRGB(255, 80, 80)
        hl.FillColor = Color3.fromRGB(255, 60, 60)
        hl.Parent = char
        hl.Name = "ACPlayerHL"
        local link = Instance.new("ObjectValue")
        link.Name = "HLLink"
        link.Value = hl
        link.Parent = bb
    end)
end

local function refreshESP()
    -- clear highlights linked
    for _, ch in ipairs(ESPFolder:GetChildren()) do
        local link = ch:FindFirstChild("HLLink")
        if link and link:IsA("ObjectValue") and link.Value then
            pcall(function() link.Value:Destroy() end)
        end
    end
    clearESP()
    local hrp = getHRP()
    if not hrp then return end
    local maxd = tonumber(S.EspMaxDist) or 400

    if S.ESP then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if (obj:IsA("Model") or obj:IsA("BasePart")) and isCrystal(obj) and meetsESP(obj) then
                if obj:IsA("Tool") and obj.Parent and (obj.Parent:IsA("Backpack") or Players:GetPlayerFromCharacter(obj.Parent)) then
                    -- skip bag
                elseif isOnPlot(obj) then
                    -- skip plot crystal
                else
                    local pos = getWorldPos(obj)
                    if pos and (pos - hrp.Position).Magnitude <= maxd then
                        createESP(obj)
                    end
                end
            end
        end
    end

    if S.EspPlayer then
        for _, plr in ipairs(Players:GetPlayers()) do
            createPlayerESP(plr)
        end
    end

    if S.EspBoulder then
        local ok, list = pcall(collectBoulders)
        if ok and list then
            local maxShow, maxHL = 40, 12
            for i, it in ipairs(list) do
                if i > maxShow then break end
                pcall(createBoulderESP, it.obj, it.kind, i <= maxHL)
            end
        end
    end
end

local function groundY(x, z, preferY)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local filter = {}
    if player.Character then table.insert(filter, player.Character) end
    params.FilterDescendantsInstances = filter
    -- beberapa ray dari ketinggian berbeda
    local best = nil
    for _, startY in ipairs({preferY and (preferY + 120) or 500, 300, 150, 80}) do
        local origin = Vector3.new(x, startY, z)
        local hit = Workspace:Raycast(origin, Vector3.new(0, -startY - 50, 0), params)
        if hit then
            if not best or hit.Position.Y > best then
                best = hit.Position.Y
            end
        end
    end
    return best
end

local function tpTo(cf)
    local h = getHRP()
    if not h then return end
    local target = typeof(cf) == "CFrame" and cf or CFrame.new(cf)
    local pos = target.Position
    local gy = groundY(pos.X, pos.Z, pos.Y)
    local y = gy and (gy + 3.5) or (pos.Y + 6)
    -- jangan turun terlalu jauh dari target (crystal di lereng)
    if gy and pos.Y > gy + 2 then
        y = math.max(gy + 3.5, pos.Y)
        -- clamp: jika target sudah di atas tanah, sedikit di atas target
        local gy2 = groundY(pos.X, pos.Z, pos.Y + 20)
        if gy2 then y = gy2 + 3.5 end
    end
    pcall(function()
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end)
    h.AssemblyLinearVelocity = Vector3.zero
    h.CFrame = CFrame.new(pos.X, y, pos.Z)
    task.defer(function()
        local h2 = getHRP()
        if not h2 then return end
        h2.AssemblyLinearVelocity = Vector3.zero
        local gy3 = groundY(h2.Position.X, h2.Position.Z, h2.Position.Y)
        if gy3 and h2.Position.Y < gy3 - 1 then
            h2.CFrame = CFrame.new(h2.Position.X, gy3 + 3.5, h2.Position.Z)
        end
    end)
end

local function tpSafePos(pos)
    tpTo(CFrame.new(pos))
end

local function findBest(mode)
    local best, sc = nil, -1
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Tool")) and isLootableWorldCrystal(obj) then
            -- TP top: jangan pakai filter collect ketat, ambil stats tertinggi di world
            local s = 0
            if mode == "luck" then s = luck(obj)
            elseif mode == "berat" then s = berat(obj)
            else s = coin(obj) end
            if s > sc then
                local pos = getWorldPos(obj)
                if pos then
                    sc, best = s, obj
                end
            end
        end
    end
    return best, sc
end


local function tpPeak()
    local bestY, bestPos = -math.huge, nil
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local full = string.lower(d:GetFullName())
            if full:find("plot", 1, true) or full:find("base", 1, true)
                or full:find("tycoon", 1, true) or full:find("spawn", 1, true)
                or full:find("water", 1, true) then
                -- skip
            else
                local top = d.Position.Y + d.Size.Y * 0.5
                local n = string.lower(d.Name)
                local score = top
                if n:find("peak", 1, true) or n:find("summit", 1, true) or n:find("puncak", 1, true)
                    or n:find("mountain", 1, true) or n:find("gunung", 1, true)
                    or n:find("tip", 1, true) or n:find("top", 1, true) then
                    score = score + 80
                end
                if d.CanCollide and score > bestY and top > 40 then
                    bestY = score
                    bestPos = Vector3.new(d.Position.X, top + 6, d.Position.Z)
                end
            end
        end
    end
    -- terrain sample grid around map center if parts weak
    if bestPos then
        local gx, gz = bestPos.X, bestPos.Z
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        if player.Character then params.FilterDescendantsInstances = {player.Character} end
        local high = bestPos.Y
        for dx = -80, 80, 20 do
            for dz = -80, 80, 20 do
                local hit = Workspace:Raycast(Vector3.new(gx+dx, high + 200, gz+dz), Vector3.new(0, -600, 0), params)
                if hit and hit.Position.Y > high then
                    high = hit.Position.Y
                    bestPos = Vector3.new(hit.Position.X, hit.Position.Y + 5, hit.Position.Z)
                end
            end
        end
        tpSafePos(bestPos)
        notify(string.format("TP Puncak Y=%.0f", bestPos.Y))
    else
        local h = getHRP()
        if h then
            tpSafePos(h.Position + Vector3.new(0, 250, 0))
            notify("TP naik (scan peak gagal)")
        end
    end
end

local function tpTop(mode)
    local best, sc = findBest(mode)
    if not best then
        notify("Tidak ada crystal di map")
        return
    end
    local pos = getWorldPos(best)
    if not pos then
        notify("Posisi crystal invalid")
        return
    end
    tpSafePos(pos + Vector3.new(0, 3, 0))
    notify(string.format("TP Top %s = %s (%s)", mode, fmt(sc), best.Name))
end

local function isFav(tool)
    if not tool then return false end
    if getAttr(tool, "Favorited") == true or getAttr(tool, "Favorite") == true then return true end
    return tool:FindFirstChild("Favorite") ~= nil or tool:FindFirstChild("Favorited") ~= nil
end

local function setFav(tool, on)
    if not tool then return end
    if Remotes.Favorite then
        pcall(function()
            if Remotes.Favorite:IsA("RemoteEvent") then Remotes.Favorite:FireServer(tool, on)
            else Remotes.Favorite:InvokeServer(tool, on) end
        end)
    end
    pcall(function() tool:SetAttribute("Favorited", on and true or false) end)
end

local function favTick()
    if not S.AutoFavorite then return end
    local bags = {}
    if player:FindFirstChild("Backpack") then table.insert(bags, player.Backpack) end
    if player.Character then table.insert(bags, player.Character) end
    local minScore = tonumber(S.FavMin) or 0
    for _, bag in ipairs(bags) do
        for _, tool in ipairs(bag:GetChildren()) do
            if tool:IsA("Tool") and isCrystal(tool) and not isFav(tool) then
                local score = 0
                if S.FavMode == "luck" then
                    score = luck(tool)
                elseif S.FavMode == "berat" then
                    score = berat(tool)
                else
                    score = coin(tool)
                end
                if type(score) == "number" and score >= minScore then
                    setFav(tool, true)
                end
            end
        end
    end
end

local function unfavAll()
    local n = 0
    local bags = {}
    if player:FindFirstChild("Backpack") then table.insert(bags, player.Backpack) end
    if player.Character then table.insert(bags, player.Character) end
    for _, bag in ipairs(bags) do
        for _, tool in ipairs(bag:GetChildren()) do
            if tool:IsA("Tool") and isFav(tool) then setFav(tool, false) n = n + 1 end
        end
    end
    notify("Unfav " .. n)
end

local function findSellRemote()
    if Remotes.Sell and Remotes.Sell.Parent then return Remotes.Sell end
    local names = {
        "SellRequest", "Sell", "SellAll", "SellCrystals", "SellCrystal",
        "RequestSell", "CrystalSell", "SellGems", "SellItems",
    }
    for _, nm in ipairs(names) do
        local r = deepFind(ReplicatedStorage, nm)
        if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
            Remotes.Sell = r
            return r
        end
    end
    return nil
end

local function sellAll()
    local okAny = false
    local remote = findSellRemote()
    if remote then
        local payloads = { {}, {"all"}, {true}, {"Crystal"}, {"Crystals"} }
        for _, args in ipairs(payloads) do
            local ok = pcall(function()
                if remote:IsA("RemoteEvent") then
                    if #args == 0 then remote:FireServer()
                    else remote:FireServer(table.unpack(args)) end
                else
                    if #args == 0 then remote:InvokeServer()
                    else remote:InvokeServer(table.unpack(args)) end
                end
            end)
            if ok then okAny = true end
        end
    end
    -- prompt sell / toko
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local n = string.lower(tostring(d.Name) .. " " .. tostring(d.ActionText) .. " " .. tostring(d.ObjectText) .. " " .. tostring(d.Parent and d.Parent.Name or ""))
            if n:find("sell", 1, true) or n:find("jual", 1, true) or n:find("toko", 1, true) then
                firePrompt(d)
                okAny = true
            end
        end
    end
    if okAny then notify("Sell dikirim")
    else notify("Sell remote tidak ketemu") end
end

local function scanInv()
    local list = {}
    local bags = {}
    if player:FindFirstChild("Backpack") then table.insert(bags, player.Backpack) end
    if player.Character then table.insert(bags, player.Character) end
    for _, bag in ipairs(bags) do
        for _, tool in ipairs(bag:GetChildren()) do
            if tool:IsA("Tool") and isCrystal(tool) then table.insert(list, tool) end
        end
    end
    return list
end


local function findDropRemote()
    local g = ReplicatedStorage:FindFirstChild("GemSignals")
    if g then
        local r = g:FindFirstChild("DropCrystal") or g:FindFirstChild("DropGem")
        if r then
            Remotes.DropCrystal = r
            return r
        end
    end
    if Remotes.DropCrystal and Remotes.DropCrystal.Parent then
        return Remotes.DropCrystal
    end
    return nil
end

-- Drop via remote saja (bukan visual parent ke Workspace)
-- Cobalt: GemSignals.DropCrystal:FireServer(1)
local function dropTool(tool, qty)
    qty = math.max(1, math.floor(tonumber(qty) or 1))
    local remote = findDropRemote()
    if not remote then
        notify("DropCrystal remote tidak ketemu")
        return 0
    end
    local dropped = 0
    local hum = getHum()
    for i = 1, qty do
        pcall(function()
            if tool and tool.Parent and hum then
                hum:UnequipTools()
                tool.Parent = player.Character
            end
        end)
        task.wait(0.03)
        local ok = pcall(function()
            remote:FireServer(1)
        end)
        if ok then dropped = dropped + 1 end
        task.wait(0.05)
    end
    return dropped
end

local function dropAll()
    local tools = scanInv()
    if #tools == 0 then notify("Tas kosong") return 0 end
    local remote = findDropRemote()
    if not remote then
        notify("DropCrystal remote tidak ketemu")
        return 0
    end
    local copy = {}
    for _, tool in ipairs(tools) do table.insert(copy, tool) end
    local n = #copy
    local hum = getHum()
    if hum then pcall(function() hum:UnequipTools() end) end

    -- fire remote untuk setiap crystal (bukan drop visual)
    for _, tool in ipairs(copy) do
        if tool and tool.Parent then
            pcall(function()
                if isFav(tool) then setFav(tool, false) end
            end)
            pcall(function()
                if hum and player.Character then
                    tool.Parent = player.Character
                end
            end)
            pcall(function()
                remote:FireServer(1)
            end)
        end
    end
    -- spam sisa kalau masih ada di tas
    task.wait(0.05)
    local left = scanInv()
    for _ = 1, #left do
        pcall(function() remote:FireServer(1) end)
    end

    notify("Drop All: " .. tostring(n))
    return n
end

-- ===== MOVE =====
local speedConn, jumpConn, antiConn, kbConn
local function setSpeed(on)
    S.speedOn = on and true or false
    if speedConn then pcall(function() speedConn:Disconnect() end) speedConn = nil end
    if S.speedOn then
        local acc = 0
        speedConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
            acc = acc + dt
            if acc < 0.25 then return end
            acc = 0
            local h = getHum()
            if h and math.abs(h.WalkSpeed - (S.speed or 28)) > 0.5 then
                pcall(function() h.WalkSpeed = S.speed or 28 end)
            end
        end)
        local h = getHum()
        if h then pcall(function() h.WalkSpeed = S.speed or 28 end) end
        notify("Speed " .. tostring(S.speed or 28))
    else
        local h = getHum()
        if h then pcall(function() h.WalkSpeed = 16 end) end
        notify("Speed OFF")
    end
end

local function setInfJump(on)
    S.infJump = on and true or false
    if jumpConn then pcall(function() jumpConn:Disconnect() end) jumpConn = nil end
    if S.infJump then
        jumpConn = UIS.JumpRequest:Connect(function()
            local h = getHum()
            if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
        end)
        notify("Inf Jump ON")
    else
        notify("Inf Jump OFF")
    end
end

local function ragdollRemote(disable)
    -- game Mine Antarctica: PlayerGui.ragdoll
    pcall(function()
        local gui = player:FindFirstChild("PlayerGui")
        local rag = gui and gui:FindFirstChild("ragdoll")
        if not rag then return end
        local ev = rag:FindFirstChild("events") and rag.events:FindFirstChild("variableserver")
        if ev then
            -- true = ragdoll on di game; kirim false untuk anti
            ev:FireServer("ragdoll", not disable and true or false)
        end
        local fn = rag:FindFirstChild("functions") and rag.functions:FindFirstChild("remoteragdoll")
        if fn and typeof(getcallbackvalue) == "function" then
            pcall(function()
                local cb = getcallbackvalue(fn, "OnClientInvoke")
                if cb then cb(not disable, nil) end
            end)
        end
    end)
end

local function setAntiRagdoll(on)
    on = false -- fitur dihapus
    S.antiRagdoll = false
    if antiConn then pcall(function() antiConn:Disconnect() end) antiConn = nil end
    if S.antiRagdoll then
        ragdollRemote(true)
        local lastRemote = 0
        antiConn = game:GetService("RunService").Heartbeat:Connect(function()
            local h = getHum()
            if not h then return end
            pcall(function()
                if h.PlatformStand then h.PlatformStand = false end
                local st = h:GetState()
                if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown
                    or st == Enum.HumanoidStateType.Physics then
                    h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    h:ChangeState(Enum.HumanoidStateType.GettingUp)
                    task.defer(function()
                        if getHum() then getHum():ChangeState(Enum.HumanoidStateType.Running) end
                    end)
                end
            end)
            local now = os.clock()
            if now - lastRemote > 2.5 then
                lastRemote = now
                ragdollRemote(true)
            end
        end)
        notify("Anti Ragdoll ON")
    else
        notify("Anti Ragdoll OFF")
    end
end

local fallConn
local function setNoFall(on)
    S.noFall = on and true or false
    if fallConn then pcall(function() fallConn:Disconnect() end) fallConn = nil end
    if S.noFall then
        fallConn = game:GetService("RunService").Heartbeat:Connect(function()
            local h = getHum()
            local root = getHRP()
            if not h then return end
            pcall(function()
                h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                -- batasi velocity jatuh
                if root and root.AssemblyLinearVelocity.Y < -80 then
                    root.AssemblyLinearVelocity = Vector3.new(
                        root.AssemblyLinearVelocity.X,
                        -40,
                        root.AssemblyLinearVelocity.Z
                    )
                end
                -- no health drop from fall: restore if sudden damage while falling
            end)
        end)
        -- Humanoid health protect light
        local h = getHum()
        if h then
            pcall(function()
                h.StateChanged:Connect(function(_, new)
                    if not S.noFall then return end
                    if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Freefall then
                        -- nothing
                    end
                end)
            end)
        end
        notify("No Fall ON")
    else
        notify("No Fall OFF")
    end
end

local function setAntiKB(on)
    S.antiKB = on and true or false
    if kbConn then pcall(function() kbConn:Disconnect() end) kbConn = nil end
    if S.antiKB then
        local lastPos = nil
        local acc = 0
        kbConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
            acc = acc + dt
            if acc < 0.2 then return end
            acc = 0
            local root = getHRP()
            if not root then return end
            for _, ch in ipairs(root:GetChildren()) do
                if ch:IsA("BodyVelocity") or ch:IsA("BodyForce") or ch:IsA("LinearVelocity")
                    or ch:IsA("VectorForce") or ch:IsA("BodyAngularVelocity") then
                    pcall(function() ch:Destroy() end)
                end
            end
            local v = root.AssemblyLinearVelocity
            local horiz = Vector3.new(v.X, 0, v.Z)
            if horiz.Magnitude > 90 then
                root.AssemblyLinearVelocity = horiz.Unit * 40 + Vector3.new(0, v.Y, 0)
            end
        end)
        notify("Anti Knockback ON")
    else
        notify("Anti Knockback OFF")
    end
end

player.CharacterAdded:Connect(function(c)
    task.wait(0.4)
    if S.speedOn then setSpeed(true) end
    if S.antiRagdoll then setAntiRagdoll(true) end
    if S.noFall then setNoFall(true) end
    if S.antiKB then setAntiKB(true) end
    if S.infJump then setInfJump(true) end
end)



-- ===== SHOP (UpgradeRemotes) =====
local function buyUpgrade(kind, amount)
    local ok = pcall(function()
        local rem = ReplicatedStorage:FindFirstChild("UpgradeRemotes")
        local buy = rem and rem:FindFirstChild("BuyUpgrade")
        if buy then
            buy:FireServer(kind, amount)
        end
    end)
    return ok
end

local function setAutoWarmth(on)
    S.autoWarmth = on and true or false
    if S._warmthThread then return end
    if not S.autoWarmth then return end
    S._warmthThread = true
    task.spawn(function()
        while S.autoWarmth do
            local amt = S.warmthAmount or 10
            if amt == "max" or amt == 999 then
                for _, a in ipairs({100, 50, 10}) do buyUpgrade("warmth", a) end
            else
                buyUpgrade("warmth", tonumber(amt) or 10)
            end
            task.wait(0.35)
        end
        S._warmthThread = false
    end)
end

local function setAutoCarry(on)
    S.autoCarry = on and true or false
    if S._carryThread then return end
    if not S.autoCarry then return end
    S._carryThread = true
    task.spawn(function()
        while S.autoCarry do
            local amt = S.carryAmount or 1
            if amt == "max" or amt == 999 then
                for _, a in ipairs({10, 5, 1}) do buyUpgrade("carry", a) end
            else
                buyUpgrade("carry", tonumber(amt) or 1)
            end
            task.wait(0.35)
        end
        S._carryThread = false
    end)
end

local function openBombShop()
    pcall(function()
        local rem = ReplicatedStorage:FindFirstChild("BombRemotes")
        local open = rem and rem:FindFirstChild("OpenShop")
        if open and firesignal then
            firesignal(open.OnClientEvent)
        elseif open then
            -- fallback
            open:FireServer()
        end
        notify("Open Boom Shop")
    end)
end

-- ===== CONFIG SAVE / LOAD =====
local CONFIG_KEY = "VannHUB_MaA_Config_v1"
local function collectConfig()
    return {
        AutoCollect = S.AutoCollect,
        InstantPrompt = S.InstantPrompt,
        AutoSell = S.AutoSell,
        SellInterval = S.SellInterval,
        CollectRadius = S.CollectRadius,
        MinLuck = S.MinLuck,
        MinCoin = S.MinCoin,
        MinBerat = S.MinBerat,
        Rarity = S.Rarity,
        EspRarity = S.EspRarity,
        EspMinLuck = S.EspMinLuck,
        EspMinCoin = S.EspMinCoin,
        EspMinBerat = S.EspMinBerat,
        EspMaxDist = S.EspMaxDist,
        BoulderMaxDist = S.BoulderMaxDist,
        speed = S.speed,
        speedOn = S.speedOn,
        infJump = S.infJump,
        antiRagdoll = S.antiRagdoll,
        noFall = S.noFall,
        antiKB = S.antiKB,
        antiAFK = S.antiAFK,
        autoReconnect = S.autoReconnect,
        warmthAmount = S.warmthAmount,
        carryAmount = S.carryAmount,
        FavMin = S.FavMin,
        FavMode = S.FavMode,
    }
end

local function applyConfig(cfg)
    if type(cfg) ~= "table" then return end
    for k, v in pairs(cfg) do
        if S[k] ~= nil then S[k] = v end
    end
    if S.speedOn then pcall(setSpeed, true) end
    if S.infJump then pcall(setInfJump, true) end
    if S.antiRagdoll then pcall(setAntiRagdoll, true) end
    if S.noFall then pcall(setNoFall, true) end
    if S.antiKB then pcall(setAntiKB, true) end
    task.defer(function()
        if refreshAllToggles then pcall(refreshAllToggles) end
    end)
end

local function saveConfig()
    local ok = pcall(function()
        if writefile and isfolder and makefolder then
            if not isfolder("VannHUB") then makefolder("VannHUB") end
            writefile("VannHUB/config.json", game:GetService("HttpService"):JSONEncode(collectConfig()))
        end
        pcall(function()
            local hs = game:GetService("HttpService")
            if setclipboard then end
        end)
    end)
    -- also player attributes backup
    pcall(function()
        player:SetAttribute("VannHUB_CFG", game:GetService("HttpService"):JSONEncode(collectConfig()))
    end)
    notify(ok and "Config disimpan" or "Config save (attribute)")
end

local function loadConfig()
    local cfg
    pcall(function()
        if readfile and isfile and isfile("VannHUB/config.json") then
            cfg = game:GetService("HttpService"):JSONDecode(readfile("VannHUB/config.json"))
        end
    end)
    if not cfg then
        pcall(function()
            local raw = player:GetAttribute("VannHUB_CFG")
            if raw then cfg = game:GetService("HttpService"):JSONDecode(raw) end
        end)
    end
    if cfg then
        applyConfig(cfg)
        notify("Config diload")
        return true
    end
    notify("Config tidak ada")
    return false
end

-- Anti AFK
task.spawn(function()
    local vu = game:GetService("VirtualUser")
    player.Idled:Connect(function()
        if not S.antiAFK then return end
        pcall(function()
            vu:CaptureController()
            vu:ClickButton2(Vector3.new())
        end)
    end)
end)

-- Auto Reconnect (lebih agresif)
task.spawn(function()
    local GuiService = game:GetService("GuiService")
    local TeleportService = game:GetService("TeleportService")
    local function doRejoin(reason)
        if not S.autoReconnect then return end
        notify("Reconnect: " .. tostring(reason))
        task.wait(1.5)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)
        task.delay(3, function()
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
            end)
        end)
    end
    pcall(function()
        GuiService.ErrorMessageChanged:Connect(function(msg)
            if msg and #tostring(msg) > 0 then doRejoin(msg) end
        end)
    end)
    -- CoreGui disconnect prompts
    pcall(function()
        local cg = game:GetService("CoreGui")
        cg.ChildAdded:Connect(function(ch)
            task.wait(0.3)
            local n = string.lower(ch.Name)
            if n:find("error", 1, true) or n:find("disconnect", 1, true) or n:find("prompt", 1, true) then
                if S.autoReconnect then doRejoin(ch.Name) end
            end
        end)
    end)
    -- network
    pcall(function()
        game:GetService("NetworkClient").ChildRemoved:Connect(function()
            doRejoin("network")
        end)
    end)
end)



-- ===== GFX / ANTI LAG =====
local Lighting = game:GetService("Lighting")
local gfxConns = {}
local gfxSaved = {}
local whiteFrame, blackFrame

local function gfxSaveLighting()
    if gfxSaved.ok then return end
    pcall(function()
        gfxSaved = {
            ok = true,
            Brightness = Lighting.Brightness,
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            Technology = Lighting.Technology,
            EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
            ClockTime = Lighting.ClockTime,
        }
    end)
end

local function setFlat(on)
    S.gfxFlat = on and true or false
    gfxSaveLighting()
    pcall(function()
        if S.gfxFlat then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            Lighting.GlobalShadows = false
            Lighting.Brightness = 2
            Lighting.FogEnd = 1e6
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
            pcall(function() Lighting.Technology = Enum.Technology.Legacy end)
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    pcall(function()
                        v.Material = Enum.Material.SmoothPlastic
                        v.Reflectance = 0
                        v.CastShadow = false
                    end)
                elseif v:IsA("Texture") or v:IsA("Decal") then
                    pcall(function() v.Transparency = 1 end)
                end
            end
        else
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            if gfxSaved.ok then
                Lighting.GlobalShadows = gfxSaved.GlobalShadows
                Lighting.Brightness = gfxSaved.Brightness
                Lighting.FogEnd = gfxSaved.FogEnd
                Lighting.EnvironmentDiffuseScale = gfxSaved.EnvironmentDiffuseScale
                Lighting.EnvironmentSpecularScale = gfxSaved.EnvironmentSpecularScale
            end
        end
    end)
    notify(S.gfxFlat and "GFX Flat ON" or "GFX Flat OFF")
end

local function stripEffects(root)
    if not root then return end
    for _, v in ipairs(root:GetDescendants()) do
        pcall(function()
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam")
                or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles")
                or v:IsA("Explosion") then
                v.Enabled = false
                v:Destroy()
            elseif v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect")
                or v:IsA("ColorCorrectionEffect") or v:IsA("DepthOfFieldEffect")
                or v:IsA("Atmosphere") or v:IsA("Clouds") then
                v:Destroy()
            elseif v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
                v.Enabled = false
            end
        end)
    end
end

local function setAntiLag(on)
    S.gfxAntiLag = on and true or false
    if gfxConns.antiLag then pcall(function() gfxConns.antiLag:Disconnect() end) gfxConns.antiLag = nil end
    if S.gfxAntiLag then
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            Lighting.GlobalShadows = false
            stripEffects(Workspace)
            stripEffects(Lighting)
        end)
        gfxConns.antiLag = Workspace.DescendantAdded:Connect(function(v)
            if not S.gfxAntiLag then return end
            pcall(function()
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam")
                    or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                    v.Enabled = false
                    task.defer(function() pcall(function() v:Destroy() end) end)
                end
            end)
        end)
        notify("Anti Lag ON")
    else
        notify("Anti Lag OFF")
    end
end

local function setHideEffects(on)
    S.gfxHideEffects = on and true or false
    if S.gfxHideEffects then
        stripEffects(Workspace)
        stripEffects(Lighting)
        notify("Hide Effects ON")
    else
        notify("Hide Effects OFF")
    end
end

local function hideChar(char, hide)
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function()
                p.LocalTransparencyModifier = hide and 1 or 0
            end)
        elseif p:IsA("Decal") or p:IsA("Texture") then
            pcall(function() p.Transparency = hide and 1 or 0 end)
        elseif p:IsA("ParticleEmitter") or p:IsA("Trail") or p:IsA("Beam") then
            pcall(function() p.Enabled = not hide end)
        elseif p:IsA("BillboardGui") or p:IsA("SurfaceGui") then
            pcall(function() p.Enabled = not hide end)
        end
    end
end

local function setHidePlayers(on)
    S.gfxHidePlayers = on and true or false
    if gfxConns.hidePlr then pcall(function() gfxConns.hidePlr:Disconnect() end) gfxConns.hidePlr = nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            hideChar(plr.Character, S.gfxHidePlayers)
        end
    end
    if S.gfxHidePlayers then
        gfxConns.hidePlr = Players.PlayerAdded:Connect(function(plr)
            plr.CharacterAdded:Connect(function(c)
                if S.gfxHidePlayers and plr ~= player then
                    task.wait(0.3)
                    hideChar(c, true)
                end
            end)
        end)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                plr.CharacterAdded:Connect(function(c)
                    if S.gfxHidePlayers then task.wait(0.3) hideChar(c, true) end
                end)
            end
        end
        notify("Hide Players ON")
    else
        notify("Hide Players OFF")
    end
end

local GfxGui
local function ensureGfx()
    if GfxGui and GfxGui.Parent then return GfxGui end
    GfxGui = Instance.new("ScreenGui")
    GfxGui.Name = "VannGFX"
    GfxGui.ResetOnSpawn = false
    GfxGui.IgnoreGuiInset = true
    GfxGui.DisplayOrder = 1
    GfxGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local ok = pcall(function() GfxGui.Parent = CoreGui end)
    if not ok or not GfxGui.Parent then
        pcall(function() GfxGui.Parent = player:WaitForChild("PlayerGui") end)
    end
    return GfxGui
end
local function screenFrame(name, color)
    local gui = ensureGfx()
    if not gui then return nil end
    local fr = gui:FindFirstChild(name)
    if not fr then
        fr = Instance.new("Frame")
        fr.Name = name
        fr.Size = UDim2.fromScale(1, 1)
        fr.BackgroundColor3 = color
        fr.BorderSizePixel = 0
        fr.Visible = false
        fr.Active = false
        fr.Parent = gui
    end
    return fr
end
local function setWhiteScreen(on)
    S.gfxWhite = on and true or false
    if S.gfxWhite then S.gfxBlack = false end
    local w = screenFrame("White", Color3.new(1,1,1))
    local b = screenFrame("Black", Color3.new(0,0,0))
    if w then w.Visible = S.gfxWhite end
    if b then b.Visible = false end
    notify(S.gfxWhite and "White Screen ON" or "White Screen OFF")
end
local function setBlackScreen(on)
    S.gfxBlack = on and true or false
    if S.gfxBlack then S.gfxWhite = false end
    local w = screenFrame("White", Color3.new(1,1,1))
    local b = screenFrame("Black", Color3.new(0,0,0))
    if b then b.Visible = S.gfxBlack end
    if w then w.Visible = false end
    notify(S.gfxBlack and "Black Screen ON" or "Black Screen OFF")
end


-- ========== UI SIMPLE ==========
pcall(function()
    for _, n in ipairs({"VannHUB", "AutoCrystalFull", "ACHub"}) do
        local o = CoreGui:FindFirstChild(n)
        if o then o:Destroy() end
        local pg = player:FindFirstChild("PlayerGui")
        if pg and pg:FindFirstChild(n) then pg[n]:Destroy() end
    end
end)

local SG = Instance.new("ScreenGui")
SG.Name = "VannHUB"
SG.ResetOnSpawn = false
SG.DisplayOrder = 80
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() SG.Parent = CoreGui end)
if not SG.Parent then SG.Parent = player:WaitForChild("PlayerGui") end

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(560, 430)
Main.Position = UDim2.new(0.5, -280, 0.5, -215)
Main.BackgroundColor3 = BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.Parent = SG
Main.ZIndex = 200
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local st = Instance.new("UIStroke")
st.Color = Color3.fromRGB(255, 176, 72)
st.Thickness = 1
st.Parent = Main

-- drag digeser ke title bar saja (hindari conflict scroll tab)

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 44)
Top.BackgroundColor3 = SIDE
Top.BorderSizePixel = 0
Top.Parent = Main
Instance.new("UICorner", Top).CornerRadius = UDim.new(0, 14)

-- drag HANYA dari title bar (scroll tab tidak geser UI)
do
    local drag, start, spos
    Top.InputBegan:Connect(function(i)
        if S.uiLocked then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; start = i.Position; spos = Main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if S.uiLocked or not drag then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - start
            Main.Position = UDim2.new(spos.X.Scale, spos.X.Offset + d.X, spos.Y.Scale, spos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

-- resize (pojok kanan bawah)
local grip = Instance.new("TextButton")
grip.Name = "ResizeGrip"
grip.Size = UDim2.fromOffset(26, 26)
grip.Position = UDim2.new(1, -28, 1, -28)
grip.BackgroundColor3 = ACC
grip.Text = "⇲"
grip.TextColor3 = Color3.fromRGB(15, 20, 30)
grip.Font = Enum.Font.GothamBold
grip.TextSize = 15
grip.ZIndex = 30
grip.Parent = Main
Instance.new("UICorner", grip).CornerRadius = UDim.new(0, 7)
do
    local resizing, rstart, rsize
    grip.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            rstart = i.Position
            rsize = Main.AbsoluteSize
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not resizing then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - rstart
            local w = math.clamp(rsize.X + d.X, 360, 620)
            local h = math.clamp(rsize.Y + d.Y, 380, 640)
            Main.Size = UDim2.fromOffset(w, h)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            resizing = false
        end
    end)
end

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 1, 0)
Title.Position = UDim2.fromOffset(14, 0)
Title.BackgroundTransparency = 1
Title.Text = "VannHUB"
Title.TextColor3 = TXT
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

local LockBtn = Instance.new("TextButton")
LockBtn.Size = UDim2.fromOffset(32, 32)
LockBtn.Position = UDim2.new(1, -76, 0, 6)
LockBtn.BackgroundColor3 = CARD
LockBtn.Text = "🔓"
LockBtn.TextColor3 = TXT
LockBtn.Font = Enum.Font.GothamBold
LockBtn.TextSize = 14
LockBtn.Parent = Top
Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(0, 8)
LockBtn.MouseButton1Click:Connect(function()
    S.uiLocked = not S.uiLocked
    LockBtn.Text = S.uiLocked and "🔒" or "🔓"
    LockBtn.BackgroundColor3 = S.uiLocked and GRN or CARD
    notify(S.uiLocked and "UI Locked" or "UI Unlocked")
end)

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(32, 32)
Close.Position = UDim2.new(1, -38, 0, 6)
Close.BackgroundColor3 = RED
Close.Text = "X"
Close.TextColor3 = TXT
Close.Font = Enum.Font.GothamBold
Close.TextSize = 13
Close.Parent = Top
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

local Open = Instance.new("TextButton")
Open.Size = UDim2.fromOffset(54, 54)
Open.Position = UDim2.fromOffset(14, 14)
Open.BackgroundColor3 = Color3.fromRGB(20, 28, 48)
Open.Text = ""
Open.Visible = false
Open.ZIndex = 50
Open.Parent = SG
Instance.new("UICorner", Open).CornerRadius = UDim.new(1, 0) -- bulat
local openStroke = Instance.new("UIStroke")
openStroke.Color = ACC
openStroke.Thickness = 2
openStroke.Parent = Open
-- badge VNHB
local openGrad = Instance.new("Frame")
openGrad.Size = UDim2.new(1, -8, 1, -8)
openGrad.Position = UDim2.fromOffset(4, 4)
openGrad.BackgroundColor3 = Color3.fromRGB(196, 130, 48)
openGrad.BorderSizePixel = 0
openGrad.ZIndex = 51
openGrad.Parent = Open
Instance.new("UICorner", openGrad).CornerRadius = UDim.new(1, 0)
local openLbl = Instance.new("TextLabel")
openLbl.Size = UDim2.new(1, 0, 1, 0)
openLbl.BackgroundTransparency = 1
openLbl.Text = "VH"
openLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
openLbl.Font = Enum.Font.GothamBlack
openLbl.TextSize = 16
openLbl.ZIndex = 52
openLbl.Parent = openGrad
local openSub = Instance.new("TextLabel")
openSub.Size = UDim2.new(1, 0, 0, 12)
openSub.Position = UDim2.new(0, 0, 1, -14)
openSub.BackgroundTransparency = 1
openSub.Text = "VNHB"
openSub.TextColor3 = Color3.fromRGB(220, 235, 255)
openSub.Font = Enum.Font.GothamBold
openSub.TextSize = 8
openSub.ZIndex = 52
openSub.Parent = openGrad
-- drag floating icon
do
    local d, st, sp
    Open.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            d = true; st = i.Position; sp = Open.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - st
            Open.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then d = false end
    end)
end
local function hideHub()
    tw(Main, 0.16, { BackgroundTransparency = 0.35 })
    task.delay(0.14, function()
        Main.Visible = false
        Main.BackgroundTransparency = 0
        Open.Visible = true
        Open.Size = UDim2.fromOffset(40, 40)
        tw(Open, 0.18, { Size = UDim2.fromOffset(54, 54) })
    end)
end
local function showHub()
    Open.Visible = false
    Main.Visible = true
    local target = Main.Size
    Main.Size = UDim2.fromOffset(math.max(target.X.Offset - 30, 300), math.max(target.Y.Offset - 40, 280))
    tw(Main, 0.2, { Size = target })
end
Close.MouseButton1Click:Connect(hideHub)
Open.MouseButton1Click:Connect(showHub)

-- tabs
local Side = Instance.new("Frame")
Side.Name = "Sidebar"
Side.Size = UDim2.new(0, 118, 1, -52)
Side.Position = UDim2.fromOffset(0, 44)
Side.BackgroundColor3 = SIDE
Side.BorderSizePixel = 0
Side.Parent = Main
local sideLine = Instance.new("Frame")
sideLine.Size = UDim2.new(0, 1, 1, 0)
sideLine.Position = UDim2.new(1, -1, 0, 0)
sideLine.BackgroundColor3 = Color3.fromRGB(70, 56, 36)
sideLine.BorderSizePixel = 0
sideLine.Parent = Side

local TabBar = Instance.new("ScrollingFrame")
TabBar.Size = UDim2.new(1, -10, 1, -12)
TabBar.Position = UDim2.fromOffset(6, 8)
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel = 0
TabBar.ScrollBarThickness = 2
TabBar.ScrollBarImageColor3 = ACC
TabBar.ScrollingDirection = Enum.ScrollingDirection.Y
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.Parent = Side
local tabLay = Instance.new("UIListLayout")
tabLay.FillDirection = Enum.FillDirection.Vertical
tabLay.Padding = UDim.new(0, 4)
tabLay.Parent = TabBar
tabLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabBar.CanvasSize = UDim2.new(0, 0, 0, tabLay.AbsoluteContentSize.Y + 8)
end)

local pages, tabs = {}, {}
local function page(name)
    local sc = Instance.new("ScrollingFrame")
    sc.Size = UDim2.new(1, -136, 1, -60)
    sc.Position = UDim2.fromOffset(126, 52)
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 3
    sc.ScrollBarImageColor3 = ACC
    sc.Visible = false
    sc.Parent = Main
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = sc
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sc.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 10)
    end)
    pages[name] = sc
    return sc
end

local function switch(name)
    for n, p in pairs(pages) do p.Visible = n == name end
    for n, b in pairs(tabs) do
        local on = n == name
        tw(b, 0.16, { BackgroundColor3 = on and ACC or CARD, TextColor3 = on and Color3.fromRGB(8, 14, 24) or TXT })
    end
end

for _, n in ipairs({"Farm", "ESP", "Player", "Move", "Shop", "Server", "Config", "Inv", "GFX"}) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -2, 0, 30)
    b.BackgroundColor3 = SIDE
    b.Text = "  " .. n
    b.TextColor3 = TXT
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.Parent = TabBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    tabs[n] = b
    page(n)
    b.MouseButton1Click:Connect(function() switch(n) end)
end

local ToggleRefs = {} -- for refresh after load config

local function toggle(parent, text, order, get, set)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = get() and GRN or CARD
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = get() and Color3.fromRGB(140, 255, 180) or Color3.fromRGB(50, 60, 80)
    stroke.Transparency = 0.35
    stroke.Parent = btn
    local nameL = Instance.new("TextLabel")
    nameL.BackgroundTransparency = 1
    nameL.Size = UDim2.new(1, -70, 1, 0)
    nameL.Position = UDim2.fromOffset(12, 0)
    nameL.Font = Enum.Font.GothamMedium
    nameL.TextSize = 13
    nameL.TextXAlignment = Enum.TextXAlignment.Left
    nameL.TextColor3 = TXT
    nameL.Text = text
    nameL.Parent = btn
    local pill = Instance.new("Frame")
    pill.Size = UDim2.fromOffset(42, 20)
    pill.Position = UDim2.new(1, -52, 0.5, -10)
    pill.BackgroundColor3 = get() and Color3.fromRGB(40, 160, 90) or Color3.fromRGB(40, 46, 58)
    pill.Parent = btn
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = get() and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(245, 248, 255)
    knob.Parent = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local function paint()
        local on = get() and true or false
        tw(btn, 0.16, { BackgroundColor3 = on and Color3.fromRGB(28, 58, 42) or CARD })
        tw(stroke, 0.16, { Color = on and Color3.fromRGB(120, 230, 160) or Color3.fromRGB(50, 60, 80) })
        tw(pill, 0.16, { BackgroundColor3 = on and Color3.fromRGB(46, 180, 100) or Color3.fromRGB(40, 46, 58) })
        tw(knob, 0.16, { Position = on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) })
    end
    btn.MouseButton1Click:Connect(function()
        set(not get())
        paint()
    end)
    btn.MouseEnter:Connect(function() tw(btn, 0.12, { BackgroundTransparency = 0.05 }) end)
    btn.MouseLeave:Connect(function() tw(btn, 0.12, { BackgroundTransparency = 0 }) end)
    table.insert(ToggleRefs, { paint = paint, get = get, text = text })
end

local function refreshAllToggles()
    for _, ref in ipairs(ToggleRefs) do
        pcall(ref.paint)
    end
    -- num boxes: skip (user can reopen); tier drawers painted on open
end

local function btn(parent, text, color, order, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 34)
    b.LayoutOrder = order
    b.BackgroundColor3 = color or CARD
    b.AutoButtonColor = false
    b.Text = text
    b.TextColor3 = TXT
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    local base = color or CARD
    b.MouseEnter:Connect(function()
        tw(b, 0.12, { BackgroundColor3 = base:Lerp(Color3.new(1,1,1), 0.12) })
    end)
    b.MouseLeave:Connect(function()
        tw(b, 0.12, { BackgroundColor3 = base })
    end)
    b.MouseButton1Down:Connect(function()
        tw(b, 0.08, { BackgroundColor3 = base:Lerp(Color3.new(0,0,0), 0.15) })
    end)
    b.MouseButton1Up:Connect(function()
        tw(b, 0.12, { BackgroundColor3 = base })
    end)
    b.MouseButton1Click:Connect(cb)
end

local function numBox(parent, label, order, get, set)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.LayoutOrder = order
    row.BackgroundColor3 = CARD
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(0.5, -6, 1, 0)
    lab.Position = UDim2.fromOffset(10, 0)
    lab.BackgroundTransparency = 1
    lab.Text = label
    lab.TextColor3 = MUT
    lab.Font = Enum.Font.Gotham
    lab.TextSize = 12
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.Parent = row
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.42, 0, 0, 24)
    box.Position = UDim2.new(0.55, 0, 0.5, -12)
    box.BackgroundColor3 = BG
    do
        local gv = get()
        if type(gv) == "number" and gv >= 1000 then box.Text = fmt(gv)
        else box.Text = tostring(gv) end
    end
    box.TextColor3 = TXT
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    box.FocusLost:Connect(function()
        local n = parseMoney(box.Text)
        if n then set(n) end
        -- tampil singkat 1B/1M bukan angka panjang
        local v = get()
        if type(v) == "number" and v >= 1000 then
            box.Text = fmt(v)
        else
            box.Text = tostring(v)
        end
    end)
end

local function label(parent, text, order)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 16)
    l.LayoutOrder = order
    l.BackgroundTransparency = 1
    l.Text = string.upper(text)
    l.TextColor3 = Color3.fromRGB(140, 160, 190)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
end

-- FARM
local farm = pages.Farm
label(farm, "COLLECT", 1)
toggle(farm, "Auto Collect Crystal", 2, function() return S.AutoCollect end, function(v) S.AutoCollect = v notify(v and "Collect Crystal ON" or "OFF") end)
toggle(farm, "Auto Collect Rune", 3, function() return S.AutoRune end, function(v) S.AutoRune = v notify(v and "Collect Rune ON" or "OFF") end)
toggle(farm, "Instant Prompt", 4, function() return S.InstantPrompt end, function(v) S.InstantPrompt = v end)
btn(farm, "UNEXECUTE (matikan semua)", RED, 99, function()
    local f = _G.VannHUB_Unexec
    if f then f() else notify("Unexecute belum siap") end
end)
numBox(farm, "Radius", 4, function() return S.CollectRadius end, function(n) S.CollectRadius = math.clamp(n, 5, 80) end)
numBox(farm, "Delay collect 0.1-1s", 4, function() return S.CollectInterval or 0.4 end, function(n) S.CollectInterval = math.clamp(tonumber(n) or 0.4, 0.1, 1) end)
label(farm, "FILTER COLLECT", 5)
numBox(farm, "Min Luck", 6, function() return S.MinLuck end, function(n) S.MinLuck = n end)
numBox(farm, "Min Coin", 7, function() return S.MinCoin end, function(n) S.MinCoin = n end)
numBox(farm, "Min Berat", 8, function() return S.MinBerat end, function(n) S.MinBerat = n end)
label(farm, "RARITY", 9)
do
    local open = false
    local head = Instance.new("TextButton")
    head.Size = UDim2.new(1, 0, 0, 34)
    head.LayoutOrder = 10
    head.BackgroundColor3 = CARD
    head.AutoButtonColor = false
    head.Font = Enum.Font.GothamMedium
    head.TextSize = 13
    head.TextColor3 = TXT
    head.Text = "Tier collect  v"
    head.Parent = farm
    Instance.new("UICorner", head).CornerRadius = UDim.new(0, 8)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, 0, 0, 0)
    box.LayoutOrder = 11
    box.BackgroundTransparency = 1
    box.ClipsDescendants = true
    box.Parent = farm
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 4)
    lay.Parent = box
    local function summary()
        local n = 0
        for _, on in pairs(S.Rarity) do if on then n = n + 1 end end
        head.Text = "Tier collect  " .. n .. "/8  " .. (open and "^" or "v")
    end
    for _, k in ipairs({"Umum","Tidak Biasa","Langka","Epic","Legendaris","Mitos","Exotic","Zenith"}) do
        local kk = k
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 28)
        b.BackgroundColor3 = S.Rarity[kk] and GRN or CARD
        b.Text = kk
        b.TextColor3 = TXT
        b.Font = Enum.Font.Gotham
        b.TextSize = 12
        b.Parent = box
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function()
            S.Rarity[kk] = not S.Rarity[kk]
            b.BackgroundColor3 = S.Rarity[kk] and GRN or CARD
            summary()
        end)
    end
    head.MouseButton1Click:Connect(function()
        open = not open
        box.Size = UDim2.new(1, 0, 0, open and (lay.AbsoluteContentSize.Y + 4) or 0)
        summary()
    end)
    summary()
end
label(farm, "TELEPORT", 20)
btn(farm, "TP Top Luck", Color3.fromRGB(100, 80, 170), 21, function() tpTop("luck") end)
btn(farm, "TP Top Coin", Color3.fromRGB(100, 80, 170), 22, function() tpTop("coin") end)
btn(farm, "TP Top Berat", Color3.fromRGB(100, 80, 170), 23, function() tpTop("berat") end)
btn(farm, "TP Meteor", Color3.fromRGB(170, 90, 40), 24, function()
    for _, o in ipairs(Workspace:GetDescendants()) do
        if string.lower(o.Name):find("meteor", 1, true) then
            local p = getPart(o)
            if p then tpSafePos(p.Position + Vector3.new(0, 5, 0)) notify("Meteor") return end
        end
    end
    notify("Meteor tidak ada")
end)
-- TP Puncak dihapus
btn(farm, "Set Home sini", CARD, 26, function()
    local h = getHRP()
    if h then S.HomeCF = h.CFrame notify("Home set") end
end)
btn(farm, "TP Home", Color3.fromRGB(70, 110, 180), 27, function()
    if S.HomeCF then tpTo(S.HomeCF)
    elseif Remotes.GoHome then pcall(function() Remotes.GoHome:FireServer("home") end)
    else tpTo(CFrame.new(0, 50, 0)) end
    notify("Home")
end)
btn(farm, "Set Plot sini (skip TP Top)", CARD, 28, function()
    local h = getHRP()
    if h then S.PlotCF = h.CFrame notify("Plot set — Top skip area ini") end
end)
btn(farm, "TP Plot", Color3.fromRGB(70, 110, 180), 29, function()
    if S.PlotCF then tpTo(S.PlotCF) else tpTo(CFrame.new(0, 50, 0)) end
    notify("Plot")
end)

-- ESP CUSTOM
local esp = pages.ESP
label(esp, "ESP", 1)
toggle(esp, "ESP Crystal", 2, function() return S.ESP end, function(v) S.ESP = v if not v then refreshESP() end end)
toggle(esp, "ESP Player", 3, function() return S.EspPlayer end, function(v) S.EspPlayer = v refreshESP() end)
toggle(esp, "ESP Boulder", 4, function() return S.EspBoulder end, function(v) S.EspBoulder = v refreshESP() end)
label(esp, "Muncul setelah jalur digali, dalam jarak render", 5)
numBox(esp, "Jarak Boulder (m)", 6, function() return S.BoulderMaxDist or 1200 end, function(n)
    S.BoulderMaxDist = math.clamp(tonumber(n) or 1200, 50, 4000)
    if S.EspBoulder then pcall(refreshESP) end
end)
label(esp, "FILTER CRYSTAL", 8)
numBox(esp, "Min Luck", 9, function() return S.EspMinLuck end, function(n) S.EspMinLuck = n end)
numBox(esp, "Min Coin", 10, function() return S.EspMinCoin end, function(n) S.EspMinCoin = n end)
numBox(esp, "Min Berat", 11, function() return S.EspMinBerat end, function(n) S.EspMinBerat = n end)
numBox(esp, "Jarak Crystal (m)", 12, function() return S.EspMaxDist end, function(n) S.EspMaxDist = math.clamp(n, 50, 2500) end)
label(esp, "RARITY ESP", 9)
do
    local open = false
    local head = Instance.new("TextButton")
    head.Size = UDim2.new(1, 0, 0, 34)
    head.LayoutOrder = 10
    head.BackgroundColor3 = CARD
    head.AutoButtonColor = false
    head.Font = Enum.Font.GothamMedium
    head.TextSize = 13
    head.TextColor3 = TXT
    head.Text = "Tier ESP"
    head.Parent = esp
    Instance.new("UICorner", head).CornerRadius = UDim.new(0, 8)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, 0, 0, 0)
    box.LayoutOrder = 11
    box.BackgroundTransparency = 1
    box.ClipsDescendants = true
    box.Parent = esp
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 4)
    lay.Parent = box
    local function summary()
        local n = 0
        for _, on in pairs(S.EspRarity) do if on then n = n + 1 end end
        head.Text = "Tier ESP  " .. n .. "/8  " .. (open and "^" or "v")
    end
    for _, k in ipairs({"Umum","Tidak Biasa","Langka","Epic","Legendaris","Mitos","Exotic","Zenith"}) do
        local kk = k
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 28)
        b.BackgroundColor3 = S.EspRarity[kk] and GRN or CARD
        b.Text = kk
        b.TextColor3 = TXT
        b.Font = Enum.Font.Gotham
        b.TextSize = 12
        b.Parent = box
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function()
            S.EspRarity[kk] = not S.EspRarity[kk]
            b.BackgroundColor3 = S.EspRarity[kk] and GRN or CARD
            summary()
        end)
    end
    head.MouseButton1Click:Connect(function()
        open = not open
        box.Size = UDim2.new(1, 0, 0, open and (lay.AbsoluteContentSize.Y + 4) or 0)
        summary()
    end)
    summary()
end
label(esp, "TAMPILAN LABEL", 20)
toggle(esp, "Tampil Luck", 21, function() return S.EspShowLuck end, function(v) S.EspShowLuck = v end)
toggle(esp, "Tampil Coin", 22, function() return S.EspShowCoin end, function(v) S.EspShowCoin = v end)
toggle(esp, "Tampil Berat", 23, function() return S.EspShowBerat end, function(v) S.EspShowBerat = v end)
btn(esp, "Refresh ESP", CARD, 24, function() refreshESP() notify("ESP refresh") end)

label(esp, "LIST CRYSTAL (TP)", 25)
local crystalListBox = Instance.new("Frame")
crystalListBox.Size = UDim2.new(1, 0, 0, 8)
crystalListBox.LayoutOrder = 26
crystalListBox.BackgroundTransparency = 1
crystalListBox.Parent = esp
local crystalListLay = Instance.new("UIListLayout")
crystalListLay.Padding = UDim.new(0, 4)
crystalListLay.Parent = crystalListBox
crystalListLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    crystalListBox.Size = UDim2.new(1, 0, 0, math.min(crystalListLay.AbsoluteContentSize.Y + 4, 400))
end)

local function refreshCrystalList()
    for _, c in ipairs(crystalListBox:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    local hrp = getHRP()
    local items = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and isCrystal(obj) and meetsESP(obj) then
            if isOnPlot(obj) then
            else
                local pos = getWorldPos(obj)
                if pos then
                    local dist = hrp and (pos - hrp.Position).Magnitude or 0
                    if dist <= (tonumber(S.EspMaxDist) or 400) then
                        table.insert(items, {obj = obj, pos = pos, dist = dist, luck = luck(obj), coin = coin(obj), berat = berat(obj), rar = getCrystalRarity(obj)})
                    end
                end
            end
        end
    end
    table.sort(items, function(a, b) return a.coin > b.coin end)
    if #items == 0 then
        local e = Instance.new("TextLabel")
        e.Size = UDim2.new(1, 0, 0, 22)
        e.BackgroundTransparency = 1
        e.Text = "Tidak ada crystal (cek filter ESP)"
        e.TextColor3 = MUT
        e.Font = Enum.Font.Gotham
        e.TextSize = 11
        e.Parent = crystalListBox
        return
    end
    for i, it in ipairs(items) do
        if i > 40 then break end
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 44)
        card.BackgroundColor3 = CARD
        card.Parent = crystalListBox
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, -58, 0, 18)
        tl.Position = UDim2.fromOffset(8, 3)
        tl.BackgroundTransparency = 1
        tl.Text = string.format("%s [%s]", it.obj.Name, it.rar)
        tl.TextColor3 = TXT
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 11
        tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.TextTruncate = Enum.TextTruncate.AtEnd
        tl.Parent = card
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -58, 0, 16)
        sub.Position = UDim2.fromOffset(8, 22)
        sub.BackgroundTransparency = 1
        sub.Text = string.format("L:%s $:%s W:%s | %.0fm", fmt(it.luck), fmt(it.coin), fmt(it.berat), it.dist)
        sub.TextColor3 = MUT
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = card
        local tb = Instance.new("TextButton")
        tb.Size = UDim2.fromOffset(44, 26)
        tb.Position = UDim2.new(1, -50, 0.5, -13)
        tb.BackgroundColor3 = ACC
        tb.Text = "TP"
        tb.TextColor3 = TXT
        tb.Font = Enum.Font.GothamBold
        tb.TextSize = 11
        tb.Parent = card
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
        local pos = it.pos
        tb.MouseButton1Click:Connect(function()
            tpSafePos(pos + Vector3.new(0, 3, 0))
            notify("TP " .. it.obj.Name)
        end)
    end
end

btn(esp, "Refresh List Crystal", Color3.fromRGB(0, 110, 190), 27, function()
    refreshCrystalList()
    notify("List crystal OK")
end)

-- PLAYER TAB
local playerPage = pages.Player
label(playerPage, "PLAYER", 1)
toggle(playerPage, "ESP Player", 2, function() return S.EspPlayer end, function(v) S.EspPlayer = v refreshESP() end)
btn(playerPage, "Refresh Player", Color3.fromRGB(0, 110, 190), 3, function()
    refreshPlayerList()
    if S.EspPlayer then refreshESP() end
    notify("Player list OK")
end)

local playerListBox = Instance.new("Frame")
playerListBox.Size = UDim2.new(1, 0, 0, 8)
playerListBox.LayoutOrder = 4
playerListBox.BackgroundTransparency = 1
playerListBox.Parent = playerPage
local playerListLay = Instance.new("UIListLayout")
playerListLay.Padding = UDim.new(0, 4)
playerListLay.Parent = playerListBox
playerListLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    playerListBox.Size = UDim2.new(1, 0, 0, playerListLay.AbsoluteContentSize.Y + 4)
end)

function refreshPlayerList()
    for _, c in ipairs(playerListBox:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    local my = getHRP()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            local dist = (my and root) and (root.Position - my.Position).Magnitude or 99999
            table.insert(list, {plr = plr, root = root, dist = dist})
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    if #list == 0 then
        local e = Instance.new("TextLabel")
        e.Size = UDim2.new(1, 0, 0, 22)
        e.BackgroundTransparency = 1
        e.Text = "Tidak ada player lain"
        e.TextColor3 = MUT
        e.Font = Enum.Font.Gotham
        e.TextSize = 11
        e.Parent = playerListBox
        return
    end
    for _, it in ipairs(list) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 40)
        card.BackgroundColor3 = CARD
        card.Parent = playerListBox
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, -58, 1, 0)
        tl.Position = UDim2.fromOffset(8, 0)
        tl.BackgroundTransparency = 1
        tl.Text = string.format("%s  |  %.0fm", it.plr.DisplayName or it.plr.Name, it.dist)
        tl.TextColor3 = TXT
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 12
        tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.Parent = card
        local tb = Instance.new("TextButton")
        tb.Size = UDim2.fromOffset(44, 26)
        tb.Position = UDim2.new(1, -50, 0.5, -13)
        tb.BackgroundColor3 = ACC
        tb.Text = "TP"
        tb.TextColor3 = TXT
        tb.Font = Enum.Font.GothamBold
        tb.TextSize = 11
        tb.Parent = card
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 6)
        local plrRef = it.plr
        tb.MouseButton1Click:Connect(function()
            local ch = plrRef.Character
            local r = ch and ch:FindFirstChild("HumanoidRootPart")
            if r then
                tpTo(r.CFrame + Vector3.new(0, 3, 0))
                notify("TP " .. (plrRef.DisplayName or plrRef.Name))
            else
                notify("Player tidak ada karakter")
            end
        end)
    end
end

task.defer(function()
    pcall(refreshPlayerList)
end)


-- EXTRA
local movePage = pages.Move
label(movePage, "MOVEMENT", 1)
toggle(movePage, "WalkSpeed", 2, function() return S.speedOn end, function(v) setSpeed(v) end)
numBox(movePage, "Speed Value", 3, function() return S.speed or 28 end, function(n)
    S.speed = math.clamp(n, 16, 120)
    if S.speedOn then local h=getHum() if h then h.WalkSpeed=S.speed end end
end)
btn(movePage, "Speed 28", CARD, 4, function() S.speed=28 if S.speedOn then local h=getHum() if h then h.WalkSpeed=28 end end notify("28") end)
btn(movePage, "Speed 50", CARD, 5, function() S.speed=50 if S.speedOn then local h=getHum() if h then h.WalkSpeed=50 end end notify("50") end)
btn(movePage, "Speed 80", CARD, 6, function() S.speed=80 if S.speedOn then local h=getHum() if h then h.WalkSpeed=80 end end notify("80") end)
toggle(movePage, "Inf Jump", 7, function() return S.infJump end, function(v) setInfJump(v) end)
toggle(movePage, "Anti Knockback", 8, function() return S.antiKB end, function(v) setAntiKB(v) end)

-- SHOP
local shop = pages.Shop
label(shop, "AUTO SELL", 1)
toggle(shop, "Auto Sell", 2, function() return S.AutoSell end, function(v) S.AutoSell = v end)
numBox(shop, "Sell Interval 10-30s", 3, function() return S.SellInterval or 15 end, function(n)
    S.SellInterval = math.clamp(math.floor(tonumber(n) or 15), 10, 30)
end)
btn(shop, "Sell All Now", RED, 4, sellAll)
label(shop, "UPGRADE", 5)
btn(shop, "Warmth +10", CARD, 6, function() S.warmthAmount=10 buyUpgrade("warmth",10) notify("Warmth 10") end)
btn(shop, "Warmth +50", CARD, 7, function() S.warmthAmount=50 buyUpgrade("warmth",50) notify("Warmth 50") end)
btn(shop, "Warmth MAX", CARD, 8, function() S.warmthAmount=999 buyUpgrade("warmth",100) buyUpgrade("warmth",50) buyUpgrade("warmth",10) notify("Warmth max") end)
toggle(shop, "Auto Buy Warmth", 9, function() return S.autoWarmth end, function(v) setAutoWarmth(v) end)
btn(shop, "Carry +1", CARD, 10, function() S.carryAmount=1 buyUpgrade("carry",1) notify("Carry 1") end)
btn(shop, "Carry MAX", CARD, 11, function() S.carryAmount=999 buyUpgrade("carry",10) buyUpgrade("carry",5) buyUpgrade("carry",1) notify("Carry max") end)
toggle(shop, "Auto Buy Carry", 12, function() return S.autoCarry end, function(v) setAutoCarry(v) end)
btn(shop, "Open Boom Shop", Color3.fromRGB(180, 100, 40), 13, openBombShop)

label(shop, "BOMB", 20)
toggle(shop, "Auto Buy Bomb", 21, function() return S.AutoBuyBombs end, function(v) S.AutoBuyBombs = v notify(v and "Auto Bomb ON" or "Auto Bomb OFF") end)
btn(shop, "Buy Bomb Terpilih", Color3.fromRGB(180, 90, 50), 22, function()
    buySelected("bomb")
end)
do
    local names = {"ClassicBomb","IceBomb","FireBomb","PoisonBomb","LightningBomb","WindBomb","DivineBomb","VoidBomb","NebulaBomb"}
    local open = false
    local head = Instance.new("TextButton")
    head.Size = UDim2.new(1, 0, 0, 34)
    head.LayoutOrder = 23
    head.BackgroundColor3 = CARD
    head.Font = Enum.Font.GothamMedium
    head.TextSize = 13
    head.TextColor3 = TXT
    head.Text = "Pilih bomb"
    head.Parent = shop
    Instance.new("UICorner", head).CornerRadius = UDim.new(0, 8)
    local box = Instance.new("Frame")
    box.LayoutOrder = 24
    box.Size = UDim2.new(1, 0, 0, 0)
    box.BackgroundTransparency = 1
    box.ClipsDescendants = true
    box.Parent = shop
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 4)
    lay.Parent = box
    local function summary()
        local n=0
        for _, nm in ipairs(names) do if S.BuyBombs[nm] then n=n+1 end end
        head.Text = "Pilih bomb  "..n.."/"..#names.."  "..(open and "^" or "v")
    end
    for _, name in ipairs(names) do
        local nm=name
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(1,0,0,28)
        b.BackgroundColor3=S.BuyBombs[nm] and GRN or CARD
        b.Text=nm
        b.TextColor3=TXT
        b.Font=Enum.Font.Gotham
        b.TextSize=12
        b.Parent=box
        Instance.new("UICorner", b).CornerRadius=UDim.new(0,6)
        b.MouseButton1Click:Connect(function()
            S.BuyBombs[nm]=not S.BuyBombs[nm]
            b.BackgroundColor3=S.BuyBombs[nm] and GRN or CARD
            summary()
        end)
    end
    head.MouseButton1Click:Connect(function()
        open=not open
        box.Size=UDim2.new(1,0,0, open and (lay.AbsoluteContentSize.Y+4) or 0)
        summary()
    end)
    summary()
end

label(shop, "RADAR", 40)
toggle(shop, "Auto Buy Radar", 41, function() return S.AutoBuyRadars end, function(v) S.AutoBuyRadars = v notify(v and "Auto Radar ON" or "Auto Radar OFF") end)
btn(shop, "Buy Radar Terpilih", Color3.fromRGB(70, 120, 180), 42, function()
    buySelected("radar")
end)
do
    local names = {"CrystalRadar","BoulderRadar","RuneRadar","RarityRadar","MeteorRadar","ZenithRadar"}
    local open = false
    local head = Instance.new("TextButton")
    head.Size = UDim2.new(1, 0, 0, 34)
    head.LayoutOrder = 43
    head.BackgroundColor3 = CARD
    head.Font = Enum.Font.GothamMedium
    head.TextSize = 13
    head.TextColor3 = TXT
    head.Text = "Pilih radar"
    head.Parent = shop
    Instance.new("UICorner", head).CornerRadius = UDim.new(0, 8)
    local box = Instance.new("Frame")
    box.LayoutOrder = 44
    box.Size = UDim2.new(1, 0, 0, 0)
    box.BackgroundTransparency = 1
    box.ClipsDescendants = true
    box.Parent = shop
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 4)
    lay.Parent = box
    local function summary()
        local n=0
        for _, nm in ipairs(names) do if S.BuyRadars[nm] then n=n+1 end end
        head.Text = "Pilih radar  "..n.."/"..#names.."  "..(open and "^" or "v")
    end
    for _, name in ipairs(names) do
        local nm=name
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(1,0,0,28)
        b.BackgroundColor3=S.BuyRadars[nm] and GRN or CARD
        b.Text=nm
        b.TextColor3=TXT
        b.Font=Enum.Font.Gotham
        b.TextSize=12
        b.Parent=box
        Instance.new("UICorner", b).CornerRadius=UDim.new(0,6)
        b.MouseButton1Click:Connect(function()
            S.BuyRadars[nm]=not S.BuyRadars[nm]
            b.BackgroundColor3=S.BuyRadars[nm] and GRN or CARD
            summary()
        end)
    end
    head.MouseButton1Click:Connect(function()
        open=not open
        box.Size=UDim2.new(1,0,0, open and (lay.AbsoluteContentSize.Y+4) or 0)
        summary()
    end)
    summary()
end


-- SERVER
local server = pages.Server
label(server, "SERVER", 1)
toggle(server, "Anti AFK", 2, function() return S.antiAFK end, function(v) S.antiAFK = v end)
toggle(server, "Auto Reconnect", 3, function() return S.autoReconnect end, function(v) S.autoReconnect = v end)
btn(server, "Rejoin", Color3.fromRGB(200, 120, 40), 4, function()
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, player)
    end)
    notify("Rejoin...")
end)
btn(server, "Server Hop", Color3.fromRGB(120, 80, 180), 5, function()
    pcall(function()
        local Ts = game:GetService("TeleportService")
        local Hs = game:GetService("HttpService")
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local data = Hs:JSONDecode(game:HttpGet(url))
        local servers = {}
        for _, s in ipairs(data.data or {}) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                table.insert(servers, s.id)
            end
        end
        if #servers > 0 then
            Ts:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], player)
            notify("Server hop...")
        else
            notify("Server penuh / tidak ada")
        end
    end)
end)

-- CONFIG
local configPage = pages.Config
label(configPage, "CONFIGURATION", 1)
toggle(configPage, "Auto Load saat execute", 2, function() return S.autoLoadConfig end, function(v) S.autoLoadConfig = v end)

local cfgNameBox
do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.LayoutOrder = 3
    row.BackgroundColor3 = CARD
    row.Parent = configPage
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(0.35, 0, 1, 0)
    lab.Position = UDim2.fromOffset(8, 0)
    lab.BackgroundTransparency = 1
    lab.Text = "Nama Config"
    lab.TextColor3 = MUT
    lab.Font = Enum.Font.Gotham
    lab.TextSize = 12
    lab.TextXAlignment = Enum.TextXAlignment.Left
    lab.Parent = row
    cfgNameBox = Instance.new("TextBox")
    cfgNameBox.Size = UDim2.new(0.55, 0, 0, 24)
    cfgNameBox.Position = UDim2.new(0.4, 0, 0.5, -12)
    cfgNameBox.BackgroundColor3 = BG
    cfgNameBox.Text = "default"
    cfgNameBox.TextColor3 = TXT
    cfgNameBox.Font = Enum.Font.GothamBold
    cfgNameBox.TextSize = 12
    cfgNameBox.ClearTextOnFocus = false
    cfgNameBox.Parent = row
    Instance.new("UICorner", cfgNameBox).CornerRadius = UDim.new(0, 6)
end

local function configPath(name)
    name = tostring(name or "default"):gsub("[^%w%-%_]", "_")
    return "VannHUB/configs/" .. name .. ".json"
end

local function listConfigs()
    local list = {}
    pcall(function()
        if isfolder and listfiles and isfolder("VannHUB/configs") then
            for _, f in ipairs(listfiles("VannHUB/configs")) do
                local n = tostring(f):match("([^/\]+)%.json$")
                if n then table.insert(list, n) end
            end
        end
    end)
    return list
end

local cfgListBox = Instance.new("Frame")
cfgListBox.Size = UDim2.new(1, 0, 0, 8)
cfgListBox.LayoutOrder = 6
cfgListBox.BackgroundTransparency = 1
cfgListBox.Parent = configPage
local cfgListLay = Instance.new("UIListLayout")
cfgListLay.Padding = UDim.new(0, 4)
cfgListLay.Parent = cfgListBox
cfgListLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    cfgListBox.Size = UDim2.new(1, 0, 0, cfgListLay.AbsoluteContentSize.Y + 4)
end)

local function refreshConfigList()
    for _, c in ipairs(cfgListBox:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    local list = listConfigs()
    if #list == 0 then
        local e = Instance.new("TextLabel")
        e.Size = UDim2.new(1, 0, 0, 22)
        e.BackgroundTransparency = 1
        e.Text = "Belum ada config tersimpan"
        e.TextColor3 = MUT
        e.Font = Enum.Font.Gotham
        e.TextSize = 11
        e.Parent = cfgListBox
        return
    end
    for _, name in ipairs(list) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 36)
        card.BackgroundColor3 = CARD
        card.Parent = cfgListBox
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, -100, 1, 0)
        tl.Position = UDim2.fromOffset(8, 0)
        tl.BackgroundTransparency = 1
        tl.Text = name
        tl.TextColor3 = TXT
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 12
        tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.Parent = card
        local loadB = Instance.new("TextButton")
        loadB.Size = UDim2.fromOffset(44, 24)
        loadB.Position = UDim2.new(1, -96, 0.5, -12)
        loadB.BackgroundColor3 = ACC
        loadB.Text = "Load"
        loadB.TextColor3 = TXT
        loadB.Font = Enum.Font.GothamBold
        loadB.TextSize = 11
        loadB.Parent = card
        Instance.new("UICorner", loadB).CornerRadius = UDim.new(0, 6)
        local nm = name
        loadB.MouseButton1Click:Connect(function()
            cfgNameBox.Text = nm
            loadConfigNamed(nm)
        end)
        local delB = Instance.new("TextButton")
        delB.Size = UDim2.fromOffset(40, 24)
        delB.Position = UDim2.new(1, -48, 0.5, -12)
        delB.BackgroundColor3 = RED
        delB.Text = "Del"
        delB.TextColor3 = TXT
        delB.Font = Enum.Font.GothamBold
        delB.TextSize = 11
        delB.Parent = card
        Instance.new("UICorner", delB).CornerRadius = UDim.new(0, 6)
        delB.MouseButton1Click:Connect(function()
            pcall(function()
                if delfile then delfile(configPath(nm)) end
            end)
            refreshConfigList()
            notify("Deleted " .. nm)
        end)
    end
end

function saveConfigNamed(name)
    name = name or (cfgNameBox and cfgNameBox.Text) or "default"
    local ok = pcall(function()
        if makefolder then
            if not isfolder("VannHUB") then makefolder("VannHUB") end
            if not isfolder("VannHUB/configs") then makefolder("VannHUB/configs") end
        end
        if writefile then
            writefile(configPath(name), game:GetService("HttpService"):JSONEncode(collectConfig()))
        end
        player:SetAttribute("VannHUB_CFG", game:GetService("HttpService"):JSONEncode(collectConfig()))
        player:SetAttribute("VannHUB_CFG_NAME", name)
    end)
    refreshConfigList()
    notify(ok and ("Saved: " .. name) or "Save gagal")
end

function loadConfigNamed(name)
    name = name or (cfgNameBox and cfgNameBox.Text) or "default"
    local cfg
    pcall(function()
        if readfile and isfile and isfile(configPath(name)) then
            cfg = game:GetService("HttpService"):JSONDecode(readfile(configPath(name)))
        end
    end)
    if not cfg then
        pcall(function()
            local raw = player:GetAttribute("VannHUB_CFG")
            if raw then cfg = game:GetService("HttpService"):JSONDecode(raw) end
        end)
    end
    if cfg then
        applyConfig(cfg)
        if cfgNameBox then cfgNameBox.Text = name end
        task.defer(function()
            pcall(refreshAllToggles)
        end)
        notify("Loaded: " .. name)
        return true
    end
    notify("Config tidak ada: " .. tostring(name))
    return false
end

btn(configPage, "Save Config", Color3.fromRGB(0, 120, 180), 4, function()
    saveConfigNamed(cfgNameBox.Text)
end)
btn(configPage, "Load Config", Color3.fromRGB(0, 120, 180), 5, function()
    loadConfigNamed(cfgNameBox.Text)
end)
btn(configPage, "Refresh List Config", CARD, 7, refreshConfigList)
task.defer(refreshConfigList)

-- Extra = Fav + Inventory (tetap)
local extra = pages.Inv
label(extra, "FAV / INVENTORY", 1)
toggle(extra, "Auto Favorite", 50, function() return S.AutoFavorite end, function(v) S.AutoFavorite = v end)
numBox(extra, "Fav Min (coin/luck/kg)", 51, function() return S.FavMin end, function(n) S.FavMin = tonumber(n) or 0 end)
btn(extra, "Fav = Coin", CARD, 52, function() S.FavMode = "coin" notify("Fav mode: Coin") end)
btn(extra, "Fav = Luck", CARD, 53, function() S.FavMode = "luck" notify("Fav mode: Luck") end)
btn(extra, "Fav = Berat (kg)", CARD, 54, function() S.FavMode = "berat" notify("Fav mode: Berat kg — isi Fav Min misal 3.3") end)
btn(extra, "Sell All", RED, 55, sellAll)
btn(extra, "Unfavorite All", Color3.fromRGB(140, 60, 70), 56, unfavAll)
label(extra, "ISI TAS (crystal)", 57)

local invBox = Instance.new("Frame")
invBox.Name = "InvBox"
invBox.Size = UDim2.new(1, 0, 0, 8)
invBox.LayoutOrder = 49
invBox.BackgroundTransparency = 1
invBox.Parent = extra
local invLay = Instance.new("UIListLayout")
invLay.Padding = UDim.new(0, 4)
invLay.Parent = invBox
invLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    invBox.Size = UDim2.new(1, 0, 0, invLay.AbsoluteContentSize.Y + 4)
end)

local function refreshInv()
    for _, c in ipairs(invBox:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    local tools = scanInv()
    if #tools == 0 then
        local e = Instance.new("TextLabel")
        e.Size = UDim2.new(1, 0, 0, 24)
        e.BackgroundTransparency = 1
        e.Text = "Tas kosong"
        e.TextColor3 = MUT
        e.Font = Enum.Font.Gotham
        e.TextSize = 12
        e.Parent = invBox
        return
    end
    for _, tool in ipairs(tools) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 42)
        card.BackgroundColor3 = CARD
        card.Parent = invBox
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, -12, 0, 18)
        tl.Position = UDim2.fromOffset(8, 3)
        tl.BackgroundTransparency = 1
        tl.Text = tool.Name .. (isFav(tool) and " *" or "")
        tl.TextColor3 = TXT
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 12
        tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.Parent = card
        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(1, -12, 0, 16)
        s.Position = UDim2.fromOffset(8, 22)
        s.BackgroundTransparency = 1
        s.Text = string.format("L:%s $:%s W:%s", fmt(luck(tool)), fmt(coin(tool)), fmt(berat(tool)))
        s.TextColor3 = MUT
        s.Font = Enum.Font.Gotham
        s.TextSize = 11
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.Parent = card
    end
end

btn(extra, "Refresh Inventory", Color3.fromRGB(0, 110, 190), 48, function()
    refreshInv()
    notify("Inv OK")
end)
btn(extra, "Drop All", RED, 49, function()
    dropAll()
    task.delay(0.3, function() pcall(refreshInv) end)
end)
btn(extra, "Reset Character", Color3.fromRGB(80, 80, 95), 50, function()
    local h = getHum()
    if h then h.Health = 0 end
end)

-- GFX TAB
local gfxPage = pages.GFX
label(gfxPage, "GRAPHICS / PERFORMANCE", 1)
toggle(gfxPage, "Flat / Smooth GFX", 2, function() return S.gfxFlat end, function(v) setFlat(v) end)
toggle(gfxPage, "Anti Lag", 3, function() return S.gfxAntiLag end, function(v) setAntiLag(v) end)
toggle(gfxPage, "Hide Effects", 4, function() return S.gfxHideEffects end, function(v) setHideEffects(v) end)
toggle(gfxPage, "Hide Other Players", 5, function() return S.gfxHidePlayers end, function(v) setHidePlayers(v) end)
label(gfxPage, "SCREEN", 6)
toggle(gfxPage, "White Screen", 7, function() return S.gfxWhite end, function(v) setWhiteScreen(v) end)
toggle(gfxPage, "Black Screen", 8, function() return S.gfxBlack end, function(v) setBlackScreen(v) end)
toggle(gfxPage, "FPS / CPU / GPU", 8, function() return S.showPerf end, function(v)
    local fn = _G.VannSetPerf
    if fn then fn(v) else notify("Monitor belum siap") end
end)
btn(gfxPage, "Apply Anti Lag + Flat", Color3.fromRGB(0, 120, 180), 9, function()
    setFlat(true)
    setAntiLag(true)
    setHideEffects(true)
    notify("Full low GFX applied")
end)

switch("Farm")

task.spawn(function()
    local load = Instance.new("Frame")
    load.Name = "Loader"
    load.Size = UDim2.fromScale(1, 1)
    load.BackgroundColor3 = Color3.fromRGB(6, 7, 10)
    load.BackgroundTransparency = 1
    load.ZIndex = 400
    load.Parent = SG
    tw(load, 0.25, { BackgroundTransparency = 0.15 })

    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.55)
    card.Size = UDim2.fromOffset(280, 120)
    card.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
    card.ZIndex = 401
    card.Parent = load
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
    local cs = Instance.new("UIStroke")
    cs.Color = ACC
    cs.Thickness = 1.2
    cs.Transparency = 0.2
    cs.Parent = card

    local mark = Instance.new("TextLabel")
    mark.BackgroundTransparency = 1
    mark.Size = UDim2.new(1, -24, 0, 28)
    mark.Position = UDim2.fromOffset(16, 16)
    mark.Font = Enum.Font.GothamBlack
    mark.TextSize = 22
    mark.TextXAlignment = Enum.TextXAlignment.Left
    mark.TextColor3 = ACC
    mark.Text = "VANNHUB"
    mark.ZIndex = 402
    mark.Parent = card

    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Size = UDim2.new(1, -24, 0, 18)
    sub.Position = UDim2.fromOffset(16, 46)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 13
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextColor3 = MUT
    sub.Text = "Menyiapkan hub..."
    sub.ZIndex = 402
    sub.Parent = card

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -32, 0, 6)
    track.Position = UDim2.fromOffset(16, 86)
    track.BackgroundColor3 = Color3.fromRGB(36, 40, 50)
    track.ZIndex = 402
    track.Parent = card
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = ACC
    bar.ZIndex = 403
    bar.Parent = track
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local steps = { "Menyiapkan farm", "ESP & jarak", "Shop bomb & radar", "Siap" }
    for i, msg in ipairs(steps) do
        sub.Text = msg
        tw(bar, 0.28, { Size = UDim2.new(i / #steps, 0, 1, 0) })
        task.wait(0.32)
    end
    tw(card, 0.18, { BackgroundTransparency = 1 })
    tw(mark, 0.18, { TextTransparency = 1 })
    tw(sub, 0.18, { TextTransparency = 1 })
    tw(load, 0.22, { BackgroundTransparency = 1 })
    task.wait(0.2)
    load:Destroy()
    Main.Visible = true
    local target = Main.Size
    Main.Size = UDim2.fromOffset(target.X.Offset, target.Y.Offset - 24)
    tw(Main, 0.22, { Size = target })
end)


-- loops
task.spawn(function()
    while SG.Parent and not S.dead do
        task.wait(math.clamp(tonumber(S.CollectInterval) or 0.4, 0.1, 1))
        if S.AutoCollect or S.AutoRune or S.InstantPrompt then
            pcall(autoCollect)
        end
    end
end)
task.spawn(function()
    while SG.Parent and not S.dead do
        task.wait(2)
        if S.AutoFavorite then pcall(favTick) end
    end
end)

task.spawn(function()
    while SG.Parent and not S.dead do
        local waitSec = math.clamp(tonumber(S.SellInterval) or 15, 10, 30)
        task.wait(waitSec)
        if S.AutoSell then
            pcall(function()
                -- sell filter: only notify/fire if bag has matching (best-effort)
                sellAll()
            end)
        end
    end
end)
task.spawn(function()
    while SG.Parent and not S.dead do
        task.wait(S.EspBoulder and 1.6 or 3)
        if S.ESP or S.EspPlayer or S.EspBoulder then pcall(refreshESP) end
    end
end)

if S.autoLoadConfig then
    task.defer(function()
        local nm = player:GetAttribute("VannHUB_CFG_NAME") or "default"
        pcall(loadConfigNamed, nm)
    end)
end

pcall(function()
    local br = ReplicatedStorage:FindFirstChild("BoulderRemotes")
    local ev = br and br:FindFirstChild("Broken")
    if ev and ev:IsA("RemoteEvent") then
        ev.OnClientEvent:Connect(function(_, _, _, kind, _, inst)
            if type(kind) == "string" and inst and inst.Parent then
                RadarBoulderCache[inst] = { kind = kind, t = tick() }
            end
        end)
    end
end)
local boulderScanAt = 0
Workspace.DescendantAdded:Connect(function(inst)
    if not S.EspBoulder then return end
    if not (inst:IsA("Model") or inst:IsA("BasePart") or inst:IsA("MeshPart")) then return end
    if not matchBoulderKind(inst.Name) then return end
    if os.clock() - boulderScanAt < 0.4 then return end
    boulderScanAt = os.clock()
    task.defer(function() pcall(refreshESP) end)
end)

local function unexecuteAll()
    S.dead = true
    S.AutoCollect = false
    S.AutoRune = false
    S.InstantPrompt = false
    S.AutoSell = false
    S.AutoFavorite = false
    S.ESP = false
    S.EspPlayer = false
    S.EspBoulder = false
    S.AutoBoulderRadar = false
    S.autoWarmth = false
    S.autoCarry = false
    S.AutoBuyBombs = false
    S.AutoBuyRadars = false
    S.antiAFK = false
    S.autoReconnect = false
    S.gfxFlat = false
    S.gfxAntiLag = false
    S.gfxHidePlayers = false
    S.gfxHideEffects = false
    pcall(function() setWhiteScreen(false) end)
    pcall(function() setBlackScreen(false) end)
    pcall(function() setSpeed(false) end)
    pcall(function() setInfJump(false) end)
    pcall(function() setAntiRagdoll(false) end)
    pcall(function() setNoFall(false) end)
    pcall(function() setAntiKB(false) end)
    pcall(clearESP)
    pcall(function() table.clear(claimed) end)
    pcall(function() table.clear(dropIgnore) end)
    S.showPerf = false
    pcall(function() if PerfGui then PerfGui:Destroy() end end)
    pcall(function() if GfxGui then GfxGui:Destroy() end end)
    notify("Unexecuted")
    task.defer(function()
        pcall(function() if ESPFolder then ESPFolder:Destroy() end end)
        pcall(function() if SG then SG:Destroy() end end)
    end)
    print("[VannHUB] unexecuted")
end
_G.VannHUB_Unexec = unexecuteAll


local ShopStock = { bomb = {}, radar = {} }
pcall(function()
    local br = ReplicatedStorage:FindFirstChild("BombRemotes")
    local ev = br and br:FindFirstChild("ShopState")
    if ev and ev:IsA("RemoteEvent") then
        ev.OnClientEvent:Connect(function(data)
            if type(data) == "table" and type(data.stock) == "table" then
                ShopStock.bomb = data.stock
            end
        end)
    end
    local rr = ReplicatedStorage:FindFirstChild("RadarRemotes")
    local ev2 = rr and rr:FindFirstChild("ShopState")
    if ev2 and ev2:IsA("RemoteEvent") then
        ev2.OnClientEvent:Connect(function(data)
            if type(data) == "table" and type(data.stock) == "table" then
                ShopStock.radar = data.stock
            end
        end)
    end
end)

local function buyOneBomb(name)
    local stock = ShopStock.bomb[name]
    if stock ~= nil and tonumber(stock) ~= nil and tonumber(stock) <= 0 then return false end
    local folder = ReplicatedStorage:FindFirstChild("BombRemotes")
    local ev = folder and folder:FindFirstChild("BuyBomb")
    if not ev then return false end
    local ok = pcall(function()
        if ev:IsA("RemoteFunction") then ev:InvokeServer(name, "cash")
        else ev:FireServer(name, "cash") end
    end)
    return ok
end

local function buyOneRadar(name)
    local stock = ShopStock.radar[name]
    if stock ~= nil and tonumber(stock) ~= nil and tonumber(stock) <= 0 then return false end
    local folder = ReplicatedStorage:FindFirstChild("RadarRemotes")
    local ev = folder and folder:FindFirstChild("BuyRadar")
    if not ev then return false end
    local ok = pcall(function()
        if ev:IsA("RemoteFunction") then ev:InvokeServer(name)
        else ev:FireServer(name) end
    end)
    return ok
end

function buySelected(kind)
    local n = 0
    if kind == "bomb" or kind == "all" then
        for name, on in pairs(S.BuyBombs) do
            if on and buyOneBomb(name) then n = n + 1 end
        end
    end
    if kind == "radar" or kind == "all" then
        for name, on in pairs(S.BuyRadars) do
            if on and buyOneRadar(name) then n = n + 1 end
        end
    end
    notify("Buy attempt: " .. tostring(n))
end

task.spawn(function()
    while SG and SG.Parent and not S.dead do
        task.wait(4)
        if S.AutoBuyBombs then
            for name, on in pairs(S.BuyBombs) do
                if on then pcall(buyOneBomb, name) end
            end
        end
        if S.AutoBuyRadars then
            for name, on in pairs(S.BuyRadars) do
                if on then pcall(buyOneRadar, name) end
            end
        end
    end
end)


local PerfGui
local function setPerf(on)
    S.showPerf = on and true or false
    if PerfGui then pcall(function() PerfGui:Destroy() end) PerfGui = nil end
    if not S.showPerf then
        notify("Monitor OFF")
        return
    end
    PerfGui = Instance.new("ScreenGui")
    PerfGui.Name = "VannPerf"
    PerfGui.ResetOnSpawn = false
    PerfGui.IgnoreGuiInset = true
    PerfGui.DisplayOrder = 1000
    PerfGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local parented = false
    pcall(function()
        local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui")
        PerfGui.Parent = pg
        parented = PerfGui.Parent ~= nil
    end)
    if not parented then
        pcall(function() PerfGui.Parent = CoreGui parented = PerfGui.Parent ~= nil end)
    end
    if not parented then
        notify("Monitor gagal parent")
        return
    end
    local f = Instance.new("TextLabel")
    f.Name = "Readout"
    f.AnchorPoint = Vector2.new(0, 0)
    f.Size = UDim2.fromOffset(180, 62)
    f.Position = UDim2.new(0, 10, 0, 46)
    f.BackgroundColor3 = Color3.fromRGB(8, 10, 14)
    f.BackgroundTransparency = 0.05
    f.TextColor3 = Color3.fromRGB(255, 214, 120)
    f.Font = Enum.Font.GothamBold
    f.TextSize = 14
    f.TextXAlignment = Enum.TextXAlignment.Left
    f.TextYAlignment = Enum.TextYAlignment.Center
    f.Text = "FPS  --\\nCPU  --\\nGPU  --"
    f.ZIndex = 50
    f.Parent = PerfGui
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.Parent = f
    local acc, frames = 0, 0
    local conn
    conn = game:GetService("RunService").RenderStepped:Connect(function(dt)
        if S.dead or not S.showPerf or not PerfGui or not PerfGui.Parent then
            if conn then conn:Disconnect() end
            return
        end
        frames = frames + 1
        acc = acc + dt
        if acc < 0.45 then return end
        local fps = math.floor(frames / math.max(acc, 0.01) + 0.5)
        frames = 0
        acc = 0
        local cpu, gpu = "--", "--"
        pcall(function()
            local ps = game:GetService("Stats"):FindFirstChild("PerformanceStats")
            if not ps then return end
            local function read(name)
                local o = ps:FindFirstChild(name)
                if not o then return nil end
                local ok, v = pcall(function() return o:GetValue() end)
                if ok and type(v) == "number" then return string.format("%.1f", v) end
            end
            cpu = read("CPU") or cpu
            gpu = read("GPU") or gpu
        end)
        f.Text = "FPS  " .. tostring(fps) .. "\\nCPU  " .. tostring(cpu) .. " ms\\nGPU  " .. tostring(gpu) .. " ms"
    end)
    notify("Monitor ON")
end
_G.VannSetPerf = setPerf

task.defer(function() if _G.VannSetPerf then _G.VannSetPerf(true) end end)
notify("VannHUB ready")
print("[VannHUB] Mine a Antarctica | remotes fixed")
