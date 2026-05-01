local Locale = {}

Locale.DEFAULT = "en"

local ORDER = { "en", "ko" }
local DATA = {
    en = {},
    ko = {},
}

local function setPath(root, path, value)
    local cursor = root
    local parts = {}
    for part in path:gmatch("[^%.]+") do
        parts[#parts + 1] = part
    end
    for i = 1, #parts - 1 do
        local part = parts[i]
        cursor[part] = cursor[part] or {}
        cursor = cursor[part]
    end
    cursor[parts[#parts]] = value
end

local function getPath(root, path)
    local cursor = root
    for part in path:gmatch("[^%.]+") do
        if type(cursor) ~= "table" then
            return nil
        end
        cursor = cursor[part]
        if cursor == nil then
            return nil
        end
    end
    return cursor
end

local function pair(path, enValue, koValue)
    setPath(DATA.en, path, enValue)
    setPath(DATA.ko, path, koValue)
end

local function meta(key, enName, koName)
    pair("meta." .. key .. ".name", enName, koName)
end

local function mutation(key, enName, koName)
    pair("mutation." .. key .. ".name", enName, koName)
end

function Locale.isSupported(code)
    return DATA[code] ~= nil
end

function Locale.next(code)
    for i, item in ipairs(ORDER) do
        if item == code then
            return ORDER[(i % #ORDER) + 1]
        end
    end
    return Locale.DEFAULT
end

function Locale.ref(key, params)
    return { key = key, params = params }
end

local function resolveParam(code, value)
    if type(value) == "table" and value.key then
        return Locale.text(code, value.key, value.params)
    end
    if value == nil then
        return ""
    end
    return tostring(value)
end

function Locale.text(code, key, params)
    local lang = Locale.isSupported(code) and code or Locale.DEFAULT
    local template = getPath(DATA[lang], key) or getPath(DATA[Locale.DEFAULT], key)
    if template == nil then
        return key
    end
    if type(template) ~= "string" or not params then
        return template
    end
    return (template:gsub("{([%w_]+)}", function(name)
        return resolveParam(lang, params[name])
    end))
end

pair("app.title", "Baby Dragon Incremental v1", "아기 용 인크리멘탈 v1")
pair("language.en", "English", "영어")
pair("language.ko", "Korean", "한국어")
pair("hud.map", "Map {map} ({unlocked}/{total})", "맵 {map} ({unlocked}/{total})")
pair("hud.time_map", "Time {time}   {map}", "시간 {time}   {map}")
pair("hud.essence", "Essence {essence}   Lv {level}   XP {current}/{goal}", "에센스 {essence}   레벨 {level}   경험치 {current}/{goal}")
pair("hud.instinct_progress", "Instinct {current}/{next}   Remain {remain}", "본능 {current}/{next}   남음 {remain}")
pair("hud.instinct_short", "Instinct {remain}", "본능 {remain}")
pair("hud.instinct_complete", "Instinct progression complete", "본능 진행 완료")
pair("hud.manual_save", "Manual Save", "수동 저장")
pair("hud.help", "[H] Help", "[H] 도움말")
pair("boss.title", "Final Boss", "최종 보스")
pair("boss.timer", "Arena {time}", "결투장 {time}")
pair("boss.weak_points", "Weak {count}", "약점 {count}")
pair("boss.status.shielded", "Shielded", "방어 중")
pair("boss.status.vulnerable", "Vulnerable", "취약")

pair("help.title", "HELP", "도움말")
pair("help.language", "Language {language}", "언어 {language}")
pair("help.toggle_language", "[L] Switch language", "[L] 언어 전환")
pair("help.toggle_language_label", "Switch language", "언어 전환")
pair("help.close", "[H] Close help", "[H] 도움말 닫기")
pair("help.close_label", "Close help", "도움말 닫기")
pair("help.run_end.summary", "Reason {reason} | Essence {essence} | Lv {level} | Points {points}", "종료 사유 {reason} | 에센스 {essence} | 레벨 {level} | 포인트 {points}")
pair("help.run_end.drag", "[Drag] Pan view", "[드래그] 화면 이동")
pair("help.run_end.wheel", "[Wheel] Zoom in or out", "[휠] 확대 축소")
pair("help.run_end.tab", "[Click Tab] Switch Meta and Nest", "[탭 클릭] 메타와 둥지 전환")
pair("help.run_end.buy", "[Click] Buy upgrade  |  [R] Start new run", "[클릭] 업그레이드 구매  |  [R] 새 런 시작")
pair("help.run_choice.line1", "Choose one instinct to shape this run", "이번 런의 방향을 정할 본능 하나를 고릅니다")
pair("help.run_choice.line2", "Time and combat pause while choosing", "선택 중에는 시간과 전투가 멈춥니다")
pair("help.run_choice.line3", "Brooder and Hatchery improve this system", "부화실과 부화장이 이 시스템을 강화합니다")
pair("help.run_choice.line4", "[Click] Pick one card  |  [H] Close help", "[클릭] 카드 하나 선택  |  [H] 도움말 닫기")
pair("help.game.goal", "Goal: win a 15-second hunt, earn stars, and open the boss path.", "목표: 15초 사냥에서 성과를 내고 별을 모아 보스 길을 엽니다")
pair("help.game.map", "[1-4] Switch map", "[1-4] 맵 전환")
pair("help.game.boss", "[B] Enter boss", "[B] 보스 진입")
pair("help.game.save", "[F5/F9] Save or Load  |  [F10] Reset all data", "[F5/F9] 저장 또는 불러오기  |  [F10] 전체 초기화")

pair("guide.confirm", "Understood", "확인")
pair("guide.run_start.title", "First Hunt", "첫 사냥")
pair("guide.run_start.body", "Chase the cursor and keep eating inside your bite range. Each hunt lasts 15 seconds, so every detour matters.", "커서를 따라 움직이며 섭식 반경 안의 먹이를 계속 먹어야 합니다. 한 번의 사냥은 15초뿐이라 매 움직임이 중요합니다")
pair("guide.first_instinct.title", "Instinct Choice", "본능 선택")
pair("guide.first_instinct.body", "Pick one card to shape this run. Combat and time pause here, so read the bonuses before choosing.", "이번 런의 방향을 정할 카드 하나를 고릅니다. 여기서는 시간과 전투가 멈추므로 효과를 보고 선택하면 됩니다")
pair("guide.first_map_unlock.title", "New Hunting Ground", "새 사냥터")
pair("guide.first_map_unlock.body", "A stronger map has opened from hunt stars. Use keys 1-4 to swap maps when you want better rewards at the cost of tougher prey.", "사냥 별로 더 강한 맵이 열렸습니다. 더 강한 먹이 대신 더 좋은 보상을 원하면 1-4 키로 맵을 바꾸면 됩니다")
pair("guide.boss_ready.title", "Boss Is Ready", "보스 진입 가능")
pair("guide.boss_ready.body", "The final duel is ready. Stay on map 4 and press B to enter the boss arena.", "최종 결투가 준비됐습니다. 4번 맵에서 B를 눌러 보스 결투장에 진입합니다")
pair("guide.run_end_tree.title", "Growth View", "성장 화면")
pair("guide.run_end_tree.body", "Spend essence in the Meta Tree, switch to the Nest tab for persistent upgrades, and drag or wheel the tree to inspect routes.", "메타 트리에 에센스를 투자하고 둥지 탭에서 영구 업그레이드를 고릅니다. 트리는 드래그와 휠로 이동하고 확대할 수 있습니다")

pair("tab.meta", "Meta Tree", "메타 트리")
pair("tab.nest", "Nest", "둥지")

pair("save_status.never", "never", "없음")
pair("save_status.saved", "saved", "저장됨")
pair("save_status.failed", "save failed {error}", "저장 실패 {error}")
pair("save_status.delayed_choice", "save delayed: instinct choice", "본능 선택 중이라 저장 연기")
pair("save_status.delayed_boss", "save delayed: boss duel", "보스전 중이라 저장 연기")

pair("message.save_warning", "Save warning {error}", "저장 경고 {error}")
pair("message.choose_instinct", "Choose an instinct", "본능을 선택하세요")
pair("message.new_run_started", "New run started", "새 런 시작")
pair("message.run_ended", "Run ended", "런 종료")
pair("message.mid_event_started", "Mid hunt target appeared", "중간 사냥 목표 출현")
pair("message.mid_event_cleared", "Mid hunt cleared", "중간 사냥 목표 달성")
pair("message.final_event_started", "Final hunt target appeared", "피니시 목표 출현")
pair("message.final_event_cleared", "Final hunt cleared", "피니시 목표 달성")
pair("message.new_map_unlocked_from_stars", "New map unlocked from hunt stars", "사냥 별로 새 맵 해금")
pair("message.meta_upgrade_purchased", "Meta upgrade purchased", "메타 업그레이드 구매")
pair("message.save_reloaded", "Save reloaded", "저장 다시 불러옴")
pair("message.all_progress_reset", "All progress reset", "모든 진행 초기화")
pair("message.new_map_unlocked_from_skill_tree", "New map unlocked from skill tree", "스킬트리 진행으로 새 맵 해금")
pair("message.save_delayed_until_choice_ends", "Save delayed until instinct choice ends", "본능 선택이 끝날 때까지 저장 연기")
pair("message.save_delayed_during_boss_arena", "Save delayed during boss duel", "보스전이 끝날 때까지 저장 연기")
pair("message.map_changed", "Map changed to {mapName}", "{mapName} 맵으로 변경")
pair("message.final_boss_engaged", "Final boss engaged", "최종 보스 교전 시작")
pair("message.final_boss_defeated", "Final boss defeated", "최종 보스 처치")
pair("message.meta_upgrade_purchased_map", "Meta upgrade purchased. New map unlocked", "메타 업그레이드 구매. 새 맵 해금")
pair("message.meta_upgrade_failed", "Meta upgrade failed: {error}", "메타 업그레이드 실패: {error}")
pair("message.nest_upgrade_purchased", "Nest upgrade purchased", "둥지 업그레이드 구매")
pair("message.nest_upgrade_failed", "Nest upgrade failed: {error}", "둥지 업그레이드 실패: {error}")
pair("message.instinct_choice_failed", "Instinct choice failed: {error}", "본능 선택 실패: {error}")
pair("message.choose_another_instinct", "Choose another instinct", "다른 본능을 선택하세요")
pair("message.instinct_chosen", "Instinct chosen", "본능 선택 완료")
pair("message.language_changed", "Language switched to {language}", "언어를 {language}로 전환")

pair("run_reason.time", "Time ran out", "시간 종료")
pair("run_reason.boss_failed", "Boss trial failed", "보스전 실패")
pair("run_reason.victory", "Victory", "승리")
pair("run_reason.unknown", "Unknown", "알 수 없음")

pair("status.BUY", "BUY", "구매 가능")
pair("status.LOCKED", "LOCKED", "잠김")
pair("status.NEED_ESSENCE", "NEED ESSENCE", "에센스 부족")
pair("status.MAX", "MAX", "최대")
pair("status.NEED_POINTS", "NEED POINTS", "포인트 부족")

pair("error.generic.not_in_run_end", "not in run end screen", "런 종료 화면이 아님")
pair("error.meta.invalid_index", "invalid node", "잘못된 노드")
pair("error.meta.already_max", "already maxed", "이미 최대 레벨")
pair("error.meta.dependency_missing", "dependency missing", "선행 노드 부족")
pair("error.meta.not_enough_essence", "not enough essence", "에센스 부족")
pair("error.nest.invalid_key", "invalid upgrade", "잘못된 업그레이드")
pair("error.nest.already_max", "already maxed", "이미 최대 레벨")
pair("error.nest.not_enough_points", "not enough points", "포인트 부족")
pair("error.mutation.invalid_choice", "invalid choice", "잘못된 선택")

pair("map.1.name", "Sprout Meadow", "새싹 초원")
pair("map.2.name", "Crystal Cave", "수정 동굴")
pair("map.3.name", "Molten Ridge", "용암 산등성이")
pair("map.4.name", "Abyss Nursery", "심연의 보육지")

pair("nest.summary", "Level {level}   Free {points}   Spent {spent}   Evolution {evolution}", "레벨 {level}   여유 {points}   사용 {spent}   진화 {evolution}")
pair("nest.progress", "Total essence {essence}   Need {next} for next level", "누적 에센스 {essence}   다음 레벨까지 {next}")
pair("nest.footer", "Spend level points to reshape each new run", "레벨 포인트를 써서 다음 런의 흐름을 바꿉니다")
pair("nest.level", "{name}  Lv.{level}/{max}", "{name}  Lv.{level}/{max}")
pair("nest.cost", "Cost {cost}", "비용 {cost}")
pair("nest.upgrade.brooder.name", "Brooder", "부화실")
pair("nest.upgrade.brooder.desc", "Start each run with instinct picks", "각 런 시작 시 본능 선택을 미리 얻습니다")
pair("nest.upgrade.larder.name", "Larder", "저장고")
pair("nest.upgrade.larder.desc", "Lower essence needed for instinct levels", "본능 레벨업에 필요한 에센스를 줄입니다")
pair("nest.upgrade.roost.name", "Roost", "보금자리")
pair("nest.upgrade.roost.desc", "Raise starting speed and magnet reach", "시작 이동 속도와 자석 반경을 올립니다")
pair("nest.upgrade.hatchery.name", "Hatchery", "부화장")
pair("nest.upgrade.hatchery.desc", "More instinct cards and better rarity", "본능 카드 수와 희귀도를 강화합니다")
pair("nest.effect.brooder", "Start with {count} instinct picks", "시작 본능 선택 {count}회")
pair("nest.effect.larder", "Instinct level cost -{percent}%", "본능 레벨 비용 -{percent}%")
pair("nest.effect.roost", "Speed +{speed}  Magnet +{magnet}", "속도 +{speed}  자석 +{magnet}")
pair("nest.effect.hatchery", "Choices {count}  Rarity shift {shift}", "선택지 {count}  희귀도 보정 {shift}")

pair("run_end.title", "RUN ENDED", "런 종료")
pair("run_end.hover", "Hover a node to inspect details", "노드 위에 마우스를 올려 상세 정보를 봅니다")
pair("run_end.tooltip.title", "[{index}] {name}  Lv.{level}/{max}", "[{index}] {name}  Lv.{level}/{max}")
pair("run_end.tooltip.cost_status", "Cost {cost} | Status {status}", "비용 {cost} | 상태 {status}")
pair("run_end.result.reason", "Reason: {reason}", "종료 사유: {reason}")
pair("run_end.result.total_eaten", "Total Eaten: {total}", "총 섭취 수: {total}")
pair("run_end.result.run_stars", "This Run Stars: {stars}/3", "이번 런 별: {stars}/3")
pair("run_end.result.map_best", "Current Map Best: {best}/3", "현재 맵 최고 별: {best}/3")
pair("run_end.result.total_stars", "Total Stars: {stars}/{max}", "총 별: {stars}/{max}")
pair("run_end.result.current_essence", "Current Essence: {essence}", "현재 에센스: {essence}")
pair("run_end.result.level", "Dragon Level: {level}", "드래곤 레벨: {level}")
pair("run_end.result.points", "Nest Points: {points}", "네스트 포인트: {points}")
pair("run_end.result.next_map", "Next Map: {map}   {current}/{required} stars", "다음 맵: {map}   별 {current}/{required}")
pair("run_end.result.all_maps", "All maps unlocked", "모든 맵 해금 완료")
pair("run_end.result.evolution", "Evolution: {evolution}", "진화 단계: {evolution}")
pair("run_end.result.continue", "Click to continue to growth view", "클릭해 성장 화면으로 이동")
pair("evolution.stage.1", "Baby Dragon", "아기 용")
pair("evolution.stage.2", "Young Drake", "어린 용")
pair("evolution.stage.3", "Adult Drake", "성체 용")
pair("evolution.stage.4", "Elder Dragon", "고룡")

pair("run_choice.title", "CHOOSE AN INSTINCT", "본능 선택")
pair("run_choice.summary", "Run essence {essence}   Pending choices {pending}", "런 에센스 {essence}   남은 선택 {pending}")
pair("run_choice.click", "Click to choose", "클릭해 선택")
pair("category.hunt", "Hunt", "사냥")
pair("category.stomach", "Stomach", "소화")
pair("category.sense", "Sense", "감각")
pair("category.spawn", "Spawn", "번식")
pair("category.instinct", "Instinct", "본능")
pair("rarity.common", "Common", "일반")
pair("rarity.rare", "Rare", "희귀")
pair("rarity.mythic", "Mythic", "신화")

pair("bonus.period.per_level", " per level", " 레벨당")
pair("bonus.lightningEnabled", "Unlock lightning", "번개 해금")
pair("bonus.fireballEnabled", "Unlock fireballs", "화염구 해금")
pair("bonus.speed", "Move speed +{value}", "이동 속도 +{value}")
pair("bonus.reach", "Reach +{value}", "섭식 반경 +{value}")
pair("bonus.magnet", "Magnet +{value}", "자석 +{value}")
pair("bonus.contactBite", "Contact bite +{value}", "접촉 물기 +{value}")
pair("bonus.eventBiteBonus", "Event target bite +{value}", "이벤트 목표 물기 +{value}")
pair("bonus.essenceMult", "Essence gain +{value}%", "에센스 획득 +{value}%")
pair("bonus.rareBonus", "Rare spawn +{value}%", "희귀 스폰 +{value}%")
pair("bonus.eliteBonus", "Elite spawn +{value}%", "엘리트 스폰 +{value}%")
pair("bonus.rareValue", "Rare value +{value}%", "희귀 가치 +{value}%")
pair("bonus.eliteValue", "Elite value +{value}%", "엘리트 가치 +{value}%")
pair("bonus.spawnRate", "Spawn speed +{value}%", "스폰 속도 +{value}%")
pair("bonus.spawnCap", "Spawn cap +{value}", "스폰 수용량 +{value}")
pair("bonus.lightningDamage", "Lightning damage +{value}", "번개 피해 +{value}")
pair("bonus.lightningChain", "Lightning chain +{value}", "번개 연쇄 +{value}")
pair("bonus.lightningIntervalCut", "Lightning cooldown -{value}s", "번개 재사용 대기 -{value}초")
pair("bonus.fireballDamage", "Fireball damage +{value}", "화염구 피해 +{value}")
pair("bonus.fireballRadius", "Explosion radius +{value}", "폭발 반경 +{value}")
pair("bonus.fireballCount", "Projectile count +{value}", "투사체 수 +{value}")
pair("bonus.fireballSplit", "Projectile split +{value}", "투사체 분열 +{value}")
pair("bonus.fireballIntervalCut", "Fireball cooldown -{value}s", "화염구 재사용 대기 -{value}초")

mutation("hunt_bite", "Razor Bite", "칼날 물기")
mutation("hunt_pursuit", "Pursuit Muscle", "추적 근육")
mutation("hunt_jaw", "Latch Jaw", "걸쇠 턱")
mutation("stomach_feast", "Feast Stomach", "포식 위장")
mutation("stomach_gem", "Gem Tongue", "보석 혀")
mutation("stomach_crown", "Royal Appetite", "왕실 식욕")
mutation("sense_pull", "Far Scent", "먼 향기")
mutation("sense_sprint", "Spring Tendon", "도약 힘줄")
mutation("sense_jaw", "Long Tongue", "긴 혀")
mutation("spawn_bloom", "Brood Heat", "부화 열기")
mutation("spawn_pack", "Crowded Tracks", "과밀 흔적")
mutation("spawn_lure", "Lure Gland", "유인 샘")
mutation("instinct_storm", "Storm Mouth", "폭풍 입")
mutation("instinct_ember", "Ember Sac", "잉걸 주머니")

meta("origin_heart", "Origin Heart", "기원의 심장")
pair("meta.origin_heart.desc", "Unlocks the primal dragon lattice", "원초 용 격자를 엽니다")

meta("core_mid_clock", "Mid Hunt Fang", "중간 사냥 송곳니")
meta("core_final_clock", "Final Hunt Fang", "피니시 사냥 송곳니")
meta("core_overtime", "Quickwing Chamber", "속도 날개 격실")
meta("core_last_window", "Finisher Claw", "마무리 발톱")
meta("core_flow", "Flow Spine", "흐름 척추")
meta("core_focus", "Focus Maw", "집중 턱")
meta("core_hoard", "Hoard Heart", "비축 심장")
meta("core_apex", "Hunt Crown", "사냥 왕관")

meta("hunt_stride", "Predator Stride", "포식자 보폭")
meta("hunt_maw", "Long Maw", "긴 턱")
meta("hunt_bite", "Crush Bite", "분쇄 물기")
meta("hunt_pursuit", "Pursuit Muscle", "추적 근육")
meta("hunt_hook", "Hook Jaw", "갈고리 턱")
meta("hunt_maul", "Maul Crest", "난도 볏")
meta("hunt_lock", "Lock Fang", "고정 송곳니")
meta("hunt_apex", "Apex Predator", "정점 포식자")

meta("economy_greed", "Greed Gland", "탐욕 샘")
meta("economy_scent", "Rare Scent", "희귀 향")
meta("economy_crown", "Elite Crown", "엘리트 왕관")
meta("economy_pull", "Vacuum Pull", "진공 끌림")
meta("economy_trail", "Trail Heat", "흔적 열기")
meta("economy_brood", "Brood Chamber", "부화 격실")
meta("economy_gold", "Golden Feast", "황금 만찬")
meta("economy_apex", "Royal Nest", "왕실 둥지")

meta("lightning_root", "Storm Sigil", "폭풍 문양")
meta("lightning_shock", "Shock Fang", "충격 송곳니")
meta("lightning_link", "Link Coil", "연쇄 고리")
meta("lightning_pulse", "Pulse Clock", "맥동 시계")
meta("lightning_storm", "Storm Core", "폭풍 핵")
meta("lightning_arc", "Arc Jaw", "전류 턱")
meta("lightning_relay", "Relay Spine", "중계 척추")
meta("lightning_apex", "Tempest Crown", "폭풍 왕관")

meta("fireball_root", "Flame Sigil", "화염 문양")
meta("fireball_blast", "Blast Gullet", "폭발 식도")
meta("fireball_core", "Molten Core", "용해 핵")
meta("fireball_count", "Twin Ember", "쌍둥이 잉걸")
meta("fireball_cinder", "Cinder Clock", "잿불 시계")
meta("fireball_salvo", "Salvo Jaw", "연사 턱")
meta("fireball_furnace", "Furnace Lung", "화로 폐")
meta("fireball_apex", "Inferno Crown", "지옥불 왕관")

return Locale
