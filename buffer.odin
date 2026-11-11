package tui

import "core:fmt"
import px "core:sys/posix"
import lx "core:sys/linux"

import "core:os"
import "core:io"

import "core:math"
import "core:slice"

import "core:log"











// TODO: Rect -> Pos, rect is kinda bad for buffers in retrospect

// NOTE: data is sequential rows
Buffer :: struct($Item : typeid) {
    rect : Rect,
    data : []Item,
}

buffer_create :: proc (r : Rect, $ty : typeid, allocator := context.allocator) -> (buffer : Buffer(ty), ok : bool = false) {
    size := cast(u64)r.z * cast(u64)r.w
    buffer = Buffer(ty){ rect = r, data = make([]ty, size, allocator) }
    ok = true
    return
}

buffer_free :: proc (buffer : Buffer($ty)) {
    delete(buffer.data)
}

buffer_get :: proc (buffer : Buffer($ty), pos : Pos, relative : bool = true) -> (cell : ty, ok : bool = false) {
    rpos := (!relative) ? (pos - buffer.rect.xy) : pos
    if rpos.x < 0 || rpos.y < 0 { return }
    if rpos.x >= buffer.rect.z || rpos.y >= buffer.rect.w { return }

    index := rpos.y * buffer.rect.z + rpos.x
    if index < 0 || cast(int)index >= len(buffer.data) { return }
    return buffer.data[index], true
}

buffer_set :: proc (buffer : Buffer($ty), pos : Pos, value : ty, relative : bool = true) -> (ok : bool = false) {
    rpos := (!relative) ? (pos - buffer.rect.xy) : pos
    if rpos.x < 0 || rpos.y < 0 { return }
    if rpos.x >= buffer.rect.z || rpos.y >= buffer.rect.w { return }
    index := rpos.y * buffer.rect.z + rpos.x
    if index < 0 || cast(int)index >= len(buffer.data) { return }
    buffer.data[index] = value
    ok = true
    return
}

buffer_reset :: proc (buffer : Buffer($ty), value : ty) {
    for i in 0..<(buffer.rect.z * buffer.rect.w) {
        buffer.data[i] = value
    }
}

buffer_copyToBuffer :: proc (dst : Buffer($ty), src : Buffer(ty), offset : Pos = { 0, 0 }) {
    for x in 0..<src.rect.z {
        for y in 0..<src.rect.w {
            buffer_set(dst, { x, y } + src.rect.xy + offset, buffer_get(src, { x, y }) or_continue)
        }
    }
}

drawBoxCell :: proc (buffer : Buffer(BoxCellData), pos : Pos, box : BoxCellData) {
    v, _ := buffer_get(buffer, pos)
    buffer_set(buffer, pos, BoxCellData{ v.masks | box.masks, box.style, box.layer })
}

drawBox :: proc (buffer : Buffer(BoxCellData), rect : Rect, box : BoxType, style : FontStyle, layer : int) {
    br := br_from_rect(rect)

    for x in (rect.x + 1)..<(br.x - 1) {
        drawBoxCell(buffer, Pos{ x,   rect.y }, BoxCellData{ { {}, { box }, {}, { box } }, style, layer })
        drawBoxCell(buffer, Pos{ x, br.y - 1 }, BoxCellData{ { {}, { box }, {}, { box } }, style, layer })
    }

    for y in (rect.y + 1)..<(br.y - 1) {
        drawBoxCell(buffer, Pos{ rect.x,   y }, BoxCellData{ { { box }, {}, { box }, {} }, style, layer })
        drawBoxCell(buffer, Pos{ br.x - 1, y }, BoxCellData{ { { box }, {}, { box }, {} }, style, layer })
    }

    // tl tr br bl
    drawBoxCell(buffer, Pos{ rect.x,   rect.y   }, BoxCellData{ { {},      { box }, { box }, {}      }, style, layer })
    drawBoxCell(buffer, Pos{ br.x - 1, rect.y   }, BoxCellData{ { {},      {},      { box }, { box } }, style, layer })
    drawBoxCell(buffer, Pos{ br.x - 1, br.y - 1 }, BoxCellData{ { { box }, {},      {},      { box } }, style, layer })
    drawBoxCell(buffer, Pos{ rect.x,   br.y - 1 }, BoxCellData{ { { box }, { box }, {},      {}      }, style, layer })
}

drawLine :: proc (buffer : Buffer(BoxCellData), rect : Rect, box : BoxType, style : FontStyle, layer : int) {
    if rect.z != 1 && rect.w != 1 { return }
    
    mask : [4]BoxTypeMask = rect.z == 1 ? { { box }, {}, { box }, {} } : { {}, { box }, {}, { box } }

    br := br_from_rect(rect)
    for y in (rect.y)..<(br.y) {
        for x in (rect.x)..<(br.x) {
            drawBoxCell(buffer, { x, y }, BoxCellData{ mask, style, layer })
        }
    }

    // NOTE: ehhhh idk this is kinda jank but it works for reasonable cases
    if rect.z == 1 {
        drawBoxCell(buffer, { rect.x, rect.y - 1 }, BoxCellData{ { {}, {}, { box }, {} }, style, layer })
        drawBoxCell(buffer, { rect.x, br.y },       BoxCellData{ { { box }, {}, {}, {} }, style, layer })
    }
    else {
        drawBoxCell(buffer, { rect.x - 1, rect.y }, BoxCellData{ { {}, { box }, {}, {} }, style, layer })
        drawBoxCell(buffer, { br.x,       rect.y }, BoxCellData{ { {}, {}, {}, { box } }, style, layer })
    }
}

cc_resolveBoxBuffer :: proc (cb : ^CommandBuffer, buffer : Buffer(BoxCellData)) {
    for y in 0..<buffer.rect.w {
        consecutive := false

        for x in 0..<buffer.rect.z {
            box := buffer_get(buffer, { x, y }) or_continue
            if box.masks == {} {
                consecutive = false
                continue
            }


            candidate : BoxCharacter
            for c in BoxCharacters {
                if (box.masks[0] & c.masks[0] == {} && box.masks[0] | c.masks[0] != {}) ||
                   (box.masks[1] & c.masks[1] == {} && box.masks[1] | c.masks[1] != {}) ||
                   (box.masks[2] & c.masks[2] == {} && box.masks[2] | c.masks[2] != {}) ||
                   (box.masks[3] & c.masks[3] == {} && box.masks[3] | c.masks[3] != {}) { continue }

                candidate = c
                break
            }


            if !consecutive {
                consecutive = true
                c_goto(cb, { x, y } + buffer.rect.xy)
            }
            c_style(cb, box.style)
            c_appendRune(cb, candidate.character)
        }
    }
}





applyStretching :: proc (total : u64, stretchings : []Stretching, values : []u64) {
    sum : u64 = 0
    for v in values { sum += v }

    delta : i64 = (i64(total) - i64(sum))
    deltaOriginal := delta

    one : f64 = 0
    for s in stretchings { one += cast(f64)calculatePriority(s) }

    for &v, i in values {
        p := cast(f64)calculatePriority(stretchings[i])
        inc := cast(i64)math.round(f64(deltaOriginal) * (p / one))

        if i64(v) + inc < 0 {
            inc -= (i64(v) + inc)
            log.debugf("COMPOEN")
        }

        delta -= inc
        v = u64(i64(v) + inc)
    }

    if delta == 0 { return }

    // for &v, i in values {
    //     s := stretchings[i]
    //     if s.fill == .Expand {
    //         p := cast(f64)calculatePriority(s)
    //         inc := i64(f64(delta) * (p / one))
    //
    //         if i64(v) + inc < 0 {
    //             inc -= (i64(v) + inc)
    //         }
    //
    //         delta -= inc
    //         v = u64(i64(v) + inc)
    //     }
    // }
    //
    // if delta == 0 { return }
}


TerminalState :: struct {
    termios : px.termios,
}

interactiveEnable :: proc () -> (state : TerminalState, ok : bool = false) {
    if px.tcgetattr(px.STDIN_FILENO, &state.termios) != .OK { return }

    term := state.termios
    term.c_lflag -= { .ECHO, .ICANON }

    if px.tcsetattr(px.STDIN_FILENO, .TCSANOW, &term) != .OK { return }

    // Disable cursor
    os.write_string(os.stdout, "\e[?25l")
    // Enable alternative buffer
    os.write_string(os.stdout, "\e[?1049h")

    return
}

interactiveDisable :: proc (state : TerminalState) {
    state := state
    px.tcsetattr(px.STDIN_FILENO, .TCSANOW, &state.termios)

    // Disable alternative buffer
    os.write_string(os.stdout, "\e[?1049l")
    // Enable cursor
    os.write_string(os.stdout, "\e[?25h")
}



RenderingContext :: struct {
    screenRect : Rect,
    commandBuffer : ^CommandBuffer,

    bufferBoxes : Buffer(BoxCellData),
    // TODO: remove, this isnt needed with new box rendering
    sharedBoxLayer : int,
    uniqueBoxLayer : int,
}
