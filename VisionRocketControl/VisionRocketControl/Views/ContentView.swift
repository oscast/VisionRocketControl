//
//  ContentView.swift
//  VisionRocketController
//
//  Created by Oscar Castillo on 9/10/24.
//

import SwiftUI
import RealityKit
import TipKit

struct ContentView: View {
    @State private var arViewModel = ARViewModel()
    @State private var gestureDetected: Bool = false
    
    var body: some View {
        ZStack {
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
                .environment(arViewModel)
            
            VStack {
                
                Spacer()
                
                Group {
                    if arViewModel.entity == nil {
                        Text("Tap on a surface to add the rocket")
                    } else if arViewModel.entityMoved == false {
                        Text("In front of the Camera, point your thumb to the right to go up, or left to go down")
                    }
                }
                .font(.system(size: 24))
                .bold()
                .foregroundStyle(Color.white)
                .padding()
                .background(Color.blue)
                .padding()
                .cornerRadius(10.0)
            }
        }
    }
}
