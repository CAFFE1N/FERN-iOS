//
//  PlotWeb.swift
//  FERN iOS
//
//  Created by ctstudent18 on 3/11/25.
//

import SwiftUI

struct PlotSymbol: View {
    enum Components: String, CaseIterable {
        case _10, _50, _1000
        case _transects
    }
    @State var components: [Components] = Components.allCases
    @State var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(components.contains(._10) ? .lightGreen0 : .primary.opacity(0.2))
                .frame(width: 222.12*scale, height: 222.12*scale)
            Circle()
                .stroke(components.contains(._10) ? .lightGreen1 : .primary.opacity(0.2), lineWidth: 2)
                .frame(width: 222.12*scale, height: 222.12*scale)
            Circle()
                .fill(components.contains(._50) ? .peach0 : .primary.opacity(0.05))
                .frame(width: 99.9*scale, height: 99.9*scale)
            Circle()
                .stroke(components.contains(._50) ? .peach1 : .primary.opacity(0.2), style: .init(lineWidth: 2, lineCap: .round, dash: [5, 10]))
                .frame(width: 99.9*scale, height: 99.9*scale)
            ForEach(0...2, id: \.self) { i in
                Rectangle()
                    .fill(components.contains(._transects) ? .tumeric0 : .primary.opacity(0.2))
                    .frame(width: 2, height: 150*scale)
                    .rotationEffect(.degrees(Double(120*i)), anchor: .bottom)
                    .offset(y: -75*scale)
            }
            .zIndex(components.contains(._1000) ? 0 : 7)
            ForEach(0...3, id: \.self) { i in
                Circle()
                    .fill(components.contains(._1000) ? .skyBlue0 : .primary.opacity(0.2))
                    .frame(width: 22.32*scale, height: 22.32*scale)
                    .offset(y: -49.95*scale)
                    .rotationEffect(.degrees(Double(i*90)))
                Circle()
                    .stroke(components.contains(._1000) ? .skyBlue1 : .primary.opacity(0.2), lineWidth: 2)
                    .frame(width: 22.32*scale, height: 22.32*scale)
                    .offset(y: -49.95*scale)
                    .rotationEffect(.degrees(Double(i*90)))
            }
        }
        .frame(height: 260*scale, alignment: .bottom)
        .padding(.vertical, 24*scale)
    }
}

#Preview {
    PlotSymbol(scale: 1.5)
}

struct PlotDataWeb: View {
    @ObservedObject var plot: Plot
    
    struct Card10: View {
        @ObservedObject var plot: Plot
        
        var body: some View {
            VStack(spacing: 0) {
                Text("1/10")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.lightGreen1, in: RoundedCorner(radius: 16, corners: [.topLeft, .topRight]))
                NavigationLink {
                    FormView(form: plot.overstory)
                } label: {
                    HStack {
                        Text("Overstory")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                }
                Divider()
                NavigationLink {
                    FormView(form: plot.snags)
                } label: {
                    HStack {
                        Text("Snags")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                }
                Divider()
                NavigationLink {
                    FormView(form: plot.wildlife)
                } label: {
                    HStack {
                        Text("Wildlife")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                }
                Divider()
                NavigationLink {
                    FormView(form: plot.hardwoodPhenology)
                } label: {
                    HStack {
                        Text("Hardwood Phenology")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                }
                Divider()
                NavigationLink {
                    FormView(form: plot.softwoodPhenology)
                } label: {
                    HStack {
                        Text("Softwood Phenology")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                }
                Divider()
                NavigationLink {
                    FormView(form: plot.invasiveSpecies)
                } label: {
                    HStack {
                        Text("Invasive Species")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                }
                Divider()
                NavigationLink {
                    FormView(form: plot.treeHealth)
                } label: {
                    HStack {
                        Text("Forest Health")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                }
//                Divider()
//                NavigationLink {
//                    FormView(form: plot.trailCameraForm)
//                } label: {
//                    HStack {
//                        Text("Trail Camera")
//                        Spacer()
//                        Image(systemName: "chevron.right")
//                            .foregroundStyle(.tertiary)
//                    }
//                    .padding(16)
//                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(ListRow())
            .background {
                RoundedRectangle(cornerRadius: 16, style: .circular)
                    .fill(Color(.secondarySystemGroupedBackground))
                RoundedRectangle(cornerRadius: 16, style: .circular)
                    .stroke(Color(.systemFill))
                    .padding(.horizontal, 0.5)
            }
        }
    }
    
    struct Card50: View {
        @ObservedObject var plot: Plot
        
        var body: some View {
            VStack(spacing: 0) {
                Text("1/50")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.peach0, in: RoundedCorner(radius: 16, corners: [.topLeft, .topRight]))
                NavigationLink {
                    FormView(form: plot.saplingsForm)
                } label: {
                    HStack {
                        Text("Saplings")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(ListRow())
            .background {
                RoundedRectangle(cornerRadius: 16, style: .circular)
                    .fill(Color(.secondarySystemGroupedBackground))
                RoundedRectangle(cornerRadius: 16, style: .circular)
                    .stroke(Color(.systemFill))
                    .padding(.horizontal, 0.5)
            }
        }
    }
    
    struct Card1000: View {
        @ObservedObject var plot: Plot
        
        var body: some View {
            VStack(spacing: 0) {
                Text("1/1000")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.skyBlue1, in: RoundedCorner(radius: 16, corners: [.topLeft, .topRight]))
                NavigationLink {
                    FormView(form: plot.seedlingsForm)
                } label: {
                    HStack {
                        Text("Seedlings")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(ListRow())
            .background {
                RoundedRectangle(cornerRadius: 16, style: .circular)
                    .fill(Color(.secondarySystemGroupedBackground))
                RoundedRectangle(cornerRadius: 16, style: .circular)
                    .stroke(Color(.systemFill))
                    .padding(.horizontal, 0.5)
            }
        }
    }
    
    struct CardTransectLine: View {
        @ObservedObject var plot: Plot
        
        var body: some View {
            VStack(spacing: 0) {
                Text("Transect Lines")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.tumeric0, in: RoundedCorner(radius: 16, corners: [.topLeft, .topRight]))
                NavigationLink {
                    FormView(form: plot.debrisForm)
                } label: {
                    HStack {
                        Text("Debris")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(16)
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(ListRow())
            .background {
                RoundedRectangle(cornerRadius: 16, style: .circular)
                    .fill(Color(.secondarySystemGroupedBackground))
                RoundedRectangle(cornerRadius: 16, style: .circular)
                    .stroke(Color(.systemFill))
                    .padding(.horizontal, 0.5)
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            Card10(plot: plot)
            VStack(spacing: 54) {
                Card50(plot: plot)
                Card1000(plot: plot)
                CardTransectLine(plot: plot)
            }
        }
        .frame(maxWidth: .infinity)
    }
}


//                    .frame(maxWidth: .infinity)
//Card50(plot: $plot.plot50)
//                    .frame(maxWidth: .infinity)
//VStack(spacing: 24) {
//    ForEach($plot.plot1000) { plot in
//        Card1000(plot: plot)
//                            .frame(maxWidth: .infinity)
//    }
//}
//VStack(spacing: 24) {
//    ForEach($plot.transects) { line in
//        CardTransectLine(line: line)
//                            .frame(maxWidth: .infinity)
//    }
//}
