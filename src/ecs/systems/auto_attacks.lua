


---@class g.exampleSystem: ecs.System
local autoAttacks = {}


function autoAttacks:postUpdate()
    for _,ent in self.ecs:iterate("autoAttack") do
    end
end




return autoAttacks

