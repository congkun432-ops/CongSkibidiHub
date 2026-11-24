
local Text = {
    -- Tabs
    ["tab.player"]   = { "Người chơi", "Player" },
    ["tab.farm"]     = { "Cày", "Farm" },
    ["tab.esp"]      = { "ESP", "ESP" },
    ["tab.items"]    = { "Vật phẩm", "Items" },
    ["tab.teleport"] = { "Dịch chuyển", "Teleport" },
    ["tab.misc"]     = { "Khác", "Misc" },
    ["tab.settings"] = { "Cài đặt", "Settings" },
    ["tab.extras"]   = { "Linh tinh", "Extras" },

    -- Player
    ["player.speed"]       = { "Tăng tốc", "Speed boost" },
    ["player.speed_value"] = { "Tốc độ chạy", "Run speed" },
    ["player.fly"]         = { "Bay", "Fly" },
    ["player.fly_speed"]   = { "Tốc độ bay", "Fly speed" },
    ["player.noclip"]      = { "Xuyên tường", "Noclip" },
    ["player.infjump"]     = { "Nhảy vô hạn", "Infinite jump" },
    ["player.instant"]     = { "Tương tác tức thì", "Instant interact" },
    ["player.third"]       = { "Góc nhìn thứ 3", "Third person" },
    ["player.zoom"]        = { "Zoom xa tối đa", "Max zoom" },

    -- Combat
    ["combat.aura_section"]  = { "Kill Aura", "Kill Aura" },
    ["combat.aura"]          = { "Kill Aura", "Kill Aura" },
    ["combat.gun_aura"]      = { "Kill Aura Gun", "Kill Aura Gun" },
    ["combat.aura_speed"]    = { "Tốc độ đánh", "Attack speed" },
    ["combat.range"]         = { "Phạm vi", "Range" },
    ["combat.weapon_slot"]   = { "Ô vũ khí", "Weapon slot" },
    ["combat.gun_slot"]      = { "Ô súng", "Gun slot" },
    ["combat.rapid_section"] = { "Không hồi chiêu", "No cooldown" },
    ["combat.rapid_gun"]     = { "Súng không hồi chiêu", "No-cooldown gun" },
    ["combat.fire_rate"]     = { "Tốc độ bắn", "Fire rate" },
    ["combat.reload"]        = { "Nạp đạn nhanh", "Fast reload" },
    ["combat.rapid_melee"]   = { "Cận chiến không hồi chiêu", "No-cooldown melee" },
    ["combat.melee_speed"]   = { "Tốc độ đánh", "Attack speed" },

    -- Collect categories
    ["cat.Ingredient"] = { "Nguyên liệu", "Ingredients" },
    ["cat.Item"]       = { "Vật phẩm khác", "Other items" },
    ["cat.Material"]   = { "Vật liệu", "Materials" },
    ["cat.Corpse"]     = { "Xác Zombie", "Zombie corpses" },
    ["cat.Medical"]    = { "Đồ y tế", "Medical" },

    -- Collect / Grind
    ["collect.section"] = { "Tự động nhặt", "Auto pickup" },
    ["collect.range"]   = { "Phạm vi", "Range" },
    ["collect.enable"]  = { "Bật tự nhặt", "Enable auto pickup" },
    ["collect.types"]   = { "Loại nhặt", "Pickup types" },
    ["grind.section"]   = { "Tự động nghiền", "Auto grind" },
    ["grind.enable"]    = { "Bật tự nghiền", "Enable auto grind" },
    ["grind.types"]     = { "Loại nghiền", "Grind types" },
    ["grind.speed"]     = { "Tốc độ nghiền", "Grind speed" },

    -- Acorn
    ["acorn.farm"] = { "Farm hạt dẻ", "Farm acorns" },

    -- Chest
    ["chest.auto"]    = { "Tự mở rương", "Auto open chests" },
    ["chest.types"]   = { "Loại mở", "Chest types" },
    ["chest.Chest"]   = { "Rương", "Chests" },
    ["chest.Fridge"]  = { "Tủ lạnh", "Fridges" },
    ["chest.Cactus"]  = { "Xương rồng", "Cacti" },
    ["chest.safe"]    = { "Mở két sắt", "Open safe" },
    ["chest.safe_btn"] = { "Mở", "Open" },

    -- ESP
    ["esp.player"]   = { "ESP người chơi", "Player ESP" },
    ["esp.zombie"]   = { "ESP zombie", "Zombie ESP" },
    ["esp.item"]     = { "ESP vật phẩm", "Item ESP" },
    ["esp.body"]     = { "ESP xác", "Body ESP" },
    ["esp.chest"]    = { "ESP rương", "Chest ESP" },
    ["esp.settings"] = { "Cài đặt ESP", "ESP settings" },
    ["esp.names"]    = { "Hiện tên", "Show names" },
    ["esp.distance"] = { "Hiện khoảng cách", "Show distance" },
    ["esp.highlight"] = { "Viền sáng", "Glow outline" },
    ["esp.range"]    = { "Tầm tối đa", "Max range" },
    ["esp.tag.Player"] = { "Người chơi: %s", "Player: %s" },
    ["esp.tag.Zombie"] = { "Zombie: %s", "Zombie: %s" },
    ["esp.tag.Body"]   = { "Xác: %s", "Body: %s" },
    ["esp.tag.Item"]   = { "Vật phẩm: %s", "Item: %s" },
    ["esp.tag.Chest"]  = { "Rương: %s", "Chest: %s" },
    ["esp.studs"]      = { "%d studs", "%d studs" },

    -- Items / Bring
    ["bring.section"] = { "Kéo vật phẩm", "Bring items" },
    ["bring.enable"]  = { "Bật kéo", "Enable bring" },
    ["bring.type"]    = { "Loại", "Type" },
    ["bring.delay"]   = { "Độ trễ", "Delay" },
    ["bring.All"]     = { "Tất cả", "All" },
    ["bring.Item"]    = { "Vật phẩm", "Items" },
    ["bring.Body"]    = { "Xác", "Bodies" },

    -- Teleport
    ["tp.location"] = { "Địa điểm", "Location" },
    ["tp.button"]   = { "Dịch chuyển", "Teleport" },
    ["tp.go"]       = { "Đi", "Go" },
    ["tp.empty"]    = { "(chưa có điểm dịch chuyển)", "(no teleport points)" },

    -- Misc
    ["misc.cutscene"]  = { "Bỏ qua cảnh phim", "Skip cutscenes" },
    ["misc.safe_code"] = { "Mã két", "Safe code" },
    ["misc.code_btn"]  = { "Code", "Code" },
    ["misc.all_codes"] = { "Tất cả code", "All codes" },
    ["misc.scan"]      = { "Quét", "Scan" },
    ["code.title"]     = { "Code", "Code" },
    ["code.no_clipboard"] = { "Không thấy BankClipboard.", "BankClipboard not found." },
    ["code.empty_clipboard"] = { "Không có mã trong BankClipboard.", "No code in BankClipboard." },
    ["code.none"]      = { "Không tìm thấy code nào trong map.", "No codes found on the map." },
    ["code.Safe"]      = { "Mã két", "Safe code" },
    ["code.Raygun"]    = { "Mã Raygun", "Raygun code" },
    ["code.Keypad"]    = { "Mã Keypad", "Keypad code" },
    ["code.Sewer"]     = { "Mã cống", "Sewer code" },
    ["code.Gate"]      = { "Mã cổng cơ sở", "Facility gate code" },
    ["code.Notes"]     = { "Bảng ghi chú", "Notes board" },
    ["code.Display"]   = { "Màn hình", "Screen" },
    ["code.KeyItems"]  = { "Vật phẩm chính", "Key items" },

    -- Extras
    ["spin.section"]  = { "Quay người", "Spin" },
    ["spin.enable"]   = { "Bật quay người", "Enable spin" },
    ["spin.speed"]    = { "Tốc độ quay (độ/giây)", "Spin speed (deg/s)" },
    ["giant.section"] = { "Nhân vật to (chỉ mình thấy)", "Giant character (only you see it)" },
    ["giant.enable"]  = { "Bật nhân vật to", "Enable giant" },
    ["giant.size"]    = { "Kích thước", "Size" },
    ["orbit.section"] = { "Lãnh địa vật phẩm", "Item territory" },
    ["orbit.enable"]  = { "Bật lãnh địa", "Enable territory" },
    ["orbit.types"]   = { "Loại vật phẩm", "Item types" },
    ["orbit.count"]   = { "Số lượng", "Amount" },
    ["orbit.radius"]  = { "Bán kính", "Radius" },
    ["orbit.speed"]   = { "Tốc độ xoay", "Orbit speed" },
    ["orbit.height"]  = { "Độ cao", "Height" },
    ["orbit.reach"]   = { "Tầm hút", "Pull reach" },

    -- Settings / Language
    ["lang.notify"]   = { "Ngôn ngữ", "Language" },
    ["lang.changed"]  = { "Đã chuyển sang %s.", "Switched to %s." },

    -- System
    ["sys.module_error"] = { "Lỗi khi chạy, xem console.", "Runtime error, see console." },
}

return {
    Langs = { "vi", "en" },
    Names = { vi = "Tiếng Việt", en = "English" },
    Text = Text,
}
