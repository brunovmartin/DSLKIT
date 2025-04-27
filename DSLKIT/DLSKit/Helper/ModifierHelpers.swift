//
//  ModifierHelpers.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//

import SwiftUI

public func mapEdgeSet(from strings: [String]?) -> Edge.Set {
    guard let strings = strings else { return .all }
    var edgeSet: Edge.Set = []
    for str in strings {
        switch str.lowercased() {
        case "top": edgeSet.insert(.top)
        case "bottom": edgeSet.insert(.bottom)
        case "leading": edgeSet.insert(.leading)
        case "trailing": edgeSet.insert(.trailing)
        case "horizontal": edgeSet.insert(.horizontal)
        case "vertical": edgeSet.insert(.vertical)
        case "all": edgeSet.insert(.all)
        default: break
        }
    }
     return edgeSet
}

public func mapAlignment(from string: String?) -> Alignment {
    guard let string = string?.lowercased() else { return .center }
    switch string {
    case "center": return .center
    case "leading": return .leading
    case "trailing": return .trailing
    case "top": return .top
    case "bottom": return .bottom
    case "topLeading": return .topLeading
    case "topTrailing": return .topTrailing
    case "bottomLeading": return .bottomLeading
    case "bottomTrailing": return .bottomTrailing
    default: return .center
    }
}

public func mapNavDisplayMode(_ mode: String?) -> NavigationBarItem.TitleDisplayMode {
    switch mode?.lowercased() {
    case "inline": return .inline
    case "large": return .large
    default: return .automatic
    }
}

public func mapFontWeight(_ weightName: String?) -> Font.Weight? {
    guard let weightName = weightName?.lowercased() else { return nil }
    switch weightName {
    case "ultralight": return .ultraLight
    case "thin": return .thin
    case "light": return .light
    case "regular": return .regular
    case "medium": return .medium
    case "semibold": return .semibold
    case "bold": return .bold
    case "heavy": return .heavy
    case "black": return .black
    default: return nil
    }
}

func parseDimension(_ key: String, frameParams: [String: Any], evaluated: Any) -> CGFloat? {
    guard let value = frameParams[key] else { return CGFloat(1) }
    if let s = evaluated as? String, s.lowercased() == ".infinity" { return .infinity }
    if let number = evaluated as? NSNumber { return CGFloat(number.doubleValue) }
    if let float = evaluated as? CGFloat { return float }
    return nil
}

public func mapTextStyle(from styleName: String?) -> Font.TextStyle? {
    guard let styleName = styleName?.lowercased() else { return nil }
    switch styleName {
    case "largetitle": return .largeTitle
    case "title": return .title // Mapeia para title1
    case "title2": return .title2
    case "title3": return .title3
    case "headline": return .headline
    case "subheadline": return .subheadline
    case "body": return .body
    case "callout": return .callout
    case "footnote": return .footnote
    case "caption": return .caption // Mapeia para caption1
    case "caption2": return .caption2
    default: return nil
    }
}

@available(iOS 16.1, macOS 13.0, tvOS 16.1, watchOS 9.1, *)
public func mapFontDesign(_ designName: String?) -> Font.Design? {
    guard let designName = designName?.lowercased() else { return nil }
    switch designName {
    case "default": return .default
    case "monospaced": return .monospaced
    case "rounded": return .rounded
    case "serif": return .serif
    default: return nil
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public func mapFontWidth(_ widthName: String?) -> Font.Width? {
    guard let widthName = widthName?.lowercased() else { return nil }
    switch widthName {
    case "compressed": return .compressed
    case "condensed": return .condensed
    case "standard": return .standard
    case "expanded": return .expanded
    default: return nil
    }
}

// Add these functions to ModifierHelpers.swift

public func mapContentMode(from string: String?) -> ContentMode {
    switch string?.lowercased() {
    case "fit": return .fit
    case "fill": return .fill
    default: return .fit // Default to fit
    }
}

public func mapRenderingMode(from string: String?) -> Image.TemplateRenderingMode? {
    switch string?.lowercased() {
    case "template": return .template
    case "original": return .original
    default: return nil // Default behavior (often like .original)
    }
}

public func mapInterpolation(from string: String?) -> Image.Interpolation {
    switch string?.lowercased() {
    case "high": return .high
    case "medium": return .medium
    case "low": return .low
    case "none": return .none
    default: return .high // Default to high quality
    }
}
