//
//  Copyright 2022 • Sidetrack Tech Limited
//

import SwiftUI

internal struct PipifyModifier<PipView: View>: ViewModifier {
    @Binding var isPresented: Bool
    @ObservedObject var controller: PipifyController
    let pipContent: () -> PipView
    let onPlayPause: ((Bool) -> Void)?
    let offscreenRendering: Bool
    
    init(
        isPresented: Binding<Bool>,
        pipContent: @escaping () -> PipView,
        onPlayPause: ((Bool) -> Void)?,
        offscreenRendering: Bool
    ) {
        self._isPresented = isPresented
        self.controller = PipifyController(isPresented: isPresented)
        self.pipContent = pipContent
        self.onPlayPause = onPlayPause
        self.offscreenRendering = offscreenRendering
    }
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if offscreenRendering == false {
                    GeometryReader { proxy in
                        generateLayerView(size: proxy.size)
                    }
                } else {
                    generateLayerView(size: nil)
                }
            }
            .onChange(of: isPresented) { newValue in
                if newValue {
                    controller.start()
                } else {
                    controller.stop()
                }
            }
            .onChange(of: controller.isPlaying) { newValue in
                onPlayPause?(newValue)
            }
            .task {
                controller.isPlayPauseEnabled = onPlayPause != nil
                controller.setView(pipContent())
            }
    }
    
    @ViewBuilder
    func generateLayerView(size: CGSize?) -> some View {
        LayerView(layer: controller.bufferLayer, size: size)
            // layer needs to be in the hierarchy, doesn't actually need to be visible
            .opacity(0)
            .allowsHitTesting(false)
            // if we have a size, then we'll morph from the existing view. otherwise we'll fade from offscreen.
            .offset(size != nil ? .zero : .init(width: .max, height: .max))
    }
}

