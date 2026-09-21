-- MC-ImGui HD: a small pixel renderer for CraftOS-PC graphics mode.

local imgui = {
    style = {
        primary = colors.blue,
        secondary = colors.gray,
        text = colors.white,
        background = colors.black,
    },
    frames = {},
    scale = 1,
    cellWidth = 6,
    cellHeight = 9,
    graphics = false,
    pixelMode = false,
    pixelWidth = 0,
    pixelHeight = 0,
    frontBuffer = nil,
    backBuffer = nil,
    activeFrame = nil,
    drawing = false,
    originX = 0,
    originY = 0,
}

local glyphs = {
    [" "] = {"00000", "00000", "00000", "00000", "00000", "00000", "00000"},
    ["0"] = {"01110", "10001", "10011", "10101", "11001", "10001", "01110"},
    ["1"] = {"00100", "01100", "00100", "00100", "00100", "00100", "01110"},
    ["2"] = {"01110", "10001", "00001", "00010", "00100", "01000", "11111"},
    ["3"] = {"11110", "00001", "00001", "01110", "00001", "00001", "11110"},
    ["4"] = {"00010", "00110", "01010", "10010", "11111", "00010", "00010"},
    ["5"] = {"11111", "10000", "10000", "11110", "00001", "00001", "11110"},
    ["6"] = {"01110", "10000", "10000", "11110", "10001", "10001", "01110"},
    ["7"] = {"11111", "00001", "00010", "00100", "01000", "01000", "01000"},
    ["8"] = {"01110", "10001", "10001", "01110", "10001", "10001", "01110"},
    ["9"] = {"01110", "10001", "10001", "01111", "00001", "00001", "01110"},
    [":"] = {"00000", "00100", "00100", "00000", "00100", "00100", "00000"},
    ["-"] = {"00000", "00000", "00000", "11111", "00000", "00000", "00000"},
}

local function pairs(value)
    return next, value, nil
end

local function addLetters()
    local rows = {
        A = {"01110", "10001", "10001", "11111", "10001", "10001", "10001"},
        B = {"11110", "10001", "10001", "11110", "10001", "10001", "11110"},
        C = {"01111", "10000", "10000", "10000", "10000", "10000", "01111"},
        D = {"11110", "10001", "10001", "10001", "10001", "10001", "11110"},
        E = {"11111", "10000", "10000", "11110", "10000", "10000", "11111"},
        F = {"11111", "10000", "10000", "11110", "10000", "10000", "10000"},
        G = {"01111", "10000", "10000", "10111", "10001", "10001", "01111"},
        H = {"10001", "10001", "10001", "11111", "10001", "10001", "10001"},
        I = {"11111", "00100", "00100", "00100", "00100", "00100", "11111"},
        J = {"00111", "00010", "00010", "00010", "10010", "10010", "01100"},
        K = {"10001", "10010", "10100", "11000", "10100", "10010", "10001"},
        L = {"10000", "10000", "10000", "10000", "10000", "10000", "11111"},
        M = {"10001", "11011", "10101", "10101", "10001", "10001", "10001"},
        N = {"10001", "11001", "10101", "10011", "10001", "10001", "10001"},
        O = {"01110", "10001", "10001", "10001", "10001", "10001", "01110"},
        P = {"11110", "10001", "10001", "11110", "10000", "10000", "10000"},
        Q = {"01110", "10001", "10001", "10001", "10101", "10010", "01101"},
        R = {"11110", "10001", "10001", "11110", "10100", "10010", "10001"},
        S = {"01111", "10000", "10000", "01110", "00001", "00001", "11110"},
        T = {"11111", "00100", "00100", "00100", "00100", "00100", "00100"},
        U = {"10001", "10001", "10001", "10001", "10001", "10001", "01110"},
        V = {"10001", "10001", "10001", "10001", "10001", "01010", "00100"},
        W = {"10001", "10001", "10001", "10101", "10101", "11011", "10001"},
        X = {"10001", "10001", "01010", "00100", "01010", "10001", "10001"},
        Y = {"10001", "10001", "01010", "00100", "00100", "00100", "00100"},
        Z = {"11111", "00001", "00010", "00100", "01000", "10000", "11111"},
    }
    for letter, bitmap in pairs(rows) do glyphs[letter] = bitmap end
end

addLetters()

-- Compact 3x5 glyphs keep one text character close to one terminal cell.
local compactFont = {
    [" "] = {"000", "000", "000", "000", "000"},
    ["0"] = {"111", "101", "101", "101", "111"}, ["1"] = {"010", "110", "010", "010", "111"},
    ["2"] = {"110", "001", "010", "100", "111"}, ["3"] = {"110", "001", "010", "001", "110"},
    ["4"] = {"101", "101", "111", "001", "001"}, ["5"] = {"111", "100", "110", "001", "110"},
    ["6"] = {"011", "100", "111", "101", "111"}, ["7"] = {"111", "001", "010", "010", "010"},
    ["8"] = {"111", "101", "111", "101", "111"}, ["9"] = {"111", "101", "111", "001", "110"},
    [":"] = {"000", "010", "000", "010", "000"}, ["-"] = {"000", "000", "111", "000", "000"},
    ["."] = {"000", "000", "000", "000", "010"}, [","] = {"000", "000", "000", "010", "100"},
    ["/"] = {"001", "001", "010", "100", "100"}, ["'"] = {"010", "010", "000", "000", "000"},
    ["("] = {"001", "010", "010", "010", "001"}, [")"] = {"100", "010", "010", "010", "100"},
    ["_"] = {"000", "000", "000", "000", "111"},
    A = {"010", "101", "111", "101", "101"}, B = {"110", "101", "110", "101", "110"},
    C = {"011", "100", "100", "100", "011"}, D = {"110", "101", "101", "101", "110"},
    E = {"111", "100", "110", "100", "111"}, F = {"111", "100", "110", "100", "100"},
    G = {"011", "100", "101", "101", "011"}, H = {"101", "101", "111", "101", "101"},
    I = {"111", "010", "010", "010", "111"}, J = {"001", "001", "001", "101", "010"},
    K = {"101", "101", "110", "101", "101"}, L = {"100", "100", "100", "100", "111"},
    M = {"101", "111", "111", "101", "101"}, N = {"101", "111", "111", "111", "101"},
    O = {"010", "101", "101", "101", "010"}, P = {"110", "101", "110", "100", "100"},
    Q = {"010", "101", "101", "010", "001"}, R = {"110", "101", "110", "101", "101"},
    S = {"011", "100", "010", "001", "110"}, T = {"111", "010", "010", "010", "010"},
    U = {"101", "101", "101", "101", "111"}, V = {"101", "101", "101", "101", "010"},
    W = {"101", "101", "111", "111", "101"}, X = {"101", "101", "010", "101", "101"},
    Y = {"101", "101", "010", "010", "010"}, Z = {"111", "001", "010", "100", "111"},
}

glyphs = compactFont

local function pixelRect(x, y, width, height, colour)
    if width <= 0 or height <= 0 then return end
    if imgui.drawing then
        local left = math.max(0, math.floor(x))
        local top = math.max(0, math.floor(y))
        local right = math.min(imgui.pixelWidth, math.ceil(x + width))
        local bottom = math.min(imgui.pixelHeight, math.ceil(y + height))
        for py = top, bottom - 1 do
            local row = imgui.backBuffer[py]
            if row then
                for px = left, right - 1 do row[px] = colour end
            end
        end
    elseif imgui.canvas.setPixel then
        for py = y, y + height - 1 do
            for px = x, x + width - 1 do imgui.canvas.setPixel(px, py, colour) end
        end
    end
end

local function flushPixels()
    for y = 0, imgui.pixelHeight - 1 do
        local oldRow = imgui.frontBuffer[y]
        local newRow = imgui.backBuffer[y]
        if not oldRow or not newRow then goto nextRow end
        local x = 0
        while x < imgui.pixelWidth do
            if oldRow[x] == newRow[x] then
                x = x + 1
            else
                local colour = newRow[x]
                local start = x
                repeat x = x + 1 until x >= imgui.pixelWidth or oldRow[x] == newRow[x] or newRow[x] ~= colour
                if imgui.canvas.drawPixels then
                    imgui.canvas.drawPixels(start, y, colour, x - start, 1)
                else
                    for px = start, x - 1 do imgui.canvas.setPixel(px, y, colour) end
                end
            end
        end
        ::nextRow::
    end
    imgui.frontBuffer, imgui.backBuffer = imgui.backBuffer, imgui.frontBuffer
end

local function frameOutline(frame, width, height, colour)
    local left = (frame.position.x - 1) * imgui.cellWidth
    local top = (frame.position.y - 1) * imgui.cellHeight + imgui.cellHeight
    local right = left + width * imgui.cellWidth - 2
    local bottom = (frame.position.y - 1) * imgui.cellHeight + height * imgui.cellHeight - 2
    pixelRect(left, bottom, right - left + 2, 2, colour)
    pixelRect(left, top, 2, bottom - top + 2, colour)
    pixelRect(right, top, 2, bottom - top + 2, colour)
end

local function cellRect(x, y, width, height, colour)
    if not imgui.pixelMode then
        imgui.canvas.setCursorPos(x + imgui.originX, y + imgui.originY)
        imgui.canvas.setBackgroundColor(colour)
        imgui.canvas.write((" "):rep(math.max(0, width)))
        return
    end
    pixelRect((x + imgui.originX - 1) * imgui.cellWidth, (y + imgui.originY - 1) * imgui.cellHeight, width * imgui.cellWidth, height * imgui.cellHeight, colour)
end

local function text(x, y, value, colour)
    if not imgui.pixelMode then
        imgui.canvas.setCursorPos(x + imgui.originX, y + imgui.originY)
        imgui.canvas.setTextColor(colour)
        imgui.canvas.write(tostring(value))
        return
    end
    local s = imgui.scale
    x = x + imgui.originX
    y = y + imgui.originY
    value = tostring(value):upper()
    for index = 1, #value do
        local bitmap = glyphs[value:sub(index, index)] or glyphs[" "]
        for row = 1, 5 do
            local line = bitmap[row]
            for column = 1, 3 do
                if line:sub(column, column) == "1" then
                    pixelRect((x - 1) * imgui.cellWidth + (index - 1) * imgui.cellWidth + (column - 1) * s, (y - 1) * imgui.cellHeight + (row - 1) * s, s, s, colour)
                end
            end
        end
    end
end

local function eventPosition(ev)
    if (ev[1] == "mouse_click" or ev[1] == "mouse_drag" or ev[1] == "mouse_up") and imgui.pixelMode then
        local x, y = ev[3], ev[4]
        if x > imgui.termSize[1] or y > imgui.termSize[2] then
            local normalized = {ev[1], ev[2], math.floor(x / imgui.cellWidth) + 1, math.floor(y / imgui.cellHeight) + 1}
            return normalized
        end
    end
    return ev
end

imgui.objects = {}

function imgui.objects.button(tbl)
    local button = {x = tbl.x, y = tbl.y, label = tbl.label, id = tbl.id}
    function button.event(ev, parent)
        if ev[1] == "mouse_click" and ev[4] >= parent.position.y + button.y and ev[4] < parent.position.y + button.y + 1 then
            local left = parent.position.x + button.x
            if ev[3] >= left and ev[3] < left + #button.label then
                return {type = "button_click", mouseButton = ev[2], id = button.id}
            end
        end
    end
    function button.render()
        cellRect(button.x, button.y + 1, #button.label, 1, imgui.style.primary)
        text(button.x, button.y + 1, button.label, imgui.style.text)
    end
    return button
end

function imgui.objects.label(tbl)
    local label = {x = tbl.x, y = tbl.y, label = tbl.label, id = tbl.id}
    function label.event() end
    function label.render()
        text(label.x, label.y + 1, label.label, imgui.style.text)
    end
    return label
end

function imgui.objects.textbox(tbl)
    local box = {
        x = tbl.x,
        y = tbl.y,
        width = tbl.width or math.max(#(tbl.placeholder or ""), 16),
        placeholder = tbl.placeholder or "",
        text = "",
        id = tbl.id,
        typing = false,
    }
    function box.event(ev, parent)
        if ev[1] == "mouse_click" then
            local left = parent.position.x + box.x
            local top = parent.position.y + box.y
            box.typing = ev[4] >= top and ev[4] < top + 1 and ev[3] >= left and ev[3] < left + box.width
        elseif ev[1] == "key" and box.typing then
            if ev[2] == keys.enter then return {type = "textbox_enter", text = box.text, id = box.id}
            elseif ev[2] == keys.backspace then box.text = box.text:sub(1, -2) end
        elseif ev[1] == "char" and box.typing then box.text = box.text .. ev[2] end
    end
    function box.render()
        local value = #box.text > 0 and box.text or box.placeholder
        cellRect(box.x, box.y + 1, box.width, 1, box.typing and imgui.style.primary or imgui.style.secondary)
        text(box.x, box.y + 1, value, imgui.style.text)
    end
    return box
end

function imgui.init(win, parent)
    imgui.canvas = parent or win or term.current()
    imgui.window = win or imgui.canvas
    imgui.parent = parent or imgui.canvas
    imgui.pixelMode = imgui.canvas.setPixel or imgui.canvas.drawPixel or imgui.canvas.drawPixels
    if imgui.pixelMode and imgui.canvas.setGraphicsMode then
        imgui.canvas.setGraphicsMode(1)
        imgui.graphics = true
    end
    if imgui.pixelMode and imgui.canvas.getSize then
        local pixelWidth, pixelHeight = imgui.canvas.getSize(1)
        imgui.pixelWidth, imgui.pixelHeight = pixelWidth, pixelHeight
        imgui.termSize = {math.floor(pixelWidth / imgui.cellWidth), math.floor(pixelHeight / imgui.cellHeight)}
        imgui.frontBuffer, imgui.backBuffer = {}, {}
        for y = 0, pixelHeight - 1 do
            imgui.frontBuffer[y], imgui.backBuffer[y] = {}, {}
            for x = 0, pixelWidth - 1 do
                imgui.frontBuffer[y][x] = false
                imgui.backBuffer[y][x] = imgui.style.background
            end
        end
    else
        imgui.termSize = {imgui.canvas.getSize()}
    end
end

function imgui.setStyle(style)
    for key, value in pairs(style) do imgui.style[key] = value end
end

function imgui.createFrame(name, x, y, width, height)
    local frame = {elements = {}, label = name, width = width, height = height, position = {x = x, y = y}, visible = true, hold = {}, style = {indent = true, maximised = true}, z = #imgui.frames + 1}
    function frame.setVisible(value) frame.visible = value end
    function frame.indent(value) frame.style.indent = value end
    function frame.setMaximised(value) frame.style.maximised = value end
    function frame.minimise() frame.style.maximised = false end
    function frame.restore() frame.style.maximised = true end
    function frame.insert(element) frame.elements[#frame.elements + 1] = element end
    function frame.render()
        imgui.originX, imgui.originY = 0, 0
        local titleColour = frame == imgui.activeFrame and imgui.style.primary or imgui.style.secondary
        cellRect(frame.position.x, frame.position.y, width, 1, titleColour)
        text(frame.position.x, frame.position.y, name, imgui.style.text)
        if not frame.style.maximised then return end
        imgui.originX, imgui.originY = frame.position.x - 1, frame.position.y - 1
        cellRect(1, 2, width, height - 1, imgui.style.background)
        frameOutline(frame, width, height, imgui.style.secondary)
        for index = 1, #frame.elements do frame.elements[index].render() end
        imgui.originX, imgui.originY = 0, 0
    end
    function frame.processEvent(ev)
        ev = eventPosition(ev)
        if ev[1] == "mouse_click" and ev[4] >= frame.position.y and ev[4] < frame.position.y + 1 and ev[3] >= frame.position.x and ev[3] < frame.position.x + width then
            imgui.activeFrame = frame
            for index = #imgui.frames, 1, -1 do
                if imgui.frames[index] == frame then table.remove(imgui.frames, index) break end
            end
            imgui.frames[#imgui.frames + 1] = frame
            if ev[3] == frame.position.x then frame.setMaximised(not frame.style.maximised)
            else frame.hold.offset = ev[3] - frame.position.x; frame.holded = true end
        elseif ev[1] == "mouse_drag" and frame.holded then
            frame.position.x = ev[3] - frame.hold.offset
            frame.position.y = ev[4]
        elseif ev[1] == "mouse_up" then frame.holded = false end
        if not frame.style.maximised then return end
        local events = {}
        for index = 1, #frame.elements do
            local result = frame.elements[index].event(ev, frame)
            if result then events[#events + 1] = result end
        end
        return events
    end
    imgui.frames[#imgui.frames + 1] = frame
    imgui.activeFrame = frame
    return frame
end

function imgui.render()
    if not imgui.pixelMode then
        cellRect(1, 1, imgui.termSize[1], imgui.termSize[2], imgui.style.background)
    else
        for y = 0, imgui.pixelHeight - 1 do
            local row = imgui.backBuffer[y]
            if row then
                for x = 0, imgui.pixelWidth - 1 do row[x] = imgui.style.background end
            end
        end
        imgui.drawing = true
    end
    for index = 1, #imgui.frames do
        local frame = imgui.frames[index]
        if frame.visible then frame.render() end
    end
    if imgui.pixelMode then
        imgui.drawing = false
        flushPixels()
    end
end

function imgui.getEvents(ev)
    ev = eventPosition(ev)
    local events = {}
    for index = #imgui.frames, 1, -1 do
        local frame = imgui.frames[index]
        if frame.visible then
            local frameEvents = frame.processEvent(ev) or {}
            for eventIndex = 1, #frameEvents do
                frameEvents[eventIndex].frameLabel = frame.label
                events[#events + 1] = frameEvents[eventIndex]
            end
            if ev[1] == "mouse_click" and ev[3] >= frame.position.x and ev[3] < frame.position.x + frame.width and ev[4] >= frame.position.y and ev[4] < frame.position.y + frame.height then
                break
            end
        end
    end
    return events
end

return imgui