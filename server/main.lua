lib.callback.register('environment:getGroupMembers', function(source, groupName)
    local player = Ox.GetPlayer(source)
    local group = GlobalState[('group.%s'):format(groupName)]

    if not player.hasGroup(group.name, group.adminGrade) then return false end

    return MySQL.query.await('SELECT character_groups.grade AS grade, character_groups.charid AS charid, CONCAT(characters.firstname, " ", characters.lastname) AS fullName FROM character_groups LEFT JOIN characters ON character_groups.charid = characters.charid WHERE character_groups.name = ?', {groupName})
end)

RegisterServerEvent('environment:updateMembers', function(data)
    local group = GlobalState[('group.%s'):format(data.group)]
    local player = Ox.GetPlayer(source)

    if not player.hasGroup(group.name, group.adminGrade) then return end

    local updateMembers = {}
    local removeMembers = {}

    for id, grade in pairs(data.members) do
        local member = Ox.GetPlayerByFilter({charid = id})

        if member then
            if member.getGroup(group.name) ~= grade then
                member.setGroup(group.name, grade)
            end
        else
            if grade == 0 then
                removeMembers[#removeMembers + 1] = {id, group}
            else
                updateMembers[#updateMembers + 1] = {grade, id, group.name}
            end
        end
    end

    if next(updateMembers) then
        MySQL.prepare('UPDATE character_groups SET grade = ? WHERE charid = ? AND name = ?', updateMembers)
    end

    if next(removeMembers) then
        MySQL.prepare('DELETE FROM character_groups WHERE charid = ? and name = ?', removeMembers)
    end
end)

RegisterServerEvent('environment:inviteMember', function(data)
    local group = GlobalState[('group.%s'):format(data.group)]
    local player = Ox.GetPlayer(source)

    if not player.hasGroup(group.name, group.adminGrade) then return end

    local target = Ox.GetPlayer(data.id)

    local response = lib.callback.await('environment:groupInvitation', target.source, {
        group = group.name,
        grade = data.grade,
        gradeLabel = group.grades[data.grade]
    })

    if response == 'confirm' then
        target.setGroup(group.name, data.grade)
    end
end)

lib.callback.register('environment:getInvitees', function(source, groupName)
    local player = Ox.GetPlayer(source)
    local group = GlobalState[('group.%s'):format(groupName)]

    if not player.hasGroup(group.name, group.adminGrade) then return false end

    local invitees = {}
    local playerPos = player.getCoords()
    local players = Ox.GetPlayers()
    local len = #players

    for i = 1, len do
        local nearbyPlayer = players[i]

        if nearbyPlayer.source ~= player.source and not nearbyPlayer.hasGroup(group.name) and #(nearbyPlayer.getCoords() - playerPos) < 10 then
            invitees[#invitees + 1] = {
                name = nearbyPlayer.name,
                id = nearbyPlayer.source
            }
        end
    end

    return invitees
end)
