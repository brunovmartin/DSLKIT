//
//  BindableContext.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//


import Foundation
import Combine

public class BindableContext: ObservableObject {
    @Published public var global: [String: Any]
    @Published public var local: [String: Any]

    public init(global: [String: Any], local: [String: Any] = [:]) {
        self.global = global
        self.local = local
    }

    public func resolve(_ pathSpec: Any) -> Any? {
        if let ref = pathSpec as? [String: String],
           let scope = ref["scope"], let path = ref["path"] {
            return (scope == "local" ? local : global)[path]
        }
        return nil
    }

    public func assign(_ pathSpec: Any, value: Any?) {
        guard let ref = pathSpec as? [String: String],
              let scope = ref["scope"], let path = ref["path"] else { return }

        if scope == "global" {
            global[path] = value
        } else {
            local[path] = value
        }
    }
}
