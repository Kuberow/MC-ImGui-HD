local imgui = require("mc-imgui")

local oTerm = term.current()

imgui.init(window.create(term.current(),1,1,term.getSize()),term.current())

local frame = imgui.createFrame("Clicker Game",1,1,20,10)

frame.indent(false)

frame.insert(imgui.objects.button{
    id = "btn_1",
    label = "Click",
    x = 1,
    y = 2,
})

frame.insert(imgui.objects.label{
    id = "label",
    label = "Clicker",
    x = 1,
    y = 1,
})

local clicks = 0

local clickLabel = imgui.objects.label{
    id = "clicks",
    label = "Clicks: ",
    x = 1,
    y = 3
}

frame.insert(clickLabel)

frame.insert(imgui.objects.textbox{
    id = "texbox",
    placeholder = "Enter Text",
    x = 1,
    y = 4
})

local succ, err = pcall(function()while true do
    imgui.render()
    local ev = {os.pullEvent()}
    local imguiEv = imgui.getEvents(ev)
    
    for i,a in ipairs(imguiEv) do
        if a.type == "button_click" then
            clicks = clicks + 1
            clickLabel.label = ("Clicks: %d"):format(clicks)
        end
    end
end end)

term.redirect(oTerm)

if not succ then
    error(err)
end