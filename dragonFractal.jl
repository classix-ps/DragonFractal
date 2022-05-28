# Visualizing the dragon fractal

using Gtk, Graphics

struct IntCoord
    x::Int
    y::Int
end

function Base.:+(p1::IntCoord, p2::IntCoord)
    return IntCoord(p1.x + p2.x, p1.y + p2.y)
end

function Base.:-(p1::IntCoord, p2::IntCoord)
    return IntCoord(p1.x - p2.x, p1.y - p2.y)
end

mutable struct DragonFractal
    lines::Vector{IntCoord}
    rotatedLines::Vector{IntCoord}
end

function rotate(p::IntCoord)
    return IntCoord(-p.y, p.x)
end

function calculateNextLines(frac::DragonFractal)
    offset = last(frac.lines) - last(frac.rotatedLines)

    currentLines = length(frac.lines)
    for i = (currentLines-1):-1:1
        newPoint = frac.rotatedLines[i] + offset
        push!(frac.lines, newPoint)
        push!(frac.rotatedLines, rotate(newPoint))
    end
end

# TODO: Only draw what's in view
# TODO: Zoom around center of canvas instead of origin
function drawFractal(frac::DragonFractal, off::IntCoord, scale::Real)
    @guarded draw(c) do widget
        ctx = getgc(c)
        h = height(c)
        w = width(c)
    
        set_source_rgb(ctx, 0, 0, 0)
        for i = 2:length(frac.lines)
            move_to(ctx, w / 2 + frac.lines[i-1].x * 10 * scale + off.x, h / 2 + frac.lines[i-1].y * 10 * scale + off.y)
            line_to(ctx, w / 2 + frac.lines[i].x * 10 * scale + off.x, h / 2 + frac.lines[i].y * 10 * scale + off.y)
            stroke(ctx)
        end
    end
end

function drawNewLines(frac::DragonFractal, off::IntCoord, scale::Real)
    @guarded draw(c) do widget
        ctx = getgc(c)
        h = height(c)
        w = width(c)
    
        set_source_rgb(ctx, 0, 0, 0)
        for i = (ceil(Int, length(frac.lines) / 2) + 1):length(frac.lines)
            move_to(ctx, w / 2 + frac.lines[i-1].x * 10 * scale + off.x, h / 2 + frac.lines[i-1].y * 10 * scale + off.y)
            line_to(ctx, w / 2 + frac.lines[i].x * 10 * scale + off.x, h / 2 + frac.lines[i].y * 10 * scale + off.y)
            stroke(ctx)
        end
    end
end

function resetCanvas()
    @guarded draw(c) do widget
        ctx = getgc(c)
        h = height(c)
        w = width(c)
    
        set_source_rgb(ctx, 1, 1, 1)
        rectangle(ctx, 0, 0, w, h)
        fill(ctx)
    end
end

c = GtkCanvas()
win = GtkWindow(c, "Canvas")

initialPoint = IntCoord(0, 1)
fractal = DragonFractal([IntCoord(0, 0), initialPoint], [IntCoord(0, 0), rotate(initialPoint)])

offset = IntCoord(0, 0)
oldMousePos = IntCoord(0, 0)
zoom = 1.0

panning = false

drawFractal(fractal, offset, zoom)

function keypress(w, event)
    #print(event.keyval)
    if event.keyval == 65307 # esc
        exit(86)
    elseif event.keyval == 32 # space
        calculateNextLines(fractal)
        drawNewLines(fractal, offset, zoom)
    elseif event.keyval == 99 # c
        global offset = IntCoord(0, 0)
        resetCanvas()
        drawFractal(fractal, offset, zoom)
    end
end
signal_connect(keypress, win, "key-press-event")

function mousepress(w, event)
    if event.button == 1 # left-click
        global oldMousePos = IntCoord(event.x, event.y)
        global panning = true
    end
end
signal_connect(mousepress, win, "button-press-event")

function mouserelease(w, event)
    if event.button == 1 # left-click
        global panning = false
    end
end
signal_connect(mouserelease, win, "button-release-event")

function mousemove(w, event)
    if panning
        mousePos = IntCoord(event.x, event.y)
        deltaPos = mousePos - oldMousePos
        global offset += deltaPos
        global oldMousePos = mousePos
        resetCanvas()
        drawFractal(fractal, offset, zoom)
    end
end
signal_connect(mousemove, win, "motion-notify-event")

function scroll(w, event)
    if event.direction == 0 # up
        global zoom = min(100.0, zoom * 1.12)
    elseif event.direction == 1 # down
        global zoom = max(0.01, zoom / 1.12)
    end
    resetCanvas()
    drawFractal(fractal, offset, zoom)
end
signal_connect(scroll, win, "scroll-event")

cond = Condition()
endit(w) = notify(cond)
signal_connect(endit, win, :destroy)
show(c)
wait(cond)