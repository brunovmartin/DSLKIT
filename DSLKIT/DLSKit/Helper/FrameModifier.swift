//
//  FrameModifier.swift
//  DSLKIT
//
//  Created by Pixel Logic Apps on 30/04/25.
//

import SwiftUI

public func registerFrameViewModifiers(on registry: DSLModifierRegistry<AnyView>) {
    registry.register("frame") { view, paramsAny, context in
        let params = paramsAny as? [String: Any] ?? [:]
        func parseDimension(_ key: String) -> CGFloat? {
             guard let value = params[key] else { return nil }
             let evaluatedValue = DSLExpression.shared.evaluate(value, context)
             if let stringValue = evaluatedValue as? String, stringValue.lowercased() == ".infinity" { return .infinity }
             if let number = evaluatedValue as? NSNumber { return CGFloat(number.doubleValue) }
             if let cgFloat = evaluatedValue as? CGFloat { return cgFloat }
             return nil
         }
        
        let mw = parseDimension("minWidth")
        let iw = parseDimension("width")
        let xw = parseDimension("maxWidth")
        let mh = parseDimension("minHeight")
        let ih = parseDimension("height")
        let xh = parseDimension("maxHeight")
        let alignment = mapAlignment(from: DSLExpression.shared.evaluate(params["alignment"], context) as? String)

        // 1) Somente width
        if iw != nil && mw == nil && xw == nil && mh == nil && ih == nil && xh == nil {
            // Com alignment
            return AnyView(view.frame(width: iw!, alignment: alignment))
        }
        // versão sem alignment
        if iw != nil && mw == nil && xw == nil && mh == nil && ih == nil && xh == nil {
            return AnyView(view.frame(width: iw!))
        }

        // 2) Somente height
        if ih != nil && mw == nil && iw == nil && xw == nil && mh == nil && xh == nil {
            // Com alignment
            return AnyView(view.frame(height: ih!, alignment: alignment))
        }
        // versão sem alignment
        if ih != nil && mw == nil && iw == nil && xw == nil && mh == nil && xh == nil {
            return AnyView(view.frame(height: ih!))
        }

        // 3) Width + height
        if iw != nil && ih != nil && mw == nil && xw == nil && mh == nil && xh == nil {
            // Com alignment
            return AnyView(view.frame(width: iw!, height: ih!, alignment: alignment))
        }
        // versão sem alignment
        if iw != nil && ih != nil && mw == nil && xw == nil && mh == nil && xh == nil {
            return AnyView(view.frame(width: iw!, height: ih!))
        }

        // 4) Fallback: outras combinações ou nenhuma
        return AnyView(view.frame(
            minWidth:    mw,
            idealWidth:  iw,
            maxWidth:    xw,
            minHeight:   mh,
            idealHeight: ih,
            maxHeight:   xh,
            alignment:   alignment
        ))
        
    }
}
