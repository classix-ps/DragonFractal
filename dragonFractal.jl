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

function drawFractal(frac::DragonFractal)
    @guarded draw(c) do widget
        ctx = getgc(c)
        h = height(c)
        w = width(c)
    
        for i = 2:length(fractal.lines)
            rectangle(ctx, w / 2 + fractal.lines[i-1].x * 10, h / 2 + fractal.lines[i-1].y * 10, (fractal.lines[i] - fractal.lines[i-1]).x * 10 + 1, (fractal.lines[i] - fractal.lines[i-1]).y * 10 + 1)
            set_source_rgb(ctx, 0, 0, 0)
            fill(ctx)
        end
    end
end

c = GtkCanvas()
win = GtkWindow(c, "Canvas")

initialPoint = IntCoord(0, 1)
fractal = DragonFractal([IntCoord(0, 0), initialPoint], [IntCoord(0, 0), rotate(initialPoint)])

drawFractal(fractal)

function keycall(w, event)
    ch = Char(event.keyval)
    if ch == 'q'
        exit(86)
    else
        calculateNextLines(fractal)
        drawFractal(fractal)
    end
end
signal_connect(keycall, win, "key-press-event")

cond = Condition()
endit(w) = notify(cond)
signal_connect(endit, win, :destroy)
showall(win)
wait(cond)