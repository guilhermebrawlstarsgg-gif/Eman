
-- EMAN HUB V4 Premium Theme Loaded
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local TextChatService  = game:GetService("TextChatService")
local StarterGui       = game:GetService("StarterGui")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local LP   = Players.LocalPlayer
local pGui = LP:WaitForChild("PlayerGui")
local TW   = TweenService

local savedGoalPos       = nil
local goalBallSpeed      = 180
local goalInstantTP      = false
local magnetEnabled      = false
local striking           = false
local tpWalkEnabled      = false
local tpWalkSpeed        = 0.5
local loopTpEnabled      = false
local ultimoCmd          = nil


local function FindBall()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name=="TPS" or v.Name:lower():find("ball")) then return v end
    end
    return nil
end
local function ClaimOwner(ball)
    local char=LP.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        firetouchinterest(ball,char.HumanoidRootPart,0)
        task.wait(0.03)
        firetouchinterest(ball,char.HumanoidRootPart,1)
    end
end
local function FindBallTP()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n=v.Name:upper()
            if n=="TPS" or n:find("BALL") or n=="PRS" or n=="TCS" or n=="TRS" or n=="MPS" then return v end
        end
    end
    return nil
end

local function findGKTool()
    for _,bag in ipairs({LP.Backpack, LP.Character}) do
        if bag then for _,t in ipairs(bag:GetChildren()) do
            if t:IsA("Tool") then local n=t.Name:lower()
                if n:find("goleiro") or n:find("gk") then return t, bag==LP.Character end
            end
        end end
    end
    return nil
end

local function getBallNearest(hrp)
    if not hrp then return nil end
    local nearest, bestDist = nil, math.huge
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name=="TPS" then
            local d=(v.Position-hrp.Position).Magnitude
            if d<bestDist then bestDist=d; nearest=v end
        end
    end
    return nearest
end

local function pressKeyDive(kc)
    task.spawn(function() pcall(function()
        local vim=game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true,kc,false,game); task.wait(0.15); vim:SendKeyEvent(false,kc,false,game)
    end) end)
    task.spawn(function() pcall(function()
        keypress(kc.Value); task.wait(0.15); keyrelease(kc.Value)
    end) end)
end

local function gkDiveTouch(ball)
    local char = LP.Character
    if char then
        for _,name in ipairs({"Left Leg","Right Leg","Left Foot","Right Foot","HumanoidRootPart"}) do
            local part = char:FindFirstChild(name)
            if part then
                pcall(function()
                    firetouchinterest(part,ball,0)
                    firetouchinterest(part,ball,1)
                end)
            end
        end
    end
end

local function getDiveKey(hrp,ball)
    local t=ball.Position-hrp.Position
    local rd=t:Dot(hrp.CFrame.RightVector)
    local ht=t.Y
    local isC=math.abs(rd)<1.8; local isR=rd>=1.8
    local isH=ht>1.5; local isVH=ht>4.5
    if isC then return Enum.KeyCode.R,"High Catch",isVH
    elseif isR then
        if isVH then return Enum.KeyCode.E,"E alto dir",true
        elseif isH then return Enum.KeyCode.E,"E alto dir",false
        else return Enum.KeyCode.C,"C baixo dir",false end
    else
        if isVH then return Enum.KeyCode.Q,"Q alto esq",true
        elseif isH then return Enum.KeyCode.Q,"Q alto esq",false
        else return Enum.KeyCode.Z,"Z baixo esq",false end
    end
end

local function diveIncoming(hrp,ball,detectDist)
    local dist=(ball.Position-hrp.Position).Magnitude
    if dist>detectDist then return false end
    local vel=ball.AssemblyLinearVelocity
    local tp=hrp.Position-ball.Position
    if tp.Magnitude<=0.01 then return true end
    return tp.Unit:Dot(vel)>3 or dist<6
end

local adacOn=false; local adMiniSG=nil; local adCatchReach=12
local lastDive=0; local DIVE_CD=1.0

function executarCMD(c)
    local char=LP.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    local root=char and char:FindFirstChild("HumanoidRootPart")
    if c=="kill" then if char then char:BreakJoints() end
    elseif c=="freeze" then if hum then hum.WalkSpeed=0 end
    elseif c=="unfreeze" then if hum then hum.WalkSpeed=16 end
    elseif c=="fling" then if root then TW:Create(root,TweenInfo.new(1),{CFrame=CFrame.new(0,1e5,0)}):Play() end end
end
local function processMsg(text)
    if not text or not text:match("^eman|") then return end
    local parts={}; for p in text:gmatch("[^|]+") do table.insert(parts,p) end
    if #parts<3 then return end
    if parts[3]:lower()~=LP.Name:lower() then return end
    if parts[2]=="ping" then
        if not getgenv().EMANHUB_PONG then getgenv().EMANHUB_PONG={} end
        getgenv().EMANHUB_PONG[LP.Name]=true
        local ch=TextChatService.TextChannels:FindFirstChild("RBXGeneral") or TextChatService.TextChannels:GetChildren()[1]
        if ch then task.wait(0.1); ch:SendAsync("eman|pong|"..LP.Name) end
        return
    end
    executarCMD(parts[2])
end
local function conectar(canal)
    if canal:IsA("TextChannel") then
        canal.MessageReceived:Connect(function(msg) processMsg(msg.Text or "") end)
    end
end
for _,ch in pairs(TextChatService.TextChannels:GetChildren()) do conectar(ch) end
TextChatService.TextChannels.ChildAdded:Connect(conectar)
task.spawn(function()
    while true do task.wait(0.1)
        local cmd=getgenv().EMANHUB_CMD
        if cmd and cmd.tick~=(ultimoCmd and ultimoCmd.tick) then
            ultimoCmd=cmd
            if cmd.alvo==LP.Name then executarCMD(cmd.comando) end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not tpWalkEnabled or not LP.Character then return end
    local hum=LP.Character:FindFirstChild("Humanoid")
    local hrp=LP.Character:FindFirstChild("HumanoidRootPart")
    if hum and hrp and hum.MoveDirection.Magnitude>0 then
        hrp.CFrame=hrp.CFrame+(hum.MoveDirection*tpWalkSpeed)
    end
end)

RunService.Heartbeat:Connect(function()
    if not magnetEnabled or not savedGoalPos or striking then return end
    local char=LP.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local ball=FindBall(); if not ball then return end

    local distBall = (ball.Position - hrp.Position).Magnitude

    if goalInstantTP then
        if distBall <= 5 then
            striking = true
            task.spawn(function()
                ClaimOwner(ball)
                ball.CFrame = CFrame.new(savedGoalPos)
                ball.AssemblyLinearVelocity = Vector3.zero
            end)
            task.delay(1.5, function() striking = false end)
        end
    else
        if distBall <= 6 or ball.AssemblyLinearVelocity.Magnitude >= 10 then
            striking = true; ClaimOwner(ball)
            local conn; conn=RunService.Heartbeat:Connect(function()
                if not magnetEnabled or goalInstantTP or not ball or not ball.Parent then
                    conn:Disconnect(); striking=false; return
                end
                local dir=(savedGoalPos-ball.Position).Unit
                ball.AssemblyLinearVelocity=dir*goalBallSpeed
                if (savedGoalPos-ball.Position).Magnitude<3 then
                    ball.AssemblyLinearVelocity=Vector3.zero; conn:Disconnect(); striking=false
                end
            end)
        end
    end
    end)

local BG    = Color3.fromRGB(8,10,18)
local SIDE  = Color3.fromRGB(11,13,23)
local TOP   = Color3.fromRGB(12,15,27)
local ITEM  = Color3.fromRGB(16,20,34)
local ITEM2 = Color3.fromRGB(20,25,42)
local BLUE  = Color3.fromRGB(80,145,255)
local BLUEL = Color3.fromRGB(125,185,255)
local BLUED = Color3.fromRGB(35,72,145)
local TEXT  = Color3.fromRGB(235,241,255)
local TEXTD = Color3.fromRGB(145,158,185)
local RED   = Color3.fromRGB(240,72,90)
local GREEN = Color3.fromRGB(45,205,125)
local WHITE = Color3.new(1,1,1)

local function corner(r,p)
    local o=Instance.new("UICorner")
    o.CornerRadius=UDim.new(0,r)
    o.Parent=p
    return o
end

local function stroke(c,t,p,trans)
    local o=Instance.new("UIStroke")
    o.Color=c
    o.Thickness=t
    o.Transparency=trans or 0
    o.Parent=p
    return o
end

local function gradient(p,c1,c2,rot)
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new(c1,c2)
    g.Rotation=rot or 0
    g.Parent=p
    return g
end

local function equalColor(a,b)
    return a and b and a == b
end

local notifSG = Instance.new("ScreenGui")
notifSG.Name = "EmanNotif"
notifSG.ResetOnSpawn = false
notifSG.DisplayOrder = 1000
notifSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notifSG.Parent = pGui

local function notify(msg, col)
    col = col or BLUE
    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(330, 48)
    card.Position = UDim2.new(0.5, 0, 0, -70)
    card.AnchorPoint = Vector2.new(0.5, 0)
    card.BackgroundColor3 = Color3.fromRGB(12,15,26)
    card.BackgroundTransparency = 0.04
    card.BorderSizePixel = 0
    card.ZIndex = 100
    card.Parent = notifSG
    corner(14,card)
    stroke(col,1.5,card)
    gradient(card,Color3.fromRGB(18,22,38),Color3.fromRGB(10,13,23),0)

    local glow = Instance.new("Frame",card)
    glow.Size = UDim2.new(0,3,1,-12)
    glow.Position = UDim2.new(0,7,0,6)
    glow.BackgroundColor3 = col
    glow.BorderSizePixel = 0
    glow.ZIndex = 101
    corner(2,glow)

    local icon = Instance.new("TextLabel",card)
    icon.Size = UDim2.fromOffset(28,28)
    icon.Position = UDim2.new(0,18,0.5,-14)
    icon.BackgroundColor3 = Color3.fromRGB(255,255,255)
    icon.BackgroundTransparency = 0.92
    icon.Text = "•"
    icon.TextColor3 = col
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 18
    icon.ZIndex = 102
    corner(9,icon)

    local lbl = Instance.new("TextLabel",card)
    lbl.Size = UDim2.new(1,-62,1,0)
    lbl.Position = UDim2.new(0,52,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = msg
    lbl.TextColor3 = TEXT
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.ZIndex = 102

    local inScale = Instance.new("UIScale",card)
    inScale.Scale = 0.92
    TW:Create(card,TweenInfo.new(0.32,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,0,0,18)}):Play()
    TW:Create(inScale,TweenInfo.new(0.32,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()

    task.delay(2.6,function()
        if not card.Parent then return end
        local tw=TW:Create(card,TweenInfo.new(0.28,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Position=UDim2.new(0.5,0,0,-65)})
        tw:Play()
        TW:Create(inScale,TweenInfo.new(0.28,Enum.EasingStyle.Quint),{Scale=0.94}):Play()
        task.wait(0.32)
        if card.Parent then card:Destroy() end
    end)
end

if pGui:FindFirstChild("EmanHub") then pGui.EmanHub:Destroy() end

local SG=Instance.new("ScreenGui")
SG.Name="EmanHub"
SG.ResetOnSpawn=false
SG.DisplayOrder=999
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.Parent=pGui

-- Som de clique seguro para os controles da interface.
local SoundService = game:GetService("SoundService")
local CLICK_SOUND_ID = "rbxassetid://6026984224"
local clickSound = Instance.new("Sound")
clickSound.Name = "EmanClick"
clickSound.SoundId = CLICK_SOUND_ID
clickSound.Volume = 0.28
clickSound.PlaybackSpeed = 1.03
clickSound.Parent = SoundService

local function playClick()
    pcall(function()
        clickSound:Play()
    end)
end

local Main=Instance.new("Frame",SG)
Main.Name="Main"
Main.Size=UDim2.fromOffset(720,500)
Main.Position=UDim2.new(0.5,-360,0.5,-250)
Main.BackgroundColor3=Color3.fromRGB(11,12,18)
Main.BackgroundTransparency=0
Main.BorderSizePixel=0
Main.ZIndex=10
Main.Active=true
Main.Draggable=false
corner(10,Main)
stroke(Color3.fromRGB(54,59,76),1.2,Main,0.05)
local MainScale=Instance.new("UIScale",Main)
MainScale.Scale=0.94

local Shadow=Instance.new("Frame",SG)
Shadow.Name="Shadow"
Shadow.Size=Main.Size
Shadow.Position=Main.Position + UDim2.fromOffset(0,8)
Shadow.BackgroundColor3=Color3.fromRGB(0,0,0)
Shadow.BackgroundTransparency=0.48
Shadow.BorderSizePixel=0
Shadow.ZIndex=1
corner(12,Shadow)

-- Browser-like chrome, matching the reference layout.
local TopBar=Instance.new("Frame",Main)
TopBar.Size=UDim2.new(1,0,0,42)
TopBar.BackgroundColor3=Color3.fromRGB(24,25,32)
TopBar.BorderSizePixel=0
TopBar.ZIndex=11
corner(10,TopBar)
local TopMask=Instance.new("Frame",TopBar)
TopMask.Size=UDim2.new(1,0,0,12)
TopMask.Position=UDim2.new(0,0,1,-12)
TopMask.BackgroundColor3=Color3.fromRGB(24,25,32)
TopMask.BorderSizePixel=0
TopMask.ZIndex=11

local BrowserDot=Instance.new("Frame",TopBar)
BrowserDot.Size=UDim2.fromOffset(14,14)
BrowserDot.Position=UDim2.new(0,10,0.5,-7)
BrowserDot.BackgroundColor3=BLUED
BrowserDot.BorderSizePixel=0
BrowserDot.ZIndex=13
corner(7,BrowserDot)
stroke(BLUE,1,BrowserDot,0.1)
local LogoWrap=BrowserDot
local logo=Instance.new("ImageLabel",LogoWrap)
logo.Size=UDim2.new(0.72,0,0.72,0)
logo.Position=UDim2.new(0.14,0,0.14,0)
logo.BackgroundTransparency=1
logo.Image="rbxassetid://110219163753015"
logo.ZIndex=14

local tTitle=Instance.new("TextLabel",TopBar)
tTitle.Size=UDim2.new(0,190,0,16)
tTitle.Position=UDim2.new(0,32,0,6)
tTitle.BackgroundTransparency=1
tTitle.Text="EMAN HUB"
tTitle.TextColor3=Color3.fromRGB(225,227,235)
tTitle.Font=Enum.Font.GothamBold
tTitle.TextSize=11
tTitle.TextXAlignment=Enum.TextXAlignment.Left
tTitle.ZIndex=13

local tSub=Instance.new("TextLabel",TopBar)
tSub.Size=UDim2.new(0,230,0,12)
tSub.Position=UDim2.new(0,32,0,22)
tSub.BackgroundTransparency=1
tSub.Text="eman hub • premium edition"
tSub.TextColor3=Color3.fromRGB(118,123,137)
tSub.Font=Enum.Font.Gotham
tSub.TextSize=7
tSub.TextXAlignment=Enum.TextXAlignment.Left
tSub.ZIndex=13

local URLBox=Instance.new("Frame",TopBar)
URLBox.Size=UDim2.fromOffset(210,22)
URLBox.Position=UDim2.new(0.5,-105,0.5,-11)
URLBox.BackgroundColor3=Color3.fromRGB(17,18,24)
URLBox.BorderSizePixel=0
URLBox.ZIndex=13
corner(6,URLBox)
local URLText=Instance.new("TextLabel",URLBox)
URLText.Size=UDim2.new(1,-14,1,0)
URLText.Position=UDim2.new(0,7,0,0)
URLText.BackgroundTransparency=1
URLText.Text="eman hub / dashboard"
URLText.TextColor3=Color3.fromRGB(112,116,129)
URLText.Font=Enum.Font.Gotham
URLText.TextSize=7
URLText.TextXAlignment=Enum.TextXAlignment.Left
URLText.ZIndex=14

local Hint=Instance.new("TextLabel",TopBar)
Hint.Size=UDim2.fromOffset(120,18)
Hint.Position=UDim2.new(1,-266,0.5,-9)
Hint.BackgroundTransparency=1
Hint.Text="Min: RightShift"
Hint.TextColor3=Color3.fromRGB(86,90,104)
Hint.Font=Enum.Font.Gotham
Hint.TextSize=6
Hint.TextXAlignment=Enum.TextXAlignment.Right
Hint.ZIndex=14

local OnlinePill=Instance.new("Frame",TopBar)
OnlinePill.Size=UDim2.fromOffset(68,22)
OnlinePill.Position=UDim2.new(1,-112,0.5,-11)
OnlinePill.BackgroundColor3=Color3.fromRGB(14,29,24)
OnlinePill.BorderSizePixel=0
OnlinePill.ZIndex=14
corner(7,OnlinePill)
stroke(GREEN,1,OnlinePill,0.25)
local OnlineDot=Instance.new("Frame",OnlinePill)
OnlineDot.Size=UDim2.fromOffset(6,6)
OnlineDot.Position=UDim2.new(0,8,0.5,-3)
OnlineDot.BackgroundColor3=GREEN
OnlineDot.BorderSizePixel=0
OnlineDot.ZIndex=15
corner(3,OnlineDot)
local OnlineText=Instance.new("TextLabel",OnlinePill)
OnlineText.Size=UDim2.new(1,-22,1,0)
OnlineText.Position=UDim2.new(0,19,0,0)
OnlineText.BackgroundTransparency=1
OnlineText.Text="ONLINE"
OnlineText.TextColor3=GREEN
OnlineText.Font=Enum.Font.GothamBold
OnlineText.TextSize=7
OnlineText.TextXAlignment=Enum.TextXAlignment.Left
OnlineText.ZIndex=15

local MinBtn=Instance.new("TextButton",TopBar)
MinBtn.Size=UDim2.fromOffset(24,22)
MinBtn.Position=UDim2.new(1,-39,0.5,-11)
MinBtn.BackgroundColor3=Color3.fromRGB(49,51,62)
MinBtn.Text="—"
MinBtn.TextColor3=Color3.fromRGB(192,194,202)
MinBtn.Font=Enum.Font.GothamBold
MinBtn.TextSize=13
MinBtn.BorderSizePixel=0
MinBtn.ZIndex=15
corner(7,MinBtn)
stroke(Color3.fromRGB(78,82,96),1,MinBtn,0.3)

local CloseBtn=Instance.new("TextButton",TopBar)
CloseBtn.Size=UDim2.fromOffset(24,22)
CloseBtn.Position=UDim2.new(1,-12,0.5,-11)
CloseBtn.AnchorPoint=Vector2.new(1,0)
CloseBtn.BackgroundColor3=Color3.fromRGB(67,26,36)
CloseBtn.Text="×"
CloseBtn.TextColor3=Color3.fromRGB(235,112,130)
CloseBtn.Font=Enum.Font.GothamBold
CloseBtn.TextSize=13
CloseBtn.BorderSizePixel=0
CloseBtn.ZIndex=15
corner(7,CloseBtn)
stroke(RED,1,CloseBtn,0.3)

local SideBar=Instance.new("Frame",Main)
SideBar.Size=UDim2.new(0,64,1,-42)
SideBar.Position=UDim2.new(0,0,0,42)
SideBar.BackgroundColor3=Color3.fromRGB(14,15,22)
SideBar.BorderSizePixel=0
SideBar.ZIndex=11

local SideGlow=Instance.new("Frame",SideBar)
SideGlow.Size=UDim2.new(0,1,1,0)
SideGlow.Position=UDim2.new(1,-1,0,0)
SideGlow.BackgroundColor3=Color3.fromRGB(38,43,58)
SideGlow.BorderSizePixel=0
SideGlow.ZIndex=12

local SideTabArea=Instance.new("ScrollingFrame",SideBar)
SideTabArea.Size=UDim2.new(1,0,1,-54)
SideTabArea.Position=UDim2.new(0,0,0,0)
SideTabArea.BackgroundTransparency=1
SideTabArea.BorderSizePixel=0
SideTabArea.ZIndex=12
SideTabArea.ScrollingDirection=Enum.ScrollingDirection.Y
SideTabArea.ScrollBarThickness=0
SideTabArea.CanvasSize=UDim2.new(0,0,0,0)
SideTabArea.AutomaticCanvasSize=Enum.AutomaticSize.Y
SideTabArea.ScrollingEnabled=true

local SideList=Instance.new("UIListLayout",SideTabArea)
SideList.SortOrder=Enum.SortOrder.LayoutOrder
SideList.Padding=UDim.new(0,7)
local SidePad=Instance.new("UIPadding",SideTabArea)
SidePad.PaddingTop=UDim.new(0,12)
SidePad.PaddingLeft=UDim.new(0,8)
SidePad.PaddingRight=UDim.new(0,8)

local tabsData={}
local pageTitles={}

local PageArea=Instance.new("Frame",Main)
PageArea.Size=UDim2.new(1,-64,1,-42)
PageArea.Position=UDim2.new(0,64,0,42)
PageArea.BackgroundColor3=Color3.fromRGB(8,9,14)
PageArea.BorderSizePixel=0
PageArea.ClipsDescendants=true
PageArea.ZIndex=11

local ProfileCard=Instance.new("Frame",SideBar)
ProfileCard.Size=UDim2.new(1,-10,0,44)
ProfileCard.Position=UDim2.new(0,5,1,-50)
ProfileCard.BackgroundColor3=Color3.fromRGB(18,20,30)
ProfileCard.BorderSizePixel=0
ProfileCard.ZIndex=14
corner(10,ProfileCard)
stroke(BLUED,1,ProfileCard,0.15)

local avatarImg=Instance.new("ImageLabel",ProfileCard)
avatarImg.Size=UDim2.fromOffset(30,30)
avatarImg.Position=UDim2.new(0,7,0.5,-15)
avatarImg.BackgroundColor3=BLUED
avatarImg.Image="rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=150&h=150"
avatarImg.ZIndex=15
corner(9,avatarImg)
local avatarStroke=stroke(BLUE,1.2,avatarImg)

local avatarStatus=Instance.new("Frame",ProfileCard)
avatarStatus.Size=UDim2.fromOffset(7,7)
avatarStatus.Position=UDim2.new(0,31,1,-13)
avatarStatus.BackgroundColor3=GREEN
avatarStatus.BorderSizePixel=0
avatarStatus.ZIndex=16
corner(4,avatarStatus)

local prn=Instance.new("TextLabel",ProfileCard)
prn.Size=UDim2.new(1,-43,0,14)
prn.Position=UDim2.new(0,41,0,6)
prn.BackgroundTransparency=1
prn.Text=LP.DisplayName ~= "" and LP.DisplayName or LP.Name
prn.TextColor3=Color3.fromRGB(225,227,235)
prn.Font=Enum.Font.GothamBold
prn.TextSize=8
prn.TextXAlignment=Enum.TextXAlignment.Left
prn.TextTruncate=Enum.TextTruncate.AtEnd
prn.ZIndex=15

local userLbl=Instance.new("TextLabel",ProfileCard)
userLbl.Size=UDim2.new(1,-43,0,12)
userLbl.Position=UDim2.new(0,41,0,19)
userLbl.BackgroundTransparency=1
userLbl.Text="@"..LP.Name
userLbl.TextColor3=Color3.fromRGB(128,132,146)
userLbl.Font=Enum.Font.Gotham
userLbl.TextSize=7
userLbl.TextXAlignment=Enum.TextXAlignment.Left
userLbl.TextTruncate=Enum.TextTruncate.AtEnd
userLbl.ZIndex=15

local statusLbl=Instance.new("TextLabel",ProfileCard)
statusLbl.Size=UDim2.new(1,-43,0,10)
statusLbl.Position=UDim2.new(0,41,0,30)
statusLbl.BackgroundTransparency=1
statusLbl.Text="● ONLINE"
statusLbl.TextColor3=GREEN
statusLbl.Font=Enum.Font.GothamBold
statusLbl.TextSize=6
statusLbl.TextXAlignment=Enum.TextXAlignment.Left
statusLbl.ZIndex=15

local function makePage()
    local page=Instance.new("ScrollingFrame",PageArea)
    page.Size=UDim2.new(1,0,1,0)
    page.Position=UDim2.new(0,14,0,0)
    page.BackgroundTransparency=1
    page.BorderSizePixel=0
    page.ScrollBarThickness=3
    page.ScrollBarImageColor3=BLUE
    page.ScrollBarImageTransparency=0.35
    page.ZIndex=12
    page.Visible=false
    page.CanvasSize=UDim2.new(0,0,0,0)
    page.AutomaticCanvasSize=Enum.AutomaticSize.Y
    local pageScale=Instance.new("UIScale",page)
    pageScale.Name="EmanPageScale"
    pageScale.Scale=1
    local ll=Instance.new("UIListLayout",page)
    ll.SortOrder=Enum.SortOrder.LayoutOrder
    ll.Padding=UDim.new(0,8)
    local lp=Instance.new("UIPadding",page)
    lp.PaddingTop=UDim.new(0,14)
    lp.PaddingLeft=UDim.new(0,12)
    lp.PaddingRight=UDim.new(0,12)
    lp.PaddingBottom=UDim.new(0,16)
    return page
end

local function buttonScale(btn)
    local sc=btn:FindFirstChild("EmanButtonScale")
    if not sc then
        sc=Instance.new("UIScale",btn)
        sc.Name="EmanButtonScale"
    end
    sc.Scale=1
    btn.MouseEnter:Connect(function()
        TW:Create(sc,TweenInfo.new(0.12,Enum.EasingStyle.Quad),{Scale=1.02}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TW:Create(sc,TweenInfo.new(0.12,Enum.EasingStyle.Quad),{Scale=1}):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        playClick()
        TW:Create(sc,TweenInfo.new(0.06,Enum.EasingStyle.Quad),{Scale=0.96}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TW:Create(sc,TweenInfo.new(0.12,Enum.EasingStyle.Back),{Scale=1.02}):Play()
    end)
    return sc
end

local function makeTabBtn(name,icon,page)
    pageTitles[page]=name
    local btn=Instance.new("TextButton",SideTabArea)
    btn.Size=UDim2.new(1,0,0,46)
    btn.BackgroundColor3=Color3.fromRGB(17,19,28)
    btn.Text=""
    btn.BorderSizePixel=0
    btn.Active=true
    btn.AutoButtonColor=false
    btn.ZIndex=13
    btn.LayoutOrder=#tabsData+1
    corner(9,btn)
    local bstroke=stroke(Color3.fromRGB(32,36,50),1,btn,0.18)

    local ind=Instance.new("Frame",btn)
    ind.Size=UDim2.new(0,3,1,-10)
    ind.Position=UDim2.new(0,0,0,5)
    ind.BackgroundColor3=BLUE
    ind.BorderSizePixel=0
    ind.ZIndex=16
    ind.Visible=false
    corner(2,ind)

    local iconBg=Instance.new("Frame",btn)
    iconBg.Size=UDim2.fromOffset(34,34)
    iconBg.Position=UDim2.new(0.5,-17,0.5,-17)
    iconBg.BackgroundColor3=Color3.fromRGB(24,26,37)
    iconBg.BorderSizePixel=0
    iconBg.ZIndex=14
    corner(8,iconBg)
    local il=Instance.new("TextLabel",iconBg)
    il.Size=UDim2.new(1,0,1,0)
    il.BackgroundTransparency=1
    il.Text=icon
    il.TextColor3=Color3.fromRGB(137,142,157)
    il.Font=Enum.Font.GothamBold
    il.TextSize=16
    il.ZIndex=15

    local tooltip=Instance.new("TextLabel",btn)
    tooltip.Size=UDim2.fromOffset(92,24)
    tooltip.Position=UDim2.new(1,8,0.5,-12)
    tooltip.BackgroundColor3=Color3.fromRGB(23,25,34)
    tooltip.BorderSizePixel=0
    tooltip.Text=name
    tooltip.TextColor3=Color3.fromRGB(215,218,227)
    tooltip.Font=Enum.Font.GothamMedium
    tooltip.TextSize=8
    tooltip.Visible=false
    tooltip.ZIndex=200
    corner(7,tooltip)
    stroke(Color3.fromRGB(46,50,64),1,tooltip,0.2)

    buttonScale(btn)
    local t={btn=btn,page=page,ind=ind,nl=tooltip,il=il,iconBg=iconBg,tooltip=tooltip,stroke=bstroke}
    table.insert(tabsData,t)

    btn.MouseEnter:Connect(function()
        if not page.Visible then
            TW:Create(btn,TweenInfo.new(0.13),{BackgroundColor3=Color3.fromRGB(22,24,35)}):Play()
        end
        tooltip.Visible=true
    end)
    btn.MouseLeave:Connect(function()
        if not page.Visible then
            TW:Create(btn,TweenInfo.new(0.13),{BackgroundColor3=Color3.fromRGB(17,19,28)}):Play()
        end
        tooltip.Visible=false
    end)

    btn.Activated:Connect(function()
        for _,td in pairs(tabsData) do
            td.page.Visible=false
            td.ind.Visible=false
            td.btn.BackgroundColor3=Color3.fromRGB(17,19,28)
            td.il.TextColor3=Color3.fromRGB(137,142,157)
            td.iconBg.BackgroundColor3=Color3.fromRGB(24,26,37)
            td.stroke.Color=Color3.fromRGB(32,36,50)
        end
        playClick()
        page.Visible=true
        page.Position=UDim2.new(0,14,0,0)
        ind.Visible=true
        btn.BackgroundColor3=Color3.fromRGB(25,37,57)
        il.TextColor3=BLUEL
        iconBg.BackgroundColor3=Color3.fromRGB(31,51,82)
        bstroke.Color=BLUED
        TW:Create(page,TweenInfo.new(0.22,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,0,0)}):Play()
        local ps=page:FindFirstChild("EmanPageScale")
        if ps then
            ps.Scale=0.985
            TW:Create(ps,TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
        end
        TW:Create(ind,TweenInfo.new(0.16,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,4,1,-8),Position=UDim2.new(0,0,0,4)}):Play()
    end)
    return btn
end

local pageCred   = makePage()
local pageMenu   = makePage()
local pagePlayer = makePage()
local pageBola   = makePage()
local pageBoost  = makePage()
local pageFechar = makePage()

makeTabBtn("Início","⌂",pageCred)
makeTabBtn("Menu","▦",pageMenu)
makeTabBtn("Player","♟",pagePlayer)
makeTabBtn("Bola","⚽",pageBola)
makeTabBtn("Boost","⚡",pageBoost)
makeTabBtn("Fechar","×",pageFechar)

-- Header drag.
do
    local dragging=false
    local dragStart=nil
    local startPos=nil
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=input.Position
            startPos=Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-dragStart
            Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
            Shadow.Position=Main.Position+UDim2.fromOffset(0,8)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
end

local function animateHub(show)
    if show then
        Main.Visible=true
        MainScale.Scale=0.92
        Shadow.Visible=true
        TW:Create(MainScale,TweenInfo.new(0.34,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
        TW:Create(Shadow,TweenInfo.new(0.28,Enum.EasingStyle.Quad),{BackgroundTransparency=0.48}):Play()
    else
        TW:Create(MainScale,TweenInfo.new(0.18,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Scale=0.92}):Play()
        TW:Create(Shadow,TweenInfo.new(0.18,Enum.EasingStyle.Quad),{BackgroundTransparency=1}):Play()
        task.delay(0.18,function()
            if MainScale.Scale < 0.96 then Main.Visible=false end
        end)
    end
end

local FloatBtn=Instance.new("TextButton",SG)
FloatBtn.Size=UDim2.fromOffset(48,48)
FloatBtn.Position=UDim2.new(0,14,0.5,-24)
FloatBtn.BackgroundColor3=Color3.fromRGB(16,18,28)
FloatBtn.Text=""
FloatBtn.BorderSizePixel=0
FloatBtn.ZIndex=200
FloatBtn.Visible=false
corner(14,FloatBtn)
stroke(BLUE,1.4,FloatBtn)
local fi=Instance.new("ImageLabel",FloatBtn)
fi.Size=UDim2.new(0.62,0,0.62,0)
fi.Position=UDim2.new(0.19,0,0.19,0)
fi.BackgroundTransparency=1
fi.Image="rbxassetid://110219163753015"
fi.ZIndex=201
buttonScale(FloatBtn)
FloatBtn.MouseButton1Click:Connect(function() animateHub(true) end)

local function addSection(page,txt)
    local f=Instance.new("Frame",page)
    f.Size=UDim2.new(1,0,0,24)
    f.BackgroundTransparency=1
    f.ZIndex=13
    local l=Instance.new("TextLabel",f)
    l.Size=UDim2.new(1,-30,1,0)
    l.Position=UDim2.new(0,2,0,0)
    l.BackgroundTransparency=1
    l.Text=txt:upper()
    l.TextColor3=BLUEL
    l.Font=Enum.Font.GothamBold
    l.TextSize=9
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.ZIndex=14
    local ln=Instance.new("Frame",f)
    ln.Size=UDim2.new(1,0,0,1)
    ln.Position=UDim2.new(0,0,1,-1)
    ln.BackgroundColor3=BLUED
    ln.BackgroundTransparency=0.45
    ln.BorderSizePixel=0
    ln.ZIndex=14
    local dot=Instance.new("Frame",f)
    dot.Size=UDim2.fromOffset(5,5)
    dot.Position=UDim2.new(1,-5,0.5,-2.5)
    dot.BackgroundColor3=BLUE
    dot.BorderSizePixel=0
    dot.ZIndex=14
    corner(3,dot)
end

local function addToggle(page,label,default,cb)
    local row=Instance.new("Frame",page)
    row.Size=UDim2.new(1,0,0,48)
    row.BackgroundColor3=ITEM
    row.BorderSizePixel=0
    row.ZIndex=13
    corner(12,row)
    stroke(Color3.fromRGB(26,33,52),1,row,0.25)
    gradient(row,Color3.fromRGB(21,26,43),Color3.fromRGB(15,19,32),0)

    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-100,1,0)
    lbl.Position=UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency=1
    lbl.Text=label
    lbl.TextColor3=TEXT
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.ZIndex=14

    local togBtn=Instance.new("TextButton",row)
    togBtn.Size=UDim2.fromOffset(50,24)
    togBtn.Position=UDim2.new(1,-64,0.5,-12)
    togBtn.BackgroundColor3=Color3.fromRGB(39,46,67)
    togBtn.Text=""
    togBtn.BorderSizePixel=0
    togBtn.ZIndex=15
    corner(12,togBtn)
    local knob=Instance.new("Frame",togBtn)
    knob.Size=UDim2.fromOffset(18,18)
    knob.Position=UDim2.new(0,3,0.5,-9)
    knob.BackgroundColor3=Color3.fromRGB(180,190,210)
    knob.BorderSizePixel=0
    knob.ZIndex=16
    corner(9,knob)
    stroke(Color3.fromRGB(255,255,255),1,knob,0.7)
    local state=Instance.new("TextLabel",row)
    state.Size=UDim2.fromOffset(30,12)
    state.Position=UDim2.new(1,-103,0.5,-6)
    state.BackgroundTransparency=1
    state.Text="OFF"
    state.TextColor3=TEXTD
    state.Font=Enum.Font.GothamBold
    state.TextSize=7
    state.TextXAlignment=Enum.TextXAlignment.Right
    state.ZIndex=14

    local on=default or false
    local function refresh()
        local bg=on and BLUE or Color3.fromRGB(39,46,67)
        local knobX=on and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
        state.Text=on and "ON" or "OFF"
        state.TextColor3=on and BLUEL or TEXTD
        TW:Create(togBtn,TweenInfo.new(0.18,Enum.EasingStyle.Quint),{BackgroundColor3=bg}):Play()
        TW:Create(knob,TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=knobX,BackgroundColor3=on and WHITE or Color3.fromRGB(180,190,210)}):Play()
    end
    refresh()
    local function toggle()
        on=not on
        refresh()
        if cb then cb(on) end
    end
    togBtn.MouseButton1Click:Connect(toggle)
    local hit=Instance.new("TextButton",row)
    hit.Size=UDim2.new(1,-80,1,0)
    hit.BackgroundTransparency=1
    hit.Text=""
    hit.ZIndex=16
    hit.MouseButton1Click:Connect(toggle)
    return row
end

local function addButton(page,label,cb)
    local btn=Instance.new("TextButton",page)
    btn.Size=UDim2.new(1,0,0,42)
    btn.BackgroundColor3=Color3.fromRGB(20,28,48)
    btn.Text=label
    btn.TextColor3=TEXT
    btn.Font=Enum.Font.GothamBold
    btn.TextSize=11
    btn.BorderSizePixel=0
    btn.ZIndex=13
    corner(12,btn)
    stroke(BLUED,1.1,btn,0.15)
    local shine=Instance.new("Frame",btn)
    shine.Size=UDim2.new(0,3,1,-14)
    shine.Position=UDim2.new(0,7,0,7)
    shine.BackgroundColor3=BLUE
    shine.BorderSizePixel=0
    shine.ZIndex=14
    corner(2,shine)
    buttonScale(btn)
    btn.MouseEnter:Connect(function()
        TW:Create(btn,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(27,42,71)}):Play()
        TW:Create(shine,TweenInfo.new(0.14),{Size=UDim2.new(0,5,1,-12)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TW:Create(btn,TweenInfo.new(0.14),{BackgroundColor3=Color3.fromRGB(20,28,48)}):Play()
        TW:Create(shine,TweenInfo.new(0.14),{Size=UDim2.new(0,3,1,-14)}):Play()
    end)
    btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    return btn
end

local function addSlider(parent,label,minV,maxV,defV,step,cb)
    step=step or 1
    local con=Instance.new("Frame",parent)
    con.Size=UDim2.new(1,0,0,64)
    con.BackgroundColor3=ITEM
    con.BorderSizePixel=0
    con.ZIndex=13
    corner(12,con)
    stroke(Color3.fromRGB(26,33,52),1,con,0.25)

    local lbl=Instance.new("TextLabel",con)
    lbl.Size=UDim2.new(1,-18,0,18)
    lbl.Position=UDim2.new(0,12,0,7)
    lbl.BackgroundTransparency=1
    lbl.Text=label..": "..defV
    lbl.TextColor3=TEXT
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=10
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.ZIndex=14

    local track=Instance.new("Frame",con)
    track.Size=UDim2.new(1,-62,0,6)
    track.Position=UDim2.new(0,30,0,43)
    track.BackgroundColor3=Color3.fromRGB(28,34,51)
    track.BorderSizePixel=0
    track.ZIndex=14
    corner(3,track)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new(0,0,1,0)
    fill.BackgroundColor3=BLUE
    fill.BorderSizePixel=0
    fill.ZIndex=15
    corner(3,fill)
    local knob=Instance.new("Frame",track)
    knob.Size=UDim2.fromOffset(14,14)
    knob.Position=UDim2.new(0,-7,0.5,-7)
    knob.BackgroundColor3=WHITE
    knob.BorderSizePixel=0
    knob.ZIndex=16
    corner(7,knob)
    stroke(BLUEL,1.2,knob)

    local bMin=Instance.new("TextButton",con)
    bMin.Size=UDim2.fromOffset(18,18)
    bMin.Position=UDim2.new(0,7,0,37)
    bMin.BackgroundColor3=Color3.fromRGB(30,42,67)
    bMin.Text="−"
    bMin.TextColor3=BLUEL
    bMin.Font=Enum.Font.GothamBold
    bMin.TextSize=12
    bMin.BorderSizePixel=0
    bMin.ZIndex=16
    corner(6,bMin)
    local bMax=Instance.new("TextButton",con)
    bMax.Size=UDim2.fromOffset(18,18)
    bMax.Position=UDim2.new(1,-25,0,37)
    bMax.BackgroundColor3=Color3.fromRGB(30,42,67)
    bMax.Text="+"
    bMax.TextColor3=BLUEL
    bMax.Font=Enum.Font.GothamBold
    bMax.TextSize=12
    bMax.BorderSizePixel=0
    bMax.ZIndex=16
    corner(6,bMax)

    local value=defV
    local function apply(v)
        value=math.clamp(math.floor(v/step+0.5)*step,minV,maxV)
        local pct=(value-minV)/(maxV-minV)
        fill.Size=UDim2.new(pct,0,1,0)
        knob.Position=UDim2.new(pct,-7,0.5,-7)
        lbl.Text=label..": "..value
        if cb then cb(value) end
    end
    apply(defV)

    local drag=false
    knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true end end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            apply(minV+(maxV-minV)*math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1))
            drag=true
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            apply(minV+(maxV-minV)*math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1))
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    bMin.MouseButton1Click:Connect(function() apply(value-step) end)
    bMax.MouseButton1Click:Connect(function() apply(value+step) end)
end

local function addParagraph(page,title,body)
    local f=Instance.new("Frame",page)
    f.Size=UDim2.new(1,0,0,0)
    f.AutomaticSize=Enum.AutomaticSize.Y
    f.BackgroundColor3=ITEM
    f.BorderSizePixel=0
    f.ZIndex=13
    corner(12,f)
    stroke(Color3.fromRGB(26,33,52),1,f,0.25)
    local ll=Instance.new("UIListLayout",f)
    ll.SortOrder=Enum.SortOrder.LayoutOrder
    ll.Padding=UDim.new(0,4)
    local pp=Instance.new("UIPadding",f)
    pp.PaddingLeft=UDim.new(0,13)
    pp.PaddingRight=UDim.new(0,13)
    pp.PaddingTop=UDim.new(0,10)
    pp.PaddingBottom=UDim.new(0,10)
    local t=Instance.new("TextLabel",f)
    t.Size=UDim2.new(1,0,0,16)
    t.BackgroundTransparency=1
    t.Text=title
    t.TextColor3=BLUEL
    t.Font=Enum.Font.GothamBold
    t.TextSize=11
    t.TextXAlignment=Enum.TextXAlignment.Left
    t.ZIndex=14
    t.LayoutOrder=1
    local b=Instance.new("TextLabel",f)
    b.Size=UDim2.new(1,0,0,0)
    b.AutomaticSize=Enum.AutomaticSize.Y
    b.BackgroundTransparency=1
    b.Text=body
    b.TextColor3=TEXTD
    b.Font=Enum.Font.Gotham
    b.TextSize=10
    b.TextXAlignment=Enum.TextXAlignment.Left
    b.TextWrapped=true
    b.ZIndex=14
    b.LayoutOrder=2
end

local function addInfoBox(page,titulo,texto)
    local outer=Instance.new("Frame",page)
    outer.Size=UDim2.new(1,0,0,0)
    outer.AutomaticSize=Enum.AutomaticSize.Y
    outer.BackgroundColor3=Color3.fromRGB(12,22,38)
    outer.BorderSizePixel=0
    outer.ZIndex=13
    corner(12,outer)
    stroke(BLUED,1.2,outer,0.1)
    local strip=Instance.new("Frame",outer)
    strip.Size=UDim2.new(0,3,1,-16)
    strip.Position=UDim2.new(0,8,0,8)
    strip.BackgroundColor3=BLUE
    strip.BorderSizePixel=0
    strip.ZIndex=14
    corner(2,strip)
    local inner=Instance.new("UIListLayout",outer)
    inner.SortOrder=Enum.SortOrder.LayoutOrder
    inner.Padding=UDim.new(0,4)
    local pad=Instance.new("UIPadding",outer)
    pad.PaddingLeft=UDim.new(0,18); pad.PaddingRight=UDim.new(0,12); pad.PaddingTop=UDim.new(0,10); pad.PaddingBottom=UDim.new(0,10)
    local icon=Instance.new("TextLabel",outer)
    icon.Size=UDim2.new(1,0,0,15)
    icon.BackgroundTransparency=1
    icon.Text="✦  "..titulo
    icon.TextColor3=BLUEL
    icon.Font=Enum.Font.GothamBold
    icon.TextSize=11
    icon.TextXAlignment=Enum.TextXAlignment.Left
    icon.ZIndex=14
    icon.LayoutOrder=1
    local body=Instance.new("TextLabel",outer)
    body.Size=UDim2.new(1,0,0,0)
    body.AutomaticSize=Enum.AutomaticSize.Y
    body.BackgroundTransparency=1
    body.Text=texto
    body.TextColor3=Color3.fromRGB(165,178,207)
    body.Font=Enum.Font.Gotham
    body.TextSize=10
    body.TextXAlignment=Enum.TextXAlignment.Left
    body.TextWrapped=true
    body.ZIndex=14
    body.LayoutOrder=2
end

-- Browser-style home dashboard, based on the supplied reference image.
do
    local page=pageCred

    local profile=Instance.new("Frame",page)
    profile.Size=UDim2.new(1,0,0,74)
    profile.BackgroundColor3=Color3.fromRGB(15,17,24)
    profile.BorderSizePixel=0
    profile.ZIndex=13
    corner(8,profile)
    stroke(Color3.fromRGB(54,58,70),1,profile,0.12)

    local pAvatar=Instance.new("ImageLabel",profile)
    pAvatar.Size=UDim2.fromOffset(52,52)
    pAvatar.Position=UDim2.new(0,12,0.5,-26)
    pAvatar.BackgroundColor3=Color3.fromRGB(28,31,42)
    pAvatar.Image="rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=150&h=150"
    pAvatar.ZIndex=14
    corner(5,pAvatar)
    stroke(BLUED,1,pAvatar,0.1)

    local pName=Instance.new("TextLabel",profile)
    pName.Size=UDim2.new(1,-84,0,17)
    pName.Position=UDim2.new(0,76,0,12)
    pName.BackgroundTransparency=1
    pName.Text=(LP.DisplayName ~= "" and LP.DisplayName or LP.Name)
    pName.TextColor3=Color3.fromRGB(225,227,235)
    pName.Font=Enum.Font.GothamBold
    pName.TextSize=11
    pName.TextXAlignment=Enum.TextXAlignment.Left
    pName.ZIndex=14

    local pUser=Instance.new("TextLabel",profile)
    pUser.Size=UDim2.new(1,-84,0,12)
    pUser.Position=UDim2.new(0,76,0,29)
    pUser.BackgroundTransparency=1
    pUser.Text="@"..LP.Name.."  •  UserID "..tostring(LP.UserId)
    pUser.TextColor3=Color3.fromRGB(115,119,132)
    pUser.Font=Enum.Font.Gotham
    pUser.TextSize=7
    pUser.TextXAlignment=Enum.TextXAlignment.Left
    pUser.ZIndex=14

    local pStatus=Instance.new("TextLabel",profile)
    pStatus.Size=UDim2.new(1,-84,0,11)
    pStatus.Position=UDim2.new(0,76,0,46)
    pStatus.BackgroundTransparency=1
    pStatus.Text="●  EMAN HUB  •  PREMIUM  •  ONLINE"
    pStatus.TextColor3=GREEN
    pStatus.Font=Enum.Font.GothamBold
    pStatus.TextSize=6
    pStatus.TextXAlignment=Enum.TextXAlignment.Left
    pStatus.ZIndex=14

    local grid=Instance.new("Frame",page)
    grid.Size=UDim2.new(1,0,0,260)
    grid.BackgroundTransparency=1
    grid.ZIndex=13

    local server=Instance.new("Frame",grid)
    server.Size=UDim2.new(0.49,-5,0,190)
    server.Position=UDim2.new(0,0,0,0)
    server.BackgroundColor3=Color3.fromRGB(13,15,21)
    server.BorderSizePixel=0
    server.ZIndex=13
    corner(9,server)
    stroke(Color3.fromRGB(46,49,60),1,server,0.16)

    local sTitle=Instance.new("TextLabel",server)
    sTitle.Size=UDim2.new(1,-18,0,20)
    sTitle.Position=UDim2.new(0,10,0,8)
    sTitle.BackgroundTransparency=1
    sTitle.Text="Server"
    sTitle.TextColor3=Color3.fromRGB(230,231,237)
    sTitle.Font=Enum.Font.GothamBold
    sTitle.TextSize=10
    sTitle.TextXAlignment=Enum.TextXAlignment.Left
    sTitle.ZIndex=14

    local sSub=Instance.new("TextLabel",server)
    sSub.Size=UDim2.new(1,-18,0,14)
    sSub.Position=UDim2.new(0,10,0,25)
    sSub.BackgroundTransparency=1
    sSub.Text="Information about the session you're currently in"
    sSub.TextColor3=Color3.fromRGB(112,116,128)
    sSub.Font=Enum.Font.Gotham
    sSub.TextSize=6
    sSub.TextXAlignment=Enum.TextXAlignment.Left
    sSub.ZIndex=14

    local statGrid=Instance.new("Frame",server)
    statGrid.Size=UDim2.new(1,-18,0,112)
    statGrid.Position=UDim2.new(0,9,0,48)
    statGrid.BackgroundTransparency=1
    statGrid.ZIndex=14
    local sg=Instance.new("UIGridLayout",statGrid)
    sg.CellSize=UDim2.new(0.5,-4,0,30)
    sg.CellPadding=UDim2.fromOffset(5,5)

    local stats={
        {"Players",function() return tostring(#Players:GetPlayers()) end,"playing"},
        {"Maximum Players",function() return tostring(Players.MaxPlayers or 0) end,"max"},
        {"Latency",function()
            local ok,ping=pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString() end)
            return ok and tostring(ping) or "--"
        end,"ms"},
        {"Server Region",function() return "Online" end,"region"},
        {"In server for",function() return string.format("%02d:%02d",math.floor((os.clock())/60)%60,math.floor(os.clock())%60) end,"time"},
        {"Join Script",function() return "Tap to copy join script" end,"join"},
    }
    for i,s in ipairs(stats) do
        local c=Instance.new("Frame",statGrid)
        c.BackgroundColor3=Color3.fromRGB(25,27,34)
        c.BorderSizePixel=0
        c.ZIndex=15
        corner(5,c)
        local t=Instance.new("TextLabel",c)
        t.Size=UDim2.new(1,-12,0,12)
        t.Position=UDim2.new(0,6,0,4)
        t.BackgroundTransparency=1
        t.Text=s[1]
        t.TextColor3=Color3.fromRGB(174,177,187)
        t.Font=Enum.Font.GothamBold
        t.TextSize=6
        t.TextXAlignment=Enum.TextXAlignment.Left
        t.ZIndex=16
        local v=Instance.new("TextLabel",c)
        v.Size=UDim2.new(1,-12,0,11)
        v.Position=UDim2.new(0,6,0,16)
        v.BackgroundTransparency=1
        v.Text=s[2]()
        v.TextColor3=Color3.fromRGB(110,113,124)
        v.Font=Enum.Font.Gotham
        v.TextSize=6
        v.TextXAlignment=Enum.TextXAlignment.Left
        v.ZIndex=16
        if s[1]=="Join Script" then
            local b=Instance.new("TextButton",c)
            b.Size=UDim2.new(1,0,1,0)
            b.BackgroundTransparency=1
            b.Text=""
            b.ZIndex=17
            buttonScale(b)
            b.MouseButton1Click:Connect(function()
                pcall(function() setclipboard(game.JobId) end)
                notify("📋 JobId copiado!",BLUE)
            end)
        end
    end

    local wave=Instance.new("TextButton",grid)
    wave.Size=UDim2.new(0.51,-5,0,75)
    wave.Position=UDim2.new(0.49,5,0,0)
    wave.BackgroundColor3=Color3.fromRGB(110,38,45)
    wave.BorderSizePixel=0
    wave.Text=""
    wave.ZIndex=13
    corner(9,wave)
    stroke(Color3.fromRGB(170,76,84),1,wave,0.12)
    local wTitle=Instance.new("TextLabel",wave)
    wTitle.Size=UDim2.new(1,-18,0,17)
    wTitle.Position=UDim2.new(0,10,0,8)
    wTitle.BackgroundTransparency=1
    wTitle.Text="Wave"
    wTitle.TextColor3=Color3.fromRGB(255,240,242)
    wTitle.Font=Enum.Font.GothamBold
    wTitle.TextSize=12
    wTitle.TextXAlignment=Enum.TextXAlignment.Left
    wTitle.ZIndex=14
    local wBody=Instance.new("TextLabel",wave)
    wBody.Size=UDim2.new(1,-18,0,30)
    wBody.Position=UDim2.new(0,10,0,28)
    wBody.BackgroundTransparency=1
    wBody.Text="Your executor seems to support this script."
    wBody.TextColor3=Color3.fromRGB(241,205,208)
    wBody.Font=Enum.Font.Gotham
    wBody.TextSize=7
    wBody.TextWrapped=true
    wBody.TextXAlignment=Enum.TextXAlignment.Left
    wBody.ZIndex=14
    buttonScale(wave)
    wave.MouseButton1Click:Connect(function() notify("⚡ EMAN HUB ready",GREEN) end)

    local friends=Instance.new("Frame",grid)
    friends.Size=UDim2.new(0.51,-5,0,108)
    friends.Position=UDim2.new(0.49,5,0,82)
    friends.BackgroundColor3=Color3.fromRGB(20,21,25)
    friends.BorderSizePixel=0
    friends.ZIndex=13
    corner(9,friends)
    stroke(Color3.fromRGB(55,56,62),1,friends,0.14)

    local fTitle=Instance.new("TextLabel",friends)
    fTitle.Size=UDim2.new(1,-16,0,17)
    fTitle.Position=UDim2.new(0,9,0,8)
    fTitle.BackgroundTransparency=1
    fTitle.Text="Friends"
    fTitle.TextColor3=Color3.fromRGB(232,233,238)
    fTitle.Font=Enum.Font.GothamBold
    fTitle.TextSize=11
    fTitle.TextXAlignment=Enum.TextXAlignment.Left
    fTitle.ZIndex=14

    local fSub=Instance.new("TextLabel",friends)
    fSub.Size=UDim2.new(1,-16,0,13)
    fSub.Position=UDim2.new(0,9,0,24)
    fSub.BackgroundTransparency=1
    fSub.Text="Find out what your friends are currently doing."
    fSub.TextColor3=Color3.fromRGB(119,121,130)
    fSub.Font=Enum.Font.Gotham
    fSub.TextSize=6
    fSub.TextXAlignment=Enum.TextXAlignment.Left
    fSub.ZIndex=14

    local friendGrid=Instance.new("Frame",friends)
    friendGrid.Size=UDim2.new(1,-18,0,58)
    friendGrid.Position=UDim2.new(0,9,0,43)
    friendGrid.BackgroundTransparency=1
    friendGrid.ZIndex=14
    local fg=Instance.new("UIGridLayout",friendGrid)
    fg.CellSize=UDim2.new(0.5,-3,0,27)
    fg.CellPadding=UDim2.fromOffset(5,4)
    local fItems={
        {"In Server","0 friends"},{"Offline","0 friends"},{"Online","1 friend"},{"All","1 friend"}
    }
    for _,item in ipairs(fItems) do
        local c=Instance.new("Frame",friendGrid)
        c.BackgroundColor3=Color3.fromRGB(31,31,36)
        c.BorderSizePixel=0
        c.ZIndex=15
        corner(5,c)
        local a=Instance.new("TextLabel",c)
        a.Size=UDim2.new(1,-8,0,11)
        a.Position=UDim2.new(0,5,0,3)
        a.BackgroundTransparency=1
        a.Text=item[1]
        a.TextColor3=Color3.fromRGB(213,214,220)
        a.Font=Enum.Font.GothamBold
        a.TextSize=6
        a.TextXAlignment=Enum.TextXAlignment.Left
        a.ZIndex=16
        local b=Instance.new("TextLabel",c)
        b.Size=UDim2.new(1,-8,0,10)
        b.Position=UDim2.new(0,5,0,13)
        b.BackgroundTransparency=1
        b.Text=item[2]
        b.TextColor3=Color3.fromRGB(121,123,132)
        b.Font=Enum.Font.Gotham
        b.TextSize=5
        b.TextXAlignment=Enum.TextXAlignment.Left
        b.ZIndex=16
    end

    local discord=Instance.new("TextButton",page)
    discord.Size=UDim2.new(0.49,-5,0,58)
    discord.Position=UDim2.new(0,0,0,198)
    discord.BackgroundColor3=Color3.fromRGB(76,89,206)
    discord.BorderSizePixel=0
    discord.Text=""
    discord.ZIndex=13
    corner(9,discord)
    stroke(Color3.fromRGB(120,132,245),1,discord,0.15)
    local dTitle=Instance.new("TextLabel",discord)
    dTitle.Size=UDim2.new(1,-18,0,17)
    dTitle.Position=UDim2.new(0,10,0,8)
    dTitle.BackgroundTransparency=1
    dTitle.Text="Discord"
    dTitle.TextColor3=Color3.fromRGB(255,255,255)
    dTitle.Font=Enum.Font.GothamBold
    dTitle.TextSize=12
    dTitle.TextXAlignment=Enum.TextXAlignment.Left
    dTitle.ZIndex=14
    local dSub=Instance.new("TextLabel",discord)
    dSub.Size=UDim2.new(1,-18,0,17)
    dSub.Position=UDim2.new(0,10,0,27)
    dSub.BackgroundTransparency=1
    dSub.Text="Tap to copy: discord.gg/FWQENyvHS"
    dSub.TextColor3=Color3.fromRGB(225,227,255)
    dSub.Font=Enum.Font.Gotham
    dSub.TextSize=7
    dSub.TextXAlignment=Enum.TextXAlignment.Left
    dSub.ZIndex=14
    buttonScale(discord)
    discord.MouseButton1Click:Connect(function()
        pcall(function() setclipboard("https://discord.gg/FWQENyvHS") end)
        notify("📋 Discord copiado!",BLUE)
    end)

    local quick=Instance.new("Frame",page)
    quick.Size=UDim2.new(0.51,-5,0,58)
    quick.Position=UDim2.new(0.49,5,0,198)
    quick.BackgroundTransparency=1
    quick.ZIndex=13
    local q1=Instance.new("TextButton",quick)
    q1.Size=UDim2.new(0.5,-3,1,0)
    q1.BackgroundColor3=Color3.fromRGB(28,31,40)
    q1.BorderSizePixel=0
    q1.Text="Menu"
    q1.TextColor3=Color3.fromRGB(210,212,222)
    q1.Font=Enum.Font.GothamBold
    q1.TextSize=8
    q1.ZIndex=14
    corner(8,q1)
    local q2=Instance.new("TextButton",quick)
    q2.Size=UDim2.new(0.5,-3,1,0)
    q2.Position=UDim2.new(0.5,6,0,0)
    q2.BackgroundColor3=Color3.fromRGB(28,31,40)
    q2.BorderSizePixel=0
    q2.Text="Settings"
    q2.TextColor3=Color3.fromRGB(210,212,222)
    q2.Font=Enum.Font.GothamBold
    q2.TextSize=8
    q2.ZIndex=14
    corner(8,q2)
    buttonScale(q1); buttonScale(q2)
    q1.Activated:Connect(function() tabsData[2].btn:Activate() end)
    q2.Activated:Connect(function() tabsData[5].btn:Activate() end)

    -- Small live counters on the home page.
    local live=Instance.new("TextLabel",page)
    live.Size=UDim2.new(1,0,0,14)
    live.BackgroundTransparency=1
    live.Text="eman hub • live session"
    live.TextColor3=Color3.fromRGB(92,96,109)
    live.Font=Enum.Font.Gotham
    live.TextSize=6
    live.TextXAlignment=Enum.TextXAlignment.Left
    live.ZIndex=14
end

-- Theme selector: changes the current UI accent without recreating the feature pages.
do
    addSection(pageBoost,"🎨  Tema do Menu")
    local themes={
        {"Ocean Blue",Color3.fromRGB(55,140,255),Color3.fromRGB(120,190,255),Color3.fromRGB(28,67,135)},
        {"Galaxy Purple",Color3.fromRGB(145,82,255),Color3.fromRGB(190,135,255),Color3.fromRGB(78,42,146)},
        {"Crimson",Color3.fromRGB(245,67,84),Color3.fromRGB(255,130,145),Color3.fromRGB(130,35,48)},
        {"Emerald",Color3.fromRGB(33,205,133),Color3.fromRGB(105,245,181),Color3.fromRGB(28,111,76)},
        {"Neon Pink",Color3.fromRGB(244,60,174),Color3.fromRGB(255,140,220),Color3.fromRGB(134,38,97)},
        {"Gold",Color3.fromRGB(245,178,54),Color3.fromRGB(255,220,125),Color3.fromRGB(133,94,28)},
    }
    local themeWrap=Instance.new("Frame",pageBoost)
    themeWrap.Size=UDim2.new(1,0,0,0)
    themeWrap.AutomaticSize=Enum.AutomaticSize.Y
    themeWrap.BackgroundColor3=ITEM
    themeWrap.BorderSizePixel=0
    themeWrap.ZIndex=13
    corner(14,themeWrap)
    stroke(Color3.fromRGB(26,33,52),1,themeWrap,0.25)
    local grid=Instance.new("UIGridLayout",themeWrap)
    grid.CellSize=UDim2.new(0.5,-6,0,44)
    grid.CellPadding=UDim2.fromOffset(7,7)
    grid.SortOrder=Enum.SortOrder.LayoutOrder
    local gp=Instance.new("UIPadding",themeWrap)
    gp.PaddingTop=UDim.new(0,9); gp.PaddingBottom=UDim.new(0,9); gp.PaddingLeft=UDim.new(0,9); gp.PaddingRight=UDim.new(0,9)

    local function applyTheme(accent,light,dark,name)
        local oldA,oldL,oldD=BLUE,BLUEL,BLUED
        BLUE,BLUEL,BLUED=accent,light,dark
        for _,obj in ipairs(SG:GetDescendants()) do
            pcall(function()
                if obj:IsA("GuiObject") then
                    if equalColor(obj.BackgroundColor3,oldA) then obj.BackgroundColor3=BLUE
                    elseif equalColor(obj.BackgroundColor3,oldL) then obj.BackgroundColor3=BLUEL
                    elseif equalColor(obj.BackgroundColor3,oldD) then obj.BackgroundColor3=BLUED end
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                        if equalColor(obj.TextColor3,oldA) then obj.TextColor3=BLUE
                        elseif equalColor(obj.TextColor3,oldL) then obj.TextColor3=BLUEL
                        elseif equalColor(obj.TextColor3,oldD) then obj.TextColor3=BLUED end
                    end
                    if obj:IsA("ScrollingFrame") and equalColor(obj.ScrollBarImageColor3,oldA) then obj.ScrollBarImageColor3=BLUE end
                elseif obj:IsA("UIStroke") then
                    if equalColor(obj.Color,oldA) then obj.Color=BLUE
                    elseif equalColor(obj.Color,oldL) then obj.Color=BLUEL
                    elseif equalColor(obj.Color,oldD) then obj.Color=BLUED end
                elseif obj:IsA("UIGradient") then
                    local keys=obj.Color.Keypoints
                    for _,k in ipairs(keys) do end
                end
            end)
        end
        AccentLine.BackgroundColor3=BLUE
        statusLbl.TextColor3=GREEN
        notify("🎨 Tema aplicado: "..name,BLUE)
    end

    for i,data in ipairs(themes) do
        local name,accent,light,dark=data[1],data[2],data[3],data[4]
        local b=Instance.new("TextButton",themeWrap)
        b.BackgroundColor3=Color3.fromRGB(22,27,44)
        b.Text=name
        b.TextColor3=TEXT
        b.Font=Enum.Font.GothamBold
        b.TextSize=9
        b.BorderSizePixel=0
        b.ZIndex=14
        b.LayoutOrder=i
        corner(10,b)
        stroke(dark,1,b,0.1)
        local dot=Instance.new("Frame",b)
        dot.Size=UDim2.fromOffset(12,12)
        dot.Position=UDim2.new(1,-21,0.5,-6)
        dot.BackgroundColor3=accent
        dot.BorderSizePixel=0
        dot.ZIndex=15
        corner(6,dot)
        buttonScale(b)
        b.MouseButton1Click:Connect(function() applyTheme(accent,light,dark,name) end)
    end
end


-- Keyboard minimize: configurable from the Boost tab.
local minimizeKey = Enum.KeyCode.RightShift
local waitingForMinimizeKey = false
local minimizeKeyButton = nil

local function minimizeKeyName(key)
    return key and key.Name or "RightShift"
end

local function updateMinimizeKeyLabel()
    local name = minimizeKeyName(minimizeKey)
    if minimizeKeyButton and minimizeKeyButton.Parent then
        minimizeKeyButton.Text = name
    end
    Hint.Text = "Arraste • Min: "..name
end

local function toggleHubVisibility()
    if Main.Visible then
        animateHub(false)
    else
        animateHub(true)
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if waitingForMinimizeKey then
        if input.KeyCode == Enum.KeyCode.Escape then
            waitingForMinimizeKey = false
            updateMinimizeKeyLabel()
            notify("⌨️ Alteração cancelada", Color3.fromRGB(200,200,200))
        elseif input.KeyCode ~= Enum.KeyCode.Unknown then
            minimizeKey = input.KeyCode
            waitingForMinimizeKey = false
            updateMinimizeKeyLabel()
            notify("⌨️ Tecla de minimizar: "..minimizeKeyName(minimizeKey), BLUE)
        end
        return
    end

    if not gameProcessed and input.KeyCode == minimizeKey then
        toggleHubVisibility()
    end
end)

-- Interface shortcut selector.
do
    addSection(pageBoost,"⌨️  Interface")

    local keyRow=Instance.new("Frame",pageBoost)
    keyRow.Size=UDim2.new(1,0,0,54)
    keyRow.BackgroundColor3=ITEM
    keyRow.BorderSizePixel=0
    keyRow.ZIndex=13
    corner(12,keyRow)
    stroke(Color3.fromRGB(26,33,52),1,keyRow,0.25)

    local keyTitle=Instance.new("TextLabel",keyRow)
    keyTitle.Size=UDim2.new(1,-135,0,16)
    keyTitle.Position=UDim2.new(0,12,0,9)
    keyTitle.BackgroundTransparency=1
    keyTitle.Text="Tecla para minimizar"
    keyTitle.TextColor3=TEXT
    keyTitle.Font=Enum.Font.GothamBold
    keyTitle.TextSize=10
    keyTitle.TextXAlignment=Enum.TextXAlignment.Left
    keyTitle.ZIndex=14

    local keySub=Instance.new("TextLabel",keyRow)
    keySub.Size=UDim2.new(1,-135,0,13)
    keySub.Position=UDim2.new(0,12,0,27)
    keySub.BackgroundTransparency=1
    keySub.Text="Escolha uma tecla para abrir/fechar o hub"
    keySub.TextColor3=TEXTD
    keySub.Font=Enum.Font.Gotham
    keySub.TextSize=8
    keySub.TextXAlignment=Enum.TextXAlignment.Left
    keySub.ZIndex=14

    minimizeKeyButton=Instance.new("TextButton",keyRow)
    minimizeKeyButton.Size=UDim2.fromOffset(104,30)
    minimizeKeyButton.Position=UDim2.new(1,-116,0.5,-15)
    minimizeKeyButton.BackgroundColor3=BLUED
    minimizeKeyButton.Text=minimizeKeyName(minimizeKey)
    minimizeKeyButton.TextColor3=WHITE
    minimizeKeyButton.Font=Enum.Font.GothamBold
    minimizeKeyButton.TextSize=9
    minimizeKeyButton.BorderSizePixel=0
    minimizeKeyButton.ZIndex=15
    corner(9,minimizeKeyButton)
    stroke(BLUE,1,minimizeKeyButton,0.12)
    buttonScale(minimizeKeyButton)

    minimizeKeyButton.MouseButton1Click:Connect(function()
        waitingForMinimizeKey = true
        minimizeKeyButton.Text = "PRESSIONE..."
        notify("⌨️ Pressione a nova tecla • ESC cancela", BLUE)
    end)
end

local CircleBtn = Instance.new("TextButton", SG)
CircleBtn.Size = UDim2.fromOffset(60,60)
CircleBtn.Position = UDim2.new(1,-78,1,-84)
CircleBtn.BackgroundColor3 = Color3.fromRGB(18,27,45)
CircleBtn.Text = ""
CircleBtn.BorderSizePixel = 0
CircleBtn.ZIndex = 9999
corner(20,CircleBtn)
stroke(BLUE,2,CircleBtn)
gradient(CircleBtn,Color3.fromRGB(28,43,71),Color3.fromRGB(12,18,30),45)
local circleImg = Instance.new("ImageLabel",CircleBtn)
circleImg.Size = UDim2.new(0.62,0,0.62,0)
circleImg.Position = UDim2.new(0.19,0,0.19,0)
circleImg.BackgroundTransparency = 1
circleImg.Image = "rbxassetid://110219163753015"
circleImg.ZIndex = 10000
buttonScale(CircleBtn)
CircleBtn.MouseButton1Click:Connect(function()
    if Main.Visible then animateHub(false) else animateHub(true) end
end)

-- Small floating glow around the launcher.
local launcherGlow=Instance.new("Frame",CircleBtn)
launcherGlow.Size=UDim2.new(1,8,1,8)
launcherGlow.Position=UDim2.new(0,-4,0,-4)
launcherGlow.BackgroundTransparency=1
launcherGlow.ZIndex=9998
corner(24,launcherGlow)
stroke(BLUE,1,launcherGlow,0.7)

task.spawn(function()
    while CircleBtn.Parent do
        local tw=TW:Create(launcherGlow,TweenInfo.new(1.15,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.85})
        tw:Play(); tw.Completed:Wait()
        if not CircleBtn.Parent then break end
        TW:Create(launcherGlow,TweenInfo.new(1.15,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=1}):Play()
        task.wait(1.15)
    end
end)

-- Global animation polish.
pageCred.Visible=true
pageCred.Position=UDim2.new(0,0,0,0)
for i,td in ipairs(tabsData) do
    if i==1 then
        td.ind.Visible=true
        td.btn.BackgroundColor3=Color3.fromRGB(20,30,52)
        td.nl.TextColor3=WHITE
        td.il.TextColor3=BLUEL
        td.iconBg.BackgroundColor3=Color3.fromRGB(30,52,90)
        td.stroke.Color=BLUED
    end
end


addSection(pageBola,"Auto Goal")
addButton(pageBola,"💾  Salvar Posição do Gol",function()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        savedGoalPos=LP.Character.HumanoidRootPart.Position
        notify("✅ Posição do gol salva!")
    else
        notify("❌ Personagem não encontrado!",Color3.fromRGB(255,80,80))
    end
end)
addToggle(pageBola,"Auto Goal",false,function(v)
    if v and not savedGoalPos then
        notify("⚠️ Salve a posição do gol primeiro!",Color3.fromRGB(255,160,0))
        return
    end
    magnetEnabled=v
    notify(v and "✅ Auto Goal ATIVADO!" or "🔴 Auto Goal desativado", v and GREEN or Color3.fromRGB(200,200,200))
end)
addSlider(pageBola,"Velocidade da Bola",1,10,4,1,function(v)
    goalBallSpeed = v * 50
end)
addToggle(pageBola,"⚡  Teleporte Instantâneo",false,function(v)
    goalInstantTP = v
    notify(v and "⚡ Modo: Teleporte Instantâneo" or "🏃 Modo: Velocidade", v and BLUEL or Color3.fromRGB(200,200,200))
end)

addInfoBox(pageBola,
    "Como funciona o Auto Goal?",
    "🇧🇷 O sistema salva uma posição fixa no mapa (dentro do gol). Quando a bola toca o jogador ou é chutada, o sistema aplica uma força direcionando a bola automaticamente para essa posição.\n\n🇺🇸 The system stores a fixed position on the map (inside the goal). When the ball touches the player or is kicked, it applies a force directing the ball automatically toward that saved position."
)

addSection(pageBola,"Bring Ball (OP)")
do
    local bbPos = nil
    local bbOn  = false

    local avisoCard = Instance.new("Frame", SG)
    avisoCard.Size = UDim2.new(0.7, 0, 0, 0)
    avisoCard.AutomaticSize = Enum.AutomaticSize.Y
    avisoCard.Position = UDim2.new(0.15, 0, 0, 40)
    avisoCard.BackgroundColor3 = Color3.fromRGB(25, 18, 5)
    avisoCard.BorderSizePixel = 0
    avisoCard.ZIndex = 5000
    avisoCard.Visible = false
    corner(9, avisoCard)
    stroke(Color3.fromRGB(255, 160, 0), 1.5, avisoCard)

    local avPad = Instance.new("UIPadding", avisoCard)
    avPad.PaddingLeft   = UDim.new(0,8)
    avPad.PaddingRight  = UDim.new(0,8)
    avPad.PaddingTop    = UDim.new(0,6)
    avPad.PaddingBottom = UDim.new(0,6)

    local avList = Instance.new("UIListLayout", avisoCard)
    avList.SortOrder = Enum.SortOrder.LayoutOrder
    avList.Padding = UDim.new(0,4)

    local avTitulo = Instance.new("TextLabel", avisoCard)
    avTitulo.Size = UDim2.new(1,0,0,18)
    avTitulo.BackgroundTransparency = 1
    avTitulo.Text = "⚠️ Aviso"
    avTitulo.TextColor3 = Color3.fromRGB(255,180,0)
    avTitulo.Font = Enum.Font.GothamBold
    avTitulo.TextSize = 11
    avTitulo.TextXAlignment = Enum.TextXAlignment.Left
    avTitulo.ZIndex = 5001
    avTitulo.LayoutOrder = 1

    local avTexto = Instance.new("TextLabel", avisoCard)
    avTexto.Size = UDim2.new(1,0,0,0)
    avTexto.AutomaticSize = Enum.AutomaticSize.Y
    avTexto.BackgroundTransparency = 1
    avTexto.Text = 'Caso o Bring Ball não funcione corretamente, utilize alguma Tool de ação na bola, como "Parar Bola" ou "Chapéu".\n\nEssas ações forçam a interação com a bola e fazem o sistema funcionar normalmente.'
    avTexto.TextColor3 = Color3.fromRGB(220,195,140)
    avTexto.Font = Enum.Font.Gotham
    avTexto.TextSize = 10
    avTexto.TextXAlignment = Enum.TextXAlignment.Left
    avTexto.TextWrapped = true
    avTexto.ZIndex = 5001
    avTexto.LayoutOrder = 2

    addToggle(pageBola,"Bring Ball (OP)",false,function(v)
        bbOn = v
        avisoCard.Visible = v

        if not v then
            notify("🔴 Bring Ball desativado",Color3.fromRGB(200,200,200))
            return
        end

        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            notify("❌ Personagem não encontrado!",Color3.fromRGB(255,80,80))
            bbOn = false; avisoCard.Visible = false; return
        end

        bbPos = char.HumanoidRootPart.Position
        notify("✅ Bring Ball ATIVADO! Posição salva.")

        task.spawn(function()
            while bbOn do
                task.wait(0.01)
                local c = LP.Character
                if not c then continue end
                local hrp = c:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end

                local ball = FindBallTP()
                if not ball then continue end

                hrp.CFrame = CFrame.new(ball.Position + Vector3.new(0,3,0))

                firetouchinterest(ball, hrp, 0)
                firetouchinterest(ball, hrp, 1)

                ball.AssemblyLinearVelocity = (bbPos - ball.Position).Unit * 180

                if (bbPos - ball.Position).Magnitude < 4 then
                    ball.AssemblyLinearVelocity = Vector3.zero
                    bbOn = false
                    avisoCard.Visible = false
                    task.wait(0.1)
                    local c2 = LP.Character
                    if c2 and c2:FindFirstChild("HumanoidRootPart") then
                        c2.HumanoidRootPart.CFrame = CFrame.new(bbPos + Vector3.new(0,3,0))
                    end
                    notify("⚽ Bola chegou! Voltando à posição.", GREEN)
                    return
                end
            end
            avisoCard.Visible = false
        end)
    end)
end

addSection(pageBola,"Teleport")
addButton(pageBola,"📍  TP para a Bola",function()
    local ball=FindBallTP(); local char=LP.Character
    if ball and char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame=ball.CFrame+Vector3.new(0,3,0)
        notify("✅ Teleportado para a bola!")
    else
        notify("❌ Bola não encontrada!",Color3.fromRGB(255,80,80))
    end
end)
addToggle(pageBola,"Loop TP Ball",false,function(v)
    loopTpEnabled=v
    notify(v and "✅ Loop TP ATIVADO!" or "🔴 Loop TP desativado", v and GREEN or Color3.fromRGB(200,200,200))
    task.spawn(function()
        while loopTpEnabled do
            local ball=FindBallTP(); local char=LP.Character
            if ball and char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame=ball.CFrame+Vector3.new(0,3,0)
            end
            task.wait(0.15)
        end
    end)
end)

addSection(pageBola,"Cor da Bola")
do
    local CORES = {
        {Color3.fromRGB(255,255,255),"Branco"},
        {Color3.fromRGB(200,200,200),"Cinza Claro"},
        {Color3.fromRGB(130,130,130),"Cinza"},
        {Color3.fromRGB(55,55,55),   "Cinza Escuro"},
        {Color3.fromRGB(15,15,15),   "Preto"},
        {Color3.fromRGB(255,50,50),  "Vermelho"},
        {Color3.fromRGB(160,0,0),    "Vermelho Escuro"},
        {Color3.fromRGB(220,20,60),  "Carmesim"},
        {Color3.fromRGB(255,105,180),"Rosa Quente"},
        {Color3.fromRGB(255,182,193),"Rosa Bebê"},
        {Color3.fromRGB(255,20,147), "Rosa Choque"},
        {Color3.fromRGB(255,100,100),"Salmão"},
        {Color3.fromRGB(255,140,0),  "Laranja Escuro"},
        {Color3.fromRGB(255,165,0),  "Laranja"},
        {Color3.fromRGB(255,200,60), "Amarelo Ouro"},
        {Color3.fromRGB(255,255,0),  "Amarelo"},
        {Color3.fromRGB(173,255,47), "Verde Neon"},
        {Color3.fromRGB(50,205,50),  "Verde Lima"},
        {Color3.fromRGB(0,180,0),    "Verde"},
        {Color3.fromRGB(0,100,0),    "Verde Escuro"},
        {Color3.fromRGB(0,255,127),  "Verde Água"},
        {Color3.fromRGB(64,224,208), "Turquesa"},
        {Color3.fromRGB(0,210,210),  "Ciano"},
        {Color3.fromRGB(170,80,255),  "Azul Claro"},
        {Color3.fromRGB(30,100,255), "Azul"},
        {Color3.fromRGB(0,0,180),    "Azul Escuro"},
        {Color3.fromRGB(0,0,80),     "Azul Marinho"},
        {Color3.fromRGB(75,0,130),   "Índigo"},
        {Color3.fromRGB(138,43,226), "Violeta"},
        {Color3.fromRGB(148,0,211),  "Roxo"},
        {Color3.fromRGB(200,0,200),  "Magenta"},
        {Color3.fromRGB(238,130,238),"Lavanda"},
        {Color3.fromRGB(139,69,19),  "Marrom"},
        {Color3.fromRGB(80,40,5),    "Marrom Escuro"},
        {Color3.fromRGB(205,133,63), "Marrom Claro"},
        {Color3.fromRGB(210,180,140),"Bege"},
        {Color3.fromRGB(255,215,0),  "Dourado"},
        {Color3.fromRGB(192,192,192),"Prata"},
        {Color3.fromRGB(255,127,80), "Coral"},
        {Color3.fromRGB(0,255,255),  "Ciano Neon"},
    }


    local function applyBallColor(col)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name == "TPS" then

                local sa = obj:FindFirstChildOfClass("SurfaceAppearance")
                if sa then sa:Destroy() end

                local mesh = obj:FindFirstChildOfClass("SpecialMesh")
                if mesh then
                    mesh.TextureId = ""
                    mesh.VertexColor = Vector3.new(1,1,1)
                end

                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("Decal") then
                        child.Color3 = col
                    end
                end
                obj.Color = col
            end
        end
    end

    local corAtual  = Color3.fromRGB(227,227,227)
    local nomeAtual = "Padrão"


    local curRow = Instance.new("Frame", pageBola)
    curRow.Size = UDim2.new(1,0,0,34)
    curRow.BackgroundColor3 = ITEM
    curRow.BorderSizePixel = 0
    curRow.ZIndex = 13
    corner(6, curRow)

    local curLbl = Instance.new("TextLabel", curRow)
    curLbl.Size = UDim2.new(1,-50,1,0)
    curLbl.Position = UDim2.new(0,9,0,0)
    curLbl.BackgroundTransparency = 1
    curLbl.Text = "Cor atual:  "..nomeAtual
    curLbl.TextColor3 = TEXT
    curLbl.Font = Enum.Font.Gotham
    curLbl.TextSize = 11
    curLbl.TextXAlignment = Enum.TextXAlignment.Left
    curLbl.ZIndex = 14

    local curDot = Instance.new("Frame", curRow)
    curDot.Size = UDim2.fromOffset(20,20)
    curDot.Position = UDim2.new(1,-28,0.5,-10)
    curDot.BackgroundColor3 = corAtual
    curDot.BorderSizePixel = 0
    curDot.ZIndex = 15
    corner(5, curDot)

    local curDotStroke = Instance.new("UIStroke", curDot)
    curDotStroke.Color = BLUE
    curDotStroke.Thickness = 1


    local paleta = Instance.new("Frame", SG)
    paleta.Size = UDim2.fromOffset(270, 350)
    paleta.Position = UDim2.new(0.5,-135,0.5,-175)
    paleta.BackgroundColor3 = BG
    paleta.BorderSizePixel = 0
    paleta.ZIndex = 6000
    paleta.Visible = false
    corner(10, paleta)

    local palStk = Instance.new("UIStroke", paleta)
    palStk.Color = BLUE
    palStk.Thickness = 1.5


    local palTop = Instance.new("Frame", paleta)
    palTop.Size = UDim2.new(1,0,0,36)
    palTop.BackgroundColor3 = TOP
    palTop.BorderSizePixel = 0
    palTop.ZIndex = 6001
    corner(10, palTop)

    local palFix = Instance.new("Frame", palTop)
    palFix.Size = UDim2.new(1,0,0,10)
    palFix.Position = UDim2.new(0,0,1,-10)
    palFix.BackgroundColor3 = TOP
    palFix.BorderSizePixel = 0
    palFix.ZIndex = 6001

    local palTitulo = Instance.new("TextLabel", palTop)
    palTitulo.Size = UDim2.new(1,-40,1,0)
    palTitulo.Position = UDim2.new(0,12,0,0)
    palTitulo.BackgroundTransparency = 1
    palTitulo.Text = "🎨  Cor da Bola"
    palTitulo.TextColor3 = WHITE
    palTitulo.Font = Enum.Font.GothamBold
    palTitulo.TextSize = 13
    palTitulo.TextXAlignment = Enum.TextXAlignment.Left
    palTitulo.ZIndex = 6002

    local palFechar = Instance.new("TextButton", palTop)
    palFechar.Size = UDim2.fromOffset(24,24)
    palFechar.Position = UDim2.new(1,-30,0.5,-12)
    palFechar.BackgroundColor3 = RED
    palFechar.Text = "×"
    palFechar.TextColor3 = WHITE
    palFechar.Font = Enum.Font.GothamBold
    palFechar.TextSize = 16
    palFechar.BorderSizePixel = 0
    palFechar.ZIndex = 6002
    corner(5, palFechar)
    palFechar.MouseButton1Click:Connect(function() paleta.Visible = false end)


    local hoverLbl = Instance.new("TextLabel", paleta)
    hoverLbl.Size = UDim2.new(1,-16,0,16)
    hoverLbl.Position = UDim2.new(0,8,0,40)
    hoverLbl.BackgroundTransparency = 1
    hoverLbl.Text = "Toque em uma cor para aplicar"
    hoverLbl.TextColor3 = TEXTD
    hoverLbl.Font = Enum.Font.Gotham
    hoverLbl.TextSize = 10
    hoverLbl.TextXAlignment = Enum.TextXAlignment.Left
    hoverLbl.ZIndex = 6002


    local gridScroll = Instance.new("ScrollingFrame", paleta)
    gridScroll.Size = UDim2.new(1,-10,1,-100)
    gridScroll.Position = UDim2.new(0,5,0,60)
    gridScroll.BackgroundTransparency = 1
    gridScroll.BorderSizePixel = 0
    gridScroll.ScrollBarThickness = 3
    gridScroll.ScrollBarImageColor3 = BLUE
    gridScroll.CanvasSize = UDim2.new(0,0,0,0)
    gridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    gridScroll.ZIndex = 6001

    local gl = Instance.new("UIGridLayout", gridScroll)
    gl.CellSize = UDim2.fromOffset(38,38)
    gl.CellPadding = UDim2.fromOffset(5,5)
    gl.SortOrder = Enum.SortOrder.LayoutOrder

    local glPad = Instance.new("UIPadding", gridScroll)
    glPad.PaddingLeft  = UDim.new(0,4)
    glPad.PaddingTop   = UDim.new(0,4)
    glPad.PaddingRight = UDim.new(0,4)


    local resetBtn = Instance.new("TextButton", paleta)
    resetBtn.Size = UDim2.new(1,-16,0,30)
    resetBtn.Position = UDim2.new(0,8,1,-38)
    resetBtn.BackgroundColor3 = BLUED
    resetBtn.Text = "🔄  Resetar cor padrão"
    resetBtn.TextColor3 = TEXT
    resetBtn.Font = Enum.Font.GothamBold
    resetBtn.TextSize = 11
    resetBtn.BorderSizePixel = 0
    resetBtn.ZIndex = 6002
    corner(6, resetBtn)

    local rstStk = Instance.new("UIStroke", resetBtn)
    rstStk.Color = BLUE
    rstStk.Thickness = 1

    resetBtn.MouseButton1Click:Connect(function()
        local def = Color3.fromRGB(227,227,227)
        applyBallColor(def)
        corAtual = def; nomeAtual = "Padrão"
        curDot.BackgroundColor3 = def
        curLbl.Text = "Cor atual:  Padrão"
        paleta.Visible = false
        hoverLbl.Text = "Toque em uma cor para aplicar"
        hoverLbl.TextColor3 = TEXTD
        notify("🔄 Cor resetada para padrão!")
    end)


    for i, data in ipairs(CORES) do
        local col, nome = data[1], data[2]

        local sw = Instance.new("TextButton", gridScroll)
        sw.BackgroundColor3 = col
        sw.Text = ""
        sw.BorderSizePixel = 0
        sw.ZIndex = 6002
        sw.LayoutOrder = i
        corner(7, sw)

        local swStk = Instance.new("UIStroke", sw)
        swStk.Color = Color3.fromRGB(30,40,65)
        swStk.Thickness = 1.5

        sw.MouseEnter:Connect(function()
            hoverLbl.Text = nome
            hoverLbl.TextColor3 = col
            TW:Create(swStk,TweenInfo.new(0.1),{Color=WHITE,Thickness=2.5}):Play()
        end)
        sw.MouseLeave:Connect(function()
            hoverLbl.Text = "Toque em uma cor para aplicar"
            hoverLbl.TextColor3 = TEXTD
            TW:Create(swStk,TweenInfo.new(0.1),{Color=Color3.fromRGB(30,40,65),Thickness=1.5}):Play()
        end)
        sw.MouseButton1Click:Connect(function()
            applyBallColor(col)
            corAtual = col; nomeAtual = nome
            curDot.BackgroundColor3 = col
            curDotStroke.Color = col
            curLbl.Text = "Cor atual:  "..nome
            paleta.Visible = false
            hoverLbl.Text = "Toque em uma cor para aplicar"
            hoverLbl.TextColor3 = TEXTD
            notify("🎨 "..nome.." aplicada!", col)
        end)
    end

    addButton(pageBola,"🎨  Selecionar Cor da Bola",function()
        paleta.Visible = not paleta.Visible
    end)
end

addSection(pageBola,"Auto Skill")
do
    local autoSkillOn = false
    local skillConn   = nil
    local claimTimer  = 0
    local dribleSpd   = 3.0
    local miniSG      = nil
    local inContact   = false
    local DIST_IN     = 4
    local DIST_OUT    = 6

    local function stopSkill()
        autoSkillOn = false
        claimTimer  = 0
        if skillConn then skillConn:Disconnect(); skillConn = nil end
        if miniSG    then miniSG:Destroy();       miniSG    = nil end
    end

    local function criarMiniGui()
        if miniSG then miniSG:Destroy() end

        miniSG = Instance.new("ScreenGui", LP.PlayerGui)
        miniSG.Name = "AutoSkillMini"
        miniSG.ResetOnSpawn = false
        miniSG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        local mf = Instance.new("Frame", miniSG)
        mf.Size = UDim2.fromOffset(162, 38)
        mf.Position = UDim2.new(0.5, -81, 0.12, 0)
        mf.BackgroundColor3 = BG
        mf.BorderSizePixel = 0
        mf.ZIndex = 500
        corner(19, mf)
        local mStk = Instance.new("UIStroke", mf)
        mStk.Color = BLUE; mStk.Thickness = 1.5

        local mLbl = Instance.new("TextLabel", mf)
        mLbl.Size = UDim2.new(1,-54,1,0)
        mLbl.Position = UDim2.new(0,12,0,0)
        mLbl.BackgroundTransparency = 1
        mLbl.Text = "🎯  Auto Skill"
        mLbl.TextColor3 = TEXT
        mLbl.Font = Enum.Font.GothamBold
        mLbl.TextSize = 11
        mLbl.TextXAlignment = Enum.TextXAlignment.Left
        mLbl.ZIndex = 501

        local mBg = Instance.new("Frame", mf)
        mBg.Size = UDim2.fromOffset(36,20)
        mBg.Position = UDim2.new(1,-46,0.5,-10)
        mBg.BackgroundColor3 = BLUE
        mBg.BorderSizePixel = 0
        mBg.ZIndex = 501
        corner(10, mBg)

        local mKnob = Instance.new("Frame", mBg)
        mKnob.Size = UDim2.fromOffset(14,14)
        mKnob.Position = UDim2.new(1,-17,0.5,-7)
        mKnob.BackgroundColor3 = WHITE
        mKnob.BorderSizePixel = 0
        mKnob.ZIndex = 502
        corner(7, mKnob)

        local mBtn = Instance.new("TextButton", mf)
        mBtn.Size = UDim2.new(1,0,1,0)
        mBtn.BackgroundTransparency = 1
        mBtn.Text = ""
        mBtn.ZIndex = 503

        local mMoved = false
        local mDrag, mStart, mPos = false, nil, nil

        mBtn.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                mDrag = true; mStart = i.Position; mPos = mf.Position; mMoved = false
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if mDrag and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - mStart
                if d.Magnitude > 4 then mMoved = true end
                mf.Position = UDim2.new(mPos.X.Scale, mPos.X.Offset+d.X, mPos.Y.Scale, mPos.Y.Offset+d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                mDrag = false
            end
        end)

        mBtn.MouseButton1Click:Connect(function()
            if mMoved then return end
            TW:Create(mBg,   TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(38,38,58)}):Play()
            TW:Create(mKnob, TweenInfo.new(0.15), {Position = UDim2.new(0,3,0.5,-7), BackgroundColor3 = Color3.fromRGB(110,110,145)}):Play()
            task.wait(0.15)
            stopSkill()
            notify("🔴 Auto Skill desativado", Color3.fromRGB(200,200,200))
        end)
    end

    addToggle(pageBola,"🎯  Auto Skill",false,function(v)
        if v then
            autoSkillOn = true
            skillConn = RunService.Heartbeat:Connect(function(dt)
                if not autoSkillOn then skillConn:Disconnect(); skillConn = nil; return end

                local ball = FindBallTP()
                local c    = LP.Character
                local hrp  = c and c:FindFirstChild("HumanoidRootPart")
                if not hrp or not ball then return end

                local dist = (ball.Position - hrp.Position).Magnitude


                if not inContact and dist <= DIST_IN then
                    inContact = true
                elseif inContact and dist > DIST_OUT then
                    inContact = false
                    claimTimer = 0
                end

                if not inContact then return end


                claimTimer = claimTimer + dt
                if claimTimer >= 0.08 then
                    claimTimer = 0
                    task.spawn(ClaimOwner, ball)
                end

                local t       = tick()
                local right   = hrp.CFrame.RightVector
                local forward = hrp.CFrame.LookVector

                local side = math.sin(t * dribleSpd) * 2.0
                local fwd  = math.sin(t * dribleSpd * 0.5) * 1.0 + 1.8
                local ballY = hrp.Position.Y - 2.0

                local rawTarget = hrp.Position + right * side + forward * fwd
                local target    = Vector3.new(rawTarget.X, ballY, rawTarget.Z)


                local toTarget = target - ball.Position
                if toTarget.Magnitude > 0.05 then
                    local spd = math.min(toTarget.Magnitude * 12, 40)
                    ball.AssemblyLinearVelocity = toTarget.Unit * spd
                else
                    ball.AssemblyLinearVelocity = Vector3.new(0,0,0)
                end
            end)
            criarMiniGui()
            notify("🎯 Auto Skill ATIVADO!")
        else
            stopSkill()
            notify("🔴 Auto Skill desativado", Color3.fromRGB(200,200,200))
        end
    end)

    addSlider(pageBola,"Velocidade do Drible",1,10,6,1,function(v)
        dribleSpd = v * 0.5
    end)
end

addSection(pageBola,"Auto Farm Save")
do
    local farmOn    = false
    local farmTask  = nil
    local catchConn = nil

    local POS1_AWAY = Vector3.new(-18.176804, -28.935629,  327.618164)
    local POS2_AWAY = Vector3.new(-16.469315, -28.935629,  379.894714)
    local POS1_HOME = Vector3.new(-18.176628, -28.935629, -143.833786)
    local POS2_HOME = Vector3.new(-18.082869, -28.935629, -198.238998)

    local function isGKTaken(keyword)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Team then
                local nm = p.Team.Name:lower()
                if nm:find(keyword) and nm:find("gk") then return true end
            end
        end
        return false
    end

    local function stopFarm()
        farmOn = false
        if farmTask  then task.cancel(farmTask);  farmTask  = nil end
        if catchConn then catchConn:Disconnect(); catchConn = nil end
    end

    addToggle(pageBola,"🧤  Auto Farm Save",false,function(v)
        if v then
            local gkRole, pos1, pos2

            if not isGKTaken("away") then
                gkRole = "-Away GK"; pos1 = POS1_AWAY; pos2 = POS2_AWAY
                notify("🟢 Away GK disponível! Iniciando...", GREEN)
            elseif not isGKTaken("home") then
                gkRole = "-Home GK"; pos1 = POS1_HOME; pos2 = POS2_HOME
                notify("🔵 Away GK ocupado. Usando Home GK!", Color3.fromRGB(80,140,255))
            else
                notify("❌ Ambos os goleiros estão ocupados!", Color3.fromRGB(255,80,80))
                return
            end

            farmOn = true
            pcall(function() ReplicatedStorage.ChangeTeam:FireServer(gkRole) end)
            task.wait(0.6)


            local catchTimer = 0
            catchConn = RunService.Heartbeat:Connect(function(dt)
                if not farmOn then catchConn:Disconnect(); catchConn = nil; return end
                catchTimer = catchTimer + dt
                if catchTimer >= 0.08 then
                    catchTimer = 0
                    local ball = FindBallTP()
                    if ball then
                        pcall(function() ReplicatedStorage.CatchBall:FireServer(ball) end)
                    end
                end
            end)

            farmTask = task.spawn(function()
                while farmOn do

                    local arrived = false
                    while farmOn and not arrived do
                        local c   = LP.Character
                        local hrp = c and c:FindFirstChild("HumanoidRootPart")
                        if not hrp then task.wait(0.1); break end

                        local ball = FindBallTP()
                        if ball then
                            hrp.CFrame = CFrame.new(ball.Position + Vector3.new(0, 3, 0))
                            firetouchinterest(ball, hrp, 0)
                            firetouchinterest(ball, hrp, 1)
                            ball.AssemblyLinearVelocity = (pos1 - ball.Position).Unit * 180

                            if (pos1 - ball.Position).Magnitude < 4 then
                                ball.AssemblyLinearVelocity = Vector3.zero
                                arrived = true
                            end
                        end
                        task.wait(0.01)
                    end

                    if not farmOn then break end


                    local ca   = LP.Character
                    local hrpa = ca and ca:FindFirstChild("HumanoidRootPart")
                    if hrpa then hrpa.CFrame = CFrame.new(pos1 + Vector3.new(0, 3, 0)) end


                    task.wait(2)
                    if not farmOn then break end


                    local cb   = LP.Character
                    local hrpb = cb and cb:FindFirstChild("HumanoidRootPart")
                    if hrpb then hrpb.CFrame = CFrame.new(pos2) end
                    task.wait(2)


                end
            end)
        else
            stopFarm()
            notify("🔴 Auto Farm Save desativado", Color3.fromRGB(200,200,200))
        end
    end)
end

addSection(pageBola,"Ball Predict")
do
    local predictOn   = false
    local predictConn = nil


    local landAnchor  = nil
    local landSelBox  = nil


    local NUM_CHV  = 6
    local ARM_LEN  = 1.7
    local ARM_W    = 0.18
    local ARM_H    = 0.1
    local ANGLE    = math.rad(40)
    local chevrons = {}


    local function getNearestTPS()
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local nearest, bestDist = nil, math.huge
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Name == "TPS" then
                local d = (v.Position - hrp.Position).Magnitude
                if d < bestDist then bestDist = d; nearest = v end
            end
        end
        return nearest
    end

    local function predictLanding(ball)
        local pos = ball.Position
        local vel = ball.AssemblyLinearVelocity
        if vel.Magnitude < 2 then return nil end
        local g = -workspace.Gravity; local dt = 0.05
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local char = LP.Character
        params.FilterDescendantsInstances = char and {char, ball} or {ball}
        for _ = 1, 160 do
            local newPos = Vector3.new(
                pos.X + vel.X*dt,
                pos.Y + vel.Y*dt + 0.5*g*dt*dt,
                pos.Z + vel.Z*dt)
            local newVel = Vector3.new(vel.X, vel.Y + g*dt, vel.Z)
            local dir = newPos - pos

            if dir.Y < 0 and dir.Magnitude > 0.01 then
                local hit = workspace:Raycast(pos, dir, params)

                if hit and hit.Normal.Y > 0.5 then
                    return Vector3.new(hit.Position.X, hit.Position.Y, hit.Position.Z)
                end
            end
            pos = newPos; vel = newVel
        end
        return nil
    end


    local function criarMarcador()
        if landAnchor and landAnchor.Parent then return end
        landAnchor = Instance.new("Part")
        landAnchor.Name="BPredictAnchor"; landAnchor.Anchored=true
        landAnchor.CanCollide=false; landAnchor.CanQuery=false
        landAnchor.CanTouch=false; landAnchor.CastShadow=false
        landAnchor.Size=Vector3.new(3.2,0.1,3.2)
        landAnchor.Transparency=1; landAnchor.Parent=workspace

        landSelBox = Instance.new("SelectionBox")
        landSelBox.Color3          = Color3.fromRGB(0,200,255)
        landSelBox.LineThickness   = 0.09
        landSelBox.SurfaceTransparency = 1
        landSelBox.SurfaceColor3   = Color3.fromRGB(0,200,255)
        landSelBox.Adornee         = nil
        landSelBox.Parent          = workspace
    end

    local function destruirMarcador()
        if landSelBox and landSelBox.Parent then landSelBox:Destroy() end
        if landAnchor and landAnchor.Parent then landAnchor:Destroy() end
        landSelBox=nil; landAnchor=nil
    end

    local function setMarcadorPos(landPos)
        if not landAnchor or not landAnchor.Parent then return end


        local safeY = landPos.Y
        local down = workspace:Raycast(
            Vector3.new(landPos.X, landPos.Y + 3, landPos.Z),
            Vector3.new(0, -8, 0)
        )
        if down and down.Normal.Y > 0.5 then
            safeY = down.Position.Y
        end
        landAnchor.CFrame = CFrame.new(landPos.X, safeY + 0.05, landPos.Z)
        if landSelBox then landSelBox.Adornee = landAnchor end
    end

    local function ocultarMarcador()
        if landSelBox then landSelBox.Adornee = nil end
    end


    local function novaAsa()
        local p = Instance.new("Part")
        p.Anchored=true; p.CanCollide=false; p.CanQuery=false
        p.CanTouch=false; p.CastShadow=false
        p.Size=Vector3.new(ARM_W, ARM_H, ARM_LEN)
        p.Material=Enum.Material.Neon
        p.Color=Color3.fromRGB(255,80,0)
        p.Transparency=1; p.Parent=workspace
        return p
    end

    local function criarChevrons()
        for i = 1, NUM_CHV do
            chevrons[i] = {L=novaAsa(), R=novaAsa()}
        end
    end

    local function destruirChevrons()
        for _, c in ipairs(chevrons) do
            if c.L and c.L.Parent then c.L:Destroy() end
            if c.R and c.R.Parent then c.R:Destroy() end
        end
        chevrons = {}
    end

    local function atualizarChevrons(ballPos, landPos)

        local toLand = landPos - ballPos
        local dist3D = toLand.Magnitude

        if dist3D < 2 then
            for _, c in ipairs(chevrons) do
                if c.L.Parent then c.L.Transparency=1 end
                if c.R.Parent then c.R.Transparency=1 end
            end
            return
        end

        local forward = toLand.Unit


        local hFlat = Vector3.new(forward.X, 0, forward.Z)
        if hFlat.Magnitude < 0.01 then

            for _, c in ipairs(chevrons) do
                if c.L.Parent then c.L.Transparency=1 end
                if c.R.Parent then c.R.Transparency=1 end
            end
            return
        end
        local hDir  = hFlat.Unit
        local right = Vector3.new(-hDir.Z, 0, hDir.X)

        local cosA = math.cos(ANGLE)
        local sinA = math.sin(ANGLE)

        for i = 1, NUM_CHV do
            local c = chevrons[i]
            if not c then continue end


            local t   = 0.05 + (i - 1) * (0.77 / math.max(NUM_CHV - 1, 1))
            local tip = ballPos + toLand * t



            local lDir = (-forward * cosA - right * sinA).Unit
            c.L.CFrame = CFrame.new(tip + lDir*(ARM_LEN/2), tip + lDir*ARM_LEN)
            c.L.Transparency = 0.05

            local rDir = (-forward * cosA + right * sinA).Unit
            c.R.CFrame = CFrame.new(tip + rDir*(ARM_LEN/2), tip + rDir*ARM_LEN)
            c.R.Transparency = 0.05
        end
    end

    local function ocultarChevrons()
        for _, c in ipairs(chevrons) do
            if c.L and c.L.Parent then c.L.Transparency=1 end
            if c.R and c.R.Parent then c.R.Transparency=1 end
        end
    end


    addToggle(pageBola,"🎯  Ball Predict",false,function(v)
        predictOn = v
        if v then
            criarMarcador(); criarChevrons()
            predictConn = RunService.Heartbeat:Connect(function()
                if not predictOn then
                    if predictConn then predictConn:Disconnect(); predictConn=nil end
                    destruirMarcador(); destruirChevrons(); return
                end
                if not landAnchor or not landAnchor.Parent then criarMarcador() end
                if #chevrons == 0 then criarChevrons() end

                local ball = getNearestTPS()
                if not ball then ocultarMarcador(); ocultarChevrons(); return end

                local landPos = predictLanding(ball)
                if landPos then
                    setMarcadorPos(landPos)
                    atualizarChevrons(ball.Position, landPos)
                else
                    ocultarMarcador(); ocultarChevrons()
                end
            end)
            notify("🎯 Ball Predict ATIVADO!")
        else
            if predictConn then predictConn:Disconnect(); predictConn=nil end
            destruirMarcador(); destruirChevrons()
            notify("🔴 Ball Predict desativado", Color3.fromRGB(200,200,200))
        end
    end)
end

    local function getBall()
        return workspace:FindFirstChild("TPS")
            or workspace:FindFirstChild("MPS")
            or workspace:FindFirstChild("PRS")
    end

addSection(pagePlayer,"Speed")
addToggle(pagePlayer,"Speed (Anti Ban)",false,function(v)
    tpWalkEnabled=v
    notify(v and "✅ Speed ATIVADO!" or "🔴 Speed desativado", v and GREEN or Color3.fromRGB(200,200,200))
end)
addSlider(pagePlayer,"Speed",0,10,5,1,function(v) tpWalkSpeed=v/10 end)

addSection(pagePlayer,"Auto Ball")
do
    local autoFollowOn   = false
    local followDistance = 1.8
    local TargetCenter   = Vector3.new(0,-28.94,0)
    local CenterTol      = 3.5
    local followConn     = nil

    local function GetClosestBall()
        local c   = LP.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local best, dist = nil, math.huge
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name == "TPS" or obj.Name:lower():find("ball") or obj.Name:lower():find("bola")) then
                local sz      = obj.Size.X
                local atCenter = (obj.Position - TargetCenter).Magnitude <= CenterTol
                if sz >= 0.8 and sz <= 5.0 and not atCenter then
                    local d = (obj.Position - hrp.Position).Magnitude
                    if d < dist then dist = d; best = obj end
                end
            end
        end
        return best
    end

    local function IsManualMoving()
        local c   = LP.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0.05 then return true end
        return UserInputService:IsKeyDown(Enum.KeyCode.W)
            or UserInputService:IsKeyDown(Enum.KeyCode.A)
            or UserInputService:IsKeyDown(Enum.KeyCode.S)
            or UserInputService:IsKeyDown(Enum.KeyCode.D)
    end

    addToggle(pagePlayer,"⚽  Auto Ball",false,function(v)
        autoFollowOn = v
        if v then
            followConn = RunService.RenderStepped:Connect(function()
                if not autoFollowOn then return end
                if IsManualMoving() then return end

                local c   = LP.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum then return end

                local ball = GetClosestBall()
                if not ball then return end

                local ballPos = ball.Position
                local myPos   = hrp.Position
                local target  = Vector3.new(ballPos.X, myPos.Y, ballPos.Z)
                local dist    = (target - myPos).Magnitude

                if dist > followDistance then
                    hum:Move((target - myPos).Unit, false)
                end
            end)


            local old = LP.PlayerGui:FindFirstChild("AutoBallMini")
            if old then old:Destroy() end
            local abSG = Instance.new("ScreenGui", LP.PlayerGui)
            abSG.Name = "AutoBallMini"; abSG.ResetOnSpawn=false; abSG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

            local abF = Instance.new("Frame", abSG)
            abF.Size = UDim2.fromOffset(160,38); abF.Position = UDim2.new(0.5,-80,0.12,0)
            abF.BackgroundColor3=BG; abF.BorderSizePixel=0; abF.ZIndex=500; corner(19,abF)
            local abStk=Instance.new("UIStroke",abF); abStk.Color=BLUE; abStk.Thickness=1.5

            local abLbl=Instance.new("TextLabel",abF)
            abLbl.Size=UDim2.new(1,-54,1,0); abLbl.Position=UDim2.new(0,12,0,0)
            abLbl.BackgroundTransparency=1; abLbl.Text="⚽  Auto Ball"
            abLbl.TextColor3=TEXT; abLbl.Font=Enum.Font.GothamBold; abLbl.TextSize=11
            abLbl.TextXAlignment=Enum.TextXAlignment.Left; abLbl.ZIndex=501

            local abBg=Instance.new("Frame",abF)
            abBg.Size=UDim2.fromOffset(36,20); abBg.Position=UDim2.new(1,-46,0.5,-10)
            abBg.BackgroundColor3=BLUE; abBg.BorderSizePixel=0; abBg.ZIndex=501; corner(10,abBg)
            local abKnob=Instance.new("Frame",abBg)
            abKnob.Size=UDim2.fromOffset(14,14); abKnob.Position=UDim2.new(1,-17,0.5,-7)
            abKnob.BackgroundColor3=WHITE; abKnob.BorderSizePixel=0; abKnob.ZIndex=502; corner(7,abKnob)

            local abBtn=Instance.new("TextButton",abF)
            abBtn.Size=UDim2.new(1,0,1,0); abBtn.BackgroundTransparency=1; abBtn.Text=""; abBtn.ZIndex=503

            local abMoved,abDrag,abStart,abPos=false,false,nil,nil
            abBtn.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                    abDrag=true; abStart=i.Position; abPos=abF.Position; abMoved=false
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if abDrag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                    local d=i.Position-abStart
                    if d.Magnitude>4 then abMoved=true end
                    abF.Position=UDim2.new(abPos.X.Scale,abPos.X.Offset+d.X,abPos.Y.Scale,abPos.Y.Offset+d.Y)
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then abDrag=false end
            end)
            abBtn.MouseButton1Click:Connect(function()
                if abMoved then return end

                autoFollowOn = not autoFollowOn
                if autoFollowOn then
                    TW:Create(abBg,TweenInfo.new(0.15),{BackgroundColor3=BLUE}):Play()
                    TW:Create(abKnob,TweenInfo.new(0.15),{Position=UDim2.new(1,-17,0.5,-7),BackgroundColor3=WHITE}):Play()
                    notify("▶ Auto Ball resumido")
                else
                    TW:Create(abBg,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(38,38,58)}):Play()
                    TW:Create(abKnob,TweenInfo.new(0.15),{Position=UDim2.new(0,3,0.5,-7),BackgroundColor3=Color3.fromRGB(110,110,145)}):Play()
                    notify("⏸ Auto Ball pausado",Color3.fromRGB(255,165,0))
                end
            end)

            notify("⚽ Auto Ball ATIVADO!")
        else
            if followConn then followConn:Disconnect(); followConn=nil end
            local old2=LP.PlayerGui:FindFirstChild("AutoBallMini")
            if old2 then old2:Destroy() end
            notify("🔴 Auto Ball desativado", Color3.fromRGB(200,200,200))
        end
    end)

    addSlider(pagePlayer,"Distância de Parada",1,5,2,1,function(v)
        followDistance = v * 0.55
    end)
end

addSection(pagePlayer,"Proteção")
addButton(pagePlayer,"🛡️  Anti-Kick",function()
    hookfunction(LP.Kick,newcclosure(function() return nil end))
    notify("🛡️ Anti-Kick ATIVADO!")
end)

addSection(pagePlayer,"Player Trail")
do
    local TRAIL_CORES = {
        {Color3.fromRGB(255,255,255),"Branco"},          {Color3.fromRGB(200,200,200),"Cinza Claro"},
        {Color3.fromRGB(130,130,130),"Cinza"},           {Color3.fromRGB(30,30,30),  "Preto"},
        {Color3.fromRGB(255,50,50),  "Vermelho"},        {Color3.fromRGB(160,0,0),    "Verm. Escuro"},
        {Color3.fromRGB(220,20,60),  "Carmesim"},        {Color3.fromRGB(255,105,180),"Rosa Quente"},
        {Color3.fromRGB(255,182,193),"Rosa Bebê"},       {Color3.fromRGB(255,20,147), "Rosa Choque"},
        {Color3.fromRGB(255,140,0),  "Laranja Esc."},    {Color3.fromRGB(255,165,0),  "Laranja"},
        {Color3.fromRGB(255,215,0),  "Dourado"},         {Color3.fromRGB(255,255,0),  "Amarelo"},
        {Color3.fromRGB(173,255,47), "Verde Neon"},      {Color3.fromRGB(50,205,50),  "Verde Lima"},
        {Color3.fromRGB(0,180,0),    "Verde"},           {Color3.fromRGB(0,100,0),    "Verde Esc."},
        {Color3.fromRGB(0,255,127),  "Verde Água"},      {Color3.fromRGB(64,224,208), "Turquesa"},
        {Color3.fromRGB(0,210,210),  "Ciano"},           {Color3.fromRGB(170,80,255),  "Azul Claro"},
        {Color3.fromRGB(30,100,255), "Azul"},            {Color3.fromRGB(0,0,180),    "Azul Esc."},
        {Color3.fromRGB(75,0,130),   "Índigo"},          {Color3.fromRGB(148,0,211),  "Roxo"},
        {Color3.fromRGB(200,0,200),  "Magenta"},         {Color3.fromRGB(238,130,238),"Lavanda"},
        {Color3.fromRGB(139,69,19),  "Marrom"},          {Color3.fromRGB(255,127,80), "Coral"},
        {Color3.fromRGB(192,192,192),"Prata"},           {Color3.fromRGB(255,215,0),  "Ouro"},
        {Color3.fromRGB(0,255,255),  "Ciano Neon"},      {Color3.fromRGB(255,0,255),  "Magenta Neon"},
        {Color3.fromRGB(57,255,20),  "Verde Elétrico"},  {Color3.fromRGB(255,165,0),  "Âmbar"},
    }

    local playerTrailOn = false
    local pTrailColor   = Color3.fromRGB(255,255,255)
    local pAtt0, pAtt1, pTrail = nil, nil, nil

    local function buildPlayerTrail()
        local c = LP.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if pAtt0 and pAtt0.Parent then pAtt0:Destroy() end
        if pAtt1 and pAtt1.Parent then pAtt1:Destroy() end
        pAtt0 = Instance.new("Attachment", hrp); pAtt0.Position = Vector3.new(0,1,0)
        pAtt1 = Instance.new("Attachment", hrp); pAtt1.Position = Vector3.new(0,-1,0)
        pTrail = Instance.new("Trail", hrp)
        pTrail.Attachment0 = pAtt0; pTrail.Attachment1 = pAtt1
        pTrail.Color = ColorSequence.new(pTrailColor)
        pTrail.Lifetime = 0.7; pTrail.MinLength = 0; pTrail.FaceCamera = true
        pTrail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
    end

    local function destroyPlayerTrail()
        if pAtt0 and pAtt0.Parent then pAtt0:Destroy() end
        if pAtt1 and pAtt1.Parent then pAtt1:Destroy() end
        pAtt0, pAtt1, pTrail = nil, nil, nil
    end

    addToggle(pagePlayer,"✨  Player Trail",false,function(v)
        playerTrailOn = v
        if v then buildPlayerTrail(); notify("✨ Player Trail ATIVADO!")
        else destroyPlayerTrail(); notify("🔴 Player Trail desativado",Color3.fromRGB(200,200,200)) end
    end)

    LP.CharacterAdded:Connect(function()
        if playerTrailOn then task.wait(0.5); buildPlayerTrail() end
    end)


    local ptRow = Instance.new("Frame",pagePlayer)
    ptRow.Size = UDim2.new(1,0,0,34); ptRow.BackgroundColor3=ITEM; ptRow.BorderSizePixel=0; ptRow.ZIndex=13; corner(6,ptRow)
    local ptLbl = Instance.new("TextLabel",ptRow)
    ptLbl.Size=UDim2.new(1,-50,1,0); ptLbl.Position=UDim2.new(0,9,0,0); ptLbl.BackgroundTransparency=1
    ptLbl.Text="Cor:  Branco"; ptLbl.TextColor3=TEXT; ptLbl.Font=Enum.Font.Gotham; ptLbl.TextSize=11
    ptLbl.TextXAlignment=Enum.TextXAlignment.Left; ptLbl.ZIndex=14
    local ptDot = Instance.new("Frame",ptRow)
    ptDot.Size=UDim2.fromOffset(20,20); ptDot.Position=UDim2.new(1,-28,0.5,-10)
    ptDot.BackgroundColor3=pTrailColor; ptDot.BorderSizePixel=0; ptDot.ZIndex=15; corner(5,ptDot)
    local ptStk = Instance.new("UIStroke",ptDot); ptStk.Color=BLUE; ptStk.Thickness=1


    local ptPal = Instance.new("Frame",SG)
    ptPal.Size=UDim2.fromOffset(270,345); ptPal.Position=UDim2.new(0.5,-135,0.5,-172)
    ptPal.BackgroundColor3=BG; ptPal.BorderSizePixel=0; ptPal.ZIndex=7000; ptPal.Visible=false; corner(10,ptPal)
    local ptPStk=Instance.new("UIStroke",ptPal); ptPStk.Color=BLUE; ptPStk.Thickness=1.5
    local ptTop=Instance.new("Frame",ptPal); ptTop.Size=UDim2.new(1,0,0,36); ptTop.BackgroundColor3=TOP; ptTop.BorderSizePixel=0; ptTop.ZIndex=7001; corner(10,ptTop)
    local ptFix=Instance.new("Frame",ptTop); ptFix.Size=UDim2.new(1,0,0,10); ptFix.Position=UDim2.new(0,0,1,-10); ptFix.BackgroundColor3=TOP; ptFix.BorderSizePixel=0; ptFix.ZIndex=7001
    local ptTit=Instance.new("TextLabel",ptTop); ptTit.Size=UDim2.new(1,-40,1,0); ptTit.Position=UDim2.new(0,12,0,0); ptTit.BackgroundTransparency=1; ptTit.Text="✨  Cor do Player Trail"; ptTit.TextColor3=WHITE; ptTit.Font=Enum.Font.GothamBold; ptTit.TextSize=12; ptTit.TextXAlignment=Enum.TextXAlignment.Left; ptTit.ZIndex=7002
    local ptX=Instance.new("TextButton",ptTop); ptX.Size=UDim2.fromOffset(24,24); ptX.Position=UDim2.new(1,-30,0.5,-12); ptX.BackgroundColor3=RED; ptX.Text="×"; ptX.TextColor3=WHITE; ptX.Font=Enum.Font.GothamBold; ptX.TextSize=16; ptX.BorderSizePixel=0; ptX.ZIndex=7002; corner(5,ptX)
    ptX.MouseButton1Click:Connect(function() ptPal.Visible=false end)
    local ptHov=Instance.new("TextLabel",ptPal); ptHov.Size=UDim2.new(1,-16,0,16); ptHov.Position=UDim2.new(0,8,0,40); ptHov.BackgroundTransparency=1; ptHov.Text="Toque para selecionar"; ptHov.TextColor3=TEXTD; ptHov.Font=Enum.Font.Gotham; ptHov.TextSize=10; ptHov.TextXAlignment=Enum.TextXAlignment.Left; ptHov.ZIndex=7002
    local ptSc=Instance.new("ScrollingFrame",ptPal); ptSc.Size=UDim2.new(1,-10,1,-100); ptSc.Position=UDim2.new(0,5,0,60); ptSc.BackgroundTransparency=1; ptSc.BorderSizePixel=0; ptSc.ScrollBarThickness=3; ptSc.ScrollBarImageColor3=BLUE; ptSc.CanvasSize=UDim2.new(0,0,0,0); ptSc.AutomaticCanvasSize=Enum.AutomaticSize.Y; ptSc.ZIndex=7001
    local ptGl=Instance.new("UIGridLayout",ptSc); ptGl.CellSize=UDim2.fromOffset(38,38); ptGl.CellPadding=UDim2.fromOffset(5,5); ptGl.SortOrder=Enum.SortOrder.LayoutOrder
    local ptGP=Instance.new("UIPadding",ptSc); ptGP.PaddingLeft=UDim.new(0,4); ptGP.PaddingTop=UDim.new(0,4); ptGP.PaddingRight=UDim.new(0,4)
    local ptRst=Instance.new("TextButton",ptPal); ptRst.Size=UDim2.new(1,-16,0,30); ptRst.Position=UDim2.new(0,8,1,-38); ptRst.BackgroundColor3=BLUED; ptRst.Text="🔄  Resetar cor"; ptRst.TextColor3=TEXT; ptRst.Font=Enum.Font.GothamBold; ptRst.TextSize=11; ptRst.BorderSizePixel=0; ptRst.ZIndex=7002; corner(6,ptRst)
    local ptRS=Instance.new("UIStroke",ptRst); ptRS.Color=BLUE; ptRS.Thickness=1
    ptRst.MouseButton1Click:Connect(function()
        pTrailColor=Color3.fromRGB(255,255,255); ptDot.BackgroundColor3=pTrailColor; ptLbl.Text="Cor:  Branco"
        if pTrail and pTrail.Parent then pTrail.Color=ColorSequence.new(pTrailColor) end
        ptPal.Visible=false; notify("🔄 Cor resetada!")
    end)

    for i,d in ipairs(TRAIL_CORES) do
        local col,nome=d[1],d[2]
        local sw=Instance.new("TextButton",ptSc); sw.BackgroundColor3=col; sw.Text=""; sw.BorderSizePixel=0; sw.ZIndex=7002; sw.LayoutOrder=i; corner(7,sw)
        local ss=Instance.new("UIStroke",sw); ss.Color=Color3.fromRGB(30,40,65); ss.Thickness=1.5
        sw.MouseEnter:Connect(function() ptHov.Text=nome; ptHov.TextColor3=col; TW:Create(ss,TweenInfo.new(0.1),{Color=WHITE,Thickness=2.5}):Play() end)
        sw.MouseLeave:Connect(function() ptHov.Text="Toque para selecionar"; ptHov.TextColor3=TEXTD; TW:Create(ss,TweenInfo.new(0.1),{Color=Color3.fromRGB(30,40,65),Thickness=1.5}):Play() end)
        sw.MouseButton1Click:Connect(function()
            pTrailColor=col; ptDot.BackgroundColor3=col; ptLbl.Text="Cor:  "..nome
            if pTrail and pTrail.Parent then pTrail.Color=ColorSequence.new(col) end
            ptPal.Visible=false; notify("✨ Cor: "..nome,col)
        end)
    end

    addButton(pagePlayer,"🎨  Selecionar Cor do Trail",function() ptPal.Visible=not ptPal.Visible end)
end

addSection(pageMenu,"Scripts")
do
    local powerShootLoaded=false
    local powerShootOn=false
    local POWER_URL="https://pastefy.app/Vx4cpscu/raw"

    local function powerShootOff()
        powerShootOn=false
        getgenv().EMAN_POWER_SHOOT_ENABLED=false
        local cleaners={"DisablePowerShoot","PowerShootDisable","StopPowerShoot","UnloadPowerShoot"}
        for _,name in ipairs(cleaners) do
            local fn=nil
            pcall(function() fn=getgenv()[name] end)
            if type(fn)=="function" then pcall(fn) end
        end
    end

    addToggle(pageMenu,"⚡  Power Shoot",false,function(v)
        powerShootOn=v
        getgenv().EMAN_POWER_SHOOT_ENABLED=v
        if v then
            if not powerShootLoaded then
                local ok,err=pcall(function()
                    local src=game:HttpGet(POWER_URL)
                    local fn=loadstring(src)
                    if fn then fn() end
                end)
                if ok then
                    powerShootLoaded=true
                    notify("⚡ Power Shoot ativado!",GREEN)
                else
                    powerShootOn=false
                    getgenv().EMAN_POWER_SHOOT_ENABLED=false
                    notify("❌ Falha ao carregar Power Shoot",Color3.fromRGB(255,90,90))
                end
            else
                notify("⚡ Power Shoot ativado!",GREEN)
            end
        else
            powerShootOff()
            if powerShootLoaded then
                notify("🟠 Power Shoot desligado. O desligamento depende do script externo.",Color3.fromRGB(255,180,70))
            else
                notify("🔴 Power Shoot desligado",Color3.fromRGB(200,200,200))
            end
        end
    end)

    addButton(pageMenu,"↻  Recarregar Power Shoot",function()
        powerShootLoaded=false
        powerShootOn=false
        getgenv().EMAN_POWER_SHOOT_ENABLED=false
        task.wait()
        local ok=pcall(function()
            local src=game:HttpGet(POWER_URL)
            local fn=loadstring(src)
            if fn then fn() end
        end)
        if ok then
            powerShootLoaded=true
            powerShootOn=true
            getgenv().EMAN_POWER_SHOOT_ENABLED=true
            notify("⚡ Power Shoot recarregado!",GREEN)
        else
            notify("❌ Não foi possível recarregar Power Shoot",Color3.fromRGB(255,90,90))
        end
    end)
end

addButton(pageMenu,"🐛  Bug Ball (Dev)",function()
    loadstring(game:HttpGet("https://pastebin.com/raw/yEQUzHFG"))()
    notify("🐛 Bug Ball carregado!")
end)

addSection(pageMenu,"Control Ball")
do
    local controllOn = false
    local inContact  = false
    local touchConn  = nil
    local watchConn  = nil
    local moveConn   = nil
    local claimTimer = 0

    local function showAviso()
        local old = LP.PlayerGui:FindFirstChild("CBAviso")
        if old then old:Destroy() end

        local sg = Instance.new("ScreenGui", LP.PlayerGui)
        sg.Name = "CBAviso"
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        local f = Instance.new("Frame", sg)
        f.Size = UDim2.new(0, 320, 0, 50)
        f.Position = UDim2.new(0.5, -160, 0.15, 0)
        f.BackgroundColor3 = Color3.fromRGB(40, 20, 0)
        f.BorderSizePixel = 0
        f.ZIndex = 9000
        corner(8, f)

        local fStk = Instance.new("UIStroke", f)
        fStk.Color = Color3.fromRGB(200, 140, 30)
        fStk.Thickness = 1.5

        local lbl = Instance.new("TextLabel", f)
        lbl.Size = UDim2.new(1, -12, 1, 0)
        lbl.Position = UDim2.new(0, 6, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "⚠️  AVISO: Encoste na Bola primeiro"
        lbl.TextColor3 = Color3.fromRGB(230, 175, 60)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.ZIndex = 9001

        task.delay(2.5, function()
            for i = 1, 10 do
                if not f.Parent then return end
                f.BackgroundTransparency = i / 10
                lbl.TextTransparency = i / 10
                fStk.Transparency = i / 10
                task.wait(0.05)
            end
            if sg and sg.Parent then sg:Destroy() end
        end)
    end

    local function setupTouch(ball)
        if touchConn then touchConn:Disconnect() end
        touchConn = ball.Touched:Connect(function(hit)
            local c = LP.Character
            if c and hit:IsDescendantOf(c) then
                inContact = true
            else
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character and hit:IsDescendantOf(p.Character) then
                        inContact = false
                        return
                    end
                end
            end
        end)
    end

    addInfoBox(pageMenu,
        "Como funciona o Controll Ball?",
        "🇧🇷: ⚽ Para usar o Controll Ball, você precisa primeiro encostar na bola.\n\n📱 Depois, basta tocar em qualquer lugar da tela e a bola irá até o ponto onde você tocou.\n\nEncoste na bola → toque na tela → a bola vai até o toque.\n\n🇺🇸: ⚽ To use Controll Ball, you first need to touch the ball.\n\n📱 Then, simply tap anywhere on the screen, and the ball will go to the point where you tapped.\n\nTouch the ball → tap the screen → the ball goes to the tap."
    )

    addToggle(pageMenu,"🎯  Control Ball",false,function(v)
        controllOn = v
        inContact  = false
        claimTimer = 0

        if v then
            showAviso()

            local ball = FindBallTP()
            if ball then setupTouch(ball) end


            watchConn = RunService.Heartbeat:Connect(function()
                if not controllOn then watchConn:Disconnect(); watchConn = nil; return end
                local b = FindBallTP()
                if b and (not touchConn or not touchConn.Connected) then
                    setupTouch(b)
                end
            end)


            local mouse         = LP:GetMouse()
            local clickConn     = nil
            local currentTarget = nil

            clickConn = mouse.Button1Down:Connect(function()
                if not controllOn or not inContact then return end
                local ball2 = FindBallTP()
                local c     = LP.Character
                local hrp   = c and c:FindFirstChild("HumanoidRootPart")
                if not ball2 or not hrp then return end


                currentTarget = mouse.Hit.Position + Vector3.new(0, 1, 0)
                local myTarget = currentTarget

                task.spawn(function()
                    while controllOn and ball2 and ball2.Parent do

                        if currentTarget ~= myTarget then return end

                        local dist = (myTarget - ball2.Position).Magnitude
                        if dist < 2 then
                            ball2.AssemblyLinearVelocity = Vector3.zero
                            return
                        end

                        firetouchinterest(ball2, hrp, 0)
                        firetouchinterest(ball2, hrp, 1)
                        ball2.AssemblyLinearVelocity = (myTarget - ball2.Position).Unit * 65
                        task.wait(0.02)
                    end
                end)
            end)

            notify("🎯 Control Ball ATIVADO!")
        else
            if touchConn then touchConn:Disconnect(); touchConn = nil end
            if watchConn then watchConn:Disconnect(); watchConn = nil end
            local old = LP.PlayerGui:FindFirstChild("CBAviso")
            if old then old:Destroy() end
            notify("🔴 Control Ball desativado", Color3.fromRGB(200,200,200))
        end
    end)
end

addSection(pageMenu,"🎉  Celebrações (Gamepass)")
do
    local celebs = {
        {"Siuuu",           "Sii"},
        {"Siuuu Duplo",     "DoubleSii"},
        {"Calm Down",       "Calm"},
        {"Salto pra Trás",  "Backflip"},
        {"Salto pra Frente","Frontflip"},
        {"Meditação",       "Meditation"},
        {"Vuvuzela",        "Vuvuzela"},
        {"Malabarismo",     "Juggle"},
        {"O Cochilo",       "Nap"},
        {"Bola na Cabeça",  "HeadStall"},
    }

    local shown = false


    local mostrarRow = Instance.new("TextButton", pageMenu)
    mostrarRow.Size = UDim2.new(1,0,0,36)
    mostrarRow.BackgroundColor3 = ITEM
    mostrarRow.Text = ""
    mostrarRow.BorderSizePixel = 0
    mostrarRow.ZIndex = 13
    corner(6, mostrarRow)

    local mostrarLbl = Instance.new("TextLabel", mostrarRow)
    mostrarLbl.Size = UDim2.new(1,-40,1,0)
    mostrarLbl.Position = UDim2.new(0,10,0,0)
    mostrarLbl.BackgroundTransparency = 1
    mostrarLbl.Text = "👁  Mostrar Celebrações"
    mostrarLbl.TextColor3 = TEXT
    mostrarLbl.Font = Enum.Font.Gotham
    mostrarLbl.TextSize = 12
    mostrarLbl.TextXAlignment = Enum.TextXAlignment.Left
    mostrarLbl.ZIndex = 14

    local mostrarArrow = Instance.new("TextLabel", mostrarRow)
    mostrarArrow.Size = UDim2.new(0,26,1,0)
    mostrarArrow.Position = UDim2.new(1,-30,0,0)
    mostrarArrow.BackgroundTransparency = 1
    mostrarArrow.Text = "▼"
    mostrarArrow.TextColor3 = TEXTD
    mostrarArrow.Font = Enum.Font.GothamBold
    mostrarArrow.TextSize = 13
    mostrarArrow.ZIndex = 14


    local container = Instance.new("Frame", pageMenu)
    container.Size = UDim2.new(1,0,0,0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Visible = false

    local cList = Instance.new("UIListLayout", container)
    cList.SortOrder = Enum.SortOrder.LayoutOrder
    cList.Padding = UDim.new(0,4)

    for i, c in ipairs(celebs) do
        local nome, key = c[1], c[2]
        local btn = Instance.new("TextButton", container)
        btn.Size = UDim2.new(1,0,0,36)
        btn.BackgroundColor3 = ITEM
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.LayoutOrder = i
        btn.ZIndex = 13
        corner(6, btn)

        local lbl = Instance.new("TextLabel", btn)
        lbl.Size = UDim2.new(1,-40,1,0)
        lbl.Position = UDim2.new(0,10,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "🎊  "..nome
        lbl.TextColor3 = TEXT
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 14

        local arr = Instance.new("TextLabel", btn)
        arr.Size = UDim2.new(0,26,1,0)
        arr.Position = UDim2.new(1,-30,0,0)
        arr.BackgroundTransparency = 1
        arr.Text = "›"
        arr.TextColor3 = TEXTD
        arr.Font = Enum.Font.GothamBold
        arr.TextSize = 18
        arr.ZIndex = 14

        btn.MouseButton1Click:Connect(function()
            pcall(function() ReplicatedStorage.Celebration:FireServer(key) end)
            notify("🎊 "..nome.."!")
        end)
    end

    mostrarRow.MouseButton1Click:Connect(function()
        shown = not shown
        container.Visible = shown
        mostrarLbl.Text = shown and "▲  Ocultar Celebrações" or "👁  Mostrar Celebrações"
        mostrarArrow.Text = shown and "▲" or "▼"
    end)
end


local joystickSG=nil; local joyActive=false
local joyDragging=false; local joyActiveInput=nil; local joyInputPos=Vector2.zero
local joyStickRef=nil; local joyMainRef=nil

local function criarJoystick()
    local old=LP.PlayerGui:FindFirstChild("PremiumControlsFix")
    if old then old:Destroy() end
    joyDragging=false; joyActiveInput=nil; joyInputPos=Vector2.zero

    joystickSG=Instance.new("ScreenGui")
    joystickSG.Name="PremiumControlsFix"; joystickSG.ResetOnSpawn=false
    joystickSG.DisplayOrder=100; joystickSG.Parent=LP.PlayerGui

    local CZ=Instance.new("TextButton")
    CZ.Size=UDim2.new(0,200,0,200); CZ.Position=UDim2.new(0.15,-100,0.75,-100)
    CZ.BackgroundTransparency=1; CZ.Text=""; CZ.AutoButtonColor=false; CZ.Parent=joystickSG

    joyMainRef=Instance.new("Frame")
    joyMainRef.Size=UDim2.new(0,120,0,120); joyMainRef.Position=UDim2.new(0.5,-60,0.5,-60)
    joyMainRef.BackgroundColor3=Color3.fromRGB(30,30,30); joyMainRef.BackgroundTransparency=0.5
    joyMainRef.BorderSizePixel=0; joyMainRef.Parent=CZ; corner(60,joyMainRef)

    joyStickRef=Instance.new("Frame")
    joyStickRef.Size=UDim2.new(0,50,0,50); joyStickRef.Position=UDim2.new(0.5,-25,0.5,-25)
    joyStickRef.BackgroundColor3=Color3.fromRGB(255,255,255)
    joyStickRef.BorderSizePixel=0; joyStickRef.Parent=joyMainRef; corner(25,joyStickRef)

    local JumpBtn=Instance.new("TextButton")
    JumpBtn.Size=UDim2.new(0,80,0,80); JumpBtn.Position=UDim2.new(0.85,-40,0.75,-40)
    JumpBtn.BackgroundTransparency=1; JumpBtn.TextTransparency=1
    JumpBtn.BorderSizePixel=0; JumpBtn.AutoButtonColor=false; JumpBtn.Text=""; JumpBtn.Parent=joystickSG
    JumpBtn.MouseButton1Click:Connect(function()
        local char=LP.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Jump=true end
    end)

    CZ.InputBegan:Connect(function(input)
        if joyDragging then return end
        if input.UserInputType==Enum.UserInputType.Touch
        or input.UserInputType==Enum.UserInputType.MouseButton1 then
            joyDragging=true; joyActiveInput=input; joyInputPos=input.Position
        end
    end)

    joyActive=true
end

local function destruirJoystick()
    joyActive=false; joyDragging=false; joyActiveInput=nil
    if joystickSG then joystickSG:Destroy(); joystickSG=nil end
    joyStickRef=nil; joyMainRef=nil
end

UserInputService.InputChanged:Connect(function(input)
    if not joyActive or not joyDragging or not joyActiveInput then return end
    if input==joyActiveInput then
        joyInputPos=input.Position
    elseif joyActiveInput.UserInputType==Enum.UserInputType.MouseButton1
    and input.UserInputType==Enum.UserInputType.MouseMovement then
        joyInputPos=input.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not joyActive or not joyActiveInput then return end
    if input==joyActiveInput then
        joyDragging=false; joyActiveInput=nil; joyInputPos=Vector2.zero
        pcall(function()
            if joyStickRef and joyStickRef.Parent then
                joyStickRef:TweenPosition(UDim2.new(0.5,-25,0.5,-25),"Out","Quad",0.1,true)
            end
        end)
    end
end)

RunService.RenderStepped:Connect(function()
    if not joyActive or not joyDragging or not joyActiveInput then return end
    if not joyStickRef or not joyMainRef then return end
    local char=LP.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local cam=workspace.CurrentCamera
    local center=joyMainRef.AbsolutePosition+(joyMainRef.AbsoluteSize/2)
    local diff=Vector2.new(joyInputPos.X-center.X,joyInputPos.Y-center.Y)
    local dist=math.min(diff.Magnitude,55)
    if dist>0 then
        local angle=math.atan2(diff.Y,diff.X)
        pcall(function()
            joyStickRef.Position=UDim2.new(0.5,(math.cos(angle)*dist)-25,0.5,(math.sin(angle)*dist)-25)
        end)
        local cameraCF=cam.CFrame
        local fwd=Vector3.new(cameraCF.LookVector.X,0,cameraCF.LookVector.Z)
        local rgt=Vector3.new(cameraCF.RightVector.X,0,cameraCF.RightVector.Z)
        if fwd.Magnitude>0 then fwd=fwd.Unit end
        if rgt.Magnitude>0 then rgt=rgt.Unit end
        local dir=Vector2.new(math.cos(angle)*(dist/55),math.sin(angle)*(dist/55))
        local moveDir=rgt*dir.X+fwd*(-dir.Y)
        if moveDir.Magnitude>0 then hum:Move(moveDir.Unit,false) end
    end
end)

addSection(pageMenu,"Auto Dive")
do
    local function criarMiniDive(label)
        if adMiniSG then adMiniSG:Destroy() end
        adMiniSG=Instance.new("ScreenGui",LP.PlayerGui)
        adMiniSG.Name="AutoDiveMini"; adMiniSG.ResetOnSpawn=false; adMiniSG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        local mf=Instance.new("Frame",adMiniSG)
        mf.Size=UDim2.fromOffset(185,38); mf.Position=UDim2.new(0.5,-93,0.12,0)
        mf.BackgroundColor3=BG; mf.BorderSizePixel=0; corner(19,mf)
        local mStk=Instance.new("UIStroke",mf); mStk.Color=BLUE; mStk.Thickness=1.5
        local mLbl=Instance.new("TextLabel",mf)
        mLbl.Size=UDim2.new(1,-54,1,0); mLbl.Position=UDim2.new(0,12,0,0)
        mLbl.BackgroundTransparency=1; mLbl.Text="🤿  "..label
        mLbl.TextColor3=TEXT; mLbl.Font=Enum.Font.GothamBold; mLbl.TextSize=11
        mLbl.TextXAlignment=Enum.TextXAlignment.Left; mLbl.ZIndex=501
        local mBg=Instance.new("Frame",mf)
        mBg.Size=UDim2.fromOffset(36,20); mBg.Position=UDim2.new(1,-46,0.5,-10)
        mBg.BackgroundColor3=BLUE; mBg.BorderSizePixel=0; corner(10,mBg)
        local mKnob=Instance.new("Frame",mBg)
        mKnob.Size=UDim2.fromOffset(14,14); mKnob.Position=UDim2.new(1,-17,0.5,-7)
        mKnob.BackgroundColor3=WHITE; mKnob.BorderSizePixel=0; corner(7,mKnob)
        local mBtn=Instance.new("TextButton",mf)
        mBtn.Size=UDim2.new(1,0,1,0); mBtn.BackgroundTransparency=1; mBtn.Text=""; mBtn.ZIndex=503
        local mPaused=false; local mMoved,mDrag,mStart,mPos=false,false,nil,nil
        mBtn.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                mDrag=true; mStart=i.Position; mPos=mf.Position; mMoved=false
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if mDrag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                local d=i.Position-mStart; if d.Magnitude>4 then mMoved=true end
                mf.Position=UDim2.new(mPos.X.Scale,mPos.X.Offset+d.X,mPos.Y.Scale,mPos.Y.Offset+d.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then mDrag=false end
        end)
        local isAC=true
        mBtn.MouseButton1Click:Connect(function()
            if mMoved then return end
            mPaused=not mPaused
            if mPaused then
                adacOn=false
                TW:Create(mBg,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(38,38,58)}):Play()
                TW:Create(mKnob,TweenInfo.new(0.15),{Position=UDim2.new(0,3,0.5,-7),BackgroundColor3=Color3.fromRGB(110,110,145)}):Play()
                mLbl.TextColor3=TEXTD
            else
                adacOn=true
                TW:Create(mBg,TweenInfo.new(0.15),{BackgroundColor3=BLUE}):Play()
                TW:Create(mKnob,TweenInfo.new(0.15),{Position=UDim2.new(1,-17,0.5,-7),BackgroundColor3=WHITE}):Play()
                mLbl.TextColor3=TEXT
            end
        end)
    end

    addToggle(pageMenu,"🤿  Auto Dive + Agarrar Automático",false,function(v)
        adacOn=v
        if v then criarMiniDive("Dive + Agarrar Auto"); criarJoystick(); notify("🤿 Auto Dive + Agarrar Automático ATIVO!",GREEN)
        else adacOn=false
            if adMiniSG then adMiniSG:Destroy(); adMiniSG=nil end
            destruirJoystick()
            notify("🔴 Auto Dive desativado",Color3.fromRGB(200,200,200))
        end
    end)
end

RunService.Heartbeat:Connect(function()
    if not adacOn then return end
    local c=LP.Character; local hrp=c and c:FindFirstChild("HumanoidRootPart")
    local hum=c and c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local tool,equipped=findGKTool()
    if tool and not equipped then pcall(function() hum:EquipTool(tool) end) end
    local ball=getBallNearest(hrp)
    if not ball then return end
    if tick()-lastDive<DIVE_CD then return end
    local detectDist = 12
    if not diveIncoming(hrp,ball,detectDist) then return end
    lastDive=tick()
    local kc,kname,needJump=getDiveKey(hrp,ball)
    task.spawn(function()
        if needJump then pressKeyDive(Enum.KeyCode.Space) end
        pressKeyDive(kc)
        gkDiveTouch(ball)
        if adacOn then
            local dist=(ball.Position-hrp.Position).Magnitude
            if dist<=adCatchReach then
                pcall(function()
                    local args={[1]=ball}
                    ReplicatedStorage.CatchBall:FireServer(unpack(args))
                end)
                pcall(function()
                    local args={[1]="BallSound",[2]=ball}
                    ReplicatedStorage.Client:FireServer(unpack(args))
                end)
            end
        end
    end)
end)

--------------------------------------------------
-- REACH • OLISE CORE • FIXED18
-- Núcleo baseado diretamente no Reach do Olise Hub fornecido pelo usuário.
-- No Olise, o alcance é 1:1 em studs, a esfera usa reach*2 e o loop toca
-- ball -> bodyPart quando a distância está dentro do valor configurado.

local ReachEnabled = false
local ReachDistance = 3.5
local ReachVisualizerEnabled = false
local ReachVisualizerBall = nil
local ReachVisualizerRing = nil
local ReachVisualizerBillboard = nil
local ReachVisualizerConn = nil
local ReachStatusLabel = nil

-- Cache leve: evita Workspace:GetDescendants() por frame.
local ReachBalls = {}
local ReachBallsStamp = 0
local ReachBallRefreshInterval = 0.75
local ReachBodyParts = {}
local ReachBodyCharacter = nil
local ReachActionToken = 0

local function GetReachStuds()
    -- 1:1 com o Olise: valor do regulador = studs reais.
    return ReachDistance
end

local function UpdateReachStatus()
    local studs = GetReachStuds()
    if ReachStatusLabel then
        ReachStatusLabel.Text = string.format(
            "Configuração: %.1f / 10  •  Alcance efetivo: %.1f studs",
            ReachDistance,
            studs
        )
    end

    local diameter = math.max(0.2, studs * 2)
    if ReachVisualizerBall then
        ReachVisualizerBall.Size = Vector3.new(diameter, diameter, diameter)
    end
    if ReachVisualizerRing then
        ReachVisualizerRing.Size = Vector3.new(diameter, 0.16, diameter)
    end
    if ReachVisualizerBillboard then
        local label = ReachVisualizerBillboard:FindFirstChild("Label")
        if label then
            label.Text = string.format("REACH %.1f studs", studs)
        end
    end
end

local function RefreshReachBalls(force)
    local now = os.clock()
    if not force and now - ReachBallsStamp < ReachBallRefreshInterval then
        return
    end
    ReachBallsStamp = now

    local seen = {}
    table.clear(ReachBalls)

    -- TCS usa workspace.TPS neste jogo; checar direto é barato e pega
    -- respawn/troca de bola imediatamente sem varrer o Workspace.
    local direct = workspace:FindFirstChild("TPS")
    if direct and direct:IsA("BasePart") and direct.Parent then
        ReachBalls[#ReachBalls + 1] = direct
        seen[direct] = true
    end

    -- Compatibilidade com outras variantes de bola do TCS/Olise.
    local names = {"ESA","MRS","PRS","MPS","SSS","AIFA","RBZ","TRS","TCS"}
    for _, name in ipairs(names) do
        local obj = workspace:FindFirstChild(name)
        if obj and obj:IsA("BasePart") and obj.Parent and not seen[obj] then
            ReachBalls[#ReachBalls + 1] = obj
            seen[obj] = true
        end
    end

    -- Fallback periódico igual ao conceito do Olise: uma busca ampla, mas
    -- só algumas vezes por segundo, nunca em cada frame.
    if #ReachBalls == 0 then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local n = obj.Name
                if (n == "TPS" or n == "ESA" or n == "MRS" or n == "PRS" or n == "MPS") and not seen[obj] then
                    ReachBalls[#ReachBalls + 1] = obj
                    seen[obj] = true
                end
            end
        end
    end
end

local function RebuildReachBodyParts(char)
    ReachBodyCharacter = char
    table.clear(ReachBodyParts)
    if not char then return end

    -- Olise usa todas as partes do personagem, exceto o HumanoidRootPart.
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            ReachBodyParts[#ReachBodyParts + 1] = p
        end
    end
end

local function GetReachBodyParts(char)
    if ReachBodyCharacter ~= char or #ReachBodyParts == 0 then
        RebuildReachBodyParts(char)
    end
    return ReachBodyParts
end

local function TouchReachOlise(ball, part)
    if not firetouchinterest or not ball or not part then return end
    if not ball.Parent or not part.Parent then return end
    -- Esta é a direção usada no Olise: bola -> parte do jogador.
    pcall(function()
        firetouchinterest(ball, part, 0)
        firetouchinterest(ball, part, 1)
    end)
end

local function DoOliseReach()
    if not ReachEnabled or not firetouchinterest then return end

    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    RefreshReachBalls(false)
    if #ReachBalls == 0 then return end

    local parts = GetReachBodyParts(char)
    local reach = GetReachStuds()
    local reachSq = reach * reach

    -- Mesmo conceito do Olise, mas sem criar uma lista nova de partes e
    -- sem GetDescendants por frame.
    for i = 1, #parts do
        local part = parts[i]
        if part and part.Parent then
            local ppos = part.Position
            for j = 1, #ReachBalls do
                local ball = ReachBalls[j]
                if ball and ball.Parent then
                    local delta = ball.Position - ppos
                    if delta:Dot(delta) <= reachSq then
                        TouchReachOlise(ball, part)
                    end
                end
            end
        end
    end
end

-- TCS ACTION BRIDGE • FIXED19
-- O Olise resolve o drible com touch contínuo. Nos testes deste TCS,
-- Shoot/Pass/Long também enviam os remotes TweenLimb e DropBall.
-- Aqui observamos SOMENTE esses dois remotes e, durante a janela curta
-- da ação, repetimos o mesmo touch do Olise na perna/braço em movimento.
-- A chamada original sempre segue intacta.

local ReachActionToken = 0
local ReachActionPart = nil
local ReachActionPartName = nil
local ReachActionWindow = 0.34
local ReachActionInterval = 0.025

local function GetCharacterPartByActionName(name)
    local char = LP.Character
    if not char or type(name) ~= "string" then return nil end

    local n = string.lower(name)
    local aliases = {
        ["right leg"]  = {"Right Leg", "RightFoot", "Right Foot"},
        ["left leg"]   = {"Left Leg", "LeftFoot", "Left Foot"},
        ["right arm"]  = {"Right Arm", "RightHand", "Right Hand"},
        ["left arm"]   = {"Left Arm", "LeftHand", "Left Hand"},
        ["right foot"] = {"Right Foot", "RightFoot", "Right Leg"},
        ["left foot"]  = {"Left Foot", "LeftFoot", "Left Leg"},
        ["head"]       = {"Head"},
        ["torso"]      = {"UpperTorso", "Torso", "HumanoidRootPart"},
    }

    local list = aliases[n]
    if not list then return nil end
    for _, partName in ipairs(list) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

local function GetNearestReachBallCached(hrp, radius)
    if not hrp then return nil end
    RefreshReachBalls(false)

    local best, bestSq = nil, math.huge
    local radiusSq = radius * radius

    for i = 1, #ReachBalls do
        local ball = ReachBalls[i]
        if ball and ball.Parent then
            local d = ball.Position - hrp.Position
            local dsq = d:Dot(d)
            if dsq <= radiusSq and dsq < bestSq then
                best = ball
                bestSq = dsq
            end
        end
    end

    return best
end

local function TouchActionBall(ball, preferredPart)
    if not ReachEnabled or not ball or not ball.Parent then return end

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local reach = GetReachStuds()
    local delta = ball.Position - hrp.Position
    if delta:Dot(delta) > (reach + 1.5) * (reach + 1.5) then
        return
    end

    local parts = {}
    local seen = {}

    local function addPart(part)
        if part and part.Parent and part:IsA("BasePart") and not seen[part] then
            seen[part] = true
            parts[#parts + 1] = part
        end
    end

    -- Prioridade para o membro que o jogo está animando.
    addPart(preferredPart)

    -- Fallback curto para garantir contato durante a animação.
    addPart(char:FindFirstChild("Right Leg"))
    addPart(char:FindFirstChild("Left Leg"))
    addPart(char:FindFirstChild("Right Foot") or char:FindFirstChild("RightFoot"))
    addPart(char:FindFirstChild("Left Foot") or char:FindFirstChild("LeftFoot"))

    for i = 1, #parts do
        local part = parts[i]
        local pdelta = ball.Position - part.Position
        if pdelta:Dot(pdelta) <= (reach + 1.0) * (reach + 1.0) then
            -- Mantém o comportamento do Olise e adiciona o sentido inverso
            -- apenas durante a ação, onde o TCS pode observar o contato da parte.
            pcall(function()
                firetouchinterest(ball, part, 0)
                firetouchinterest(ball, part, 1)
            end)
            pcall(function()
                firetouchinterest(part, ball, 0)
                firetouchinterest(part, ball, 1)
            end)
        end
    end
end

local function StartReachActionBridge(part)
    if not ReachEnabled then return end

    ReachActionToken += 1
    local token = ReachActionToken
    ReachActionPart = part

    task.spawn(function()
        local started = os.clock()
        while ReachEnabled and token == ReachActionToken and (os.clock() - started) <= ReachActionWindow do
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then break end

            local ball = GetNearestReachBallCached(hrp, GetReachStuds() + 1.5)
            if ball then
                TouchActionBall(ball, ReachActionPart)
            end

            task.wait(ReachActionInterval)
        end

        if token == ReachActionToken then
            ReachActionPart = nil
        end
    end)
end

local function InstallTCSActionBridge19()
    if _G.__EMAN_TCS_ACTION_BRIDGE_V19 then return end
    _G.__EMAN_TCS_ACTION_BRIDGE_V19 = true

    if type(hookmetamethod) ~= "function"
        or type(getnamecallmethod) ~= "function"
        or type(newcclosure) ~= "function" then
        return
    end

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()

        -- Nunca bloqueia ou altera a chamada original.
        if ReachEnabled and method == "FireServer" and typeof(self) == "Instance" then
            local remoteName = self.Name

            if remoteName == "TweenLimb" then
                local args = {...}
                local limbName = args[1]
                local part = GetCharacterPartByActionName(limbName)
                ReachActionPart = part
                ReachActionPartName = limbName
                StartReachActionBridge(part)

            elseif remoteName == "DropBall" then
                StartReachActionBridge(ReachActionPart)
            end
        end

        return oldNamecall(self, ...)
    end))
end

InstallTCSActionBridge19()

-- Fallback: se o executor não oferecer hookmetamethod, mantém o burst
-- de Tool, sem interceptar a ação normal.
local ReachToolConnections = {}
local function HookReachTool(tool)
    if not tool or not tool:IsA("Tool") or ReachToolConnections[tool] then return end

    local ok, conn = pcall(function()
        return tool.Activated:Connect(function()
            if type(hookmetamethod) == "function" then return end
            if not ReachEnabled then return end

            ReachActionToken += 1
            local token = ReachActionToken
            task.spawn(function()
                local started = os.clock()
                while ReachEnabled and token == ReachActionToken and (os.clock() - started) <= 0.24 do
                    DoOliseReach()
                    task.wait(0.025)
                end
            end)
        end)
    end)

    if ok and conn then
        ReachToolConnections[tool] = conn
    end
end

local function HookReachTools()
    local char = LP.Character
    if not char then return end

    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            HookReachTool(obj)
        end
    end

    for _, obj in ipairs(LP.Backpack:GetChildren()) do
        if obj:IsA("Tool") then
            HookReachTool(obj)
        end
    end
end

LP.CharacterAdded:Connect(function(char)
    task.defer(function()
        pcall(function() char:WaitForChild("HumanoidRootPart", 5) end)
        task.wait(0.15)
        RebuildReachBodyParts(char)
        HookReachTools()
        RefreshReachBalls(true)
    end)
end)

LP.Backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then
        task.defer(HookReachTool, child)
    end
end)

RebuildReachBodyParts(LP.Character)
HookReachTools()
RefreshReachBalls(true)

RunService.RenderStepped:Connect(function()
    pcall(DoOliseReach)
end)

local function DestroyReachVisualizer()
    if ReachVisualizerConn then
        ReachVisualizerConn:Disconnect()
        ReachVisualizerConn = nil
    end
    if ReachVisualizerBillboard then
        ReachVisualizerBillboard:Destroy()
        ReachVisualizerBillboard = nil
    end
    if ReachVisualizerBall then
        ReachVisualizerBall:Destroy()
        ReachVisualizerBall = nil
    end
    if ReachVisualizerRing then
        ReachVisualizerRing:Destroy()
        ReachVisualizerRing = nil
    end
end

local function CreateReachVisualizer()
    DestroyReachVisualizer()
    if not ReachVisualizerEnabled then return end

    ReachVisualizerBall = Instance.new("Part")
    ReachVisualizerBall.Name = "EmanReachVisualizer"
    ReachVisualizerBall.Shape = Enum.PartType.Ball
    ReachVisualizerBall.Anchored = true
    ReachVisualizerBall.CanCollide = false
    ReachVisualizerBall.CanTouch = false
    ReachVisualizerBall.CanQuery = false
    ReachVisualizerBall.CastShadow = false
    ReachVisualizerBall.Material = Enum.Material.ForceField
    ReachVisualizerBall.Color = Color3.fromRGB(0,180,255)
    ReachVisualizerBall.Transparency = 0.91
    ReachVisualizerBall.Parent = workspace

    ReachVisualizerRing = Instance.new("Part")
    ReachVisualizerRing.Name = "EmanReachVisualizerRing"
    ReachVisualizerRing.Shape = Enum.PartType.Cylinder
    ReachVisualizerRing.Anchored = true
    ReachVisualizerRing.CanCollide = false
    ReachVisualizerRing.CanTouch = false
    ReachVisualizerRing.CanQuery = false
    ReachVisualizerRing.CastShadow = false
    ReachVisualizerRing.Material = Enum.Material.ForceField
    ReachVisualizerRing.Color = Color3.fromRGB(0,180,255)
    ReachVisualizerRing.Transparency = 0.72
    ReachVisualizerRing.Parent = workspace

    ReachVisualizerBillboard = Instance.new("BillboardGui")
    ReachVisualizerBillboard.Name = "EmanReachVisualizerLabel"
    ReachVisualizerBillboard.AlwaysOnTop = true
    ReachVisualizerBillboard.Size = UDim2.fromOffset(230,42)
    ReachVisualizerBillboard.StudsOffset = Vector3.new(0,1.8,0)
    ReachVisualizerBillboard.Parent = ReachVisualizerBall

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(220,245,255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.Text = ""
    label.Parent = ReachVisualizerBillboard

    UpdateReachStatus()

    ReachVisualizerConn = RunService.Heartbeat:Connect(function()
        if not ReachVisualizerEnabled then return end
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        ReachVisualizerBall.Position = hrp.Position
        ReachVisualizerRing.Position = hrp.Position - Vector3.new(0, hrp.Size.Y * 0.45, 0)
        ReachVisualizerRing.Orientation = Vector3.new(0,0,90)
    end)
end

local function SetReach(value)
    ReachDistance = math.clamp(tonumber(value) or ReachDistance, 1, 10)
    UpdateReachStatus()
end

addSection(pageMenu,"Reach")
do
    addToggle(pageMenu,"🦵  Reach",false,function(v)
        ReachEnabled = v
        notify(
            v and string.format("✅ Reach ON • %.1f / 10 • %.1f studs",ReachDistance,GetReachStuds())
                or "🔴 Reach OFF",
            v and GREEN or Color3.fromRGB(200,200,200)
        )
    end)

    addSlider(pageMenu,"Alcance do Reach",1,10,3.5,1,function(v)
        SetReach(v)
    end)

    addToggle(pageMenu,"👁️  Reach Visualizer",false,function(v)
        ReachVisualizerEnabled = v
        if v then
            CreateReachVisualizer()
            notify(
                string.format("🔵 Visualizer ON • %.1f / 10 • %.1f studs",ReachDistance,GetReachStuds()),
                BLUE
            )
        else
            DestroyReachVisualizer()
            notify("🔴 Reach Visualizer OFF",Color3.fromRGB(200,200,200))
        end
    end)

    addInfoBox(
        pageMenu,
        "Reach TCS compatível",
        "Baseado no método antigo do TCS: toca a bola usando as partes do personagem e não intercepta Tools, botões ou RemoteEvents. O alcance do visualizer acompanha o regulador."
    )
end

addSection(pageMenu,"Auto Catch")
do
    local acSize=20; local acOn=false; local acLast=0; local acPart=nil
    local acVisual=nil; local acVisualOn=false; local acVisualConn=nil

    addToggle(pageMenu,"AC (Auto Catch)",false,function(v)
        acOn=v
        notify(v and "✅ Auto Catch ATIVADO!" or "🔴 Auto Catch desativado", v and GREEN or Color3.fromRGB(200,200,200))
        if v then
            if not acPart then
                acPart=Instance.new("Part",workspace)
                acPart.Anchored=true; acPart.CanCollide=false; acPart.Transparency=1
            end
            task.spawn(function()
                local catchRE=ReplicatedStorage:FindFirstChild("CatchBall")
                local soundRE=ReplicatedStorage:FindFirstChild("Client")
                while acOn do
                    local char=LP.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local hrp=char.HumanoidRootPart
                        acPart.Size=Vector3.new(acSize,acSize,acSize); acPart.CFrame=hrp.CFrame
                        for _,v2 in pairs(workspace:GetDescendants()) do
                            if v2:IsA("BasePart") and (v2.Name=="TPS" or v2.Name=="MPS") then
                                if (v2.Position-hrp.Position).Magnitude<=(acSize/2) and tick()-acLast>=2 then
                                    acLast=tick()
                                    if catchRE then catchRE:FireServer(v2) end
                                    if soundRE then soundRE:FireServer("BallSound",v2) end
                                end
                            end
                        end
                    end
                    RunService.RenderStepped:Wait()
                end
                if acPart then acPart:Destroy(); acPart=nil end
            end)
        else
            if acPart then acPart:Destroy(); acPart=nil end
        end
    end)

    addToggle(pageMenu,"📦  Mostrar AC",false,function(v)
        acVisualOn = v
        if v then
            if acVisual and acVisual.Parent then acVisual:Destroy() end
            acVisual = Instance.new("Part", workspace)
            acVisual.Size        = Vector3.new(acSize, acSize, acSize)
            acVisual.Anchored    = true
            acVisual.CanCollide  = false
            acVisual.CastShadow  = false
            acVisual.Transparency = 0.82
            acVisual.Color       = Color3.fromRGB(0, 170, 255)
            acVisual.Material    = Enum.Material.Neon

            acVisualConn = RunService.Heartbeat:Connect(function()
                if not acVisualOn then
                    acVisualConn:Disconnect(); acVisualConn=nil; return
                end
                local c   = LP.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                if hrp and acVisual and acVisual.Parent then
                    acVisual.CFrame = hrp.CFrame
                    acVisual.Size   = Vector3.new(acSize, acSize, acSize)
                end
            end)
            notify("📦 Mostrar AC ("..acSize.." studs)")
        else
            if acVisual and acVisual.Parent then acVisual:Destroy(); acVisual=nil end
            if acVisualConn then acVisualConn:Disconnect(); acVisualConn=nil end
            notify("🔴 Mostrar AC desativado", Color3.fromRGB(200,200,200))
        end
    end)

    addSlider(pageMenu,"Tamanho",0,100,20,1,function(v)
        acSize=v
        if acPart   then acPart.Size   = Vector3.new(v,v,v) end
        if acVisual and acVisual.Parent then acVisual.Size = Vector3.new(v,v,v) end
    end)
end


addSection(pageFechar,"Fechar")
addButton(pageFechar,"❌  Fechar Script",function()
    SG:Destroy()
    notifSG:Destroy()
end)

addSection(pageBoost,"⚡  Performance")


do
    local fpsOn        = false
    local origTrans    = {}
    local origMat      = {}
    local origShadows  = game.Lighting.GlobalShadows

    addToggle(pageBoost,"🚀  FPS Boost",false,function(v)
        fpsOn = v
        if v then

            for _, obj in ipairs(workspace:GetDescendants()) do
                pcall(function()
                    if obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SurfaceAppearance") then
                        origTrans[obj] = obj.Transparency
                        obj.Transparency = 1
                    elseif obj:IsA("BasePart") or obj:IsA("MeshPart") then
                        origMat[obj] = obj.Material
                        obj.Material  = Enum.Material.SmoothPlastic
                    elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke")
                    or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Trail") or obj:IsA("Beam") then
                        obj.Enabled = false
                    end
                end)
            end
            pcall(function() game.Lighting.GlobalShadows = false end)
            for _, c in pairs(game.Lighting:GetChildren()) do
                pcall(function()
                    if c:IsA("Atmosphere") or c:IsA("BlurEffect") or c:IsA("SunRaysEffect")
                    or c:IsA("ColorCorrectionEffect") or c:IsA("DepthOfFieldEffect") then
                        c.Enabled = false
                    end
                end)
            end
            notify("🚀 FPS Boost ATIVADO!",GREEN)
        else

            for obj, trans in pairs(origTrans) do
                pcall(function() if obj and obj.Parent then obj.Transparency = trans end end)
            end
            for obj, mat in pairs(origMat) do
                pcall(function() if obj and obj.Parent then obj.Material = mat end end)
            end
            for _, obj in ipairs(workspace:GetDescendants()) do
                pcall(function()
                    if obj:IsA("ParticleEmitter") or obj:IsA("Smoke")
                    or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Trail") or obj:IsA("Beam") then
                        obj.Enabled = true
                    end
                end)
            end
            pcall(function() game.Lighting.GlobalShadows = origShadows end)
            for _, c in pairs(game.Lighting:GetChildren()) do
                pcall(function()
                    if c:IsA("Atmosphere") or c:IsA("BlurEffect") or c:IsA("SunRaysEffect")
                    or c:IsA("ColorCorrectionEffect") or c:IsA("DepthOfFieldEffect") then
                        c.Enabled = true
                    end
                end)
            end
            origTrans = {}; origMat = {}
            notify("🔴 FPS Boost desativado",Color3.fromRGB(200,200,200))
        end
    end)
end


do
    local stretchOn   = false
    local stretchConn = nil
    local INTENSITY   = 0.75

    local function applyStretch()
        if stretchConn then stretchConn:Disconnect() end
        stretchConn = RunService.RenderStepped:Connect(function()
            if workspace.CurrentCamera then
                local cam = workspace.CurrentCamera
                cam.CFrame = cam.CFrame * CFrame.new(0,0,0, 1,0,0, 0,INTENSITY,0, 0,0,1)
            end
        end)
    end

    addToggle(pageBoost,"📺  Tela Esticada",false,function(v)
        stretchOn = v
        if v then
            applyStretch()
            notify("📺 Tela Esticada ATIVADA!",GREEN)
        else
            if stretchConn then stretchConn:Disconnect(); stretchConn = nil end
            notify("🔴 Tela Esticada desativada",Color3.fromRGB(200,200,200))
        end
    end)
end


do
    local antiOn      = false
    local aOrigTrans  = {}
    local aOrigShadow = game.Lighting.GlobalShadows

    addToggle(pageBoost,"🛡️  Anti-Lag",false,function(v)
        antiOn = v
        if v then

            for _, obj in ipairs(workspace:GetDescendants()) do
                pcall(function()
                    if obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SurfaceAppearance") then
                        aOrigTrans[obj] = obj.Transparency
                        obj.Transparency = 1
                    elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke")
                    or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Trail") or obj:IsA("Beam") then
                        obj.Enabled = false
                    end
                end)
            end
            pcall(function() game.Lighting.GlobalShadows = false end)
            for _, c in pairs(game.Lighting:GetChildren()) do
                pcall(function()
                    if c:IsA("BlurEffect") or c:IsA("DepthOfFieldEffect")
                    or c:IsA("SunRaysEffect") or c:IsA("Atmosphere") then
                        c.Enabled = false
                    end
                end)
            end
            notify("🛡️ Anti-Lag ATIVADO!",GREEN)
        else
            for obj, trans in pairs(aOrigTrans) do
                pcall(function() if obj and obj.Parent then obj.Transparency = trans end end)
            end
            for _, obj in ipairs(workspace:GetDescendants()) do
                pcall(function()
                    if obj:IsA("ParticleEmitter") or obj:IsA("Smoke")
                    or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Trail") or obj:IsA("Beam") then
                        obj.Enabled = true
                    end
                end)
            end
            pcall(function() game.Lighting.GlobalShadows = aOrigShadow end)
            for _, c in pairs(game.Lighting:GetChildren()) do
                pcall(function()
                    if c:IsA("BlurEffect") or c:IsA("DepthOfFieldEffect")
                    or c:IsA("SunRaysEffect") or c:IsA("Atmosphere") then
                        c.Enabled = true
                    end
                end)
            end
            aOrigTrans = {}
            notify("🔴 Anti-Lag desativado",Color3.fromRGB(200,200,200))
        end
    end)
end

-- Premium ambient animations
do
    local onlineScale=Instance.new("UIScale",OnlinePill)
    onlineScale.Scale=1
    local logoGlow=Instance.new("UIStroke",LogoWrap)
    logoGlow.Color=BLUED
    logoGlow.Thickness=1
    logoGlow.Transparency=0.2

    task.spawn(function()
        local phase=0
        while SG.Parent do
            phase=phase+1
            if phase%2==0 then
                TW:Create(onlineScale,TweenInfo.new(0.65,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Scale=1.025}):Play()
                TW:Create(OnlineDot,TweenInfo.new(0.65,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0.2}):Play()
                TW:Create(logoGlow,TweenInfo.new(0.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Transparency=0.05,Thickness=1.6}):Play()
            else
                TW:Create(onlineScale,TweenInfo.new(0.65,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Scale=1}):Play()
                TW:Create(OnlineDot,TweenInfo.new(0.65,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=0}):Play()
                TW:Create(logoGlow,TweenInfo.new(0.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Transparency=0.2,Thickness=1}):Play()
            end
            task.wait(0.65)
        end
    end)

    ProfileCard.MouseEnter:Connect(function()
        TW:Create(ProfileCard,TweenInfo.new(0.16,Enum.EasingStyle.Quint),{BackgroundColor3=Color3.fromRGB(24,27,39)}):Play()
        TW:Create(avatarStroke,TweenInfo.new(0.16),{Thickness=1.8}):Play()
    end)
    ProfileCard.MouseLeave:Connect(function()
        TW:Create(ProfileCard,TweenInfo.new(0.16,Enum.EasingStyle.Quint),{BackgroundColor3=Color3.fromRGB(18,20,30)}):Play()
        TW:Create(avatarStroke,TweenInfo.new(0.16),{Thickness=1.2}):Play()
    end)
end

do
    local td = tabsData[1]
    if td then
        td.page.Visible = true
        td.ind.Visible = true
        td.btn.BackgroundColor3 = Color3.fromRGB(20,30,52)
        td.nl.TextColor3 = WHITE
        td.il.TextColor3 = BLUEL
        td.page.Position = UDim2.new(0,0,0,0)
    end
end

buttonScale(MinBtn)
buttonScale(CloseBtn)
MinBtn.MouseEnter:Connect(function()
    TW:Create(MinBtn,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(61,63,75),TextColor3=WHITE}):Play()
end)
MinBtn.MouseLeave:Connect(function()
    TW:Create(MinBtn,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(49,51,62),TextColor3=Color3.fromRGB(192,194,202)}):Play()
end)
CloseBtn.MouseEnter:Connect(function()
    TW:Create(CloseBtn,TweenInfo.new(0.12),{BackgroundColor3=RED,TextColor3=WHITE}):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TW:Create(CloseBtn,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(67,26,36),TextColor3=Color3.fromRGB(235,112,130)}):Play()
end)
MinBtn.MouseButton1Click:Connect(function()
    toggleHubVisibility()
end)
CloseBtn.MouseButton1Click:Connect(function()
    SG:Destroy()
    notifSG:Destroy()
end)

Main.Visible=false
Shadow.Visible=false

local boot = Instance.new("Frame",SG)
boot.Size = UDim2.fromOffset(390,220)
boot.Position = UDim2.new(0.5,-195,0.5,-110)
boot.BackgroundColor3 = Color3.fromRGB(8,11,20)
boot.BackgroundTransparency = 0.02
boot.BorderSizePixel = 0
boot.ZIndex = 5000
corner(18,boot)
stroke(BLUE,1.4,boot)

local bootScale = Instance.new("UIScale",boot)
bootScale.Scale = 0.88
TW:Create(bootScale,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()

local bootLogo = Instance.new("ImageLabel",boot)
bootLogo.Size = UDim2.fromOffset(58,58)
bootLogo.Position = UDim2.new(0.5,-29,0,25)
bootLogo.BackgroundTransparency = 1
bootLogo.Image = "rbxassetid://110219163753015"
bootLogo.ZIndex = 5001

local bootTitle = Instance.new("TextLabel",boot)
bootTitle.Size = UDim2.new(1,-20,0,26)
bootTitle.Position = UDim2.new(0,10,0,92)
bootTitle.BackgroundTransparency = 1
bootTitle.Text = "EMAN HUB"
bootTitle.TextColor3 = WHITE
bootTitle.Font = Enum.Font.GothamBold
bootTitle.TextSize = 20
bootTitle.ZIndex = 5001

local bootStatus = Instance.new("TextLabel",boot)
bootStatus.Size = UDim2.new(1,-40,0,18)
bootStatus.Position = UDim2.new(0,20,0,119)
bootStatus.BackgroundTransparency = 1
bootStatus.Text = "Preparando interface..."
bootStatus.TextColor3 = TEXTD
bootStatus.Font = Enum.Font.Gotham
bootStatus.TextSize = 9
bootStatus.ZIndex = 5001

local loadBg = Instance.new("Frame",boot)
loadBg.Size = UDim2.new(1,-56,0,8)
loadBg.Position = UDim2.new(0,28,0,154)
loadBg.BackgroundColor3 = Color3.fromRGB(24,30,45)
loadBg.BorderSizePixel = 0
loadBg.ZIndex = 5001
corner(4,loadBg)

local loadBar = Instance.new("Frame",loadBg)
loadBar.Size = UDim2.new(0,0,1,0)
loadBar.BackgroundColor3 = BLUE
loadBar.BorderSizePixel = 0
loadBar.ZIndex = 5002
corner(4,loadBar)

local loadPct = Instance.new("TextLabel",boot)
loadPct.Size = UDim2.new(1,-56,0,16)
loadPct.Position = UDim2.new(0,28,0,169)
loadPct.BackgroundTransparency = 1
loadPct.Text = "0%"
loadPct.TextColor3 = BLUEL
loadPct.Font = Enum.Font.GothamBold
loadPct.TextSize = 8
loadPct.TextXAlignment = Enum.TextXAlignment.Right
loadPct.ZIndex = 5001

task.spawn(function()
    local stages = {
        {0.22,"Carregando interface..."},
        {0.45,"Preparando navegação..."},
        {0.68,"Sincronizando jogador..."},
        {0.84,"Ativando animações..."},
        {1.00,"EMAN HUB pronto!"},
    }
    for _,s in ipairs(stages) do
        bootStatus.Text = s[2]
        loadPct.Text = tostring(math.floor(s[1]*100)).."%"
        TW:Create(loadBar,TweenInfo.new(0.28,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(s[1],0,1,0)}):Play()
        TW:Create(bootLogo,TweenInfo.new(0.18,Enum.EasingStyle.Sine),{Rotation=2}):Play()
        task.wait(0.28)
        TW:Create(bootLogo,TweenInfo.new(0.18,Enum.EasingStyle.Sine),{Rotation=-2}):Play()
    end
    task.wait(0.22)
    TW:Create(bootScale,TweenInfo.new(0.22,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Scale=0.94}):Play()
    TW:Create(boot,TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play()
    task.wait(0.25)
    if boot.Parent then boot:Destroy() end
    animateHub(true)
    task.wait(0.35)
    notify("✨ EMAN HUB carregado",BLUE)
end)
