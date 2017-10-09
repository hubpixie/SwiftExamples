//
//  MainViewController.swift
//  CollectionView
//
//  Created by Andrea Prearo on 8/19/16.
//  Copyright © 2016 Andrea Prearo. All rights reserved.
//

import UIKit

class MainViewController: UICollectionViewController {
    enum ReadStateEnum {
        case none
        case reading
        case read
    }
    fileprivate static let sectionInsets = UIEdgeInsetsMake(0, 2, 0, 2)
    fileprivate let userViewModelController = UserViewModelController()
    fileprivate var firstLoaded: Bool = true
    fileprivate var indexPathsForReadStateStack: [IndexPath] = []
    fileprivate var totalReadStates: [ReadStateEnum] = []

    // Pre-Fetching Queue
    fileprivate let imageLoadQueue = OperationQueue()
    fileprivate var imageLoadOperations = [IndexPath: ImageLoadOperation]()
    fileprivate weak var timer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()

        #if CLEAR_CACHES
        let cachesFolderItems = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        for item in cachesFolderItems {
            try? FileManager.default.removeItem(atPath: item)
        }
        #endif

        if #available(iOS 10.0, *) {
            collectionView?.prefetchDataSource = self
        }
        userViewModelController.retrieveUsers { [weak self] (success, error) in
            guard let strongSelf = self else { return }
            if !success {
                DispatchQueue.main.async {
                    let title = "Error"
                    if let error = error {
                        strongSelf.showError(title, message: error.localizedDescription)
                    } else {
                        strongSelf.showError(title, message: NSLocalizedString("Can't retrieve contacts.", comment: "Can't retrieve contacts."))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    strongSelf.totalReadStates = Array(repeating: ReadStateEnum.none, count: strongSelf.userViewModelController.viewModelsCount)
                    strongSelf.collectionView?.reloadData()
                    strongSelf.timer = nil
                }
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] context in
            self?.collectionView?.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }
}

// MARK: UICollectionViewDataSource
extension MainViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userViewModelController.viewModelsCount
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCell", for: indexPath) as! UserCell

        if var viewModel = userViewModelController.viewModel(at: (indexPath as NSIndexPath).item) {
            viewModel.readState = (self.totalReadStates[indexPath.item] == ReadStateEnum.none ? false: true)
            cell.configure(viewModel)
            if let imageLoadOperation = imageLoadOperations[indexPath],
                let image = imageLoadOperation.image {
                cell.avatar.setRoundedImage(image)
            } else {
                let imageLoadOperation = ImageLoadOperation(url: viewModel.avatarUrl)
                imageLoadOperation.completionHandler = { [weak self] (image) in
                    guard let strongSelf = self else {
                        return
                    }
                    cell.avatar.setRoundedImage(image)
                    strongSelf.imageLoadOperations.removeValue(forKey: indexPath)
                }
                imageLoadQueue.addOperation(imageLoadOperation)
                imageLoadOperations[indexPath] = imageLoadOperation
            }
        }
        
        #if DEBUG_CELL_LIFECYCLE
        //print(String.init(format: "cellForRowAt #%i", indexPath.row))
        #endif
        
        return cell
    }

    #if DEBUG_CELL_LIFECYCLE
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if self.firstLoaded == false &&  self.navigationController?.isNavigationBarHidden == false {
            self.navigationController?.isNavigationBarHidden = true
        }
        if (self.collectionView?.indexPathsForVisibleItems.count)! % 2 == 0 {
                //do something after table is done loading
           // print("findReadStateOfCollectionView.1")
                self.findReadStateOfCollectionView()
        }
    }
    #endif

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        self.firstLoaded = false
        
        guard let imageLoadOperation = imageLoadOperations[indexPath] else {
            return
        }
        imageLoadOperation.cancel()
        imageLoadOperations.removeValue(forKey: indexPath)
        #if DEBUG_CELL_LIFECYCLE
        print(String.init(format: "didEndDisplaying #%i", indexPath.item))
        #endif
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let ipt: IndexPath? = self.collectionView?.indexPath(for: (self.collectionView?.visibleCells[0])!)
        if ipt != nil && (ipt?.item)! <= 2 {
            self.navigationController?.isNavigationBarHidden = false
        }
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView,
                                           willDecelerate decelerate: Bool) {
        self.findReadStateOfCollectionView()
    }
    
    func findReadStateOfCollectionView() {
        if self.timer != nil  {
            self.timer.invalidate()
        }
        for indexPath in (self.collectionView?.indexPathsForVisibleItems)! {
            if self.totalReadStates[indexPath.item] == ReadStateEnum.read {
                continue
            }
            if self.totalReadStates[indexPath.item] == ReadStateEnum.none {
                self.indexPathsForReadStateStack.append(indexPath)
            }
        }
        if self.timer == nil || !self.timer.isValid {
            self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.drawCellReadState), userInfo: nil, repeats: true)
        }
    }

    @objc func drawCellReadState() {
        //find be-read cells
        if (self.indexPathsForReadStateStack.isEmpty) {
            self.timer.invalidate()
            return
        }
        guard let offsetPoint: CGPoint = self.collectionView?.contentOffset else {
            return
        }
        DispatchQueue.main.async {
            for i in 0..<(self.totalReadStates.count) {
                if (self.totalReadStates[i] == ReadStateEnum.reading) {
                    let ipt: IndexPath = IndexPath(item: i, section: 0)
                    guard let cell :UserCell = self.collectionView?.cellForItem(at: ipt) as? UserCell else {
                        continue
                    }
                    guard let idx = self.indexPathsForReadStateStack.index(of: ipt) else {
                        continue
                    }
                    cell.readStateLabel.textColor = UIColor.gray
                    self.totalReadStates[i] = ReadStateEnum.read
                    self.indexPathsForReadStateStack.remove(at: idx)
                }
            }
            for _ in 0..<self.indexPathsForReadStateStack.count{
                guard let indexPath: IndexPath = self.indexPathsForReadStateStack.first else {
                    return
                }
                guard let cell: UserCell = self.collectionView?.cellForItem(at: indexPath) as? UserCell else {
                    self.indexPathsForReadStateStack.remove(at: 0)
                    continue
                }

                if cell.frame.origin.y - offsetPoint.y + cell.frame.size.height / 2 > self.view.bounds.size.height {
//                    print("drawCellReadState.A==cell height=\(cell.frame.origin.y, cell.frame.size.height, self.view.bounds.size.height), indexPath = \(indexPath)")
                    self.indexPathsForReadStateStack.remove(at: 0)
                    continue
                }

                cell.readStateLabel.text = "Read!"
                cell.readStateLabel.textColor = UIColor.brown
                self.totalReadStates[indexPath.item] = ReadStateEnum.reading
                self.indexPathsForReadStateStack.remove(at: 0)
            }
        }
    }
}


extension MainViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //print("scrollViewDidScroll")
    }
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("scrollViewDidEndScrollingAnimation")
    }
}

// MARK: UICollectionViewDelegateFlowLayout protocol methods
extension MainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let columns: Int = {
            var count = 2
            if traitCollection.horizontalSizeClass == .regular {
                count = count + 1
            }
            if collectionView.bounds.width > collectionView.bounds.height {
                count = count + 1
            }
            return count
        }()
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(columns - 1))
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(columns))
        return CGSize(width: size, height: 90)
    }
}

// MARK: UICollectionViewDataSourcePrefetching
extension MainViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            if let _ = imageLoadOperations[indexPath] {
                return
            }
            if let viewModel = userViewModelController.viewModel(at: indexPath.item) {
                let imageLoadOperation = ImageLoadOperation(url: viewModel.avatarUrl)
                imageLoadQueue.addOperation(imageLoadOperation)
                imageLoadOperations[indexPath] = imageLoadOperation
            }
            
            #if DEBUG_CELL_LIFECYCLE
           // print(String(format: "prefetchItemsAt #%i", indexPath.item))
            #endif
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let imageLoadOperation = imageLoadOperations[indexPath] else {
                return
            }
            imageLoadOperation.cancel()
            imageLoadOperations.removeValue(forKey: indexPath)
            
            #if DEBUG_CELL_LIFECYCLE
            //print(String(format: "cancelPrefetchingForItemsAt #%i", indexPath.item))
            #endif
        }
    }
}
