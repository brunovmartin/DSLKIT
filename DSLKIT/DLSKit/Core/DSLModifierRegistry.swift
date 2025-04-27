//
//  DSLModifierRegistry.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//

import SwiftUI

public class DSLModifierRegistry<ViewType> {
    public typealias Modifier = (ViewType, Any, DSLContext) -> ViewType

    private var modifiers: [String: Modifier] = [:]

    public func register(_ name: String, _ fn: @escaping Modifier) {
        modifiers[name] = fn
    }

    public func apply(_ list: [[String: Any]], to view: ViewType, context: DSLContext) -> ViewType {
        list.reduce(view) { current, mod in
            guard let key = mod.keys.first,
                  let value = mod[key],
                  let fn = modifiers[key] else {
                return current
            }
            return fn(current, value, context)
        }
    }
}
