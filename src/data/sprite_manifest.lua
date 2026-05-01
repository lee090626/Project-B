local SpriteManifest = {
    player = {
        mode = "sheet",
        path = "assets/sprites/player_walk_sheet_v2.png",
        frameWidth = 272,
        frameHeight = 352,
        columns = 4,
        rows = 2,
        frameCount = 8,
        fps = 8,
        idleFrame = 1,
        targetScale = 4,
    },
    world = {
        fireball = {
            mode = "sheet",
            path = "assets/sprites/fireball_sprite_sheet.png",
            frameWidth = 256,
            frameHeight = 144,
            columns = 6,
            rows = 1,
            frameCount = 6,
            fps = 12,
            originX = 202,
            originY = 72,
        },
        boss = {
            mode = "image",
            path = "assets/sprites/boss_final_v2.png",
            width = 256,
            height = 256,
        },
        bossWeakPoint = {
            mode = "image",
            path = "assets/sprites/boss_weak_point_v2.png",
            width = 256,
            height = 256,
        },
        monsters = {
            common = {
                mode = "image",
                path = "assets/sprites/monster_common_v2.png",
                width = 256,
                height = 256,
            },
            rare = {
                mode = "image",
                path = "assets/sprites/monster_rare_v2.png",
                width = 256,
                height = 256,
            },
            elite = {
                mode = "image",
                path = "assets/sprites/monster_elite_v2.png",
                width = 256,
                height = 256,
            },
        },
    },
}

return SpriteManifest
