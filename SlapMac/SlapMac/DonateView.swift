import SwiftUI

struct DonateView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("☕ Support SlapMac")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("SlapMac is free and always will be!\nIf you enjoy it, consider buying me a coffee 😊")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)
                
                Divider()
                
                // Momo QR Code
                VStack(spacing: 12) {
                    Text("MoMo")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.pink)
                    
                    if let momoImage = loadBundleImage(named: "momo") {
                        Image(nsImage: momoImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200, maxHeight: 200)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    } else {
                        placeholderQR(label: "MoMo QR Code")
                    }
                }
                
                // Techcombank QR Code
                VStack(spacing: 12) {
                    Text("Techcombank")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    if let techImage = loadBundleImage(named: "techcombank") {
                        Image(nsImage: techImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200, maxHeight: 200)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    } else {
                        placeholderQR(label: "Techcombank QR Code")
                    }
                }
                
                Divider()
                
                Text("Thank you for your support! 🙏")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 32)
        }
        .frame(width: 500, height: 620)
    }
    
    private func loadBundleImage(named name: String) -> NSImage? {
        // Try loading from bundle resources
        let extensions = ["jpeg", "jpg", "png"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return NSImage(contentsOf: url)
            }
            // Also check Resources subdirectory
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources") {
                return NSImage(contentsOf: url)
            }
        }
        return nil
    }
    
    private func placeholderQR(label: String) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 200, height: 200)
            .overlay(
                VStack {
                    Image(systemName: "qrcode")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            )
    }
}

#Preview {
    DonateView()
}
