local EventFrame = CreateFrame("Frame")

EventFrame:RegisterEvent("PLAYER_LOGIN")

EventFrame:SetScript("OnEvent", function(self,event,...) 

if SimpleMap == true then
   PlayerMovementFrameFader.AddDeferredFrame(WorldMapFrame, .3, 3.0, .5)
elseif SimpleMap == false then
   PlayerMovementFrameFader.AddDeferredFrame(WorldMapFrame, 1, 3.0, .5)
else
   PlayerMovementFrameFader.AddDeferredFrame(WorldMapFrame, .3, 3.0, .5)
   SimpleMap = true
end

end)

WorldMapFrame:SetScale(0.8)
WorldMapFrame.BlackoutFrame.Blackout:SetAlpha(0)
WorldMapFrame.BlackoutFrame:EnableMouse(false)

WorldMapFrame.ScrollContainer.GetCursorPosition = function(f)
   local x,y = MapCanvasScrollControllerMixin.GetCursorPosition(f);
   local s = WorldMapFrame:GetScale();
   return x/s, y/s;
end

local function SimpleMapCommands(msg, editbox)
   if msg == 'off' then
      print('SimpleMap fade has been turned off.')
      PlayerMovementFrameFader.AddDeferredFrame(WorldMapFrame, 1, 3.0, .5)
      SimpleMap = false
   elseif msg == 'on' then
      print('SimpleMap fade has been turned on.')
      PlayerMovementFrameFader.AddDeferredFrame(WorldMapFrame, .3, 3.0, .5)
      SimpleMap = true
   end
end

SlashCmdList["SMFADE"] = SimpleMapCommands

SLASH_SMFADE1 = '/smfade'

