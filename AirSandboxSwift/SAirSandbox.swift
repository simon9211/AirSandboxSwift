//
//  SAirSandbox.swift
//  AirSandboxSwift
//
//  Created by xiwang wang on 2017/7/21.
//  Copyright © 2017年 xiwang wang. All rights reserved.
//

import UIKit

let ASThemeColor: UIColor = UIColor.init(white: 0.2, alpha: 1.0)

enum ASFileItemType {
    case ASFileItemNone
    case ASFileItemUp
    case ASFileItemDirectory
    case ASFileItemFile
}

struct ASFileItem {
    var name: String = ""
    var path: String = ""
    var type: ASFileItemType
    
    init(n: String, p:String, t:ASFileItemType) {
        name = n
        path = p
        type = t
    }
}

class SAirSandbox: NSObject {
    
    static let shareInstance = SAirSandbox()
    
    lazy var window: UIWindow = {
        let window = UIWindow()
        var keyFrame = UIScreen.main.bounds
        keyFrame.origin.y += 64
        keyFrame.origin.x += 20
        keyFrame.size.width -= 40
        keyFrame.size.height -= 100
        window.frame = keyFrame
        window.backgroundColor = UIColor.white
        window.layer.borderColor = ASThemeColor.cgColor
        window.layer.borderWidth = 2.0
        window.windowLevel = UIWindowLevelStatusBar
        return window
    }()
    
    lazy var ctrl: ASViewController = {
        let ctrl = ASViewController()
        return ctrl
    }()
    
    func enableSwip() {
        let pan = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeDetected))
        pan.numberOfTouchesRequired = 1
        pan.direction = .left
        UIApplication.shared.keyWindow?.addGestureRecognizer(pan)
    }
    
    @objc func onSwipeDetected(){
        window.rootViewController = ctrl
        window.isHidden = false
    }
    
}

class ASTableViewCell: UITableViewCell {
    var item: ASFileItem?
    private var didSelectCell: ((_ cell: ASTableViewCell) ->())?
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(ges:)))
        longPress.minimumPressDuration = 2.0
        contentView.addGestureRecognizer(longPress)
        
    }
    
    @objc func longPressAction(ges: UILongPressGestureRecognizer) {
        if (didSelectCell != nil) {
            didSelectCell!(self)
        }
    }
    
    ///select cell
    func didSelectCellClosure(closure:@escaping (_ cell: ASTableViewCell)->()) {
        didSelectCell = closure
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}

class ASViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    var items = [ASFileItem]()
    var rootPath: String = NSHomeDirectory()
    
    
    var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.white
        tableView.separatorStyle = .none
        return tableView
    }()
    
    var btnClose: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = ASThemeColor
        btn.setTitle("Close", for: .normal)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.addTarget(self, action: #selector(btnCloseClick(btn:)), for: .touchUpInside)
        return btn
    }()
    
    @objc func btnCloseClick(btn: UIButton) {
        view.window?.isHidden = true
    }
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        view.addSubview(btnClose)
        loadPath(filePath: "")
    }
    
    override func viewWillLayoutSubviews() {
        super .viewWillLayoutSubviews()
        
        let viewWidth: CGFloat = UIScreen.main.bounds.size.width - 2*20.0
        let closeWidth: CGFloat = 60
        let closeHeight: CGFloat = 28.0
        btnClose.frame = CGRect(x: viewWidth - closeWidth - 4, y: 4, width: closeWidth, height: closeHeight)
        
        var tableViewFrame = view.frame
        tableViewFrame.origin.y += (closeHeight + 4)
        tableViewFrame.size.height -= (closeHeight + 4)
        tableView.frame = tableViewFrame
        tableView.register(ASTableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    //MARK: - TableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ASTableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ASTableViewCell
        let fileItem = items[indexPath.row]
        cell.textLabel?.text = fileItem.name
        cell.item = fileItem
        
        cell.didSelectCellClosure { (longpressCell) in
            print("长按")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < items.count {
            let item = items[indexPath.row];
            switch item.type {
            case .ASFileItemUp:do {
                let strPath = item.path as NSString!
                loadPath(filePath: (strPath?.deletingLastPathComponent)! as String)
                }
                break
            case .ASFileItemFile:do {
                shareFile(filePath: item.path)
                }
                break
            case .ASFileItemDirectory:do {
                loadPath(filePath: item.path)
                }
                break
            default:
                break
            }
        }
    }
    
    //MARK -loadpath and share file
    private func loadPath(filePath: String) {
        var files = [ASFileItem]()
        let fileManager = FileManager.default
        var targetPath: String = filePath
        if targetPath.isEmpty || targetPath == rootPath {
            targetPath = rootPath
        } else {
            let file = ASFileItem(n: "🔙..", p: filePath, t: .ASFileItemUp)
            files.append(file)
        }
        
        var paths = [String]()
        
        do {
            try paths = fileManager.contentsOfDirectory(atPath: targetPath)
            
        } catch  {
            print(error.localizedDescription)
            //@throw NSException(name: NSExceptionName(rawValue: "ERROR"), reason: error.localizedDescription, userInfo: nil) as! Error
        }
        
        if (paths.count > 0) {
            for itemPath:String! in paths {
                if itemPath.hasPrefix(".") {
                    continue
                }
                
                var isDir: ObjCBool = ObjCBool(false)
                
                let fullPath = (targetPath as NSString!).appendingPathComponent(itemPath)
                //                fileManager.fileExists(atPath: fullPath)
                fileManager.fileExists(atPath: fullPath, isDirectory: &isDir)
                var file: ASFileItem = ASFileItem(n: "", p:"", t: .ASFileItemNone)
                file.path = fullPath
                if isDir.boolValue {
                    file.type = .ASFileItemDirectory
                    file.name = "📁" + itemPath
                } else {
                    file.type = .ASFileItemFile
                    file.name = "📃" + itemPath
                }
                files.append(file)
                print(itemPath);
            }
            items = files
            tableView.reloadData()
        }
    }
    
    func shareFile(filePath: String) {
        let url: NSURL = NSURL(fileURLWithPath: filePath)
        let objectToShare = [url]
        let controller: UIActivityViewController = UIActivityViewController(activityItems: objectToShare, applicationActivities: nil)
        
        let excludedActivities = [UIActivityType.postToTwitter, UIActivityType.postToFacebook,
                                  UIActivityType.postToWeibo,
                                  UIActivityType.message, UIActivityType.mail,
                                  UIActivityType.print, UIActivityType.copyToPasteboard,
                                  UIActivityType.assignToContact, UIActivityType.saveToCameraRoll,
                                  UIActivityType.addToReadingList, UIActivityType.postToFlickr,
                                  UIActivityType.postToVimeo, UIActivityType.postToTencentWeibo]
        controller.excludedActivityTypes = excludedActivities;
        
        if UIDevice.current.model.hasPrefix("iPad") {
            controller.popoverPresentationController?.sourceView = view
            controller.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.size.width * 0.5, y: UIScreen.main.bounds.size.height * 0.5, width: 10, height: 10)
            
        }
        self .present(controller, animated: true, completion: nil)
    }
}


