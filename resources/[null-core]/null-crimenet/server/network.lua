-- ============================================================================
-- CRIMENET - Network Graph Builder
-- Computes the visual network tree for a player based on their contacts.
-- ============================================================================

-- Build the network graph for a specific player
-- @param playerIdentifier: the player viewing the network
-- @param resolvedContacts: list of resolved contact objects (from CrimeNet:getData)
-- @return { nodes = [...], edges = [...], clusters = [...] }
function CrimeNet.BuildNetworkGraph(playerIdentifier, resolvedContacts, goFastContacts)
    local nodes = {}
    local edges = {}
    local clusters = {}

    -- Track which gang bosses we've found among contacts
    local gangMap = {}      -- [gangname] = { boss = identifier|nil, members = { identifier, ... } }
    local contactMap = {}   -- [identifier] = resolvedContact
    local firstGangContact = {} -- [gangname] = first contact identifier from that gang

    -- Index contacts by identifier and sort by gang
    for _, c in ipairs(resolvedContacts) do
        contactMap[c.identifier] = c

        if c.gangname and c.gangname ~= "" then
            if not gangMap[c.gangname] then
                gangMap[c.gangname] = { boss = nil, members = {}, label = c.gangLabel or c.gangname }
                -- Track the first contact we see from this gang
                firstGangContact[c.gangname] = c.identifier
            end
            table.insert(gangMap[c.gangname], c.identifier) -- backwards compat
            table.insert(gangMap[c.gangname].members, c.identifier)
            if c.is_boss then
                gangMap[c.gangname].boss = c.identifier
            end
        end
    end

    -- Player center node
    table.insert(nodes, {
        id = playerIdentifier,
        type = "player",
        ring = 0,
    })

    -- Determine which contacts go into gang clusters vs standalone
    -- Also track if boss should connect through existing gang member
    local clusteredIds = {}
    local bossThroughMember = {} -- [bossId] = memberId (boss connects through this member)

    if CrimeNet.Config.Graph.showGangClusters then
        for gangname, gang in pairs(gangMap) do
            if gang.boss and #gang.members > 1 then
                -- This gang has a boss in contacts AND other members → create cluster
                local clusterMembers = {}
                for _, mid in ipairs(gang.members) do
                    clusteredIds[mid] = true
                    table.insert(clusterMembers, mid)
                end
                table.insert(clusters, {
                    id = "gang_" .. gangname,
                    label = gang.label,
                    gangname = gangname,
                    boss = gang.boss,
                    members = clusterMembers,
                    -- If we had a member before adding the boss, link through them
                    bridgeMember = firstGangContact[gangname] ~= gang.boss and firstGangContact[gangname] or nil,
                })
                -- Mark boss to connect through the bridge member if exists
                if firstGangContact[gangname] and firstGangContact[gangname] ~= gang.boss then
                    bossThroughMember[gang.boss] = firstGangContact[gangname]
                end
            end
        end
    end

    -- Add standalone contacts (not in any cluster)
    for _, c in ipairs(resolvedContacts) do
        if not clusteredIds[c.identifier] then
            local nodeType = "contact"
            if c.is_important then nodeType = "important" end
            if c.is_boss then nodeType = "boss" end

            table.insert(nodes, {
                id = c.identifier,
                type = nodeType,
                name = c.name,
                gangname = c.gangname,
                gangLabel = c.gangLabel,
                is_important = c.is_important,
                admin_label = c.admin_label,
                description = c.description,
                avatar_url = c.avatar_url,
                online = c.online,
                is_fake = c.is_fake,
                ring = 1,
            })

            -- Edge: player → contact
            table.insert(edges, {
                from = playerIdentifier,
                to = c.identifier,
                type = "direct",
            })
        end
    end

    -- Add cluster nodes
    for _, cluster in ipairs(clusters) do
        -- Boss node (center of cluster, or connected through bridge member)
        local bossContact = contactMap[cluster.boss]
        if bossContact then
            -- Determine ring: if connected through member, push to ring 2, else ring 1
            local bossRing = 1
            local bossEdgeFrom = playerIdentifier
            local bossEdgeType = "gang_boss"

            -- If boss should connect through an existing gang member
            if cluster.bridgeMember and bossThroughMember[cluster.boss] then
                bossRing = 2
                bossEdgeFrom = bossThroughMember[cluster.boss]
                bossEdgeType = "gang_boss_via_member"
            end

            table.insert(nodes, {
                id = bossContact.identifier,
                type = "boss",
                name = bossContact.name,
                gangname = bossContact.gangname,
                gangLabel = bossContact.gangLabel,
                is_important = bossContact.is_important,
                admin_label = bossContact.admin_label,
                description = bossContact.description,
                avatar_url = bossContact.avatar_url,
                online = bossContact.online,
                is_fake = bossContact.is_fake,
                ring = bossRing,
                cluster = cluster.id,
            })

            -- Edge: player or bridge member → boss
            table.insert(edges, {
                from = bossEdgeFrom,
                to = bossContact.identifier,
                type = bossEdgeType,
            })
        end

        -- Member nodes (around boss or directly connected)
        for _, mid in ipairs(cluster.members) do
            if mid ~= cluster.boss then
                local memberContact = contactMap[mid]
                if memberContact then
                    local mType = "gang_member"
                    if memberContact.is_important then mType = "important" end

                    -- If this is the bridge member, they connect directly to player
                    -- Other members connect to boss
                    local memberRing = 2
                    local memberEdgeFrom = cluster.boss
                    local memberEdgeType = "gang_member"

                    if mid == cluster.bridgeMember then
                        memberRing = 1
                        memberEdgeFrom = playerIdentifier
                        memberEdgeType = "gang_bridge"
                    end

                    table.insert(nodes, {
                        id = memberContact.identifier,
                        type = mType,
                        name = memberContact.name,
                        gangname = memberContact.gangname,
                        gangLabel = memberContact.gangLabel,
                        is_important = memberContact.is_important,
                        admin_label = memberContact.admin_label,
                        description = memberContact.description,
                        avatar_url = memberContact.avatar_url,
                        online = memberContact.online,
                        is_fake = memberContact.is_fake,
                        ring = memberRing,
                        cluster = cluster.id,
                    })

                    -- Edge: boss → member (or player → bridge member)
                    table.insert(edges, {
                        from = memberEdgeFrom,
                        to = memberContact.identifier,
                        type = memberEdgeType,
                    })
                end
            end
        end
    end

    -- ========================================================================
    -- DEFAULT NPC CONTACTS BRANCH (L'Intermédiaire → GoFast chain)
    -- ========================================================================
    if CrimeNet.Config.DefaultContact then
        local dc = CrimeNet.Config.DefaultContact
        local npcNodeId = "npc:" .. dc.id

        table.insert(nodes, {
            id = npcNodeId,
            type = "npc_contact",
            name = dc.name,
            is_important = true,
            admin_label = dc.label,
            description = dc.description,
            ring = 1,
            cluster = "npc_chain",
            is_npc = true,
        })

        -- Edge: player → L'Intermédiaire
        table.insert(edges, {
            from = playerIdentifier,
            to = npcNodeId,
            type = "npc_chain",
        })

        -- GoFast NPC contacts chain
        if CrimeNet.Config.NPCContacts then
            -- Build lookup for givenBy resolution
            local npcLookup = {}
            npcLookup[dc.id] = npcNodeId

            -- Get player XP to determine which contacts are unlocked
            local playerXP = 0
            if goFastContacts then
                playerXP = goFastContacts.xp or 0
            end

            for _, npc in ipairs(CrimeNet.Config.NPCContacts) do
                local unlocked = playerXP >= (npc.unlockXP or 0)
                local nid = "npc:" .. npc.id
                npcLookup[npc.id] = nid

                -- Determine which node this connects to
                local parentId = npcLookup[npc.givenBy] or npcNodeId
                local ring = 2
                -- Count depth from intermediaire
                local depth = 2
                local checkId = npc.givenBy
                while checkId and checkId ~= dc.id do
                    depth = depth + 1
                    for _, inner in ipairs(CrimeNet.Config.NPCContacts) do
                        if inner.id == checkId then
                            checkId = inner.givenBy
                            break
                        end
                    end
                end
                ring = depth

                table.insert(nodes, {
                    id = nid,
                    type = "npc_contact",
                    name = unlocked and npc.name or (npc.alias or "???"),
                    is_important = unlocked,
                    admin_label = npc.label,
                    description = unlocked and npc.description or "???",
                    ring = ring,
                    cluster = "npc_chain",
                    is_npc = true,
                    locked = not unlocked,
                })

                table.insert(edges, {
                    from = parentId,
                    to = nid,
                    type = "npc_chain",
                })
            end
        end

        -- Add cluster for the NPC chain
        local npcMembers = { npcNodeId }
        if CrimeNet.Config.NPCContacts then
            for _, npc in ipairs(CrimeNet.Config.NPCContacts) do
                table.insert(npcMembers, "npc:" .. npc.id)
            end
        end
        table.insert(clusters, {
            id = "npc_chain",
            label = "Réseau Souterrain",
            gangname = "_npc",
            boss = npcNodeId,
            members = npcMembers,
        })
    end

    return {
        nodes = nodes,
        edges = edges,
        clusters = clusters,
    }
end

print("[CrimeNet] Network graph builder loaded")
