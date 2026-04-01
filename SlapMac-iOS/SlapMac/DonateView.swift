import SwiftUI

struct DonateView: View {
    private let bgColor = Color(red: 0.086, green: 0.086, blue: 0.149)
    private let accentRed = Color(red: 0.91, green: 0.27, blue: 0.38)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("☕ Donate")
                        .font(.title.bold())
                        .foregroundColor(accentRed)

                    Text("If you enjoy SlapMac, consider supporting the developer!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Text("⚠ 18+ warning: adult-oriented sound content")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)

                    // MoMo
                    qrSection(title: "MoMo", imageName: "momo.jpeg")

                    // Techcombank
                    qrSection(title: "Techcombank", imageName: "techcombank.jpeg")

                    Spacer().frame(height: 40)
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func qrSection(title: String, imageName: String) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            if let img = loadResourceImage(imageName) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 250)
                    .cornerRadius(12)
            } else {
                Text("QR code not available")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }

    private func loadResourceImage(_ name: String) -> UIImage? {
        // Try bundle root
        if let path = Bundle.main.path(forResource: name, ofType: nil) {
            return UIImage(contentsOfFile: path)
        }
        // Try Resources subdirectory
        if let path = Bundle.main.path(forResource: name, ofType: nil, inDirectory: "Resources") {
            return UIImage(contentsOfFile: path)
        }
        // Try without extension
        let baseName = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        if let path = Bundle.main.path(forResource: baseName, ofType: ext) {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
}
