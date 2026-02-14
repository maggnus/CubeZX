//
//  AlgorithmCardView.swift
//  CubeSync
//
//  Algorithm library cards and learning interface
//

import SwiftUI

struct AlgorithmCard: View {
    let algorithm: Algorithm
    @State private var isExpanded = false
    
    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(algorithm.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            GlassBadge(algorithm.category, color: categoryColor)
                            
                            HStack(spacing: 2) {
                                ForEach(Array(0..<algorithm.difficulty), id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.solarOrange)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Mini 3D cube preview
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.slate)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "cube.fill")
                            .font(.title2)
                            .foregroundColor(.neonCyan)
                    }
                }
                
                // Notation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notation")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.textSecondary)
                    
                    Text(algorithm.notation)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(isExpanded ? nil : 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: { isExpanded.toggle() }) {
                        Label(isExpanded ? "Less" : "More", systemImage: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.subheadline)
                    }
                    .glassButton()
                    
                    Spacer()
                    
                    Button(action: practiceAlgorithm) {
                        Label("Practice", systemImage: "play.fill")
                            .font(.subheadline)
                    }
                    .primaryButton()
                }
                
                // Expanded content
                if isExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        // Recognition guide
                        Text("Recognition")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.textSecondary)
                        
                        Text(algorithm.recognitionGuide)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        // Tips
                        if !algorithm.tips.isEmpty {
                            Text("Tips")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.textSecondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(algorithm.tips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.caption)
                                            .foregroundColor(.solarOrange)
                                        Text(tip)
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                            }
                        }
                        
                        // Statistics
                        HStack(spacing: 20) {
                            StatBox(value: "\(algorithm.practiceCount)", label: "Practiced")
                            StatBox(value: String(format: "%.2fs", algorithm.bestTime ?? 0), label: "Best")
                        }
                    }
                }
            }
        }
    }
    
    private var categoryColor: Color {
        switch algorithm.category {
        case "OLL": return .plasmaPurple
        case "PLL": return .electricBlue
        case "F2L": return .matrixGreen
        case "Beginner": return .neonCyan
        default: return .textSecondary
        }
    }
    
    private func practiceAlgorithm() {
        // Navigate to practice mode
    }
}

struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.textTertiary)
        }
    }
}

// MARK: - Algorithm Library View

struct AlgorithmLibraryView: View {
    @State private var selectedCategory: AlgorithmCategory = .all
    @State private var searchText = ""
    @State private var algorithms: [Algorithm] = Algorithm.sampleData
    
    var filteredAlgorithms: [Algorithm] {
        algorithms.filter { algorithm in
            let matchesCategory = selectedCategory == .all || algorithm.category == selectedCategory.rawValue
            let matchesSearch = searchText.isEmpty || 
                algorithm.name.localizedCaseInsensitiveContains(searchText) ||
                algorithm.notation.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }
    
    var body: some View {
        ZStack {
            Color.deepVoid.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Category filter
                categoryFilter
                
                // Algorithm list
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredAlgorithms) { algorithm in
                            AlgorithmCard(algorithm: algorithm)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textTertiary)
            
            TextField("Search algorithms...", text: $searchText)
                .foregroundColor(.white)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding()
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AlgorithmCategory.allCases) { category in
                    Button(action: { selectedCategory = category }) {
                        Text(category.rawValue)
                            .font(.subheadline.weight(.medium))
                    }
                    .glassButton(isSelected: selectedCategory == category)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Supporting Types

enum AlgorithmCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case oll = "OLL"
    case pll = "PLL"
    case f2l = "F2L"
    case beginner = "Beginner"
    
    var id: String { rawValue }
}

struct Algorithm: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let notation: String
    let difficulty: Int // 1-5
    let recognitionGuide: String
    let tips: [String]
    var practiceCount: Int = 0
    var bestTime: TimeInterval?
    var isFavorite: Bool = false
}

// MARK: - Sample Data

extension Algorithm {
    static let sampleData: [Algorithm] = [
        Algorithm(
            name: "T-Perm",
            category: "PLL",
            notation: "R U R' U' R' F R2 U' R' U' R U R' F'",
            difficulty: 3,
            recognitionGuide: "Look for headlights on the left and a bar on the right. The corners need to be swapped diagonally.",
            tips: ["Execute the F moves carefully", "Watch for the T-shape formation"],
            practiceCount: 24,
            bestTime: 1.85
        ),
        Algorithm(
            name: "Y-Perm",
            category: "PLL",
            notation: "F R U' R' U' R U R' F' R U R' U' R' F R F'",
            difficulty: 4,
            recognitionGuide: "Look for two corners that need to be swapped diagonally on one side.",
            tips: ["Pay attention to the F moves at start and end", "The algorithm flows in a pattern"],
            practiceCount: 18,
            bestTime: 2.34
        ),
        Algorithm(
            name: "Sune",
            category: "OLL",
            notation: "R U R' U R U2 R'",
            difficulty: 1,
            recognitionGuide: "Fish pattern with the head pointing to the back-left.",
            tips: ["One of the most common OLLs", "Very intuitive to execute"],
            practiceCount: 156,
            bestTime: 0.89
        ),
        Algorithm(
            name: "Anti-Sune",
            category: "OLL",
            notation: "R U2 R' U' R U' R'",
            difficulty: 1,
            recognitionGuide: "Fish pattern with the head pointing to the back-right.",
            tips: ["Mirror of the regular Sune", "Same rhythm, different direction"],
            practiceCount: 142,
            bestTime: 0.92
        ),
        Algorithm(
            name: "U-Perm (Clockwise)",
            category: "PLL",
            notation: "R2 U R U R' U' R' U' R' U R'",
            difficulty: 2,
            recognitionGuide: "Three edges need to cycle clockwise. Look for the solved bar.",
            tips: ["Keep the solved bar on the left", "Smooth execution is key"],
            practiceCount: 67,
            bestTime: 1.56
        ),
        Algorithm(
            name: "H-Perm",
            category: "PLL",
            notation: "M2 U M2 U2 M2 U M2",
            difficulty: 2,
            recognitionGuide: "Opposite edge swaps on all sides. Looks like an H pattern.",
            tips: ["Use M-slice for speed", "Very short and fast algorithm"],
            practiceCount: 45,
            bestTime: 1.23
        )
    ]
}

// MARK: - Preview

#Preview("Algorithm Library") {
    AlgorithmLibraryView()
}

#Preview("Algorithm Card") {
    ZStack {
        Color.deepVoid.ignoresSafeArea()
        
        ScrollView(.vertical, showsIndicators: true) {
            AlgorithmCard(algorithm: Algorithm.sampleData[0])
                .padding()
        }
    }
}
