local MODULES = {}
local MODULE_CACHE = {}

local function require(target: any): any
	if MODULE_CACHE[target] then
		return MODULE_CACHE[target]
	elseif MODULES[target] then
		local module = MODULES[target]()
		MODULE_CACHE[target] = module
		return module
	else
		local success, module = pcall(require, target)
		assert(success, ("Invalid module '%s'"):format(target))
		return module
	end
end

MODULES["Universe"] = function()
	local Universe = {}

	Universe.Seed = Random.new():NextNumber(-10000, 10000)
	Universe.Size = 200
	Universe.SystemSize = 20

	return Universe
end

---------------------------------------------------------------------------------
local Universe = require("Universe")

local MapToMove: GuiObject

local Screen = GetPart("Screen") or GetPart("TouchScreen")
local Keyboard = GetPart("Keyboard")

local function Chance2(seed: number, x: number, y: number): number
	return Random.new(seed + x + y):NextNumber(0, 100)
end

local function NumberInRange(number: number, min: number, max: number): boolean
	return number >= min and number <= max
end

local Seed = Universe.Seed

local SavedStars = {}

local Chance = 7
local Stars = 0

local Background = Screen:CreateElement("ImageLabel", {
	Size = UDim2.fromScale(1, 1),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	TileSize = UDim2.fromOffset(120, 120),
	ScaleType = Enum.ScaleType.Stretch,
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 1,
	Image = "rbxassetid://3899340539",
	ZIndex = -9999,
})

local Generating = Screen:CreateElement("TextLabel", {
	Size = UDim2.fromScale(1, 1),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 0.5,
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = true,
	Text = "Generating universe...",
	ZIndex = 9999,
})

local TotalStars = Screen:CreateElement("TextLabel", {
	Parent = Generating,
	Size = UDim2.fromScale(1, 0.2),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.9),
	BackgroundTransparency = 0.5,
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = true,
	Text = 0,
	ZIndex = 9999,
})

local Credits = Screen:CreateElement("TextLabel", {
	Parent = Generating,
	Size = UDim2.fromScale(1, 0.3),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.15),
	BackgroundTransparency = 0.5,
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = true,
	Text = "Universe Generator - proudly made by Astroxd8",
	ZIndex = 9999,
})

local GenRuns = 0
for x = -Universe.Size / 2, Universe.Size / 2 do
	if GenRuns >= 40 then
		task.wait()
		GenRuns = 0
	end
	for y = -Universe.Size / 2, Universe.Size / 2 do
		if GenRuns >= 40 then
			task.wait()
			GenRuns = 0
		end
		local ProcessedSeed = math.noise(x / Seed, y / Seed) * Seed * Seed
		local Generator = Random.new(ProcessedSeed)

		if x == 0 and y == 0 then
			Stars += 1
			TotalStars.Text = Stars
			table.insert(SavedStars,
				{
					Coordinate = {x, y},
					Type = "BlackHole",
				}
			)
			continue
		end

		if Chance2(ProcessedSeed, x, y) <= Chance / 100 then
			Stars += 1
			TotalStars.Text = Stars
			table.insert(SavedStars,
				{
					Coordinate = {x, y},
					Type = "BlackHole",
				}
			)
		elseif Chance2(ProcessedSeed, x, y) <= Chance then
			Stars += 1
			TotalStars.Text = Stars

			local StarType: string
			local Temperature: number
			local Bodies: table = {}

			if Chance2(ProcessedSeed, x, y) <= Chance / 2 then
				Temperature = Generator:NextInteger(2300, 6000)
			else
				Temperature = Generator:NextInteger(6001, 38000)
			end

			if Temperature < 3900 then
				StarType = "M"
			elseif Temperature < 5300 then
				StarType = "K"
			elseif Temperature < 6000 then
				StarType = "G"
			elseif Temperature < 7300 then
				StarType = "F"
			elseif Temperature < 10000 then
				StarType = "A"
			elseif Temperature < 33000 then
				StarType = "B"
			elseif Temperature >= 33000 then
				StarType = "O"
			end

			for px = -Universe.SystemSize / 2, Universe.SystemSize / 2 do
				for py = -Universe.SystemSize / 2, Universe.SystemSize / 2 do
					if px == 0 and py == 0 then continue end

					local ProcessedSeed2 = math.noise((x + px) / Seed, (y + py) / Seed) * Seed * Seed

					local Moons: table = {}

					if Chance2(ProcessedSeed2, x + px, y + py) <= 1 then
						for mx = -Universe.SystemSize / 2, Universe.SystemSize / 2 do
							for my = -Universe.SystemSize / 2, Universe.SystemSize / 2 do
								if mx == 0 and my == 0 then continue end
								local ProcessedSeed3 = math.noise((x + px + mx) / Seed, (y + py + my) / Seed) * Seed * Seed
								if Chance2(ProcessedSeed3, x + px + mx, y + py + my) <= 0.5 then
									table.insert(Moons, {
										Coordinate = {mx, my},
										Type = "Planet",
										Data = {
											GroundColor3 = Color3.fromRGB(Generator:NextInteger(0, 255), Generator:NextInteger(0, 255), Generator:NextInteger(0, 255)),
											AtmosphereColor3 = Color3.fromRGB(Generator:NextInteger(0, 255), Generator:NextInteger(0, 255), Generator:NextInteger(0, 255)),
										}
									})
								end
							end
						end

						table.insert(Bodies, {
							Coordinate = {px, py},
							Type = "Planet",
							Data = {
								GroundColor3 = Color3.fromRGB(Generator:NextInteger(0, 255), Generator:NextInteger(0, 255), Generator:NextInteger(0, 255)),
								AtmosphereColor3 = Color3.fromRGB(Generator:NextInteger(0, 255), Generator:NextInteger(0, 255), Generator:NextInteger(0, 255)),
								Moons = Moons,
							},
						})
					end
				end
			end
			
			table.insert(SavedStars,
				{
					Coordinate = {x, y},
					Type = "Star",
					Data = {
						Type = StarType,
						Temperature = Temperature,
						Bodies = Bodies,
					}
				}
			)
		end
		GenRuns += 1
	end
	GenRuns += 1
end

local StarSize = 6

local StarMap = Screen:CreateElement("Frame", {
	Size = UDim2.fromOffset(Universe.Size * StarSize, Universe.Size * StarSize),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1,
})

local UniverseButton = Screen:CreateElement("TextButton", {
	Size = UDim2.fromScale(0.3, 0.1),
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.fromScale(1, 0.9),
	BackgroundColor3 = Color3.fromRGB(255, 128, 0),
	Font = Enum.Font.SciFi,
	TextColor3 = Color3.fromRGB(0, 0, 0),
	TextScaled = true,
	Text = "Universe",
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 1,
	Visible = false,
})

local HelpButton = Screen:CreateElement("TextButton", {
	Size = UDim2.fromScale(0.3, 0.1),
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	Font = Enum.Font.SciFi,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = true,
	Text = "Help",
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 1,
	Visible = false,
})

local SearchButton = Screen:CreateElement("TextButton", {
	Size = UDim2.fromScale(0.3, 0.1),
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	Font = Enum.Font.SciFi,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextScaled = true,
	Text = "Search",
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 1,
	Visible = false,
})

task.wait(1)

local Runs = 0
for key, star in pairs(SavedStars) do
	if Runs >= Universe.Size / 20 then
		task.wait()
		Runs = 0
	end

	local function GetStarTypeForColor3(type: string): Color3
		if type == "M" then
			return Color3.fromRGB(255, 0, 0)
		elseif type == "K" then
			return Color3.fromRGB(255, 128, 0)
		elseif type == "G" then
			return Color3.fromRGB(255, 255, 128)
		elseif type == "F" then
			return Color3.fromRGB(255, 255, 255)
		elseif type == "A" then
			return Color3.fromRGB(63, 63, 255)
		elseif type == "B" then
			return Color3.fromRGB(0, 63, 255)
		elseif type == "O" then
			return Color3.fromRGB(0, 0, 255)
		end
	end

	local Star = Screen:CreateElement("TextButton", {
		Parent = StarMap,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(StarSize, StarSize),
		Position = UDim2.fromScale(0.5 + (star.Coordinate[1] / Universe.Size), 0.5 + -(star.Coordinate[2] / Universe.Size)),
		Text = "",
		Visible = false,
	})

	if star.Type == "Star" then
		Star.BackgroundColor3 = GetStarTypeForColor3(star.Data.Type)
	elseif star.Type == "BlackHole" then
		Star.BorderSizePixel = 1
		Star.BorderColor3 = Color3.fromRGB(255, 165, 0)
		Star.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		Star.ZIndex += 1
	end

	Star.MouseButton1Click:Connect(function()
		local InfoMain = Screen:CreateElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
		})

		local StarPreview = Screen:CreateElement("Frame", {
			Parent = InfoMain,
			Size = UDim2.fromScale(0.5, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.25, 0.5),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 1,
		})

		if star.Type == "Star" then
			Screen:CreateElement("Frame", {
				Parent = StarPreview,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(160, 160),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = GetStarTypeForColor3(star.Data.Type)
			})
		elseif star.Type == "BlackHole" then
			Screen:CreateElement("Frame", {
				Parent = StarPreview,
				BorderSizePixel = 35,
				BorderColor3 = Color3.fromRGB(255, 165, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(160, 160),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			})
		end

		local StarInfo = Screen:CreateElement("Frame", {
			Parent = InfoMain,
			Size = UDim2.fromScale(0.5, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.75, 0.5),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 1,
		})

		if star.Type == "Star" then
			local CoordX = Screen:CreateElement("TextLabel", {
				Parent = StarInfo,
				Size = UDim2.fromScale(0.5, 0.1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.25, 0.05),
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				Text = star.Coordinate[1],
				BorderColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 1,
			})
			local CoordY = Screen:CreateElement("TextLabel", {
				Parent = StarInfo,
				Size = UDim2.fromScale(0.5, 0.1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.75, 0.05),
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				Text = star.Coordinate[2],
				BorderColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 1,
			})
			local Type = Screen:CreateElement("TextLabel", {
				Parent = StarInfo,
				Size = UDim2.fromScale(1, 0.1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.15),
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				Text = "Star Type: " .. star.Data.Type,
				BorderColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 1,
			})

			local ViewPlanetsButton = Screen:CreateElement("TextButton", {
				Parent = StarInfo,
				Size = UDim2.fromScale(1, 0.2),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.9),
				BackgroundColor3 = Color3.fromRGB(255, 128, 0),
				Font = Enum.Font.SciFi,
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextScaled = true,
				Text = "Planets",
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 1,
			})

			ViewPlanetsButton.MouseButton1Click:Connect(function()
				local GeneratingFrame = Screen:CreateElement("Frame", {
					Size = UDim2.fromScale(1, 1),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					BackgroundTransparency = 0.5,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					ZIndex = 9999,
				})

				InfoMain.Visible = false
				UniverseButton.Visible = false
				SearchButton.Visible = false

				local PlanetMap = Screen:CreateElement("Frame", {
					Size = UDim2.fromOffset(Universe.SystemSize * (StarSize * 4), Universe.SystemSize * (StarSize * 4)),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					BackgroundTransparency = 1,
				})
				MapToMove = PlanetMap

				local SystemStar = Star:Clone()
				SystemStar.Parent = PlanetMap
				SystemStar.Size = UDim2.fromOffset(StarSize * 4, StarSize * 4)
				SystemStar.Position = UDim2.fromScale(0.5, 0.5)
				SystemStar.Visible = true

				for key, planet in pairs(star.Data.Bodies) do
					local Planet = Screen:CreateElement("TextButton", {
						Parent = PlanetMap,
						BackgroundColor3 = planet.Data.GroundColor3,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.fromOffset(StarSize * 4, StarSize * 4),
						Position = UDim2.fromScale(0.5 + (planet.Coordinate[1] / Universe.SystemSize), 0.5 + -(planet.Coordinate[2] / Universe.SystemSize)),
						BorderColor3 = planet.Data.AtmosphereColor3,
						BorderSizePixel = 2,
						Text = '',
					})

					Planet.MouseButton1Click:Connect(function()
						PlanetMap.Visible = false

						local PlanetInfoMain = Screen:CreateElement("Frame", {
							Size = UDim2.fromScale(1, 1),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							BackgroundTransparency = 1,
						})
				
						local PlanetPreview = Screen:CreateElement("Frame", {
							Parent = PlanetInfoMain,
							Size = UDim2.fromScale(0.5, 1),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.25, 0.5),
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							BorderColor3 = Color3.fromRGB(255, 255, 255),
							BorderSizePixel = 1,
						})
				
						Screen:CreateElement("Frame", {
							Parent = PlanetPreview,
							BorderSizePixel = 15,
							AnchorPoint = Vector2.new(0.5, 0.5),
							Size = UDim2.fromOffset(160, 160),
							Position = UDim2.fromScale(0.5, 0.5),
							BackgroundColor3 = planet.Data.GroundColor3,
							BorderColor3 = planet.Data.AtmosphereColor3,
						})
				
						local PlanetInfo = Screen:CreateElement("Frame", {
							Parent = PlanetInfoMain,
							Size = UDim2.fromScale(0.5, 1),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.75, 0.5),
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							BorderColor3 = Color3.fromRGB(255, 255, 255),
							BorderSizePixel = 1,
						})
						local CoordSX = Screen:CreateElement("TextLabel", {
							Parent = PlanetInfo,
							Size = UDim2.fromScale(0.5, 0.1),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.25, 0.05),
							BackgroundTransparency = 0,
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							Font = Enum.Font.Gotham,
							TextColor3 = Color3.fromRGB(0, 255, 0),
							TextScaled = true,
							Text = star.Coordinate[1],
							BorderColor3 = Color3.fromRGB(255, 255, 255),
							BorderSizePixel = 1,
						})
						local CoordSY = Screen:CreateElement("TextLabel", {
							Parent = PlanetInfo,
							Size = UDim2.fromScale(0.5, 0.1),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.75, 0.05),
							BackgroundTransparency = 0,
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							Font = Enum.Font.Gotham,
							TextColor3 = Color3.fromRGB(0, 255, 0),
							TextScaled = true,
							Text = star.Coordinate[2],
							BorderColor3 = Color3.fromRGB(255, 255, 255),
							BorderSizePixel = 1,
						})
						local CoordX = Screen:CreateElement("TextLabel", {
							Parent = PlanetInfo,
							Size = UDim2.fromScale(0.5, 0.1),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.25, 0.15),
							BackgroundTransparency = 0,
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							Font = Enum.Font.Gotham,
							TextColor3 = Color3.fromRGB(255, 255, 0),
							TextScaled = true,
							Text = planet.Coordinate[1],
							BorderColor3 = Color3.fromRGB(255, 255, 255),
							BorderSizePixel = 1,
						})
						local CoordY = Screen:CreateElement("TextLabel", {
							Parent = PlanetInfo,
							Size = UDim2.fromScale(0.5, 0.1),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.75, 0.15),
							BackgroundTransparency = 0,
							BackgroundColor3 = Color3.fromRGB(0, 0, 0),
							Font = Enum.Font.Gotham,
							TextColor3 = Color3.fromRGB(255, 255, 0),
							TextScaled = true,
							Text = planet.Coordinate[2],
							BorderColor3 = Color3.fromRGB(255, 255, 255),
							BorderSizePixel = 1,
						})

						local ViewMoonsButton = Screen:CreateElement("TextButton", {
							Parent = PlanetInfo,
							Size = UDim2.fromScale(1, 0.2),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.9),
							BackgroundColor3 = Color3.fromRGB(255, 128, 0),
							Font = Enum.Font.SciFi,
							TextColor3 = Color3.fromRGB(0, 0, 0),
							TextScaled = true,
							Text = "Moons",
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 1,
						})

						ViewMoonsButton.MouseButton1Click:Connect(function()
							local GeneratingFrame = Screen:CreateElement("Frame", {
								Size = UDim2.fromScale(1, 1),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0.5),
								BackgroundTransparency = 0.5,
								BackgroundColor3 = Color3.fromRGB(0, 0, 0),
								ZIndex = 9999,
							})
			
							PlanetInfoMain.Visible = false
			
							local MoonMap = Screen:CreateElement("Frame", {
								Size = UDim2.fromOffset(Universe.SystemSize * (StarSize * 4), Universe.SystemSize * (StarSize * 4)),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(0.5, 0.5),
								BackgroundTransparency = 1,
							})
							MapToMove = MoonMap
			
							local PlanetCenter = Planet:Clone()
							PlanetCenter.Parent = MoonMap
							PlanetCenter.Size = UDim2.fromOffset(StarSize * 4, StarSize * 4)
							PlanetCenter.Position = UDim2.fromScale(0.5, 0.5)
							PlanetCenter.Visible = true

							for key, moon in pairs(planet.Data.Moons) do
								local Moon = Screen:CreateElement("TextButton", {
									Parent = MoonMap,
									BackgroundColor3 = moon.Data.GroundColor3,
									AnchorPoint = Vector2.new(0.5, 0.5),
									Size = UDim2.fromOffset(StarSize * 4, StarSize * 4),
									Position = UDim2.fromScale(0.5 + (moon.Coordinate[1] / Universe.SystemSize), 0.5 + -(moon.Coordinate[2] / Universe.SystemSize)),
									BorderColor3 = moon.Data.AtmosphereColor3,
									BorderSizePixel = 2,
									Text = '',
								})

								Moon.MouseButton1Click:Connect(function()
									MoonMap.Visible = false

									local MoonInfoMain = Screen:CreateElement("Frame", {
										Size = UDim2.fromScale(1, 1),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.fromScale(0.5, 0.5),
										BackgroundTransparency = 1,
									})
							
									local MoonPreview = Screen:CreateElement("Frame", {
										Parent = MoonInfoMain,
										Size = UDim2.fromScale(0.5, 1),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.fromScale(0.25, 0.5),
										BackgroundColor3 = Color3.fromRGB(0, 0, 0),
										BorderColor3 = Color3.fromRGB(255, 255, 255),
										BorderSizePixel = 1,
									})
							
									Screen:CreateElement("Frame", {
										Parent = MoonPreview,
										BorderSizePixel = 15,
										AnchorPoint = Vector2.new(0.5, 0.5),
										Size = UDim2.fromOffset(160, 160),
										Position = UDim2.fromScale(0.5, 0.5),
										BackgroundColor3 = moon.Data.GroundColor3,
										BorderColor3 = moon.Data.AtmosphereColor3,
									})
							
									local MoonInfo = Screen:CreateElement("Frame", {
										Parent = MoonInfoMain,
										Size = UDim2.fromScale(0.5, 1),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.fromScale(0.75, 0.5),
										BackgroundColor3 = Color3.fromRGB(0, 0, 0),
										BorderColor3 = Color3.fromRGB(255, 255, 255),
										BorderSizePixel = 1,
									})
									local CoordSX = Screen:CreateElement("TextLabel", {
										Parent = MoonInfo,
										Size = UDim2.fromScale(0.5, 0.1),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.fromScale(0.25, 0.05),
										BackgroundTransparency = 0,
										BackgroundColor3 = Color3.fromRGB(0, 0, 0),
										Font = Enum.Font.Gotham,
										TextColor3 = Color3.fromRGB(0, 255, 0),
										TextScaled = true,
										Text = star.Coordinate[1],
										BorderColor3 = Color3.fromRGB(255, 255, 255),
										BorderSizePixel = 1,
									})
									local CoordSY = Screen:CreateElement("TextLabel", {
										Parent = MoonInfo,
										Size = UDim2.fromScale(0.5, 0.1),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.fromScale(0.75, 0.05),
										BackgroundTransparency = 0,
										BackgroundColor3 = Color3.fromRGB(0, 0, 0),
										Font = Enum.Font.Gotham,
										TextColor3 = Color3.fromRGB(0, 255, 0),
										TextScaled = true,
										Text = star.Coordinate[2],
										BorderColor3 = Color3.fromRGB(255, 255, 255),
										BorderSizePixel = 1,
									})
									local CoordPX = Screen:CreateElement("TextLabel", {
										Parent = MoonInfo,
										Size = UDim2.fromScale(0.5, 0.1),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.fromScale(0.25, 0.15),
										BackgroundTransparency = 0,
										BackgroundColor3 = Color3.fromRGB(0, 0, 0),
										Font = Enum.Font.Gotham,
										TextColor3 = Color3.fromRGB(255, 255, 0),
										TextScaled = true,
										Text = planet.Coordinate[1],
										BorderColor3 = Color3.fromRGB(255, 255, 255),
										BorderSizePixel = 1,
									})
									local CoordPY = Screen:CreateElement("TextLabel", {
										Parent = MoonInfo,
										Size = UDim2.fromScale(0.5, 0.1),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.fromScale(0.75, 0.15),
										BackgroundTransparency = 0,
										BackgroundColor3 = Color3.fromRGB(0, 0, 0),
										Font = Enum.Font.Gotham,
										TextColor3 = Color3.fromRGB(255, 255, 0),
										TextScaled = true,
										Text = planet.Coordinate[2],
										BorderColor3 = Color3.fromRGB(255, 255, 255),
										BorderSizePixel = 1,
									})
									local CoordX = Screen:CreateElement("TextLabel", {
										Parent = MoonInfo,
										Size = UDim2.fromScale(0.5, 0.1),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.fromScale(0.25, 0.25),
										BackgroundTransparency = 0,
										BackgroundColor3 = Color3.fromRGB(0, 0, 0),
										Font = Enum.Font.Gotham,
										TextColor3 = Color3.fromRGB(0, 255, 255),
										TextScaled = true,
										Text = moon.Coordinate[1],
										BorderColor3 = Color3.fromRGB(255, 255, 255),
										BorderSizePixel = 1,
									})
									local CoordY = Screen:CreateElement("TextLabel", {
										Parent = MoonInfo,
										Size = UDim2.fromScale(0.5, 0.1),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.fromScale(0.75, 0.25),
										BackgroundTransparency = 0,
										BackgroundColor3 = Color3.fromRGB(0, 0, 0),
										Font = Enum.Font.Gotham,
										TextColor3 = Color3.fromRGB(0, 255, 255),
										TextScaled = true,
										Text = moon.Coordinate[2],
										BorderColor3 = Color3.fromRGB(255, 255, 255),
										BorderSizePixel = 1,
									})

									local CloseButton5 = Screen:CreateElement("TextButton", {
										Parent = MoonInfoMain,
										Size = UDim2.fromScale(0.05, 0.05),
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.fromScale(0.025, 0.025),
										BackgroundColor3 = Color3.fromRGB(255, 0, 0),
										BorderSizePixel = 0,
										Text = "X",
									})
							
									CloseButton5.MouseButton1Click:Connect(function()
										MoonMap.Visible = true
										MoonInfoMain:Destroy()
									end)
								end)
							end

							local CloseButton4 = Screen:CreateElement("TextButton", {
								Size = UDim2.fromScale(0.05, 0.05),
								AnchorPoint = Vector2.new(0.5, 0.5),
								Position = UDim2.fromScale(0.025, 0.025),
								BackgroundColor3 = Color3.fromRGB(255, 0, 0),
								BorderSizePixel = 0,
								Text = "X",
							})
					
							CloseButton4.MouseButton1Click:Connect(function()
								PlanetInfoMain.Visible = true
								MapToMove = PlanetMap
								MoonMap:Destroy()
								CloseButton4:Destroy()
							end)

							GeneratingFrame:Destroy()
						end)

						local CloseButton3 = Screen:CreateElement("TextButton", {
							Parent = PlanetInfoMain,
							Size = UDim2.fromScale(0.05, 0.05),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.025, 0.025),
							BackgroundColor3 = Color3.fromRGB(255, 0, 0),
							BorderSizePixel = 0,
							Text = "X",
						})
				
						CloseButton3.MouseButton1Click:Connect(function()
							PlanetMap.Visible = true
							PlanetInfoMain:Destroy()
						end)
					end)
				end

				local CloseButton2 = Screen:CreateElement("TextButton", {
					Size = UDim2.fromScale(0.05, 0.05),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.025, 0.025),
					BackgroundColor3 = Color3.fromRGB(255, 0, 0),
					BorderSizePixel = 0,
					Text = "X",
				})
		
				CloseButton2.MouseButton1Click:Connect(function()
					InfoMain.Visible = true
					--UniverseButton.Visible = true
					--SearchButton.Visible = true
					MapToMove = StarMap
					PlanetMap:Destroy()
					CloseButton2:Destroy()
				end)

				GeneratingFrame:Destroy()
			end)
		elseif star.Type == "BlackHole" then
			local CoordX = Screen:CreateElement("TextLabel", {
				Parent = StarInfo,
				Size = UDim2.fromScale(0.5, 0.1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.25, 0.05),
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				Text = star.Coordinate[1],
				BorderColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 1,
			})
			local CoordY = Screen:CreateElement("TextLabel", {
				Parent = StarInfo,
				Size = UDim2.fromScale(0.5, 0.1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.75, 0.05),
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Font = Enum.Font.Gotham,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextScaled = true,
				Text = star.Coordinate[2],
				BorderColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 1,
			})
		end

		local CloseButton = Screen:CreateElement("TextButton", {
			Parent = InfoMain,
			Size = UDim2.fromScale(0.05, 0.05),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.025, 0.025),
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
			BorderSizePixel = 0,
			Text = "X",
		})

		CloseButton.MouseButton1Click:Connect(function()
			StarMap.Visible = true
			InfoMain:Destroy()
		end)

		StarMap.Visible = false
	end)

	Star.Visible = true

	Runs += 1
end
Beep()

TotalStars:Destroy()
Credits:Destroy()

Generating.Text = "Let's go!"
task.wait(2)
Generating:Destroy()

task.wait(0.1)


--[[UniverseButton.Visible = true
UniverseButton.MouseButton1Click:Connect(function()
	local InfoMain = Screen:CreateElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
	})

	local StarPreview = Screen:CreateElement("Frame", {
		Parent = InfoMain,
		Size = UDim2.fromScale(0.5, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.25, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 1,
	})

	Screen:CreateElement("Frame", {
		Parent = StarPreview,
		BorderSizePixel = 50,
		BorderColor3 = Color3.fromRGB(0, 255, 255),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(150, 150),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 0, 255)
	})

	local StarInfo = Screen:CreateElement("Frame", {
		Parent = InfoMain,
		Size = UDim2.fromScale(0.5, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.75, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 1,
	})

	local CloseButton = Screen:CreateElement("TextButton", {
		Parent = InfoMain,
		Size = UDim2.fromScale(0.05, 0.05),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.025, 0.025),
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		BorderSizePixel = 0,
		Text = "X",
	})

	CloseButton.MouseButton1Click:Connect(function()
		StarMap.Visible = true
		InfoMain:Destroy()
	end)

	StarMap.Visible = false
end)

HelpButton.Visible = true
HelpButton.MouseButton1Click:Connect(function()
	-- TODO
end)

SearchButton.Visible = true
SearchButton.MouseButton1Click:Connect(function()
	-- TODO
end)]]

local MovingKeys = {
	[Enum.KeyCode.W] = UDim2.fromOffset(0, StarSize * StarSize);
	[Enum.KeyCode.S] = UDim2.fromOffset(0, -StarSize * StarSize);
	[Enum.KeyCode.A] = UDim2.fromOffset(StarSize * StarSize, 0);
	[Enum.KeyCode.D] = UDim2.fromOffset(-StarSize * StarSize, 0);
}

MapToMove = StarMap
Keyboard.UserInput:Connect(function(input, player)
	if input.UserInputState == Enum.UserInputState.Begin then
		if not MapToMove.Visible then return end
		
		local Modifier = MovingKeys[input.KeyCode]
		if Modifier == nil then return end

		if typeof(Modifier) == "UDim2" then
			MapToMove.Position += Modifier
		end
	end

	if SearchButton.Text ~= "Search" then
		SearchButton.Text = "Search"
	end

	if HelpButton.Text ~= "Help" then
		HelpButton.Text = "Help"
	end

	if UniverseButton.Text ~= "Universe" then
		UniverseButton.Text = "Universe"
	end
end)