local seed = os.time()
math.randomseed(seed)
print("SEED: "..seed)

local startingPlanetAmount = 300
local startingPlanetMass = 10000 -- kg
local startingPlanetMassError = 0.2
local gravitationalConstant = 100--math.exp(6.67,-11)
local planetMinimum = 250

local threadCount = 4
local threads = {}

local playingSpace = 1
local radiusMultiplier = 0.2
local wallDrag = 1--0.5

local mapSize = {
	["x"] = 5000,
	["y"] = 5000,
}

local camera = {
	["position"] = {
		["x"] = 0,
		["y"] = 0,
	},
	["speed"] = 1000
}

local planets = {
	--[[["sun"] = {
		["position"] = {
			["x"] = 400,
			["y"] = 400,
		},
		["size"] = {
			["x"] = 200,
			["y"] = 200,
		},
		["sprite"] = sunImage,
		["gravity"] = 6000000,
	}]]--
}

function getRadius(v)
	return (math.pow( v["mass"] / ( (4/3) * math.pi ), 1/3 )) * radiusMultiplier
end

function generatePlanet()
	local A = {
		["position"] = {
			["x"] = math.random(1,mapSize["x"]),
			["y"] = math.random(1,mapSize["y"]),
		},
		["velocity"] = {
			["x"] = math.random()*10,
			["y"] = math.random()*10,
		},
		["acceleration"] = {
			["x"] = 0,
			["y"] = 0,
		},
		["mass"] = startingPlanetMass + (startingPlanetMass * (math.random(-1000,1000) / 1000) * startingPlanetMassError),
		["radius"] = 0,
		["color"] = {
			math.random(),
			math.random(),
			math.random()
		},
		["UID"] = 0
	}
	A["radius"] = getRadius(A)
	return A
end

function love.load()
	for i=1,startingPlanetAmount do
		local A = generatePlanet()
		A["UID"] = i
		planets[i] = A
	end
	for i=1,4 do
		threads[i] = love.thread.newThread([[
			
		]])
	end
end

function getDistance(v,b)
	local distanceX = (b["position"]["x"] - v["position"]["x"]) * playingSpace
	local distanceY = (b["position"]["y"] - v["position"]["y"]) * playingSpace
	local distanceTotal = math.sqrt((distanceX * distanceX) + (distanceY * distanceY))
	return distanceTotal,distanceX,distanceY
end

function love.update(dt)
	--playingSpace = playingSpace + (dt/3)
	--print(playingSpace)
	--print("Ticks per second: "..tonumber(1/dt))
	
	local start = love.timer.getTime()
	for k,v in pairs(planets) do
		local totalForce = {
			["x"] = 0,
			["y"] = 0
		}
		for p,b in pairs(planets) do
			if v["UID"] == b["UID"] then else
				local distanceTotal,distanceX,distanceY = getDistance(v,b)
				local F = ( gravitationalConstant * v["mass"] * b["mass"] )/(distanceTotal * distanceTotal)
				
				local cDistanceX = distanceX/distanceTotal
				local cDistanceY = distanceY/distanceTotal
				
				totalForce["x"] = totalForce["x"] + (F * dt * cDistanceX)
				totalForce["y"] = totalForce["y"] + (F * dt * cDistanceY)
			end
		end
		
		v["acceleration"]["x"] = totalForce["x"] / v["mass"]
		v["acceleration"]["y"] = totalForce["y"] / v["mass"]
		
		--print("Acc X "..tostring(v["acceleration"]["x"]))
		--print("Acc Y "..tostring(v["acceleration"]["y"]))
	end
	--print("Force calculations "..love.timer.getTime() - start)
	
	local start = love.timer.getTime()
	for k,v in pairs(planets) do
		--print("Vel X "..tostring(v["velocity"]["x"]))
		--print("Vel Y "..tostring(v["velocity"]["y"]))
		
		v["velocity"]["y"] = v["velocity"]["y"] + (v["acceleration"]["y"] * dt)
		v["velocity"]["x"] = v["velocity"]["x"] + (v["acceleration"]["x"] * dt)
		
		--print("Pos X "..tostring(v["position"]["x"]))
		--print("Pos Y "..tostring(v["position"]["y"]))
		
		v["position"]["y"] = v["position"]["y"] + (v["velocity"]["y"] * dt)
		v["position"]["x"] = v["position"]["x"] + (v["velocity"]["x"] * dt)
		
		--[[if v["position"]["x"] > love.graphics.getWidth() then
			v["position"]["x"] = v["position"]["x"] - love.graphics.getWidth()
		elseif v["position"]["x"] < 0 then
			v["position"]["x"] = v["position"]["x"] + love.graphics.getWidth()
		end
		
		if v["position"]["y"] > love.graphics.getHeight() then
			v["position"]["y"] = v["position"]["y"] - love.graphics.getHeight()
		elseif v["position"]["y"] < 0 then
			v["position"]["y"] = v["position"]["y"] + love.graphics.getHeight()
		end]]--
		
		if v["position"]["x"] > mapSize["x"] or v["position"]["x"] < 0 then
			v["velocity"]["x"] = v["velocity"]["x"] * wallDrag * -1
		end
		
		if v["position"]["y"] > mapSize["y"] or v["position"]["y"] < 0 then
			v["velocity"]["y"] = v["velocity"]["y"] * wallDrag * -1
		end
	end
	--print("Position calculations "..love.timer.getTime() - start)
	
	local start = love.timer.getTime()
	local planetCount = 0
	local delete = {}
	for k,v in pairs(planets) do
		planetCount = planetCount + 1
		for p,b in pairs(planets) do
			if v["UID"] == b["UID"] then else
				local distanceTotal = getDistance(v,b)
				local r1 = v["radius"]
				local r2 = b["radius"]
				if (r1 + r2) > distanceTotal then
					local eV = {
						["x"] = (1/2)*(v["mass"])*(v["velocity"]["x"])*(v["velocity"]["x"]), -- <== HERE
						["y"] = (1/2)*(v["mass"])*(v["velocity"]["y"])*(v["velocity"]["y"]), -- <== HERE 
					}
					local eB = {
						["x"] = (1/2)*(b["mass"])*(b["velocity"]["x"])*(b["velocity"]["x"]), -- <== HERE
						["y"] = (1/2)*(b["mass"])*(b["velocity"]["y"])*(b["velocity"]["y"]), -- <== HERE
					}
					local eC = {
						["x"] = 0,
						["y"] = 0,
					}
					
					if v["velocity"]["x"] < 0 then eV["x"] = -eV["x"] end
					if v["velocity"]["y"] < 0 then eV["y"] = -eV["y"] end
					if b["velocity"]["x"] < 0 then eB["x"] = -eB["x"] end
					if b["velocity"]["y"] < 0 then eB["y"] = -eB["y"] end
					
					eC["x"] = eV["x"] + eB["x"]
					eC["y"] = eV["y"] + eB["y"]
					
					local negativeX = 1
					local negativeY = 1
					
					if eC["x"] < 0 then
						negativeX = -1
					end
					if eC["x"] < 0 then
						negativeY = -1
					end
					
					eC["x"] = math.abs(eC["x"])
					eC["y"] = math.abs(eC["y"])
					
					--print("eCX "..tonumber(eC["x"]))
					--print("eCY "..tonumber(eC["y"]))
					
					if v["mass"] > b["mass"] then
						v["mass"] = v["mass"] + b["mass"]
						v["velocity"]["x"] = math.sqrt(eC["x"] / ( (1/2) * v["mass"] )) * negativeX
						v["velocity"]["y"] = math.sqrt(eC["y"] / ( (1/2) * v["mass"] )) * negativeY
						v["radius"] = getRadius(v)
						b["mass"] = 0
						table.insert(delete,p)
					elseif v["mass"] < b["mass"] then
						b["mass"] = b["mass"] + v["mass"]
						b["velocity"]["x"] = math.sqrt(eC["x"] / ( (1/2) * b["mass"] )) * negativeX
						b["velocity"]["y"] = math.sqrt(eC["y"] / ( (1/2) * b["mass"] )) * negativeY
						b["radius"] = getRadius(b)
						v["mass"] = 0
						table.insert(delete,k)
					end
				end
			end
		end
	end
	
	for _,k in pairs(delete) do
		planetCount = planetCount - 1
		planets[k] = nil
	end
	--print("Collision calculations "..love.timer.getTime() - start)
	
	if planetCount < planetMinimum then
		local A = generatePlanet()
		local B = math.random(1,9999999)
		while planets[B] do B = math.random(1,9999999) end
		A["UID"] = B
		planets[B] = A
	end
	
	if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
		camera["position"]["x"] = camera["position"]["x"] - (dt * camera["speed"])
		if camera["position"]["x"] < 0 then camera["position"]["x"] = 0 end
	end
	if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
		camera["position"]["x"] = camera["position"]["x"] + (dt * camera["speed"])
		if camera["position"]["x"] > mapSize["x"] - love.graphics.getWidth() then camera["position"]["x"] = mapSize["x"] - love.graphics.getWidth() end
	end
	
	if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
		camera["position"]["y"] = camera["position"]["y"] - (dt * camera["speed"])
		if camera["position"]["y"] < 0 then camera["position"]["y"] = 0 end
	end
	if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
		camera["position"]["y"] = camera["position"]["y"] + (dt * camera["speed"])
		if camera["position"]["y"] > mapSize["y"] - love.graphics.getHeight() then camera["position"]["y"] = mapSize["y"] - love.graphics.getHeight() end
	end
end

function love.draw()
	for k,v in pairs(planets) do
		--love.graphics.draw(v["sprite"],v["position"]["x"] - (v["size"]["x"] / 2),v["position"]["y"] - (v["size"]["y"] / 2))
		local r = v["radius"]
		love.graphics.setColor(v["color"])
		love.graphics.circle("fill",v["position"]["x"] - camera["position"]["x"],v["position"]["y"] - camera["position"]["y"],r / playingSpace)
	end
end