//
//  Fonts.swift
//  HelloWorld
//
//  Created by Pixel Logic Apps on 25/04/25.
//

import SwiftUI

extension Font.TextStyle {
    var size: CGFloat {
        #if os(iOS) || os(tvOS)
        switch self {
        case .largeTitle: return UIFont.preferredFont(forTextStyle: .largeTitle).pointSize
        case .title: return UIFont.preferredFont(forTextStyle: .title1).pointSize
        case .headline: return UIFont.preferredFont(forTextStyle: .headline).pointSize
        case .subheadline: return UIFont.preferredFont(forTextStyle: .subheadline).pointSize
        case .body: return UIFont.preferredFont(forTextStyle: .body).pointSize
        case .callout: return UIFont.preferredFont(forTextStyle: .callout).pointSize
        case .caption: return UIFont.preferredFont(forTextStyle: .caption1).pointSize
        case .footnote: return UIFont.preferredFont(forTextStyle: .footnote).pointSize
        case .title2: if #available(iOS 14.0, tvOS 14.0, *) { return UIFont.preferredFont(forTextStyle: .title2).pointSize } else { return UIFont.preferredFont(forTextStyle: .title1).pointSize * 0.9 }
        case .title3: if #available(iOS 14.0, tvOS 14.0, *) { return UIFont.preferredFont(forTextStyle: .title3).pointSize } else { return UIFont.preferredFont(forTextStyle: .title1).pointSize * 0.8 }
        case .caption2: if #available(iOS 14.0, tvOS 14.0, *) { return UIFont.preferredFont(forTextStyle: .caption2).pointSize } else { return UIFont.preferredFont(forTextStyle: .caption1).pointSize * 0.9 }
        @unknown default: return UIFont.preferredFont(forTextStyle: .body).pointSize
        }
        #elseif os(macOS)
        switch self {
        case .largeTitle: return 34
        case .title: return 28
        case .headline: return 17
        case .subheadline: return 15
        case .body: return 17
        case .callout: return 16
        case .caption: return 12
        case .footnote: return 13
        case .title2: if #available(macOS 11.0, *) { return 22 } else { return 28 * 0.9 }
        case .title3: if #available(macOS 11.0, *) { return 20 } else { return 28 * 0.8 }
        case .caption2: if #available(macOS 11.0, *) { return 11 } else { return 12 * 0.9 }
        @unknown default: return 17
        }
        #else
        switch self {
        case .largeTitle: return 30
        case .title: return 24
        case .headline: return 18
        case .subheadline: return 16
        case .body: return 17
        case .callout: return 16
        case .caption: return 14
        case .footnote: return 15
        case .title2: if #available(watchOS 7.0, *) { return 22 } else { return 24 * 0.9 }
        case .title3: if #available(watchOS 7.0, *) { return 20 } else { return 24 * 0.8 }
        case .caption2: if #available(watchOS 7.0, *) { return 13 } else { return 14 * 0.9 }
        @unknown default: return 17
        }
        #endif
    }
}
