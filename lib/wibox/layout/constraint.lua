---------------------------------------------------------------------------
-- @author Lukáš Hrázký
-- @copyright 2012 Lukáš Hrázký
-- @release @AWESOME_VERSION@
-- @classmod wibox.layout.constraint
---------------------------------------------------------------------------

local pairs = pairs
local type = type
local setmetatable = setmetatable
local base = require("wibox.widget.base")
local math = math

local constraint = { mt = {} }

--- Layout a constraint layout
function constraint:layout(_, width, height)
    if self.widget then
        return { base.place_widget_at(self.widget, 0, 0, width, height) }
    end
end

--- Fit a constraint layout into the given space
function constraint:fit(context, width, height)
    local w, h
    if self.widget then
        w = self._strategy(width, self._width)
        h = self._strategy(height, self._height)

        w, h = base.fit_widget(self, context, self.widget, w, h)
    else
        w, h = 0, 0
    end

    w = self._strategy(w, self._width)
    h = self._strategy(h, self._height)

    return w, h
end

--- Set the widget that this layout adds a constraint on.
function constraint:set_widget(widget)
    self.widget = widget
    self:emit_signal("widget::layout_changed")
end

--- Get the number of children element
-- @treturn table The children
function constraint:get_children()
    return {self.widget}
end

--- Replace the layout children
-- This layout only accept one children, all others will be ignored
-- @tparam table children A table composed of valid widgets
function constraint:set_children(children)
    self:set_widget(children[1])
end

--- Set the strategy to use for the constraining. Valid values are 'max',
-- 'min' or 'exact'. Throws an error on invalid values.
function constraint:set_strategy(val)
    local func = {
        min = function(real_size, limit)
            return limit and math.max(limit, real_size) or real_size
        end,
        max = function(real_size, limit)
            return limit and math.min(limit, real_size) or real_size
        end,
        exact = function(real_size, limit)
            return limit or real_size
        end
    }

    if not func[val] then
        error("Invalid strategy for constraint layout: " .. tostring(val))
    end

    self._strategy = func[val]
    self:emit_signal("widget::layout_changed")
end

--- Set the maximum width to val. nil for no width limit.
function constraint:set_width(val)
    self._width = val
    self:emit_signal("widget::layout_changed")
end

--- Set the maximum height to val. nil for no height limit.
function constraint:set_height(val)
    self._height = val
    self:emit_signal("widget::layout_changed")
end

--- Reset this layout. The widget will be unreferenced, strategy set to "max"
-- and the constraints set to nil.
function constraint:reset()
    self._width = nil
    self._height = nil
    self:set_strategy("max")
    self:set_widget(nil)
end

--- Returns a new constraint layout. This layout will constraint the size of a
-- widget according to the strategy. Note that this will only work for layouts
-- that respect the widget's size, eg. fixed layout. In layouts that don't
-- (fully) respect widget's requested size, the inner widget still might get
-- drawn with a size that does not fit the constraint, eg. in flex layout.
-- @param[opt] widget A widget to use.
-- @param[opt] strategy How to constraint the size. 'max' (default), 'min' or
-- 'exact'.
-- @param[opt] width The maximum width of the widget. nil for no limit.
-- @param[opt] height The maximum height of the widget. nil for no limit.
local function new(widget, strategy, width, height)
    local ret = base.make_widget()

    for k, v in pairs(constraint) do
        if type(v) == "function" then
            ret[k] = v
        end
    end

    ret:set_strategy(strategy or "max")
    ret:set_width(width)
    ret:set_height(height)

    if widget then
        ret:set_widget(widget)
    end

    return ret
end

function constraint.mt:__call(...)
    return new(...)
end

return setmetatable(constraint, constraint.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
