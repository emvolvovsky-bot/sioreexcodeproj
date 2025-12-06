//
//  QRCodeView.swift
//  Sioree
//
//  View for displaying QR codes
//

import SwiftUI

struct QRCodeView: View {
    let qrString: String
    let size: CGFloat
    
    init(qrString: String, size: CGFloat = 200) {
        self.qrString = qrString
        self.size = size
    }
    
    var body: some View {
        if let qrImage = QRCodeService.shared.generateQRCode(from: qrString, size: CGSize(width: size, height: size)) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .background(Color.white)
                .cornerRadius(Theme.CornerRadius.medium)
                .padding(Theme.Spacing.s)
                .background(Color.white)
                .cornerRadius(Theme.CornerRadius.medium)
        } else {
            ZStack {
                Rectangle()
                    .fill(Color.sioreeLightGrey.opacity(0.3))
                    .frame(width: size, height: size)
                
                Image(systemName: "qrcode")
                    .font(.system(size: size * 0.3))
                    .foregroundColor(Color.sioreeIcyBlue.opacity(0.5))
            }
        }
    }
}

#Preview {
    QRCodeView(qrString: "test-qr-code-data")
        .padding()
        .background(Color.sioreeBlack)
}


