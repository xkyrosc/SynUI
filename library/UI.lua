-- Convert your library.lua to a single loadstring
-- This is what you'll upload to GitHub

local libraryLoadstring = [[
-- library.lua (Minified/Combined for loadstring)
local Library = {}
Library.__index = Library

function Library.new(config)
	config = config or {}
	local self = setmetatable({}, Library)
	
	-- Configuration
	self.Title = config.Title or "Library"
	self.TypingAnimation = config.TypingAnimation ~= false
	self.TypingSpeed = config.TypingSpeed or 0.08
	self.BackspaceSpeed = config.BackspaceSpeed or 0.04
	self.PauseAfterTyping = config.PauseAfterTyping or 2
	self.PauseAfterBackspace = config.PauseAfterBackspace or 0.5
	self.HeaderColor = config.HeaderColor or Color3.fromRGB(88, 101, 242)
	self.BackgroundColor = config.BackgroundColor or Color3.fromRGB(30, 30, 40)
	self.AccentColor = config.AccentColor or Color3.fromRGB(0, 200, 255)
	self.Parent = config.Parent or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	self.ToggleEnabled = config.ToggleEnabled ~= false
	
	-- State
	self.Tabs = {}
	self.GuiVisible = true
	self.SelectedTab = nil
	
	-- Services
	local TweenService = game:GetService("TweenService")
	self.TweenService = TweenService
	
	-- Build UI
	self:_buildMainGui()
	self:_buildHeader()
	self:_buildTabSystem()
	
	if self.ToggleEnabled then
		self:_buildToggle()
	end
	
	return self
end

function Library:_buildMainGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = self.Title .. "_Library"
	gui.ResetOnSpawn = false
	gui.Parent = self.Parent
	self.Gui = gui
	
	for _, child in ipairs(self.Parent:GetChildren()) do
		if child.Name == self.Title .. "_Library" and child ~= gui then
			child:Destroy()
		end
	end
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0.35, 0, 0.6, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = self.BackgroundColor
	mainFrame.BackgroundTransparency = 0.2
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui
	self.MainFrame = mainFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.05, 0)
	corner.Parent = mainFrame
end

function Library:_buildHeader()
	local headerBar = Instance.new("Frame")
	headerBar.Size = UDim2.new(1, 0, 0.1, 0)
	headerBar.Position = UDim2.new(0, 0, 0, 0)
	headerBar.BackgroundColor3 = self.HeaderColor
	headerBar.BorderSizePixel = 0
	headerBar.Parent = self.MainFrame
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0.05, 0)
	headerCorner.Parent = headerBar
	
	local headerText = Instance.new("TextLabel")
	headerText.Size = UDim2.new(1, -20, 1, 0)
	headerText.Position = UDim2.new(0, 10, 0, 0)
	headerText.BackgroundTransparency = 1
	headerText.Text = ""
	headerText.Font = Enum.Font.SciFi
	headerText.TextColor3 = Color3.fromRGB(255, 255, 255)
	headerText.TextSize = 16
	headerText.TextXAlignment = Enum.TextXAlignment.Center
	headerText.Parent = headerBar
	self.HeaderText = headerText
	
	if self.TypingAnimation then
		self:_startTypingAnimation()
	else
		headerText.Text = self.Title
	end
end

function Library:_startTypingAnimation()
	local fullText = self.Title
	
	task.spawn(function()
		while true do
			for i = 1, #fullText do
				self.HeaderText.Text = string.sub(fullText, 1, i)
				task.wait(self.TypingSpeed)
			end
			task.wait(self.PauseAfterTyping)
			for i = #fullText, 0, -1 do
				self.HeaderText.Text = string.sub(fullText, 1, i)
				task.wait(self.BackspaceSpeed)
			end
			task.wait(self.PauseAfterBackspace)
		end
	end)
end

function Library:_buildTabSystem()
	self.TabButtons = {}
	self.TabFrames = {}
	self.TabContainer = Instance.new("Frame")
	self.TabContainer.Size = UDim2.new(1, 0, 0.1, 0)
	self.TabContainer.Position = UDim2.new(0, 0, 0.1, 0)
	self.TabContainer.BackgroundTransparency = 1
	self.TabContainer.Parent = self.MainFrame
end

function Library:CreateTab(name)
	local tabIndex = #self.Tabs + 1
	local tabCount = tabIndex
	
	local tabButton = Instance.new("TextButton")
	tabButton.Name = name .. "Tab"
	tabButton.Size = UDim2.new(1/tabCount, 0, 1, 0)
	tabButton.Position = UDim2.new((tabIndex-1)/tabCount, 0, 0, 0)
	tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	tabButton.Text = name
	tabButton.Font = Enum.Font.SciFi
	tabButton.TextColor3 = Color3.fromRGB(200, 200, 255)
	tabButton.TextSize = 14
	tabButton.ZIndex = 2
	tabButton.Parent = self.TabContainer
	
	local tabFrame = Instance.new("Frame")
	tabFrame.Name = name .. "Frame"
	tabFrame.Size = UDim2.new(1, 0, 0.8, 0)
	tabFrame.Position = UDim2.new(0, 0, 0.2, 0)
	tabFrame.BackgroundTransparency = 1
	tabFrame.Visible = false
	tabFrame.Parent = self.MainFrame
	
	for _, btn in pairs(self.TabButtons) do
		local newTabCount = #self.Tabs + 1
		btn.Size = UDim2.new(1/newTabCount, 0, 1, 0)
		local idx = table.find(self.TabButtons, btn)
		if idx then
			btn.Position = UDim2.new((idx-1)/newTabCount, 0, 0, 0)
		end
	end
	
	local tab = {
		Name = name,
		Button = tabButton,
		Frame = tabFrame,
		Library = self
	}
	
	table.insert(self.Tabs, tab)
	table.insert(self.TabButtons, tabButton)
	self.TabFrames[name] = tabFrame
	
	tabButton.MouseButton1Click:Connect(function()
		self:SelectTab(name)
	end)
	
	if #self.Tabs == 1 then
		self:SelectTab(name)
	end
	
	return tab
end

function Library:SelectTab(name)
	for _, tab in ipairs(self.Tabs) do
		tab.Frame.Visible = false
		tab.Button.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	end
	
	local selected = self.TabFrames[name]
	if selected then
		selected.Visible = true
		self.SelectedTab = name
		
		for _, tab in ipairs(self.Tabs) do
			if tab.Name == name then
				tab.Button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
				break
			end
		end
	end
end

function Library:_buildToggle()
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 50, 0, 50)
	toggleButton.Position = UDim2.new(0, 20, 0.5, -25)
	toggleButton.AnchorPoint = Vector2.new(0, 0.5)
	toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	toggleButton.TextColor3 = Color3.fromRGB(200, 200, 255)
	toggleButton.Text = "☰"
	toggleButton.Font = Enum.Font.SciFi
	toggleButton.TextSize = 24
	toggleButton.ZIndex = 10
	toggleButton.Parent = self.Gui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = toggleButton
	
	toggleButton.MouseButton1Click:Connect(function()
		if self.GuiVisible then
			local tween = self.TweenService:Create(self.MainFrame, TweenInfo.new(0.5), {
				Position = UDim2.new(1.5, 0, 0.5, 0)
			})
			tween:Play()
			toggleButton.Text = "≡"
		else
			self.MainFrame.Visible = true
			local tween = self.TweenService:Create(self.MainFrame, TweenInfo.new(0.5), {
				Position = UDim2.new(0.5, 0, 0.5, 0)
			})
			tween:Play()
			toggleButton.Text = "☰"
		end
		self.GuiVisible = not self.GuiVisible
	end)
end

function Library:Destroy()
	if self.Gui then
		self.Gui:Destroy()
	end
end

function Library:AddLabel(tab, text, options)
	options = options or {}
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(options.Width or 1, options.WidthOffset or 0, 0, options.Height or 20)
	label.Position = UDim2.new(options.X or 0, options.XOffset or 0, options.Y or 0, options.YOffset or 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = options.Font or Enum.Font.SciFi
	label.TextColor3 = options.TextColor or Color3.fromRGB(200, 200, 255)
	label.TextSize = options.TextSize or 14
	label.TextXAlignment = options.AlignX or Enum.TextXAlignment.Left
	label.TextWrapped = options.TextWrapped or false
	label.Parent = tab.Frame
	
	return label
end

function Library:AddButton(tab, text, callback, options)
	options = options or {}
	
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(options.Width or 0.6, options.WidthOffset or 0, 0, options.Height or 30)
	button.Position = UDim2.new(options.X or 0.2, options.XOffset or 0, options.Y or 0, options.YOffset or 0)
	button.BackgroundColor3 = options.ButtonColor or Color3.fromRGB(0, 100, 150)
	button.Text = text
	button.Font = options.Font or Enum.Font.SciFi
	button.TextColor3 = options.TextColor or Color3.fromRGB(200, 255, 255)
	button.TextSize = options.TextSize or 14
	button.Parent = tab.Frame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = button
	
	if callback then
		button.MouseButton1Click:Connect(callback)
	end
	
	return button
end

function Library:AddTextBox(tab, placeholder, options)
	options = options or {}
	
	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(options.Width or 0.8, options.WidthOffset or 0, 0, options.Height or 25)
	textBox.Position = UDim2.new(options.X or 0.1, options.XOffset or 0, options.Y or 0, options.YOffset or 0)
	textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	textBox.BorderSizePixel = 0
	textBox.Text = options.DefaultText or ""
	textBox.PlaceholderText = placeholder or ""
	textBox.TextColor3 = Color3.fromRGB(200, 200, 255)
	textBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 150)
	textBox.Font = options.Font or Enum.Font.SciFi
	textBox.TextSize = options.TextSize or 11
	textBox.ClearTextOnFocus = options.ClearOnFocus or false
	textBox.Parent = tab.Frame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.2, 0)
	corner.Parent = textBox
	
	return textBox
end

function Library:AddScrollingFrame(tab, options)
	options = options or {}
	
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(options.Width or 0.85, options.WidthOffset or 0, options.Height or 0.5, options.HeightOffset or 0)
	scrollFrame.Position = UDim2.new(options.X or 0.075, options.XOffset or 0, options.Y or 0, options.YOffset or 0)
	scrollFrame.BackgroundTransparency = options.Transparent and 1 or 0
	scrollFrame.BackgroundColor3 = options.BackgroundColor or Color3.fromRGB(40, 40, 60)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = options.ScrollBarThickness or 4
	scrollFrame.ScrollBarImageColor3 = options.ScrollBarColor or Color3.fromRGB(100, 100, 150)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = tab.Frame
	
	local layout = Instance.new("UIListLayout")
	layout.Parent = scrollFrame
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, options.Padding or 3)
	
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
	end)
	
	scrollFrame.Layout = layout
	return scrollFrame
end

function Library:AddToggle(tab, text, callback, options)
	options = options or {}
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(options.Width or 1, options.WidthOffset or 0, 0, options.Height or 30)
	frame.Position = UDim2.new(options.X or 0, options.XOffset or 0, options.Y or 0, options.YOffset or 0)
	frame.BackgroundTransparency = 1
	frame.Parent = tab.Frame
	
	local toggleButton = Instance.new("TextButton")
	toggleButton.Size = UDim2.new(0, 30, 0, 30)
	toggleButton.Position = UDim2.new(0, 0, 0.5, -15)
	toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	toggleButton.Text = ""
	toggleButton.Parent = frame
	
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0.2, 0)
	toggleCorner.Parent = toggleButton
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -40, 1, 0)
	label.Position = UDim2.new(0, 40, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = options.Font or Enum.Font.SciFi
	label.TextColor3 = options.TextColor or Color3.fromRGB(200, 200, 255)
	label.TextSize = options.TextSize or 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame
	
	local toggled = false
	
	toggleButton.MouseButton1Click:Connect(function()
		toggled = not toggled
		toggleButton.BackgroundColor3 = toggled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 80)
		if callback then
			callback(toggled)
		end
	end)
	
	return toggleButton
end

function Library:AddDropdown(tab, items, callback, options)
	options = options or {}
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(options.Width or 0.8, options.WidthOffset or 0, 0, options.Height or 30)
	frame.Position = UDim2.new(options.X or 0.1, options.XOffset or 0, options.Y or 0, options.YOffset or 0)
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = false
	frame.Parent = tab.Frame
	
	local dropButton = Instance.new("TextButton")
	dropButton.Size = UDim2.new(1, 0, 1, 0)
	dropButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	dropButton.Text = options.DefaultText or "Select..."
	dropButton.Font = Enum.Font.SciFi
	dropButton.TextColor3 = Color3.fromRGB(200, 200, 255)
	dropButton.TextSize = 12
	dropButton.Parent = frame
	
	local dropCorner = Instance.new("UICorner")
	dropCorner.CornerRadius = UDim.new(0.2, 0)
	dropCorner.Parent = dropButton
	
	local listFrame = Instance.new("Frame")
	listFrame.Size = UDim2.new(1, 0, 0, #items * 25)
	listFrame.Position = UDim2.new(0, 0, 1, 5)
	listFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	listFrame.BorderSizePixel = 0
	listFrame.Visible = false
	listFrame.Parent = frame
	
	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0.1, 0)
	listCorner.Parent = listFrame
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Parent = listFrame
	
	local opened = false
	
	dropButton.MouseButton1Click:Connect(function()
		opened = not opened
		listFrame.Visible = opened
	end)
	
	for i, item in ipairs(items) do
		local itemButton = Instance.new("TextButton")
		itemButton.Size = UDim2.new(1, 0, 0, 25)
		itemButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		itemButton.Text = item
		itemButton.Font = Enum.Font.SciFi
		itemButton.TextColor3 = Color3.fromRGB(200, 200, 255)
		itemButton.TextSize = 11
		itemButton.Parent = listFrame
		
		itemButton.MouseButton1Click:Connect(function()
			dropButton.Text = item
			listFrame.Visible = false
			opened = false
			if callback then
				callback(item)
			end
		end)
	end
	
	return dropButton
end

return Library
]]

-- Return a function that executes the loadstring
return function()
	local success, result = pcall(function()
		return loadstring(libraryLoadstring)()
	end)
	
	if success then
		return result
	else
		warn("Failed to load library: " .. tostring(result))
		return nil
	end
end
