------------
-- PICO-ECS
-- A small entity component system
-- library built for the fantasy
-- console, PICO-8.
-- @script PICO-ECS
-- @author Joeb Rogers
-- @license MIT
-- @copyright Joeb Rogers 2018

--- A table storing various utility
-- functions used by the ECS.
utilities = {}

--- Assigns the contents of a table to another.
-- Copy over the keys and values from source 
-- tables to a target. Assign only shallow copies
-- to the target table. For a deep copy, use
-- deepAssign instead.
-- @param target The table to be copied to.
-- @param source Either a table to copy from,
-- or an array storing multiple source tables.
-- @param multiple Specifies whether source contains
-- more than one table.
-- @return The target table with overwritten and 
-- appended values.
function utilities.assign(target, source, multiple)
  multiple = multiple or false
  if multiple == true then
    for count = 1, #source do
      target = utilities.assign(target, source[count])
    end
    return target
  else
    for k, v in pairs(source) do
      target[k] = v;
    end
  end
  return target;
end

--- Deep assigns the contents of a table to another.
-- Copy over the keys and values from source 
-- tables to a target. Will recurse through child
-- tables to copy over their keys/values as well.
-- @param target The table to be copied to.
-- @param source Either a table to copy from,
-- or an array storing multiple source tables.
-- @param multiple Specifies whether source contains
-- more than one table.
-- @return The target table with overwritten and 
-- appended values.
function utilities.deepAssign(target, source, multiple)
  multiple = multiple or false
  if multiple == true then
    for count = 1, #source do
      target = utilities.deepAssign(target, source[count])
    end
    return target
  else
    for k, v in pairs(source) do
      if type(v) == "table" then
        target[k] = utilities.deepAssign({}, v)
      else
        target[k] = v;
      end
    end
  end
  return target;
end

--- Removes a string key from a table.
-- @param t The table to modify.
-- @param k The key to remove.
function utilities.tableRemoveKey(t, k)
    t[k] = nil
end

--- Unloads a scene, and loads in the specified new one.
-- @param currentScene The currently running scene.
-- @param newScene The new scene to load in.
-- @return The newly loaded in scene.
function utilities.changeScene(currentScene, newScene)
    currentScene:unload()
    currentScene = newScene
    currentScene:onLoad()
    return currentScene
end

--- A table used as the base for a 
-- reusable GameObject.
-- @field active Whether the current object 
-- should be processed. If disabled, this 
-- object won't be updated or drawn.
-- @field flagRemoval Whether the current
-- object should be flagged for removal.
-- If set to true, the object will be 
-- cleaned up once it's parent has finished
-- processing.
_baseObject = {    
    active      = true,
    flagRemoval = false
}

--- Sets an object's 'active' field.
-- @param state A bool representing what
-- the field be set to.
function _baseObject:setActive(state)
    self.active = state
end

--- Sets an object's 'flagRemoval' field.
-- @param state A bool representing what
-- the field be set to.
function _baseObject:setRemoval(state)
    self.flagRemoval = state
end

--- The number of entities currently 
-- created within the application 
-- lifetime.
ENTITY_COUNT = 0

--- A table used as a base for entities.
-- This table is also assigned the 
-- properties of _baseObject.
-- @field _components A table containing 
-- the entity's added components.
-- @field type A string containing the 
-- object's "type".
-- @field name A string containing the 
-- entity's name. Used for indexing within
-- the scene. 
_entity = {
    _components = {},
    type        = "entity",
    name        = "entity_"..ENTITY_COUNT
}

--Append the properties of _baseObject to _entity.
utilities.deepAssign(_entity, _baseObject)

--- Add a component to the entity's list of components.
-- The added component has it's parent assiged to the 
-- entity.
-- @param component The component to add.
-- @return Returns early if the component
-- isn't valid.
function _entity:addComponent(component)
    if not component or not component.type or component.type != "component" then return end

    self._components[component.name] = component
    self._components[component.name]:setParent(self)
end

--- Removes a component from the entity's list of components.
-- The specified component is flagged for removal and 
-- will be removed once the other component's have 
-- finished processing.
-- @param name The string index of the component
-- to remove.
function _entity:removeComponent(name)
    self._components[name]:setRemoval(true)
end

--- Returns a component specified by name.
-- @param name The string index of the component
-- to retrieve.
-- @return The retrieved component.
function _entity:getComponent(name)
    return self._components[name]
end

function _entity:init()
    for k, v in pairs(self._components) do
        self._components[k]:init()
    end
end

function _entity:update()
    if not self.active then return end
    for k, v in pairs(self._components) do
        if self._components[k].active then
            self._components[k]:update()
        end
    end

    for k, v in pairs(self._components) do
        if self._components[k].flagRemoval then
            utilities.tableRemoveKey(self._components, k) 
        end
    end
end

function _entity:draw()
    if not self.active then return end
    for k, v in pairs(self._components) do
        if self._components[k].active then
            self._components[k]:draw()
        end
    end
end

--/////////////////////////////
--Component
COMPONENT_COUNT = 0
_component = {
    parent = nil,
    type   = "component",
    name   = "component_"..COMPONENT_COUNT
}
utilities.deepAssign(_component, _baseObject)

function _component:init()   end
function _component:update() end
function _component:draw()   end
function _component:setParent(parent)
    self.parent = parent
end

--/////////////////////////////
--Scene
_scene = {
    _entities = {},
    type ="scene"
}

function _scene:addEntity(entity)
    if not entity or not entity.type or entity.type != "entity" then return end

    self._entities[entity.name] = entity
end

function _scene:removeEntity(name)
    self._entities[name]:setRemoval(true)
end

function _scene:getEntity(name)
    return self._entities[name]
end

function _scene:init()
    for k, v in pairs(self._entities) do
        self._entities[k]:init()
    end
end

function _scene:update()
    for k, v in pairs(self._entities) do
        if self._entities[k].active then
            self._entities[k]:update()
        end
    end

    for k, v in pairs(self._entities) do
        if self._entities[k].flagRemoval then
            utilities.tableRemoveKey(self._entities, k) 
        end
    end
end

function _scene:draw()
    for k, v in pairs(self._entities) do
        if self._entities[k].active then
            self._entities[k]:draw()
        end
    end
end

function _scene:onLoad()
    for k, v in pairs(self._entities) do
        self._entities[k]:init()
    end
end

function _scene:unload() end

--/////////////////////////////
--Factories
factory = {}

function factory.createScene(scene)
    local sc = scene or {}
    sc = utilities.deepAssign({}, {_scene, sc}, true)
    return sc
end

function factory.createEntity(entity)
    local ent = entity or {}
    ent = utilities.deepAssign({}, {_entity, ent}, true)
    ENTITY_COUNT += 1
    return ent
end

function factory.createComponent(component)
    local c = component or {}
    c = utilities.deepAssign({}, {_component, c}, true)
    COMPONENT_COUNT += 1
    return c
end