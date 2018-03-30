pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

------------
-- PICO-EC - 
-- A small scene/entity/component
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
-- @param multipleSource Specifies whether source
-- contains more than one table.
-- @param exclude Either a string or an array of
-- string containing keys to exclude from copying.
-- @param multipleExclude Specifies whether exclude
-- contains more than one string.
-- @return The target table with overwritten and 
-- appended values.
function utilities.deepAssign(target, source, multipleSource, exclude, multipleExclude)
    multipleSource = multipleSource or false
    exclude = exclude or nil
    multipleExclude = multipleExclude or false

    if multipleSource then
        for count = 1, #source do
            target = utilities.deepAssign(target, source[count], false, exclude, multipleExclude)
        end
        return target
    else
        for k, v in pairs(source) do
            local match = false
            if multipleExclude then
                for count = 1, #exclude do
                    if (k == exclude[count]) match = true
                end
            elseif exclude then
                if (k == exclude) match = true
            end
            if not match then
                if type(v) == "table" then
                    target[k] = utilities.deepAssign({}, v, false, exclude, multipleExclude)
                else
                    target[k] = v;
                end
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
-- This table can be combined with a 
-- custom entity object with overwritten
-- fields and functions when the
-- createEntity() function is called.
-- @field _components A table containing 
-- the entity's added components.
-- @field _componentsIndexed A table 
-- containing the entity's added 
-- components, indexed in the order
-- they were added to the entity.
-- @field type A string containing the 
-- object's "type".
-- @field name A string containing the 
-- entity's name. Used for indexing within
-- the scene. 
-- @field ind The index of this entity's
-- position within the scene's ordererd
-- array.
_entity = {
    _components        = {},
    _componentsIndexed = {},
    type               = "entity",
    name               = "entity_"..ENTITY_COUNT,
    ind                = 0
}

-- Append the properties of _baseObject to _entity.
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
    add(self._componentsIndexed, component)
    component.ind = #self._componentsIndexed
    self._components[component.name]:setParent(self)
    self._components[component.name]:onAddedToEntity()
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

--- Called when the entity is added to a
-- scene with the addEntity() function.
-- Has no default behaviour, should be 
-- overwritten by a custom entity.
function _entity:onAddedToScene() end

--- Calls init() on all of an entity's components.
function _entity:init()
    for v in all(self._componentsIndexed) do
        v:init()
    end
end

--- Calls update() on all of an entity's components.
-- Loops back around once all components have been 
-- updated to remove any components that have been
-- flagged.
-- @return Will return early if the entity isn't
-- active.
-- @return Will return before resetting indexes
-- if no objects have been removed.
function _entity:update()
    if not self.active then return end

    local reIndex = false

    for v in all(self._componentsIndexed) do
        if v.active then
            v:update()
        end
    end

    for v in all(self._componentsIndexed) do
        if v.flagRemoval then
            utilities.tableRemoveKey(self._components, v.name)
            del(self._componentsIndexed, v)
        end
    end

    if (not reIndex) return

    local i = 1
    for v in all(self._componentsIndexed) do
        v.ind = i
        i += 1
    end
end

--- Calls draw() on all of an entity's components.
-- @return Will return early if the entity isn't
-- active.
function _entity:draw()
    if not self.active then return end
    for v in all(self._componentsIndexed) do
        if v.active then
            v:draw()
        end
    end
end

--- The number of components currently 
-- created within the application 
-- lifetime.
COMPONENT_COUNT = 0

--- A table used as a base for components.
-- This table is also assigned the 
-- properties of _baseObject.
-- This table can be combined with a 
-- custom component object with overwritten
-- fields and functions when the
-- createComponent() function is called.
-- This is the intended method for creating
-- custom behaviours.
-- @field parent A reference to the entity
-- that contains this component.
-- @field type A string containing the 
-- object's "type".
-- @field name A string containing the 
-- component's name. Used for indexing 
-- within the parent entity. 
-- @field ind The index of this component's
-- position within the entity's ordererd
-- array.
_component = {
    parent = nil,
    type   = "component",
    name   = "component_"..COMPONENT_COUNT,
    ind    = 0
}

-- Append the properties of _baseObject to _component.
utilities.deepAssign(_component, _baseObject)

--- Called when the component is added to
-- an entity with the addComponent() function.
-- Has no default behaviour, should be 
-- overwritten by a custom component.
function _component:onAddedToEntity() end

--- A function to initialise the component.
-- init is a placeholder that can be overwritten
-- upon creation of a component. Will be called
-- once when the application calls _init() and
-- when a new scene's onLoad() function is
-- called.
function _component:init() end

--- A function to update the component.
-- update is a placeholder that can be overwritten
-- upon creation of a component. Will be called
-- every frame when the application calls _update().
function _component:update() end

--- A function to draw the component.
-- draw is a placeholder that can be overwritten
-- upon creation of a component. Will be called
-- every frame when the application calls _draw().
function _component:draw() end

--- Sets a reference to the component's parent
-- entity.
-- @param parent The entity containing this 
-- component.
function _component:setParent(parent)
    self.parent = parent
end

--- A table used as a base for scenes.
-- This table can be combined with a 
-- custom scene object with overwritten
-- fields and functions when the
-- createScene() function is called.
-- @field _entities A list of all the
-- entities currently added to this
-- scene.
-- @field _entitiesIndexed A table 
-- containing the scenes's added 
-- entities, indexed in the order
-- they were added to the scene.
-- @field type A string containing the 
-- object's "type".
_scene = {
    _entities        = {},
    _entitiesIndexed = {},
    type             ="scene"
}

--- Adds an entity to this scene's entity list.
-- @param entity The entity to add.
-- @return Will return early if the entity is
-- invalid.
function _scene:addEntity(entity)
    if not entity or not entity.type or entity.type != "entity" then return end

    self._entities[entity.name] = entity
    add(self._entitiesIndexed, entity)
    entity.ind = #self._entitiesIndexed
    self._entities[entity.name]:onAddedToScene()
end

--- Flags an entity for removal from the scene.
-- @param name The name the entity is indexed
-- by within the scene.
function _scene:removeEntity(name)
    self._entities[name]:setRemoval(true)
end

--- Returns the entity within the scene with
-- the passed in name.
-- @param name The name the entity is indexed
-- by within the scene.
-- @return The retrieved entity.
function _scene:getEntity(name)
    return self._entities[name]
end

--- Calls init() on all of the scene's entities.
function _scene:init()
    for v in all(self._entitiesIndexed) do
        v:init()
    end
end

--- Calls update() on all of an scene's entities.
-- Entity is skipped if not active.
-- Loops back around once all entities have been 
-- updated to remove any entities that have been
-- flagged.
-- @return Will return before resetting indexes
-- if no objects have been removed.
function _scene:update()
    local reIndex = false

    for v in all(self._entitiesIndexed) do
        if v.active then
            v:update()
        end
    end

    for v in all(self._entitiesIndexed) do
        if v.flagRemoval then
            utilities.tableRemoveKey(self._entities, v.name)
            del(self._entitiesIndexed, v)
            reIndex = true
        end
    end

    if (not reIndex) return

    local i = 1
    for v in all(self._entitiesIndexed) do
        v.ind = i
        i += 1
    end
end

--- Calls draw() on all of an scene's entities.
-- Entity is skipped if not active.
function _scene:draw()
    for v in all(self._entitiesIndexed) do
        if v.active then
            v:draw()
        end
    end
end

--- Function called when the scene is loaded
-- in as the active scene.
-- By default calls init() on all of it's 
-- stored entities. If planning to overwrite
-- the onLoad() function with a custom scene,
-- this behvaiour should be copied over to
-- the new scene, else no entities or 
-- components will be initialised unless the
-- scene is the loaded in the application 
-- _init().
function _scene:onLoad()
    for k, v in pairs(self._entities) do
        self._entities[k]:init()
    end
end

--- Function called during the change to a
-- new scene. To be overwritten if any 
-- custom behaviours need special 
-- attention before being removed.
function _scene:unload() end

--- A table storing various factory
-- functions used by the ECS.
factory = {}

--- Creates and returns a new scene object.
-- Will either return a new default scene or
-- one combined with a passed in custom scene.
-- @param scene A custom scene to combine with
-- the default scene.
-- @return The created scene object.
function factory.createScene(scene)
    local sc = scene or {}
    sc = utilities.deepAssign({}, {_scene, sc}, true)
    return sc
end

--- Creates and returns a new entity object.
-- Will either return a new default entity or
-- one combined with a passed in custom entity.
-- Also increments the global entity count.
-- @param entity A custom entity to combine with
-- the default entity.
-- @return The created entity object.
function factory.createEntity(entity)
    local ent = entity or {}
    ent = utilities.deepAssign({}, {_entity, ent}, true)
    ENTITY_COUNT += 1
    return ent
end

--- Creates and returns a new component object.
-- Will either return a new default component or
-- one combined with a passed in custom component.
-- Also increments the global component count.
-- @param component A custom component to combine 
-- with the default component.
-- @return The created component object.
function factory.createComponent(component)
    local c = component or {}
    c = utilities.deepAssign({}, {_component, c}, true)
    COMPONENT_COUNT += 1
    return c
end

-------------------------------------------------

-- Transform
_transformComponent = {
  name = "Transform",
  x = 0,
  y = 0
}

-- Rect
_rectComponent = {
  name = "Rect",
  transform = nil,
  w = 0,
  h = 0,
  color = 0
}

function _rectComponent:setColor(col)
  self.color = col
end

function _rectComponent:setSize(w, h)
  self.w = w or 0
  self.h = h or 0
end

function _rectComponent:init()
  self.transform = self.parent:getComponent("Transform")
end

function _rectComponent:draw()
  local x = self.transform.x
  local y = self.transform.y
  local w = x + self.w
  local h = y + self.h
  rectfill(x, y, w, h, self.color)
end

-- Mover
_moverComponent = {
  name = "Mover",
  transform = nil
}

function _moverComponent:init()
  self.transform = self.parent:getComponent("Transform")
end

function _moverComponent:update()
  if (btn(0)) self.transform.x -= 1
  if (btn(1)) self.transform.x += 1
  if (btn(2)) self.transform.y -= 1
  if (btn(3)) self.transform.y += 1
end

-- Main

-- Create scenes and entities
local movingRectScene = factory.createScene()
local backgroundEnt = factory.createEntity()
local playerEnt = factory.createEntity()

-- Create components for background rect
backgroundEnt:addComponent(factory.createComponent(_transformComponent))
backgroundEnt:addComponent(factory.createComponent(_rectComponent))
--Let's set the player's size
backgroundEnt:getComponent("Rect"):setSize(128, 128)
--Let's change the color of the background
backgroundEnt:getComponent("Rect"):setColor(5)

-- Create components for player rect
playerEnt:addComponent(factory.createComponent(_transformComponent))
playerEnt:addComponent(factory.createComponent(_rectComponent))
playerEnt:addComponent(factory.createComponent(_moverComponent))
--Let's set the player's size
playerEnt:getComponent("Rect"):setSize(5, 5)
--Let's change the color of the player
playerEnt:getComponent("Rect"):setColor(15)

mainScene = movingRectScene
mainScene:addEntity(backgroundEnt)
mainScene:addEntity(playerEnt)

function _init()
  mainScene:init()
end

function _update()
  mainScene:update()
end

function _draw()
  mainScene:draw()
end