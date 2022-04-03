//
//  ViewController.swift
//  TextRecognizer
//
//  Created by K Saravana Kumar on 13/03/20.
//  Copyright © 2020 K Saravana Kumar. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVSpeechSynthesizerDelegate, AVCapturePhotoCaptureDelegate, LoadedProductsDelegate {
    
    
    func didLoaded() {
        /*
         let containedRegexWords = global.productKeyWords.filter { (productName) -> Bool in
         let regexString = self.matchRegexProducts(string: "\njakavi®D\n", array: productName.components(separatedBy: " "))
         guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
         let appended = "\njakavi®D\n".components(separatedBy: "\n").reduce("") { (result, last) -> String in
         return result + " " + last
         }.trimmingCharacters(in: .whitespaces)
         
         let results = regex.matches(in: appended,
         range: NSRange(appended.startIndex..., in: appended))
         
         let aaa = "\nDiovan\"D\nvbg\n".trimmingCharacters(in: .newlines)
         
         let mapp = results.map {
         String(appended[Range($0.range, in: appended)!])
         }
         
         let newSentence = appended.replacingOccurrences(
         of: regexString,
         with: " ",
         options: .regularExpression
         )
         
         let regggg = "Diovan(.*)D"
         
         if let match = appended.range(of: regggg, options: .regularExpression) {
         print(appended.substring(with: match))
         }
         
         
         
         let query = "\nDiovan\"D\nvbg\n"
         let regex1 = try! NSRegularExpression(pattern:regggg, options: [])
         var results1 = [String]()
         
         regex1.enumerateMatches(in: query, options: [], range: NSMakeRange(0, query.utf16.count)) { result, flags, stop in
         if let r = result?.range(at: 1), let range = Range(r, in: query) {
         results1.append(String(query[range]))
         }
         }
         
         
         let range = NSRange(location: 0, length: appended.utf16.count)
         return regex.firstMatch(in: appended, options: [], range: range) != nil
         
         }
         */
        
        
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        self.errorLogs = global.errors
        
        self.startLiveVideo()
        //    }
    }
    
    var requests = [VNRequest]()
    var textRecognitionRequest = VNRecognizeTextRequest()
    var recognizedText = ""
    
    var utterance = AVSpeechUtterance()
    let synthesizer = AVSpeechSynthesizer()
    
    var session = AVCaptureSession()
    var captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
    var deviceOutput = AVCaptureVideoDataOutput()
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    
    var deviceLastInput: AVCaptureDeviceInput? = nil
    
    var errorLogs = errorlogs(dictionary: [:])
    
    var realImage = UIImage()
    
    var orientationCheck: CGImagePropertyOrientation!
    
    var pixcelBuffer: CVImageBuffer!
    
    var requestOptions:[VNImageOption : Any] = [:]
    
    @IBOutlet weak var cameraBaseView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //self.utterenceSetUp()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.loadDelegate = self
        self.startTextDetection()
    }
    
    func utterenceSetUp(speechText: String) {
        //utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        //"Ningún objeto encontrado"
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch(let error) {
            print(error.localizedDescription)
        }
        self.utterance = AVSpeechUtterance.init(string: speechText)
        self.utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        self.utterance.pitchMultiplier = 1.0
        self.utterance.rate = 0.4
        self.utterance.volume = 1.0
        self.synthesizer.delegate = self
        self.synthesizer.speak(self.utterance)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        //let vaaa = "catafvvvuam".levenshtein("cataflam")
        
        // let val = "good".components(separatedBy: " ")
        
        
    }
    
    func getReturnCapsuleCountDetails(scannedString: String) -> Int {
        
        var capsuleNumber = 0
        
        let newLineArray = scannedString.components(separatedBy: "\n")
        
        let tabletValue = newLineArray.filter { (outComeData) -> Bool in
            tabletCountIdentifyArray.contains { (tablet) -> Bool in
                return String(outComeData).contains(tablet)
            }
            
        }
        
        if tabletValue.count != 0{
            
            for tabletCountString in tabletValue {
                let stringArray = tabletCountString.components(separatedBy: CharacterSet.decimalDigits.inverted)
                for item in stringArray {
                    if let number = Int(item) {
                        print("number: \(number)")
                        capsuleNumber = number
                        break
                    }
                }
            }
            
        }else{
            
        }
        
        return capsuleNumber == 0 ? 0: capsuleNumber
    }
    
    //MARK: Adding Focus Observers
    // Adding Focus observers for scanning image after getting clear image focus
    func addObservers() {
        self.captureDevice!.addObserver(self, forKeyPath: "adjustingFocus", options: [.new], context: nil)
        
    }
    
    func removeObservers() {
        self.captureDevice!.removeObserver(self, forKeyPath: "adjustingFocus")
    }
    
    //MARK: Focus Delegate
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let key = keyPath, let changes = change else {
            return
        }
        print("abc=====",key)
        if key == "adjustingFocus" {
            
            deviceOutput.setSampleBufferDelegate(self , queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
            let changedValue = changes[.newKey]
            if (changedValue! as! Bool){
                // camera is auto-focussing
            }else{
                // camera is not auto-focussing
            }
            //removeObservers()
        }
        
    }
    
    //MARK: Video Configuration
    
    func startLiveVideo() {
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                //1
                
                
                //2
                
                do {
                    try self.captureDevice!.lockForConfiguration()
                    
                    self.session.sessionPreset = AVCaptureSession.Preset.photo
                    
                    self.captureDevice!.focusMode = .autoFocus
                    
                    let deviceInput = try! AVCaptureDeviceInput(device: self.captureDevice!)
                    
                    self.deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                    
                    self.session.addInput(deviceInput)
                    self.session.addOutput(self.deviceOutput)
                    DispatchQueue.main.async {
                        //3
                        
//                        let imageLayer = AVCaptureVideoPreviewLayer(session: self.session)
//                        imageLayer.frame = self.view.bounds
                        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                        //self.previewLayer.frame = self.view.bounds
                        self.previewLayer.frame = self.cameraBaseView.bounds
                        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                        //self.view.layer.addSublayer(self.previewLayer)
                        self.cameraBaseView.layer.addSublayer(self.previewLayer)
                        
                        
                        
                        self.session.startRunning()
                        
                        self.addObservers()
                    }
                    
                    self.captureDevice!.unlockForConfiguration()
                    
                    
                    
                } catch {
                    print("Torch could not be used")
                }
                
                
                
            } else {
                
            }
        }
        
        
    }
    
    //MARK: AVCapture Delegate
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        //self.detectRectangle(in: pixelBuffer)
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        //CGImagePropertyOrientation(rawValue: 6)!
        
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: requestOptions)
        
        
        self.orientationCheck = .right
        
        self.requestOptions = requestOptions
        
        self.pixcelBuffer = pixelBuffer
        
        /*
         //        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
         //            return
         //        }
         CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
         let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
         let width = CVPixelBufferGetWidth(pixelBuffer)
         let height = CVPixelBufferGetHeight(pixelBuffer)
         let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
         let colorSpace = CGColorSpaceCreateDeviceRGB()
         let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
         guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
         return
         }
         guard let cgImage = context.makeImage() else {
         return
         }
         
         let image = UIImage(cgImage: cgImage, scale: 1, orientation:.left)
         CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
         
         
         // let imageRequestHandler = VNImageRequestHandler.init(cgImage: image.cgImage!, options: requestOptions)
         
         let imageRequestHandler = VNImageRequestHandler.init(cgImage: image.cgImage!, orientation: .left, options: requestOptions)
         */
        
        do {
            try imageRequestHandler.perform([self.textRecognitionRequest])
            //self.getBufferData(sampleBuffer: sampleBuffer)
            
        } catch {
            print(error)
        }
        
        
    }
    
//    func VNNormalizedRectForImageRect(_ imageRect: CGRect,
//    _ imageWidth: Int,
//    _ imageHeight: Int) -> CGRect{
//
//    }
    
    private func detectRectangle(in image: CVPixelBuffer) {
        let request = VNDetectRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                guard let results = request.results as? [VNRectangleObservation] else { return }
                self.removeBoundingBoxLayer()
                //retrieve the first observed rectangle
                guard let rect = results.first else{return}
                //function used to draw the bounding box of the detected rectangle
                self.drawBoundingBox(rect: rect)
//                results.forEach { (rect) in
//                    self.drawBoundingBox(rect: rect)
//                }
                
            }
        })
        //Set the value for the detected rectangle
        //request.minimumAspectRatio = VNAspectRatio(0.0)
        //request.maximumAspectRatio = VNAspectRatio(1.0)
        request.minimumSize = Float(0.3)
        request.maximumObservations = 3
        request.minimumConfidence = 0.6
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform([request])
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                //self.presentAlert("Image Request Failed", error: error)
                return
            }
        }
    }
    
    func drawBoundingBox(rect : VNRectangleObservation) {
        let transform = CGAffineTransform(scaleX: 1, y: -1)
            .translatedBy(x: 0,
                          y: -self.previewLayer.bounds.height)
        let scale = CGAffineTransform.identity
            .scaledBy(x:self.previewLayer.bounds.width,
                      y:self.previewLayer.bounds.height)
        let bounds = rect.boundingBox.applying(scale).applying(transform)
        
        //var convertedRect = self.previewLayer .metadataOutputRectConverted(fromLayerRect: rect.boundingBox)
        //let bounds = rect.
        createLayer(in: bounds)
        
    }
    
    private var bBoxLayer = CAShapeLayer()
    private func createLayer(in rect: CGRect) {
      bBoxLayer = CAShapeLayer()
      //let convertedRect = self.previewLayer.layerRectConverted(fromMetadataOutputRect: rect)
      bBoxLayer.frame = rect
      bBoxLayer.cornerRadius = 2
      bBoxLayer.opacity = 1
      bBoxLayer.borderColor = UIColor.systemRed.cgColor
      bBoxLayer.borderWidth = 2.0
      self.previewLayer.insertSublayer(bBoxLayer, at: 1)
    }
    func removeBoundingBoxLayer() {
      bBoxLayer.removeFromSuperlayer()
    }
    
    
    func imageExtraction(_ observation: VNRectangleObservation,
                         from buffer: CVImageBuffer) -> UIImage {
      var ciImage = CIImage(cvImageBuffer: buffer)
      
      let topLeft = observation.topLeft.scaled(to: ciImage.extent.size)
      let topRight = observation.topRight.scaled(to: ciImage.extent.size)
      let bottomLeft = observation.bottomLeft.scaled(to: ciImage.extent.size)
      let bottomRight = observation.bottomRight.scaled(to: ciImage.extent.size)
    // pass filters to extract/rectify the image
      ciImage = ciImage.applyingFilter("CIPerspectiveCorrection",
       parameters: [
        "inputTopLeft": CIVector(cgPoint: topLeft),
        "inputTopRight": CIVector(cgPoint: topRight),
        "inputBottomLeft": CIVector(cgPoint: bottomLeft),
        "inputBottomRight": CIVector(cgPoint: bottomRight),
       ])
      let context = CIContext()
      let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
      let output = UIImage(cgImage: cgImage!)
      //return image
      return output
    }
    
    
    func getBufferData(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return
        }
        guard let cgImage = context.makeImage() else {
            return
        }
        let image = UIImage(cgImage: cgImage, scale: 1, orientation:.left)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        
        self.realImage = image
        
        DispatchQueue.main.async {
            let imageView = UIImageView.init(frame: CGRect.init(x: 30, y: 30, width: 250, height: 250))
            
            imageView.image = image
            
            self.view.addSubview(imageView)
        }
    }
    
    
    
    //MARK: Text Detection Method
    
    func startTextDetection() {
        //caja con 30 grageas
        //30 comprimidos recubiertos
        //50 cápsulas de gelatina blanda
        self.textRecognitionRequest.recognitionLevel = .fast
        self.textRecognitionRequest.recognitionLanguages = ["en-GB","es-ES"]
        self.textRecognitionRequest.customWords = global.productKeyWords
        
        self.textRecognitionRequest = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                fatalError("Received invalid observations")
            }
            var textAppended = ""
            
            if observations.count != 0 {
                self.session.stopRunning()
            }
            for observation in observations {
                
                for value in observation.topCandidates(1) {
                    print("Found this candidate1: \(value.string)")
                }
                
                guard let bestCandidate = observation.topCandidates(1).first else {
                    print("No candidate")
                    continue
                }
                
                //self.textOCR.text = self.textOCR.text! + " " + bestCandidate.string
                //textAppended = textAppended + "\n" + self.replaceSpecialCharecters(stringPool: bestCandidate.string).replacingOccurrences(of: "  ", with: " ")
                textAppended = textAppended + "\n" + bestCandidate.string
                print(bestCandidate.string)
                print("Found this candidate: \(bestCandidate.string)")
            }
            print("textPrinted=",textAppended)
            textAppended = textAppended.trimmingCharacters(in: .whitespacesAndNewlines)
            
            //textAppended = "Tacrolimus Sandoz 0,5 mg\nTacrolimus 0,5mg\n50 capsulas\nSANI\nVia oral\nSANDOY\nNDO7\nSANDE\nVenta bajo receta profesional\nNDO\nSENTE\nMEDICAMENTO\nINTERCAMBIABLE\nSANDOZ o Nouar tis"
            //textAppended = "Diovan\"D\n30 col\nValsartan 80 mg\nHidrociorotiazida 12.5 mg\ncomprmidos recubiertos\nBoned\nNOVARTIS\nDiovan D\nValsartan 30 m\nHidroclorotiazid.\ncomprimidos recubiertos\n30\ncomprimidos recubiertos"
            
            //textAppended = "SILVAON $\n30 film-coated tablets /\ncomprimidos con cubierta pelicular\no Stalevo®\n200/50/200 mg\nlevodopa carbidopa entacapone"
            
           // textAppended = "Ecuador 29728-04-11\n28 comprimes pelliculés/film-coated tablets/\ncomprimidos con cubierta pelicular 5 mg/160 mg\ni NOVARTIS\nEXFORGE\n5 mg/160 mg\namlodipine/valsartan\nConditionnement-calendrier/\namlodipino/valsarton\nCalendar pack/Envase-calendario\n28 comprimes pelliculés/flm-coated tablets/\ncomprimidos con cubierta pelicular\nmg/160 mg\n5t76/515\n1, NOVARTIS\n28 comprimés pelliculés/\nfilm-coated tablets/\ncomprimidos con cubierta\nEXFORGE\npelicular 5 mg/160 mg\nomlodipine/valsorton\n5 mg/160 mg\nomlodipino /valsart in\nSHOVE\nstEVA0N\nVoie orale. A conserver a une température ne dépassant pas 30° et a l\'abri de I\'humidite.\nA conserver dans T\'emballage exterieur d\'origine. Tenir hors de la portee et de la vue des enfants.\nMédicament soumis a prescription médicale.\nFor oral use. Do not store above 30°C, protect from moisture.\nStore in the original Package. Keep out of the reach and sight of children.\nMedicinal product subject to medical prescription.\nVia oral. No conservar a temperatura superior a 30°C, proteger de la humedad.\nConservar en el embalaje original. Mantener fuera del alcance y de la vista de los nifos,\nMedicamento sujeto a prescripcion medica.\nPanama: 77003\nRep. Dominicana: 2012-0762\ncomprime pelicule/film-coated tablet/comprim.do con cubierta\namodipine besylate/besilato de amlodn 6.94 mg\npelicular\nUAE reg no 5537-6761-2\n(corresp. to amlodipine/amladipino\nCosta Rica 4134-IE-7531:\nmg), valsartan 160 mg\nEl Salvador F023630052007:\nGuatemala PF-44674;\nHonduras M-17536\nManufactured by Novartis Farmaceutica S. A.\nBarbera del Valles, Spain for\nNicaragua 01116070611\nNovartis Pharma AG, Basel, Switzerland\nPery: R.5.NO E-22633;\nFabricado por Novartis Farmaceutica S. A.,\nNAFDAC Req. No A4-068\nBorbera del Valles, Espana para\nZimbabwe Reg. No.:\nNovartis Pharma AG, Basilea, Suiza\n2013/12.3.5/4766 (PP)\nMM Reg. No. 2002AA8549\nZambia 120/041 (POM)\nOCT\n13\n..\ntv"
            
              // textAppended = "Alcon\nImporta,\nrepresenta y distribuye\nUruguay:\nMurry S.A. (Scienza\nUruguay)-\nNovartis company\nLuis A. de Herrera 1248, Torre\nOficina 1906. Montevideo, Urug\nD.T.: Q.F. Adriana Nabon.\nReg, Prod. No. 24.872\n1413895026454\nFabricado por:\nALCON-COUVREUR,\nPuurs, Belgica para Novartis\nPharma NV, Vitvoorde, Belgica.\nIndustria Belga\nVENTA BAJO RECETA\nPROFESIONAL\nun\nISOPTOMAX*\nDexametasona 0.1%\nNeomicina 3,500 UI\nPolimixina B 6,000 UI\nSuspension Oftalmica Esteril\nMR\nAlcon\nAut. no. 176\n*Marca registrada de Novart\nNovartis company\n5 mL"
            //textAppended = "ing ef pp ouelayond a\n*nings youn whg ppagouct on fas\ned\nau1 fg Auo paransmaupe\nultibro 110/ 50 microgram\nbreezhaler\nInhalation Powder hard capsule\nPolvo para inhalacion en capsulas duras\nPoudre pour inhalation en gélules\nindacaterol and glycopyrronium\nindacaterol y glicopirronio\nIndacatérol et glycopyrronium\n& NOVARTIS\nultibro®\n110/50 microgram\n30 capsules\n30 capsulas\nbreezhaler\n30 gélules et\nInhalation Powder hard capsule\nPotvo para inhalacion on capsulas duras\nPoudre pour Inhalation en gélules"
            
           // textAppended = "342/43261-2/n342/43261-2/n28x28x70 mm/n342/43261-2/n12-2017/nAlcon/nCOMPOSICION:/nCada mL de TOBRADEX*/na Novartis company/ncontiene: Activos: tobramicina/n3 mg; dexamelasona/nmg./nConservante:/ncloruro de benzalconio al/n0.01 %-/nExcipientes: hidroxieti-/ncelulosa. edetato disodico/ndihidratado, tiloxapol,/nsullato ds/nsodin anhidro, cloruro de sodio,/nacido sulfurico y/o hidroxido de/nsodio (para ajustar el ph), agua/npurificada c.s.p. 1 ml./nImporta, representa y distribuye en/nUruguay: Mury S.A. (Scienza/nUruguay)/n5 mL/nLivis A. de Herrera 1248 Torre 2,/nOficina 1905,/nMonteviden, Uruguay./nTOBRADEX*/nM221.620m.S68517/nN- Reg. MSP; 30056/nL/nD.T.: Q.F. Adriane Nabon,/nYENTA BAJO RECETA/nTobramicina/n0.3%/nPROFESIONAL./nDexametasona/n0.1%/nAut. no. 176/nFabricado por:/nSuspension Oftalmica Esteril/nALCON-COUVREUR,/nPours. Begica para Novartis Pharma N%,/nVivoorde, Belgica./nAlcon/nndustria Beigs/na Novartis company/nTOBRADEX*/nTobramicina 0.3%/nDexametasona/n0.1%/nSuspension Oftalmica Esterl"
            /*
            textAppended = "Testing Report for Scienza Vision (Oct 2i/n• 6. sandimmun neoral/na@d/njeoan unuimipues/nSILAVAON/n5 NOVARTIS/nSandimmun Neor/nCiclosporin / Ciclosporina/nA/n25 mg/n50 soft gelatin capsules//ncapsules molles de gelatine//ncapsulas blandas de gelatin/nezins 'eajiseg 'oy/nBUJBLd SQUENON BUED/nBlUBWBM'uapeg,/upequragg/nHourg upeqiagg fueuling awajeie) sod opeauges/nenipewu e,soau oleg eosi/npuepaziws 'ajseg 'O ELLJBLd/nSq/ENON J01/n10-10-BEh2-0919 30k aun/nfueuue9 *uapeg,/ypeqlagg/n1401g upeq agg fueuing 1u8j2193 /q pampernuer/n2S6 1O IN BRA DYGAIN/ndISCIENIS TN BAL ANDIRUIS/nsypa, pesopue c) .1B,a) 2922)/nBw c7/neuLodsopio/n(uuodsopip = einsdgs, rejnsdes/nSTETIZSG5T Thin ensic On/n1e10 e11/esn 1e10:304/aje10 210)/nTISETWOODE. TINI Ti24 MIN/n9.52 e JoHlad ns eumpeiadlua, e ieA185U03 ON/nYOZZZ ADDENAS IG/n9.57 anoge 2J0)5 jou 00/n2130 S5 BleouLing dag/n/ 3.57+ sed quessedep au aimexadwa, eun e J8/8sU03 y/nINIt& PLUR URTE/nSOUTL soj ap eqsin ej ap K eoueoje jap guany Jauajuew/n96-3905-i0 an Bicaton/nvasprup yo nais pue upees aut j0 10o daay/n18-89000 IN STAPURS/nSque us sap ans E ap 13 agu0d ej ap JOL JIUB I!/ndisht he epuging/nSE251 3 HE7t 80ig/nSILNVAON/n1001R/npresentationKettg/nENUN3/n30"
            */
            /*
            textAppended = "SLINVAON/n10/nupeje8 ep sepueng sejnsdea,/oupejes ap/nsejpow seinsdea /sainsdeo uppjad yOS OG/nSw/nOCT/neuuodsopio / uuodsopip/nLY/nJe10a N unuwipues/nSLINVAON/nI/nNOVARTIS/nSandimmun Neoral®/nCiclosporin Ciclosporina/nN/n100/nmg/n50 soft gelatin capsules/capsules molles/nde gelatine/capsulas blancas ce gelatin/nERINS SRIRE 54 sullp4& superok wrEd/nexpouN FIOna pioN PRRK/ngiusware-veceazupeqsagg*iqwp spe.ng future sued obuei/npiBuez, wS 'asea 'The UhJeNd SpAINON B01/n11D ED EER!:0509 JONJ/nKuwaing vnceg opogiage^hgup usezing_ fitn gases / gmoyy/nBUSE-110 0 120d D1 T4EN/narts Nis sedius/n1,-c0) poe1ps at apo isist/n2u1 cot auuodsopns 2u1ocs png in Finsoep apfr 1/nFIENT# EZYEST THIERRILA/nje10 yacm 1209, FAST IR.0 1D)/n0 .$2 06 SOUNI esa/ugsu0g• 9207- soung apEiBIe SeUSPUEW/n0.52ap shossep-ne wraosuog w eluejue sap eoped ap sse sing/nK tastIEin4/nST MD130 a303s - u2ap 1u3 j0 40821 2741 19 ton deary/nla 6sam w s21spas4/n15:11531 04 PP07250/n753s1 atelni awni/nSTLXVAON/n9 a/nNow/n130/ntv"
            */
            /*
            textAppended = "NOVARTIS/nJAKAVI® 15 mg/nRuxolitinib/ntablets / comprimés / comprimidos/n60 tablets / comprimés / comprimidos/nFor oral use/nvoie orale/nvia oral"
            
            */
            
            /*
             textAppended = "28 comprimes pellicules/film-coated tablets//ncomprimidos con cubierta pelicular mg/80 mg/n6 NOVARTIS/nDs/nEXFORGE/n5 mg/160 mg/namlodipine/valsartan/nConditionnement-calendrier//namlodipino/valsarton/nCalendar pack/Envase-calendario/n28 comprimes pellicules/f Im-coated tablets//ncomprimides con cublerta pelicular mg/160 mg/nExtorge HUl/nExiade/nNOV/n30/ntv"
            */
            /*
            textAppended = "NOVARTIS/nEXFORGE/n5 mg/160 mg/namlodipine/valsartan/nConditionnement-calendrier//namlodipino/valsarton/nCalendar pack/Envase-calendario/n28 comprimes pelliculés/film-coated tablets//ncomprimidos con cubierta pelicular/nmg/160 mg/nvPush.p12/ncoAccou...tificates/ntv"
            */
            /*
            textAppended = "Preview/nFile/nEdit View/nGo/nTools Window/nHelp/nTesting Report for Scienza ision (Oct 2020).pdf (page 6 of 6)/n06 0 & Sear/n6 noVaRtIS/nEXFORGEHCT® 5mg/160mg/12.5mg/ncomprimés pelliculés//nfilm-coated tablets//ncomprimidos con cubierta/npelicular/namlodipine/vasartan/hydrochlorothiazie/namlodipino/valartan/hidroclrotd/n28 comprimés pelliculés/film-coated tablets//ncomprimidos con cubierta pelicular 5 mg/ 160 mg/ 12.5 mg/nO NOVARTIS/nEXFORGEHCT® 5mg/160mg/25mg/ncomprimés pelliculés//nfilm-coated tablets//ncomprimidos con cubierta/npelicular/namlodipine/valartan/hydrochlorothiazide/namlodipino)/valsartan/hidroclrt/n1000% 3H"
            */
            if self.orientationCheck == .right{
                self.session.stopRunning()
                self.removeObservers()
                self.deviceOutput.setSampleBufferDelegate(nil, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
            }
            
            //self.checkIfProductNotFound(string: textAppended)
            //textAppended = "       ".trimmingCharacters(in: .whitespaces)
            
            
            if textAppended.count != 0 && textAppended != ""{
                
                let containedWords = global.productKeyWords.filter { (keyword) -> Bool in
                    return textAppended.lowercased().contains(keyword.lowercased())
                }
                
                // var tabletCount = 0
                
                // tabletCount = self.getReturnCapsuleCountDetails(scannedString: textAppended)
                
                // print("tabCount =",tabletCount)
                
                if containedWords.count != 0 {
                    
                    
                    var product: ProductDetails? = nil
                    /*
                     for value in containedWords {
                     
                     if global.proudctList[value] != nil {
                     
                     product = global.proudctList[value]?.first
                     break
                     
                     }
                     
                     }
                     */
                    
                    if let available = self.checkIfProductFound(string: textAppended, containedWords: containedWords) {
                        
                        product = available
                        
                        DispatchQueue.main.async(execute: {
                            
                            //self.utterance = AVSpeechUtterance.init(string: product!.speechtext)
                            //self.synthesizer.speak(self.utterance)
                            let speechText = product!.speechtext
                            //let speechText = tabletCount == 0 ? product!.speechtext : "\(tabletCount) comprimidos \(product!.speechtext)"
                            self.utterenceSetUp(speechText: speechText)
                            
                        })
                        
                    }else{
                        
                        if let mayBeProduct = self.checkIfProductNotFound(string: textAppended) {
                            
                            var product: ProductDetails? = nil
                            
                            product = mayBeProduct
                            
                            DispatchQueue.main.async(execute: {
                                
                                //self.utterance = AVSpeechUtterance.init(string: product!.speechtext)
                                //self.synthesizer.speak(self.utterance)
                                let speechText = product!.speechtext
                                //let speechText = tabletCount == 0 ? product!.speechtext : "\(tabletCount) comprimidos \(product!.speechtext)"
                                self.utterenceSetUp(speechText: speechText)
                                
                            })
                            
                        }else{
                            if self.orientationCheck == .right{
                                self.utterenceSetUp(speechText: "Ningún objeto encontrado")
                            }else if self.orientationCheck == .left{
                                self.utterenceSetUp(speechText: "Rotate Left Side")
                                //self.utterenceSetUp(speechText: self.errorLogs.dataInsufficient)
                            }else if self.orientationCheck == .up{
                                self.utterenceSetUp(speechText: "Rotate Up Side")
                                //self.utterenceSetUp(speechText: self.errorLogs.dataInsufficient)
                            }else if self.orientationCheck == .down{
                                self.utterenceSetUp(speechText: "Rotate Down Side")
                                //self.utterenceSetUp(speechText: self.errorLogs.dataInsufficient)
                            }else{
                                self.utterenceSetUp(speechText: self.errorLogs.dataInsufficient)
                            }
                            
                        }
                    }
                    
                    
                }else{
                    
//                    let containedRegexWords = global.productKeyWords.filter { (productName) -> Bool in
//                        let regexString = self.matchRegexProducts(string: textAppended, array: productName.components(separatedBy: " "))
//                        let appended = textAppended.components(separatedBy: "\n").reduce("") { (result, last) -> String in
//                            return result + " " + last
//                        }.trimmingCharacters(in: .whitespaces)
//                        guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
//                        let range = NSRange(location: 0, length: appended.utf16.count)
//                        return regex.firstMatch(in: appended, options: [], range: range) != nil
//
//                    }
//
//                    if containedRegexWords.count != 0{
//
//                        var product: ProductDetails? = nil
//                        if let available = self.checkIfProductFound(string: textAppended, containedWords: containedRegexWords) {
//
//                            product = available
//
//                            DispatchQueue.main.async(execute: {
//
//                                //self.utterance = AVSpeechUtterance.init(string: product!.speechtext)
//                                //self.synthesizer.speak(self.utterance)
//                                let speechText = product!.speechtext
//                                //let speechText = tabletCount == 0 ? product!.speechtext : "\(tabletCount) comprimidos \(product!.speechtext)"
//                                self.utterenceSetUp(speechText: speechText)
//
//                            })
//
//                        }else{
//                            //"Todavía estoy identificando el producto, un momento"
//
//                            if self.orientationCheck == .right{
//                                self.utterenceSetUp(speechText: self.errorLogs.dataInsufficient)
//                            }else if self.orientationCheck == .left{
//                                self.utterenceSetUp(speechText: "Rotate Left Side")
//                                //self.utterenceSetUp(speechText: self.errorLogs.dataInsufficient)
//                            }else if self.orientationCheck == .up{
//                                self.utterenceSetUp(speechText: "Rotate Up Side")
//                                //self.utterenceSetUp(speechText: self.errorLogs.dataInsufficient)
//                            }else if self.orientationCheck == .down{
//                                self.utterenceSetUp(speechText: "Rotate Down Side")
//                                //self.utterenceSetUp(speechText: self.errorLogs.dataInsufficient)
//                            }else{
//                                self.utterenceSetUp(speechText: self.errorLogs.dataInsufficient)
//                            }
//                        }
//
//                    }else
                        
                        
                        if self.orientationCheck == .right {
                        
                        //   self.utterenceSetUp(speechText: "We could not get the products correctly please wait we will check if the images rotated or misplaced")
                        
                        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: self.pixcelBuffer, orientation: .left, options: self.requestOptions)
                        
                        self.orientationCheck = .left
                        
                        do {
                            try imageRequestHandler.perform([self.textRecognitionRequest])
                            //self.getBufferData(sampleBuffer: sampleBuffer)
                            
                        } catch {
                            print(error)
                        }
                        
                    }else if self.orientationCheck == .left {
                        
                        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: self.pixcelBuffer, orientation: .up, options: self.requestOptions)
                        
                        self.orientationCheck = .up
                        
                        do {
                            try imageRequestHandler.perform([self.textRecognitionRequest])
                            //self.getBufferData(sampleBuffer: sampleBuffer)
                            
                        } catch {
                            print(error)
                        }
                        
                    }else if self.orientationCheck == .up{
                        
                        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: self.pixcelBuffer, orientation: .down, options: self.requestOptions)
                        
                        self.orientationCheck = .down
                        
                        do {
                            try imageRequestHandler.perform([self.textRecognitionRequest])
                            //self.getBufferData(sampleBuffer: sampleBuffer)
                            
                        } catch {
                            print(error)
                        }
                        
                    }else{
                        
                        
                        
//                        if let mayBeProduct = self.checkIfProductNotFound(string: textAppended) {
//
//                            var product: ProductDetails? = nil
//
//                            product = mayBeProduct
//
//                            DispatchQueue.main.async(execute: {
//
//                                //self.utterance = AVSpeechUtterance.init(string: product!.speechtext)
//                                //self.synthesizer.speak(self.utterance)
//                                let speechText = product!.speechtext
//                                //let speechText = tabletCount == 0 ? product!.speechtext : "\(tabletCount) comprimidos \(product!.speechtext)"
//                                self.utterenceSetUp(speechText: speechText)
//
//                            })
//
//                        }else{
//                            self.errorThroughFunction(textAppended: textAppended)
//                        }
                        
                        self.errorThroughFunction(textAppended: textAppended)
                    }
                    
                    
                }
                
            }else{
                
                self.addObservers()
                self.session.startRunning()
                
                //self.utterenceSetUp(speechText: "Ningún objeto encontrado")
            }
            
        }
    }
    
    //MARK: Utterence Delegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance){
        self.addObservers()
        self.session.startRunning()
        
    }
    
    func replaceSpecialCharecters(stringPool: String) -> String {
        return (stringPool.contains("\'") ? stringPool.replacingOccurrences(of: "\'", with: " ") : stringPool.contains("\"") ? stringPool.replacingOccurrences(of: "\"", with: " ") : stringPool.contains("®") ? stringPool.replacingOccurrences(of: "®", with: " ") : stringPool)
    }
    
    func errorThroughFunction(textAppended: String) {
        if textAppended.count == 0 {
            //self.session.stopRunning()
            //"Ningún objeto encontrado"
            self.utterenceSetUp(speechText: self.errorLogs.nodata)
            //                    self.utterance = AVSpeechUtterance.init(string: "Ningún objeto encontrado")
            //                    self.utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
            //                    self.utterance.pitchMultiplier = 1.0
            //                    self.utterance.rate = 0.4
            //                    self.synthesizer.speak(self.utterance)
            
            //self.session.startRunning()
            
        }else{
            DispatchQueue.main.async(execute: {
                //                let alert = UIAlertController.init(title: "Recognized Text", message: textAppended, preferredStyle: .alert)
                //                alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (good) in
                //                    //                        self.synthesizer.stopSpeaking(at: .immediate)
                //                    //                    self.session.startRunning()
                //
                //                }))
                //                self.present(alert, animated: true, completion: nil)
                
                //self.utterance = AVSpeechUtterance.init(string: "This is not Diovan")
                //self.synthesizer.speak(self.utterance)
                
                //let speechText = "Este no es tu producto que buscas"
                self.utterenceSetUp(speechText: self.errorLogs.nomatching)
                
            })
            //synthesizer.stopSpeaking(at: .word)
            
            
            
            
        }
        
    }
    
    //®
    func checkIfProductFound(string: String, containedWords: [String]) -> ProductDetails? {
        
        let arrangedContainedWords = containedWords.sorted { (stringOne, stringTwo) -> Bool in
            return stringOne.count > stringTwo.count
        }
        
        for value in arrangedContainedWords {
            
            if global.proudctList[value] != nil {
                
                let products = global.proudctList[value]
                
                guard let conTypeProduct = products?.filter({ (product) -> Bool in
                    return string.lowercased().contains(product.concentrationType.lowercased())
                }) else { return products?.first! }
                
                if conTypeProduct.count != 0 {
                    
                    if let product = self.getPerfectProductFilter(conTypeProduct: conTypeProduct, string: string){
                        return product
                    }else{
                        //                        let product = conTypeProduct.first!
                        //                        product.speechtext = "it is \(product.name). But we could not identify the concentration and presentation"
                        //
                        //                        return product
                    }
                    /*
                     if let product = self.getAverageIngredientProductFilter(conTypeProduct: conTypeProduct, string: string){
                     return product
                     }
                     
                     if let product = self.getAverageIngredientValueProductFilter(conTypeProduct: conTypeProduct, string: string){
                     return product
                     }
                     
                     if let product = self.getAveragePresentationProductFilter(conTypeProduct: conTypeProduct, string: string){
                     return product
                     }
                     
                     
                     if let product = self.getAverageIngredientandValueProductFilter(conTypeProduct: conTypeProduct, string: string){
                     return product
                     }
                     
                     if let product = self.getAverageIngredientandPresentationProductFilter(conTypeProduct: conTypeProduct, string: string){
                     return product
                     }
                     
                     if let product = self.getAverageIngredientValueandPresentationProductFilter(conTypeProduct: conTypeProduct, string: string){
                     return product
                     }
                     
                     if let product = self.getAverageFilter(conTypeProduct: conTypeProduct, string: string){
                     return product
                     }
                     */
                    
                }else{
                    
                    //                    let product = products!.first!
                    //                    product.speechtext = "it is \(product.name). But we could not identify the concentration and presentation"
                    //
                    //                    return product
                    
                    
                }
                
            }else{
                
            }
            
        }
        return nil
    }
    
    //®
    func checkIfProductNotFound(string: String) -> ProductDetails? {
        /*
         for (_,allProductDetails) in global.proudctList {
         
         let conTypeKey = allProductDetails.filter { (productDetails) -> Bool in
         return (string.contains(productDetails.concentrationType) && string.contains(productDetails.concentrationKey))
         }
         
         if conTypeKey.count != 0 {
         
         }else{
         
         }
         
         }
         */
        
        if let getMatchingHighProduct = self.getHighPercentageProduct(string: string){
            
            let conTypeProduct = getMatchingHighProduct.filter({ (product) -> Bool in
                return string.lowercased().contains(product.concentrationType.lowercased())
            })
            
            if conTypeProduct.count != 0 {
                /*
                 let conKeyProduct = conTypeProduct.filter { (product) -> Bool in
                 return string.contains(product.concentrationKey)
                 }
                 */
                /*
                 let conKeyProduct = conTypeProduct.filter { (product) -> Bool in
                 
                 let ingredientColl = product.concentration.filter { (concent) -> Bool in
                 /*
                 let mostPercentage = Double((Double(concent.ingredient.lowercased().count - string.lowercased().levenshtein(concent.ingredient.lowercased()))/Double(concent.ingredient.lowercased().count)) * 100)
                 */
                 
                 let regexString = self.matchRegexProducts(string: string, array: [concent.ingredient,String(describing: concent.ingredientValue)])
                 let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
                 return result + " " + last
                 }.trimmingCharacters(in: .whitespaces)
                 guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                 let range = NSRange(location: 0, length: appended.utf16.count)
                 
                 let mostPercentage = self.getHighPriorityObject(string: string.lowercased(), ingredient: concent.ingredient.lowercased())
                 let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
                 
                 return regex.firstMatch(in: appended, options: [], range: range) != nil || string.lowercased().contains(concent.ingredient.lowercased()) || mostPercentage >= 50.0
                 
                 }
                 
                 if ingredientColl.count != 0{
                 
                 let ingreVal = product.concentration.filter { (concent) -> Bool in
                 
                 let regexString = self.matchRegexProducts(string: string, array: [String(describing: concent.ingredientValue), product.concentrationType])
                 let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
                 return result + " " + last
                 }.trimmingCharacters(in: .whitespaces)
                 guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                 let range = NSRange(location: 0, length: appended.utf16.count)
                 
                 let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
                 
                 return regex.firstMatch(in: appended, options: [], range: range) != nil || string.lowercased().contains(String(describing: concent.ingredientValue).lowercased())
                 
                 }
                 
                 if ingreVal.count != 0{
                 
                 return true
                 
                 }else{
                 return false
                 }
                 
                 }else{
                 
                 return false
                 
                 }
                 
                 
                 }
                 
                 if conKeyProduct.count != 0{
                 
                 let presentKey = conKeyProduct.filter { (product) -> Bool in
                 return string.lowercased().contains(product.presentationKey.lowercased())
                 }
                 
                 if presentKey.count != 0 {
                 return presentKey.first!
                 }else{
                 return conKeyProduct.first!
                 }
                 
                 }else{
                 return conTypeProduct.first!
                 }
                 
                 */
                
                if let product = self.getPerfectProductFilter(conTypeProduct: conTypeProduct, string: string){
                    return product
                }else{
                    
                    //                    let product = conTypeProduct.first!
                    //                    product.speechtext = "it is \(product.name). But we could not identify the concentration and presentation"
                    //
                    //                    return product
                    
                    return nil
                    
                }
                
                /*
                 if let product = self.getAverageIngredientProductFilter(conTypeProduct: conTypeProduct, string: string){
                 return product
                 }
                 
                 if let product = self.getAverageIngredientValueProductFilter(conTypeProduct: conTypeProduct, string: string){
                 return product
                 }
                 
                 if let product = self.getAveragePresentationProductFilter(conTypeProduct: conTypeProduct, string: string){
                 return product
                 }
                 
                 
                 if let product = self.getAverageIngredientandValueProductFilter(conTypeProduct: conTypeProduct, string: string){
                 return product
                 }
                 
                 if let product = self.getAverageIngredientandPresentationProductFilter(conTypeProduct: conTypeProduct, string: string){
                 return product
                 }
                 
                 if let product = self.getAverageIngredientValueandPresentationProductFilter(conTypeProduct: conTypeProduct, string: string){
                 return product
                 }
                 
                 if let product = self.getAverageFilter(conTypeProduct: conTypeProduct, string: string){
                 return product
                 }
                 */
                
            }else{
                
                return nil
                //return getMatchingHighProduct.first!
            }
            
            //return nil
            
        }else{
            return nil
        }
        
    }
    
    func getHighPercentageProduct(string: String) -> [ProductDetails]? {
        
        var matchedKeyWords = [String: Double]()
        
        
        for productName in global.productKeyWords {
            
            let stringArray = string.components(separatedBy: "\n")
            
            var matchedSeparatorKeyWords = [String: Double]()
            
            
            for seperatedString in stringArray {
                
                if seperatedString != "" && seperatedString != " " {
                    
                    
                    //var sepCharArray = Array(seperatedString)
                    
                    let editDistance = seperatedString.lowercased().levenshtein(productName)
                    
                    matchedSeparatorKeyWords[seperatedString] = (Double(productName.count) - Double(editDistance))/Double(productName.count) * 100
                    
                    
                }
            }
            
            let matSepKeySorted = matchedSeparatorKeyWords.sorted { (arg0, arg1) -> Bool in
                
                return arg0.value > arg1.value
                
            }
            
            matchedKeyWords[productName] = matSepKeySorted.first?.value
            
        }
        
        
        let matchedKeyWordsSorted = matchedKeyWords.sorted { (arg0, arg1) -> Bool in
            return arg0.value > arg1.value
        }
        
        if matchedKeyWordsSorted.count != 0{
            
            //global.proudctList[matchedKeyWordsSorted.first!.key]
            
            return matchedKeyWordsSorted.first!.value >= 50.0 ? global.proudctList[matchedKeyWordsSorted.first!.key] : nil
        }else{
            return nil
        }
        
    }
    
    /*
     func getHighPercentageProduct(string: String) -> [ProductDetails]? {
     
     var matchedKeyWords = [String: Double]()
     
     
     for productName in global.productKeyWords {
     
     let stringArray = string.components(separatedBy: "\n")
     
     var matchedSeparatorKeyWords = [String: Double]()
     
     
     for seperatedString in stringArray {
     
     if seperatedString != "" && seperatedString != " " {
     
     var percentage = 0
     
     //var sepCharArray = Array(seperatedString)
     
     
     let marchCharCount = self.getMatchingCharsFromProduct(string: string, productName: productName)
     
     let mergedProCount = marchCharCount.reduce(0) { (result, next) -> Int in
     return result + Int(next.count)
     }
     //for proChar in Array(productName){
     for proChar in marchCharCount{
     
     /*
     sepCharArray: for (index,sepChar) in sepCharArray.enumerated() {
     
     if sepChar == proChar {
     
     percentage += 1
     sepCharArray.remove(at: index)
     break sepCharArray
     
     }
     
     }
     */
     
     if seperatedString.contains(proChar) {
     percentage += proChar.count
     }
     
     //matchedSeparatorKeyWords[seperatedString] =
     
     
     }
     if Double(percentage) != 0 {
     matchedSeparatorKeyWords[seperatedString] = Double(percentage)/Double(mergedProCount)*100.0
     }
     
     }
     }
     
     let matSepKeySorted = matchedSeparatorKeyWords.sorted { (arg0, arg1) -> Bool in
     
     return arg0.value > arg1.value
     
     }
     
     matchedKeyWords[productName] = matSepKeySorted.first?.value
     
     }
     
     
     let matchedKeyWordsSorted = matchedKeyWords.sorted { (arg0, arg1) -> Bool in
     return arg0.value > arg1.value
     }
     
     if matchedKeyWordsSorted.count != 0{
     
     //global.proudctList[matchedKeyWordsSorted.first!.key]
     
     return matchedKeyWordsSorted.first!.value > 50.0 ? global.proudctList[matchedKeyWordsSorted.first!.key] : nil
     }else{
     return nil
     }
     
     }
     */
    
    func getHighPriorityObject(string: String, ingredient: String) -> Double {
        //for productName in global.productKeyWords {
        
        let stringArray = string.components(separatedBy: "\n")
        
        var matchedSeparatorKeyWords = [String: Double]()
        
        
        for seperatedString in stringArray {
            
            if seperatedString != "" && seperatedString != " " {
                
                
                //var sepCharArray = Array(seperatedString)
                
                let editDistance = seperatedString.levenshtein(ingredient)
                
                matchedSeparatorKeyWords[seperatedString] = (Double(ingredient.count) - Double(editDistance))/Double(ingredient.count) * 100
                
                
            }
        }
        
        let matSepKeySorted = matchedSeparatorKeyWords.sorted { (arg0, arg1) -> Bool in
            
            return arg0.value > arg1.value
            
        }
        
        return matSepKeySorted.first?.value ?? 0.0
        
        //}
        
        
        //        let matchedKeyWordsSorted = matchedKeyWords.sorted { (arg0, arg1) -> Bool in
        //            return arg0.value > arg1.value
        //        }
    }
    
    func getMatchingCharsFromProduct(string: String, productName: String) -> [String] {
        var charInct = 2
        var startIndex = 2
        var charIndex = 0
        let productStr = productName
        let productStrArray = Array(productStr)
        
        var stringArray = [String]()
        
        
        for index in stride(from: (productStr.count - 1), to: 0, by: -1) {
            print(index)
            
            for overLoopIndex in 0..<index {
                print("bnv=",overLoopIndex)
                var appendedStr = ""
                for inVal1 in charIndex..<charInct {
                    appendedStr = appendedStr + String(productStrArray[inVal1])
                    
                }
                print("added=",appendedStr)
                stringArray.append(appendedStr)
                charInct += 1
                charIndex += 1
            }
            
            startIndex += 1
            charInct = startIndex
            charIndex = 0
            
        }
        return stringArray
    }
    
    func matchRegexProducts(string: String, array: [String]) -> String {
        
        var regexPattern = ""
        
        if array.count == 1 {
            
            regexPattern = ".*" + array.first! + ".*"
            
        }else{
            
            
            
            for (index,value) in array.enumerated() {
                
                if index == array.count-1{
                    
                    regexPattern += value
                    regexPattern = regexPattern + ".*"
                    
                }else{
                    
                    regexPattern = ".*" + value + ".*"
                    
                }
                
                
                
            }
            
        }
        
        return regexPattern
        
        
    }
    
    func getConcentrationAppendedProbability(ingredientValue: String, type: String) -> [String] {
        /*
         var addedConcentration = [String]()
         
         addedConcentration.append(ingredientValue.lowercased())
         
         addedConcentration.append(ingredientValue.lowercased() + type.lowercased())
         
         return addedConcentration
         */
        
        var addedConcentration = [String]()
        
        let regexIngredientTypeIncludedCon = ".*" + ingredientValue.lowercased() + ".*" + type.lowercased() + ".*"
        
        //let regexIngredientTypeIncludedCon = "[\\n\\s]{1,}" + ingredientValue.lowercased() + ".*" + type.lowercased() + ".*"
        
        let regexIngredientType = ingredientValue.lowercased()
        //let regexIngredientType = ".*" + ingredientValue.lowercased() + ".*"
        
        addedConcentration.append(regexIngredientTypeIncludedCon)
        
        addedConcentration.append(regexIngredientType)
        
        return addedConcentration
        
    }
    
    func getConcentrationAccurateAppendedProbability(ingredientValue: String, type: String) -> [String] {
        /*
         var addedConcentration = [String]()
         
         addedConcentration.append(ingredientValue.lowercased())
         
         addedConcentration.append(ingredientValue.lowercased() + type.lowercased())
         
         return addedConcentration
         */
        
        var addedConcentration = [String]()
        
        //let regexIngredientTypeIncludedCon = ".*" + ingredientValue.lowercased() + ".*" + type.lowercased() + ".*"
        
        let regexIngredientTypeIncludedCon = "[\\n\\s]{1,}" + ingredientValue.lowercased() + ".*" + type.lowercased() + ".*"
        
        let regexIngredientType = ingredientValue.lowercased()
        //let regexIngredientType = ".*" + ingredientValue.lowercased() + ".*"
        
        addedConcentration.append(regexIngredientTypeIncludedCon)
        
        addedConcentration.append(regexIngredientType)
        
        return addedConcentration
        
    }
    
    /*
     
     func getConcentrationAppendedProbability(ingredientValue: String, type: String) -> [String] {
     /*
     var addedConcentration = [String]()
     
     addedConcentration.append(ingredientValue.lowercased())
     
     addedConcentration.append(ingredientValue.lowercased() + type.lowercased())
     
     return addedConcentration
     */
     
     var addedConcentration = [String]()
     
     let regexIngredient = ".*" + ingredientValue.lowercased() + ".*"
     
     addedConcentration.append(regexIngredient)
     
     let regexIngredientType = ".*" + ingredientValue.lowercased() + ".*" + type.lowercased() + ".*"
     
     addedConcentration.append(regexIngredientType)
     
     return addedConcentration
     
     }
     */
    
    func getPerfectProductFilter(conTypeProduct: [ProductDetails], string: String) -> ProductDetails? {
        
        let conProductFilterByIngredient = conTypeProduct.filter { (product) -> Bool in
            
            let conKeyConcentration = product.concentration.filter { (concentration) -> Bool in
                
                let concenKeyArray = concentration.ingredient.filter { (key) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: key.components(separatedBy: " "))
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return string.lowercased().contains(key.lowercased()) || checkIfContained
                    
                }
                
                if concenKeyArray.count > 0{
                   return true
                }else{
                   return false
                }
                
            }
            
            if conKeyConcentration.count == product.concentration.count {
                return true
            }else{
                return false
            }
            
        }
        
        
        if conProductFilterByIngredient.count != 0{
            
            let conProductFilterByIngredientValue = conProductFilterByIngredient.filter { (product) -> Bool in
                
                let conCentrationValue = product.concentration.filter { (concentration) -> Bool in
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + "  " + last}.trimmingCharacters(in: .whitespaces)
                    
                    let seperateBy = appended.components(separatedBy: "  ")
                    
                    let conArray = self.getConcentrationAppendedProbability(ingredientValue: String(describing: concentration.ingredientValue).lowercased(), type: product.concentrationType)
                    
                    
                    let checkIfExistCon = seperateBy.filter { (value) -> Bool in
                        
                        //                        let seperateBySlash = value.components(separatedBy: "/").filter { (value1) -> Bool in
                        //                            return conArray.contains(value1)
                        //                        }
                        //
                        //                        return conArray.contains(value.lowercased()) || seperateBySlash.count != 0
                        
                        /*
                         
                         let seperateBySlash = conArray.filter { (conValueRegex) -> Bool in
                         guard let regex = try? NSRegularExpression(pattern: conValueRegex, options: .caseInsensitive) else { return false }
                         let range = NSRange(location: 0, length: value.utf16.count)
                         
                         let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                         return checkIfContained
                         }
                         */
                        
                        
                        
                        //                        guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                        //                        let range = NSRange(location: 0, length: appended.utf16.count)
                        //
                        //                        let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                        
                        let availAnyMatchingCon = conArray.filter { (conVal) -> Bool in
                            
                            if conVal.contains(product.concentrationType){
                            
                            guard let regex = try? NSRegularExpression(pattern: conVal, options: .caseInsensitive) else { return false }
                            let range = NSRange(location: 0, length: value.utf16.count)
                            
                            let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                            return checkIfContained
                            }else{
                            return value.range(of: "\\b\(conVal)\\b", options: .regularExpression) != nil
                            
                            }
                            
                        }
                        
                        if availAnyMatchingCon.count > 0{
                            return true
                        }else{
                            return false
                        }
                        
                        
                    }
                    
                    
                    
                    if checkIfExistCon.count != 0{
                        return true
                    }else{
                        return false
                    }
                    //return string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    
                }
                
                
                if conCentrationValue.count == product.concentration.count {
                    return true
                }else{
                    return false
                }
                
            }
            
            if conProductFilterByIngredientValue.count != 0{
                
                let conProductFilterByPresentation = conProductFilterByIngredientValue.filter { (product) -> Bool in
                    
                    
                    let regexString = self.matchRegexProducts(string: string, array: product.presentation.components(separatedBy: " "))
                    
                    let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    //let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    
                }
                
                if conProductFilterByPresentation.count != 0 {
                    
                    
                    if conProductFilterByPresentation.count == 1 {
                        return conProductFilterByPresentation.first
                    }else{
                       let accurateProduct = self.getAccurateProductFilter(conTypeProduct: conProductFilterByPresentation, string: string)
                        if accurateProduct == nil {
                           return conProductFilterByPresentation.first
                        }else{
                           return accurateProduct
                        }
                    }
                }else{
                    //                    let product = conTypeProduct.first!
                    //
                    //                    let appendedIngredient = product.concentration.reduce("") { (result, next) -> String in
                    //                        return result + " " + (next.ingredient + String(describing: next.ingredientValue))
                    //                    }
                    //
                    //                    product.speechtext = "it is \(product.name). and \(appendedIngredient). But we could not identify the presentation"
                    //
                    //                    return product
                    
                    return nil
                }
                /*
                 else{
                 
                 let conProductFilterByPresentationPercentage = conProductFilterByIngredientValue.filter { (product) -> Bool in
                 
                 
                 return self.getHighPriorityObject(string: string, ingredient: product.presentation) >= 50.0
                 
                 
                 }
                 
                 if conProductFilterByPresentationPercentage.count != 0{
                 return conProductFilterByPresentationPercentage.first
                 }
                 
                 }
                 
                 */
                
                
                
            }else{
                
                //                let product = conTypeProduct.first!
                //
                //                let appendedIngredient = product.concentration.reduce("") { (result, next) -> String in
                //                    return result + " " + next.ingredient
                //                }
                //
                //                product.speechtext = "it is \(product.name). and \(product.name) has \(appendedIngredient) But we could not identify the Ingrdient values and presentation"
                //
                //                return product
                
                return nil
                
            }
            
        }else{
            
            //            let product = conTypeProduct.first!
            //
            //            product.speechtext = "it is \(product.name). But we could not identify the concentration and presentation"
            //
            //            return product
            
            return nil
            
        }
        
        
        
    }
    
    
    func getAccurateProductFilter(conTypeProduct: [ProductDetails], string: String) -> ProductDetails? {
            
            let conProductFilterByIngredientValue = conTypeProduct.filter { (product) -> Bool in
                
                let conCentrationValue = product.concentration.filter { (concentration) -> Bool in
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + "  " + last}.trimmingCharacters(in: .whitespaces)
                    
                    let seperateBy = appended.components(separatedBy: "  ")
                    
                    let conArray = self.getConcentrationAccurateAppendedProbability(ingredientValue: String(describing: concentration.ingredientValue).lowercased(), type: product.concentrationType)
                    
                    
                    let checkIfExistCon = seperateBy.filter { (value) -> Bool in
                        
                        let availAnyMatchingCon = conArray.filter { (conVal) -> Bool in
                            
                            if conVal.contains(product.concentrationType){
                            
                            guard let regex = try? NSRegularExpression(pattern: conVal, options: .caseInsensitive) else { return false }
                            let range = NSRange(location: 0, length: value.utf16.count)
                            
                            let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                            return checkIfContained
                            }else{
                            return value.range(of: "\\b\(conVal)\\b", options: .regularExpression) != nil
                            
                            }
                            
                        }
                        
                        if availAnyMatchingCon.count > 0{
                            return true
                        }else{
                            return false
                        }
                        
                        
                    }
                    
                    
                    
                    if checkIfExistCon.count != 0{
                        return true
                    }else{
                        return false
                    }
                    //return string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    
                }
                
                
                if conCentrationValue.count == product.concentration.count {
                    return true
                }else{
                    return false
                }
                
            }
            
            if conProductFilterByIngredientValue.count != 0{
                
                let conProductFilterByPresentation = conProductFilterByIngredientValue.filter { (product) -> Bool in
                    
                    
                    let regexString = self.matchRegexProducts(string: string, array: product.presentation.components(separatedBy: " "))
                    
                    let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    //let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    
                }
                
                if conProductFilterByPresentation.count != 0 {
                    
                    return conProductFilterByPresentation.first
                    
                }else{
                    
                    return nil
                }
                
            }else{
                
                return nil
                
            }
            
        
        
    }
    
    func getAveragePresentationProductFilter(conTypeProduct: [ProductDetails], string: String) -> ProductDetails? {
        
        let conProductFilterByIngredient = conTypeProduct.filter { (product) -> Bool in
            
            let conKeyConcentration = product.concentration.filter { (concentration) -> Bool in
                /*
                let regexString = self.matchRegexProducts(string: string, array: concentration.ingredient.components(separatedBy: " "))
                
                let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                    return result + " " + last
                }.trimmingCharacters(in: .whitespaces)
                guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                let range = NSRange(location: 0, length: appended.utf16.count)
                
                let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                
                return string.lowercased().contains(concentration.ingredient.lowercased()) || checkIfContained
                
                */
                
                let concenKeyArray = concentration.ingredient.filter { (key) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: key.components(separatedBy: " "))
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return string.lowercased().contains(key.lowercased()) || checkIfContained
                    
                }
                
                if concenKeyArray.count > 0{
                   return true
                }else{
                   return false
                }
                
            }
            
            if conKeyConcentration.count == product.concentration.count {
                return true
            }else{
                return false
            }
            
        }
        
        
        if conProductFilterByIngredient.count != 0{
            
            let conProductFilterByIngredientValue = conProductFilterByIngredient.filter { (product) -> Bool in
                
                let conCentrationValue = product.concentration.filter { (concentration) -> Bool in
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + "  " + last}.trimmingCharacters(in: .whitespaces)
                    
                    let seperateBy = appended.components(separatedBy: "  ")
                    
                    let conArray = self.getConcentrationAppendedProbability(ingredientValue: String(describing: concentration.ingredientValue).lowercased(), type: product.concentrationType)
                    
                    
                    let checkIfExistCon = seperateBy.filter { (value) -> Bool in
                        
//                        guard let regex = try? NSRegularExpression(pattern: conArray, options: .caseInsensitive) else { return false }
//                        let range = NSRange(location: 0, length: value.utf16.count)
//
//                        let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
//                        return checkIfContained
                        
                        let availAnyMatchingCon = conArray.filter { (conVal) -> Bool in
                            
                            guard let regex = try? NSRegularExpression(pattern: conVal, options: .caseInsensitive) else { return false }
                            let range = NSRange(location: 0, length: value.utf16.count)
                            
                            let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                            return checkIfContained
                            
                        }
                        
                        if availAnyMatchingCon.count > 0{
                            return true
                        }else{
                            return false
                        }
                        
                        //return conArray.contains(value.lowercased())
                    }
                    
                    if checkIfExistCon.count != 0{
                        return true
                    }else{
                        return false
                    }
                    //return string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    
                }
                
                if conCentrationValue.count == product.concentration.count{
                    return true
                }else{
                    return false
                }
                
            }
            
            if conProductFilterByIngredientValue.count != 0{
                
                let conProductFilterByPresentation = conProductFilterByIngredientValue.filter { (product) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: product.presentation.components(separatedBy: " "))
                    
                    let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    //let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    
                }
                
                if conProductFilterByPresentation.count != 0 {
                    
                    return conProductFilterByPresentation.first
                    
                }
                    
                else{
                    
                    let conProductFilterByPresentationPercentage = conProductFilterByIngredientValue.filter { (product) -> Bool in
                        
                        
                        return self.getHighPriorityObject(string: string, ingredient: product.presentation) >= 50.0
                        
                        
                    }
                    
                    if conProductFilterByPresentationPercentage.count != 0{
                        return conProductFilterByPresentationPercentage.first
                    }
                    
                }
                
                
                
            }else{
                
            }
            
        }
        
        return nil
        
    }
    
    func getAverageIngredientValueProductFilter(conTypeProduct: [ProductDetails], string: String) -> ProductDetails? {
        
        let conProductFilterByIngredient = conTypeProduct.filter { (product) -> Bool in
            
            let conKeyConcentration = product.concentration.filter { (concentration) -> Bool in
                /*
                let regexString = self.matchRegexProducts(string: string, array: concentration.ingredient.components(separatedBy: " "))
                
                let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                    return result + " " + last
                }.trimmingCharacters(in: .whitespaces)
                guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                let range = NSRange(location: 0, length: appended.utf16.count)
                
                let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                
                return string.lowercased().contains(concentration.ingredient.lowercased()) || checkIfContained
                */
                
                let concenKeyArray = concentration.ingredient.filter { (key) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: key.components(separatedBy: " "))
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return string.lowercased().contains(key.lowercased()) || checkIfContained
                    
                }
                
                if concenKeyArray.count > 0{
                   return true
                }else{
                   return false
                }
                
            }
            
            if conKeyConcentration.count == product.concentration.count {
                return true
            }else{
                return false
            }
            
        }
        
        
        if conProductFilterByIngredient.count != 0{
            
            let conProductFilterByIngredientValue = conProductFilterByIngredient.filter { (product) -> Bool in
                
                let conCentrationValue = product.concentration.filter { (concentration) -> Bool in
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + "  " + last}.trimmingCharacters(in: .whitespaces)
                    
                    let seperateBy = appended.components(separatedBy: "  ")
                    
                    let conArray = self.getConcentrationAppendedProbability(ingredientValue: String(describing: concentration.ingredientValue).lowercased(), type: product.concentrationType)
                    
                    
                    let checkIfExistCon = seperateBy.filter { (value) -> Bool in
                        /*
                        guard let regex = try? NSRegularExpression(pattern: conArray, options: .caseInsensitive) else { return false }
                        let range = NSRange(location: 0, length: value.utf16.count)
                        
                        let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                        return checkIfContained
                        */
                        
                        let availAnyMatchingCon = conArray.filter { (conVal) -> Bool in
                            
                            guard let regex = try? NSRegularExpression(pattern: conVal, options: .caseInsensitive) else { return false }
                            let range = NSRange(location: 0, length: value.utf16.count)
                            
                            let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                            return checkIfContained
                            
                        }
                        
                        if availAnyMatchingCon.count > 0{
                            return true
                        }else{
                            return false
                        }
                        
                        
                        //return conArray.contains(value.lowercased())
                    }
                    //|| string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    if checkIfExistCon.count != 0 {
                        return true
                    }else{
                        return false
                    }
                    //return string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    
                }
                
                if conCentrationValue.count == product.concentration.count{
                    return true
                }else{
                    return false
                }
                
            }
            
            if conProductFilterByIngredientValue.count != 0{
                
                let conProductFilterByPresentation = conProductFilterByIngredientValue.filter { (product) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: product.presentation.components(separatedBy: " "))
                    
                    let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    //let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    
                }
                
                if conProductFilterByPresentation.count != 0 {
                    
                    return conProductFilterByPresentation.first
                    
                }
                    
                else{
                    
                    let conProductFilterByPresentationPercentage = conProductFilterByIngredientValue.filter { (product) -> Bool in
                        
                        
                        return self.getHighPriorityObject(string: string, ingredient: product.presentation) >= 50.0
                        
                        
                    }
                    
                    if conProductFilterByPresentationPercentage.count != 0{
                        return conProductFilterByPresentationPercentage.first
                    }
                    
                }
                
                
                
            }else{
                
            }
            
        }
        
        return nil
        
    }
    
    func getAverageIngredientProductFilter(conTypeProduct: [ProductDetails], string: String) -> ProductDetails? {
        
        let conProductFilterByIngredient = conTypeProduct.filter { (product) -> Bool in
            
            let conKeyConcentration = product.concentration.filter { (concentration) -> Bool in
                /*
                let regexString = self.matchRegexProducts(string: string, array: concentration.ingredient.components(separatedBy: " "))
                
                let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                    return result + " " + last
                }.trimmingCharacters(in: .whitespaces)
                guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                let range = NSRange(location: 0, length: appended.utf16.count)
                
                let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                
                return string.lowercased().contains(concentration.ingredient.lowercased()) || checkIfContained || getHighPriorityObject(string: string, ingredient: concentration.ingredient) >= 50.0
                
                */
                
                let concenKeyArray = concentration.ingredient.filter { (key) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: key.components(separatedBy: " "))
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                   // return string.lowercased().contains(key.lowercased()) || checkIfContained
                    
                    return string.lowercased().contains(key.lowercased()) || checkIfContained || getHighPriorityObject(string: string, ingredient: key) >= 50.0
                    
                }
                
                if concenKeyArray.count > 0{
                   return true
                }else{
                   return false
                }
                
            }
            
            if conKeyConcentration.count != 0 {
                return true
            }else{
                return false
            }
            
        }
        
        
        if conProductFilterByIngredient.count != 0{
            
            let conProductFilterByIngredientValue = conProductFilterByIngredient.filter { (product) -> Bool in
                
                let conCentrationValue = product.concentration.filter { (concentration) -> Bool in
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + "  " + last}.trimmingCharacters(in: .whitespaces)
                    
                    let seperateBy = appended.components(separatedBy: "  ")
                    
                    let conArray = self.getConcentrationAppendedProbability(ingredientValue: String(describing: concentration.ingredientValue).lowercased(), type: product.concentrationType)
                    
                    
                    let checkIfExistCon = seperateBy.filter { (value) -> Bool in
                        /*
                        guard let regex = try? NSRegularExpression(pattern: conArray, options: .caseInsensitive) else { return false }
                        let range = NSRange(location: 0, length: value.utf16.count)
                        
                        let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                        return checkIfContained
                        //return conArray.contains(value.lowercased())
                        */
                        let availAnyMatchingCon = conArray.filter { (conVal) -> Bool in
                            
                            guard let regex = try? NSRegularExpression(pattern: conVal, options: .caseInsensitive) else { return false }
                            let range = NSRange(location: 0, length: value.utf16.count)
                            
                            let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                            return checkIfContained
                            
                        }
                        
                        if availAnyMatchingCon.count > 0{
                            return true
                        }else{
                            return false
                        }
                    }
                    
                    // || string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    
                    if checkIfExistCon.count != 0 {
                        return true
                    }else{
                        return false
                    }
                    //return string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    
                }
                if conCentrationValue.count == product.concentration.count{
                    //if conCentrationValue.count != 0{
                    return true
                }else{
                    return false
                }
                
            }
            
            if conProductFilterByIngredientValue.count != 0{
                
                let conProductFilterByPresentation = conProductFilterByIngredientValue.filter { (product) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: product.presentation.components(separatedBy: " "))
                    
                    let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    //let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    
                }
                
                if conProductFilterByPresentation.count != 0 {
                    
                    return conProductFilterByPresentation.first
                    
                }
                
                //                else{
                //
                //                    let conProductFilterByPresentationPercentage = conProductFilterByIngredientValue.filter { (product) -> Bool in
                //
                //
                //                        return self.getHighPriorityObject(string: string, ingredient: product.presentation) >= 50.0
                //
                //
                //                    }
                //
                //                    if conProductFilterByPresentationPercentage.count != 0{
                //                       return conProductFilterByPresentationPercentage.first
                //                    }
                //
                //                }
                
                
                
            }else{
                
            }
            
        }
        
        return nil
        
    }
    
    func getAverageIngredientandValueProductFilter(conTypeProduct: [ProductDetails], string: String) -> ProductDetails? {
        
        let conProductFilterByIngredient = conTypeProduct.filter { (product) -> Bool in
            
            let conKeyConcentration = product.concentration.filter { (concentration) -> Bool in
                /*
                let regexString = self.matchRegexProducts(string: string, array: concentration.ingredient.components(separatedBy: " "))
                
                let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                    return result + " " + last
                }.trimmingCharacters(in: .whitespaces)
                guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                let range = NSRange(location: 0, length: appended.utf16.count)
                
                let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                
                return string.lowercased().contains(concentration.ingredient.lowercased()) || checkIfContained || getHighPriorityObject(string: string, ingredient: concentration.ingredient) >= 50.0
                */
                
                let concenKeyArray = concentration.ingredient.filter { (key) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: key.components(separatedBy: " "))
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                   // return string.lowercased().contains(key.lowercased()) || checkIfContained
                    
                    return string.lowercased().contains(key.lowercased()) || checkIfContained || getHighPriorityObject(string: string, ingredient: key) >= 50.0
                    
                }
                
                if concenKeyArray.count > 0{
                   return true
                }else{
                   return false
                }
                
            }
            
            if conKeyConcentration.count != 0 {
                return true
            }else{
                return false
            }
            
        }
        
        
        if conProductFilterByIngredient.count != 0{
            
            let conProductFilterByIngredientValue = conProductFilterByIngredient.filter { (product) -> Bool in
                
                let conCentrationValue = product.concentration.filter { (concentration) -> Bool in
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + "  " + last}.trimmingCharacters(in: .whitespaces)
                    
                    let seperateBy = appended.components(separatedBy: "  ")
                    
                    let conArray = self.getConcentrationAppendedProbability(ingredientValue: String(describing: concentration.ingredientValue).lowercased(), type: product.concentrationType)
                    
                    
                    let checkIfExistCon = seperateBy.filter { (value) -> Bool in
                        /*
                        guard let regex = try? NSRegularExpression(pattern: conArray, options: .caseInsensitive) else { return false }
                        let range = NSRange(location: 0, length: value.utf16.count)
                        
                        let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                        return checkIfContained
                        //return conArray.contains(value.lowercased())
                        */
                        let availAnyMatchingCon = conArray.filter { (conVal) -> Bool in
                            
                            guard let regex = try? NSRegularExpression(pattern: conVal, options: .caseInsensitive) else { return false }
                            let range = NSRange(location: 0, length: value.utf16.count)
                            
                            let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                            return checkIfContained
                            
                        }
                        
                        if availAnyMatchingCon.count > 0{
                            return true
                        }else{
                            return false
                        }
                    }
                    
                    if checkIfExistCon.count != 0 || string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased()) || self.getHighPriorityObject(string: string, ingredient: String(describing: concentration.ingredientValue).lowercased()) >= 50.0 {
                        return true
                    }else{
                        return false
                    }
                    //return string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    
                }
                if conCentrationValue.count == product.concentration.count{
                    //if conCentrationValue.count != 0{
                    return true
                }else{
                    return false
                }
                
            }
            
            if conProductFilterByIngredientValue.count != 0{
                
                let conProductFilterByPresentation = conProductFilterByIngredientValue.filter { (product) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: product.presentation.components(separatedBy: " "))
                    
                    let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    //let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    
                }
                
                if conProductFilterByPresentation.count != 0 {
                    
                    return conProductFilterByPresentation.first
                    
                }
                    
                else{
                    
                    let conProductFilterByPresentationPercentage = conProductFilterByIngredientValue.filter { (product) -> Bool in
                        
                        
                        return self.getHighPriorityObject(string: string, ingredient: product.presentation) >= 50.0
                        
                        
                    }
                    
                    if conProductFilterByPresentationPercentage.count != 0{
                        return conProductFilterByPresentationPercentage.first
                    }
                    
                }
                
                
                
            }else{
                
            }
            
        }
        
        return nil
        
    }
    
    func getAverageIngredientandPresentationProductFilter(conTypeProduct: [ProductDetails], string: String) -> ProductDetails? {
        
        let conProductFilterByIngredient = conTypeProduct.filter { (product) -> Bool in
            
            let conKeyConcentration = product.concentration.filter { (concentration) -> Bool in
                /*
                let regexString = self.matchRegexProducts(string: string, array: concentration.ingredient.components(separatedBy: " "))
                
                let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                    return result + " " + last
                }.trimmingCharacters(in: .whitespaces)
                guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                let range = NSRange(location: 0, length: appended.utf16.count)
                
                let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                
                return string.lowercased().contains(concentration.ingredient.lowercased()) || checkIfContained || getHighPriorityObject(string: string, ingredient: concentration.ingredient) >= 50.0
                */
                let concenKeyArray = concentration.ingredient.filter { (key) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: key.components(separatedBy: " "))
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                   // return string.lowercased().contains(key.lowercased()) || checkIfContained
                    
                    return string.lowercased().contains(key.lowercased()) || checkIfContained || getHighPriorityObject(string: string, ingredient: key) >= 50.0
                    
                }
                
                if concenKeyArray.count > 0{
                   return true
                }else{
                   return false
                }
                
            }
            
            if conKeyConcentration.count != 0 {
                return true
            }else{
                return false
            }
            
        }
        
        
        if conProductFilterByIngredient.count != 0{
            
            let conProductFilterByIngredientValue = conProductFilterByIngredient.filter { (product) -> Bool in
                
                let conCentrationValue = product.concentration.filter { (concentration) -> Bool in
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + "  " + last}.trimmingCharacters(in: .whitespaces)
                    
                    let seperateBy = appended.components(separatedBy: "  ")
                    
                    let conArray = self.getConcentrationAppendedProbability(ingredientValue: String(describing: concentration.ingredientValue).lowercased(), type: product.concentrationType)
                    
                    
                    let checkIfExistCon = seperateBy.filter { (value) -> Bool in
                        /*
                        guard let regex = try? NSRegularExpression(pattern: conArray, options: .caseInsensitive) else { return false }
                        let range = NSRange(location: 0, length: value.utf16.count)
                        
                        let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                        return checkIfContained
                        //return conArray.contains(value.lowercased())
                        */
                        let availAnyMatchingCon = conArray.filter { (conVal) -> Bool in
                            
                            guard let regex = try? NSRegularExpression(pattern: conVal, options: .caseInsensitive) else { return false }
                            let range = NSRange(location: 0, length: value.utf16.count)
                            
                            let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                            return checkIfContained
                            
                        }
                        
                        if availAnyMatchingCon.count > 0{
                            return true
                        }else{
                            return false
                        }
                    }
                    
                    // || string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    
                    if checkIfExistCon.count != 0 {
                        return true
                    }else{
                        return false
                    }
                    //return string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    
                }
                if conCentrationValue.count == product.concentration.count{
                    //if conCentrationValue.count != 0{
                    return true
                }else{
                    return false
                }
                
            }
            
            if conProductFilterByIngredientValue.count != 0{
                
                let conProductFilterByPresentation = conProductFilterByIngredientValue.filter { (product) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: product.presentation.components(separatedBy: " "))
                    
                    let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    //let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    
                }
                
                if conProductFilterByPresentation.count != 0 {
                    
                    return conProductFilterByPresentation.first
                    
                }
                    
                else{
                    
                    let conProductFilterByPresentationPercentage = conProductFilterByIngredientValue.filter { (product) -> Bool in
                        
                        
                        return self.getHighPriorityObject(string: string, ingredient: product.presentation) >= 50.0
                        
                        
                    }
                    
                    if conProductFilterByPresentationPercentage.count != 0{
                        return conProductFilterByPresentationPercentage.first
                    }
                    
                }
                
                
                
            }else{
                
            }
            
        }
        
        return nil
        
    }
    
    func getAverageIngredientValueandPresentationProductFilter(conTypeProduct: [ProductDetails], string: String) -> ProductDetails? {
        
        let conProductFilterByIngredient = conTypeProduct.filter { (product) -> Bool in
            
            let conKeyConcentration = product.concentration.filter { (concentration) -> Bool in
                /*
                let regexString = self.matchRegexProducts(string: string, array: concentration.ingredient.components(separatedBy: " "))
                
                let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                    return result + " " + last
                }.trimmingCharacters(in: .whitespaces)
                guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                let range = NSRange(location: 0, length: appended.utf16.count)
                
                let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                
                return string.lowercased().contains(concentration.ingredient.lowercased()) || checkIfContained
                */
                let concenKeyArray = concentration.ingredient.filter { (key) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: key.components(separatedBy: " "))
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return string.lowercased().contains(key.lowercased()) || checkIfContained
                    
                }
                
                if concenKeyArray.count > 0{
                   return true
                }else{
                   return false
                }
                
            }
            
            if conKeyConcentration.count == product.concentration.count {
                return true
            }else{
                return false
            }
            
        }
        
        
        if conProductFilterByIngredient.count != 0{
            
            let conProductFilterByIngredientValue = conProductFilterByIngredient.filter { (product) -> Bool in
                
                let conCentrationValue = product.concentration.filter { (concentration) -> Bool in
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + "  " + last}.trimmingCharacters(in: .whitespaces)
                    
                    let seperateBy = appended.components(separatedBy: "  ")
                    
                    let conArray = self.getConcentrationAppendedProbability(ingredientValue: String(describing: concentration.ingredientValue).lowercased(), type: product.concentrationType)
                    
                    
                    let checkIfExistCon = seperateBy.filter { (value) -> Bool in
                        
                        /*
                        guard let regex = try? NSRegularExpression(pattern: conArray, options: .caseInsensitive) else { return false }
                        let range = NSRange(location: 0, length: value.utf16.count)
                        
                        let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                        return checkIfContained
                        //return conArray.contains(value.lowercased())
                        */
                        let availAnyMatchingCon = conArray.filter { (conVal) -> Bool in
                            
                            guard let regex = try? NSRegularExpression(pattern: conVal, options: .caseInsensitive) else { return false }
                            let range = NSRange(location: 0, length: value.utf16.count)
                            
                            let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                            return checkIfContained
                            
                        }
                        
                        if availAnyMatchingCon.count > 0{
                            return true
                        }else{
                            return false
                        }
                    }
                    
                    if checkIfExistCon.count != 0 || string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased()) || self.getHighPriorityObject(string: string, ingredient: String(describing: concentration.ingredientValue).lowercased()) >= 50.0  {
                        return true
                    }else{
                        return false
                    }
                    //return string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    
                }
                
                if conCentrationValue.count == product.concentration.count{
                    return true
                }else{
                    return false
                }
                
            }
            
            if conProductFilterByIngredientValue.count != 0{
                
                let conProductFilterByPresentation = conProductFilterByIngredientValue.filter { (product) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: product.presentation.components(separatedBy: " "))
                    
                    let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    //let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    
                }
                
                if conProductFilterByPresentation.count != 0 {
                    
                    return conProductFilterByPresentation.first
                    
                }
                    
                else{
                    
                    let conProductFilterByPresentationPercentage = conProductFilterByIngredientValue.filter { (product) -> Bool in
                        
                        
                        return self.getHighPriorityObject(string: string, ingredient: product.presentation) >= 50.0
                        
                        
                    }
                    
                    if conProductFilterByPresentationPercentage.count != 0{
                        return conProductFilterByPresentationPercentage.first
                    }
                    
                }
                
                
                
            }else{
                
            }
            
        }
        
        return nil
        
    }
    
    func getAverageFilter(conTypeProduct: [ProductDetails], string: String) -> ProductDetails? {
        
        let conProductFilterByIngredient = conTypeProduct.filter { (product) -> Bool in
            
            let conKeyConcentration = product.concentration.filter { (concentration) -> Bool in
                /*
                let regexString = self.matchRegexProducts(string: string, array: concentration.ingredient.components(separatedBy: " "))
                
                let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                    return result + " " + last
                }.trimmingCharacters(in: .whitespaces)
                guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                let range = NSRange(location: 0, length: appended.utf16.count)
                
                let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                
                return string.lowercased().contains(concentration.ingredient.lowercased()) || checkIfContained || getHighPriorityObject(string: string, ingredient: concentration.ingredient) >= 50.0
                */
                let concenKeyArray = concentration.ingredient.filter { (key) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: key.components(separatedBy: " "))
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    let checkIfContained = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                   // return string.lowercased().contains(key.lowercased()) || checkIfContained
                    
                    return string.lowercased().contains(key.lowercased()) || checkIfContained || getHighPriorityObject(string: string, ingredient: key) >= 50.0
                    
                }
                
                if concenKeyArray.count > 0{
                   return true
                }else{
                   return false
                }
                
            }
            
            if conKeyConcentration.count != 0 {
                return true
            }else{
                return false
            }
            
        }
        
        
        if conProductFilterByIngredient.count != 0{
            
            let conProductFilterByIngredientValue = conProductFilterByIngredient.filter { (product) -> Bool in
                
                let conCentrationValue = product.concentration.filter { (concentration) -> Bool in
                    
                    let appended = string.lowercased().components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + "  " + last}.trimmingCharacters(in: .whitespaces)
                    
                    let seperateBy = appended.components(separatedBy: "  ")
                    
                    let conArray = self.getConcentrationAppendedProbability(ingredientValue: String(describing: concentration.ingredientValue).lowercased(), type: product.concentrationType)
                    
                    
                    let checkIfExistCon = seperateBy.filter { (value) -> Bool in
                        /*
                        guard let regex = try? NSRegularExpression(pattern: conArray, options: .caseInsensitive) else { return false }
                        let range = NSRange(location: 0, length: value.utf16.count)
                        
                        let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                        return checkIfContained
                        //return conArray.contains(value.lowercased())
                        */
                        let availAnyMatchingCon = conArray.filter { (conVal) -> Bool in
                            
                            guard let regex = try? NSRegularExpression(pattern: conVal, options: .caseInsensitive) else { return false }
                            let range = NSRange(location: 0, length: value.utf16.count)
                            
                            let checkIfContained = regex.firstMatch(in: value, options: [], range: range) != nil
                            return checkIfContained
                            
                        }
                        
                        if availAnyMatchingCon.count > 0{
                            return true
                        }else{
                            return false
                        }
                    }
                    
                    // || string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    
                    if checkIfExistCon.count != 0 || string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased()) || self.getHighPriorityObject(string: string, ingredient: String(describing: concentration.ingredientValue).lowercased()) >= 50.0  {
                        return true
                    }else{
                        return false
                    }
                    //return string.lowercased().contains(String(describing: concentration.ingredientValue).lowercased())
                    
                }
                if conCentrationValue.count == product.concentration.count{
                    //if conCentrationValue.count != 0{
                    return true
                }else{
                    return false
                }
                
            }
            
            if conProductFilterByIngredientValue.count != 0{
                
                let conProductFilterByPresentation = conProductFilterByIngredientValue.filter { (product) -> Bool in
                    
                    let regexString = self.matchRegexProducts(string: string, array: product.presentation.components(separatedBy: " "))
                    
                    let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
                        return result + " " + last
                    }.trimmingCharacters(in: .whitespaces)
                    guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
                    let range = NSRange(location: 0, length: appended.utf16.count)
                    
                    //let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    return regex.firstMatch(in: appended, options: [], range: range) != nil
                    
                    
                }
                
                if conProductFilterByPresentation.count != 0 {
                    
                    return conProductFilterByPresentation.first
                    
                }
                    
                else{
                    
                    let conProductFilterByPresentationPercentage = conProductFilterByIngredientValue.filter { (product) -> Bool in
                        
                        
                        return self.getHighPriorityObject(string: string, ingredient: product.presentation) >= 50.0
                        
                        
                    }
                    
                    if conProductFilterByPresentationPercentage.count != 0{
                        return conProductFilterByPresentationPercentage.first
                    }
                    
                }
                
                
                
            }else{
                
            }
            
        }
        
        return nil
        
    }
    
    /*
     func checkConcentrationKeyPercentage(string: String, product: [ProductDetails])-> [ProductDetails]? {
     
     
     }
     */
    
    /*
     //®
     func checkIfProductNotFound(string: String) -> ProductDetails? {
     /*
     for (_,allProductDetails) in global.proudctList {
     
     let conTypeKey = allProductDetails.filter { (productDetails) -> Bool in
     return (string.contains(productDetails.concentrationType) && string.contains(productDetails.concentrationKey))
     }
     
     if conTypeKey.count != 0 {
     
     }else{
     
     }
     
     }
     */
     
     if let getMatchingHighProduct = self.getHighPercentageProduct(string: string){
     
     let conTypeProduct = getMatchingHighProduct.filter({ (product) -> Bool in
     return string.lowercased().contains(product.concentrationType.lowercased())
     })
     
     if conTypeProduct.count != 0 {
     /*
     let conKeyProduct = conTypeProduct.filter { (product) -> Bool in
     return string.contains(product.concentrationKey)
     }
     */
     
     let conKeyProduct = conTypeProduct.filter { (product) -> Bool in
     
     let ingredientColl = product.concentration.filter { (concent) -> Bool in
     /*
     let mostPercentage = Double((Double(concent.ingredient.lowercased().count - string.lowercased().levenshtein(concent.ingredient.lowercased()))/Double(concent.ingredient.lowercased().count)) * 100)
     */
     
     let regexString = self.matchRegexProducts(string: string, array: [concent.ingredient,String(describing: concent.ingredientValue)])
     let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
     return result + " " + last
     }.trimmingCharacters(in: .whitespaces)
     guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
     let range = NSRange(location: 0, length: appended.utf16.count)
     
     let mostPercentage = self.getHighPriorityObject(string: string.lowercased(), ingredient: concent.ingredient.lowercased())
     let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
     
     return regex.firstMatch(in: appended, options: [], range: range) != nil || string.lowercased().contains(concent.ingredient.lowercased()) || mostPercentage >= 50.0
     
     }
     
     if ingredientColl.count != 0{
     
     let ingreVal = product.concentration.filter { (concent) -> Bool in
     
     let regexString = self.matchRegexProducts(string: string, array: [String(describing: concent.ingredientValue), product.concentrationType])
     let appended = string.components(separatedBy: "\n").reduce("") { (result, last) -> String in
     return result + " " + last
     }.trimmingCharacters(in: .whitespaces)
     guard let regex = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive) else { return false }
     let range = NSRange(location: 0, length: appended.utf16.count)
     
     let acc = regex.firstMatch(in: appended, options: [], range: range) != nil
     
     return regex.firstMatch(in: appended, options: [], range: range) != nil || string.lowercased().contains(String(describing: concent.ingredientValue).lowercased())
     
     }
     
     if ingreVal.count != 0{
     
     return true
     
     }else{
     return false
     }
     
     }else{
     
     return false
     
     }
     
     
     }
     
     if conKeyProduct.count != 0{
     
     let presentKey = conKeyProduct.filter { (product) -> Bool in
     return string.lowercased().contains(product.presentationKey.lowercased())
     }
     
     if presentKey.count != 0 {
     return presentKey.first!
     }else{
     return conKeyProduct.first!
     }
     
     }else{
     return conTypeProduct.first!
     }
     
     }else{
     return getMatchingHighProduct.first!
     }
     
     }else{
     return nil
     }
     
     }
     */
}

extension String {
    subscript(index: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: index)]
    }
}

extension String {
    public func levenshtein(_ other: String) -> Int {
        let sCount = self.count
        //let sCount = other.count
        let oCount = other.count
        
        guard sCount != 0 else {
            return oCount
        }
        
        guard oCount != 0 else {
            return sCount
        }
        
        let line : [Int]  = Array(repeating: 0, count: oCount + 1)
        var mat : [[Int]] = Array(repeating: line, count: sCount + 1)
        
        for i in 0...sCount {
            mat[i][0] = i
        }
        
        for j in 0...oCount {
            mat[0][j] = j
        }
        
        for j in 1...oCount {
            for i in 1...sCount {
                if self[i - 1] == other[j - 1] {
                    mat[i][j] = mat[i - 1][j - 1]       // no operation
                }
                else {
                    let del = mat[i - 1][j] + 1         // deletion
                    let ins = mat[i][j - 1] + 1         // insertion
                    let sub = mat[i - 1][j - 1] + 1     // substitution
                    mat[i][j] = min(min(del, ins), sub)
                }
            }
        }
        
        return mat[sCount][oCount]
    }
}

extension CGPoint {
 func scaled(to size: CGSize) -> CGPoint {
  return CGPoint(x: self.x * size.width,y: self.y * size.height)
 }
}
