//
//  BindingResolver.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//


import SwiftUI

struct BindingResolver {
    static func bind<T>(_ varName: String, context: DSLContext, defaultValue: T) -> Binding<T> {
        Binding<T>(
            get: {
                context.storage[varName] as? T ?? defaultValue
            },
            set: {
                context.set(varName, to: $0)
            }
        )
    }
}
