//
//  JimoPinView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/9/22.
//

import SDWebImage
import UIKit
import MapKit

enum PinState {
    case dot, regular
}

class JimoPinView: MKAnnotationView {
    private var pinState = PinState.regular
    private var pinDiameter: CGFloat = 25
    private var pinBorderWidth: CGFloat = 2

    private var width: CGFloat {
        pinDiameter + pinBorderWidth * 2
    }

    private var height: CGFloat {
        width
    }

    private lazy var view: UIView = {
        let view = UIView()
        view.frame = self.bounds
        return view
    }()

    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.frame = CGRect(x: 0, y: 0, width: pinDiameter, height: pinDiameter)
        image.layer.cornerRadius = pinDiameter / 2
        image.layer.masksToBounds = true
        image.layer.borderWidth = pinBorderWidth
        image.backgroundColor = .white
        return image
    }()

    private lazy var overlay: UIView = {
        let overlay = UIView()
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.frame = view.bounds
        overlay.alpha = 0.0
        overlay.layer.cornerRadius = overlay.frame.width / 2.0
        return overlay
    }()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
        frame = CGRect(x: 0, y: 0, width: width, height: height)
        addSubview(view)
        view.addSubview(imageView)
        view.addSubview(overlay)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        toPin()
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        guard let pin = annotation as? MKJimoPinAnnotation else {
            return
        }

        if let url = pin.imageUrl {
            let transformer = SDImageResizingTransformer(size: CGSize(width: pinDiameter * 3, height: pinDiameter * 3), scaleMode: .fill)
            imageView.sd_setImage(
                with: URL(string: url),
                placeholderImage: UIImage(systemName: "person.crop.circle"),
                context: [.imageTransformer: transformer])
            imageView.tintColor = UIColor(named: pin.category?.lowercased() ?? "lightgray")
            imageView.contentMode = .scaleAspectFill
        } else {
            imageView.image = UIImage(systemName: "person.crop.circle")
            imageView.tintColor = .gray
        }
        if let color = UIColor(named: pin.category?.lowercased() ?? "lightgray") {
            imageView.layer.borderColor = color.cgColor
        }
    }

    func toDot() {
        if self.pinState == .dot {
            return
        }
        overlay.backgroundColor = UIColor(named: (annotation as? MKJimoPinAnnotation)?.category ?? "lightgray")
        overlay.alpha = 1.0
        self.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        self.zPriority = .init(2.0)
        self.pinState = .dot
    }

    func toPin() {
        if self.pinState == .regular {
            return
        }
        overlay.alpha = 0.0
        self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        self.zPriority = .init(3.0 + Float((annotation as? MKJimoPinAnnotation)?.numPosts ?? 0))
        self.pinState = .regular
    }
}
