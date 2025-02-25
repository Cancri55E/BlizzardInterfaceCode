local mainTextureKitRegions = {
	-- Added in SetUpMajorFactionData after expansion has been determined
	-- ["Background"] = "%s-MajorFactions-%s-Background"
	["TopGlow"] = "UI-%s-Highlight-Top",
	["BottomGlow"] = "UI-%s-Highlight-Bottom",
};
local headerTextureKitRegions = {
	["Background"] = "UI-%s-HeaderOrb",
};
local trackTextureKitRegions = {
	["Glow"] = "UI-%s-Highlight-Middle",
};

-- Animated Effects behind the renown reward;
local finalToastSwirlEffects = {
};

local ExpansionLayoutInfo =
{
	[LE_EXPANSION_DRAGONFLIGHT] = {
		useOldNineSlice = true,
		textureKit = "Dragonflight",
		renownFrameDecorations = {
			["TopLeftBorderDecoration"] = "Dragonflight-DragonHeadLeft",
			["TopRightBorderDecoration"] = "Dragonflight-DragonHeadRight",
			["BottomBorderDecoration"] = "dragonflight-golddetailbottom",
		},
		renownFrameDecorationAnchors = {
			["TopLeftBorderDecoration"] = { x = -40, y = 8, },
			["TopRightBorderDecoration"] = { x = 40, y = 8, },
			["BottomBorderDecoration"] = { x = 0, y = 10, },
		},
		closeButtonOffset = { x = -1, y = -6 },
	},
	[LE_EXPANSION_WAR_WITHIN] = {
		textureKit = "thewarwithin",
		borderAnchors = {
			["TOPLEFT"] = { x = -6, y = 6, relativePoint = "TOPLEFT" },
			["BOTTOMRIGHT"] = { x = 6, y = -6, relativePoint = "BOTTOMRIGHT" },
		},
		renownFrameDecorations = {
			["TopLeftBorderDecoration"] = "ui-frame-thewarwithin-embellishmentleft",
			["TopRightBorderDecoration"] = "ui-frame-thewarwithin-embellishmentright",
			["BottomBorderDecoration"] = "ui-frame-thewarwithin-embellishmentbottom",
		},
		renownFrameDecorationAnchors = {
			["TopLeftBorderDecoration"] = { x = -110, y = 17, point = "TOP", relativePoint = "TOP" },
			["TopRightBorderDecoration"] = { x = 110, y = 17, point = "TOP", relativePoint = "TOP" },
			["BottomBorderDecoration"] = { x = 0, y = 0, point = "BOTTOM", relativePoint = "BOTTOM" },
		},
		closeButtonOffset = { x = -9, y = -9 },
	},
};

local TextureKitOverrideLayoutInfo =
{
	["plunderstorm"] = {
		useOldNineSlice = true,
		textureKit = "plunderstorm",
		renownFrameDecorations = {
			["TopLeftBorderDecoration"] = "plunderstorm-wavesleft",
			["TopRightBorderDecoration"] = "plunderstorm-wavesright",
			["BottomBorderDecoration"] = "plunderstorm-decalbottom",
		},
		renownFrameDecorationAnchors = {
			["TopLeftBorderDecoration"] = { x = 9, y = 19, },
			["TopRightBorderDecoration"] = { x = -9, y = 19, },
			["BottomBorderDecoration"] = { x = 0, y = 4, },
		},
		closeButtonOffset = { x = -1, y = -6 },
	},
};

local MajorFactionsLayout =
{
	["TopRightCorner"] = { atlas = "%s-NineSlice-CornerTopRight" },
	["TopLeftCorner"] = { atlas = "%s-NineSlice-CornerTopLeft" },
	["BottomLeftCorner"] = { atlas = "%s-NineSlice-CornerBottomLeft" },
	["BottomRightCorner"] = { atlas = "%s-NineSlice-CornerBottomRight" },
	["TopEdge"] = nil, -- Using a custom top border,
	["BottomEdge"] = { atlas = "_%s-NineSlice-EdgeBottom" },
	["LeftEdge"] = { atlas = "!%s-NineSlice-EdgeLeft" },
	["RightEdge"] = { atlas = "!%s-NineSlice-EdgeRight" },
	["Center"] = { atlas = "%s-NineSlice-Center" },
};

local levelEffectDelay = 0.5;

local currentFactionID;
local currentFactionData;

local function SetupTextureKit(frame, regions)
	SetupTextureKitOnRegions(currentFactionData.textureKit, frame, regions, TextureKitConstants.SetVisibility, TextureKitConstants.UseAtlasSize);
end

local function ClearRenownFrameNineSlice(frame)
	local previousLayoutInfo = frame.layoutInfo;
	if not previousLayoutInfo then
		return;
	end

	local useNewNineSlice = not previousLayoutInfo.useOldNineSlice;

	if useNewNineSlice then
		-- Hide all border decoration textures defined in the previous layout info in case they're not used in in the new layout info.
		for textureKey, atlas in pairs(previousLayoutInfo.renownFrameDecorations) do
			local texture = frame[textureKey];
			if texture then
				texture:SetShown(false);
			end
		end
	end
end

local function SetupRenownFrameNineSlice(frame)
	local layoutInfo = frame.layoutInfo;
	if not layoutInfo then
		return;
	end

	local textureKit = layoutInfo.textureKit;

	-- For backwards compatibility, support art set up in either old or new nineSlice format.
	local useNewNineSlice = not layoutInfo.useOldNineSlice;

	frame.NineSlice:SetShown(not useNewNineSlice);
	frame.Border:SetShown(useNewNineSlice);

	if useNewNineSlice then
		local borderFile = "UI-Frame-%s-Border";
		frame.Border:SetAtlas(borderFile:format(textureKit));

		-- Apply the anchoring data defined in the layout info for the Border texture.
		frame.Border:ClearAllPoints();
		for anchorKey, anchorPoint in pairs(layoutInfo.borderAnchors) do
			frame.Border:SetPoint(anchorKey, frame, anchorPoint.relativePoint, anchorPoint.x, anchorPoint.y);
		end

		-- Apply the atlas and anchoring data defined in the layout info for all border decoration textures.
		for textureKey, atlas in pairs(layoutInfo.renownFrameDecorations) do
			local texture = frame[textureKey];
			if texture then
				texture:SetAtlas(atlas, TextureKitConstants.UseAtlasSize);
				texture:SetShown(true);

				local anchorPoint = layoutInfo.renownFrameDecorationAnchors[textureKey];
				if anchorPoint then
					texture:ClearAllPoints();
					texture:SetPoint(anchorPoint.point, frame, anchorPoint.relativePoint, anchorPoint.x, anchorPoint.y);
				end
			end
		end
	else
		NineSliceUtil.ApplyLayout(frame.NineSlice, MajorFactionsLayout, textureKit);
		NineSliceUtil.DisableSharpening(frame.NineSlice);

		-- Set up the custom top border
		local topBorderFormat = "_%s-NineSlice-EdgeTop";
		frame.NineSlice.TopLeftBorder:SetAtlas(topBorderFormat:format(textureKit), TextureKitConstants.IgnoreAtlasSize);
		frame.NineSlice.TopLeftBorder:ClearAllPoints();
		frame.NineSlice.TopLeftBorder:SetPoint("TOPLEFT", frame.NineSlice.TopLeftCorner, "TOPRIGHT");
		frame.NineSlice.TopRightBorder:SetAtlas(topBorderFormat:format(textureKit), TextureKitConstants.IgnoreAtlasSize);
		frame.NineSlice.TopRightBorder:ClearAllPoints();
		frame.NineSlice.TopRightBorder:SetPoint("TOPRIGHT", frame.NineSlice.TopRightCorner, "TOPLEFT");

		local renownFrameDecorations = layoutInfo.renownFrameDecorations;
		if renownFrameDecorations then
			SetupAtlasesOnRegions(frame.NineSlice, renownFrameDecorations, TextureKitConstants.UseAtlasSize);

			for regionKey, offsets in pairs(layoutInfo.renownFrameDecorationAnchors) do
				local region = frame.NineSlice[regionKey];
				region:ClearPointsOffset();
				region:AdjustPointsOffset(offsets.x, offsets.y);
			end
		end
	end

	if layoutInfo.closeButtonOffset then
		frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", layoutInfo.closeButtonOffset.x, layoutInfo.closeButtonOffset.y);
	end
end

MajorFactionRenownMixin = {};

local MajorFactionRenownEvents = {
	"MAJOR_FACTION_RENOWN_LEVEL_CHANGED",
	"MAJOR_FACTION_UNLOCKED",
	"UPDATE_FACTION",
};

function MajorFactionRenownMixin:OnLoad()
	local attributes =
	{
		area = "left",
		pushable = 0,
		allowOtherPanels = 1,
		width = 820,
		height = 578,
		yoffset = -2,
		whileDead = 1,
	};
	RegisterUIPanel(MajorFactionRenownFrame, attributes);
	
	self.rewardsPool = CreateFramePool("FRAME", self, "MajorFactionRenownRewardTemplate");

	EventRegistry:RegisterCallback("MajorFactionRenownMixin.MajorFactionRenownRequest", self.SetMajorFaction, self);
end

function MajorFactionRenownMixin:SetMajorFaction(majorFactionID)
	self.majorFactionID = majorFactionID;
	EventRegistry:TriggerEvent("MajorFactionRenownMixin.RenownTrackFactionChanged", majorFactionID);
end

function MajorFactionRenownMixin:GetCurrentFactionID()
	return self.majorFactionID;
end

function MajorFactionRenownMixin:OnShow()
	self:SetUpMajorFactionData();
	self:GetLevels();
	local fromOnShow = true;
	self:Refresh(fromOnShow);
	self:CheckTutorials();
	FrameUtil.RegisterFrameForEvents(self, MajorFactionRenownEvents);

	PlaySound(SOUNDKIT.UI_MAJOR_FACTION_RENOWN_OPEN_WINDOW);
end

function MajorFactionRenownMixin:OnHide()
	self.majorFactionID = nil;
	EventRegistry:TriggerEvent("MajorFactionRenownMixin.RenownTrackFactionChanged", nil);
	FrameUtil.UnregisterFrameForEvents(self, MajorFactionRenownEvents);
	self:SetCelebrationSwirlEffects(nil);
	self:CancelLevelEffect();

	local cvarName = "lastRenownForMajorFaction".. currentFactionID;
	local lastSeenRenownLevel = tonumber(GetCVar(cvarName)) or 0;
	-- We should only update the CVar when the value is higher than what we have stored
	-- For cases where renown is account wide, we want to remember the highest level you've seen on any character
	local shouldOverwriteLastSeenRenown = self.actualLevel > lastSeenRenownLevel;
	if shouldOverwriteLastSeenRenown then
		SetCVar(cvarName, self.actualLevel);
	end

	C_PlayerInteractionManager.ClearInteraction(Enum.PlayerInteractionType.MajorFactionRenown);

	currentFactionID = nil;
	PlaySound(SOUNDKIT.UI_MAJOR_FACTION_RENOWN_CLOSE_WINDOW);
end

function MajorFactionRenownMixin:OnEvent(event, ...)
	if event == "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" then
		self:Refresh();
	elseif event == "MAJOR_FACTION_UNLOCKED" then
		HideUIPanel(self);
	elseif event == "UPDATE_FACTION" then
		self:RefreshCurrentFactionData();
		self.HeaderFrame.RenownProgressBar:RefreshBar();
	end
end

function MajorFactionRenownMixin:OnMouseWheel(direction)
	local track = self.TrackFrame;
	local centerIndex = track:GetCenterIndex();
	centerIndex = centerIndex + (direction * -1);
	local forceRefresh = false;
	local skipSound = false;
	local overrideStopSound = SOUNDKIT.UI_MAJOR_FACTION_RENOWN_SLIDE_START;
	track:SetSelection(centerIndex, forceRefresh, skipSound, overrideStopSound);
end

function MajorFactionRenownMixin:RefreshCurrentFactionData()
	if currentFactionID then
		currentFactionData = C_MajorFactions.GetMajorFactionData(currentFactionID);
	end
end

function MajorFactionRenownMixin:SetUpMajorFactionData()
	local majorFactionID = self.majorFactionID;
	local majorFactionData = C_MajorFactions.GetMajorFactionData(majorFactionID);
	if currentFactionID ~= majorFactionID then
		currentFactionID = majorFactionID;
		currentFactionData = majorFactionData;

		ClearRenownFrameNineSlice(self);

		self.layoutInfo = TextureKitOverrideLayoutInfo[currentFactionData.textureKit] or ExpansionLayoutInfo[currentFactionData.expansionID];
		SetupRenownFrameNineSlice(self);

		local factionTextureKit = currentFactionData.textureKit;
		local renownFrameTextureKitRegions = mainTextureKitRegions;
		local backgroundFormat = self.layoutInfo.textureKit .. "-MajorFactions-%s-Background";
		renownFrameTextureKitRegions.Background = backgroundFormat;
		SetupTextureKit(self, renownFrameTextureKitRegions);

		SetupTextureKit(self.HeaderFrame, headerTextureKitRegions);
		local majorFactionIconFormat = "majorFactions_icons_%s512";
		self.HeaderFrame.Icon:SetAtlas(majorFactionIconFormat:format(factionTextureKit), TextureKitConstants.IgnoreAtlasSize);

		-- the track
		local renownLevelsInfo = C_MajorFactions.GetRenownLevels(majorFactionID);
		for i, levelInfo in ipairs(renownLevelsInfo) do
			levelInfo.rewardInfo = C_MajorFactions.GetRenownRewardsForLevel(majorFactionID, i);
		end
		self.TrackFrame:Init(renownLevelsInfo);

		self.TrackFrame.Title:SetText(majorFactionData.name or "");
		local isAccountWideReputation = C_Reputation.IsAccountWideReputation(majorFactionID);
		self.TrackFrame.Title:SetPoint("BOTTOM", self.TrackFrame, "TOP", 0, isAccountWideReputation and 20 or 15);
		self.TrackFrame.AccountWideLabel:SetShown(isAccountWideReputation);

		SetupTextureKit(self.TrackFrame, trackTextureKitRegions);

		self.maxLevel = renownLevelsInfo[#renownLevelsInfo].level;
	end
end

function MajorFactionRenownMixin:GetLevels()
	local renownLevel = C_MajorFactions.GetCurrentRenownLevel(currentFactionID);
	self.actualLevel = renownLevel;	
	local cvarName = "lastRenownForMajorFaction"..currentFactionID;
	local lastRenownLevel = tonumber(GetCVar(cvarName)) or 1;
	if lastRenownLevel < renownLevel then
		renownLevel = lastRenownLevel;
	end
	self.displayLevel = renownLevel;
end

function MajorFactionRenownMixin:Refresh(fromOnShow)
	self.HeaderFrame.Level:SetText(self.actualLevel);
	local displayLevel = math.min(self.displayLevel + 1, self.maxLevel);
	self:SetRewards(displayLevel);
	local forceRefresh = true;
	self:SelectLevel(displayLevel, fromOnShow, forceRefresh);
	self.LevelSkipButton:SetShown((self.actualLevel - self.displayLevel) > 3);
	if self.displayLevel < self.actualLevel then
		self.levelEffectTimer = C_Timer.NewTimer(levelEffectDelay, function()
			self:PlayLevelEffect();
		end);
	end
	self.HeaderFrame.RenownProgressBar:RefreshBar();
	self:CheckTutorials();
end

function MajorFactionRenownMixin:SelectLevel(level, fromOnShow, forceRefresh)
	local selectionIndex;
	local elements = self.TrackFrame:GetElements();
	for i, frame in ipairs(elements) do
		if frame:GetLevel() == level then
			selectionIndex = i;
			break;
		end
	end
	local skipSound = fromOnShow;
	self.TrackFrame:SetSelection(selectionIndex, forceRefresh, skipSound);
end

function MajorFactionRenownMixin:OnTrackUpdate(leftIndex, centerIndex, rightIndex, isMoving)
	local track = self.TrackFrame;
	local elements = track:GetElements();
	local selectedElement = elements[centerIndex];
	local selectedLevel = selectedElement:GetLevel();
	if self.displayLevel ~= self.actualLevel and selectedLevel ~= self.displayLevel + 1 then
		self:CancelLevelEffect();
		self:Refresh();
		return;
	end
	for i = leftIndex, rightIndex do
		local selected = not self.moving and centerIndex == i;
		local frame = elements[i];
		frame:Refresh(self.actualLevel, self.displayLevel, selected);
		local alpha = track:GetDesiredAlphaForIndex(i);
		frame:ApplyAlpha(alpha);
	end
	if not isMoving then
		self:SetRewards(selectedLevel);
	end
end

function MajorFactionRenownMixin:OnLevelEffectFinished()
	self.levelEffect = nil;
	self.displayLevel = self.displayLevel + 1;
	self:Refresh();
end

function MajorFactionRenownMixin:PlayLevelEffect()
	if not currentFactionData or not currentFactionData.renownTrackLevelEffectID then
		return;
	end

	local target, onEffectFinish = nil, nil;
	local onEffectResolution = GenerateClosure(self.OnLevelEffectFinished, self);
	self.levelEffect = self.LevelModelScene:AddEffect(currentFactionData.renownTrackLevelEffectID, self.TrackFrame, self.TrackFrame, onEffectFinish, onEffectResolution);

	local centerIndex = self.TrackFrame:GetCenterIndex();
	local elements = self.TrackFrame:GetElements();
	local frame = elements[centerIndex];
	local selected = true;
	frame:Refresh(self.actualLevel, self.displayLevel + 1, selected);

	local fanfareSound = currentFactionData.renownFanfareSoundKitID;
	if fanfareSound then
		PlaySound(fanfareSound);
	end
end

function MajorFactionRenownMixin:CancelLevelEffect()
	self.LevelSkipButton:Hide();
	if self.displayLevel ~= self.actualLevel then
		self.displayLevel = self.actualLevel;
		if self.levelEffect then
			self.levelEffect:CancelEffect();
			self.levelEffect = nil;
		end
		if self.levelEffectTimer then
			self.levelEffectTimer:Cancel();
			self.levelEffectTimer = nil;
		end
		self.displayLevel = self.actualLevel;
	end
end

function MajorFactionRenownMixin:SetCelebrationSwirlEffects(swirlEffects)
	if swirlEffects == nil then
		self.CelebrationModelScene:ClearEffects();
	elseif not self.CelebrationModelScene:HasActiveEffects() then
		for i, swirlEffect in ipairs(swirlEffects) do
			self.CelebrationModelScene:AddEffect(swirlEffect, self.CelebrationModelSceneTarget);
		end
	end
end

function MajorFactionRenownMixin:SetRewards(level)
	self.rewardsPool:ReleaseAll();
	local rewards = C_MajorFactions.GetRenownRewardsForLevel(currentFactionID, level);
	local numRewards = #rewards;

	local renownLevel = C_MajorFactions.GetCurrentRenownLevel(currentFactionID);
	local rewardUnlocked = level <= renownLevel;

	for i, rewardInfo in ipairs(rewards) do
		-- We can only display up to 4 rewards at once in the UI
		-- Todo: Add priority system to determine the "best" 4 rewards to show
		if i > 4 then
			break;
		end

		local rewardFrame = self.rewardsPool:Acquire();
		rewardFrame:SetScale((numRewards > 1 and 0.8 or 1), (numRewards > 1 and 0.8 or 1));
		if numRewards == 1 then
			rewardFrame:SetPoint("TOP", 0, -345);
		elseif numRewards == 2 then 
			if i == 1 then
				rewardFrame:SetPoint("TOP", 0, -380);
			elseif i == 2 then
				rewardFrame:SetPoint("TOP", 0, -508);
			end
		else
			if i == 1 then
				rewardFrame:SetPoint("TOP", -229, -380);
			elseif i == 2 then
				rewardFrame:SetPoint("TOP", 229, -380);
			elseif i == 3 then
				rewardFrame:SetPoint("TOP", -229, -508);
			elseif i == 4 then
				rewardFrame:SetPoint("TOP", 229, -508);
			end
		end
		rewardFrame:SetReward(rewardInfo, rewardUnlocked, currentFactionData.textureKit);
	end

	if level <= renownLevel then
		self:SetCelebrationSwirlEffects(finalToastSwirlEffects[currentFactionData.textureKit]);
	else
		self:SetCelebrationSwirlEffects(nil);
	end
end

function MajorFactionRenownMixin:CheckTutorials()
	-- using acknowledgeOnHide so need to check this
	if not self:IsShown() then
		return;
	end
	
	if not GetCVarBitfield("closedInfoFrames", LE_FRAME_TUTORIAL_MAJOR_FACTION_RENOWN_PROGRESS) then
		local helpTipInfo = {
			text = MAJOR_FACTION_RENOWN_TUTORIAL_PROGRESS,
			buttonStyle = HelpTip.ButtonStyle.Close,
			cvarBitfield = "closedInfoFrames",
			bitfieldFlag = LE_FRAME_TUTORIAL_MAJOR_FACTION_RENOWN_PROGRESS,
			targetPoint = HelpTip.Point.RightEdgeCenter,
			alignment = HelpTip.Alignment.Center,
			acknowledgeOnHide = true,
		};
		HelpTip:Show(self, helpTipInfo, self.HeaderFrame.RenownProgressBar);
	end
end

MajorFactionRenownHeaderFrameMixin = {}; 

function MajorFactionRenownHeaderFrameMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", -40, 130);

	if self:GetParent():GetCurrentFactionID() == Constants.MajorFactionsConsts.PLUNDERSTORM_MAJOR_FACTION_ID then
		GameTooltip_AddNormalLine(GameTooltip, PLUNDERSTORM_RENOWN_LEVEL_TOOLTIP);
	else
		local majorFactionName = currentFactionData.name;
		GameTooltip_AddNormalLine(GameTooltip, MAJOR_FACTION_RENOWN_LEVEL_TOOLTIP:format(majorFactionName));
	end

	if not C_MajorFactions.HasMaximumRenown(currentFactionID) then
		GameTooltip_AddNormalLine(GameTooltip, MAJOR_FACTION_RENOWN_CURRENT_PROGRESS:format(currentFactionData.renownReputationEarned, currentFactionData.renownLevelThreshold));
	end

	EventRegistry:TriggerEvent("MajorFactionRenown.Header.OnEnter", self, GameTooltip, currentFactionID);
	GameTooltip:Show();
end 

function MajorFactionRenownHeaderFrameMixin:OnLeave()
	GameTooltip:Hide();
end 

MajorFactionRenownTrackProgressBarMixin = {};

function MajorFactionRenownTrackProgressBarMixin:OnLoad()
	CooldownFrame_SetDisplayAsPercentage(self, 0);
end

function MajorFactionRenownTrackProgressBarMixin:RefreshBar()
	-- Show a full bar if we have max renown
	local currentValue = C_MajorFactions.HasMaximumRenown(currentFactionID) and currentFactionData.renownLevelThreshold or currentFactionData.renownReputationEarned;
	local maxValue = currentFactionData.renownLevelThreshold;
	if not currentValue or not maxValue or maxValue == 0 then
		return;
	end

	local fillArtAtlas= "UI-%s-HeaderFill";
	local fillInfo = C_Texture.GetAtlasInfo(fillArtAtlas:format(currentFactionData.textureKit));
	self:SetSwipeTexture(fillInfo.file or fillInfo.filename);
	local lowTexCoords =
	{
		x = fillInfo.leftTexCoord,
		y = fillInfo.topTexCoord,
	};
	local highTexCoords =
	{
		x = fillInfo.rightTexCoord,
		y = fillInfo.bottomTexCoord,
	};	
	self:SetTexCoordRange(lowTexCoords, highTexCoords);

	local renownProgressPercentage = (currentValue / maxValue);
	-- The bottom portion of the circular progress bar is covered by the renown level
	-- Because of this, the progress bar fill art is a semi circle and we need some special logic to determine the correct display percentage
	local barPercentageCovered = 0.16;
	local barDegreesCovered = 360 * barPercentageCovered;
	local barDegreesVisible = 360 - barDegreesCovered;
	local finalDisplayPercentage = ((renownProgressPercentage * barDegreesVisible) + (barDegreesCovered / 2)) / 360;
	CooldownFrame_SetDisplayAsPercentage(self, finalDisplayPercentage);
end
