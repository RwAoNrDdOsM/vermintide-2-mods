-- luacheck: globals Localize PassiveAbilityQuestingKnight
local all_quests = PassiveAbilityQuestingKnight._generate_quest_pool({
  _tomes_allowed = true,
  _grims_allowed = true,
})

local localizations = {
  mod_description = {
    en = "Choose which Grail Knight quests you get. DOESN'T ALLOW DUPLICATES",
  },
  quest1 = {
    en = "Quest 1",
  },
  quest2 = {
    en = "Quest 2",
  },
  quest3 = {
    en = "Quest 3",
  },
}

local function strim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

for _, quest in pairs(all_quests) do
  local name = strim(string.format(Localize(quest.reward), ""))
  localizations[quest.reward] = {
    en = name
  }
end

return localizations