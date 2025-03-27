/*
 MIT License

 Copyright (c) 2025 Xavier Normant

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

//
//  SizeReader.swift
//  ReorderingVStack
//
//  Created by Xavier on 27/03/2025.
//

#if os(iOS)
import SwiftUI

struct SizeReader: ViewModifier {
    @Binding var size: CGSize

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geo in
                    Rectangle()
                        .fill(.clear)
                        .onAppear {
                            size = geo.size
                        }
                        .onChange(of: geo.size) {
                            size = geo.size
                        }
                }
            }
    }
}

extension View {
    func sizeReader(_ size: Binding<CGSize>) -> some View {
        modifier(SizeReader(size: size))
    }
}
#endif
