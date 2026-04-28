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

local function meta(key, enName, enDesc, koName, koDesc)
    pair("meta." .. key .. ".name", enName, koName)
    pair("meta." .. key .. ".desc", enDesc, koDesc)
end

local function mutation(key, enName, koName, enDescs, koDescs)
    pair("mutation." .. key .. ".name", enName, koName)
    pair("mutation." .. key .. ".desc.common", enDescs.common, koDescs.common)
    pair("mutation." .. key .. ".desc.rare", enDescs.rare, koDescs.rare)
    pair("mutation." .. key .. ".desc.mythic", enDescs.mythic, koDescs.mythic)
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
pair("hud.stars_short", "Stars {stars}", "별 {stars}")
pair("hud.bonus_time_short", "+{time}s", "+{time}초")
pair("hud.event.opening", "Opening hunt", "오프닝 사냥")
pair("hud.event.mid", "Mid target live", "중간 목표 출현")
pair("hud.event.final_prep", "Final target incoming", "피니시 목표 준비")
pair("hud.event.final", "Final target live", "피니시 목표 출현")
pair("hud.event.done", "Final target cleared", "피니시 목표 처치")
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
pair("event.mid.pack", "Pack leader", "무리 우두머리")
pair("event.mid.runner", "Crystal runner", "수정 질주자")
pair("event.mid.breaker", "Magma breaker", "용암 파괴자")
pair("event.mid.omen", "Abyss omen", "심연 전조")
pair("event.final.alpha", "Alpha maw", "우두머리 턱")
pair("event.final.sprinter", "Deep sprinter", "심층 질주자")
pair("event.final.bastion", "Molten bastion", "용암 보루")
pair("event.final.tyrant", "Nursery tyrant", "보육지 폭군")

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
pair("run_end.result.grade", "Grade: {grade}", "등급: {grade}")
pair("run_end.result.bonus_time", "Bonus Time: +{time}s", "보너스 시간: +{time}초")
pair("run_end.result.stars", "Stars Earned: {stars}", "획득 별: {stars}")
pair("run_end.result.total_stars", "Total Stars: {stars}", "누적 별: {stars}")
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

mutation("hunt_bite", "Razor Bite", "칼날 물기", {
    common = "Contact bite +8",
    rare = "Contact bite +14",
    mythic = "Contact bite +22",
}, {
    common = "접촉 물기 +8",
    rare = "접촉 물기 +14",
    mythic = "접촉 물기 +22",
})
mutation("hunt_pursuit", "Pursuit Muscle", "추적 근육", {
    common = "Move speed +10",
    rare = "Move speed +16",
    mythic = "Move speed +24",
}, {
    common = "이동 속도 +10",
    rare = "이동 속도 +16",
    mythic = "이동 속도 +24",
})
mutation("hunt_jaw", "Latch Jaw", "걸쇠 턱", {
    common = "Reach +1.0",
    rare = "Reach +1.6",
    mythic = "Reach +2.4",
}, {
    common = "섭식 반경 +1.0",
    rare = "섭식 반경 +1.6",
    mythic = "섭식 반경 +2.4",
})
mutation("stomach_feast", "Feast Stomach", "포식 위장", {
    common = "Essence gain +6%",
    rare = "Essence gain +12%",
    mythic = "Essence gain +18%",
}, {
    common = "에센스 획득 +6%",
    rare = "에센스 획득 +12%",
    mythic = "에센스 획득 +18%",
})
mutation("stomach_gem", "Gem Tongue", "보석 혀", {
    common = "Rare value +12%",
    rare = "Rare value +20%",
    mythic = "Rare value +30%",
}, {
    common = "희귀 가치 +12%",
    rare = "희귀 가치 +20%",
    mythic = "희귀 가치 +30%",
})
mutation("stomach_crown", "Royal Appetite", "왕실 식욕", {
    common = "Elite value +15%",
    rare = "Elite value +24%",
    mythic = "Elite value +36%",
}, {
    common = "엘리트 가치 +15%",
    rare = "엘리트 가치 +24%",
    mythic = "엘리트 가치 +36%",
})
mutation("sense_pull", "Far Scent", "먼 향기", {
    common = "Magnet +10",
    rare = "Magnet +18",
    mythic = "Magnet +28",
}, {
    common = "자석 +10",
    rare = "자석 +18",
    mythic = "자석 +28",
})
mutation("sense_sprint", "Spring Tendon", "도약 힘줄", {
    common = "Move speed +12",
    rare = "Move speed +20",
    mythic = "Move speed +30",
}, {
    common = "이동 속도 +12",
    rare = "이동 속도 +20",
    mythic = "이동 속도 +30",
})
mutation("sense_jaw", "Long Tongue", "긴 혀", {
    common = "Reach +0.8",
    rare = "Reach +1.3",
    mythic = "Reach +2.0",
}, {
    common = "섭식 반경 +0.8",
    rare = "섭식 반경 +1.3",
    mythic = "섭식 반경 +2.0",
})
mutation("spawn_bloom", "Brood Heat", "부화 열기", {
    common = "Spawn speed +8%",
    rare = "Spawn speed +14%",
    mythic = "Spawn speed +22%",
}, {
    common = "스폰 속도 +8%",
    rare = "스폰 속도 +14%",
    mythic = "스폰 속도 +22%",
})
mutation("spawn_pack", "Crowded Tracks", "과밀 흔적", {
    common = "Spawn cap +4",
    rare = "Spawn cap +7",
    mythic = "Spawn cap +11",
}, {
    common = "스폰 수용량 +4",
    rare = "스폰 수용량 +7",
    mythic = "스폰 수용량 +11",
})
mutation("spawn_lure", "Lure Gland", "유인 샘", {
    common = "Rare and elite spawn up",
    rare = "Rare and elite spawn up",
    mythic = "Rare and elite spawn up",
}, {
    common = "희귀와 엘리트 스폰 증가",
    rare = "희귀와 엘리트 스폰 증가",
    mythic = "희귀와 엘리트 스폰 증가",
})
mutation("instinct_storm", "Storm Mouth", "폭풍 입", {
    common = "Lightning damage and speed up",
    rare = "Lightning damage and speed up",
    mythic = "Lightning damage and speed up",
}, {
    common = "번개 피해와 속도 증가",
    rare = "번개 피해와 속도 증가",
    mythic = "번개 피해와 속도 증가",
})
mutation("instinct_ember", "Ember Sac", "잉걸 주머니", {
    common = "Fireball damage and radius up",
    rare = "Fireball damage and radius up",
    mythic = "Fireball damage and radius up",
}, {
    common = "화염구 피해와 반경 증가",
    rare = "화염구 피해와 반경 증가",
    mythic = "화염구 피해와 반경 증가",
})
meta("origin_heart", "Origin Heart", "Unlocks the primal dragon lattice", "기원의 심장", "원초 용 격자를 엽니다")

meta("core_mid_clock", "Mid Hunt Clock", "Mid event bonus time +1 sec", "중간 사냥 시계", "중간 이벤트 보너스 시간 +1초")
meta("core_final_clock", "Final Hunt Clock", "Final event bonus time +1 sec", "피니시 시계", "피니시 보너스 시간 +1초")
meta("core_overtime", "Overtime Chamber", "Bonus time cap +1 sec per level", "연장 격실", "보너스 시간 상한 레벨당 +1초")
meta("core_last_window", "Last Window", "Final window minimum time +1 sec per level", "막판 창", "피니시 최소 시간 레벨당 +1초")
meta("core_flow", "Flow Spine", "Move speed +8 per level", "흐름 척추", "이동 속도 레벨당 +8")
meta("core_focus", "Focus Maw", "Event target bite +10 per level", "집중 턱", "이벤트 목표 물기 레벨당 +10")
meta("core_hoard", "Hoard Heart", "Essence gain +8% per level", "비축 심장", "에센스 획득 레벨당 +8%")
meta("core_apex", "Chrono Crown", "Bonus time up and event bite +14", "시간 왕관", "보너스 시간 강화 및 이벤트 물기 +14")

meta("hunt_stride", "Predator Stride", "Move speed +12 per level", "포식자 보폭", "이동 속도 레벨당 +12")
meta("hunt_maw", "Long Maw", "Feeding reach +1.8 per level", "긴 턱", "섭식 반경 레벨당 +1.8")
meta("hunt_bite", "Crush Bite", "Contact bite +8 per level", "분쇄 물기", "접촉 물기 레벨당 +8")
meta("hunt_pursuit", "Pursuit Muscle", "Move speed +16 per level", "추적 근육", "이동 속도 레벨당 +16")
meta("hunt_hook", "Hook Jaw", "Feeding reach +2.2 per level", "갈고리 턱", "섭식 반경 레벨당 +2.2")
meta("hunt_maul", "Maul Crest", "Contact bite +12 per level", "난도 볏", "접촉 물기 레벨당 +12")
meta("hunt_lock", "Lock Fang", "Event target bite +18 per level", "고정 송곳니", "이벤트 목표 물기 레벨당 +18")
meta("hunt_apex", "Apex Predator", "Contact bite +18 and event bite +24", "정점 포식자", "접촉 물기 +18 및 이벤트 물기 +24")

meta("economy_greed", "Greed Gland", "Essence gain +8% per level", "탐욕 샘", "에센스 획득 레벨당 +8%")
meta("economy_scent", "Rare Scent", "Rare spawn chance +1.5% per level", "희귀 향", "희귀 스폰 확률 레벨당 +1.5%")
meta("economy_crown", "Elite Crown", "Elite spawn chance +0.8% per level", "엘리트 왕관", "엘리트 스폰 확률 레벨당 +0.8%")
meta("economy_pull", "Vacuum Pull", "Magnet radius +16 per level", "진공 끌림", "자석 반경 레벨당 +16")
meta("economy_trail", "Trail Heat", "Spawn speed +10% per level", "흔적 열기", "스폰 속도 레벨당 +10%")
meta("economy_brood", "Brood Chamber", "Max field prey +8 per level", "부화 격실", "필드 최대 먹이 레벨당 +8")
meta("economy_gold", "Golden Feast", "Rare and elite value up", "황금 만찬", "희귀 및 엘리트 가치 증가")
meta("economy_apex", "Royal Nest", "Essence gain +14% and field growth up", "왕실 둥지", "에센스 획득 +14% 및 필드 성장 강화")

meta("lightning_root", "Storm Sigil", "Unlock periodic lightning strikes", "폭풍 문양", "주기적 번개 타격 해금")
meta("lightning_shock", "Shock Fang", "Lightning damage +10 per level", "충격 송곳니", "번개 피해 레벨당 +10")
meta("lightning_link", "Link Coil", "Lightning chain count +1 per level", "연쇄 고리", "번개 연쇄 수 레벨당 +1")
meta("lightning_pulse", "Pulse Clock", "Lightning cooldown -0.12 sec per level", "맥동 시계", "번개 재사용 대기 레벨당 -0.12초")
meta("lightning_storm", "Storm Core", "Lightning damage +14 per level", "폭풍 핵", "번개 피해 레벨당 +14")
meta("lightning_arc", "Arc Jaw", "Lightning chain +1 and damage +8", "전류 턱", "번개 연쇄 +1 및 피해 +8")
meta("lightning_relay", "Relay Spine", "Lightning cooldown -0.14 sec per level", "중계 척추", "번개 재사용 대기 레벨당 -0.14초")
meta("lightning_apex", "Tempest Crown", "Lightning damage +18 and chain +1", "폭풍 왕관", "번개 피해 +18 및 연쇄 +1")

meta("fireball_root", "Flame Sigil", "Unlock periodic fireballs", "화염 문양", "주기적 화염구 해금")
meta("fireball_blast", "Blast Gullet", "Fireball damage +9 per level", "폭발 식도", "화염구 피해 레벨당 +9")
meta("fireball_core", "Molten Core", "Explosion radius +12 per level", "용해 핵", "폭발 반경 레벨당 +12")
meta("fireball_count", "Twin Ember", "Projectile count +1 per level", "쌍둥이 잉걸", "투사체 수 레벨당 +1")
meta("fireball_cinder", "Cinder Clock", "Fireball cooldown -0.12 sec per level", "잿불 시계", "화염구 재사용 대기 레벨당 -0.12초")
meta("fireball_salvo", "Salvo Jaw", "Fireball damage +14 and split +1", "연사 턱", "화염구 피해 +14 및 분열 +1")
meta("fireball_furnace", "Furnace Lung", "Radius +18 and cooldown up", "화로 폐", "반경 +18 및 재사용 대기 강화")
meta("fireball_apex", "Inferno Crown", "Damage +18 count +1 radius +20", "지옥불 왕관", "피해 +18 투사체 +1 반경 +20")

return Locale
