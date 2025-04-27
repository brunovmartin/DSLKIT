//
//  BindingResolver.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//


import SwiftUI

struct BindingResolver {
    static func bind<T>(_ varName: String, context: DSLContext, defaultValue: T, onChangeAction: Any? = nil) -> Binding<T> {
        Binding<T>(
            get: {
                context.storage[varName] as? T ?? defaultValue
            },
            set: {
                print("--- DEBUG: BindingResolver SET for \(varName) called with value: \($0)")
                context.set(varName, to: $0)
                
                if let action = onChangeAction {
                    print("--- DEBUG: BindingResolver executing onChange action for \(varName)")
                    DSLInterpreter.shared.handleEvent(action, context: context)
                }
            }
        )
    }
}
