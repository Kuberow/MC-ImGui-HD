-- The way i made this is pretty bad on the backend

local imgui = {
    style = {
        primary = colors.blue,
        secondary = colors.gray,
        text = colors.white,
        background = colors.black
    },
    frames = {

    }
}

--#region ImguiObjects
imgui.objects = {}

function imgui.objects.button(tbl)
    local button = {}
    button.x = tbl.x
    button.y = tbl.y
    button.label = tbl.label
    button.id = tbl.id
    function button.event(ev,parent)
        if ev[1] == "mouse_click" then
            if ev[4] == parent.position.y + button.y then
                local mx = ev[3]
                if mx >= button.x+parent.position.x and mx < parent.position.x+button.x+#button.label then
                    return {
                        type = "button_click",
                        mouseButton = ev[2],
                        id = button.id
                    }
                end
            end
        end
    end

    function button.render()
        term.setCursorPos(button.x,button.y+1)
        term.setBackgroundColor(imgui.style.primary)
        term.setTextColor(colors.white)
        term.write(button.label)
    end

    return button
end

function imgui.objects.label(tbl)
    local button = {}
    button.x = tbl.x
    button.y = tbl.y
    button.label = tbl.label
    button.id = tbl.id
    function button.event(ev,parent)
        
    end

    function button.render()
        term.setCursorPos(button.x,button.y+1)
        term.setBackgroundColor(imgui.style.secondary)
        term.setTextColor(colors.white)
        term.write(button.label)
    end

    return button
end

function imgui.objects.textbox(tbl)
    local button = {}
    button.x = tbl.x
    button.y = tbl.y
    button.placeholder = tbl.placeholder
    button.text = ""
    button.id = tbl.id
    button.typing = false
    function button.event(ev,parent)
        if ev[1] == "mouse_click" then
            if ev[4] == parent.position.y + button.y then
                local mx = ev[3]
                if mx >= button.x+parent.position.x and mx < parent.position.x+button.x+#(#button.text>0 and button.text or button.placeholder) then
                    button.typing = not button.typing;
                else
                    button.typing = false; 
                end
            else
                button.typing = false;
            end
        elseif ev[1] == "key" then
            if button.typing then
                if ev[2] == keys.enter then
                    return {
                        type = "textbox_enter",
                        text = button.text,
                        id = button.id
                    }
                elseif ev[2] == keys.backspace then
                    button.text = button.text:sub(0,#button.text-1)
                end
            end
        elseif ev[1] == "char" then
            if button.typing then
                button.text = button.text..ev[2]
            end
        end
    end

    function button.render()
        term.setCursorPos(button.x,button.y+1)
        term.setBackgroundColor((not button.typing) and imgui.style.secondary or colors.black)
        term.setTextColor(colors.white)
        term.write(#button.text>0 and button.text or button.placeholder)
    end

    return button
end

--#endregion ImguiObjects

function imgui.init(win,parent,log)
    win.setPaletteColor(colors.gray,0x252525)
    imgui.window = win
    imgui.parent = parent
    imgui.termSize = {win.getSize()}
end

function imgui.setStyle(style)
    imgui.style = style
end

function imgui.createFrame(name,x,y,w,h)
    local frame = {
        elements = {}
    }
    frame.win = window.create(imgui.window,x,y,w,h)
    frame.label = name
    frame.style = {
        indent = true;
        maximised = true;
    }

    frame.hold = {}

    frame.position = {
        x = x, y = y
    }

    frame.visible = true

    frame.setVisible = function ( bool )
        frame.visible = bool
    end

    frame.render = function ()
        term.setCursorPos(1,1)
        term.setBackgroundColor(imgui.style.secondary)
        term.clear()
        -- Next line is long af. The line is the topbar.
        term.blit((frame.style.maximised and "\31" or "\30")..(frame.style.indent and "\143" or " "):rep(w-1),colors.toBlit(imgui.style.text)..(colors.toBlit(frame.style.indent and imgui.style.primary or imgui.style.secondary)):rep(w-1),colors.toBlit(imgui.style.primary)..(colors.toBlit(frame.style.indent and imgui.style.secondary or imgui.style.primary)):rep(w-1))
        term.setBackgroundColor(imgui.style.primary)
        term.setTextColor(imgui.style.text)
        term.setCursorPos(3,1)
        term.write(name)
        if frame.style.maximised then for i,a in ipairs(frame.elements) do
            a.render()
        end end
        frame.win.redraw()
    end

    frame.indent = function(bool)
        frame.style.indent = bool
    end

    frame.setMaximised = function ( bool )
        if bool then
            frame.win.reposition(frame.position.x,frame.position.y,w,h)
        else
            frame.win.reposition(frame.position.x,frame.position.y,w,1)
        end
        frame.style.maximised = bool
    end

    frame.insert = function ( el )
        table.insert(frame.elements,el)
    end

    frame.processEvent = function(ev)
        if ev[1] == "mouse_click" then
            local mx,my = ev[3],ev[4]
            if my == frame.position.y then
                if mx == frame.position.x then
                    frame.setMaximised(not frame.style.maximised)
                elseif mx > frame.position.x and mx < frame.position.x + w then
                    frame.hold.offset = mx - frame.position.x
                    frame.holded = true
                end
            end
        elseif ev[1] == "mouse_drag" then
            if frame.holded then
                frame.position.x = ev[3]-frame.hold.offset
                frame.position.y = ev[4]
                frame.win.reposition(ev[3]-frame.hold.offset,ev[4],w,frame.style.maximised and h or 1)
            end
        elseif ev[1] == "mouse_up" then
            frame.holded = false
        end
        if frame.style.maximised then
            local events = {}
            for i,a in ipairs(frame.elements) do
                local e = a.event(ev,frame)
                if e then
                    table.insert(events,e)
                end
            end
            return events
        end
    end

    table.insert(imgui.frames,frame)

    return frame
end

function imgui.render()
    imgui.window.setVisible(false)
    imgui.window.clear()
    for i,a in ipairs(imgui.frames) do
        term.redirect(a.win)
        if a.visible then
            a.render()
        end
        term.redirect(imgui.parent or imgui.window)
    end
    imgui.window.setVisible(true)
end

function imgui.getEvents(ev)
    local events = {}
    for i,a in ipairs(imgui.frames) do
        if a.visible then
            local evs = a.processEvent(ev)
            if evs then
            for i,a in ipairs(evs) do
                a.frameLabel = a.label
                table.insert(events,a)
            end
            end
        end
    end
    return events
end

return imgui