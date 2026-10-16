import vapoursynth as vs

core = vs.core

src_path = "__INPUT__"
blur_amount = __BLUR__

src = core.bs.VideoSource(src_path)

sup = core.mv.Super(
    src,
    pel=2,
    sharp=1
)

bv = core.mv.Analyse(
    sup,
    isb=True,
    delta=1,
    blksize=8,
    overlap=4,
    search=3,
    truemotion=True
)

fv = core.mv.Analyse(
    sup,
    isb=False,
    delta=1,
    blksize=8,
    overlap=4,
    search=3,
    truemotion=True
)

out = core.mv.FlowBlur(
    src,
    sup,
    bv,
    fv,
    blur=blur_amount,
    prec=2
)

out.set_output()
