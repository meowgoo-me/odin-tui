package main

import tui "../"

import "core:os"
import "core:log"
import str "core:strings"
import "core:time"
import "core:io"

import "core:prof/spall"
import "base:runtime"
import "core:sync"


when ODIN_DEBUG {
    spall_ctx: spall.Context
    @(thread_local) spall_buffer: spall.Buffer

    // Automatic profiling of every procedure:

    @(instrumentation_enter)
    spall_enter :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
    	spall._buffer_begin(&spall_ctx, &spall_buffer, "", "", loc)
    }

    @(instrumentation_exit)
    spall_exit :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
    	spall._buffer_end(&spall_ctx, &spall_buffer)
    }
}


run :: proc () -> bool {
    // when ODIN_DEBUG {
        logFile, _ := os.open("./log.txt", { .Write, .Create, .Trunc })
        context.logger = log.create_file_logger(logFile, .Debug, { .Level, .Short_File_Path, .Line })
    // }



    p20scroll := tui.scroll({ false, true }, { false, true }, true,
        tui.linear(.Vertical, {}, { { priority = 1, fill = .MinimalPossible }, {}, {} }, {
            tui.label("[1:1] In the beginning when God created the heavens and the earth,"),
            tui.label("[1:2] the earth was a formless void and darkness covered the face of the deep, while a wind from God swept over the face of the waters."),
            tui.label("[1:3] Then God said, \"Let there be light\"; and there was light."),
            tui.label("[1:4] And God saw that the light was good; and God separated the light from the darkness."),
            tui.label("[1:5] God called the light Day, and the darkness he called Night. And there was evening and there was morning, the first day."),
            tui.label("[1:6] And God said, \"Let there be a dome in the midst of the waters, and let it separate the waters from the waters.\""),
            tui.label("[1:7] So God made the dome and separated the waters that were under the dome from the waters that were above the dome. And it was so."),
            tui.label("[1:8] God called the dome Sky. And there was evening and there was morning, the second day."),
            tui.label("[1:9] And God said, \"Let the waters under the sky be gathered together into one place, and let the dry land appear.\" And it was so."),
            tui.label("[1:10] God called the dry land Earth, and the waters that were gathered together he called Seas. And God saw that it was good."),
            tui.label("[1:11] Then God said, \"Let the earth put forth vegetation: plants yielding seed, and fruit trees of every kind on earth that bear fruit with the seed in it.\" And it was so."),
            tui.label("[1:12] The earth brought forth vegetation: plants yielding seed of every kind, and trees of every kind bearing fruit with the seed in it. And God saw that it was good."),
            tui.label("[1:13] And there was evening and there was morning, the third day."),
            tui.label("[1:14] And God said, \"Let there be lights in the dome of the sky to separate the day from the night; and let them be for signs and for seasons and for days and years,"),
            tui.label("[1:15] and let them be lights in the dome of the sky to give light upon the earth.\" And it was so."),
            tui.label("[1:16] God made the two great lights - the greater light to rule the day and the lesser light to rule the night - and the stars."),
            tui.label("[1:17] God set them in the dome of the sky to give light upon the earth,"),
            tui.label("[1:18] to rule over the day and over the night, and to separate the light from the darkness. And God saw that it was good."),
            tui.label("[1:19] And there was evening and there was morning, the fourth day."),
            tui.label("[1:20] And God said, \"Let the waters bring forth swarms of living creatures, and let birds fly above the earth across the dome of the sky.\""),
            tui.label("[1:21] So God created the great sea monsters and every living creature that moves, of every kind, with which the waters swarm, and every winged bird of every kind. And God saw that it was good."),
            tui.label("[1:22] God blessed them, saying, \"Be fruitful and multiply and fill the waters in the seas, and let birds multiply on the earth.\""),
            tui.label("[1:23] And there was evening and there was morning, the fifth day."),
            tui.label("[1:24] And God said, \"Let the earth bring forth living creatures of every kind: cattle and creeping things and wild animals of the earth of every kind.\" And it was so."),
            tui.label("[1:25] God made the wild animals of the earth of every kind, and the cattle of every kind, and everything that creeps upon the ground of every kind. And God saw that it was good."),
            tui.label("[1:26] Then God said, \"Let us make humankind in our image, according to our likeness; and let them have dominion over the fish of the sea, and over the birds of the air, and over the cattle, and over all the wild animals of the earth, and over every creeping thing that creeps upon the earth.\""),
            tui.label("[1:27] So God created humankind in his image, in the image of God he created them; male and female he created them."),
            tui.label("[1:28] God blessed them, and God said to them, \"Be fruitful and multiply, and fill the earth and subdue it; and have dominion over the fish of the sea and over the birds of the air and over every living thing that moves upon the earth.\""),
            tui.label("[1:29] God said, \"See, I have given you every plant yielding seed that is upon the face of all the earth, and every tree with seed in its fruit; you shall have them for food."),
            tui.label("[1:30] And to every beast of the earth, and to every bird of the air, and to everything that creeps on the earth, everything that has the breath of life, I have given every green plant for food.\" And it was so."),
            tui.label("[1:31] God saw everything that he had made, and indeed, it was very good. And there was evening and there was morning, the sixth day. "),
        })
    )


    
    // NOTE: this is still a useful example

    // c : []u64 = { 2, 3, 5 }
    // r : [3]u64
    // divideBetween(cast(u64)width, c, r[:], 1)
    //
    // rectA, lineAB, rectBC := rect_splitVerticalLineGap(content, cast(i16)r[0], 1)
    // rectB, lineBC, rectC := rect_splitVerticalLineGap(rectBC, cast(i16)r[1], 1)
    //
    // drawBlock(ctx.bufferBoxes, lineAB, .SingleCurve)
    // drawBlock(ctx.bufferBoxes, lineBC, .SingleCurve)
    //
    // element_render(self.children[0], ctx, rectA)
    // element_render(self.children[1], ctx, rectB)
    // element_render(self.children[2], ctx, rectC)


    root :=
        tui.box(.SingleCurve, {}, {},
            tui.linear(.Horizontal, .Double, { { priority = 1, fill = .MinimalPossible }, {
                // TODO: the result is kinda what we expected, but there's not really a way
                // to split a container proportionally, unless all elements take the same
                // amount of space prior to getting stretched
                tui.Stretching{ .Expand, 1 },
                tui.Stretching{ .Expand, 3 },
                tui.Stretching{ .Expand, 5 },
            }, {} }, {

                tui.linear(.Vertical, .Single, { { priority = 1, fill = .MinimalPossible }, {
                    tui.Stretching{ .MinimalPossible, 1 },
                    tui.Stretching{ .Expand, 5 }
                }, {} }, {
                    tui.label("ELF Header"),
                    tui.table({ 2, 2 }, { .Single, {} }, { { { .Expand, 1 }, { tui.Stretching{ .MinimalNecessary, 1 }, tui.Stretching{ .Expand, 1 } }, {} }, { { .MinimalPossible, 1 }, {}, {} } }, {
                        tui.label("Magic:"), tui.label("7f 45 4c 46"),
                        tui.label("Type:"),  tui.label("Shared Object"), 
                    })
                }),
                tui.label("Test"),
                p20scroll,
            })
        )

    tui.element_retrieve(tui.Element, root, { 0, 0, 1, 1 }).interact = proc(self : ^tui.Element) {
        log.debugf("magic")

        env := tui.element_getEnvironment(self)
        mbox := tui.env_getComponent(env, tui.Component.MessageBox, tui.Element)
        tui.env_addLayer(env, mbox, { .Expand1, .Expand1 }, true, returnFocusTo = tui.element_getLayer(self).id)
    }

    // TODO: are there even cases where we do NOT watch stretching (when rendering)?
    tui.element_retrieve(tui.Element_Linear, root, { 0 }).stretch.x = true
    tui.element_retrieve(tui.Element_Linear, root, { 0, 0 }).stretch.y = true
    tui.element_retrieve(tui.Element_Table,  root, { 0, 0, 1 }).stretch.x = true

    testptr : ^tui.Element

    textPopup := 
        tui.box(.Double, {}, {},
            tui.linear(.Vertical, .None, { { priority = 1, fill = .MinimalNecessary }, {}, {} }, {
                tui.label("Information idk"),
                tui.linear(.Horizontal, .None, { { priority = 1, fill = .MinimalNecessary }, {}, {} }, {
                    tui.box(.Single, {}, {}, 
                        tui.label("YES")
                    ),
                    tui.box(.Single, {}, {}, 
                        tui.label("NO")
                    ),
                })
            })
        )

    tui.element_retrieve(tui.Element, textPopup, { 0, 1 }).stretch.x = true
    tui.element_retrieve(tui.Element, textPopup, { 0, 1, 0, 0 }).interact = proc(self : ^tui.Element) {
        log.debugf("YES")

        env := tui.element_getEnvironment(self)
        tui.env_removeLayer(env, tui.element_getLayer(self).id)
    }

    tui.element_retrieve(tui.Element, textPopup, { 0, 1, 1, 0 }).interact = proc(self : ^tui.Element) {
        log.debugf("NO")

        env := tui.element_getEnvironment(self)
        tui.env_removeLayer(env, tui.element_getLayer(self).id)
    }


    env : tui.Environment

    tui.env_addComponent(&env, tui.Component.MessageBox, textPopup)

    tui.env_addLayer(&env, root, { .Fill, .Fill }, true)
    // env_addLayer(&env, textPopup, { .Expand1, .Expand1 }, true)











    box : tui.Buffer(tui.BoxCellData)
    cb : tui.CommandBuffer = tui.CommandBuffer_Stdout{
        builder = str.builder_make_none(),
        style = tui.FontStyle_default,
    }



    sw : time.Stopwatch




    tstate, _ := tui.interactiveEnable()
    defer tui.interactiveDisable(tstate)
    inputStream := os.to_stream(os.stdin)

    for !env.quit {
        time.stopwatch_reset(&sw)
        time.stopwatch_start(&sw)





        screenRect := tui.getScreenRect() or_return

        if box.data == nil || box.rect != screenRect {
            tui.buffer_free(box)
            box = tui.buffer_create(screenRect, tui.BoxCellData) or_return
        }

        tui.buffer_reset(box, tui.BoxCellData{ {}, tui.FontStyle_default, -1 })
        tui.c_reset(&cb)





        tui.c_styleClear(&cb)
        tui.c_clear(&cb)

        // TODO: im not sure, but it might be more useful to delegate context creation to environment
        ctx := tui.RenderingContext{
            screenRect = screenRect,
            commandBuffer = &cb,

            bufferBoxes = box,
            sharedBoxLayer = 0,
            uniqueBoxLayer = 100000,
        }


        tui.env_render(&env, &ctx, ctx.screenRect)




        os.write_string(os.stdout, str.to_string(cb.(tui.CommandBuffer_Stdout).builder))





        time.stopwatch_stop(&sw)
        log.debugf("DRAW TIME: %v", time.stopwatch_duration(sw))




        // TODO: are there any cases where non-unicode input is needed? raw bytes?
        c, _, err := io.read_rune(inputStream)

        tui.env_input(&env, c)
    }


    return true
}

main :: proc () {
    when ODIN_DEBUG {
        spall_ctx = spall.context_create("trace_test.spall")
        defer spall.context_destroy(&spall_ctx)

        buffer_backing := make([]u8, spall.BUFFER_DEFAULT_SIZE)
        defer delete(buffer_backing)

        spall_buffer = spall.buffer_create(buffer_backing, u32(sync.current_thread_id()))
        defer spall.buffer_destroy(&spall_ctx, &spall_buffer)

        spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, #procedure)
    }





    run()
}
