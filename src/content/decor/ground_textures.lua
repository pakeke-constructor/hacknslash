


g.defineEntity("ground_tex", {
    drawOrder = -100,

    color = g.snapToPalette(objects.Color.BROWN),

    onDraw = function (ent, x, y)
        lg.setColor(ent.color)
        lg.circle("fill",x,y, 10)
    end
})

