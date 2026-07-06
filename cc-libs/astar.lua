local function astar(start, goal, get_neighbors, cost_fn, heuristic_fn, start_to_goal)
    local open = { start }
    local parent = {}
    local f_score = {
        [start] = 0,
    }
    local h_score = {
        -- [start] = f_score[start] + heuristic_fn(start, goal),
    }

    local function pop_lowest_h()
        local lowest = nil
        local score = nil
        local lowest_i = nil
        for i, key in ipairs(open) do
            local s = h_score[key]
            if lowest == nil or s < score then
                lowest = key
                score = s
                lowest_i = i
            end
        end
        table.remove(open, lowest_i)
        return lowest
    end

    -- Compute graph weights
    while #open > 0 do
        -- Get node in open with lowest f + h score and remove it from open
        local current = pop_lowest_h()

        -- If the goal is found, stop searching
        if current == goal then
            break
        end

        -- Iterate over all neighbors of current
        local neighbors = get_neighbors(current)
        for neighbor, weight in pairs(neighbors) do
            -- Calculate f score for neighbor
            local dist = f_score[current] + cost_fn(current, neighbor)

            -- If current is a shorter path to neighbor
            if f_score[neighbor] == nil or dist < f_score[neighbor] then
                -- Update parent and scores
                parent[neighbor] = current
                f_score[neighbor] = dist
                h_score[neighbor] = dist + heuristic_fn(neighbor, goal)

                -- Push neighbor into open list
                open[#open + 1] = neighbor
            end
        end
    end

    -- Find path
    local path = {}
    local curr = goal
    while curr ~= nil and curr ~= start do
        path[#path + 1] = curr
        curr = parent[curr]
    end

    -- Check full path was found
    if curr ~= start then
        return nil
    end

    -- Add start to the path
    path[#path + 1] = curr

    -- Reverse path to be from start to goal
    if start_to_goal then
        local reversed = {}
        for i = 1, #path do
            reversed[#path - (i - 1)] = path[i]
        end
        return reversed
    end

    -- Returns path from goal to start
    return path
end

return astar
