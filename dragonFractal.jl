# Visualizing the dragon fractal (https://en.wikipedia.org/wiki/Dragon_curve)
# Github: https://github.com/classix-ps/DragonFractal

using Gtk

struct IntCoord
    x::Int64
    y::Int64
end

struct FloatCoord
    x::Float64
    y::Float64
end

function Base.:+(p1::Union{IntCoord, FloatCoord}, p2::Union{IntCoord, FloatCoord})
    if typeof(p1) == FloatCoord || typeof(p2) == FloatCoord
        return FloatCoord(p1.x + p2.x, p1.y + p2.y)
    else
        return IntCoord(p1.x + p2.x, p1.y + p2.y)
    end
end

function Base.:-(p1::Union{IntCoord, FloatCoord}, p2::Union{IntCoord, FloatCoord})
    if typeof(p1) == FloatCoord || typeof(p2) == FloatCoord
        return FloatCoord(p1.x - p2.x, p1.y - p2.y)
    else
        return IntCoord(p1.x - p2.x, p1.y - p2.y)
    end
end

function Base.:*(p::Union{IntCoord, FloatCoord}, s::Real)
    if typeof(p) == FloatCoord
        return FloatCoord(p.x * s, p.y * s)
    else
        return IntCoord(round(Int, p.x * s), round(Int, p.y * s))
    end 
end

function Base.:/(p::Union{IntCoord, FloatCoord}, s::Real)
    if s == 0
        throw(DomainError(s, "scalar must be non-zero"))
    end

    if typeof(p) == FloatCoord
        return FloatCoord(p.x / s, p.y / s)
    else
        return IntCoord(round(Int, p.x / s), round(Int, p.y / s))
    end 
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

function planeToCanvas(p::IntCoord, off::FloatCoord, scale::Real)
    return FloatCoord((p.x + off.x) * scale, (p.y + off.y) * scale)
end

function canvasToPlane(p::FloatCoord, off::FloatCoord, scale::Real)
    return FloatCoord(p.x / scale - off.x, p.y / scale - off.y)
end

function inBounds(p::IntCoord, width::Real, height::Real)
    q = planeToCanvas(p, offset, zoom)
    return 0 < q.x < width && 0 < q.y < height
end

# TODO: Only draw what's in view without iterating over all lines
function drawFractal(frac::DragonFractal, off::FloatCoord, scale::Real, onlyDrawNewLines::Bool = false)
    @guarded draw(c) do widget
        ctx = getgc(c)
        sWidth = width(c)
        sHeight = height(c)
    
        set_source_rgb(ctx, 0, 0, 0)
        itBegin = onlyDrawNewLines ? (ceil(Int, length(frac.lines) / 2) + 1) : 2
        for i = itBegin:length(frac.lines)
            if !inBounds(frac.lines[i-1], sWidth, sHeight) && !inBounds(frac.lines[i], sWidth, sHeight)
                continue
            end

            p1 = planeToCanvas(frac.lines[i-1], off, scale)
            p2 = planeToCanvas(frac.lines[i], off, scale)

            move_to(ctx, p1.x, p1.y)
            line_to(ctx, p2.x, p2.y)
            stroke(ctx)
        end
    end
end

function resetCanvas()
    @guarded draw(c) do widget
        ctx = getgc(c)
    
        set_source_rgb(ctx, 1, 1, 1)
        rectangle(ctx, 0, 0, width(c), height(c))
        fill(ctx)
    end
end

w = 800
h = 800

c = GtkCanvas()
win = GtkWindow(c, "Canvas", w, h)

initialPoint = IntCoord(0, 1)
fractal = DragonFractal([IntCoord(0, 0), initialPoint], [IntCoord(0, 0), rotate(initialPoint)])

oldMousePos = IntCoord(0, 0)
zoom = 10.0
offset = FloatCoord(w / 2.0, h / 2.0) / zoom

panning = false

drawFractal(fractal, offset, zoom)

function keypress(widget, event)
    #print(event.keyval)
    if event.keyval == 65307 # esc
        exit(86)
    elseif event.keyval == 32 # space
        calculateNextLines(fractal)
        drawFractal(fractal, offset, zoom, true)
    elseif event.keyval == 99 # c
        global offset = FloatCoord(0.0, 0.0)
        resetCanvas()
        drawFractal(fractal, offset, zoom)
    end
end
signal_connect(keypress, win, "key-press-event")

function mousepress(widget, event)
    if event.button == 1 # left-click
        global oldMousePos = IntCoord(event.x, event.y)
        global panning = true
    end
end
signal_connect(mousepress, c, "button-press-event")

function mouserelease(widget, event)
    if event.button == 1 # left-click
        global panning = false
    end
end
signal_connect(mouserelease, c, "button-release-event")

function mousemove(widget, event)
    if panning
        mousePos = FloatCoord(event.x, event.y)
        deltaPos = mousePos - oldMousePos
        global offset += deltaPos / zoom
        global oldMousePos = mousePos
        resetCanvas()
        drawFractal(fractal, offset, zoom)
    end
end
signal_connect(mousemove, c, "motion-notify-event")

function scroll(widget, event)
    if event.direction != 0 && event.direction != 1
        return
    end

    currentWidth = width(c)
    currentHeight = height(c)
    oldCenter = canvasToPlane(FloatCoord(currentWidth / 2, currentHeight / 2), offset, zoom)
    if event.direction == 0 # up
        global zoom = min(600.0, zoom * 1.12)
    elseif event.direction == 1 # down
        global zoom = max(1.0, zoom / 1.12)
    end
    newCenter = canvasToPlane(FloatCoord(currentWidth / 2, currentHeight / 2), offset, zoom)
    global offset -= (oldCenter - newCenter)

    resetCanvas()
    drawFractal(fractal, offset, zoom)
end
signal_connect(scroll, win, "scroll-event")

#function resize(widget, event)
#end
#signal_connect(resize, c, "size-allocate")

cond = Condition()
endit(w) = notify(cond)
signal_connect(endit, win, :destroy)
show(c)
wait(cond)