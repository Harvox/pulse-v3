local espLibrary = {
    instances = {},
    espCache = {},
    chamsCache = {},
    objectCache = {},
    conns = {},
    whitelist = {}, -- insert string that is the player's name you want to whitelist (turns esp color to whitelistColor in options)
    blacklist = {}, -- insert string that is the player's name you want to blacklist (removes player from esp)
    options = {
        enabled = true,
        minScaleFactorX = 1,
        maxScaleFactorX = 10,
        minScaleFactorY = 1,
        maxScaleFactorY = 10,
        scaleFactorX = 5,
        scaleFactorY = 6,
        boundingBox = false, -- WARNING | Significant Performance Decrease when true
        boundingBoxDescending = true,
        excludedPartNames = {},
        font = 2,
        fontSize = 13,
        limitDistance = false,
        maxDistance = 1000,
        visibleOnly = false,
        teamCheck = false,
        teamColor = false,
        useCustomTeamColor = false,
        customteamColor = Color3.new(1,1,1),
        fillColor = nil,
        whitelistColor = Color3.new(1, 0, 0),
        outOfViewArrows = true,
        outOfViewArrowsFilled = true,
        outOfViewArrowsSize = 25,
        outOfViewArrowsRadius = 100,
        outOfViewArrowsColor = Color3.new(1, 1, 1),
        outOfViewArrowsTransparency = 0.5,
        outOfViewArrowsOutline = true,
        outOfViewArrowsOutlineFilled = false,
        outOfViewArrowsOutlineColor = Color3.new(1, 1, 1),
        outOfViewArrowsOutlineTransparency = 1,
        names = true,
        nameTransparency = 1,
        nameColor = Color3.new(1, 1, 1),
        boxes = true,
        boxesTransparency = 1,
        boxesColor = Color3.new(1, 0, 0),
        boxFill = false,
        boxFillTransparency = 0.5,
        boxFillColor = Color3.new(1, 0, 0),
        healthBars = true,
        healthBarsSize = 1,
        healthBarsTransparency = 1,
        healthBarsColor = Color3.new(0, 1, 0),
        healthText = true,
        healthTextTransparency = 1,
        healthTextSuffix = "%",
        healthTextColor = Color3.new(1, 1, 1),
        distance = true,
        distanceTransparency = 1,
        distanceSuffix = " Studs",
        distanceColor = Color3.new(1, 1, 1),
        tool = false,
        toolTransparency = 1,
        toolColor = Color3.new(1,1,1),
        tracers = false,
        tracerTransparency = 1,
        tracerColor = Color3.new(1, 1, 1),
        tracerOrigin = "Bottom", -- Available [Mouse, Top, Bottom]
        chams = true,
        chamsFillColor = Color3.new(1, 0, 0),
        chamsFillTransparency = 0.5,
        chamsOutlineColor = Color3.new(),
        chamsOutlineTransparency = 0,
        skeleton = false,
        skeletonColor = Color3.new(1, 1, 1),
        skeletonTransparency = 1,
    },
  };
  espLibrary.__index = espLibrary;
  
  -- variables
  local getService = game.GetService;
  local instanceNew = Instance.new;
  local drawingNew = Drawing.new;
  local vector2New = Vector2.new;
  local vector3New = Vector3.new;
  local cframeNew = CFrame.new;
  local color3New = Color3.new;
  local raycastParamsNew = RaycastParams.new;
  local abs = math.abs;
  local tan = math.tan;
  local rad = math.rad;
  local clamp = math.clamp;
  local floor = math.floor;
  local find = table.find;
  local insert = table.insert;
  local findFirstChild = game.FindFirstChild;
  local findFirstChildOfClass = game.FindFirstChildOfClass;
  local getChildren = game.GetChildren;
  local getDescendants = game.GetDescendants;
  local isA = workspace.IsA;
  local raycast = workspace.Raycast;
  local emptyCFrame = cframeNew();
  local pointToObjectSpace = emptyCFrame.PointToObjectSpace;
  local getComponents = emptyCFrame.GetComponents;
  local cross = vector3New().Cross;
  local inf = 1 / 0;
  
  -- services
  local workspace = getService(game, "Workspace");
  local runService = getService(game, "RunService");
  local players = getService(game, "Players");
  local coreGui = getService(game, "CoreGui");
  local userInputService = getService(game, "UserInputService");
  
  -- cache
  local currentCamera = workspace.CurrentCamera;
  local localPlayer = players.LocalPlayer;
  local screenGui = instanceNew("ScreenGui", coreGui);
  local lastFov, lastScale;
  
  -- instance functions
  local wtvp = currentCamera.WorldToViewportPoint;
  
  -- Support Functions
  local function isDrawing(type)
    return type == "Square" or type == "Text" or type == "Triangle" or type == "Image" or type == "Line" or type == "Circle";
  end
  
  local function create(type, properties)
    local drawing = isDrawing(type);
    local object = drawing and drawingNew(type) or instanceNew(type);
  
    if (properties) then
        for i,v in next, properties do
            object[i] = v;
        end
    end
  
    if (not drawing) then
        insert(espLibrary.instances, object);
    end
  
    return object;
  end
  
  local function worldToViewportPoint(position)
    local screenPosition, onScreen = wtvp(currentCamera, position);
    return vector2New(screenPosition.X, screenPosition.Y), onScreen, screenPosition.Z;
  end
  
  local function round(number)
    return typeof(number) == "Vector2" and vector2New(round(number.X), round(number.Y)) or floor(number);
  end
  
  -- Main Functions
  function espLibrary.getTeam(player)
    local team = player.Team;
    return team, player.TeamColor.Color;
  end
  
  function espLibrary.getCharacter(player)
    local character = player.Character
    if not character then return nil, nil end
    
    -- Try to find HumanoidRootPart first
    local torso = character:FindFirstChild("HumanoidRootPart")
    
    -- If no HumanoidRootPart, try UpperTorso (for R15 rigs)
    if not torso then
        torso = character:FindFirstChild("UpperTorso")
    end
    
    -- If still no torso found, try Torso (for R6 rigs)
    if not torso then
        torso = character:FindFirstChild("Torso")
    end
    
    return character, torso
  end

  function espLibrary.getTool(player)
    local character = player.Character;
    return findFirstChildOfClass(character, "Tool") ~= nil and tostring(findFirstChildOfClass(character, "Tool")) or findFirstChildOfClass(character, "Tool") == nil and "None"
  end
  
  function espLibrary.getBoundingBox(character, torso)
    if (espLibrary.options.boundingBox) then
        local minX, minY, minZ = inf, inf, inf;
        local maxX, maxY, maxZ = -inf, -inf, -inf;
  
        for _, part in next, espLibrary.options.boundingBoxDescending and getDescendants(character) or getChildren(character) do
            if (isA(part, "BasePart") and not find(espLibrary.options.excludedPartNames, part.Name)) then
                local size = part.Size;
                local sizeX, sizeY, sizeZ = size.X, size.Y, size.Z;
  
                local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = getComponents(part.CFrame);
  
                local wiseX = 0.5 * (abs(r00) * sizeX + abs(r01) * sizeY + abs(r02) * sizeZ);
                local wiseY = 0.5 * (abs(r10) * sizeX + abs(r11) * sizeY + abs(r12) * sizeZ);
                local wiseZ = 0.5 * (abs(r20) * sizeX + abs(r21) * sizeY + abs(r22) * sizeZ);
  
                minX = minX > x - wiseX and x - wiseX or minX;
                minY = minY > y - wiseY and y - wiseY or minY;
                minZ = minZ > z - wiseZ and z - wiseZ or minZ;
  
                maxX = maxX < x + wiseX and x + wiseX or maxX;
                maxY = maxY < y + wiseY and y + wiseY or maxY;
                maxZ = maxZ < z + wiseZ and z + wiseZ or maxZ;
            end
        end
  
        local oMin, oMax = vector3New(minX, minY, minZ), vector3New(maxX, maxY, maxZ);
        return (oMax + oMin) * 0.5, oMax - oMin;
    else
        return torso.Position, vector2New(espLibrary.options.scaleFactorX, espLibrary.options.scaleFactorY);
    end
  end
  
  function espLibrary.getScaleFactor(fov, depth)
    if (fov ~= lastFov) then
        lastScale = tan(rad(fov * 0.5)) * 2;
        lastFov = fov;
    end
  
    return 1 / (depth * lastScale) * 1000;
  end
  
  function espLibrary.getBoxData(position, size)
    local torsoPosition, onScreen, depth = worldToViewportPoint(position);
    local scaleFactor = espLibrary.getScaleFactor(currentCamera.FieldOfView, depth);
  
    local clampX = clamp(size.X, espLibrary.options.minScaleFactorX, espLibrary.options.maxScaleFactorX);
    local clampY = clamp(size.Y, espLibrary.options.minScaleFactorY, espLibrary.options.maxScaleFactorY);
    local size = round(vector2New(clampX * scaleFactor, clampY * scaleFactor));
  
    return onScreen, size, round(vector2New(torsoPosition.X - (size.X * 0.5), torsoPosition.Y - (size.Y * 0.5))), torsoPosition;
  end
  
  function espLibrary.getHealth(player, character)
    local humanoid = findFirstChild(character, "Humanoid");
  
    if (humanoid) then
        return math.floor(humanoid.Health), humanoid.MaxHealth;
    end
  
    return 100, 100;
  end
  
  function espLibrary.visibleCheck(character, position)
    local origin = currentCamera.CFrame.Position;
    local params = raycastParamsNew();
  
    params.FilterDescendantsInstances = { espLibrary.getCharacter(localPlayer), currentCamera, character };
    params.FilterType = Enum.RaycastFilterType.Blacklist;
    params.IgnoreWater = true;
  
    return (not raycast(workspace, origin, position - origin, params));
  end
  
  function espLibrary.addEsp(player)
    if (player == localPlayer) then
        return
    end
  
    local objects = {
        arrow = create("Triangle", {
            Thickness = 1,
        }),
        arrowOutline = create("Triangle", {
            Thickness = 1,
        }),
        bottom = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        tool = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        top = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        side = create("Text", {
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        }),
        boxFill = create("Square", {
            Thickness = 1,
            Filled = true,
        }),
        boxOutline = create("Square", {
            Thickness = 3,
            Color = color3New()
        }),
        box = create("Square", {
            Thickness = 1
        }),
        healthBarOutline = create("Square", {
            Thickness = 1,
            Color = color3New(),
            Filled = true
        }),
        healthBar = create("Square", {
            Thickness = 1,
            Filled = true
        }),
        lineoutline = create("Line", {Thickness = 3}),
        line = create("Line", {Thickness = 1}),
        
        -- Add skeleton line objects
        skeletonHead = create("Line", {Thickness = 1}),
        skeletonTorso = create("Line", {Thickness = 1}),
        skeletonLeftArm = create("Line", {Thickness = 1}),
        skeletonRightArm = create("Line", {Thickness = 1}),
        skeletonLeftLeg = create("Line", {Thickness = 1}),
        skeletonRightLeg = create("Line", {Thickness = 1}),
        -- For R15 additional connections
        skeletonUpperTorso = create("Line", {Thickness = 1}),
        skeletonLeftUpperArm = create("Line", {Thickness = 1}),
        skeletonRightUpperArm = create("Line", {Thickness = 1}),
        skeletonLeftUpperLeg = create("Line", {Thickness = 1}),
        skeletonRightUpperLeg = create("Line", {Thickness = 1}),
    };
  
    espLibrary.espCache[player] = objects;

    -- Add death check connection
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                -- Remove ESP when player dies
                for _, object in next, objects do
                    object.Visible = false
                end
            end)
        end
    end

    -- Connect to CharacterAdded to handle respawns
    player.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid then
            humanoid.Died:Connect(function()
                -- Remove ESP when player dies
                for _, object in next, objects do
                    object.Visible = false
                end
            end)
        end
    end)
  end
  
  function espLibrary.removeEsp(player)
    local espCache = espLibrary.espCache[player];
  
    if (espCache) then
        espLibrary.espCache[player] = nil;
  
        for index, object in next, espCache do
            espCache[index] = nil;
            object:Remove();
        end
    end
  end
  
  function espLibrary.addChams(player)
    if (player == localPlayer) then
        return
    end
  
    espLibrary.chamsCache[player] = create("Highlight", {
        Parent = screenGui,
    });
  end
  
  function espLibrary.removeChams(player)
    local highlight = espLibrary.chamsCache[player];
  
    if (highlight) then
        espLibrary.chamsCache[player] = nil;
        highlight:Destroy();
    end
  end
  
  function espLibrary.addObject(object, options)
    espLibrary.objectCache[object] = {
        options = options,
        text = create("Text", {
            Center = true,
            Size = 13,
            Outline = true,
            OutlineColor = color3New(),
            Font = 2,
        })
    };
  end
  
  function espLibrary.removeObject(object)
    local cache = espLibrary.objectCache[object];
  
    if (cache) then
        espLibrary.objectCache[object] = nil;
        cache.text:Remove();
    end
  end
  
  function espLibrary:AddObjectEsp(object, defaultOptions)
    assert(object and object.Parent, "invalid object passed");
  
    local options = defaultOptions or {};
  
    options.enabled = options.enabled or true;
    options.limitDistance = options.limitDistance or false;
    options.maxDistance = options.maxDistance or false;
    options.visibleOnly = options.visibleOnly or false;
    options.color = options.color or color3New(1, 1, 1);
    options.transparency = options.transparency or 1;
    options.text = options.text or object.Name;
    options.font = options.font or 2;
    options.fontSize = options.fontSize or 13;
  
    self.addObject(object, options);
  
    insert(self.conns, object.Parent.ChildRemoved:Connect(function(child)
        if (child == object) then
            self.removeObject(child);
        end
    end));
  
    return options;
  end
  
  function espLibrary:Unload()
    for _, connection in next, self.conns do
        connection:Disconnect();
    end
  
    for _, player in next, players:GetPlayers() do
        self.removeEsp(player);
        self.removeChams(player);
    end
  
    for object, _ in next, self.objectCache do
        self.removeObject(object);
    end
  
    for _, object in next, self.instances do
        object:Destroy();
    end
  
    screenGui:Destroy();
    runService:UnbindFromRenderStep("esp_rendering");
  end
  
  function espLibrary:Load(renderValue)
    insert(self.conns, players.PlayerAdded:Connect(function(player)
        self.addEsp(player);
        self.addChams(player);
    end));
  
    insert(self.conns, players.PlayerRemoving:Connect(function(player)
        self.removeEsp(player);
        self.removeChams(player);
    end));
  
    for _, player in next, players:GetPlayers() do
        self.addEsp(player);
        self.addChams(player);
    end
  
    runService:BindToRenderStep("esp_rendering", renderValue or (Enum.RenderPriority.Camera.Value + 1), function()
        for player, objects in next, self.espCache do
            local character, torso = self.getCharacter(player);
  
            if (character and torso) then
                -- Add check for dead players
                local humanoid = character:FindFirstChild("Humanoid")
                if not humanoid or humanoid.Health <= 0 then
                    -- Skip rendering ESP for dead players
                    for _, object in next, objects do
                        object.Visible = false
                    end
                    continue
                end

                local onScreen, size, position, torsoPosition = self.getBoxData(torso.Position, Vector3.new(5, 6.5));
                local distance = (currentCamera.CFrame.Position - torso.Position).Magnitude;
                local canShow, enabled = onScreen and (size and position), self.options.enabled;
                local team, teamColor = self.getTeam(player);
                local color = self.options.teamColor and teamColor or nil;
                local tool = self.getTool(player)

                if self.options.useCustomTeamColor and self.options.teamColor then
                    color = self.options.customteamColor
                end
  
                if (self.options.fillColor ~= nil) then
                    color = self.options.fillColor;
                end
  
                if (find(self.whitelist, player.Name)) then
                    color = self.options.whitelistColor;
                end
  
                if (find(self.blacklist, player.Name)) then
                    enabled = false;
                end
  
                if (self.options.limitDistance and distance > self.options.maxDistance) then
                    enabled = false;
                end
  
                if (self.options.visibleOnly and not self.visibleCheck(character, torso.Position)) then
                    enabled = false;
                end
  
                if (self.options.teamCheck and (team == self.getTeam(localPlayer))) then
                    enabled = false;
                end
  
                local viewportSize = currentCamera.ViewportSize;
  
                local screenCenter = vector2New(viewportSize.X / 2, viewportSize.Y / 2);
                local objectSpacePoint = (pointToObjectSpace(currentCamera.CFrame, torso.Position) * vector3New(1, 0, 1)).Unit;
                local crossVector = cross(objectSpacePoint, vector3New(0, 1, 1));
                local rightVector = vector2New(crossVector.X, crossVector.Z);
  
                local arrowRadius, arrowSize = self.options.outOfViewArrowsRadius, self.options.outOfViewArrowsSize;
                local arrowPosition = screenCenter + vector2New(objectSpacePoint.X, objectSpacePoint.Z) * arrowRadius;
                local arrowDirection = (arrowPosition - screenCenter).Unit;
  
                local pointA, pointB, pointC = arrowPosition, screenCenter + arrowDirection * (arrowRadius - arrowSize) + rightVector * arrowSize, screenCenter + arrowDirection * (arrowRadius - arrowSize) + -rightVector * arrowSize;
  
                local health, maxHealth = self.getHealth(player, character);
                local healthBarSize = round(vector2New(self.options.healthBarsSize, -(size.Y * (health / maxHealth))));
                local healthBarPosition = round(vector2New(position.X - (3 + healthBarSize.X), position.Y + size.Y));
  
                local origin = self.options.tracerOrigin;
                local show = canShow and enabled;
  
                objects.arrow.Visible = (not canShow and enabled) and self.options.outOfViewArrows;
                objects.arrow.Filled = self.options.outOfViewArrowsFilled;
                objects.arrow.Transparency = self.options.outOfViewArrowsTransparency;
                objects.arrow.Color = color or self.options.outOfViewArrowsColor;
                objects.arrow.PointA = pointA;
                objects.arrow.PointB = pointB;
                objects.arrow.PointC = pointC;
  
                objects.arrowOutline.Visible = (not canShow and enabled) and self.options.outOfViewArrowsOutline;
                objects.arrowOutline.Filled = self.options.outOfViewArrowsOutlineFilled;
                objects.arrowOutline.Transparency = self.options.outOfViewArrowsOutlineTransparency;
                objects.arrowOutline.Color = color or self.options.outOfViewArrowsOutlineColor;
                objects.arrowOutline.PointA = pointA;
                objects.arrowOutline.PointB = pointB;
                objects.arrowOutline.PointC = pointC;
  
                objects.top.Visible = show and self.options.names;
                objects.top.Font = self.options.font;
                objects.top.Size = self.options.fontSize;
                objects.top.Transparency = self.options.nameTransparency;
                objects.top.Color = color or self.options.nameColor;
                objects.top.Text = player.Name;
                objects.top.Position = round(position + vector2New(size.X * 0.5, -(objects.top.TextBounds.Y + 2)));
  
                objects.side.Visible = show and self.options.healthText;
                objects.side.Font = self.options.font;
                objects.side.Size = self.options.fontSize;
                objects.side.Transparency = self.options.healthTextTransparency;
                objects.side.Color = color or self.options.healthTextColor;
                objects.side.Text = health .. self.options.healthTextSuffix;
                objects.side.Position = round(position + vector2New(size.X + 3, -3));

                objects.tool.Visible = show and self.options.tool and tool ~= "None";
                objects.tool.Font = self.options.font;
                objects.tool.Size = self.options.fontSize;
                objects.tool.Transparency = self.options.toolTransparency;
                objects.tool.Color = color or self.options.toolColor;
                objects.tool.Text = tostring(tool);
                objects.tool.Position = round(position + vector2New(size.X * 0.5, size.Y + 1));
  
                local Distance_Offset = objects.tool.Visible and 13 or 2

                objects.bottom.Visible = show and self.options.distance;
                objects.bottom.Font = self.options.font;
                objects.bottom.Size = self.options.fontSize;
                objects.bottom.Transparency = self.options.distanceTransparency;
                objects.bottom.Color = color or self.options.distanceColor;
                objects.bottom.Text = tostring(round(distance)) .. self.options.distanceSuffix;
                objects.bottom.Position = round(position + vector2New(size.X * 0.5, size.Y + Distance_Offset));
  
                objects.box.Visible = show and self.options.boxes;
                objects.box.Color = color or self.options.boxesColor;
                objects.box.Transparency = self.options.boxesTransparency;
                objects.box.Size = size;
                objects.box.Position = position;
  
                objects.boxOutline.Visible = show and self.options.boxes;
                objects.boxOutline.Transparency = self.options.boxesTransparency;
                objects.boxOutline.Size = size;
                objects.boxOutline.Position = position;
  
                objects.boxFill.Visible = show and self.options.boxFill;
                objects.boxFill.Color = color or self.options.boxFillColor;
                objects.boxFill.Transparency = self.options.boxFillTransparency;
                objects.boxFill.Size = size;
                objects.boxFill.Position = position;
  
                objects.healthBar.Visible = show and self.options.healthBars;
                objects.healthBar.Color = self.options.healthBarsColor;
                objects.healthBar.Transparency = self.options.healthBarsTransparency;
                objects.healthBar.Size = healthBarSize;
                objects.healthBar.Position = healthBarPosition;
  
                objects.healthBarOutline.Visible = show and self.options.healthBars;
                objects.healthBarOutline.Transparency = self.options.healthBarsTransparency;
                objects.healthBarOutline.Size = round(vector2New(healthBarSize.X, -size.Y) + vector2New(2, -2));
                objects.healthBarOutline.Position = healthBarPosition - vector2New(1, -1);
  
                objects.line.Visible = show and self.options.tracers;
                objects.line.Color = color or self.options.tracerColor;
                objects.line.Transparency = self.options.tracerTransparency;
                objects.line.From =
                    origin == "Mouse" and userInputService:GetMouseLocation() or
                    origin == "Top" and vector2New(viewportSize.X * 0.5, 0) or
                    origin == "Bottom" and vector2New(viewportSize.X * 0.5, viewportSize.Y);
                objects.line.To = torsoPosition;
                objects.lineoutline.Visible = show and self.options.tracers;
                objects.lineoutline.Color = Color3.new(0,0,0)
                objects.lineoutline.Transparency = self.options.tracerTransparency;
                objects.lineoutline.From =
                    origin == "Mouse" and userInputService:GetMouseLocation() or
                    origin == "Top" and vector2New(viewportSize.X * 0.5, 0) or
                    origin == "Bottom" and vector2New(viewportSize.X * 0.5, viewportSize.Y);
                    objects.lineoutline.To = torsoPosition;

                -- Update skeleton ESP
                self.updateSkeleton(character, objects, show);

            else
                local objects = objects
                for objectName, object in next, objects do
                    object.Visible = false
                end
            end
        end
  
        for player, highlight in next, self.chamsCache do
            local character, torso = self.getCharacter(player);
  
            if (character and torso) then
                local distance = (currentCamera.CFrame.Position - torso.Position).Magnitude;
                local canShow = self.options.enabled and self.options.chams;
                local team, teamColor = self.getTeam(player);
                local color = self.options.teamColor and teamColor or nil;

                if self.options.useCustomTeamColor and self.options.teamColor then
                    color = self.options.customteamColor
                end
  
                if (self.options.fillColor ~= nil) then
                    color = self.options.fillColor;
                end
  
                if (find(self.whitelist, player.Name)) then
                    color = self.options.whitelistColor;
                end
  
                if (find(self.blacklist, player.Name)) then
                    canShow = false;
                end
  
                if (self.options.limitDistance and distance > self.options.maxDistance) then
                    canShow = false;
                end
  
                if (self.options.teamCheck and (team == self.getTeam(localPlayer))) then
                    canShow = false;
                end
  
                highlight.Enabled = canShow;
                highlight.DepthMode = self.options.visibleOnly and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop;
                highlight.Adornee = character;
                highlight.FillColor = color or self.options.chamsFillColor;
                highlight.FillTransparency = self.options.chamsFillTransparency;
                highlight.OutlineColor = color or self.options.chamsOutlineColor;
                highlight.OutlineTransparency = self.options.chamsOutlineTransparency;
            end
        end
  
        for object, cache in next, self.objectCache do
            local partPosition = vector3New();
  
            if (object:IsA("BasePart")) then
                partPosition = object.Position;
            elseif (object:IsA("Model")) then
                partPosition = self.getBoundingBox(object);
            end
  
            local distance = (currentCamera.CFrame.Position - partPosition).Magnitude;
            local screenPosition, onScreen = worldToViewportPoint(partPosition);
            local canShow = cache.options.enabled and onScreen;
  
            if (self.options.limitDistance and distance > self.options.maxDistance) then
                canShow = false;
            end
  
            if (self.options.visibleOnly and not self.visibleCheck(object, partPosition)) then
                canShow = false;
            end
  
            cache.text.Visible = canShow;
            cache.text.Font = cache.options.font;
            cache.text.Size = cache.options.fontSize;
            cache.text.Transparency = cache.options.transparency;
            cache.text.Color = cache.options.color;
            cache.text.Text = cache.options.text;
            cache.text.Position = round(screenPosition);
        end
    end);
  end

  -- Add new function to handle skeleton ESP
  function espLibrary.updateSkeleton(character, objects, show)
    if not show or not espLibrary.options.skeleton then
        -- Hide all skeleton lines if skeleton ESP is disabled
        objects.skeletonHead.Visible = false
        objects.skeletonTorso.Visible = false
        objects.skeletonLeftArm.Visible = false
        objects.skeletonRightArm.Visible = false
        objects.skeletonLeftLeg.Visible = false
        objects.skeletonRightLeg.Visible = false
        objects.skeletonUpperTorso.Visible = false
        objects.skeletonLeftUpperArm.Visible = false
        objects.skeletonRightUpperArm.Visible = false
        objects.skeletonLeftUpperLeg.Visible = false
        objects.skeletonRightUpperLeg.Visible = false
        return
    end

    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChild("Humanoid")
    if not head or not humanoid then return end

    -- Common properties for all skeleton lines
    local color = espLibrary.options.skeletonColor
    local transparency = espLibrary.options.skeletonTransparency

    -- Handle R6 and R15 differently
    if humanoid.RigType == Enum.HumanoidRigType.R6 then
        local torso = character:FindFirstChild("Torso")
        local leftArm = character:FindFirstChild("Left Arm")
        local rightArm = character:FindFirstChild("Right Arm")
        local leftLeg = character:FindFirstChild("Left Leg")
        local rightLeg = character:FindFirstChild("Right Leg")

        if torso then
            -- Head to Torso
            local headPos = worldToViewportPoint(head.Position)
            local torsoPos = worldToViewportPoint(torso.Position)
            objects.skeletonHead.From = vector2New(headPos.X, headPos.Y)
            objects.skeletonHead.To = vector2New(torsoPos.X, torsoPos.Y)
            objects.skeletonHead.Color = color
            objects.skeletonHead.Transparency = transparency
            objects.skeletonHead.Visible = show

            -- Arms
            if leftArm then
                local leftArmPos = worldToViewportPoint(leftArm.Position)
                objects.skeletonLeftArm.From = vector2New(torsoPos.X, torsoPos.Y)
                objects.skeletonLeftArm.To = vector2New(leftArmPos.X, leftArmPos.Y)
                objects.skeletonLeftArm.Color = color
                objects.skeletonLeftArm.Transparency = transparency
                objects.skeletonLeftArm.Visible = show
            end

            if rightArm then
                local rightArmPos = worldToViewportPoint(rightArm.Position)
                objects.skeletonRightArm.From = vector2New(torsoPos.X, torsoPos.Y)
                objects.skeletonRightArm.To = vector2New(rightArmPos.X, rightArmPos.Y)
                objects.skeletonRightArm.Color = color
                objects.skeletonRightArm.Transparency = transparency
                objects.skeletonRightArm.Visible = show
            end

            -- Legs
            if leftLeg then
                local leftLegPos = worldToViewportPoint(leftLeg.Position)
                objects.skeletonLeftLeg.From = vector2New(torsoPos.X, torsoPos.Y)
                objects.skeletonLeftLeg.To = vector2New(leftLegPos.X, leftLegPos.Y)
                objects.skeletonLeftLeg.Color = color
                objects.skeletonLeftLeg.Transparency = transparency
                objects.skeletonLeftLeg.Visible = show
            end

            if rightLeg then
                local rightLegPos = worldToViewportPoint(rightLeg.Position)
                objects.skeletonRightLeg.From = vector2New(torsoPos.X, torsoPos.Y)
                objects.skeletonRightLeg.To = vector2New(rightLegPos.X, rightLegPos.Y)
                objects.skeletonRightLeg.Color = color
                objects.skeletonRightLeg.Transparency = transparency
                objects.skeletonRightLeg.Visible = show
            end
        end
    else
        -- R15 Skeleton
        local upperTorso = character:FindFirstChild("UpperTorso")
        local lowerTorso = character:FindFirstChild("LowerTorso")
        local leftUpperArm = character:FindFirstChild("LeftUpperArm")
        local rightUpperArm = character:FindFirstChild("RightUpperArm")
        local leftLowerArm = character:FindFirstChild("LeftLowerArm")
        local rightLowerArm = character:FindFirstChild("RightLowerArm")
        local leftUpperLeg = character:FindFirstChild("LeftUpperLeg")
        local rightUpperLeg = character:FindFirstChild("RightUpperLeg")
        local leftLowerLeg = character:FindFirstChild("LeftLowerLeg")
        local rightLowerLeg = character:FindFirstChild("RightLowerLeg")

        if upperTorso and lowerTorso then
            -- Head to UpperTorso
            local headPos = worldToViewportPoint(head.Position)
            local upperTorsoPos = worldToViewportPoint(upperTorso.Position)
            local lowerTorsoPos = worldToViewportPoint(lowerTorso.Position)

            objects.skeletonHead.From = vector2New(headPos.X, headPos.Y)
            objects.skeletonHead.To = vector2New(upperTorsoPos.X, upperTorsoPos.Y)
            objects.skeletonHead.Color = color
            objects.skeletonHead.Transparency = transparency
            objects.skeletonHead.Visible = show

            -- Upper to Lower Torso
            objects.skeletonUpperTorso.From = vector2New(upperTorsoPos.X, upperTorsoPos.Y)
            objects.skeletonUpperTorso.To = vector2New(lowerTorsoPos.X, lowerTorsoPos.Y)
            objects.skeletonUpperTorso.Color = color
            objects.skeletonUpperTorso.Transparency = transparency
            objects.skeletonUpperTorso.Visible = show

            -- Arms
            if leftUpperArm and leftLowerArm then
                local leftUpperArmPos = worldToViewportPoint(leftUpperArm.Position)
                local leftLowerArmPos = worldToViewportPoint(leftLowerArm.Position)
                
                objects.skeletonLeftUpperArm.From = vector2New(upperTorsoPos.X, upperTorsoPos.Y)
                objects.skeletonLeftUpperArm.To = vector2New(leftUpperArmPos.X, leftUpperArmPos.Y)
                objects.skeletonLeftUpperArm.Color = color
                objects.skeletonLeftUpperArm.Transparency = transparency
                objects.skeletonLeftUpperArm.Visible = show

                objects.skeletonLeftArm.From = vector2New(leftUpperArmPos.X, leftUpperArmPos.Y)
                objects.skeletonLeftArm.To = vector2New(leftLowerArmPos.X, leftLowerArmPos.Y)
                objects.skeletonLeftArm.Color = color
                objects.skeletonLeftArm.Transparency = transparency
                objects.skeletonLeftArm.Visible = show
            end

            if rightUpperArm and rightLowerArm then
                local rightUpperArmPos = worldToViewportPoint(rightUpperArm.Position)
                local rightLowerArmPos = worldToViewportPoint(rightLowerArm.Position)
                
                objects.skeletonRightUpperArm.From = vector2New(upperTorsoPos.X, upperTorsoPos.Y)
                objects.skeletonRightUpperArm.To = vector2New(rightUpperArmPos.X, rightUpperArmPos.Y)
                objects.skeletonRightUpperArm.Color = color
                objects.skeletonRightUpperArm.Transparency = transparency
                objects.skeletonRightUpperArm.Visible = show

                objects.skeletonRightArm.From = vector2New(rightUpperArmPos.X, rightUpperArmPos.Y)
                objects.skeletonRightArm.To = vector2New(rightLowerArmPos.X, rightLowerArmPos.Y)
                objects.skeletonRightArm.Color = color
                objects.skeletonRightArm.Transparency = transparency
                objects.skeletonRightArm.Visible = show
            end

            -- Legs
            if leftUpperLeg and leftLowerLeg then
                local leftUpperLegPos = worldToViewportPoint(leftUpperLeg.Position)
                local leftLowerLegPos = worldToViewportPoint(leftLowerLeg.Position)
                
                objects.skeletonLeftUpperLeg.From = vector2New(lowerTorsoPos.X, lowerTorsoPos.Y)
                objects.skeletonLeftUpperLeg.To = vector2New(leftUpperLegPos.X, leftUpperLegPos.Y)
                objects.skeletonLeftUpperLeg.Color = color
                objects.skeletonLeftUpperLeg.Transparency = transparency
                objects.skeletonLeftUpperLeg.Visible = show

                objects.skeletonLeftLeg.From = vector2New(leftUpperLegPos.X, leftUpperLegPos.Y)
                objects.skeletonLeftLeg.To = vector2New(leftLowerLegPos.X, leftLowerLegPos.Y)
                objects.skeletonLeftLeg.Color = color
                objects.skeletonLeftLeg.Transparency = transparency
                objects.skeletonLeftLeg.Visible = show
            end

            if rightUpperLeg and rightLowerLeg then
                local rightUpperLegPos = worldToViewportPoint(rightUpperLeg.Position)
                local rightLowerLegPos = worldToViewportPoint(rightLowerLeg.Position)
                
                objects.skeletonRightUpperLeg.From = vector2New(lowerTorsoPos.X, lowerTorsoPos.Y)
                objects.skeletonRightUpperLeg.To = vector2New(rightUpperLegPos.X, rightUpperLegPos.Y)
                objects.skeletonRightUpperLeg.Color = color
                objects.skeletonRightUpperLeg.Transparency = transparency
                objects.skeletonRightUpperLeg.Visible = show

                objects.skeletonRightLeg.From = vector2New(rightUpperLegPos.X, rightUpperLegPos.Y)
                objects.skeletonRightLeg.To = vector2New(rightLowerLegPos.X, rightLowerLegPos.Y)
                objects.skeletonRightLeg.Color = color
                objects.skeletonRightLeg.Transparency = transparency
                objects.skeletonRightLeg.Visible = show
            end
        end
    end
  end

  return espLibrary;
