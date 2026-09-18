-- Banana Cat Hub + Discord Webhook (2026-09-18)
-- CACH DUNG:
-- 1. Thay noi dung BananaCatHub.lua tren repo cua ban bang file nay.
-- 2. Chay loader cu, mo Tab Webhook, nhap URL Discord, bam Gui ngay / bat tu dong.
-- 3. URL chi giu trong phien dang chay. Khong dan URL webhook vao repo cong khai.
-- Moi truong can co request/http_request (hoac BananaCatWebhookConfig.Request).
-- LocalScript Roblox Studio thong thuong chi hien UI; khong gui HTTP tu client.
-- Cac nut Auto ngoai tab Webhook van la giao dien mau cua file goc.
--
-- GIOI HAN DU LIEU:
-- - Tuoi server KHONG suy ra tu DistributedGameTime, os.clock hay gio trong game.
-- - Nhap tuoi server da biet, hoac cung cap SnapshotProvider; neu thieu: Chua xac dinh.
-- - Moc ruong 4 gio chi la UOC TINH. Khong lay modulo tuoi server; khong tu suy ra
--   lan nhat truoc, va khong reset bo dem khi nhan item tu boss/nguon khac.
-- - CakePrinceSpawner (khong tham so bo sung) va CheckTempleDoor la query duoc
--   thay trong script cong khai, khong phai API chinh thuc. Can thu trong game.
-- - Pull Lever chi cho tai khoan dang chay. Khong suy ra tu trang thai can gat cua map.
-- - Khong tu goi thao tac spawn, gat can, di chuyen, farm hoac server hop.
--
-- TICH HOP TUY CHON (dat truoc loader, trong getgenv().BananaCatWebhookConfig):
-- { WebhookURL = "", Request = function(requestOptions) ... end,
--   SnapshotProvider = function()
--     return {serverStartedAt = UNIX_SECONDS, godChaliceNextAt = UNIX_SECONDS,
--       fistOfDarknessNextAt = UNIX_SECONDS, cakeRemaining = 0..500,
--       leverPulled = true_or_false}
--   end }
-- SnapshotProvider phai doc du lieu that da kiem chung; co the bo qua cac truong
-- chua biet. Ham duoc goi moi 30 giay, du lieu het han sau 75 giay.
-- Dong menu/chay lai file se dung cac tac vu webhook cu.
--
-- Nguon tham khao (chi doc, khong tai/chay them code):
-- https://create.roblox.com/docs/reference/engine/classes/Workspace/DistributedGameTime
-- https://docs.discord.com/developers/resources/webhook
-- https://github.com/KzScripts/BloxFruits/blob/main/BloxFruits.lua
-- https://github.com/GlobeReverse/Xenon-Hub/blob/main/Xenon.lua


local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
if not player then
    warn("Banana Cat Hub: hãy chạy ở phía client khi đã vào game.")
    return
end
local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then
    warn("Banana Cat Hub: chưa tìm thấy PlayerGui.")
    return
end

local GUI_NAME = "BananaCatHub_CustomMenu_v1"
local previous = playerGui:FindFirstChild(GUI_NAME)
if previous then previous:Destroy() end

local C = {
    gold = Color3.fromRGB(245, 221, 135),
    text = Color3.fromRGB(246, 246, 246),
    muted = Color3.fromRGB(178, 179, 183),
    panel = Color3.fromRGB(12, 12, 15),
    row = Color3.fromRGB(30, 30, 35),
    edge = Color3.fromRGB(66, 65, 60),
}
local connections, tabs, allToggles, allDropdowns = {}, {}, {}, {}
local webhookTasks = {}
local activeTab, dead, fpsEnabled = nil, false, false
local settings = {transparency = 12}
local applyFilter = function() end

local function new(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props or {}) do obj[key] = value end
    obj.Parent = parent
    return obj
end

local function corner(obj, radius)
    new("UICorner", {CornerRadius = UDim.new(0, radius or 3)}, obj)
end

local function connect(signal, callback)
    local connection = signal:Connect(function(...)
        if not dead then callback(...) end
    end)
    table.insert(connections, connection)
    return connection
end

local function text(parent, value, size, pos, fontSize, color)
    return new("TextLabel", {
        Size = size, Position = pos or UDim2.new(), BackgroundTransparency = 1,
        BorderSizePixel = 0, Text = value, TextColor3 = color or C.text,
        Font = Enum.Font.GothamBold, TextSize = fontSize or 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true,
    }, parent)
end

local function button(parent, value, size, pos)
    local obj = new("TextButton", {
        Size = size, Position = pos or UDim2.new(), BackgroundColor3 = C.row,
        BackgroundTransparency = 0.15, BorderSizePixel = 0,
        Text = value, TextSize = 12, Font = Enum.Font.GothamBold,
        TextColor3 = C.text, TextWrapped = true, AutoButtonColor = true,
    }, parent)
    corner(obj, 3)
    return obj
end

local function searchBox(parent, placeholder, size, pos)
    local obj = new("TextBox", {
        Size = size, Position = pos, BackgroundColor3 = C.row,
        BackgroundTransparency = 0.08, BorderSizePixel = 0,
        ClearTextOnFocus = false, Text = "", PlaceholderText = placeholder,
        PlaceholderColor3 = C.muted, TextColor3 = C.text, TextSize = 11,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
    corner(obj, 3)
    new("UIPadding", {PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 6)}, obj)
    return obj
end

local function magnifier(parent, pos, scale)
    local circle = new("Frame", {
        Size = UDim2.fromOffset(scale, scale), Position = pos,
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, parent)
    corner(circle, scale)
    new("UIStroke", {Color = C.text, Thickness = 1.2}, circle)
    new("Frame", {
        Size = UDim2.fromOffset(5, 1), Position = UDim2.new(1, -1, 1, 1),
        Rotation = 48, BackgroundColor3 = C.text, BorderSizePixel = 0,
    }, circle)
end

local gui = new("ScreenGui", {
    Name = GUI_NAME, ResetOnSpawn = false, IgnoreGuiInset = false,
    DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local function cleanup()
    if dead then return end
    dead = true
    for _, connection in ipairs(connections) do connection:Disconnect() end
    connections = {}
    for _, thread in pairs(webhookTasks) do pcall(task.cancel, thread) end
    webhookTasks = {}
end

connect(gui.Destroying, cleanup)

local function destroy()
    cleanup()
    gui:Destroy()
end

local root = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
}, gui)
local window = new("Frame", {
    Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(700, 450),
    BackgroundTransparency = 1, BorderSizePixel = 0,
}, root)
local titlebar = button(window, "", UDim2.new(1, -58, 0, 28), UDim2.fromOffset(0, 0))
titlebar.BackgroundTransparency = 1
titlebar.AutoButtonColor = false
local brand = text(titlebar, "", UDim2.new(1, 0, 1, 0), UDim2.new(), 13)
brand.RichText = true
brand.Text = '<font color="#F5DD87">Banana Cat Hub</font> - Blox Fruit'
brand.TextXAlignment = Enum.TextXAlignment.Center
brand.TextScaled = true
new("UITextSizeConstraint", {MinTextSize = 9, MaxTextSize = 13}, brand)
local minimize = button(window, "−", UDim2.fromOffset(25, 24), UDim2.new(1, -54, 0, 2))
local close = button(window, "×", UDim2.fromOffset(25, 24), UDim2.new(1, -26, 0, 2))
minimize.TextSize, close.TextSize = 18, 18

local function panel(name)
    local obj = new("Frame", {
        Name = name, BackgroundColor3 = C.panel,
        BackgroundTransparency = settings.transparency / 100,
        BorderSizePixel = 0, ClipsDescendants = true, Active = true,
    }, window)
    corner(obj, 5)
    new("UIStroke", {Color = C.edge, Thickness = 1, Transparency = 0.35}, obj)
    return obj
end

local sidebar = panel("Sidebar")
local main = panel("MainPanel")
local navSearch = searchBox(sidebar, "Search section or Func", UDim2.new(1, -30, 0, 25), UDim2.fromOffset(25, 7))
navSearch.BackgroundTransparency = 1
magnifier(sidebar, UDim2.fromOffset(9, 15), 8)
new("Frame", {
    Size = UDim2.new(1, -12, 0, 1), Position = UDim2.fromOffset(6, 33),
    BackgroundColor3 = C.edge, BorderSizePixel = 0,
}, sidebar)
local nav = new("ScrollingFrame", {
    Position = UDim2.fromOffset(5, 39), Size = UDim2.new(1, -10, 1, -44),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
    ScrollBarImageColor3 = C.muted, CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
}, sidebar)
new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, nav)

local pageTitle = text(main, "Get and Upgrade Items Tab", UDim2.new(1, -42, 0, 29), UDim2.fromOffset(9, 1), 12)
local searchIcon = button(main, "", UDim2.fromOffset(27, 27), UDim2.new(1, -31, 0, 2))
searchIcon.BackgroundTransparency = 1
magnifier(searchIcon, UDim2.fromOffset(7, 7), 8)
local functionSearch = searchBox(main, "Search function...", UDim2.new(1, -43, 0, 25), UDim2.fromOffset(7, 3))
functionSearch.Visible = false
local pageHost = new("Frame", {
    Position = UDim2.fromOffset(7, 33), Size = UDim2.new(1, -14, 1, -40),
    BackgroundTransparency = 1, BorderSizePixel = 0,
}, main)
local noResults = text(main, "Không tìm thấy mục phù hợp.", UDim2.new(1, -24, 0, 64), UDim2.fromOffset(12, 46), 12, C.muted)
noResults.TextXAlignment, noResults.Visible = Enum.TextXAlignment.Center, false
local status = text(window, "Webhook theo dõi • Các nút Auto khác đang là giao diện mẫu", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 1, -18), 10, C.gold)
status.TextXAlignment = Enum.TextXAlignment.Center
status.TextTruncate, status.TextWrapped = Enum.TextTruncate.AtEnd, false

local launcher = button(root, "🍌", UDim2.fromOffset(46, 46), UDim2.fromOffset(12, 12))
launcher.Name, launcher.TextSize, launcher.Visible, launcher.ZIndex = "OpenMenu", 25, false, 20
local hud = text(root, "FPS: --", UDim2.fromOffset(88, 26), UDim2.new(1, -100, 0, 10), 12, C.gold)
hud.BackgroundTransparency, hud.BackgroundColor3 = 0.12, C.panel
hud.TextXAlignment, hud.Visible, hud.ZIndex = Enum.TextXAlignment.Center, false, 20
corner(hud, 4)

local function show(visible)
    window.Visible, launcher.Visible = visible, not visible
    if not visible then
        navSearch:ReleaseFocus()
        functionSearch:ReleaseFocus()
    end
end

connect(minimize.Activated, function() show(false) end)
connect(launcher.Activated, function() show(true) end)
connect(close.Activated, destroy)
connect(Input.InputBegan, function(input, processed)
    if not processed and not Input:GetFocusedTextBox() and input.KeyCode == Enum.KeyCode.RightControl then
        show(not window.Visible)
    end
end)
connect(searchIcon.Activated, function()
    functionSearch.Visible = not functionSearch.Visible
    pageTitle.Visible = not functionSearch.Visible
    if functionSearch.Visible then
        functionSearch:CaptureFocus()
    else
        functionSearch.Text = ""
        functionSearch:ReleaseFocus()
    end
end)

local function selectTab(tab)
    activeTab = tab
    pageTitle.Text = tab.name .. " Tab"
    for _, item in ipairs(tabs) do
        local selected = item == tab
        item.page.Visible = selected
        item.marker.Visible = selected
        item.button.BackgroundTransparency = selected and 0.64 or 1
        item.caption.TextColor3 = selected and C.text or Color3.fromRGB(231, 231, 233)
    end
    noResults.Visible = tab.matches == 0
end

local function addTab(name)
    local tabButton = button(nav, "", UDim2.new(1, -4, 0, 30))
    tabButton.BackgroundTransparency, tabButton.LayoutOrder = 1, #tabs + 1
    local caption = text(tabButton, name, UDim2.new(1, -13, 1, 0), UDim2.fromOffset(9, 0), 11)
    local marker = new("Frame", {
        Size = UDim2.fromOffset(3, 17), Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = C.gold, BorderSizePixel = 0, Visible = false,
    }, tabButton)
    local page = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.muted, Visible = false,
    }, pageHost)
    new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    new("UIPadding", {PaddingBottom = UDim.new(0, 4), PaddingRight = UDim.new(0, 6)}, page)
    local tab = {name = name, button = tabButton, caption = caption, marker = marker, page = page, rows = {}, matches = 0}
    table.insert(tabs, tab)
    connect(tabButton.Activated, function() selectTab(tab) end)
    return tab
end

local function row(tab, title, height)
    local obj = button(tab.page, "", UDim2.new(1, -3, 0, height or 32))
    obj.LayoutOrder = #tab.rows + 1
    table.insert(tab.rows, {object = obj, title = title})
    return obj
end

local function toggle(tab, title, callback)
    local obj = row(tab, title)
    text(obj, title, UDim2.new(1, -41, 1, -4), UDim2.fromOffset(10, 2), 12)
    local box = text(obj, "", UDim2.fromOffset(18, 18), UDim2.new(1, -28, 0.5, -9), 14, C.panel)
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.BackgroundColor3 = C.gold
    corner(box, 2)
    new("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = C.gold, Thickness = 1.2}, box)
    local value = false
    local function set(enabled, quiet)
        value = enabled
        box.Text, box.BackgroundTransparency = enabled and "✓" or "", enabled and 0 or 1
        if callback then
            callback(enabled)
        elseif not quiet then
            status.Text = title .. ": " .. (enabled and "ON" or "OFF") .. " • Chỉ đổi giao diện"
        end
    end
    connect(obj.Activated, function() set(not value, false) end)
    set(false, true)
    local control = {Set = set}
    table.insert(allToggles, control)
    return control
end

local function dropdown(tab, title, values, callback)
    local obj = row(tab, title)
    obj.ClipsDescendants = true
    local head = button(obj, "", UDim2.new(1, 0, 0, 32))
    head.BackgroundTransparency = 1
    local caption = text(head, title, UDim2.new(1, -39, 1, -4), UDim2.fromOffset(10, 2), 12, C.muted)
    local arrow = text(head, "›", UDim2.fromOffset(20, 30), UDim2.new(1, -27, 0, 0), 23)
    arrow.TextXAlignment = Enum.TextXAlignment.Center
    local expanded = false
    local function expand(value)
        expanded = value
        obj.Size = UDim2.new(1, -3, 0, value and (36 + #values * 29) or 32)
        arrow.Text = value and "⌄" or "›"
    end
    for i, value in ipairs(values) do
        local choice = button(obj, tostring(value), UDim2.new(1, -16, 0, 26), UDim2.fromOffset(8, 34 + (i - 1) * 29))
        choice.TextColor3 = C.gold
        connect(choice.Activated, function()
            caption.Text = title .. " " .. tostring(value)
            expand(false)
            if callback then
                callback(value)
            else
                status.Text = tostring(value) .. " • Lựa chọn giao diện"
            end
        end)
    end
    connect(head.Activated, function() expand(not expanded) end)
    table.insert(allDropdowns, {Reset = function() caption.Text = title; expand(false) end})
end

local function action(tab, title, callback)
    local obj = row(tab, title)
    text(obj, title, UDim2.new(1, -22, 1, 0), UDim2.fromOffset(10, 0), 12)
    connect(obj.Activated, callback)
end

local farm = addTab("Farming Other")
local fruit = addTab("Fruit and Raid")
local sea = addTab("Sea Event")
local race = addTab("Upgrade Race")
local items = addTab("Get and Upgrade Items")
local volcano = addTab("Volcano Event")
local esp = addTab("ESP")
local pvp = addTab("PVP")
local webhook = addTab("Tab Webhook")
local setting = addTab("Setting")

-- Hai lua chon dropdown la vi du UI, khong thuc hien chuyen server.
dropdown(items, "Select Method Hop CDK:", {"Normal", "Hop Server"})
for _, name in ipairs({"Auto CDK", "Auto Yama", "Auto Tushita", "Auto TTK", "Auto Saber", "Auto Craft Item Shark Anchor", "Auto Yoru Mini"}) do
    toggle(items, name)
end
-- Cac tab con lai: dieu khien mau, chua gan logic cua game.
for _, name in ipairs({"Auto Farm Level", "Auto Chest", "Auto Material"}) do toggle(farm, name) end
for _, name in ipairs({"Auto Raid", "Auto Awaken", "Auto Store Fruit"}) do toggle(fruit, name) end
for _, name in ipairs({"Auto Sea Event", "Auto Sea Beast", "Auto Repair Boat"}) do toggle(sea, name) end
for _, name in ipairs({"Auto Race V2", "Auto Race V3", "Auto Trial"}) do toggle(race, name) end
for _, name in ipairs({"Auto Volcano Event", "Auto Collect"}) do toggle(volcano, name) end
for _, name in ipairs({"ESP Players", "ESP Fruits", "ESP Chests"}) do toggle(esp, name) end
for _, name in ipairs({"Show Target", "Show Player Distance"}) do toggle(pvp, name) end
-- WEBHOOK_EXTENSION_BEGIN
do
    local Http = game:GetService("HttpService")
    local Replicated = game:GetService("ReplicatedStorage")
    local World = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    local env = type(getgenv) == "function" and getgenv() or _G
    local config = type(env.BananaCatWebhookConfig) == "table" and env.BananaCatWebhookConfig or {}
    local SEA = ({[2753915549] = 1, [4442272183] = 2, [7449423635] = 3})[game.PlaceId]
    local UNKNOWN = "Chưa xác định"
    local POLL, STALE, MIN_SEND = 30, 75, 60
    local CHEST_PERIOD = 4 * 60 * 60 -- Reference estimate; never a confirmed spawn time.
    local started = os.clock()
    local enabled, busy = false, false
    local interval = 300
    local nextSend, retryAt, lastSent = 0, 0, -math.huge
    local lastKey, failures = nil, 0
    local sending = {}
    local manualStart, lastGodChest, lastFistChest
    local providerState, cakeState, leverState = {}, {}, {}

    -- WEBHOOK_CORE_BEGIN: pure functions, also exercised by the offline checks.
    local function finite(value)
        return type(value) == "number" and value == value
            and value > -math.huge and value < math.huge
    end

    local function duration(value)
        if not finite(value) then return UNKNOWN end
        value = math.max(0, math.floor(value))
        return string.format("%02d:%02d:%02d", math.floor(value / 3600), math.floor(value / 60) % 60, value % 60)
    end

    local function validCount(value)
        return finite(value) and value >= 0 and value <= 500 and value % 1 == 0
    end

    local function parseCake(value)
        if validCount(value) then return value end
        if type(value) ~= "string" then return nil end
        local message = string.lower((value:gsub("<[^>]*>", "")))
        local count = tonumber(message:match("(%d+)%s+more%s+enem")
            or message:match("(%d+)%s+enem[^%d]-left")
            or message:match("còn%s+(%d+)%s+quái"))
        if validCount(count) then return count end
        -- Some versions return: "... defeat more enemies. N ...".
        if message:find("enem", 1, true)
            and (message:find("defeat", 1, true) or message:find("kill", 1, true)) then
            local first, second
            for number in message:gmatch("%d+") do
                if first then second = true; break end
                first = tonumber(number)
            end
            if not second and validCount(first) then return first end
        end
        if message:find("do you want", 1, true) and message:find("open the portal", 1, true) then
            return 0 -- Count requirement met; this does not confirm Dough King prerequisites.
        end
        return nil -- An error, an empty reply or unknown text must never become zero.
    end

    local function webhookURL(value)
        value = type(value) == "string" and value:match("^%s*(.-)%s*$") or ""
        local host, path = value:match("^https://([^/]+)(/[^?#]+)")
        local allowed = host == "discord.com" or host == "discordapp.com"
            or host == "canary.discord.com" or host == "ptb.discord.com"
        if not allowed or not path or value:find("#", 1, true) then return nil end
        local id, token = path:match("^/api/webhooks/(%d+)/([%w_%-]+)$")
        if not id then id, token = path:match("^/api/v%d+/webhooks/(%d+)/([%w_%-]+)$") end
        if not id or not token then return nil end
        local query = value:match("%?(.*)$")
        local thread
        if query then
            for part in query:gmatch("[^&]+") do
                if part:match("^thread_id=%d+$") then
                    thread = part
                elseif part ~= "wait=true" and part ~= "wait=false" then
                    return nil
                end
            end
        end
        return "https://" .. host .. path .. "?wait=true" .. (thread and "&" .. thread or "")
    end

    local function chestText(now, serverStart, lastCollected, nextAt, manual)
        if finite(nextAt) and nextAt > 0 then
            if nextAt > now then return "Theo nguồn tích hợp: còn " .. duration(nextAt - now) end
            return "Đã đến mốc từ nguồn tích hợp; chưa xác nhận vật phẩm xuất hiện."
        end
        local base, note = lastCollected, "lần lấy từ rương bạn ghi nhận"
        if not finite(base) then
            base, note = serverStart, manual and "tuổi server bạn nhập" or "mốc mở server từ nguồn tích hợp"
        end
        if not finite(base) or base > now then return UNKNOWN .. " • thiếu mốc server/lần lấy từ rương" end
        local remaining = base + CHEST_PERIOD - now
        if remaining <= 0 then
            return "Đã qua mốc tham khảo 4 giờ; không biết vật phẩm đã bị lấy hay chưa."
        end
        return "Ước tính còn " .. duration(remaining) .. " • từ " .. note .. "; không bảo đảm spawn"
    end

    local function retryDelay(response, decoded)
        local delay = type(decoded) == "table" and tonumber(decoded.retry_after) or nil
        for key, value in pairs(type(response.Headers) == "table" and response.Headers or {}) do
            if string.lower(tostring(key)) == "retry-after" then
                local header = tonumber(value)
                if finite(header) and (not finite(delay) or header > delay) then delay = header end
            end
        end
        return finite(delay) and math.max(1, delay + 1) or 60
    end
    -- WEBHOOK_CORE_END

    local function run(callback)
        if dead then return end
        local key = {}
        local thread = task.defer(function()
            local ok = pcall(callback)
            webhookTasks[key] = nil
            if not ok and not dead then status.Text = "Webhook: gặp lỗi; kiểm tra lại kết nối hoặc dữ liệu game." end
        end)
        webhookTasks[key] = thread
        return thread, key
    end

    local function nowUTC()
        local ok, value = pcall(function() return World:GetServerTimeNow() end)
        if ok and finite(value) then return value end
        return os.time()
    end

    local function fresh(state)
        if state.at and os.clock() - state.at <= STALE then return state.value end
        return nil
    end

    local function probe(state, callback)
        if state.pending or os.clock() < (state.nextAt or 0) then return end
        local generation = {}
        state.generation = generation
        state.pending, state.nextAt = true, os.clock() + POLL
        local thread, key = run(function()
            local ok, value = pcall(callback)
            if dead or state.generation ~= generation then return end
            state.pending, state.value, state.at = false, ok and value or nil, os.clock()
            -- Preserve false: it is a meaningful lever status.
            if ok then state.value = value end
        end)
        state.thread, state.taskKey, state.startedAt = thread, key, os.clock()
    end

    local function expireProbe(state)
        if state.pending and os.clock() - state.startedAt > 12 then
            state.pending, state.value, state.generation = false, nil, nil
            state.nextAt = os.clock() + POLL
            if state.thread then pcall(task.cancel, state.thread) end
            if state.taskKey then webhookTasks[state.taskKey] = nil end
        end
    end

    local function queryGame()
        for _, state in ipairs({providerState, cakeState, leverState}) do expireProbe(state) end
        if type(config.SnapshotProvider) == "function" then
            probe(providerState, config.SnapshotProvider)
        end
        if SEA ~= 3 then return end
        local remotes = Replicated:FindFirstChild("Remotes")
        local comm = remotes and remotes:FindFirstChild("CommF_")
        if not comm or not comm:IsA("RemoteFunction") then return end
        -- Community-observed query signatures; not an official Blox Fruits API.
        -- Do not pass a boolean to CakePrinceSpawner (used for spawning controls).
        probe(cakeState, function() return comm:InvokeServer("CakePrinceSpawner") end)
        probe(leverState, function() return comm:InvokeServer("CheckTempleDoor") end)
    end

    local function held(item)
        local backpack = player:FindFirstChildOfClass("Backpack")
        local character = player.Character
        if (backpack and backpack:FindFirstChild(item)) or (character and character:FindFirstChild(item)) then
            return true
        end
        if backpack and character then return false end
        return nil
    end

    local function livingBoss()
        local enemies = World:FindFirstChild("Enemies")
        if not enemies then return nil end
        for _, enemy in ipairs(enemies:GetChildren()) do
            if enemy.Name:find("Cake Prince", 1, true) or enemy.Name:find("Dough King", 1, true) then
                local humanoid = enemy:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then return enemy.Name end
            end
        end
        return nil -- Missing/streamed-out enemies are not proof the boss is absent.
    end

    local function snapshot()
        local now = nowUTC()
        local extra = fresh(providerState)
        extra = type(extra) == "table" and extra or {}
        local serverStart, manual = extra.serverStartedAt, false
        if not finite(serverStart) or serverStart <= 0 or serverStart > now then
            serverStart, manual = manualStart, manualStart ~= nil
        end
        local age = finite(serverStart) and (now - serverStart) or nil
        local cake = validCount(extra.cakeRemaining) and extra.cakeRemaining or parseCake(fresh(cakeState))
        local lever = extra.leverPulled
        if type(lever) ~= "boolean" then lever = fresh(leverState) end
        if type(lever) ~= "boolean" then lever = nil end
        local god, fist, sweet = held("God's Chalice"), held("Fist of Darkness"), held("Sweet Chalice")
        local boss = livingBoss()
        local cakeText = UNKNOWN .. " • phản hồi game chưa có hoặc không nhận diện được"
        if SEA ~= 3 then
            cakeText = "Chỉ kiểm tra ở Third Sea"
        elseif boss then
            cakeText = "Đang thấy boss: " .. boss
        elseif cake == 0 then
            cakeText = "Còn 0 quái • đã đủ số lượng; chưa xác nhận các điều kiện khác"
        elseif cake then
            cakeText = "Còn " .. cake .. " quái để đạt mốc 500"
        end
        local leverText = UNKNOWN
        if SEA ~= 3 and type(extra.leverPulled) ~= "boolean" then
            leverText = "Vào Third Sea để kiểm tra"
        elseif lever ~= nil then
            leverText = lever and "Đã gạt cần (Pull Lever: YES)" or "Chưa gạt cần (Pull Lever: NO)"
        end
        local function possession(value)
            if value == nil then return UNKNOWN end
            return value and "Có trong túi/đang cầm" or "Không thấy trong túi/nhân vật"
        end
        return {
            now = now,
            serverAge = age and (duration(age) .. (manual and " • bạn nhập" or " • nguồn tích hợp")) or UNKNOWN,
            monitoring = duration(os.clock() - started),
            gameTime = string.format("%02d:%02d", math.floor(Lighting.ClockTime), math.floor(Lighting.ClockTime * 60) % 60),
            cake = cakeText, lever = leverText,
            god = SEA == 3 and chestText(now, serverStart, lastGodChest, extra.godChaliceNextAt, manual) or "Vật phẩm Third Sea",
            fist = SEA == 2 and chestText(now, serverStart, lastFistChest, extra.fistOfDarknessNextAt, manual) or "Vật phẩm Second Sea",
            inventory = "God's Chalice: " .. possession(god) .. "\nFist of Darkness: " .. possession(fist)
                .. "\nSweet Chalice: " .. possession(sweet),
            key = table.concat({tostring(cake and math.ceil(cake / 25)), tostring(lever), tostring(god), tostring(fist), tostring(sweet), boss or ""}, "|"),
        }
    end

    local function labelRow(title, height)
        local box = row(webhook, title, height or 58)
        box.AutoButtonColor = false
        text(box, title, UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 3), 11, C.gold)
        return text(box, "", UDim2.new(1, -20, 1, -26), UDim2.fromOffset(10, 24), 11, C.text)
    end

    local note = labelRow("Webhook Discord", 86)
    note.Text = "Nhập URL, bấm Gửi ngay hoặc bật gửi tự động. Tuổi server có thể chưa xác định. Mốc rương 4 giờ chỉ là tham khảo."
    local urlRow = row(webhook, "Discord Webhook URL", 64)
    text(urlRow, "Discord Webhook URL • chỉ giữ trong phiên này", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 3), 11, C.gold)
    local urlBox = searchBox(urlRow, "https://discord.com/api/webhooks/...", UDim2.new(1, -16, 0, 29), UDim2.fromOffset(8, 27))
    local currentURL = type(config.WebhookURL) == "string" and config.WebhookURL or ""
    urlBox.Text = currentURL == "" and "" or "•••••••• (đã nhập URL)"
    connect(urlBox.Focused, function() urlBox.Text = currentURL end)
    connect(urlBox.FocusLost, function()
        currentURL = urlBox.Text:match("^%s*(.-)%s*$")
        urlBox.Text = currentURL == "" and "" or "•••••••• (đã nhập URL)"
        failures = 0
    end)

    local ageRow = row(webhook, "Tuổi server đã biết (phút)", 64)
    text(ageRow, "Tuổi server đã biết (phút) • tùy chọn", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 3), 11, C.gold)
    local ageBox = searchBox(ageRow, "Để trống nếu bạn không biết", UDim2.new(1, -16, 0, 29), UDim2.fromOffset(8, 27))
    connect(ageBox.FocusLost, function()
        local value = ageBox.Text:match("^%s*(.-)%s*$")
        if value == "" then manualStart = nil; return end
        local minutes = tonumber(value)
        if finite(minutes) and minutes >= 0 and minutes <= 525600 then
            manualStart = nowUTC() - minutes * 60
            status.Text = "Đã đặt tuổi server theo số bạn nhập."
        else
            manualStart, ageBox.Text = nil, ""
            status.Text = "Tuổi server phải là số phút từ 0 đến 525600."
        end
    end)

    dropdown(webhook, "Chu kỳ gửi (mặc định 300 giây):", {60, 120, 300, 600}, function(value)
        interval, nextSend = value, os.clock() + value
    end)
    local autoToggle = toggle(webhook, "Tự động gửi webhook", function(value)
        enabled = value
        if value then nextSend, lastKey = os.clock() + 2, snapshot().key end
        if value then status.Text = "Webhook: đã bật gửi định kỳ và khi trạng thái thay đổi." end
    end)

    local feedback = labelRow("Kết nối webhook", 66)
    feedback.Text = "Chưa gửi. Cần môi trường có hàm request hoặc http_request."
    local timeLabel = labelRow("Server time / Tuổi server", 82)
    local godLabel = labelRow("God's Chalice • thời gian rương", 92)
    local fistLabel = labelRow("Fist of Darkness • thời gian rương", 92)
    local cakeLabel = labelRow("Katakuri / Cake Prince / Dough King", 76)
    local leverLabel = labelRow("Pull Lever • tài khoản đang chạy", 64)
    local itemLabel = labelRow("Vật phẩm đang giữ", 100)

    local function render(s)
        timeLabel.Text = "Tuổi server: " .. s.serverAge .. "\nTheo dõi từ lúc bật script: " .. s.monitoring .. "\nGiờ trong game: " .. s.gameTime
        godLabel.Text, fistLabel.Text = s.god, s.fist
        cakeLabel.Text, leverLabel.Text, itemLabel.Text = s.cake, s.lever, s.inventory
    end

    local function getRequest()
        if type(config.Request) == "function" then return config.Request end
        if type(request) == "function" then return request end
        if type(http_request) == "function" then return http_request end
        if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
        if type(http) == "table" and type(http.request) == "function" then return http.request end
        return nil -- HttpService cannot send HTTP requests from a normal LocalScript.
    end

    local function payload(s)
        local function field(name, value, inline) return {name = name, value = tostring(value), inline = inline or false} end
        return {
            username = "Banana Cat Hub",
            allowed_mentions = {parse = {}},
            embeds = {{
                title = "Blox Fruits • Thông báo server",
                color = 16113031,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", math.floor(s.now)),
                fields = {
                    field("Người chơi", player.Name .. " (" .. tostring(player.UserId) .. ")", true),
                    field("Sea / số người", (SEA and "Sea " .. SEA or "Không nhận diện") .. " • " .. #Players:GetPlayers(), true),
                    field("Server JobId", game.JobId ~= "" and game.JobId or "Studio / chưa có JobId"),
                    field("PlaceId", game.PlaceId, true),
                    field("Tuổi server", s.serverAge, true),
                    field("Theo dõi từ khi bật script", s.monitoring, true),
                    field("Giờ trong game", s.gameTime, true),
                    field("God's Chalice • rương", s.god),
                    field("Fist of Darkness • rương", s.fist),
                    field("Katakuri / số quái còn lại", s.cake),
                    field("Pull Lever • người chơi này", s.lever),
                    field("Vật phẩm đang giữ", s.inventory),
                },
                footer = {text = "Mốc 4 giờ là ước tính; không xác nhận spawn hay lần người khác nhặt. Số quái/lever được đọc khoảng mỗi 30 giây."},
            }},
        }
    end

    local function send(s)
        if dead or busy then return end
        local clock = os.clock()
        local waitFor = math.max(retryAt - clock, MIN_SEND - (clock - lastSent))
        if waitFor > 0 then feedback.Text = "Chờ " .. math.ceil(waitFor) .. " giây trước lần gửi tiếp theo."; return end
        local url = webhookURL(currentURL)
        local transport = getRequest()
        if not url or not transport then
            feedback.Text = not url and "URL Discord webhook chưa hợp lệ."
                or "Môi trường này không có request/http_request để gửi webhook."
            autoToggle.Set(false, true)
            return
        end
        busy, lastSent = true, clock
        local generation = {}
        sending.generation, sending.startedAt = generation, clock
        feedback.Text = "Đang gửi..."
        local thread, taskKey = run(function()
            local bodyOK, body = pcall(function() return Http:JSONEncode(payload(s)) end)
            if not bodyOK then busy = false; feedback.Text = "Không tạo được nội dung webhook."; return end
            local ok, response = pcall(transport, {
                Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"},
                Body = body, Timeout = 15,
            })
            if dead or sending.generation ~= generation then return end
            busy = false
            local code = ok and type(response) == "table" and tonumber(response.StatusCode or response.Status) or nil
            if code and code >= 200 and code < 300 then
                failures, lastKey, nextSend = 0, s.key, os.clock() + interval
                feedback.Text = "Đã gửi lúc " .. os.date("!%H:%M:%S") .. " UTC."
            elseif code == 429 then
                local decodedOK, decoded = pcall(function() return Http:JSONDecode(response.Body or "") end)
                retryAt = os.clock() + retryDelay(response, decodedOK and decoded or nil)
                feedback.Text = "Discord giới hạn tần suất. Tự chờ " .. math.ceil(retryAt - os.clock()) .. " giây."
            elseif code and code >= 400 and code < 500 then
                autoToggle.Set(false, true)
                feedback.Text = "Discord trả HTTP " .. code .. ". Đã tắt tự gửi; kiểm tra URL và quyền webhook."
            else
                failures = failures + 1
                retryAt = os.clock() + math.min(600, 60 * 2 ^ math.min(failures - 1, 4))
                feedback.Text = "Gửi thất bại" .. (code and " (HTTP " .. code .. ")" or " do kết nối") .. ". Sẽ thử lại nếu tự gửi đang bật."
            end
        end)
        sending.thread, sending.taskKey = thread, taskKey
    end

    action(webhook, "Gửi ngay trạng thái đang hiển thị", function() send(snapshot()) end)
    action(webhook, "Làm mới trạng thái game", function()
        queryGame()
        render(snapshot())
        status.Text = "Đang làm mới • truy vấn game tối đa một lần mỗi 30 giây."
    end)
    action(webhook, "Ghi nhận VỪA LẤY God's Chalice TỪ RƯƠNG", function()
        if SEA ~= 3 then status.Text = "God's Chalice: cần Third Sea."; return end
        lastGodChest = nowUTC()
        status.Text = "Đã ghi mốc do bạn xác nhận. Mốc tiếp theo chỉ là ước tính."
    end)
    action(webhook, "Ghi nhận VỪA LẤY Fist of Darkness TỪ RƯƠNG", function()
        if SEA ~= 2 then status.Text = "Fist of Darkness: cần Second Sea."; return end
        lastFistChest = nowUTC()
        status.Text = "Đã ghi mốc do bạn xác nhận. Mốc tiếp theo chỉ là ước tính."
    end)
    action(webhook, "Xóa các mốc thời gian đã nhập", function()
        manualStart, lastGodChest, lastFistChest = nil, nil, nil
        ageBox.Text = ""
        render(snapshot())
    end)

    render(snapshot())
    run(function()
        while not dead do
            queryGame()
            local s = snapshot()
            render(s)
            if busy and os.clock() - sending.startedAt > 20 then
                busy, sending.generation = false, nil
                if sending.thread then pcall(task.cancel, sending.thread) end
                if sending.taskKey then webhookTasks[sending.taskKey] = nil end
                retryAt = os.clock() + 60
                feedback.Text = "Hết thời gian chờ phản hồi webhook; chưa xác nhận gửi thành công."
            end
            if enabled and not busy and os.clock() >= retryAt and os.clock() - lastSent >= MIN_SEND
                and (os.clock() >= nextSend or s.key ~= lastKey) then send(s) end
            task.wait(1)
        end
    end)
end
-- WEBHOOK_EXTENSION_END

toggle(setting, "Show FPS", function(enabled)
    fpsEnabled, hud.Visible = enabled, enabled
end)
dropdown(setting, "Panel Transparency:", {0, 12, 25, 40}, function(value)
    settings.transparency = value
    sidebar.BackgroundTransparency, main.BackgroundTransparency = value / 100, value / 100
    status.Text = "Độ trong suốt: " .. tostring(value) .. "%"
end)

local manuallyPlaced = false
local function fit(center)
    local area = root.AbsoluteSize
    if area.X <= 0 or area.Y <= 0 then return end
    local width = math.min(720, area.X < 560 and area.X - 20 or area.X * 0.84)
    local height = math.min(454, area.Y - 16)
    width, height = math.max(1, width), math.max(1, height)
    window.Size = UDim2.fromOffset(width, height)
    local navWidth = math.floor(width * 0.29)
    sidebar.Position, sidebar.Size = UDim2.fromOffset(0, 30), UDim2.new(0, navWidth, 1, -50)
    main.Position, main.Size = UDim2.fromOffset(navWidth + 7, 30), UDim2.new(1, -navWidth - 7, 1, -50)
    for _, tab in ipairs(tabs) do
        tab.caption.TextSize = width < 420 and 10 or 11
        tab.button.Size = UDim2.new(1, -4, 0, width < 420 and 36 or 30)
    end
    if center or not manuallyPlaced then
        window.Position = UDim2.fromOffset(area.X / 2, area.Y / 2)
        manuallyPlaced = false
    else
        window.Position = UDim2.fromOffset(
            math.clamp(window.Position.X.Offset, width / 2, area.X - width / 2),
            math.clamp(window.Position.Y.Offset, height / 2, area.Y - height / 2)
        )
    end
end

action(setting, "Center Menu", function() fit(true) end)
action(setting, "Reset UI", function()
    for _, item in ipairs(allToggles) do item.Set(false, true) end
    for _, item in ipairs(allDropdowns) do item.Reset() end
    settings.transparency = 12
    sidebar.BackgroundTransparency, main.BackgroundTransparency = 0.12, 0.12
    navSearch.Text, functionSearch.Text = "", ""
    functionSearch.Visible, pageTitle.Visible = false, true
    functionSearch:ReleaseFocus()
    navSearch:ReleaseFocus()
    fit(true)
    selectTab(items)
    status.Text = "CUSTOM UI • Đã khôi phục mặc định"
end)
action(setting, "Hide Menu", function() show(false) end)
action(setting, "Close Menu", destroy)

local function contains(source, query)
    return query == "" or string.find(string.lower(source), query, 1, true) ~= nil
end

applyFilter = function()
    local query = string.lower(navSearch.Text)
    local functionQuery = string.lower(functionSearch.Text)
    local firstVisible
    for _, tab in ipairs(tabs) do
        local nameMatch, globalMatch, count = contains(tab.name, query), false, 0
        for _, entry in ipairs(tab.rows) do
            local globalRowMatch = nameMatch or contains(entry.title, query)
            if globalRowMatch then globalMatch = true end
            entry.object.Visible = globalRowMatch and contains(entry.title, functionQuery)
            if entry.object.Visible then count = count + 1 end
        end
        tab.matches = count
        tab.button.Visible = nameMatch or globalMatch
        if tab.button.Visible and not firstVisible then firstVisible = tab end
    end
    if activeTab and not activeTab.button.Visible and firstVisible then selectTab(firstVisible) end
    noResults.Visible = not activeTab or activeTab.matches == 0
end
connect(navSearch:GetPropertyChangedSignal("Text"), applyFilter)
connect(functionSearch:GetPropertyChangedSignal("Text"), applyFilter)

local pointer, startPosition, windowOrigin
connect(titlebar.InputBegan, function(input)
    if not pointer and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        fit(false)
        pointer, startPosition = input, input.Position
        windowOrigin = Vector2.new(window.Position.X.Offset, window.Position.Y.Offset)
    end
end)
connect(Input.InputChanged, function(input)
    if not pointer or not window.Visible then return end
    if input ~= pointer and not (pointer.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement) then return end
    local delta, area, half = input.Position - startPosition, root.AbsoluteSize, window.AbsoluteSize / 2
    if area.X < half.X * 2 or area.Y < half.Y * 2 then return end
    window.Position = UDim2.fromOffset(
        math.clamp(windowOrigin.X + delta.X, half.X, area.X - half.X),
        math.clamp(windowOrigin.Y + delta.Y, half.Y, area.Y - half.Y)
    )
    manuallyPlaced = true
end)
connect(Input.InputEnded, function(input)
    if pointer and (input == pointer or (pointer.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)) then pointer = nil end
end)
connect(Input.WindowFocusReleased, function() pointer = nil end)
connect(window:GetPropertyChangedSignal("Visible"), function() pointer = nil end)
connect(root:GetPropertyChangedSignal("AbsoluteSize"), function() pointer = nil; fit(false) end)

local elapsed, frames = 0, 0
connect(RunService.RenderStepped, function(dt)
    elapsed, frames = elapsed + dt, frames + 1
    if elapsed >= 0.5 then
        if fpsEnabled then hud.Text = string.format("FPS: %d", math.floor(frames / elapsed + 0.5)) end
        elapsed, frames = 0, 0
    end
end)

selectTab(items)
applyFilter()
fit(true)
task.defer(function() if not dead then fit(true) end end)
