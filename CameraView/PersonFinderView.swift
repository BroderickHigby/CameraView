//
//  FindPersonView.swift
//  CameraView
//
//  Created by Broderick Higby on 9/12/20.
//  Copyright © 2020 DataHinge. All rights reserved.
//

import SwiftUI

struct PersonFinderView: View {
    var body: some View {
        LivePreview()
    }
}

struct PersonFinderView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack{
            Text("View")
            PersonFinderView()
        }
    }
}
