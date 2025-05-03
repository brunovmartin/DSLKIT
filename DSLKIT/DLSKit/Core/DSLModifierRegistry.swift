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
        logDebug("--- DEBUG: Modifier Apply - STARTING application for list: \(list)")
        return list.reduce(view) { current, mod in
            logDebug("--- DEBUG: Modifier Apply - Processing mod dict: \(mod)")
            guard let key = mod.keys.first,
                  let value = mod[key],
                  let fn = modifiers[key] else {
                // Log se o modificador for pulado
                logDebug("--- DEBUG: Modifier Apply - SKIPPING modifier (key not found or fn not registered): \(mod)")
                return current
            }
            // Log se o modificador for aplicado
            logDebug("--- DEBUG: Modifier Apply - APPLYING modifier: \(key)")
            return fn(current, value, context)
        }
    }
}
