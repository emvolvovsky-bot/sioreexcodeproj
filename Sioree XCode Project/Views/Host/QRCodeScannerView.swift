//
//  QRCodeScannerView.swift
//  Sioree
//
//  QR code scanner for hosts to scan tickets at events
//

import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    let eventId: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var scanner = QRCodeScanner()
    @State private var scannedTicket: TicketQRData?
    @State private var showResult = false
    @State private var isValidTicket = false
    @State private var message = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera view
                QRCodeScannerRepresentable(scanner: scanner)
                    .ignoresSafeArea()
                
                // Overlay
                VStack {
                    Spacer()
                    
                    // Scanning area indicator
                    VStack(spacing: Theme.Spacing.m) {
                        Text("Position QR code within frame")
                            .font(.sioreeBody)
                            .foregroundColor(.sioreeWhite)
                            .padding(Theme.Spacing.m)
                            .background(Color.sioreeBlack.opacity(0.7))
                            .cornerRadius(Theme.CornerRadius.medium)
                        
                        // Scanning frame
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Color.sioreeIcyBlue, lineWidth: 3)
                            .frame(width: 250, height: 250)
                            .overlay(
                                // Corner indicators
                                VStack {
                                    HStack {
                                        Rectangle()
                                            .fill(Color.sioreeIcyBlue)
                                            .frame(width: 30, height: 3)
                                        Spacer()
                                        Rectangle()
                                            .fill(Color.sioreeIcyBlue)
                                            .frame(width: 30, height: 3)
                                    }
                                    Spacer()
                                    HStack {
                                        Rectangle()
                                            .fill(Color.sioreeIcyBlue)
                                            .frame(width: 30, height: 3)
                                        Spacer()
                                        Rectangle()
                                            .fill(Color.sioreeIcyBlue)
                                            .frame(width: 30, height: 3)
                                    }
                                }
                                .padding(10)
                            )
                    }
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .navigationTitle("Scan Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.sioreeWhite)
                }
            }
            .onReceive(scanner.$scannedCode) { code in
                if let code = code {
                    handleScannedCode(code)
                }
            }
            .alert(isValidTicket ? "Valid Ticket" : "Invalid Ticket", isPresented: $showResult) {
                Button("OK") {
                    if isValidTicket {
                        scanner.startScanning() // Continue scanning
                    }
                }
            } message: {
                Text(message)
            }
            .onAppear {
                scanner.startScanning()
            }
            .onDisappear {
                scanner.stopScanning()
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        scanner.stopScanning()
        
        let validation = QRCodeService.shared.validateQRCode(code)
        
        if validation.isValid, let ticketData = validation.ticketData {
            // Verify it's for this event
            if ticketData.eventId == eventId {
                isValidTicket = true
                scannedTicket = ticketData
                message = "Ticket verified! User ID: \(ticketData.userId.prefix(8))"
            } else {
                isValidTicket = false
                message = "This ticket is for a different event"
            }
        } else {
            isValidTicket = false
            message = "Invalid or tampered ticket"
        }
        
        showResult = true
    }
}

// MARK: - QR Code Scanner
class QRCodeScanner: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
    }
    
    func startScanning() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }
    
    func stopScanning() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            scannedCode = stringValue
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer?.videoGravity = .resizeAspectFill
        }
        return previewLayer!
    }
}

// MARK: - Camera View Representable
struct QRCodeScannerRepresentable: UIViewControllerRepresentable {
    let scanner: QRCodeScanner
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.scanner = scanner
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        // Update if needed
    }
}

class ScannerViewController: UIViewController {
    var scanner: QRCodeScanner?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPreview()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    
    private func setupPreview() {
        guard let scanner = scanner else { return }
        let layer = scanner.getPreviewLayer()
        layer.frame = view.layer.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
        
        DispatchQueue.global(qos: .userInitiated).async {
            scanner.startScanning()
        }
    }
}

#Preview {
    QRCodeScannerView(eventId: "test-event")
}

