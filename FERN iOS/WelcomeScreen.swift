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
    @EnvironmentObject var appValues: AppValues
    
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
    @State var plot: Plot10 = Plot10(plotID: "Plot \(Date().toString(withFormat: "dd.MM.yyyy"))", location: .init(latitude: 44.365658, longitude: -69.793207))
    
    @State var filePath: URL? = nil
    
    @State var deletionAlert: Bool = false
    @State var message: String? = nil
    
    @EnvironmentObject var appValues: AppValues
    
    //    @ViewBuilder var newPlotSheet: some View {  }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Text("Welcome to the FERN Log!")
                                .font(Font.custom("PlayfairDisplay-Bold", size: 48, relativeTo: .largeTitle))
                                .foregroundStyle(.cardTitle)
                            Spacer()
                            NavigationLink {
                                InfoPage()
                            } label: { Label("", systemImage: "info.circle").imageScale(.large) }
                        }
                        VStack(spacing: 0) {
                            Text("PLOTS")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(.white)
                                .font(.headline)
                                .padding(16)
                                .background(.green2, in: RoundedCorner(radius: 16, corners: [.topRight, .topLeft]))
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(appValues.plots) { data in
                                    Button {
                                        appValues.appStatus = .loading
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            appValues.appStatus = nil
                                            appValues.selectedPlot = data.id
                                        }
                                    } label: {
                                        HStack {
                                            Text(data.plotID).padding(16)
                                            Spacer()
                                        }
                                    }
                                    .contextMenu {
                                        Button("Delete", systemImage: "trash", role: .destructive) {
                                            deletionAlert = true
                                            appValues.selectedPlot = data.id
                                        }
                                    } preview: {
                                        Text(data.plotID).padding(16)
                                            .background(Color(.secondarySystemGroupedBackground))
                                    }
                                    if data.id != appValues.plots.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .alert("Are you sure you want to delete this plot?", isPresented: $deletionAlert) {
                                Button("Cancel", role: .cancel) { deletionAlert = false }
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    appValues.appStatus = .loading
                                        withAnimation(.snappy) {
                                            appValues.plots.removeAll(where: { $0.id == appValues.selectedPlot })
                                        } completion: {
                                            deletionAlert = false
                                            appValues.selectedPlot = nil
                                            appValues.appStatus = .welcome
                                        }
                                }
                            }
                            .buttonStyle(ListRow())
                            .background {
                                RoundedCorner(radius: 16, corners: [.bottomLeft, .bottomRight])
                                    .fill(Color(.secondarySystemGroupedBackground))
                                RoundedCorner(radius: 16, corners: [.bottomLeft, .bottomRight])
                                    .stroke(Color(.systemFill))
                                    .padding(.horizontal, 0.5)
                            }
                            .fileImporter(isPresented: $importing, allowedContentTypes: [.folder]) { result in
                                switch result {
                                case .success(let success): filePath = success
                                    print(success)
                                    if let p = Plot10(url: success) {
                                        plot = p
                                        new = true
                                    } else {
                                        appValues.appStatus = .welcome
                                        message = "We had trouble reading the info in this file."
                                    }
                                case .failure(let failure): print(failure)
                                }
                                appValues.appStatus = .welcome
                            }
                            .alert(message ?? "Error!", isPresented: .init(get: { message != nil }, set: { _ in message = nil })) {
                                Button("OK") { message = nil }
                            }
                            Menu {
                                Button("Empty Plot", systemImage: "square") {
                                    plot = Plot10(plotID: "Plot \(Date().toString(withFormat: "dd.MM.yyyy"))", location: .init(latitude: 44.365658, longitude: -69.793207))
                                    withAnimation(.snappy) {
                                        new = true
                                    }
                                }
                                Button("Import From Folder", systemImage: "folder") {
                                    appValues.appStatus = .loading
                                    importing = true
                                }
                                Divider()
                                Button("Demo Plot", systemImage: "questionmark.square") {
                                    appValues.appStatus = .loading
                                    appValues.plots.append(
                                        Plot10(
                                            forms: [
                                                OverstoryForm(steward: "Andre", location: nil, data: [
                                                    .init(treeID: "001", treeSpecies: "Oak", treeStatus: .live, dbh: 0, height: 10),
                                                    .init(treeID: "002", treeSpecies: "Birch", treeStatus: .live, dbh: 0, height: 10),
                                                    .init(treeID: "003", treeSpecies: "Pine", treeStatus: .live, dbh: 0, height: 10),
                                                ]),
                                                SnagsForm(steward: "Andre", location: nil, data: [
                                                    .init(treeID: "001", treeSpecies: "Oak", treeStatus: .downed, dbh: 0, height: 10),
                                                    .init(treeID: "002", treeSpecies: "Birch", treeStatus: .downed, dbh: 0, height: 10),
                                                    .init(treeID: "003", treeSpecies: "Pine", treeStatus: .downed, dbh: 0, height: 10),
                                                ]),
                                                WildlifeForm(steward: "Andre", location: nil),
                                                HardwoodPhenologyForm(steward: "Andre", location: nil, treeID: "001"),
                                                SoftwoodPhenologyForm(steward: "Andre", location: nil, treeID: "002"),
                                                InvasiveSpeciesForm(steward: "Andre", location: nil, data: [
                                                    .init(species: "Mint", direction: 50.539, distance: 20, heightClass: 1, area: 6),
                                                    .init(species: "Japanese Knotweed", direction: 20.2, distance: 4, heightClass: 3, area: 14)
                                                ]),
                                                TreeHealthForm(steward: "Glen", location: nil, data: [
                                                    .init(treeID: "001", treeSpecies: "Ash", crownDamageType: .branches, crownDamagePercent: 2, boleDamageType: .insect, boleDamagePercent: 1)
                                                ]),
                                                //            TrailCameraForm(steward: "Glen", location: nil, data: [
                                                //                .init(imageUrl: URL(fileURLWithPath: ""), wildlife: "Deer"),
                                                //                .init(imageUrl: nil, wildlife: "Kaleb")
                                                //            ]),
                                                
                                                SaplingsForm(steward: "Glen", location: nil, data: [
                                                    .init(treeSpecies: "Ash")
                                                ]),
                                                
                                                SeedlingsForm(steward: "Glen", location: .init(latitude: 0, longitude: 0), data: [
                                                    .init(direction: .north, treeSpecies: "Red Oak"),
                                                    .init(direction: .west, treeSpecies: "White Oak"),
                                                    .init(direction: .north, treeSpecies: "Yellow Oak"),
                                                    .init(direction: .south, treeSpecies: "Birch")
                                                ]),
                                                
                                                DebrisForm(steward: "Glen", location: .init(latitude: 0, longitude: 0), data: [
                                                    .init(transect: 120, diameter: 3, decayClass: 3, species: "Oak")
                                                ])
                                            ],
                                            plotID: "Demo Plot",
                                            location: .init(latitude: 44.365658, longitude: -69.793207)))
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        appValues.appStatus = nil
                                        appValues.selectedPlot = appValues.plots.last!.id
                                    }
                                }
                            } label: {
                                Label("Add New", systemImage: "plus")
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background {
                                        RoundedCorner(corners: appValues.plots.isEmpty ? [.bottomLeft, .bottomRight] : .allCorners)
                                            .fill(Color(.secondarySystemGroupedBackground))
                                        RoundedCorner(corners: appValues.plots.isEmpty ? [.bottomLeft, .bottomRight] : .allCorners)
                                            .stroke(Color(.systemFill))
                                            .padding(.horizontal, 0.5)
                                    }
                            }
                            .buttonStyle(ListRow())
                            .padding(.top, appValues.plots.isEmpty ? 0 : nil)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(24)
                }
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
                        appValues.plots.append(plot)
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
//                            PlotMap(location: plot.location, plotID: plot.plotID, bw: true)
//                                .frame(maxHeight: .infinity)
//                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .circular))
//                                .disabled(true)
                            Divider()
                            Text("All fields are required.")
                                .font(Font.custom("AvenirLTStd-Roman", size: 14, relativeTo: .caption).italic())
                                .foregroundStyle(.cardText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
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
            .padding(.top, 102)
            .offset(x: -24, y: !new ? 24 : 0)
            .ignoresSafeArea()
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}
