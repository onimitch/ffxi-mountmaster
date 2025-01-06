addon.name = 'mountmaster'
addon.author = 'onimitch'
addon.desc = 'Manage mount and dismount from one command. Set a favorite mount or let it choose randomly.'
addon.version = '1.0'
addon.link = 'https://github.com/onimitch/'

-- Ashita libs
require('common')
local ffi = require('ffi')
local settings = require('settings')
local chat = require('chat')

-- Mount master files
local encoding = require('encoding')

local mountmaster = {
    default_settings = T{
        selected_mount = 0, -- Random
        mount_music = 0, -- Set to 0 to disable mount music
    },
    settings = T{},
    held_mounts = T{},
    lang_id = 1, -- 1 = en, 2 = ja
    mount_status_id = 252,
}

local MOUNT_NAMES = T{
    [3072] = { 'Chocobo', 'マイチョコボ' },
    [3073] = { 'Raptor', 'ラプトル' },
    [3074] = { 'Tiger', '剣虎' },
    [3075] = { 'Crab', 'クラブ' },
    [3076] = { 'Red Crab', '赤クラブ' },
    [3077] = { 'Bomb', 'ボム' },
    [3078] = { 'Sheep', '大羊' },
    [3079] = { 'Morbol', 'モルボル' },
    [3080] = { 'Crawler', 'クロウラー' },
    [3081] = { 'Fenrir', 'フェンリル' },
    [3082] = { 'Beetle', '甲虫' },
    [3083] = { 'Moogle', 'モーグリ' },
    [3084] = { 'Magic Pot', 'マジックポット' },
    [3085] = { 'Tulfaire', 'トゥルフェイア' },
    [3086] = { 'Warmachine', 'ウォーマシン' },
    [3087] = { 'Xzomit', 'ゾミト' },
    [3088] = { 'Hippogryph', 'ヒポグリフ' },
    [3089] = { 'Spectral Chair', '悪霊の椅子' },
    [3090] = { 'Spheroid', 'スフィアロイド' },
    [3091] = { 'Omega', 'オメガ' },
    [3092] = { 'Coeurl', 'クァール' },
    [3093] = { 'Goobbue', 'グゥーブー' },
    [3094] = { 'Raaz', 'ラズ' },
    [3095] = { 'Levitus', 'レヴィデイス' },
    [3096] = { 'Adamantoise', 'アダマンタス' },
    [3097] = { 'Dhalmel', 'ダルメル' },
    [3098] = { 'Doll', 'ドール' },
    [3099] = { 'Golden Bomb', 'ゴールデンボム' },
    [3100] = { 'Buffalo', 'バッファロー' },
    [3101] = { 'Wivre', 'ウィヴル' },
    [3102] = { 'Red Raptor', '赤ラプトル' },
    [3103] = { 'Iron Giant', '鉄巨人' },
    [3104] = { 'Byakko', '白虎' },
    [3105] = { 'Noble Chocobo', 'ノーブルチョコボ' },
    [3106] = { 'Ixion', 'イクシオン' },
    [3107] = { 'Phuabo', 'フワボ' },
}

mountmaster.initialize = function()
    mountmaster.held_mounts = mountmaster.get_available_mounts()
end

mountmaster.set_favorite_mount = function(mount_name)
    if mount_name == 'random' then
        mountmaster.settings.selected_mount = 0
        print(chat.header(addon.name):append(chat.success('Set mount: Random')))
    else
        local mount_name_lower = mount_name:lower()
        local mount_id, _ = MOUNT_NAMES:find_if(function(entry)
            -- Note we don't do lowercase conversion on the Japanese names (index 2), it'll corrupt the data
            return entry[1]:lower() == mount_name_lower or entry[2] == mount_name
        end)
        if mount_id ~= nil then
            mountmaster.settings.selected_mount = mount_id
            print(chat.header(addon.name):append(chat.success('Set mount: %s'):fmt(encoding:UTF8_To_ShiftJIS(mount_name))))
        else
            print(chat.header(addon.name):append(chat.error('Unrecognised mount name: %s'):fmt(encoding:UTF8_To_ShiftJIS(mount_name))))
        end
    end

    settings.save()
end

mountmaster.get_available_mounts = function()
    local player = AshitaCore:GetMemoryManager():GetPlayer()

    local mount_list = {}
    for k, _ in pairs(MOUNT_NAMES) do
        if player:HasKeyItem(k) then
            table.insert(mount_list, k)
        end
    end

    return mount_list
end

mountmaster.get_random_mount = function()
    local rand = math.random(#mountmaster.held_mounts)
    return mountmaster.held_mounts[rand]
end

mountmaster.mount_up = function(mount_id)
    if mount_id == nil or mount_id == 0 then
        mount_id = mountmaster.get_random_mount()
    end

    local mount_name = MOUNT_NAMES[mount_id][mountmaster.lang_id]
    AshitaCore:GetChatManager():QueueCommand(1, string.format('/mount "%s"', encoding:UTF8_To_ShiftJIS(mount_name)))
end

mountmaster.dismount = function()
    AshitaCore:GetChatManager():QueueCommand(1, '/dismount')
end

mountmaster.is_mounted = function()
    local buff_list = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs()
    for _, buff in pairs(buff_list) do
        if buff == mountmaster.mount_status_id then
            return true
        end
    end
    return false
end

-- Ashita events

ashita.events.register('load', 'mountmaster_load', function()
    mountmaster.settings = settings.load(default_settings)

    -- Get language
    local lang = AshitaCore:GetConfigurationManager():GetInt32('boot', 'ashita.language', 'playonline', 2)
    mountmaster.lang_id = 1 -- en
    if lang == 1 then
        mountmaster.lang_id = 2 -- ja
    end

    mountmaster.initialize()

    -- Register for future settings updates
    settings.register('settings', 'mountmaster_settings_update', function(s)
        if (s ~= nil) then
            mountmaster.settings = s
            mountmaster.initialize()
        end
        settings.save()
    end)
end)

ashita.events.register('packet_in', 'packet_in_cb', function(e)
    -- Key items changed
    if e.id == 0x055 then
        -- Reload available mounts
        mountmaster.held_mounts = mountmaster.get_available_mounts()
    end

    -- Zone in
    if e.id == 0x0A then
        local song_id = mountmaster.settings.mount_music ~= nil and mountmaster.settings.mount_music or 0
        ashita.bits.pack_be(e.data_modified_raw, 0, 0x5E, song_id, 16)
    end

    -- Music update
    if e.id == 0x5F then
        local slot = struct.unpack('H', e.data, 0x04 + 1)
        -- | Slot | Purpose |
        -- | --- | --- |
        -- | `0` | _Zone (Day)_ |
        -- | `1` | _Zone (Night)_ |
        -- | `2` | _Combat (Solo)_ |
        -- | `3` | _Combat (Party)_ |
        -- | `4` | _Mount_ |
        -- | `5` | _Dead_ |
        -- | `6` | _Mog House_ |
        -- | `7` | _Fishing_ |
        if slot == 4 then
            if mountmaster.settings.mount_music == 0 or mountmaster.settings.mount_music == nil then
                e.blocked = true
            else
                -- local song = struct.unpack('H', e.data, 0x06 + 1)
                local ptr = ffi.cast('uint8_t*', e.data_modified_raw);
                ptr[0x06] = mountmaster.settings.mount_music
            end
        end
    end
end)

ashita.events.register('command', 'mountmaster_command', function(e)
    -- Parse the command arguments..
    local args = e.command:args()
    if #args == 0 or args[1] ~= '/mount' then
        return
    end

    -- Handle: /mount
    if #args == 1 then
        e.blocked = true

        if mountmaster.is_mounted() then
            mountmaster.dismount()
        else
            mountmaster.mount_up(mountmaster.settings.selected_mount)
        end
        return
    end

    -- Handle: /mount random
    if #args == 2 and args[2] == 'random' then
        e.blocked = true

        if mountmaster.is_mounted() then
            mountmaster.dismount()
        else
            mountmaster.mount_up(0)
        end
        return
    end

    -- Handle: /mount set <name>
    if #args >= 2 and args[2] == 'set' then
        e.blocked = true

        local remain_args_count = #args - 2
        if remain_args_count == 0 then
            mountmaster.set_favorite_mount('random')
        else
            local mount_name = args:slice(3, #args - 2):join(' ')
            mountmaster.set_favorite_mount(encoding:ShiftJIS_To_UTF8(mount_name))
        end
        return
    end

    -- Handle: /mount bgm <song_id>
    if #args == 3 and args[2] == 'bgm' then
        e.blocked = true

        mountmaster.settings.mount_music = tonumber(args[3])
        settings.save()
        return
    end

    -- Otherwise pass command through to the game for /mount <mount name>
end)