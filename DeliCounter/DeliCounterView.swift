//
//  DeliCounterView.swift
//  DeliCounter
//
//  Created by Daniel Bolella on 3/26/25.
//

import SwiftUI

struct DeliCounterView: View {
    @State var dco: DeliCounterObservable = DeliCounterObservable()
    
    var body: some View {
        VStack {
            Image(systemName: "fork.knife.circle")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Deli Now Serving:")
            
            Text(String(dco.currentCustomerServed))
            
            HStack {
                Button("Previous") {
                    dco.previousCustomer()
                }
                
                Button("Next") {
                    dco.nextCustomer()
                }
            }
        }
        .padding()
        .task {
            let server: DeliCounterServer = DeliCounterServer(addWS: dco.addWS, removeWS: dco.removeWS)
            do {
                try await server.startAsync()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
}

#Preview {
    DeliCounterView()
}
