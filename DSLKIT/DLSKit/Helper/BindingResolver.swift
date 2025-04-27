//
//  BindingResolver.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//


import SwiftUI
struct BindingResolver {
    static func bind(_ varName: String, context: DSLContext) -> Binding<String> {
        Binding<String>(
            get: {
                context.storage[varName] as? String ?? ""
            },
            set: {
                context.set(varName, to: $0)
            }
        )
    }
}
