//
//  DividerView.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 26/04/25.
//


// swift-helloworld-main/HelloWorld/DLSKit/UI/Components/DividerView.swift
import SwiftUI

public struct DividerView {
    static let modifierRegistry = DSLModifierRegistry<AnyView>()

    public static func render(_ node: [String: Any], context: DSLContext) -> AnyView {
        // A SwiftUI Divider is quite simple
        let divider = Divider()

        // Wrap in AnyView before applying modifiers
        var finalView = AnyView(divider)

        // Apply common modifiers (like padding, background color for thickness, etc.)
        if let modifiers = node["modifiers"] as? [[String: Any]] {
            finalView = modifierRegistry.apply(modifiers, to: finalView, context: context)
        }

        return finalView
    }

    public static func register() {
        DSLComponentRegistry.shared.register("divider", builder: render)

        // Registra modificadores de base comuns (padding, frame, background)
        // Usados frequentemente para estilizar o Divider (ex: frame(height: 1).background(Color.gray))
        registerBaseViewModifiers(on: modifierRegistry)

        // Divider não tem muitos modificadores específicos em SwiftUI.
    }
}