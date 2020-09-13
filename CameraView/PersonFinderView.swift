//
//  PersonFinderView.swift
//  CameraView
//
//  Created by Broderick Higby on 9/12/20.
//  Copyright © 2020 DataHinge. All rights reserved.
//

import SwiftUI
import AVKit

struct PersonFinderView: View {
    @ObservedObject var viewModel = LiveCameraViewModel()
    var body: some View {
        LivePreview(model: viewModel)
            .edgesIgnoringSafeArea(.all)
            .onReceive(viewModel.$personInView, perform: { detected in
                if detected {
                    self.viewModel.personInView = true
                }
            })
    }// can call viewModel.personInView to check if the person is in view
}

struct PersonFinderView_Previews: PreviewProvider {
    @State private var detection = true
    static var previews: some View {
        PersonFinderView()
    }
}
