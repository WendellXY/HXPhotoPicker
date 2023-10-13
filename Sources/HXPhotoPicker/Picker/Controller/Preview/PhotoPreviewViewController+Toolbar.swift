//
//  PhotoPreviewViewController+BottomView.swift
//  HXPhotoPicker
//
//  Created by Slience on 2021/8/6.
//

import UIKit

extension PhotoPreviewViewController {
    
    func openEditor(_ photoAsset: PhotoAsset) {
        guard let picker = pickerController else { return }
        let shouldEditAsset = picker.shouldEditAsset(
            photoAsset: photoAsset,
            atIndex: currentPreviewIndex
        )
        if !shouldEditAsset {
            return
        }
        #if HXPICKER_ENABLE_EDITOR && HXPICKER_ENABLE_PICKER
        beforeNavDelegate = navigationController?.delegate
        let pickerConfig = picker.config
        if photoAsset.mediaType == .video && pickerConfig.editorOptions.isVideo {
            let cell = getCell(
                for: currentPreviewIndex
            )
            cell?.scrollContentView.stopVideo()
            var videoEditorConfig = pickerConfig.editor
            let isExceedsTheLimit = picker.videoDurationExceedsTheLimit(
                photoAsset: photoAsset
            )
            if isExceedsTheLimit {
                videoEditorConfig.video.defaultSelectedToolOption = .time
                videoEditorConfig.video.cropTime.maximumTime = TimeInterval(
                    pickerConfig.maximumSelectedVideoDuration
                )
            }
            guard let videoEditorConfig = picker.shouldEditVideoAsset(
                videoAsset: photoAsset,
                editorConfig: videoEditorConfig,
                atIndex: currentPreviewIndex
            ) else {
                return
            }
            guard var videoEditorConfig = delegate?.previewViewController(
                self,
                shouldEditVideoAsset: photoAsset,
                editorConfig: videoEditorConfig
            ) else {
                return
            }
            videoEditorConfig.languageType = pickerConfig.languageType
            videoEditorConfig.indicatorType = pickerConfig.indicatorType
            videoEditorConfig.chartlet.albumPickerConfigHandler = { [weak self] in
                var pickerConfig: PickerConfiguration
                if let config = self?.pickerController?.config {
                    pickerConfig = config
                }else {
                    pickerConfig = .init()
                }
                pickerConfig.selectOptions = [.gifPhoto]
                pickerConfig.photoList.bottomView.isHiddenOriginalButton = true
                pickerConfig.previewView.bottomView.isHiddenOriginalButton = true
                pickerConfig.previewView.bottomView.isHiddenEditButton = true
                return pickerConfig
            }
            let videoEditorVC = EditorViewController(
                .init(
                    type: .photoAsset(photoAsset),
                    result: photoAsset.editedResult
                ),
                config: videoEditorConfig,
                delegate: self
            )
            switch pickerConfig.editorJumpStyle {
            case .push(let style):
                if style == .custom {
                    navigationController?.delegate = videoEditorVC
                }
                navigationController?.pushViewController(videoEditorVC, animated: true)
            case .present(let style):
                if style == .fullScreen {
                    videoEditorVC.modalPresentationStyle = .fullScreen
                }
                present(videoEditorVC, animated: true)
            }
        }else if pickerConfig.editorOptions.isPhoto {
            guard let photoEditorConfig = picker.shouldEditPhotoAsset(
                photoAsset: photoAsset,
                editorConfig: pickerConfig.editor,
                atIndex: currentPreviewIndex
            ) else {
                return
            }
            guard var photoEditorConfig = delegate?.previewViewController(
                self,
                shouldEditPhotoAsset: photoAsset,
                editorConfig: photoEditorConfig
            ) else {
                return
            }
            if photoAsset.mediaSubType == .livePhoto ||
               photoAsset.mediaSubType == .localLivePhoto {
                let cell = getCell(
                    for: currentPreviewIndex
                )
                cell?.scrollContentView.stopLivePhoto()
            }
            photoEditorConfig.languageType = pickerConfig.languageType
            photoEditorConfig.indicatorType = pickerConfig.indicatorType
            photoEditorConfig.chartlet.albumPickerConfigHandler = { [weak self] in
                var pickerConfig: PickerConfiguration
                if let config = self?.pickerController?.config {
                    pickerConfig = config
                }else {
                    pickerConfig = .init()
                }
                pickerConfig.selectOptions = [.photo]
                pickerConfig.photoList.bottomView.isHiddenOriginalButton = true
                pickerConfig.previewView.bottomView.isHiddenOriginalButton = true
                pickerConfig.previewView.bottomView.isHiddenEditButton = true
                return pickerConfig
            }
            let photoEditorVC = EditorViewController(
                .init(
                    type: .photoAsset(photoAsset),
                    result: photoAsset.editedResult
                ),
                config: photoEditorConfig,
                delegate: self
            )
            switch pickerConfig.editorJumpStyle {
            case .push(let style):
                if style == .custom {
                    navigationController?.delegate = photoEditorVC
                }
                navigationController?.pushViewController(photoEditorVC, animated: true)
            case .present(let style):
                if style == .fullScreen {
                    photoEditorVC.modalPresentationStyle = .fullScreen
                }
                present(photoEditorVC, animated: true)
            }
        }
        #endif
    }
    
    func didFinishClick() {
        guard let pickerController = pickerController else {
            return
        }
        if !pickerController.selectedAssetArray.isEmpty {
            delegate?.previewViewController(didFinishButton: self)
            pickerController.finishCallback()
            return
        }
        if assetCount == 0 {
            ProgressHUD.showWarning(
                addedTo: view,
                text: "没有可选资源".localized,
                animated: true,
                delayHide: 1.5
            )
            return
        }
        guard let photoAsset = photoAsset(for: currentPreviewIndex) else {
            return
        }
        #if HXPICKER_ENABLE_EDITOR
        if photoAsset.mediaType == .video &&
            pickerController.videoDurationExceedsTheLimit(photoAsset: photoAsset) &&
            pickerController.config.editorOptions.isVideo {
            if pickerController.canSelectAsset(
                for: photoAsset,
                showHUD: true
            ) {
                openEditor(photoAsset)
            }
            return
        }
        #endif
        func addAsset() {
            if !isMultipleSelect {
                if pickerController.canSelectAsset(
                    for: photoAsset,
                    showHUD: true
                ) {
                    if isExternalPickerPreview {
                        delegate?.previewViewController(
                            self,
                            didSelectBox: photoAsset,
                            isSelected: true,
                            updateCell: false
                        )
                    }
                    delegate?.previewViewController(didFinishButton: self)
                    pickerController.singleFinishCallback(
                        for: photoAsset
                    )
                }
            }else {
                if videoLoadSingleCell {
                    if pickerController.canSelectAsset(
                        for: photoAsset,
                        showHUD: true
                    ) {
                        if isExternalPickerPreview {
                            delegate?.previewViewController(
                                self,
                                didSelectBox: photoAsset,
                                isSelected: true,
                                updateCell: false
                            )
                        }
                        delegate?.previewViewController(didFinishButton: self)
                        pickerController.singleFinishCallback(
                            for: photoAsset
                        )
                    }
                }else {
                    if pickerController.addedPhotoAsset(
                        photoAsset: photoAsset
                    ) {
                        if isExternalPickerPreview {
                            delegate?.previewViewController(
                                self,
                                didSelectBox: photoAsset,
                                isSelected: true,
                                updateCell: false
                            )
                        }
                        delegate?.previewViewController(didFinishButton: self)
                        pickerController.finishCallback()
                    }
                }
            }
        }
        let inICloud = photoAsset.checkICloundStatus(
            allowSyncPhoto: pickerController.config.allowSyncICloudWhenSelectPhoto
        ) { _, isSuccess in
            if isSuccess {
                addAsset()
            }
        }
        if !inICloud {
            addAsset()
        }
    }
    
    func requestSelectedAssetFileSize() {
        pickerController?.requestSelectedAssetFileSize(isPreview: true, completion: { [weak self] in
            self?.photoToolbar.originalAssetBytes($0, bytesString: $1)
        })
    }
    
    func setupRequestPreviewTimer() {
        requestPreviewTimer?.invalidate()
        requestPreviewTimer = Timer(
            timeInterval: 0.2,
            target: self,
            selector: #selector(delayRequestPreview),
            userInfo: nil,
            repeats: false
        )
        RunLoop.main.add(
            requestPreviewTimer!,
            forMode: RunLoop.Mode.common
        )
    }
    @objc func delayRequestPreview() {
        if let cell = getCell(for: currentPreviewIndex) {
            cell.requestPreviewAsset()
            requestPreviewTimer = nil
        }else {
            if assetCount == 0 {
                requestPreviewTimer = nil
                return
            }
            setupRequestPreviewTimer()
        }
    }
    
    public func setOriginal(_ isOriginal: Bool) {
        photoToolbar.updateOriginalState(isOriginal)
        if !isOriginal {
            pickerController?.cancelRequestAssetFileSize(isPreview: true)
        }else {
            requestSelectedAssetFileSize()
        }
        pickerController?.isOriginal = isOriginal
        pickerController?.originalButtonCallback()
        delegate?.previewViewController(
            self,
            didOriginalButton: isOriginal
        )
    }
    
}