collision = {}

function collision.circle(x1,y1,r1, x2,y2,r2)
    local dx = x1 - x2
    local dy = y1 - y2
    local dr = r1 + r2

    return ((dx*dx+dy*dy) < (dr*dr))
end

function collision.rectangle(x1,y1,w1,h1, x2,y2,w2,h2)
    local r1 = x1 + w1
    local b1 = y1 + h1
    local r2 = x2 + w2
    local b2 = y2 + h2

    if x1 > r2 then return false end
    if r1 < x2 then return false end
    if y1 > b2 then return false end
    if b1 < y2 then return false end

    return true
end

function collision.point_rectangle(x,y, rx,ry,rw,rh)
    if x < rx then return false end
    if y < ry then return false end
    if x > (rx+rw) then return false end
    if y > (ry+rh) then return false end

    return true
end

function collision.vector_rectangle(x,y, vx,vy, rx,ry,rw,rh)
    -- reject easiest cases
    if vx>0 then
        if x>=(rx+rw) or (x+vx)<=(rx) then return x+vx, y+vy, false, 1 end
    else
        if x<=rx or (x+vx)>=(rx+rw) then return x+vx, y+vy, false, 1 end
    end

    if vy>0 then
        if y>=(ry+rh) or (y+vy)<=(ry) then return x+vx, y+vy, false, 1 end
    else
        if y<=ry or (y+vy)>=(ry+rh) then return x+vx, y+vy, false, 1 end
    end

    local results = {
        left = {},
        right = {},
        top = {},
        bottom = {}
    }

    if vx~=0 then
        local r = results["left"]
        r.collide, r.cx, r.cy = collision.segment(x,y, x+vx, y+vy, rx,ry,rx,ry+rh)
        if r.collide then r.ratio = (r.cx-x)/vx end

        local r = results["right"]
        r.collide, r.cx, r.cy = collision.segment(x,y, x+vx, y+vy, rx+rw,ry,rx+rw,ry+rh)
        if r.collide then r.ratio = (r.cx-x)/vx end
    end

    if vy~=0 then
        local r = results["top"]
        r.collide, r.cx, r.cy = collision.segment(x,y, x+vx, y+vy, rx,ry,rx+rw,ry)
        if r.collide then r.ratio = (r.cx-x)/vx end

        local r = results["bottom"]
        r.collide, r.cx, r.cy = collision.segment(x,y, x+vx, y+vy, rx,ry+rh,rx+rw,ry+rh)
        if r.collide then r.ratio = (r.cx-x)/vx end
    end

    local best_result = nil
    for k,c in pairs(results) do
        if c.collide then
            if not best_result then
                best_result = results[k]
            elseif c.ratio<best_result.ratio then
                best_result = results[k]
            end
        end
    end

    if not best_result then
        return x+vx, y+vy, false, 1
    end

    return best_result.cx, best_result.cy, true, best_result.ratio
end

function collision.point_ellipse(px,py, ex,ey,radiusx,radiusy)
    local k = ((px-ex)/radiusx)^2 + ((py-ey)/radiusy)^2

    if k > 1 then
        return false
    end

    return true
end

-- line a (points a1 and a2) and line b (points b1, b2)
function collision.line(a1x, a1y, a2x, a2y, b1x, b1y, b2x, b2y)
    local d = ((b2y-b1y) * (a2x-a1x)) - ((b2x-b1x)*(a2y-a1y))

    -- line collide
    if d==0 then
        return false, 0, 0
    end

    local ua = ( ((b2x-b1x)*(a1y-b1y)) - ((b2y-b1y)*(a1x-b1x)) ) / d

    return true, a1x + (a2x-a1x)*ua, a1y + (a2y-a1y)*ua
end

-- segment a (points a1 and a2) and segment b (points b1, b2)
function collision.segment(a1x, a1y, a2x, a2y, b1x, b1y, b2x, b2y)
    local d = ((b2y-b1y) * (a2x-a1x)) - ((b2x-b1x)*(a2y-a1y))

    -- line collide
    if d==0 then
        return false, 0, 0
    end

    local ua = ( ((b2x-b1x)*(a1y-b1y)) - ((b2y-b1y)*(a1x-b1x)) ) / d
    if ua < 0 or ua > 1 then
        return false, 0, 0
    end

    local ub = ( ((a2x-a1x)*(a1y-b1y)) - ((a2y-a1y)*(a1x-b1x)) ) / d
    if ub < 0 or ub > 1 then
        return false, 0, 0
    end

    return true, a1x + (a2x-a1x)*ua, a1y + (a2y-a1y)*ua
end

-- line (p1 and p2)
-- circle: x, y, r
function collision.circle_line(p1x, p1y, p2x, p2y, x, y, r)
    local lp1x = p1x - x
    local lp1y = p1y - y
    local lp2x = p2x - x
    local lp2y = p2y - y

    local dx = lp2x - lp1x
    local dy = lp2y - lp1y

    local a = dx*dx + dy*dy
    local b = 2 * ((dx*lp1x) + (dy*lp1y))
    local c = (lp1x*lp1x) + (lp1y*lp1y) - r*r
    local delta = b*b - (4*a*c)

    if delta < 0 then
        return false
    elseif delta == 0 then
        local u = -b / (2*a)

        return true, p1x + u*dx, p1y + u*dy
    else
        local ds = math.sqrt(delta)
        local u1 = (-b+ds) / (2*a)
		local u2 = (-b-ds) / (2*a)

        return true, p1x + u1*dx, p1y + u1*dy, p1x + u2*dx, p1y + u2*dy
    end
end

-- line (p1 and p2)
-- circle: x, y, r
function collision.circle_segment(p1x, p1y, p2x, p2y, x, y, r)
    local lp1x = p1x - x
    local lp1y = p1y - y
    local lp2x = p2x - x
    local lp2y = p2y - y

    local dx = lp2x - lp1x
    local dy = lp2y - lp1y

    local a = dx*dx + dy*dy
    local b = 2 * ((dx*lp1x) + (dy*lp1y))
    local c = (lp1x*lp1x) + (lp1y*lp1y) - r*r
    local delta = b*b - (4*a*c)

    if delta < 0 then
        return false
    elseif delta == 0 then
        local u = -b / (2*a)
        if u<0 or u>1 then
            return false
        end

        return true, p1x + u*dx, p1y + u*dy
    else
        local ds = math.sqrt(delta)
        local u1 = (-b+ds) / (2*a)
		local u2 = (-b-ds) / (2*a)

        if (u1<0 or u1>1) and (u2<0 or u2>1) then
            return false
        end

        if u1<0 or u1>1 then
            return true, p1x + u2*dx, p1y + u2*dy
        elseif u2<0 or u2>1 then
            return true, p1x + u1*dx, p1y + u1*dy
        end

        return true, p1x + u1*dx, p1y + u1*dy, p1x + u2*dx, p1y + u2*dy
    end
end
