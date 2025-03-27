//
//  FERN_iOSApp.swift
//  FERN iOS
//
//  Created by ctstudent18 on 2/5/25.
//

import SwiftUI
import MapKit
import CoreLocation
import SwiftData

@main
struct FERN_iOSApp: App {
    @Environment(\.modelContext) private var context
    @Query var plots: [PlotWrapper]
    
    @StateObject var appValues = AppValues()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                NavigationStack {
                    if appValues.appStatus == nil {
                        if let selectedPlot = appValues.selectedPlot {
                            PlotView(plot: Plot(plots.first(where: { $0.id == selectedPlot })!)!)
                        }
                    } else {
                        LandingPage()
                    }
                }
                if appValues.appStatus == "loading" {
                    Rectangle()
                        .fill(Color.black.opacity(0.25))
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("In Progress")
                            .font(.headline.bold())
                    }
                    .frame(width: 270, height: 130)
                    .background(Material.regular.secondary, in: RoundedRectangle(cornerRadius: 16, style: .circular))
                }
            }
            .environmentObject(appValues)
            .onChange(of: plots) { oldValue, newValue in
                print("P")
//                for plot in oldValue {
//                    context.delete(plot.plotWrapper)
//                }
//                for plot in newValue {
//                    context.insert(PlotWrapper(info: plot.info, forms: plot.forms.map(\.formWrapper)))
//                }
//                do {
//                    try context.save()
//                } catch {
//                    print("NO")
//                }
            }
            .task {
                appValues.plots = plots.map({ Plot.init($0)! })
            }
        }
        .modelContainer(for: PlotWrapper.self)
    }
}

//@Model
class AppValues: ObservableObject, Codable {
    init(_ plots: [Plot] = []) { self.plots = plots }
    
    required convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: AppValuesCodingKeys.self)
        let plots = try values.decode([Plot].self, forKey: .plots)
        self.init(plots)
    }
    
    @Published var plots: [Plot] = []
    
    /*@Transient*/ @Published var appStatus: String? = "welcome"
    /*@Transient*/ @Published var selectedPlot: UUID?
    /*@Transient*/ @Published var selectedPlotWrapper: Bindable<PlotWrapper>?

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: AppValuesCodingKeys.self)
        try container.encode(self.plots, forKey: .plots)
    }
}

/*
    let treeSpeciesList: [String] = [
        "Alternate Leaf Dogwood",
        "American Basswood",
        "American Beech",
        "American Chestnut",
        "American Elm",
        "American Hornbeam",
        "American Sycamore",
        "Atlantic White Cedar",
        "Balsam Fir",
        "Balsam Poplar",
        "Bear Oak",
        "Bigtooth Aspen",
        "Bitternut Hickory",
        "Black Ash",
        "Black Cherry",
        "Black Locust",
        "Black Oak",
        "Black Spruce",
        "Black Tupelo",
        "Black Walnut",
        "Black Willow",
        "Blue Spruce",
        "Boxelder",
        "Bur Oak",
        "Butternut",
        "Canada Plum",
        "Chestnut Oak",
        "Common Chokecherry",
        "Common Juniper",
        "Eastern Hemlock",
        "Eastern Hophornbeam",
        "Eastern Redcedar",
        "Eastern White Pine",
        "Flowering Dogwood",
        "Gray Birch",
        "Green Ash",
        "Hawthorn",
        "Honeylocust",
        "Horsechestnut",
        "Jack Pine",
        "Mountain Ash",
        "Mountain Laurel",
        "Mountain Maple",
        "Mountain Paper Birch",
        "Nannyberry",
        "Northern Red Oak",
        "Northern White Cedar",
        "Norway Maple",
        "Norway Spruce",
        "Paper Birch",
        "Pin Cherry",
        "Pitch Pine",
        "Quaking Aspen",
        "Red Maple",
        "Red Osier Dogwood",
        "Red Pine",
        "Red Spruce",
        "Rosebay Rhododendron",
        "Sassafras",
        "Scarlet Oak",
        "Scots Pine",
        "Serviceberry",
        "Shagbark Hickory",
        "Silver Maple",
        "Speckled Alder",
        "Staghorn Sumac",
        "Striped Maple",
        "Sugar Maple",
        "Swamp White Oak",
        "Sweet Birch",
        "Tamarack",
        "White Ash",
        "White Oak",
        "White Spruce",
        "Witch Hazel",
        "Yellow Birch"
    ]
*/

enum AppValuesCodingKeys: String, CodingKey {
    case plots
}

extension String: @retroactive Error { }

struct DefaultsKeys { static let plots: [Plot] = [] }

/*
struct TreeSpeciesMenu: View {
    @EnvironmentObject var appValues: AppValues
    
    @State var temp: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Search", text: $temp)
                .onSubmit {
                    temp = appValues.treeSpeciesList.filter({ temp.isEmpty || $0.lowercased().contains(temp.lowercased()) }).first ?? temp
                }
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(appValues.treeSpeciesList.filter({ temp.isEmpty || $0.lowercased().contains(temp.lowercased()) }), id: \.self) { i in
                        Button { temp = i } label: {
                            Text(i)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if i != appValues.treeSpeciesList.filter({ temp.isEmpty || $0.lowercased().contains(temp.lowercased()) }).last {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(16)
    }
}
 */

func addFeetToCoordinate(coord: CLLocationCoordinate2D, northFeet: Double, eastFeet: Double) -> CLLocationCoordinate2D {
    let feetPerDegreeLatitude = 364000.0
    let feetPerDegreeLongitude = feetPerDegreeLatitude * cos(coord.latitude * .pi / 180)

    let newLatitude = coord.latitude + (northFeet / feetPerDegreeLatitude)
    let newLongitude = coord.longitude + (eastFeet / feetPerDegreeLongitude)

    return CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
}

func feetToMeters(_ feet: Double) -> Double {
    return feet * 0.3048
}

func rotateCoordinate(around pivot: CLLocationCoordinate2D, point: CLLocationCoordinate2D, by angleDegrees: Double) -> CLLocationCoordinate2D {
    let angleRadians = angleDegrees * .pi / 180 // Convert degrees to radians
    
    // Convert latitude & longitude to radians
    let lat1 = pivot.latitude * .pi / 180
    let lon1 = pivot.longitude * .pi / 180
    let lat2 = point.latitude * .pi / 180
    let lon2 = point.longitude * .pi / 180

    // Compute differences
    let dLat = lat2 - lat1
    let dLon = lon2 - lon1

    // Convert to Cartesian coordinates
    let x = dLon * cos(lat1)
    let y = dLat

    // Rotate using 2D rotation matrix
    let newX = x * cos(angleRadians) - y * sin(angleRadians)
    let newY = x * sin(angleRadians) + y * cos(angleRadians)

    // Convert back to lat/lon
    let newLat = lat1 + newY
    let newLon = lon1 + (newX / cos(lat1))

    // Convert back to degrees
    return CLLocationCoordinate2D(latitude: newLat * 180 / .pi, longitude: newLon * 180 / .pi)
}

extension Double {
    func float(_ point: Int) -> Double { Double(String(format: "%.\(point)f", self))! }
}

struct RedundantText: View {
    init(_ text: String, or redundancy: String = "Empty", suffix: String = "") {
        self.text = text
        self.redundancy = redundancy
        self.suffix = suffix
    }
    
    var text: String
    var redundancy: String
    var suffix: String
    
    var body: some View {
        Text(text.isEmpty ? redundancy : "\(text)\(suffix.isEmpty ? "" : " \(suffix)")")
            .italic(text.isEmpty)
            .foregroundStyle(text.isEmpty ? .secondary : .primary)
    }
}

struct OptionalDoubleField: View {
    init(_ placeholder: String, value: Binding<Double?>, in range: ClosedRange<Double>? = nil, float: Int = 2) {
        self._placeholder = State(wrappedValue: placeholder)
        self._value = value
        self.range = range
        self.float = float
        self.temp = value.wrappedValue?.description ?? ""
    }
    
    @State var placeholder: String = ""
    @Binding var value: Double?
    var range: ClosedRange<Double>?
    var float = 2
    
    @State private var temp = ""
    
    var body: some View {
        TextField(placeholder, text: .init(get: {
            if let value = value {
                if Double(Int(value.float(float))) == value.float(float) {
                    return String(Int(value.float(float)))
                } else {
                    return String(String(String(format: "%.\(float)f", value).reversed().trimmingPrefix(while: { "\($0)" == "0"})).reversed())
                }
            } else {
                return "?"
            }
        }, set: { string in
            temp = string
            if string != "?" || ["", "-"].contains(string) {
                if let value = Double(string) {
                    if let range = range {
                        self.value = min(range.upperBound, max(range.lowerBound, value)).float(float)
                    } else {
                        self.value = value.float(float)
                    }
                } else if string == "-" {
                    self.value = -0
                }
            } else {
                self.value = nil
            }
        }))
        .keyboardType(.numberPad)
        .onSubmit {
            if temp == "" { self.value = nil }
        }
    }
}

struct DoubleField: View {
    init(_ placeholder: String, value: Binding<Double>, in range: ClosedRange<Double>? = nil, float: Int = 2, validation: @escaping (ValidationError?) -> Void = { _ in }) {
        self._placeholder = State(wrappedValue: placeholder)
        self._value = value
        self.range = range
        self.float = float
        
        self.validation = validation
        
        self._wrapped = State(initialValue: value.wrappedValue)
        self.numberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = float
            return formatter
        }()
    }
    
    @State var placeholder: String = ""
    @Binding var value: Double
    var range: ClosedRange<Double>?
    var float = 2
    
    enum ValidationError: String {
        case NaN, outOfRange, empty
    }
    let validation: (ValidationError?) -> Void
    
    @State private var wrapped: Double? = nil
    private let numberFormatter: NumberFormatter
    
    var body: some View {
        TextField(placeholder, value: Binding<Double?>.init(get: {
            value
        }, set: { v in
            wrapped = v
            validation(nil)
            if wrapped == nil { validation(.empty) }
            if let range = range { value = min(range.upperBound, max(range.lowerBound, v ?? 0.0)) } else { value = v ?? 0.0 }
        }), formatter: numberFormatter).keyboardType(.decimalPad)
    }
}

struct IntField: View {
    init(_ placeholder: String, value: Binding<Int>, in range: ClosedRange<Int>? = nil) {
        self._placeholder = State(wrappedValue: placeholder)
        self._value = value
        self.range = range
    }
    
    @State var placeholder: String = ""
    @Binding var value: Int
    var range: ClosedRange<Int>?
        
    var body: some View {
        TextField(placeholder, text: .init(get: {
            String(value)
        }, set: { string in
            if let value = Int(string) {
                if let range = range {
                    self.value = min(range.upperBound, max(range.lowerBound, value))
                } else {
                    self.value = value
                }
            }
        }))
        .keyboardType(.numberPad)
    }
}

struct RoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    init(radius: CGFloat = 16, corners: UIRectCorner = .allCorners) {
        self.radius = radius
        self.corners = corners
    }

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct CustomStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.body
            .textFieldStyle(.plain)
            .padding(8)
            .background(.inputBG, in: RoundedRectangle(cornerRadius: 4, style: .circular))
    }
}

struct Inline: DatePickerStyle {
    @State var isOpen: Bool = false
    var icon: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        Button {
            isOpen.toggle()
        } label: {
            Text(configuration.selection.formatted(date: configuration.displayedComponents.contains(.date) ? .abbreviated : .omitted, time: configuration.displayedComponents.contains(.hourAndMinute) ? .shortened : .omitted))
//                .font(Font.custom("AvenirLTStd-Roman", size: 16, relativeTo: .body))
//                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(.inputBG, in: RoundedRectangle(cornerRadius: 4, style: .circular))
        }
        .popover(isPresented: $isOpen) {
            if configuration.displayedComponents == .hourAndMinute {
                DatePicker(selection: configuration.$selection, displayedComponents: configuration.displayedComponents) {
                    EmptyView()
                }
                .datePickerStyle(.wheel)
                .frame(width: 320, alignment: .leading)
                .padding(.trailing, 16)
            } else {
                DatePicker(selection: configuration.$selection, displayedComponents: configuration.displayedComponents) {
                    EmptyView()
                }
                .datePickerStyle(.graphical)
                .frame(width: 420)
            }
        }
    }
}

struct ListRow: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.primary)
            .opacity(configuration.isPressed ? 0.4 : 1)
            .contentShape(Rectangle())
    }
}

extension String {
    func emptyString() -> String { self == "N/A" ? "" : self }
    func fillString() -> String { (self == "" ? "N/A" : self).replacingOccurrences(of: ",", with: "-") }
    
    func toDate(withFormat format: String = "dd_MM_yyyy")-> Date?{
        let dateFormatter = DateFormatter()
//        dateFormatter.timeZone = TimeZone(identifier: "en_US_POSIX")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)
        
        return date
    }
}

extension Date {
    func toString(withFormat format: String = "dd_MM_yyyy") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tehran")
//        dateFormatter.calendar = Calendar(identifier: .persian)
        dateFormatter.dateFormat = format
        let str = dateFormatter.string(from: self)
        return str
    }
}

struct DataEditorField<Content: View>: View {
    var label: String
    var required: Bool = true
    
    var condition: Bool?
    var message: String?
    
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(label.uppercased())\(required ? " *" : "")")
                .font(Font.custom("AvenirLTStd-Roman", size: 14, relativeTo: .caption).weight(.heavy))
            content
                .textFieldStyle(CustomStyle())
                .datePickerStyle(Inline())
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.inputBG, in: RoundedRectangle(cornerRadius: 4, style: .circular))
                .overlay {
                    if condition ?? false {
                        RoundedRectangle(cornerRadius: 8, style: .circular)
                            .stroke(.red, lineWidth: 2)
                            .padding(-4)
                    }
                }
            if condition ?? false, let message = message {
                Text(message)
                    .font(.caption2.bold())
            }
        }
        .foregroundStyle(.tint)
        .tint(condition ?? false ? .red : .cardText)
    }
}

func saveTextFile(at directory: URL, fileName: String, content: String) {
    let fileURL = directory.appendingPathComponent(fileName)
    try? content.write(to: fileURL, atomically: true, encoding: .utf8)
}

struct Checkmark: ToggleStyle {
    init(_ icon: Bool = true) { self.icon = icon }
    
    let icon: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        Button("") {
            withAnimation(.bouncy(duration: 0.25, extraBounce: 0.12)) {
                configuration.isOn.toggle()
            }
        }
        .buttonStyle(CheckmarkButton(icon: icon, isOn: configuration.$isOn))
    }
}

struct CheckmarkButton: ButtonStyle {
    let icon: Bool
    @Binding var isOn: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 6, style: .circular)
                .fill(isOn ? .brightGreen : Color(.systemFill))
                .frame(width: 52, height: 28)
            RoundedRectangle(cornerRadius: 3, style: .circular)
                .fill(.white)
                .frame(width: configuration.isPressed ? 25 : 22, height: 22)
                .padding(.horizontal, 3)
                .shadow(radius: 2)
            if icon {
                Image(systemName: isOn ? "checkmark" : "xmark")
                    .imageScale(.small)
                    .bold()
                    .frame(width: configuration.isPressed ? 33 : 22, height: 22)
                    .padding(.horizontal, 3)
                    .transition(.slide.animation(.easeInOut(duration: 0.25)))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CustomListButtonStyle: ButtonStyle {
    init(_ cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }
    let cornerRadius: CGFloat
    
    func makeBody(configuration: Configuration) -> some View {
        let color: Color? = {
            switch configuration.role {
            case .cancel: return .blue
            case .destructive: return .red
            default: return nil
            }
        }()
        if let color = color {
            configuration.label
                .padding(16)
                .background(color.opacity(configuration.isPressed ? 0.6 : 1), in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            configuration.label
                .padding(16)
                .background(.tint.opacity(configuration.isPressed ? 0.6 : 1), in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}
