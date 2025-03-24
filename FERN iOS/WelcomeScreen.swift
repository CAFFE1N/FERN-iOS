//
//  WelcomeScreen.swift
//  FERN iOS
//
//  Created by ctstudent18 on 3/20/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct LandingPageButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(.inputBG, in: RoundedRectangle(cornerRadius: 4, style: .circular))
            .foregroundStyle(.cardText)
            .opacity(configuration.isPressed ? 0.8 : 1)
//            .imageScale(.large)
    }
}

struct InfoPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Info")
                    .font(Font.custom("PlayfairDisplay-Bold", size: 48, relativeTo: .largeTitle))
                    .foregroundStyle(.cardTitle)
                HelpTable()
                VStack(spacing: 24) {
                    Image("FERN Logo 1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 600, height: 200)
                    Text("""
Created by André S. and Glen L. in cooperation with the Maine Tree Foundation.

André says: I hopes you like the app! I spent around three months programming it.

Glen says: May your journies on the trail be Prosperous!
""")
                    .multilineTextAlignment(.center)
                }
                .frame(width: 600)
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .circular))
//                .padding(.vertical, 64)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.fernCream0)
    }
}

struct LandingPage: View {
    @State var importing: Bool = false
    
    @State var new = false
    @State var plot: Plot10 = Plot10(plotID: "New_Plot_\(Date().toString(withFormat: "(mm-hh_dd-MM-yyyy)"))", location: .init(latitude: 44.365658, longitude: -69.793207))
    
    @State var filePath: URL? = nil
    
    @EnvironmentObject var appValues: AppValues
    
//    @ViewBuilder var newPlotSheet: some View {  }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationStack {
                VStack(spacing: 24) {
                    Text("Welcome to the FERN Log!")
                        .font(Font.custom("PlayfairDisplay-Bold", size: 48, relativeTo: .largeTitle))
                        .foregroundStyle(.cardTitle)
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            Button("Open", systemImage: "folder") { importing = true }
                                .fileImporter(isPresented: $importing, allowedContentTypes: [.folder]) { result in
                                    switch result {
                                    case .success(let success): filePath = success
                                        print(success)
                                        plot = .init(url: success) ?? plot
                                        new = true
                                    case .failure(let failure): print(failure)
                                    }
                                }
                            Button("New", systemImage: "plus") {
                                withAnimation(.snappy) {
                                    new = true
                                }
                            }
                        }
                        NavigationLink {
                            InfoPage()
                        } label: { Label("Info", systemImage: "info.circle") }
                    }
                    .frame(width: 300)
                    .buttonStyle(LandingPageButton())
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .circular))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.fernCream0)
            }
            VStack(spacing: 0) {
                Button {
                    withAnimation(.snappy) {
                        new = false
                    }
                } label: {
                    Path {
                        $0.move(to: CGPoint(x: 0, y: 0))
                        $0.addLine(to: CGPoint(x: 28, y: 12))
                        $0.addLine(to: CGPoint(x: 56, y: 0))
                    }
                    .stroke(.green2, style: .init(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    .frame(width: 56, height: 12)
                    .padding(.top, 36)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: !new ? 0 : nil, alignment: .top)
                VStack(alignment: .leading, spacing: 16) {
                    Button {
//                        appValues.plots.append(plot)
                        appValues.appStatus = .loading
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            appValues.appStatus = nil
                            appValues.selectedPlot = appValues.plots.last!.id
                        }
                    } label: {
                        Text("Create")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(.green2, in: RoundedRectangle(cornerRadius: 16, style: .circular))
                    }
                    VStack(spacing: 16) {
                        VStack(spacing: 16) {
                            DataEditorField(label: "Plot ID") {
                                TextField("", text: $plot.plotID)
                            }
                            HStack(spacing: 16) {
                                DataEditorField(label: "Latitude") {
                                    DoubleField("", value: $plot.location.latitude, float: 8)
                                }
                                DataEditorField(label: "Longitude") {
                                    DoubleField("", value: $plot.location.longitude, float: 8)
                                }
                            }
                            PlotMap(location: plot.location, plotID: plot.plotID, bw: true)
                                .frame(maxHeight: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .circular))
                                .disabled(true)
                            Divider()
                            Text("All fields are required.")
                                .font(Font.custom("AvenirLTStd-Roman", size: 14, relativeTo: .caption).italic())
                                .foregroundStyle(.cardText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                    .background {
                        RoundedCorner(corners: [.topLeft, .topRight])
                            .fill(Color(.secondarySystemGroupedBackground))
                            .shadow(color: .black.opacity(0.05), radius: 4)
                    }
                }
                .padding([.horizontal, .top], 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .frame(height: !new ? 0 : nil, alignment: .top)
            }
            .frame(width: 420, height: !new ? 0 : nil)
            .clipShape(RoundedCorner(corners: [.topLeft, .topRight]))
            .scrollContentBackground(.hidden)
            .background {
                RoundedCorner(corners: [.topLeft, .topRight])
                    .fill(Material.regular.secondary)
                    .shadow(color: .black.opacity(0.1), radius: 8)
            }
            .padding(.top, 24)
            .offset(x: -24, y: !new ? 24 : 0)
            .ignoresSafeArea()
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

#Preview {
    LandingPage()
}
