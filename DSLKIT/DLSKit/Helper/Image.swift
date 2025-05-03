//
//  Image.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 26/04/25.
//

import SwiftUI


extension Image {
    @ViewBuilder
    func conditionalResizableScaled(_ modifiers: [[String: Any]],
                                    minWidth: CGFloat? = nil,
                                    idealWidth: CGFloat? = nil,
                                    maxWidth: CGFloat? = nil,
                                    minHeight: CGFloat? = nil,
                                    idealHeight: CGFloat? = nil,
                                    maxHeight: CGFloat? = nil,
                                    alignment: Alignment = .center) -> some View {
    
        let shouldApplyResizable = modifiers.contains(where: { $0.keys.contains("resizable") })
        let shouldApplyScaledToFit = modifiers.contains(where: { $0.keys.contains("scaledToFit") })
        let shouldApplyFrame = modifiers.contains(where: { $0["frame"] != nil })

        if(shouldApplyResizable && shouldApplyScaledToFit && shouldApplyFrame){
            self
                .resizable()
                .scaledToFit()
                .frame(width: idealWidth,height: idealHeight)
        } else if(shouldApplyResizable && shouldApplyFrame){
            self
                .resizable()
                .frame(width: idealWidth,height: idealHeight)
        } else if(shouldApplyFrame){
            self
                .frame(width: idealWidth,height: idealHeight)
        } else if(shouldApplyResizable && shouldApplyScaledToFit && !shouldApplyFrame){
            self
                .resizable()
                .scaledToFit()
        } else if(shouldApplyResizable && !shouldApplyScaledToFit && !shouldApplyFrame){
            self
                .resizable()
        }else{
            self
        }
    }
    
}
