//
//  ViewController.swift
//  What Is This
//
//  Created by An Nguyen, Duy Nguyen on 5/17/20.
//  Copyright © 2020 Duy Nguyen. All rights reserved.
//

import SwiftyJSON
import Alamofire
import SDWebImage
import ColorThiefSwift
import UIKit
import CoreML
import Vision


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let model = MobileNet()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    var thisImage : UIImage?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        
        
    }
    
    
    @IBAction func cameraTapped(_ sender: Any) {
        
        self.present(self.imagePicker, animated: true, completion: nil)

    }

    
    func detect(objectImage: CIImage) {
        
        
        
        guard let model = try? VNCoreMLModel(for: model.model) else {
            fatalError("Could not load the model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let result = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not complete classfication")
            }
            
            let id = result.identifier
            
            var names = id.components(separatedBy: " ")
            
            names.removeFirst()
            
            let name = names.joined(separator: " ").components(separatedBy: ",")[0]
            //let name = names.components(separatedBy: ",")[0].capitalized
            
            self.navigationItem.title = name.capitalized//+ result.identifier.capitalized
            
            self.requestInfo(objectName: name)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: objectImage)
        
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
        
        
    }
    
    func requestInfo(objectName: String) {
        let parameters : [String:String] = ["format" : "json", "action" : "query", "prop" : "extracts|pageimages", "exintro" : "", "explaintext" : "", "titles" : objectName, "redirects" : "1", "pithumbsize" : "500", "indexpageids" : ""]
                
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                let objectJSON : JSON = JSON(response.result.value!)
                
                let pageid = objectJSON["query"]["pageids"][0].stringValue
                
                let objectDescription = objectJSON["query"]["pages"][pageid]["extract"].stringValue
                let objectImageURL = objectJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.infoLabel.text = objectDescription
                self.imageView.sd_setImage(with: URL(string: objectImageURL), completed: { (image, error,  cache, url) in
                    
                    if let currentImage = self.imageView.image {
                        
                        guard let dominantColor = ColorThief.getColor(from: currentImage) else {
                            fatalError("Could not get dominant color")
                        }
                        
                        
                        DispatchQueue.main.async {
                            self.navigationController?.navigationBar.isTranslucent = true
                            self.navigationController?.navigationBar.barTintColor = dominantColor.makeUIColor()
                            
                            
                        }
                    } else {
                        self.imageView.image = self.thisImage
                        self.infoLabel.text = "Could not get information on the object from Wikipedia."
                    }
                    
                })
                
            }
            else {
                print("Error \(String(describing: response.result.error))")
                self.infoLabel.text = "Connection Issues"
                
                
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        if let userPickedImage = info[.editedImage] as? UIImage {
            
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Error converting image to CIImage.")
            }
            
            thisImage = userPickedImage
            
            
            detect(objectImage: ciImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
        
        
    }
    
    
    
}

