registry.register("frame") { view, paramsAny, context in
    // ... parameter parsing code above ...
    let mw = parseDimension("minWidth")
    let iw = parseDimension("width")
    let xw = parseDimension("maxWidth")
    let mh = parseDimension("minHeight")
    let ih = parseDimension("height")
    let xh = parseDimension("maxHeight")
    let alignment = mapAlignment(from: DSLExpression.shared.evaluate(params["alignment"], context) as? String)

    if true {
        return AnyView(view.frame(alignment: alignment))
    }
    if mw != nil {
        return AnyView(view.frame(minWidth: mw, alignment: alignment))
    }
    if iw != nil {
        return AnyView(view.frame(idealWidth: iw, alignment: alignment))
    }
    if mw != nil && iw != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, alignment: alignment))
    }
    if xw != nil {
        return AnyView(view.frame(maxWidth: xw, alignment: alignment))
    }
    if mw != nil && xw != nil {
        return AnyView(view.frame(minWidth: mw, maxWidth: xw, alignment: alignment))
    }
    if iw != nil && xw != nil {
        return AnyView(view.frame(idealWidth: iw, maxWidth: xw, alignment: alignment))
    }
    if mw != nil && iw != nil && xw != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, maxWidth: xw, alignment: alignment))
    }
    if mh != nil {
        return AnyView(view.frame(minHeight: mh, alignment: alignment))
    }
    if mw != nil && mh != nil {
        return AnyView(view.frame(minWidth: mw, minHeight: mh, alignment: alignment))
    }
    if iw != nil && mh != nil {
        return AnyView(view.frame(idealWidth: iw, minHeight: mh, alignment: alignment))
    }
    if mw != nil && iw != nil && mh != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, minHeight: mh, alignment: alignment))
    }
    if xw != nil && mh != nil {
        return AnyView(view.frame(maxWidth: xw, minHeight: mh, alignment: alignment))
    }
    if mw != nil && xw != nil && mh != nil {
        return AnyView(view.frame(minWidth: mw, maxWidth: xw, minHeight: mh, alignment: alignment))
    }
    if iw != nil && xw != nil && mh != nil {
        return AnyView(view.frame(idealWidth: iw, maxWidth: xw, minHeight: mh, alignment: alignment))
    }
    if mw != nil && iw != nil && xw != nil && mh != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, maxWidth: xw, minHeight: mh, alignment: alignment))
    }
    if ih != nil {
        return AnyView(view.frame(idealHeight: ih, alignment: alignment))
    }
    if mw != nil && ih != nil {
        return AnyView(view.frame(minWidth: mw, idealHeight: ih, alignment: alignment))
    }
    if iw != nil && ih != nil {
        return AnyView(view.frame(idealWidth: iw, idealHeight: ih, alignment: alignment))
    }
    if mw != nil && iw != nil && ih != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, idealHeight: ih, alignment: alignment))
    }
    if xw != nil && ih != nil {
        return AnyView(view.frame(maxWidth: xw, idealHeight: ih, alignment: alignment))
    }
    if mw != nil && xw != nil && ih != nil {
        return AnyView(view.frame(minWidth: mw, maxWidth: xw, idealHeight: ih, alignment: alignment))
    }
    if iw != nil && xw != nil && ih != nil {
        return AnyView(view.frame(idealWidth: iw, maxWidth: xw, idealHeight: ih, alignment: alignment))
    }
    if mw != nil && iw != nil && xw != nil && ih != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, maxWidth: xw, idealHeight: ih, alignment: alignment))
    }
    if mh != nil && ih != nil {
        return AnyView(view.frame(minHeight: mh, idealHeight: ih, alignment: alignment))
    }
    if mw != nil && mh != nil && ih != nil {
        return AnyView(view.frame(minWidth: mw, minHeight: mh, idealHeight: ih, alignment: alignment))
    }
    if iw != nil && mh != nil && ih != nil {
        return AnyView(view.frame(idealWidth: iw, minHeight: mh, idealHeight: ih, alignment: alignment))
    }
    if mw != nil && iw != nil && mh != nil && ih != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, minHeight: mh, idealHeight: ih, alignment: alignment))
    }
    if xw != nil && mh != nil && ih != nil {
        return AnyView(view.frame(maxWidth: xw, minHeight: mh, idealHeight: ih, alignment: alignment))
    }
    if mw != nil && xw != nil && mh != nil && ih != nil {
        return AnyView(view.frame(minWidth: mw, maxWidth: xw, minHeight: mh, idealHeight: ih, alignment: alignment))
    }
    if iw != nil && xw != nil && mh != nil && ih != nil {
        return AnyView(view.frame(idealWidth: iw, maxWidth: xw, minHeight: mh, idealHeight: ih, alignment: alignment))
    }
    if mw != nil && iw != nil && xw != nil && mh != nil && ih != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, maxWidth: xw, minHeight: mh, idealHeight: ih, alignment: alignment))
    }
    if xh != nil {
        return AnyView(view.frame(maxHeight: xh, alignment: alignment))
    }
    if mw != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, maxHeight: xh, alignment: alignment))
    }
    if iw != nil && xh != nil {
        return AnyView(view.frame(idealWidth: iw, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && iw != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, maxHeight: xh, alignment: alignment))
    }
    if xw != nil && xh != nil {
        return AnyView(view.frame(maxWidth: xw, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && xw != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, maxWidth: xw, maxHeight: xh, alignment: alignment))
    }
    if iw != nil && xw != nil && xh != nil {
        return AnyView(view.frame(idealWidth: iw, maxWidth: xw, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && iw != nil && xw != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, maxWidth: xw, maxHeight: xh, alignment: alignment))
    }
    if mh != nil && xh != nil {
        return AnyView(view.frame(minHeight: mh, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && mh != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, minHeight: mh, maxHeight: xh, alignment: alignment))
    }
    if iw != nil && mh != nil && xh != nil {
        return AnyView(view.frame(idealWidth: iw, minHeight: mh, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && iw != nil && mh != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, minHeight: mh, maxHeight: xh, alignment: alignment))
    }
    if xw != nil && mh != nil && xh != nil {
        return AnyView(view.frame(maxWidth: xw, minHeight: mh, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && xw != nil && mh != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, maxWidth: xw, minHeight: mh, maxHeight: xh, alignment: alignment))
    }
    if iw != nil && xw != nil && mh != nil && xh != nil {
        return AnyView(view.frame(idealWidth: iw, maxWidth: xw, minHeight: mh, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && iw != nil && xw != nil && mh != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, maxWidth: xw, minHeight: mh, maxHeight: xh, alignment: alignment))
    }
    if ih != nil && xh != nil {
        return AnyView(view.frame(idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && ih != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if iw != nil && ih != nil && xh != nil {
        return AnyView(view.frame(idealWidth: iw, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && iw != nil && ih != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if xw != nil && ih != nil && xh != nil {
        return AnyView(view.frame(maxWidth: xw, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && xw != nil && ih != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, maxWidth: xw, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if iw != nil && xw != nil && ih != nil && xh != nil {
        return AnyView(view.frame(idealWidth: iw, maxWidth: xw, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && iw != nil && xw != nil && ih != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, maxWidth: xw, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if mh != nil && ih != nil && xh != nil {
        return AnyView(view.frame(minHeight: mh, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && mh != nil && ih != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, minHeight: mh, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if iw != nil && mh != nil && ih != nil && xh != nil {
        return AnyView(view.frame(idealWidth: iw, minHeight: mh, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && iw != nil && mh != nil && ih != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, minHeight: mh, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if xw != nil && mh != nil && ih != nil && xh != nil {
        return AnyView(view.frame(maxWidth: xw, minHeight: mh, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && xw != nil && mh != nil && ih != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, maxWidth: xw, minHeight: mh, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if iw != nil && xw != nil && mh != nil && ih != nil && xh != nil {
        return AnyView(view.frame(idealWidth: iw, maxWidth: xw, minHeight: mh, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    if mw != nil && iw != nil && xw != nil && mh != nil && ih != nil && xh != nil {
        return AnyView(view.frame(minWidth: mw, idealWidth: iw, maxWidth: xw, minHeight: mh, idealHeight: ih, maxHeight: xh, alignment: alignment))
    }
    // Fallback if somehow none matched
    return AnyView(view.frame(alignment: alignment))
}