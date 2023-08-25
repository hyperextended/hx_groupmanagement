local menus = {
    boss_menu = true,
    boss_manage_members = true,
    boss_invite_member = true,
}

local function sortAscending(a, b)
    return a.fullName < b.fullName
end

local function onClose(keyPressed)
    if keyPressed == 'Backspace' then
        lib.showMenu('boss_menu')
    end
end

local memberData = {}

local function openBossMenu(name)
    local group = GlobalState[('group.%s'):format(name)]

    lib.registerMenu({
        id = 'boss_menu',
        title = 'Manage Group',
        options = {
            {label = group.label, close = false},
            {label = 'Manage Members'},
            {label = 'Invite Member'},
        },
    },
    function(selected, scrollIndex, args)
        if selected == 2 then
            local members = lib.callback.await('environment:getGroupMembers', 100, group.name)
            local memberGrades = {}

            if not members then return end

            for i = 1, #members do
                local member = members[i]
                memberGrades[member.grade] = memberGrades[member.grade] or {}

                memberGrades[member.grade][#memberGrades[member.grade] + 1] = member
            end

            local grades = table.clone(group.grades)

            table.insert(grades, 1, 'Remove')

            local options = {}

            for i = group.adminGrade, 1, -1 do
                local gradeGroup = memberGrades[i]

                if gradeGroup then
                    table.sort(gradeGroup, sortAscending)

                    for j = 1, #gradeGroup do
                        local member = gradeGroup[j]

                        options[#options + 1] = {
                            label = member.fullName,
                            values = grades,
                            defaultIndex = member.grade + 1,
                            close = false,
                            args = {
                                charId = member.charId
                            }
                        }
                    end
                end
            end

            options[#options + 1] = {
                label = 'Save',
                args = {
                    save = true
                }
            }

            table.wipe(memberData)

            lib.registerMenu({
                id = 'boss_manage_members',
                title = 'Manage Members',
                options = options,
                onSideScroll = function(selected, secondary, args)
                    memberData[args.charId] = secondary - 1
                end,
                onClose = onClose
            },
            function(selected, scrollIndex, args)
                if args.save then
                    TriggerServerEvent('environment:updateMembers', {
                        group = group.name,
                        members = memberData
                    })

                    lib.showMenu('boss_menu')
                end
            end)

            lib.showMenu('boss_manage_members')
        elseif selected == 3 then
            local nearby = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 10, false)

            if not next(nearby) then
                lib.notify({title = 'No suitable players nearby', type = 'error'})
                return lib.showMenu('boss_menu')
            end

            local players = lib.callback.await('environment:getInvitees', 100, group.name)

            if not next(players) then
                lib.notify({title = 'No suitable players nearby', type = 'error'})
                return lib.showMenu('boss_menu')
            end

            local grades = table.clone(group.grades)
            local options = {}

            for i = 1, #players do
                local player = players[i]

                options[#options + 1] = {
                    label = player.name,
                    values = grades,
                    args = {
                        id = player.id
                    }
                }
            end

            lib.registerMenu({
                id = 'boss_invite_member',
                title = 'Invite Member',
                options = options,
                onClose = onClose
            },
            function(selected, scrollIndex, args)
                TriggerServerEvent('environment:inviteMember', {
                    id = args.id,
                    group = group.name,
                    grade = scrollIndex
                })

                lib.showMenu('boss_menu')
            end)

            lib.showMenu('boss_invite_member')
        end
    end)

    lib.showMenu('boss_menu')
end

local function chooseBossGroup()
    local options = {}

    for name, grade in pairs(player.groups) do
        local group = GlobalState[('group.%s'):format(name)]

        if grade == group.adminGrade then
            options[#options + 1] = {
                value = group.name,
                label = group.label
            }
        end
    end

    if not next(options) then return end

    local name = options[1].value

    if #options > 1 then
        table.sort(options, function(a, b)
            return a.label < b.label
        end)

        local result = lib.inputDialog('Choose Group to Manage', {
            { type = 'select', options = options }
        })

        Wait(100)

        name = result and result[1]
    end

    if name then
        openBossMenu(name)
    end
end

lib.addKeybind({
    name = 'bossmenu',
    description = 'Open a Boss Menu',
    defaultKey = 'F6',
    onReleased = function(self)
        if menus[lib.getOpenMenu()] then
            lib.hideMenu()
        else
            chooseBossGroup()
        end
    end
})

lib.callback.register('environment:groupInvitation', function(data)
    while IsNuiFocused() or IsNuiFocusKeepingInput() do
        Wait(0)
    end

    return lib.alertDialog({
        header = 'Group Invitation',
        content = ('You have been invited to join %s at the position of %s (%s)'):format(data.group, data.gradeLabel, data.grade),
        centered = true,
        labels = {
            confirm = 'Accept',
            cancel = 'Reject'
        }
    })
end)
