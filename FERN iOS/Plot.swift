//
//  Plot.swift
//  FERN iOS
//
//  Created by ctstudent18 on 3/1/25.
//

import SwiftUI
import MapKit
import UniformTypeIdentifiers

class Plot10: Identifiable, ObservableObject, Hashable, Equatable {
    convenience init?(url: URL?) {
        guard let url = url else { return nil }
        
        var forms: [any PlotForm] = []
        
        for location in ["Overstory", "Snags", "Wildlife", "Hardwood_Phenology", "Softwood_Phenology", "Invasive_Species", "Tree_Health", "Saplings", "Seedlings", "Debris"] {
            guard let formCSV = try? String(contentsOf: url.appendingPathComponent("\(location)/Content.csv", isDirectory: false), encoding: .utf8), let formInfo = try? String(contentsOf: url.appendingPathComponent("\(location)/Info.txt", isDirectory: false), encoding: .utf8) else { return nil }
//            print(FormFrom(formCSV, info: formInfo))
            guard let form = FormFrom(formCSV, info: formInfo) else { return nil }
            forms.append(form)
        }
        
        guard let plotInfo = try? String(contentsOf: url.appendingPathComponent("Info.txt", isDirectory: false), encoding: .utf8) else { return nil }
        print(forms.map({ $0.csv }).joined(separator: "\n\n"))
        self.init(from: forms.map({ (csvString: $0.csv, info: $0.info) }), info: plotInfo)
    }
    
    init(plotID: String, location: PlotLocation) {
        self.plotID = plotID
        self.location = location
        
        self.overstory = OverstoryForm(steward: "", location: location)
        self.snags = SnagsForm(steward: "", location: location)
        self.wildlife = WildlifeForm(steward: "", location: location)
        self.hardwoodPhenology = HardwoodPhenologyForm(steward: "", location: location, treeID: "")
        self.softwoodPhenology = SoftwoodPhenologyForm(steward: "", location: location, treeID: "")
        self.invasiveSpecies = InvasiveSpeciesForm(steward: "", location: location)
        self.treeHealth = TreeHealthForm(steward: "", location: location)
//        self.trailCameraForm = TrailCameraForm(steward: "", location: location)
        
        self.saplingsForm = SaplingsForm(steward: "", location: location)

        self.seedlingsForm = SeedlingsForm(steward: "", location: location)

        self.debrisForm = DebrisForm(steward: "", location: location)
    }
    init(forms: [any PlotForm], plotID: String, location: PlotLocation) {
        self.plotID = plotID
        self.location = location
        
        let forms = forms.map({
            let form = $0
            form.location = location
            return form
        })
        
        self.overstory = forms.first(where: { $0 is OverstoryForm }) as! OverstoryForm
        self.snags = forms.first(where: { $0 is SnagsForm }) as! SnagsForm
        self.wildlife = forms.first(where: { $0 is WildlifeForm }) as! WildlifeForm
        self.hardwoodPhenology = forms.first(where: { $0 is HardwoodPhenologyForm }) as! HardwoodPhenologyForm
        self.softwoodPhenology = forms.first(where: { $0 is SoftwoodPhenologyForm }) as! SoftwoodPhenologyForm
        self.invasiveSpecies = forms.first(where: { $0 is InvasiveSpeciesForm }) as! InvasiveSpeciesForm
        self.treeHealth = forms.first(where: { $0 is TreeHealthForm }) as! TreeHealthForm
//        self.trailCameraForm = forms.first(where: { $0 is TrailCameraForm }) as! TrailCameraForm
        
        self.saplingsForm = forms.first(where: { $0 is SaplingsForm }) as! SaplingsForm

        self.seedlingsForm = forms.first(where: { $0 is SeedlingsForm }) as! SeedlingsForm

        self.debrisForm = forms.first(where: { $0 is DebrisForm }) as! DebrisForm
    }
    
    let id: UUID = UUID()
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    convenience init?(from values: [(csvString: String, info: String)], info: String) {
        let values = values.map({ FormFrom($0.csvString, info: $0.info) })
        guard !values.contains(where: { $0 == nil }), let v = values.filter({ $0 != nil }) as? [any PlotForm] else { return nil }
        
        let info = info.split(separator: "\n").map(\.description)
        guard info.count == 2, let lat = Double(info[1].split(separator: ",")[0]), let lon = Double(info[1].split(separator: ",")[1]) else { return nil }
        
        self.init(forms: v, plotID: info[0], location: .init(latitude: lat, longitude: lon))
    }
    
    static func == (lhs: Plot10, rhs: Plot10) -> Bool { lhs.id == rhs.id }
    
    var forms: [any PlotForm] {
        [
            overstory,
            snags,
            wildlife,
            hardwoodPhenology,
            softwoodPhenology,
            invasiveSpecies,
            treeHealth,
            saplingsForm,
            seedlingsForm,
            debrisForm
        ]
    }
    
    @Published var overstory: OverstoryForm
    @Published var snags: SnagsForm
    @Published var wildlife: WildlifeForm
    @Published var hardwoodPhenology: HardwoodPhenologyForm
    @Published var softwoodPhenology: SoftwoodPhenologyForm
    @Published var invasiveSpecies: InvasiveSpeciesForm
    @Published var treeHealth: TreeHealthForm
//    @Published var trailCameraForm: TrailCameraForm
    
    @Published var saplingsForm: SaplingsForm
    
    @Published var seedlingsForm: SeedlingsForm
    
    @Published var debrisForm: DebrisForm
        
    @Published var plotID: String
    @Published var location: PlotLocation
}
extension Plot10 {
    var info: String {
        """
\(self.plotID)
\(self.location.latitude),\(self.location.longitude)
"""
    }
    
    func wrapToFolder() -> URL {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(self.plotID.trimmingCharacters(in: .whitespacesAndNewlines), isDirectory: true)
        try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        saveTextFile(at: tempDir, fileName: "Info.txt", content: self.info)

        for i in [("Overstory", self.overstory), ("Snags", self.snags), ("Wildlife", self.wildlife), ("Hardwood_Phenology", self.hardwoodPhenology), ("Softwood_Phenology", self.softwoodPhenology), ("Invasive_Species", self.invasiveSpecies), ("Tree_Health", self.treeHealth), ("Saplings", self.saplingsForm), ("Seedlings", self.seedlingsForm), ("Debris", self.debrisForm)] as [(String, any PlotForm)] {
            let subfolder = tempDir.appendingPathComponent(i.0, isDirectory: true)
            try? fileManager.createDirectory(at: subfolder, withIntermediateDirectories: true)

            saveTextFile(at: subfolder, fileName: "Info.txt", content: i.1.info)
            saveTextFile(at: subfolder, fileName: "Content.csv", content: i.1.csv)
        }
        return tempDir
    }
}

struct PlotCard: View {
    var body: some View {
        VStack(spacing: 16) {
            PlotSymbol()
                .padding(.horizontal, 48)
                .padding(.vertical, -8)
            Divider()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    RoundedRectangle(cornerRadius: 4, style: .circular)
                        .fill(.lightGreen1)
                        .frame(width: 24, height: 24)
                    Text("1/10th")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    RoundedRectangle(cornerRadius: 4, style: .circular)
                        .fill(.peach0)
                        .frame(width: 24, height: 24)
                    Text("1/50th")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    RoundedRectangle(cornerRadius: 4, style: .circular)
                        .fill(.skyBlue1)
                        .frame(width: 24, height: 24)
                    Text("1/1000th")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    RoundedRectangle(cornerRadius: 4, style: .circular)
                        .fill(.tumeric0)
                        .frame(width: 24, height: 24)
                    Text("Transect Lines")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 300)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .circular))
    }
}

struct PlotView: View {
    @EnvironmentObject var appValues: AppValues
    @ObservedObject var plot: Plot10
    
    enum Selected {
        case map
        case form(Int)
    }
    @State var selected: Selected?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Plot Dashboard\(plot.plotID.isEmpty ? "" : ": \(plot.plotID)")")
                    .foregroundStyle(.cardTitle)
                    .font(Font.custom("PlayfairDisplay-Bold", size: 48, relativeTo: .largeTitle))
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            DataEditorField(label: "Plot ID") {
                                TextField("", text: $plot.plotID)
                            }
                            HStack(alignment: .top, spacing: 16) {
                                DataEditorField(label: "Latitude") {
                                    DoubleField("", value: $plot.location.latitude, float: 8)
                                }
                                DataEditorField(label: "Longitude") {
                                    DoubleField("", value: $plot.location.longitude, float: 8)
                                }
                            }
                            Divider()
                            Text("All fields are required.")
                                .font(Font.custom("AvenirLTStd-Roman", size: 14, relativeTo: .caption).italic())
                                .foregroundStyle(.cardText)
                                .lineSpacing(2.5)
                                .frame(maxWidth: 300, maxHeight: .infinity, alignment: .topLeading)
                        }
                        .textFieldStyle(CustomStyle())
                        .frame(width: 300, alignment: .top)
                        .frame(maxHeight: 300, alignment: .top)
                        .padding(16)
                        .foregroundStyle(.cardText)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .circular))
                        ZStack(alignment: .topTrailing) {
                            PlotMap(location: plot.location, plotID: plot.plotID, bw: true)
                                .mapStyle(.hybrid)
                                .mapControlVisibility(.hidden)
                            NavigationLink {
                                ZStack(alignment: .bottomTrailing) {
                                    PlotMap(location: plot.location, plotID: plot.plotID, bw: true, centered: true)
                                        .mapStyle(.hybrid)
                                    VStack(spacing: 12) {
                                        Path {
                                            $0.move(to: CGPoint(x: 0, y: 0))
                                            $0.addLine(to: CGPoint(x: 56, y: 0))
                                        }
                                        .stroke(.green3.opacity(0.8), style: .init(lineWidth: 8, lineCap: .round, lineJoin: .round))
                                        .frame(width: 56, height: 8)
                                        .padding(.top, 36)
                                        .frame(maxWidth: .infinity,alignment: .top)
                                        VStack(alignment: .leading, spacing: 16) {
                                            DataEditorField(label: "Latitude") {
                                                DoubleField("", value: $plot.location.latitude, float: 8)
                                            }
                                            DataEditorField(label: "Longitude") {
                                                DoubleField("", value: $plot.location.longitude, float: 8)
                                            }
                                            Divider()
                                            Text("All fields are required.")
                                                .font(Font.custom("AvenirLTStd-Roman", size: 14, relativeTo: .caption).italic())
                                                .foregroundStyle(.cardText)
                                                .lineSpacing(2.5)
                                                .frame(maxWidth: 300, maxHeight: .infinity, alignment: .topLeading)
                                        }
                                        .padding(16)
                                        .background {
                                            RoundedCorner(corners: [.topLeft, .topRight])
                                                .fill(Color(.secondarySystemGroupedBackground))
                                                .shadow(color: .black.opacity(0.05), radius: 4)
                                        }
                                        .padding([.horizontal, .top], 16)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                        .frame(alignment: .top)
                                    }
                                    .frame(width: 420)
                                    .clipShape(RoundedCorner(corners: [.topLeft, .topRight]))
                                    .background {
                                        RoundedCorner(corners: [.topLeft, .topRight])
                                            .fill(Material.regular.secondary)
                                            .shadow(color: .black.opacity(0.1), radius: 8)
                                    }
                                    .padding(.top, 128)
                                    .offset(x: -24)
                                    .ignoresSafeArea()
                                }
                            } label: {
                                HStack {
                                    Text("View Full Map")
                                    Image(systemName: "square.arrowtriangle.4.outward")
                                }
                                .foregroundStyle(.cardText)
                                .padding(8)
                                .background(.fernCream0, in: RoundedRectangle(cornerRadius: 4, style: .circular))
                            }
                            .buttonStyle(ListRow())
                            .padding(16)
                        }
                        .frame(height: 332)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .circular))
                    }
                    HStack(alignment: .top, spacing: 24) {
                        VStack(spacing: 24) {
                            PlotDataWeb(plot: plot)
                            NavigationLink {
                                InfoPage()
                            } label: {
                                HStack {
                                    Label("Info", systemImage: "info.circle")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background {
                                    RoundedCorner(corners: appValues.plots.isEmpty ? [.bottomLeft, .bottomRight] : .allCorners)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                    RoundedCorner(corners: appValues.plots.isEmpty ? [.bottomLeft, .bottomRight] : .allCorners)
                                        .stroke(Color(.systemFill))
                                        .padding(.horizontal, 0.5)
                                }
                                .tint(.primary)
                            }
                        }
                        PlotCard()
                    }
                }
            }
            .padding(.top, 8)
            .padding([.horizontal, .bottom], 24)
        }
        .background(.fernCream0)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    appValues.appStatus = .loading
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        appValues.appStatus = .welcome
                    }
                } label: {
                    Image(systemName: "house")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: plot.wrapToFolder(), preview: SharePreview(plot.plotID, image: Image(systemName: "folder.fill")))
            }
        }
    }
}

struct PlotMap: View {
    var location: PlotLocation
    var plotID: String
    
    var bw: Bool = false
    var centered: Bool = false

    private let stroke: CGFloat = 2
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            let plotLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            Map {
                if centered {
                    Annotation("", coordinate: addFeetToCoordinate(coord: plotLocation, northFeet: 0, eastFeet: 260), content: { EmptyView() })
                }
                if bw {
                    MapCircle(center: plotLocation, radius: CLLocationDistance(feetToMeters(37.2)))
                        .foregroundStyle(.clear)
                        .stroke(.black, lineWidth: stroke+3)
                    ForEach(0...2, id: \.self) { i in
                        let p2 = rotateCoordinate(around: plotLocation, point: addFeetToCoordinate(coord: plotLocation, northFeet: 50, eastFeet: 0), by: Double(i*120))
                        MapPolyline(coordinates: [plotLocation, p2], contourStyle: .straight)
                            .stroke(.black, style: .init(lineWidth: stroke+3, lineCap: .round))
                    }
                    ForEach(0...3, id: \.self) { i in
                        var location: CLLocationCoordinate2D {
                            switch i {
                            case 0:
                                return addFeetToCoordinate(coord: plotLocation, northFeet: 16.65, eastFeet: 0)
                            case 1:
                                return addFeetToCoordinate(coord: plotLocation, northFeet: 0, eastFeet: 16.65)
                            case 2:
                                return addFeetToCoordinate(coord: plotLocation, northFeet: -16.65, eastFeet: 0)
                            case 3:
                                return addFeetToCoordinate(coord: plotLocation, northFeet: 0, eastFeet: -16.65)
                            default: return plotLocation
                            }
                        }
                        MapCircle(center: location, radius: CLLocationDistance(feetToMeters(3.72)))
                            .foregroundStyle(.clear)
                            .stroke(.black, style: .init(lineWidth: stroke+3, lineCap: .round))
                    }
                    MapCircle(center: plotLocation, radius: CLLocationDistance(feetToMeters(16.65)))
                        .foregroundStyle(.clear)
                        .stroke(.black, style: .init(lineWidth: stroke+1.5, lineCap: .round, dash: [5, 10]))
                }
                MapCircle(center: plotLocation, radius: CLLocationDistance(feetToMeters(74)))
                    .foregroundStyle(.clear)
                MapCircle(center: plotLocation, radius: CLLocationDistance(feetToMeters(37.2)))
                    .foregroundStyle(Color(bw ? .clear : .lightGreen0).opacity(0.2))
                    .stroke(bw ? .white : .lightGreen1, lineWidth: stroke)
                MapCircle(center: plotLocation, radius: CLLocationDistance(feetToMeters(16.65)))
                    .foregroundStyle(Color(bw ? .clear : .peach0).opacity(0.2))
                    .stroke(bw ? .white : .peach1, style: .init(lineWidth: stroke, lineCap: .round, dash: [5, 10]))
                ForEach(0...3, id: \.self) { i in
                    var location: CLLocationCoordinate2D {
                        switch i {
                        case 0:
                            return addFeetToCoordinate(coord: plotLocation, northFeet: 16.65, eastFeet: 0)
                        case 1:
                            return addFeetToCoordinate(coord: plotLocation, northFeet: 0, eastFeet: 16.65)
                        case 2:
                            return addFeetToCoordinate(coord: plotLocation, northFeet: -16.65, eastFeet: 0)
                        case 3:
                            return addFeetToCoordinate(coord: plotLocation, northFeet: 0, eastFeet: -16.65)
                        default: return plotLocation
                        }
                    }
                    MapCircle(center: location, radius: CLLocationDistance(feetToMeters(3.72)))
                        .foregroundStyle(Color(bw ? .clear : .skyBlue0).opacity(0.1))
                        .stroke(bw ? .white : .skyBlue1, lineWidth: stroke)
                }
                ForEach(0...2, id: \.self) { i in
                    let p2 = rotateCoordinate(around: plotLocation, point: addFeetToCoordinate(coord: plotLocation, northFeet: 50, eastFeet: 0), by: Double(i*120))
                    MapPolyline(coordinates: [plotLocation, p2], contourStyle: .straight)
                        .stroke(bw ? .white : .tumeric0, lineWidth: stroke)
                }
                Annotation(plotID, coordinate: addFeetToCoordinate(coord: plotLocation, northFeet: -37, eastFeet: 0)) { EmptyView() }
            }
            .mapStyle(.hybrid)
        }
    }
}

#Preview("Plot") {
    @Previewable @StateObject var appValues = AppValues()
    
    NavigationStack {
        PlotView(plot: AppValues().plots.first!)
    }
    .environmentObject(appValues)
}
