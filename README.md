# PICO-EC

PICO-EC aims to provide very basic and simple support for Scenes, Entities and Components within PICO-8.

- The library offers a simple solution to creating custom objects with init, update and draw cycles that
run off of the main application states without having to manually maintain and direct their lifecycles.

- Objects can then be manipulated through custom defined behvaiours. This allows for easy abstraction of
generic behaviours and properties.

- The library itself doesn't ship with any default behaviours, however a selection of some that I think
may be useful, including sprites, animations, transforms and physics can be found here. [To be added]

## Setup

Like any PICO-8 library, integrating this library into your cart is as simple as copy/pasting the source
into the top of your code (I recommend the top in order to avoid problems with object ordering).

## Basic Usage

Getting started with PICO-EC aims to be very simple and easy. Here's an example showing how to create
a scene with a default entity added.

```lua
local firstScene = factory.createScene()
local firstEntity = factory.createEntity()

mainScene = firstScene
mainScene:addEntity(firstEntity)
```

Simple, right? In order for your scenes to run correctly however, you do of course need to hook them
up into your main application lifecycle as follows!

```lua
function _init()
  mainScene:init()
end

function _update()
  mainScene:update()
end

function _draw()
  mainScene:draw()
end
```

From here, the currently active scene will cycle through all of it's added entities and call the 
relevant lifecycle functions on them. The entities in turn will call these functions on their 
added components.

Now that's all well and good, but without any behaviours, nothing's actually going to happen, so let's
create some custom behaviours to get a rectangle moving on screen.

I think we're going to want to draw a background rect, and a moveable foreground rect. So thinking logically
about separation of behaviours, I think we can separate these into 3 separate components:

- Transform
- Rect
- Mover

### Custom Components

Creating a custom component is as simple as defining a new table object and calling a function. Your component
can simply hold properties to be manipulated and referenced by other components, or it can override some functions
on the default component to provide some new behvaiours.

```lua
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

```

With our three primary components now defined, we can bind it all together into our scene down in
our main section like so:

```lua
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

```

Let's take a look at how that runs in the console!

-- Insert gif.

Perfect! With that finished, you can go off and start writing your own custom
components, entities and scenes to run drive your games!

Whilst I do believe that this library can be quite verbose for very small PICO-8 projects,
as your projects reach a higher scale, it can really help to cut down on tokens as your game is
driven by many reusable entities and behavioours.

## Examples

You can find the example code above in the TestCart folder if you want to load it up into the console
and play around with it!

## Reference

The API documentation for the library can be viewed [here](https://joebrogers.github.io/pico-ec/).


