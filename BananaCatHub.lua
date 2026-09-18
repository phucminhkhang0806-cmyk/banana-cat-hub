-- Banana Cat Hub: client-side UI demo.
-- Run as a LocalScript in StarterPlayer > StarterPlayerScripts in Roblox Studio.
-- Game automation controls are UI placeholders; no game automation is implemented.

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
local status = text(window, "CUSTOM UI • Chưa tích hợp chức năng tự động", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 1, -18), 10, C.gold)
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
    table.insert(allToggles, {Set = set})
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
action(webhook, "Webhook chưa được cấu hình", function()
    status.Text = "Chưa có kết nối webhook • Không gửi dữ liệu"
end)

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
