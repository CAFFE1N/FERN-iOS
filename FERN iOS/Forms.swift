//
//  Forms.swift
//  FERN iOS
//
//  Created by ctstudent18 on 2/24/25.
//

import SwiftUI
import MapKit

protocol PlotForm: Identifiable, ObservableObject, Equatable, Codable {
    var id: UUID { get }
    
    var steward: String { get set }
    
    var date: Date { get set }
    var location: PlotLocation? { get set }
    
    associatedtype D: FormData
    var data: [D] { get set }
    var selected: UUID? { get set }
    
    associatedtype DataEditor: View
    var dataEditor: DataEditor { get }
    
    associatedtype Body: View
    var body: Body { get }
    
    init(id: UUID, steward: String, date: Date, location: PlotLocation?, data: [D], selected: UUID?)
}

enum FormCodingKeys: String, CodingKey {
    case info
    case csv
}

extension PlotForm {
    init(_ plotForm: any PlotForm, data: [Self.D]) {
        self.init(id: plotForm.id, steward: plotForm.steward, date: plotForm.date, location: plotForm.location, data: data, selected: plotForm.selected)
    }
    
    init?(_ csvString: String, info: String) {
        let data: [D?] = csvString.split(separator: "\n").map({ D.init($0.split(separator: ",", omittingEmptySubsequences: true).map(\.description)) })
        if data.contains(nil) { return nil }

        let info = info.split(separator: "\n", omittingEmptySubsequences: true).map(\.description)
        guard info.count == 4 else { return nil }

        guard let date = info[2].toDate() else { return nil }
        
        var location: PlotLocation? = nil
        if info[1] != "N/A"  {
            let locationInfo = info[1].split(separator: ",", omittingEmptySubsequences: true).map(\.description)
            guard let lat = Double(locationInfo[0]), let lon = Double(locationInfo[1]) else { return nil }
            location = PlotLocation(latitude: lat, longitude: lon)
        }

        self.init(id: UUID(), steward: info[0], date: date, location: location, data: data.filter({ $0 != nil }) as! [D], selected: nil)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: FormCodingKeys.self)
        let info = try values.decode(String.self, forKey: .info)
        let csv = try values.decode(String.self, forKey: .csv)
        if let _ = FormFrom(csv, info: info) {
            self.init(csv, info: info)!
        } else { throw "Could not decode!" }
    }
    
    var info: String {
        var loc = "N/A"
        if let location = location { loc = "\(location.latitude),\(location.longitude)" }
        
        return [
            steward.fillString(),
            loc,
            date.toString(),
            FormType(form: Self.self)!.rawValue
        ].joined(separator: "\n")
    }
    var csv: String { self.data.map(\.csvRow).joined(separator: "\n") }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FormCodingKeys.self)
        try container.encode(self.info, forKey: .info)
        try container.encode(self.csv, forKey: .csv)
    }
}

func FormFrom(_ csvString: String, info i: String) -> (any PlotForm)? {
    let info = i.split(separator: "\n", omittingEmptySubsequences: true).map(\.description)
    guard info.count >= 4, let form = FormType(rawValue: info[3]) else { return nil }
    
    return form.from(csvString, info: i)
}

enum FormType: String, CaseIterable {
    init?(rawValue: String) {
        guard let value = FormType.allCases.first(where: { $0.rawValue == rawValue }) else { return nil }
        self = value
    }
    
    init?(form: any PlotForm.Type) {
        guard let value = FormType.allCases.first(where: { $0.form == form }) else { return nil }
        self = value
    }
    
    case overstory, snags, wildlife, hardwood_phenology, softwood_phenology, invasive_species, tree_health
    case saplings
    case seedlings
    case debris
//    case trail_camera
        
    var rawValue: String { "\(self)".replacingOccurrences(of: "_", with: " ").capitalized }
    
    var form: any PlotForm.Type {
        switch self {
        case .overstory: OverstoryForm.self
        case .snags: SnagsForm.self
        case .wildlife: WildlifeForm.self
        case .hardwood_phenology: HardwoodPhenologyForm.self
        case .softwood_phenology: SoftwoodPhenologyForm.self
        case .invasive_species: InvasiveSpeciesForm.self
        case .tree_health: TreeHealthForm.self
        case .saplings: SaplingsForm.self
        case .seedlings: SeedlingsForm.self
        case .debris: DebrisForm.self
//        case .trail_camera: TrailCameraForm.self
        }
    }
    
    func from(_ csvString: String, info: String) -> (any PlotForm)? { self.form.init(csvString, info: info) }
}

protocol FormData: Hashable, Identifiable, View {
    init()
    init?(_ values: [String])
    
    var id: UUID { get }
    var csvRow: String { get }
}
extension FormData { func hash(into hasher: inout Hasher) { hasher.combine(id) } }

protocol Plot10Form: PlotForm { }
protocol PhenologyForm: PlotForm { var treeID: String { get set } }
protocol Plot50Form: PlotForm { }
protocol Plot1000Form: PlotForm { }
protocol TransectLineForm: PlotForm { }

struct PlotLocationField: View {
    init(_ value: Binding<PlotLocation?>) {
        self._value = value
        self._longitude = State(initialValue: value.wrappedValue?.longitude)
        self._latitude = State(initialValue: value.wrappedValue?.latitude)
    }
    
    @Binding var value: PlotLocation?
    
    @State var longitude: Double?
    @State var latitude: Double?
    
    var body: some View {
        DataEditorField(label: "Latitude", required: false) {
            OptionalDoubleField("", value: .init(get: {
                latitude
            }, set: { v in
                if let v = v {
                    value = PlotLocation(latitude: v, longitude: value?.longitude ?? 0.0)
                    latitude = v
                    longitude = value?.longitude ?? 0.0
                } else {
                    value = nil
                    latitude = nil
                    longitude = nil
                }
            }), float: 8)
        }
        DataEditorField(label: "Longitude", required: false) {
            OptionalDoubleField("", value: .init(get: {
                longitude
            }, set: { v in
                if let v = v {
                    value = PlotLocation(latitude: value?.latitude ?? 0.0, longitude: v)
                    longitude = v
                    latitude = value?.latitude ?? 0.0
                } else {
                    value = nil
                    longitude = nil
                    latitude = nil
                }
            }), float: 8).foregroundStyle(.primary)
        }
    }
}

struct FormTreeIDEditor<F: PhenologyForm>: View {
    @Binding var form: F
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "asterisk").font(.system(size: 50, weight: .black))
                .foregroundStyle(.green2)
            DataEditorField(label: "Tree ID") {
                TextField("", text: $form.treeID)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .circular))
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
    }
}

struct FormHeader<P: PlotForm/*, C: View*/>: View {
    @State var title: String
    @Binding var form: P
    var info: (() -> (Text))? = nil
    //    @Optional @Binding var extra: String
    //    @ViewBuilder var content: C

    var body: some View {
        Text("\(title) Data Form")
            .font(Font.custom("PlayfairDisplay-Bold", size: 48, relativeTo: .largeTitle))
            .foregroundStyle(Color.cardTitle)
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    DataEditorField(label: "Steward") {
                        TextField("", text: $form.steward)
                    }
                    DataEditorField(label: "Date") {
                        DatePicker("", selection: $form.date, displayedComponents: .date)
                    }
                    HStack(spacing: 16) {
                        PlotLocationField($form.location)
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Required fields are marked with an asterisk (*).")
                        Text("Leave a question mark (?) in a text field to omit it from the form.")
                    }
                    .font(Font.custom("AvenirLTStd-Roman", size: 14, relativeTo: .caption).italic())
                    .lineSpacing(2.5)
                    .foregroundStyle(.cardText)
                    .frame(maxWidth: 300, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(width: 300, alignment: .top)
                .frame(maxHeight: 300, alignment: .top)
                .padding(16)
                .foregroundStyle(.cardText)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .circular))
            }
            ZStack {
                if let location = form.location {
                    ZStack(alignment: .topTrailing) {
                        Map {
                            MapCircle(center: .init(latitude: location.latitude, longitude: location.longitude), radius: CLLocationDistance(feetToMeters(100)))
                                .foregroundStyle(.clear)
                            Marker("", coordinate: .init(latitude: location.latitude, longitude: location.longitude))
                        }
                        .mapControlVisibility(.hidden)
                        .mapStyle(.hybrid)
                        NavigationLink {
                            Map {
                                MapCircle(center: .init(latitude: location.latitude, longitude: location.longitude), radius: CLLocationDistance(feetToMeters(100)))
                                    .foregroundStyle(.clear)
                                Marker("", coordinate: .init(latitude: location.latitude, longitude: location.longitude))
                            }
                            .mapStyle(.hybrid)
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
                } else {
                    ContentUnavailableView("No Map Coordinates", systemImage: "square.dashed")
                }
            }
            .mapStyle(.hybrid)
            .frame(maxWidth: info == nil ? .infinity : 332)
            .frame(height: 332)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .circular))
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .circular))
            if let info = info {
                ScrollView {
                    VStack(alignment: .leading) {
                        Label("Info", systemImage: "info.circle")
                            .font(Font.custom("PlayfairDisplay-Bold", size: 24, relativeTo: .headline))
                            .imageScale(.small)
                            .foregroundStyle(.cardTitle)
                            .padding(.bottom, 8)
                        info()
                            .font(Font.custom("AvenirLTStd-Roman", size: 16, relativeTo: .body))
                            .lineSpacing(2.5)
                            .foregroundStyle(.cardText)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(16)
                }
                .frame(height: 332, alignment: .topLeading)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .circular))
            }
        }
        .textFieldStyle(CustomStyle())
//        .navigationTitle("\(title) Data Form")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FormView<F: PlotForm>: View {
    @ObservedObject var form: F
    
    @State var alertPresented: Bool = false
    @EnvironmentObject var appValues: AppValues
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    form.body
                        .lineSpacing(2.5)
                    if !(form is WildlifeForm || form is HardwoodPhenologyForm || form is SoftwoodPhenologyForm) {
                        Button {
                            withAnimation(.snappy) {
                                form.data.append(.init())
                                form.selected = form.data.map(\.id).last
                            }
                        } label: {
                            Label("Add New", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background {
                                    RoundedCorner(corners: form.data.isEmpty ? [.bottomLeft, .bottomRight] : .allCorners)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                    RoundedCorner(corners: form.data.isEmpty ? [.bottomLeft, .bottomRight] : .allCorners)
                                        .stroke(Color(.systemFill))
                                        .padding(.horizontal, 0.5)
                                }
                        }
                        .buttonStyle(ListRow())
                        .padding(.horizontal, 24)
                        .padding(.top, form.data.isEmpty ? 0 : nil)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
            .background(Color.fernCream0, ignoresSafeAreaEdges: .all)
            VStack(spacing: 0) {
                Button {
                    withAnimation(.snappy) {
                        form.selected = nil
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
                .frame(height: form.selected == nil ? 0 : nil, alignment: .top)
                if !(form is WildlifeForm || form is HardwoodPhenologyForm || form is SoftwoodPhenologyForm) {
                    Menu("", systemImage: "ellipsis.circle") {
                        Button(role: .destructive) {
                            alertPresented = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(ListRow())
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .circular))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 16)
                    .imageScale(.large)
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        form.dataEditor
                        Rectangle()
                            .fill(Color(.secondarySystemFill))
                            .frame(height: 1)
                        Text("Required fields are marked with an asterisk (*).\n\nLeave a question mark (?) in a text field to omit it from the form.")
                            .font(Font.custom("AvenirLTStd-Roman", size: 14, relativeTo: .caption).italic())
                            .lineSpacing(2.5)
                            .foregroundStyle(.cardText)
                            .frame(maxWidth: 300, maxHeight: .infinity, alignment: .topLeading)
                    }
                    .foregroundStyle(.cardText)
                    .padding(16)
                }
                .background {
                    RoundedCorner(corners: [.topLeft, .topRight])
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: .black.opacity(0.05), radius: 4)
                }
                .padding([.horizontal, .top], 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .frame(height: form.selected == nil ? 0 : nil, alignment: .top)
            }
            .frame(width: 420, height: form.selected == nil ? 0 : nil)
            .clipShape(RoundedCorner(corners: [.topLeft, .topRight]))
            .scrollContentBackground(.hidden)
            .background {
                RoundedCorner(corners: [.topLeft, .topRight])
                    .fill(Material.regular.secondary)
                    .shadow(color: .black.opacity(0.1), radius: 8)
            }
            .padding(.top, 102)
            .offset(x: -24, y: form.selected == nil ? 24 : 0)
            .ignoresSafeArea(.container)
        }
        .onDisappear { form.selected = nil }
        .alert("Are you sure you want to delete this entry?", isPresented: $alertPresented) {
            Button("Cancel", role: .cancel) { alertPresented = false }
            Button("Delete", systemImage: "trash", role: .destructive) {
                if let selected = form.selected {
                    withAnimation(.snappy) {
                        form.selected = nil
                        appValues.appStatus = "loading"
                    } completion: {
                        withAnimation(.snappy) {
                            form.data.removeAll(where: { $0.id == selected })
                        } completion: {
                            alertPresented = false
                            appValues.appStatus = nil
                        }
                    }
                }
            }
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

//MARK: Overstory
class OverstoryForm: Plot10Form {
    required init(id: UUID, steward: String, date: Date, location: PlotLocation?, data: [D], selected: UUID?) {
        self.id = id
        self.steward = steward
        self.date = date
        self.location = location
        self.data = data
        self.selected = selected
    }
    
    init(steward: String, location: PlotLocation?, data: [D] = []) {
        self.steward = steward
        self.location = location
        self.data = data
    }
    
    static func == (lhs: OverstoryForm, rhs: OverstoryForm) -> Bool { lhs.id == rhs.id }
    
    var id: UUID = UUID()
    
    @Published var steward: String
    @Published var date: Date = Date()
    var location: PlotLocation?
    
    @Published var data: [OverstoryData]
    @Published var selected: UUID?
    
    struct OverstoryData: FormData {
        init() { self.id = UUID() }
        init(treeID: String, treeSpecies: String, treeStatus: TreeStatus, dbh: Double, height: Double) {
            self.id = UUID()
            self.treeID = treeID
            self.treeSpecies = treeSpecies
            self.treeStatus = treeStatus
            self.dbh = dbh
            self.height = height
        }
        
        init?(_ values: [String]) {
            guard values.count == 5 else { return nil }
            self.id = UUID()
            
            self.treeID = values[0].emptyString()
            self.treeSpecies = values[1].emptyString()
            
            guard let treeStatus = TreeStatus(rawValue: values[2].emptyString().lowercased().replacingOccurrences(of: " ", with: "_")), let dbh = Double(values[3].emptyString()), let height = Double(values[4].emptyString()) else { return nil }
            
            self.treeStatus = treeStatus
            self.dbh = dbh
            self.height = height
        }
        
        let id: UUID
        var csvRow: String { "\(treeID.fillString()),\(treeSpecies.fillString()),\(treeStatus.rawValue.replacingOccurrences(of: "_", with: " ").capitalized),\(dbh),\(height)" }
        
        var treeID: String = ""
        var treeSpecies: String = ""
        
        enum TreeStatus: String, CaseIterable { case live, dead_downed, dead_harvested, dead_standing }
        var treeStatus: TreeStatus = .live
        
        var dbh: Double = 0
        var height: Double = 0
        
        var body: some View {
            HStack(spacing: 12) {
                RedundantText(treeID)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText(treeSpecies)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText(treeStatus.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText("\(String(format: "%.\(Double(Int(dbh)) == dbh ? 0 : 2)f", dbh))", suffix: "in")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText("\(String(format: "%.\(Double(Int(height)) == height ? 0 : 2)f", height))", suffix: "ft")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .lineLimit(1)
        }
    }
    
    @ViewBuilder var dataEditor: some View {
        if !data.isEmpty, let i = data.firstIndex(where: { $0.id == selected }) {
            let selectedData = Binding(get: {
                    self.data[i]
            }, set: { value in
                self.data[i] = value
            })
            VStack(alignment: .leading, spacing: 16) {
                DataEditorField(label: "TREE ID") {
                    TextField("", text: selectedData.treeID)
                }
                DataEditorField(label: "SPECIES") {
                    TextField("", text: selectedData.treeSpecies)
                }
                DataEditorField(label: "STATUS") {
                    Picker("", selection: selectedData.treeStatus) {
                        ForEach(OverstoryData.TreeStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized).tag(status)
                        }
                    }
                }
                DataEditorField(label: "DBH (INCHES)") {
                    DoubleField("", value: selectedData.dbh)
                }
                DataEditorField(label: "HEIGHT (FEET)") {
                    DoubleField("", value: selectedData.height)
                }
            }
        } else { ContentUnavailableView("Nothing Selected", systemImage: "square.dashed") }
    }
    
    @ViewBuilder var body: some View {
        FormHeader(title: "Overstory", form: .init(get: {
            self
        }, set: { plotForm in
            self.steward = plotForm.steward
            self.date = plotForm.date
        }))
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        HStack(alignment: .top, spacing: 25) {
            Text("TREE ID")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("SPECIES")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("STATUS")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("DBH")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("HEIGHT")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
        .font(.headline)
        .padding(16)
        .background(.green2, in: RoundedCorner(radius: 16, corners: [.topRight, .topLeft]))
        .padding(.horizontal, 24)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(data) { data in
                Button {
                    withAnimation(.snappy) {
                        self.selected = data.id
                    }
                } label: {
                    data.padding(16)
                }
                if data.id != self.data.last?.id {
                    Divider()
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
        .padding(.horizontal, 24)
    }
}

//MARK: Snags
class SnagsForm: Plot10Form {
    required init(id: UUID, steward: String, date: Date, location: PlotLocation?, data: [D], selected: UUID?) {
        self.id = id
        self.steward = steward
        self.date = date
        self.location = location
        self.data = data
        self.selected = selected
    }
    
    init(steward: String, location: PlotLocation?, data: [D] = []) {
        self.steward = steward
        self.location = location
        self.data = data
    }
    
    static func == (lhs: SnagsForm, rhs: SnagsForm) -> Bool { lhs.id == rhs.id }
    
    var id: UUID = UUID()
    
    @Published var steward: String
    @Published var date: Date = Date()
    var location: PlotLocation?
    
    @Published var data: [SnagsData]
    @Published var selected: UUID?
    
    struct SnagsData: FormData {
        init() { self.id = UUID() }
        init(treeID: String, treeSpecies: String, treeStatus: TreeStatus, dbh: Double, height: Double) {
            self.id = UUID()
            self.treeID = treeID
            self.treeSpecies = treeSpecies
            self.treeStatus = treeStatus
            self.dbh = dbh
            self.height = height
        }
        
        init?(_ values: [String]) {
            guard values.count == 5 else { return nil }
            self.id = UUID()
            
            self.treeID = values[0].emptyString()
            self.treeSpecies = values[1].emptyString()
            
            guard let treeStatus = TreeStatus(rawValue: values[2].emptyString().lowercased().replacingOccurrences(of: " ", with: "_")), let dbh = Double(values[3].emptyString()), let height = Double(values[4].emptyString()) else { return nil }
            
            self.treeStatus = treeStatus
            self.dbh = dbh
            self.height = height
        }
        
        let id: UUID
        var csvRow: String { "\(treeID.fillString()),\(treeSpecies.fillString()),\(treeStatus.rawValue.replacingOccurrences(of: "_", with: " ").capitalized),\(dbh),\(height)" }

        var treeID: String = ""
        var treeSpecies: String = ""
        
        enum TreeStatus: String, CaseIterable { case complete_crown, damaged_crown, missing_crown, downed }
        var treeStatus: TreeStatus = .complete_crown
        
        var dbh: Double = 0
        var height: Double = 0
        
        var body: some View {
            HStack(spacing: 12) {
                RedundantText(treeID)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText(treeSpecies)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText(treeStatus.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText("\(String(format: "%.\(Double(Int(dbh)) == dbh ? 0 : 2)f", dbh))", suffix: "in")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText("\(String(format: "%.\(Double(Int(height)) == height ? 0 : 2)f", height))", suffix: "ft")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .lineLimit(1)
        }
    }
    
    @ViewBuilder var dataEditor: some View {
        if !data.isEmpty, let i = data.firstIndex(where: { $0.id == selected }) {
            let selectedData = Binding(get: {
                self.data[i]
            }, set: { value in
                self.data[i] = value
            })
            VStack(alignment: .leading, spacing: 16) {
                DataEditorField(label: "TREE ID") {
                    TextField("", text: selectedData.treeID)
                }
                DataEditorField(label: "SPECIES") {
                    TextField("", text: selectedData.treeSpecies)
                }
                DataEditorField(label: "STATUS") {
                    Picker("", selection: selectedData.treeStatus) {
                        ForEach(SnagsData.TreeStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized).tag(status)
                        }
                    }
                }
                DataEditorField(label: "DBH (INCHES)") {
                    DoubleField("", value: selectedData.dbh)
                }
                DataEditorField(label: "HEIGHT (FEET)") {
                    DoubleField("", value: selectedData.height)
                }
                Rectangle()
                    .fill(Color(.secondarySystemFill))
                    .frame(height: 1)
                Text("""
    If you completed the Overstory activity for this plot, you may have already collected some data on snags. Here, we collect additional data on each snag, looking specifically at the process of decay.

    **Complete Crown:** The top of the trunk and branches appear completely in tact.
    **Damaged Crown:** THe top of the trunk and branches appear partially missing or otherwise damaged.
    **Missing Crown:** top of the trunk and branches appear to have fallen off the tree.
    **Downed:** use this code if data was collected on a snag in a previous year, but that snag has fallen to the ground and is now a log.
    """)
                    .font(Font.custom("AvenirLTStd-Roman", size: 14, relativeTo: .caption).italic())
                    .lineSpacing(2.5)
            }
        } else { ContentUnavailableView("Nothing Selected", systemImage: "square.dashed") }
    }
    
    @ViewBuilder var body: some View {
        FormHeader(title: "Snags", form: .init(get: {
            self
        }, set: { plotForm in
            self.steward = plotForm.steward
            self.date = plotForm.date
        })) {
            Text("""
If you completed the Overstory activity for this plot, you may have already collected some data on snags. Here, we collect additional data on each snag, looking specifically at the process of decay.

**Complete Crown:** The top of the trunk and branches appear completely in tact.
**Damaged Crown:** THe top of the trunk and branches appear partially missing or otherwise damaged.
**Missing Crown:** top of the trunk and branches appear to have fallen off the tree.
**Downed:** use this code if data was collected on a snag in a previous year, but that snag has fallen to the ground and is now a log.
""")
        }
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        HStack(alignment: .top, spacing: 25) {
            Text("TREE ID")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("SPECIES")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("STATUS")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("DBH")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("HEIGHT")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
        .font(.headline)
        .padding(16)
        .background(.green2, in: RoundedCorner(radius: 16, corners: [.topRight, .topLeft]))
        .padding(.horizontal, 24)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(data) { data in
                Button {
                    withAnimation(.snappy) {
                        self.selected = data.id
                    }
                } label: {
                    data.padding(16)
                }
                if data.id != self.data.last?.id {
                    Divider()
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
        .padding(.horizontal, 24)
    }
}

//MARK: Observing Wildlife
class WildlifeForm: Plot10Form {
    required init(id: UUID, steward: String, date: Date, location: PlotLocation?, data: [D], selected: UUID?) {
        self.id = id
        self.steward = steward
        self.date = date
        self.location = location
        self.data = data
        self.selected = selected
    }
    
    init(steward: String, location: PlotLocation?) {
        self.steward = steward
        self.location = location
    }
    
    static func == (lhs: WildlifeForm, rhs: WildlifeForm) -> Bool { lhs.id == rhs.id }
    
    var id: UUID = UUID()
    
    @Published var steward: String
    @Published var date: Date = Date()
    var location: PlotLocation?
    
    @Published var data: [WildlifeData] = WildlifeData.AnimalClass.allCases.map { WildlifeData(animalClass: $0) }
    @Published var selected: UUID?
    
    struct WildlifeData: FormData {
        init() { self.id = UUID() }
        init(animalClass: AnimalClass) { self.animalClass = animalClass; self.id = UUID()}
        
        init?(_ values: [String]) {
            guard values.count == 3 else { return nil }
            self.id = UUID()
            
            guard let animalClass = AnimalClass(rawValue: values[0].lowercased().emptyString()) else { return nil }; self.animalClass = animalClass
            
            self.signs = values[1].emptyString()
            self.sightings = values[2].emptyString()
        }
        
        let id: UUID
        var csvRow: String { "\(animalClass.rawValue.capitalized),\(signs.fillString()),\(sightings.fillString())" }
        
        enum AnimalClass: String, CaseIterable {
            case mammals, birds, reptiles, amphibians, spiders, insects
            case other
        }
        var animalClass: AnimalClass = .other
        
        var signs: String = ""
        var sightings: String = ""
        
        var body: some View {
            HStack(spacing: 12) {
                RedundantText(animalClass.rawValue.capitalized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText(signs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText(sightings)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .lineLimit(1)
        }
    }
    
    @ViewBuilder var dataEditor: some View {
        if !data.isEmpty, let i = data.firstIndex(where: { $0.id == selected }) {
            let selectedData = Binding(get: {
                self.data[i]
            }, set: { value in
                self.data[i] = value
            })
            VStack(alignment: .leading, spacing: 16) {
                Text(selectedData.wrappedValue.animalClass.rawValue.capitalized)
                    .font(Font.custom("PlayfairDisplay-Bold", size: 22, relativeTo: .title3))
                Divider()
                DataEditorField(label: "SIGNS") {
                    TextField("", text: selectedData.signs)
                }
                DataEditorField(label: "SIGHTINGS") {
                    TextField("", text: selectedData.sightings)
                }
            }
        } else { ContentUnavailableView("Nothing Selected", systemImage: "square.dashed") }
    }
    
    @ViewBuilder var body: some View {
        FormHeader(title: "Observing Wildlife", form: .init(get: {
            self
        }, set: { plotForm in
            self.steward = plotForm.steward
            self.date = plotForm.date
        }))
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        HStack(alignment: .top, spacing: 25) {
            Text("ANIMAL CLASS")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("SIGNS")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("SIGHTINGS")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
        .font(.headline)
        .padding(16)
        .background(.green2, in: RoundedCorner(radius: 16, corners: [.topRight, .topLeft]))
        .padding(.horizontal, 24)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(data) { data in
                Button {
                    withAnimation(.snappy) {
                        self.selected = data.id
                    }
                } label: {
                    data.padding(16)
                }
                if data.id != self.data.last?.id {
                    Divider()
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
        .padding(.horizontal, 24)
    }
}

//MARK: Hardwood Phenology
class HardwoodPhenologyForm: Plot10Form, PhenologyForm {
    required init(id: UUID, steward: String, date: Date, location: PlotLocation?, data: [D], selected: UUID?) {
        self.id = id
        self.steward = steward
        self.date = date
        self.location = location
        self.data = data
        self.selected = selected
    }
    
    init(steward: String, location: PlotLocation?, treeID: String) {
        self.steward = steward
        self.location = location
        self.treeID = treeID
    }
    
    static func == (lhs: HardwoodPhenologyForm, rhs: HardwoodPhenologyForm) -> Bool { lhs.id == rhs.id }
    
    var id: UUID = UUID()
    
    @Published var steward: String
    @Published var date: Date = Date()
    var location: PlotLocation?
    
    @Published var data: [PhenologyData] = [
        .init(title: "Breaking Leaf Buds"),
        .init(title: "Leaves"),
        .init(title: "Increasing Leaf Size"),
        .init(title: "Colored Leaves"),
        .init(title: "Falling Leaves"),
        .init(title: "Flowers or Flower Buds"),
        .init(title: "Open Flowers"),
        .init(title: "Pollen Release"),
        .init(title: "Developing Fruits"),
        .init(title: "Ripe Fruits"),
        .init(title: "Recent Fruits/Seed Drops")
    ]
    @Published var selected: UUID?
    
    @Published var treeID: String = ""
        
    struct PhenologyData: FormData {
        init() { self.id = UUID() }
        init(title: String) { self.title = title; self.id = UUID() }
        
        init?(_ values: [String]) {
            guard values.count == 3 else { return nil }
            self.id = UUID()
            
            self.title = values[0].emptyString()
            self.isOn = values[1] == "Present"
            self.note = values[2].emptyString()
        }
        
        let id: UUID
        var csvRow: String { "\(title),\(isOn ? "Present" : "Absent"),\(note.fillString())" }
        
        var title: String = ""
        var isOn: Bool = false
        var note: String = ""
        
        var body: some View {
            HStack(spacing: 12) {
                Text(title.capitalized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                Text(isOn ? "Present" : "Absent")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText(note)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    @ViewBuilder var dataEditor: some View {
        if !data.isEmpty, let i = data.firstIndex(where: { $0.id == selected }) {
            let selectedData = Binding(get: {
                self.data[i]
            }, set: { value in
                self.data[i] = value
            })
            VStack(alignment: .leading, spacing: 16) {
                Text(selectedData.wrappedValue.title.capitalized)
                    .font(Font.custom("PlayfairDisplay-Bold", size: 22, relativeTo: .title3))
                Divider()
                DataEditorField(label: "STATUS") {
                    HStack {
                        Button("Absent") {
                            withAnimation(.bouncy(duration: 0.25, extraBounce: 0.12)) {
                                selectedData.wrappedValue.isOn = false
                            }
                        }
                        Toggle("", isOn: selectedData.isOn).toggleStyle(Checkmark(false))
                        Button("Present") {
                            withAnimation(.bouncy(duration: 0.25, extraBounce: 0.12)) {
                                selectedData.wrappedValue.isOn = true
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderless)
                .tint(.primary)
                DataEditorField(label: "NOTE") {
                    TextField("", text: selectedData.note)
                }
            }
        } else { ContentUnavailableView("Nothing Selected", systemImage: "square.dashed") }
    }
    
    @ViewBuilder var body: some View {
        FormHeader(title: "Hardwood Phenology", form: .init(get: {
            self
        }, set: { plotForm in
            self.steward = plotForm.steward
            self.date = plotForm.date
        })) {
            Text("Remember to fill out the Tree ID field!")
        }
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        FormTreeIDEditor(form: .init(get: { self }, set: { self.treeID = $0.treeID }))
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 25) {
                Text("PHENOPHASE")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("STATUS")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("NOTE/INTENSITY")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(.white)
            .font(.headline)
            .padding(.leading, 72)
            .padding([.vertical, .trailing], 16)
            .background(.green2, in: RoundedCorner(radius: 16, corners: [.topLeft, .topRight]))
            let sections: [(String, ClosedRange<Int>)] = [("VEGETATIVE", 0...4), ("REPRODUCTIVE", 5...7), ("FRUIT/SEED", 8...10)]
            ForEach(sections, id: \.0) { section in
                HStack(spacing: 0) {
                    Text(section.0.uppercased())
                        .foregroundStyle(.secondary)
                        .frame(width: 400)
                        .rotationEffect(.degrees(-90))
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 24)
                        .frame(maxHeight: .infinity)
                        .padding(16)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedCorner(radius: 16, corners: section.0 == "FRUIT/SEED" ? .bottomLeft : []))
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(self.data[section.1], id: \.id) { data in
                            Button {
                                withAnimation(.snappy) {
                                    self.selected = data.id
                                }
                            } label: {
                                data.padding(16)
                            }
                            if data.id != (self.data[section.1].map(\.id).last) {
                                Divider()
                            }
                        }
                    }
                }
                if section.0 != "FRUIT/SEED" {
                    Rectangle().fill(.green2)
                        .frame(height: 1)
                }
            }
        }
        .buttonStyle(ListRow())
        .background {
            RoundedRectangle(cornerRadius: 16, style: .circular)
                .fill(Color(.secondarySystemGroupedBackground))
            RoundedRectangle(cornerRadius: 16, style: .circular)
                .stroke(Color(.systemFill))
                .padding(.horizontal, 0.5)
        }
        .padding(.horizontal, 24)
    }
}

//MARK: Softwood Phenology
class SoftwoodPhenologyForm: Plot10Form, PhenologyForm {
    required init(id: UUID, steward: String, date: Date, location: PlotLocation?, data: [D], selected: UUID?) {
        self.id = id
        self.steward = steward
        self.date = date
        self.location = location
        self.data = data
        self.selected = selected
    }
    
    init(steward: String, location: PlotLocation?, treeID: String) {
        self.steward = steward
        self.location = location
        self.treeID = treeID
    }
    
    static func == (lhs: SoftwoodPhenologyForm, rhs: SoftwoodPhenologyForm) -> Bool { lhs.id == rhs.id }
    
    var id: UUID = UUID()
    
    @Published var steward: String
    @Published var date: Date = Date()
    var location: PlotLocation?
    
    @Published var data: [PhenologyData] = [
        .init(title: "Breaking Needle Buds"),
        .init(title: "Young Needle"),
        .init(title: "Pollen Cones"),
        .init(title: "Pollen Release"),
        .init(title: "Unripe Seed Cone"),
        .init(title: "Ripe Seed Cone"),
        .init(title: "Recent Cone/Seed Drops")
    ]
    @Published var selected: UUID?
    
    @Published var treeID: String = ""
        
    struct PhenologyData: FormData {
        init() { self.id = UUID() }
        init(title: String) { self.title = title; self.id = UUID() }
        
        init?(_ values: [String]) {
            guard values.count == 3 else { return nil }
            self.id = UUID()
            
            self.title = values[0].emptyString()
            self.isOn = values[1] == "Present"
            self.note = values[2].emptyString()
        }
        
        let id: UUID
        var csvRow: String { "\(title.fillString()),\(isOn ? "Present" : "Absent"),\(note.fillString())" }
        
        var title: String = ""
        var isOn: Bool = false
        var note: String = ""
        
        var body: some View {
            HStack(spacing: 12) {
                Text(title.capitalized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                Text(isOn ? "Present" : "Absent")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText(note)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    @ViewBuilder var dataEditor: some View {
        if !data.isEmpty, let i = data.firstIndex(where: { $0.id == selected }) {
            let selectedData = Binding(get: {
                self.data[i]
            }, set: { value in
                self.data[i] = value
            })
            VStack(alignment: .leading, spacing: 16) {
                Text(selectedData.wrappedValue.title.capitalized)
                    .font(Font.custom("PlayfairDisplay-Bold", size: 22, relativeTo: .title3))
                Divider()
                DataEditorField(label: "STATUS") {
                    HStack {
                        Button("Absent") {
                            withAnimation(.bouncy(duration: 0.25, extraBounce: 0.12)) {
                                selectedData.wrappedValue.isOn = false
                            }
                        }
                        Toggle("", isOn: selectedData.isOn).toggleStyle(Checkmark(false))
                        Button("Present") {
                            withAnimation(.bouncy(duration: 0.25, extraBounce: 0.12)) {
                                selectedData.wrappedValue.isOn = true
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderless)
                .tint(.primary)
                DataEditorField(label: "NOTE") {
                    TextField("", text: selectedData.note)
                }
            }
        } else { ContentUnavailableView("Nothing Selected", systemImage: "square.dashed") }
    }
    
    @ViewBuilder var body: some View {
        FormHeader(title: "Softwood Phenology", form: .init(get: {
            self
        }, set: { plotForm in
            self.steward = plotForm.steward
            self.date = plotForm.date
        })) {
            Text("Remember to fill out the Tree ID field!")
        }
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        FormTreeIDEditor(form: .init(get: { self }, set: { self.treeID = $0.treeID }))
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 25) {
                Text("PHENOPHASE")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("STATUS")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("NOTE/INTENSITY")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(.white)
            .font(.headline)
            .padding(.leading, 72)
            .padding([.vertical, .trailing], 16)
            .background(.green2, in: RoundedCorner(radius: 16, corners: [.topRight, .topLeft]))
            let sections: [(String, ClosedRange<Int>)] = [("VEGETATIVE", 0...1), ("REPRODUCTIVE", 2...3), ("FRUIT/SEED", 4...6)]
            ForEach(sections, id: \.0) { section in
                HStack(spacing: 0) {
                    Text(section.0.uppercased())
                        .foregroundStyle(.secondary)
                        .frame(width: 400)
                        .rotationEffect(.degrees(-90))
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 24)
                        .frame(maxHeight: .infinity)
                        .padding(16)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedCorner(radius: 16, corners: section.0 == "FRUIT/SEED" ? .bottomLeft : []))
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(self.data[section.1], id: \.id) { data in
                            Button {
                                withAnimation(.snappy) {
                                    self.selected = data.id
                                }
                            } label: {
                                data.padding(16)
                            }
                            if data.id != (self.data[section.1].map(\.id).last) {
                                Divider()
                            }
                        }
                    }
                }
                if section.0 != "FRUIT/SEED" {
                    Rectangle().fill(.green2)
                        .frame(height: 1)
                }
            }
        }
        .buttonStyle(ListRow())
        .background {
            RoundedRectangle(cornerRadius: 16, style: .circular)
                .fill(Color(.secondarySystemGroupedBackground))
            RoundedRectangle(cornerRadius: 16, style: .circular)
                .stroke(Color(.systemFill))
                .padding(.horizontal, 0.5)
        }
        .padding(.horizontal, 24)
    }
}

//MARK: Invasive Species
class InvasiveSpeciesForm: Plot10Form {
    required init(id: UUID, steward: String, date: Date, location: PlotLocation?, data: [D], selected: UUID?) {
        self.id = id
        self.steward = steward
        self.date = date
        self.location = location
        self.data = data
        self.selected = selected
    }
    
    init(steward: String, location: PlotLocation?, data: [D] = []) {
        self.steward = steward
        self.location = location
        self.data = data
    }
    
    static func == (lhs: InvasiveSpeciesForm, rhs: InvasiveSpeciesForm) -> Bool { lhs.id == rhs.id }
    
    var id: UUID = UUID()
    
    @Published var steward: String
    @Published var date: Date = Date()
    var location: PlotLocation?
    @Published var data: [InvasiveSpeciesData]
    @Published var selected: UUID?
    
    struct InvasiveSpeciesData: FormData {
        init() { self.id = UUID() }
        init(species: String, direction: Double, distance: Double, heightClass: Int, area: Double) {
            self.id = UUID()
            self.species = species
            self.direction = direction
            self.distance = distance
            self.heightClass = heightClass
            self.area = area
        }
        
        init?(_ values: [String]) {
            guard values.count == 5 else { return nil }
            self.id = UUID()
            
            self.species = values[0]
            
            guard let direction = Double(values[1]), let distance = Double(values[2]), let heightClass = Int(values[3]), let area = Double(values[4]) else { return nil }
            
            self.direction = direction
            self.distance = distance
            self.heightClass = heightClass
            self.area = area
        }
        
        let id: UUID
        var csvRow: String { "\(species),\(direction),\(distance),\(heightClass),\(area)" }
        
        var species: String = ""
        var direction: Double = 0
        var distance: Double = 0
        var heightClass: Int = 1
        var area: Double = 0
        
        var body: some View {
            HStack(spacing: 12) {
                RedundantText(species)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText("\(String(format: "%.\(Double(Int(direction)) == direction ? 0 : 2)f", direction))", suffix: "º")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText("\(String(format: "%.\(Double(Int(distance)) == distance ? 0 : 2)f", distance))", suffix: "ft")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText("Class \(heightClass)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText("\(String(format: "%.\(Double(Int(area)) == area ? 0 : 2)f", area))", suffix: "sqft")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .lineLimit(1)
        }
    }
    
    @ViewBuilder var dataEditor: some View {
        if !data.isEmpty, let i = data.firstIndex(where: { $0.id == selected }) {
            let selectedData = Binding(get: {
                self.data[i]
            }, set: { value in
                self.data[i] = value
            })
            VStack(alignment: .leading, spacing: 16) {
                DataEditorField(label: "SPECIES") {
                    TextField("", text: selectedData.species)
                }
                DataEditorField(label: "DIRECTION FROM NORTH (DEGREES)") {
                    DoubleField("", value: selectedData.direction, in: 0...360)
                }
                DataEditorField(label: "DISTANCE FROM PLOT CENTER (FEET)") {
                    DoubleField("", value: selectedData.distance)
                }
                DataEditorField(label: "HEIGHT CLASS") {
                    Picker("", selection: selectedData.heightClass) {
                        ForEach(1...4, id: \.self) { i in Text("Class \(i)").tag(i) }
                    }
                }
                DataEditorField(label: "ESTIMATED AREA (SQFT)") {
                    DoubleField("", value: selectedData.area)
                }
                Rectangle()
                    .fill(Color(.secondarySystemFill))
                    .frame(height: 1)
                Text("""
**Class 1:** Under 2 feet
**Class 2:** 2 ft to 4.5 ft
**Class 3:** Over 4.5 feet
**Class 4:** Climbing vine
""")
                    .font(Font.custom("AvenirLTStd-Roman", size: 14, relativeTo: .caption).italic())
                    .lineSpacing(2.5)
            }
        } else { ContentUnavailableView("Nothing Selected", systemImage: "square.dashed") }
    }
    
    @ViewBuilder var body: some View {
        FormHeader(title: "Invasive Species", form: .init(get: {
            self
        }, set: { plotForm in
            self.steward = plotForm.steward
            self.date = plotForm.date
        })) {
            Text("""
**Class 1:** Under 2 feet
**Class 2:** 2 ft to 4.5 ft
**Class 3:** Over 4.5 feet
**Class 4:** Climbing vine
""")
        }
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        HStack(alignment: .top, spacing: 25) {
            Text("SPECIES")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("DIRECTION FROM NORTH")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("DISTANCE")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("HEIGHT CLASS")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("ESTIMATED AREA")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
        .font(.headline)
        .padding(16)
        .background(.green2, in: RoundedCorner(radius: 16, corners: [.topRight, .topLeft]))
        .padding(.horizontal, 24)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(data) { data in
                Button {
                    withAnimation(.snappy) {
                        self.selected = data.id
                    }
                } label: {
                    data.padding(16)
                }
                if data.id != self.data.last?.id {
                    Divider()
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
        .padding(.horizontal, 24)
    }
}

//MARK: Tree Health
class TreeHealthForm: Plot10Form {
    required init(id: UUID, steward: String, date: Date, location: PlotLocation?, data: [D], selected: UUID?) {
        self.id = id
        self.steward = steward
        self.date = date
        self.location = location
        self.data = data
        self.selected = selected
    }
    
    init(steward: String, location: PlotLocation?, data: [D] = []) {
        self.steward = steward
        self.location = location
        self.data = data
    }
    
    static func == (lhs: TreeHealthForm, rhs: TreeHealthForm) -> Bool { lhs.id == rhs.id }
    
    var id: UUID = UUID()
    
    @Published var steward: String
    @Published var date: Date = Date()
    var location: PlotLocation?
    
    @Published var data: [TreeHealthData]
    @Published var selected: UUID?
    
    struct TreeHealthData: FormData {
        init() { self.id = UUID() }
        init(treeID: String, treeSpecies: String, crownDamageType: CrownDamageType, crownDamagePercent: Int, boleDamageType: BoleDamageType, boleDamagePercent: Int) {
            self.id = UUID()
            self.treeID = treeID
            self.treeSpecies = treeSpecies
            self.crownDamageType = crownDamageType
            self.crownDamagePercent = crownDamagePercent
            self.boleDamageType = boleDamageType
            self.boleDamagePercent = boleDamagePercent
            
        }
        
        init?(_ values: [String]) {
            guard values.count == 6 else { return nil }
            self.id = UUID()
            
            self.treeID = values[0].emptyString()
            self.treeSpecies = values[1].emptyString()
            
            guard let crownDamageType = CrownDamageType(rawValue: values[2].lowercased()), let boleDamageType = BoleDamageType(rawValue: values[4].lowercased()) else { return nil }
            
            self.crownDamageType = crownDamageType
            self.boleDamageType = boleDamageType
            
            switch values[3] {
            case "0% - 25%": self.crownDamagePercent = 0
            case "26% - 50%": self.crownDamagePercent = 1
            case "51% - 75%": self.crownDamagePercent = 2
            case "76% - 100%": self.crownDamagePercent = 1
            default: return nil
            }
                        
            switch values[5] {
            case "0% - 25%": self.boleDamagePercent = 0
            case "26% - 50%": self.boleDamagePercent = 1
            case "51% - 75%": self.boleDamagePercent = 2
            case "76% - 100%": self.boleDamagePercent = 1
            default: return nil
            }
        }
        
        let id: UUID
        var csvRow: String { "\(treeID.fillString()),\(treeSpecies.fillString()),\(crownDamageType.rawValue.capitalized),\("\(((crownDamagePercent)*25+min((crownDamagePercent), 1)))% - \((crownDamagePercent)*25+25)%"),\(boleDamageType.rawValue.capitalized),\("\(((boleDamagePercent)*25+min((boleDamagePercent), 1)))% - \((boleDamagePercent)*25+25)%")" }
        
        var treeID: String = ""
        var treeSpecies: String = ""
        
        enum CrownDamageType: String, CaseIterable { case none, branches, foliage, both }
        var crownDamageType: CrownDamageType = .none
        var crownDamagePercent: Int = 1
        
        enum BoleDamageType: String, CaseIterable { case none, insect, disease, mechanical, weather, all, other }
        var boleDamageType: BoleDamageType = .none
        var boleDamagePercent: Int = 1
        
        var body: some View {
            HStack(spacing: 12) {
                RedundantText(treeID)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText(treeSpecies)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText(crownDamageType.rawValue.capitalized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                Text("\(((crownDamagePercent-1)*25+min((crownDamagePercent-1), 1)))% - \((crownDamagePercent-1)*25+25)%")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText(boleDamageType.rawValue.capitalized)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                Text("\(((boleDamagePercent-1)*25+min((boleDamagePercent-1), 1)))% - \((boleDamagePercent-1)*25+25)%")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .lineLimit(1)
        }
    }
    
    @ViewBuilder var dataEditor: some View {
        if !data.isEmpty, let i = data.firstIndex(where: { $0.id == selected }) {
            let selectedData = Binding(get: {
                self.data[i]
            }, set: { value in
                self.data[i] = value
            })
            VStack(alignment: .leading, spacing: 16) {
                DataEditorField(label: "TREE ID") {
                    TextField("", text: selectedData.treeID)
                }
                DataEditorField(label: "SPECIES") {
                    TextField("", text: selectedData.treeSpecies)
                }
                DataEditorField(label: "CROWN DAMAGE TYPE") {
                    Picker("", selection: selectedData.crownDamageType) {
                        ForEach(TreeHealthData.CrownDamageType.allCases, id: \.self) { cdt in
                            Text(cdt.rawValue.capitalized).tag(cdt)
                        }
                    }
                }
                DataEditorField(label: "CROWN DAMAGE (PERCENT)") {
                    Picker("", selection: selectedData.crownDamagePercent) {
                        ForEach(0...3, id: \.self) { i in
                            Text("\((i*25+min(i, 1)))% - \(i*25+25)%").tag(i+1)
                        }
                    }
                }
                DataEditorField(label: "BOLE DAMAGE TYPE") {
                    Picker("", selection: selectedData.boleDamageType) {
                        ForEach(TreeHealthData.BoleDamageType.allCases, id: \.self) { cdt in
                            Text(cdt.rawValue.capitalized).tag(cdt)
                        }
                    }
                }
                DataEditorField(label: "BOLE DAMAGE (PERCENT)") {
                    Picker("", selection: selectedData.boleDamagePercent) {
                        ForEach(0...3, id: \.self) { i in
                            Text("\((i*25+min(i, 1)))% - \(i*25+25)%").tag(i+1)
                        }
                    }
                }
            }
        } else { ContentUnavailableView("Nothing Selected", systemImage: "square.dashed") }
    }
    
    @ViewBuilder var body: some View {
        FormHeader(title: "Forest Health", form: .init(get: {
            self
        }, set: { plotForm in
            self.steward = plotForm.steward
            self.date = plotForm.date
        }))
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        HStack(alignment: .top, spacing: 25) {
            Text("TREE ID")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("SPECIES")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("CROWN DAMAGE TYPE")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("CROWN DAMAGE %")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("BOLE DAMAGE TYPE")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("BOLE DAMAGE %")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
        .font(.headline)
        .padding(16)
        .background(.green2, in: RoundedCorner(radius: 16, corners: [.topRight, .topLeft]))
        .padding(.horizontal, 24)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(self.data) { data in
                Button {
                    withAnimation(.snappy) {
                        self.selected = data.id
                    }
                } label: {
                    data.padding(16)
                }
                if data.id != self.data.last?.id {
                    Divider()
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
        .padding(.horizontal, 24)
    }
}

//MARK: Saplings
class SaplingsForm: Plot50Form {
    required init(id: UUID, steward: String, date: Date, location: PlotLocation?, data: [D], selected: UUID?) {
        self.id = id
        self.steward = steward
        self.date = date
        self.location = location
        self.data = data
        self.selected = selected
    }
    
    init(steward: String, location: PlotLocation?, data: [D] = []) {
        self.steward = steward
        self.location = location
        self.data = data
    }
    
    static func == (lhs: SaplingsForm, rhs: SaplingsForm) -> Bool { lhs.id == rhs.id }
    
    var id: UUID = UUID()
    
    @Published var steward: String
    @Published var date: Date = Date()
    var location: PlotLocation?
    
    @Published var data: [SaplingsData]
    @Published var selected: UUID?
    
    struct DiameterClass: Identifiable, Hashable {
        let id: UUID = UUID()
        
        var className: Int
        var value: Int
    }
    
    struct SaplingsData: FormData {
        init() { self.id = UUID() }
        init(treeSpecies: String) {
            self.id = UUID()
            self.treeSpecies = treeSpecies
        }
        
        init?(_ values: [String]) {
            guard values.count == 5 else { return nil }
            self.id = UUID()
            
            self.treeSpecies = values[0].emptyString()
            self.diameterClasses = zip(Array(1...4), values[1...]).map { DiameterClass(className: $0, value: Int($1) ?? 0) }
        }
        
        let id: UUID
        var csvRow: String { "\(treeSpecies.fillString()),\(diameterClasses.map(\.value.description).joined(separator: ","))" }
        
        var treeSpecies: String = ""
        var diameterClasses: [DiameterClass] = [
            .init(className: 1, value: 0),
            .init(className: 2, value: 0),
            .init(className: 3, value: 0),
            .init(className: 4, value: 0)
        ]
        
        var body: some View {
            HStack(spacing: 12) {
                RedundantText(treeSpecies)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                HStack(spacing: 12) {
                    ForEach(diameterClasses) { i in
                        RedundantText("\(i.value)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if i.className != 4 {
                            Divider()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .lineLimit(1)
        }
    }
    
    @ViewBuilder var dataEditor: some View {
        if !data.isEmpty, let i = data.firstIndex(where: { $0.id == selected }) {
            let selectedData = Binding(get: {
                self.data[i]
            }, set: { value in
                self.data[i] = value
            })
            VStack(alignment: .leading, spacing: 16) {
                DataEditorField(label: "TREE SPECIES") {
                    TextField("", text: selectedData.treeSpecies)
                }
                ForEach(selectedData.diameterClasses) { dc in
                    DataEditorField(label: "CLASS \(dc.className.wrappedValue)") {
                        IntField("", value: dc.value)
                    }
                }
                Rectangle()
                    .fill(Color(.secondarySystemFill))
                    .frame(height: 1)
                Text("""
                **Class 1:** 1 inches to 1.9 inches
                **Class 2:** 2 inches to  2.9 inches
                **Class 3:** 3 inches to 3.9 inches
                **Class 4:** 4 inches to 4.9 inches
                """)
                    .font(Font.custom("AvenirLTStd-Roman", size: 14, relativeTo: .caption).italic())
                    .lineSpacing(2.5)
            }
        } else { ContentUnavailableView("Nothing Selected", systemImage: "square.dashed") }
    }
    
    @ViewBuilder var body: some View {
        FormHeader(title: "Saplings", form: .init(get: {
            self
        }, set: { plotForm in
            self.steward = plotForm.steward
            self.date = plotForm.date
        })) {
            Text("""
            **Class 1:** 1 inches to 1.9 inches
            **Class 2:** 2 inches to  2.9 inches
            **Class 3:** 3 inches to 3.9 inches
            **Class 4:** 4 inches to 4.9 inches
            """)
        }
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        HStack(alignment: .top, spacing: 25) {
            Text("SPECIES")
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 25) {
                ForEach(1...4, id: \.self) { i in
                    Text("CLASS \(i)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
        .font(.headline)
        .padding(16)
        .background(.green2, in: RoundedCorner(radius: 16, corners: [.topRight, .topLeft]))
        .padding(.horizontal, 24)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(self.data) { data in
                Button {
                    withAnimation(.snappy) {
                        self.selected = data.id
                    }
                } label: {
                    data.padding(16)
                }
                if data.id != self.data.last?.id {
                    Divider()
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
        .padding(.horizontal, 24)
    }
}

//MARK: Seedlings
class SeedlingsForm: Plot1000Form {
    required init(id: UUID, steward: String, date: Date, location: PlotLocation?, data: [D], selected: UUID?) {
        self.id = id
        self.steward = steward
        self.date = date
        self.location = location
        self.data = data
        self.selected = selected
    }
    
    init(steward: String, location: PlotLocation?, data: [D] = []) {
        self.steward = steward
        self.location = location
        self.data = data
    }
    
    static func == (lhs: SeedlingsForm, rhs: SeedlingsForm) -> Bool { lhs.id == rhs.id }
    
    var id: UUID = UUID()
    
    @Published var steward: String
    @Published var date: Date = Date()
    var location: PlotLocation?
    
    @Published var data: [SeedlingsData] = []
    @Published var selected: UUID?
    
    struct DiameterClass: Identifiable, Hashable {
        let id: UUID = UUID()
        
        var className: Int
        var value: Int
    }
    
    struct SeedlingsData: FormData {
        init() { self.id = UUID() }
        init(direction: Direction, treeSpecies: String) {
            self.id = UUID()
            self.direction = direction
            self.treeSpecies = treeSpecies
        }
        
        init?(_ values: [String]) {
            guard values.count == 5 else { return nil }
            self.id = UUID()
            
            self.treeSpecies = values[0].emptyString()
            self.diameterClasses = zip(Array(1...4), values[1...]).map { DiameterClass(className: $0, value: Int($1) ?? 0) }
        }
        
        let id: UUID
        var csvRow: String { "\(treeSpecies.fillString()),\(diameterClasses.map(\.value.description).joined(separator: ","))" }

        enum Direction: String, CaseIterable { case north, east, south, west }
        var direction: Direction = .north
        
        var treeSpecies: String = ""
        var diameterClasses: [DiameterClass] = [
            .init(className: 1, value: 0),
            .init(className: 2, value: 0),
            .init(className: 3, value: 0),
            .init(className: 4, value: 0)
        ]
        
        var body: some View {
            HStack(spacing: 12) {
                RedundantText(treeSpecies)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                HStack(spacing: 12) {
                    ForEach(diameterClasses) { i in
                        RedundantText("\(i.value)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if i.className != 4 {
                            Divider()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .lineLimit(1)
        }
    }
    
    @ViewBuilder var dataEditor: some View {
        if !data.isEmpty, let i = data.firstIndex(where: { $0.id == selected }) {
            let selectedData = Binding(get: {
                self.data[i]
            }, set: { value in
                self.data[i] = value
            })
            VStack(alignment: .leading, spacing: 16) {
                DataEditorField(label: "PLOT") {
                    Picker("", selection: selectedData.direction) {
                        ForEach(SeedlingsData.Direction.allCases, id: \.self) { direction in
                            Text(direction.rawValue.capitalized).tag(direction)
                        }
                    }
                }
                DataEditorField(label: "TREE SPECIES") {
                    TextField("", text: selectedData.treeSpecies)
                }
                ForEach(selectedData.diameterClasses) { dc in
                    DataEditorField(label: "CLASS \(dc.className.wrappedValue)") {
                        IntField("", value: dc.value)
                    }
                }
                Rectangle()
                    .fill(Color(.secondarySystemFill))
                    .frame(height: 1)
                Text("""
                **Class 1:** 6 inches to 11.9 inches Softwood Only
                **Class 2:** 12 inches to 23.9 inches
                **Class 3:** 24 inches to 53.9 inches
                **Class 4:** 54+ inches; less than 1-inch DBH
                """)
                .font(Font.custom("AvenirLTStd-Roman", size: 14, relativeTo: .caption).italic())
                .lineSpacing(2.5)
            }
        } else { ContentUnavailableView("Nothing Selected", systemImage: "square.dashed") }
    }
    
    func directionSection(_ dir: SeedlingsData.Direction) -> some View {
        if !self.data.filter({ $0.direction == dir }).isEmpty {
            return AnyView(
                VStack(spacing: 0) {
                    HStack(spacing: 1) {
                        Text(dir.rawValue.prefix(1).uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 43)
                            .frame(maxHeight: .infinity)
                            .padding(16)
                            .background(.green3, in: RoundedCorner(radius: 16, corners: dir == SeedlingsData.Direction.allCases.filter({ self.data.map(\.direction).contains($0) }).last ? .bottomLeft : []))
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(self.data.filter({ $0.direction == dir })) { data in
                                Button {
                                    withAnimation(.snappy) {
                                        self.selected = data.id
                                    }
                                } label: {
                                    data.padding(16)
                                }
                                if data.id != self.data.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .buttonStyle(ListRow())
                    }
                    if dir != SeedlingsData.Direction.allCases.filter({ self.data.map(\.direction).contains($0) }).last {
                        Rectangle()
                            .fill(.green2)
                            .frame(height: 1)
                    }
                })
        } else {
            return AnyView(EmptyView())
        }
    }
    
    @ViewBuilder var body: some View {
        FormHeader(title: "Seedlings", form: .init(get: {
            self
        }, set: { plotForm in
            self.steward = plotForm.steward
            self.date = plotForm.date
        })) {
            Text("""
**Class 1:** 6 inches to 11.9 inches Softwood Only
**Class 2:** 12 inches to 23.9 inches
**Class 3:** 24 inches to 53.9 inches
**Class 4:** 54+ inches; less than 1-inch DBH
""")
        }
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        HStack(alignment: .top, spacing: 25) {
            Text("PLOT")
            Text("SPECIES")
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 25) {
                ForEach(1...4, id: \.self) { i in
                    Text("CLASS \(i)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
        .font(.headline)
        .padding(16)
        .background(.green2, in: RoundedCorner(radius: 16, corners: [.topRight, .topLeft]))
        .padding(.horizontal, 24)
        VStack(alignment: .leading, spacing: 0) {
            self.directionSection(.north)
            self.directionSection(.east)
            self.directionSection(.south)
            self.directionSection(.west)
        }
        .background {
            RoundedCorner(radius: 16, corners: [.bottomLeft, .bottomRight])
                .fill(Color(.secondarySystemGroupedBackground))
            RoundedCorner(radius: 16, corners: [.bottomLeft, .bottomRight])
                .stroke(Color(.systemFill))
                .padding(0.5)
        }
        .padding(.horizontal, 24)
    }
}

//MARK: Debris
class DebrisForm: TransectLineForm {
    required init(id: UUID, steward: String, date: Date, location: PlotLocation?, data: [D], selected: UUID?) {
        self.id = id
        self.steward = steward
        self.date = date
        self.location = location
        self.data = data
        self.selected = selected
    }
    
    init(steward: String, location: PlotLocation?, data: [D] = []) {
        self.steward = steward
        self.location = location
        self.data = data
    }
    
    static func == (lhs: DebrisForm, rhs: DebrisForm) -> Bool { lhs.id == rhs.id }
    
    var id: UUID = UUID()
    
    @Published var steward: String
    @Published var date: Date = Date()
    var location: PlotLocation?
    
    @Published var data: [DebrisData] = []
    @Published var selected: UUID?
    
    struct DebrisData: FormData {
        init() { self.id = UUID() }
        init(transect: Int, diameter: Double, decayClass: Int, species: String) {
            self.id = UUID()
            self.transect = transect
            self.diameter = diameter
            self.decayClass = decayClass
            self.species = species
        }
        
        init?(_ values: [String]) {
            guard values.count == 4 else { return nil }
            self.id = UUID()
            
            guard let transect = Int(values[0]), let diameter = Double(values[1]), let decayClass = Int(values[2]) else { return nil }
            
            self.transect = transect
            self.diameter = diameter
            self.decayClass = decayClass
            
            self.species = values[3].fillString()
        }
        
        let id: UUID
        var csvRow: String { "\(transect),\(diameter),\(decayClass),\(species.emptyString())" }
        
        var transect: Int = 0
        var diameter: Double = 0
        var decayClass: Int = 1
        var species: String = ""
        
        var body: some View {
            HStack(spacing: 12) {
                RedundantText("\(transect)º")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText("\(String(format: "%.\(Double(Int(diameter)) == diameter ? 0 : 2)f", diameter))", suffix: "in")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText("\(decayClass)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                RedundantText(species)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .lineLimit(1)
        }
    }
    
    @ViewBuilder var dataEditor: some View {
        if !data.isEmpty, let i = data.firstIndex(where: { $0.id == selected }) {
            let selectedData = Binding(get: {
                self.data[i]
            }, set: { value in
                self.data[i] = value
            })
            VStack(alignment: .leading, spacing: 16) {
                DataEditorField(label: "TRANSECT LINE") {
                    Picker("", selection: selectedData.transect) {
                        ForEach(0...2, id: \.self) { direction in
                            Text("\(direction * 120)").tag(direction * 120)
                        }
                    }
                }
                DataEditorField(label: "DIAMETER (INCHES)") {
                    DoubleField("", value: selectedData.diameter)
                }
                DataEditorField(label: "DECAY CLASS") {
                    Picker("", selection: selectedData.decayClass) {
                        ForEach(1...5, id: \.self) { dc in
                            Text("\(dc)").tag(dc)
                        }
                    }
                }
                DataEditorField(label: "SPECIES (IF POSSIBLE)") {
                    TextField("", text: selectedData.species)
                }
                Rectangle()
                    .fill(Color(.secondarySystemFill))
                    .frame(height: 1)
                Text("""
**Class 1:** Structure = sound; Bark = intact; Twigs & Branches = fine twigs present

**Class 2:** Structure = outer sapwood soft; Bark = mostly intact; Twigs & Branches = large twigs present

**Class 3:** Structure = heartwood mostly sound; Bark = falling off or absent; Twigs & Branches = branches present

**Class 4:** Structure = heartwood rotten; Bark = detached or absent; Twigs & Branches = branch stubs easily fall off

**Class 5:** Structure = completely rotten; Bark = detached or absent; Twigs & Branches = mostly absent
""")
                    .font(Font.custom("AvenirLTStd-Roman", size: 14, relativeTo: .caption).italic())
                    .lineSpacing(2.5)
            }
        } else { ContentUnavailableView("Nothing Selected", systemImage: "square.dashed") }
    }
    
    @ViewBuilder var body: some View {
        FormHeader(title: "Coarse Woody Debris", form: .init(get: {
            self
        }, set: { plotForm in
            self.steward = plotForm.steward
            self.date = plotForm.date
        })) {
            Text("""
**Class 1:** Structure = sound; Bark = intact; Twigs & Branches = fine twigs present

**Class 2:** Structure = outer sapwood soft; Bark = mostly intact; Twigs & Branches = large twigs present

**Class 3:** Structure = heartwood mostly sound; Bark = falling off or absent; Twigs & Branches = branches present

**Class 4:** Structure = heartwood rotten; Bark = detached or absent; Twigs & Branches = branch stubs easily fall off

**Class 5:** Structure = completely rotten; Bark = detached or absent; Twigs & Branches = mostly absent
""")
        }
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        HStack(alignment: .top, spacing: 25) {
            Text("TRANSECT LINE")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("DIAMETER")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("DECAY CLASS")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("SPECIES")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
        .font(.headline)
        .padding(16)
        .background(.green2, in: RoundedCorner(radius: 16, corners: [.topRight, .topLeft]))
        .padding(.horizontal, 24)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(self.data) { data in
                Button {
                    withAnimation(.snappy) {
                        self.selected = data.id
                    }
                } label: {
                    data.padding(16)
                }
                if data.id != self.data.last?.id {
                    Divider()
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
        .padding(.horizontal, 24)
    }
}

/*
//MARK: Traim Camera
class TrailCameraForm: Plot10Form {
    required init(id: UUID, steward: String, date: Date, location: PlotLocation?, data: [D], selected: UUID?) {
        self.id = id
        self.steward = steward
        self.date = date
        self.location = location
        self.data = data
        self.selected = selected
    }
    
    init(steward: String, location: PlotLocation?, data: [D] = []) {
        self.steward = steward
        self.location = location
        self.data = data
    }
    
    static func == (lhs: TrailCameraForm, rhs: TrailCameraForm) -> Bool { lhs.id == rhs.id }
    
    var id: UUID = UUID()
    
    @Published var steward: String
    @Published var date: Date = Date()
    var location: PlotLocation?
    
    @Published var data: [TrailCameraData] = []
    @Published var selected: UUID?
    
    @State private var importing: Bool = false
    
    struct TrailCameraData: FormData {
        init() { self.id = UUID() }
        init(imageUrl: URL?, date: Date = Date(), wildlife: String) {
            self.id = UUID()
            self.imageUrl = imageUrl
            self.date = date
            self.wildlife = wildlife
        }
        
        let id: UUID
        
        var imageUrl: URL? = nil
        var date: Date = Date()
        var wildlife: String = ""
        
        var body: some View {
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    if let imageUrl = imageUrl, let data = try? Data(contentsOf: imageUrl), let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
                    } else {
                        Image(systemName: "questionmark")
                            .bold()
                            .imageScale(.small)
                            .foregroundStyle(Color(.secondarySystemGroupedBackground))
                            .frame(width: 24, height: 24)
                            .background(.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
                    }
                    RedundantText(imageUrl?.pathComponents.last! ?? "")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                    .padding(.vertical, 1.5)
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                    .padding(.vertical, 1.5)
                Text(date.formatted(date: .omitted, time: .shortened))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                    .padding(.vertical, 1.5)
                RedundantText(wildlife)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .lineLimit(1)
        }
    }
    
    @ViewBuilder var dataEditor: some View {
        if !data.isEmpty, let i = data.firstIndex(where: { $0.id == selected }) {
            let _selectedData = Binding(get: {
                self.data[i]
            }, set: { value in
                self.data[i] = value
            })
            var selectedData = self.data[i]
            Form {
                Section("IMAGE") {
                    Button("Choose Image") { self.importing = true }
                        .fileImporter(isPresented: $importing, allowedContentTypes: [.image], allowsMultipleSelection: false, onCompletion: { result in
                            switch result {
                            case .success(let success):
                                if let url = success.first {
                                    selectedData.imageUrl = url
                                    print(url, selectedData.imageUrl?.absoluteString ?? "nil")
                                } else {
                                    print("None selcted")
                                }
                            case .failure(let failure):
                                print(failure)
                            }
                        }, onCancellation: {
                            print("Cancelled")
                        })
                    if let imageUrl = selectedData.imageUrl {
                        Text(imageUrl.absoluteString)
                    }
                }
                HStack {
                    Text("DATE")
                        .bold().foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("Date", selection: _selectedData.date, displayedComponents: .date)
                        .tint(.primary)
                }
                HStack {
                    Text("TIME")
                        .bold().foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("Date", selection: _selectedData.date, displayedComponents: .hourAndMinute)
                        .tint(.primary)
                }
                HStack {
                    Text("WILDLIFE")
                        .bold().foregroundStyle(.secondary)
                    TextField("Wildlife", text: _selectedData.wildlife)
                }
            }
            .datePickerStyle(Inline(icon: false))
            .multilineTextAlignment(.trailing)
            .scrollBounceBehavior(.basedOnSize)
        } else { ContentUnavailableView("Nothing Selected", systemImage: "square.dashed") }
    }
    
    @ViewBuilder var body: some View {
        FormHeader(title: "Trail Camera", form: .init(get: {
            self
        }, set: { plotForm in
            self.steward = plotForm.steward
            self.date = plotForm.date
        }))
        .padding(.bottom, 24)
        .padding(.horizontal, 24)
        HStack(alignment: .top, spacing: 25) {
            Text("IMAGE")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("DATE")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("TIME")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("WILDLIFE")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
        .font(.headline)
        .padding(16)
        .background(.green2, in: RoundedCorner(radius: 16, corners: [.topRight, .topLeft]))
        .padding(.horizontal, 24)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(self.data) { data in
                Button {
                    withAnimation(.snappy) {
                        self.selected = data.id
                    }
                } label: {
                    data.padding(13)
                }
                if data.id != self.data.last?.id {
                    Divider()
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
        .padding(.horizontal, 24)
    }
}
*/
