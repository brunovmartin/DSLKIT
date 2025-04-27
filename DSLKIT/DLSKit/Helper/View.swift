//
//  View.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let unwrapped = value {
            transform(self, unwrapped)
        } else {
            self
        }
    }
    
    func asMirrorChild<T>(type: T.Type) -> T? {
        let mirror = Mirror(reflecting: self)
        guard let storage = mirror.descendant("storage", "content") else { return nil }
        let storageMirror = Mirror(reflecting: storage)
        if let typedContent = storage as? T { return typedContent }
        if let content = storageMirror.descendant("content"), let typedContent = content as? T { return typedContent }
        if let anyViewContent = mirror.descendant("storage", "view"), let typedContent = anyViewContent as? T { return typedContent }
         if let typedView = self as? T { return typedView }
        return nil
    }
    
}
