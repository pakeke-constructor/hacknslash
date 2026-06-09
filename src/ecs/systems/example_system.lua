


local exampleSystem = {}


function exampleSystem:init()
    -- store any data you want here.
    -- This system is re-initialized when a new ECSWorld is created
    self.foo = 1
end


-- `drawEntity` is an event from ev_q 
function exampleSystem:drawEntity(ent, x,y, ...)
    -- called whenever an ent is drawn
    self.foo = self.foo + 1
end



return exampleSystem
