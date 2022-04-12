//
//  LocationAnnotationViewV2.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/21/22.
//

import UIKit
import MapKit
import SDWebImage

class LocationAnnotationViewV2: MKAnnotationView {
    
    // MARK: Initialization
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 35, height: 35)
        collisionMode = .circle
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var annotation: MKAnnotation? {
        didSet {
            if let annotation = annotation, let placeAnnotation = annotation as? PlaceAnnotationV2 {
                setupUI(for: placeAnnotation.pin)
            }
        }
    }
    
    // MARK: Setup
    
    private func setupUI(for pin: MapPinV3) {
        subviews.forEach({ $0.removeFromSuperview() })
        backgroundColor = .clear
        
        let view = UIView()
        view.frame = bounds
        
        var image: UIImageView
        if let url = pin.icon.iconUrl {
            image = UIImageView()
            let transformer = SDImageResizingTransformer(size: CGSize(width: 100, height: 100), scaleMode: .fill)
            image.sd_setImage(
                with: URL(string: url),
                placeholderImage: UIImage(systemName: "person.crop.circle"),
                context: [.imageTransformer: transformer])
            image.tintColor = UIColor(named: pin.icon.category?.lowercased() ?? "lightgray")
            image.backgroundColor = .white
            image.contentMode = .scaleAspectFill;
        } else {
            image = UIImageView(image: UIImage(systemName: "person.crop.circle"))
            image.tintColor = .gray
            image.backgroundColor = .white
        }
        let pinDiameter: CGFloat = 30
        image.frame = CGRect(x: 0, y: 0, width: pinDiameter, height: pinDiameter)
        image.layer.cornerRadius = pinDiameter / 2
        image.layer.masksToBounds = true
        image.layer.borderColor = UIColor(named: pin.icon.category?.lowercased() ?? "lightgray")?.cgColor
        image.layer.borderWidth = 2.5
        
        view.addSubview(image)
        
        if pin.icon.numPosts > 1 {
            let badge = UITextView()
            badge.isEditable = false
            badge.textContainerInset = UIEdgeInsets(top: 0.5, left: 3, bottom: 0, right: 3)
            badge.textContainer.lineFragmentPadding = 0
            badge.backgroundColor = UIColor(red: 0.11, green: 0.51, blue: 0.95, alpha: 1)
            badge.layer.masksToBounds = true
            badge.textColor = .white
            badge.textAlignment = .center
            badge.text = String(pin.icon.numPosts)
            badge.font = .systemFont(ofSize: 12, weight: .bold)
            badge.sizeToFit()
            badge.frame = CGRect(x: 0, y: 0, width: badge.frame.width + 1, height: badge.frame.height + 1)
            badge.layer.cornerRadius = min(badge.frame.height, badge.frame.width) / 2

            view.addSubview(badge)
            badge.center = CGPoint(x: view.frame.width - badge.frame.width / 2, y: badge.frame.height / 2)
        }
        
        addSubview(view)
    }
}
