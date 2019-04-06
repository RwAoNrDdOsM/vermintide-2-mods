local mod = get_mod("dodge-count-ui")
local always_on = mod:get("always_on")

local fake_input_service = {
  get = function ()
    return
  end,
  has = function ()
    return
  end
}

local scenegraph_definition = {
  root = {
    scale = "hud_scale_fit",
    size = {
      1920,
      1080
    },
    position = {
      0,
      0,
      UILayer.hud
    }
  }
}

local dodge_ui_definition = {
  scenegraph_id = "root",
  element = {
    passes = {
      {
        style_id = "dodge_text",
        pass_type = "text",
        text_id = "dodge_text",
        retained_mode = false,
        fade_out_duration = 5,
        content_check_function = function(content)
          if always_on then
            return true
          end
          return content.has_dodged
        end
      },
      {
        style_id = "cooldown_text",
        pass_type = "text",
        text_id = "cooldown_text",
        retained_mode = false,
        content_check_function = function(content)
          return content.has_cooldown
        end
      }
    }
  },
  content = {
    dodge_text = "",
    cooldown_text = "",
    has_dodged = false,
    has_cooldown = false,
  },
  style = {
    dodge_text = {
      font_type = "hell_shark",
      font_size = mod:get("dodge_count_font_size"),
      vertical_alignment = "center",
      horizontal_alignment = "center",
      text_color = Colors.get_table("white"),
      offset = {
        mod:get("offset_x"),
        -mod:get("offset_y"),
        0
      }
    },
    cooldown_text = {
      font_type = "hell_shark",
      font_size = mod:get("cooldown_font_size"),
      vertical_alignment = "center",
      horizontal_alignment = "center",
      text_color = Colors.get_table("white"),
      offset = {
        mod:get("offset_x"),
        -(mod:get("offset_y") + mod:get("dodge_count_font_size")),
        0
      }
    },
  },
  offset = {
    0,
    0,
    0
  },
}

function mod:on_disabled()
  mod.ui_renderer = nil
  mod.ui_scenegraph = nil
  mod.ui_widget = nil
end

function mod:on_setting_changed()
  always_on = mod:get("always_on")
  if not mod.ui_widget then
    return
  end
  mod.ui_widget.style.dodge_text.offset[1] = mod:get("offset_x")
  mod.ui_widget.style.dodge_text.offset[2] = -mod:get("offset_y")
  mod.ui_widget.style.dodge_text.font_size = mod:get("dodge_count_font_size")
  mod.ui_widget.style.cooldown_text.offset[1] = mod:get("offset_x")
  mod.ui_widget.style.cooldown_text.offset[2] = -(mod:get("offset_y") + mod:get("dodge_count_font_size"))
  mod.ui_widget.style.cooldown_text.font_size = mod:get("cooldown_font_size")
end

function mod:init()
  if mod.ui_widget then
    return
  end

  local world = Managers.world:world("top_ingame_view")
  mod.ui_renderer = UIRenderer.create(world, "material", "materials/fonts/gw_fonts")
  mod.ui_scenegraph = UISceneGraph.init_scenegraph(scenegraph_definition)
  mod.ui_widget = UIWidget.init(dodge_ui_definition)
end

mod:hook_safe(IngameHud, "update", function(self)
  -- If the EquipmentUI isn't visible or the player is dead
  -- then let's not show the Dodge Count UI
  if not self._currently_visible_components.EquipmentUI or self:is_own_player_dead() then
    return
  end

  local t = Managers.time:time("game")
  local player_unit = Managers.player:local_player().player_unit
  local status_system = ScriptUnit.has_extension(player_unit, "status_system")

  if not status_system or not player_unit then
    return
  end

  if not mod.ui_widget then
    mod.init()
  end

  status_system:get_dodge_item_data()
  local current_dodge_count = status_system.dodge_cooldown
  local efficient_dodge_count = status_system.dodge_count
  local cooldown = status_system.dodge_cooldown_delay or 0

  local widget = mod.ui_widget
  local ui_renderer = mod.ui_renderer
  local ui_scenegraph = mod.ui_scenegraph

  widget.content.dodge_text = string.format("%i/%u", efficient_dodge_count - current_dodge_count, efficient_dodge_count)
  widget.content.cooldown_text = string.format("%.1fs", cooldown - t)
  widget.content.has_dodged = current_dodge_count > 0
  widget.content.has_cooldown = (cooldown - t) > 0

  UIRenderer.begin_pass(ui_renderer, ui_scenegraph, fake_input_service, dt)
  UIRenderer.draw_widget(ui_renderer, widget)
  UIRenderer.end_pass(ui_renderer)
end)