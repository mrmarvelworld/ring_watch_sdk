//
//  YcProductPlugin + WatchFace.swift
//  Pods
//
//  Created by LiuHuiYang on 2023/12/7.
//

import UIKit
import Flutter
import YCProductSDK


// MARK: - 玉成表盘
extension YcProductPlugin {
    
    
    /// 查询表盘信息
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func queryWatchFaceInfo(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        var datas = [[String: Any]]()
        
        YCProduct.queryWatchFaceInfo { state, response in
            
            let code = self.convertFlutterState(state)
            
            if state == .succeed,
               let info = response as? YCWatchFaceBreakCountInfo {
                
                for item in info.dials {
                    datas.append(
                        [
                            "dialID": item.dialID,
                            "blockCount": item.blockCount,
                            "isSupportDelete": item.isSupportDelete,
                            "version": item.version,
                            
                            "limitCount": info.limitCount,
                            "localCount": info.localCount,
                        ]
                    )
                }
            }
            
            result(["code": code, "data": datas])
            
        }
        
        // 杰理开启表盘系统
        if YCProduct.shared.currentPeripheral?.mcu == .jl701n {
            
//            YCProduct.openJLDialFileSystem { isSuccess in
                
                YCProduct.queryJLDeviceLocalWatchFaceInfo { isSuccess, dials, customDials in
                    
                    //                    debugPrint("=== \(dials)")
//                    debugPrint("=== \(customDials)")
                }
                
//            }
        }
    }
    
    /// 切换表盘
    /// - Parameters:
    ///   - arguments: arguments description
    ///   - result: <#result description#>
    public func changeWatchFace(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let dialID = arguments as? Int else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.changeWatchFace(
            dialID: UInt32(truncatingIfNeeded: dialID)
        ) { state, response in
            
            let code = self.convertFlutterState(state)
            result(["code": code, "data": ""])
        }
    }
    
    /// 删除表盘
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func deleteWatchFace(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let dialID = arguments as? Int else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.deleteWatchFace(
            dialID: UInt32(truncatingIfNeeded: dialID)
        ) { state, response in
            
            let code = self.convertFlutterState(state)
            result(["code": code, "data": ""])
        }
    }
    
    /// 下载表盘
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func installWatchFace(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let list = arguments as? [Any],
              list.count >= 5
        else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        guard let isEnable = list[0] as? Bool,
              let dialID = list[1] as? Int,
              let blockCount = list[2] as? Int,
              let dialVersion = list[3] as? Int,
              let filePath = list[4] as? String,
              let data = NSData(contentsOfFile: filePath) else {
            
            result(["code": PluginState.failed,
                    "data": ""]
            )
            
            return
        }
        
        
        YCProduct.downloadWatchFace(
            isEnable: isEnable,
            data: data, dialID: UInt32(truncatingIfNeeded: dialID),
            blockCount: UInt16(truncatingIfNeeded: blockCount),
            dialVersion: UInt16(truncatingIfNeeded: dialVersion)
        ) { state, response in
            
            
            let code = self.convertFlutterState(state)
            
            if state == .succeed,
               let info = response as? YCDownloadProgressInfo {
                
                let progressInfo = [
                    "code": DeviceUpdateState.installingWatchFace.rawValue,
                    "progress": String(format: "%.2f", info.progress),
                    "error": "",
                ] as [String : Any]
                
                YcProductPlugin.methodChannel?.invokeMethod(
                    "upgradeState",
                    arguments: progressInfo
                )
                
                if info.progress < 1.0 {
                    return
                }
            }
            
            result(["code": code, "data": ""])
        }
        
    }
    
    
    /// 查询自定义表盘的信息
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func queryDeviceCustomWatchFaceInfo(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let filePath = arguments as? String,
              let data = NSData(contentsOfFile: filePath)
        else {
            
            result(["code": PluginState.failed,
                    "data": ""]
            )
            
            return
        }
        
        let info =  YCProduct.queryDeviceBmpInfo(data as Data)
        
        result(
            [
                "code": PluginState.succeed,
                "data": [
                    "size": info.size,
                    "width": info.width,
                    "height": info.height,
                    "radius": info.radius,
                    
                    "thumbnailSize": info.thumbnailSize,
                    "thumbnailWidth": info.thumbnailWidth,
                    "thumbnailHeight": info.thumbnailHeight,
                    "thumbnailRadius": info.thumbnailRadius,
                ]
            ]
        )
    }
    
    
    /// 下载自定义表盘
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func installCustomWatchFace(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let list = arguments as? [Any],
              list.count >= 9,
              
              let dialID = list[0] as? Int,
              let filePath = list[1] as? String,
              let backgroundImagePath = list[2] as? String,
              let thumbnailPath = list[3] as? String,
              let timeX = list[4] as? Int,
              let timeY = list[5] as? Int,
              let redColor = list[6] as? Int,
              let greenColor = list[7] as? Int,
              let blueColor = list[8] as? Int,
              
                let dialData = NSData(contentsOfFile: filePath)
                
        else {
            
            result(
                [
                    "code": PluginState.failed,
                    "data": ""
                ]
            )
            
            return
        }
         
        let bgImage = UIImage(contentsOfFile: backgroundImagePath)
        let thumbnail = UIImage(contentsOfFile: thumbnailPath)
  
        let newDialData =
        YCProduct.generateCustomDialData(
            dialData as Data,
            backgroundImage: bgImage,
            thumbnail: thumbnail,
            timePosition: CGPoint(x: timeX, y: timeY),
            redColor: UInt8(truncatingIfNeeded: redColor),
            greenColor: UInt8(truncatingIfNeeded: greenColor),
            blueColor: UInt8(truncatingIfNeeded: blueColor),
            isFlipColor: YCProduct.shared.currentPeripheral?.supportItems.isFlipCustomDialColor ?? false
        )
        
        // 删除表盘
        YCProduct.deleteWatchFace(dialID: UInt32(dialID)
        ) { state, response in
            
            YCProduct.downloadWatchFace(
                isEnable: true,
                data: newDialData as NSData,
                dialID: UInt32(dialID),
                blockCount: 0,
                dialVersion: 0
            ) { state, response in
                
                let code = self.convertFlutterState(state)
                
                if state == .succeed,
                   let info = response as? YCDownloadProgressInfo {
                    
                    let progressInfo = [
                        "code": DeviceUpdateState.installingWatchFace.rawValue,
                        "progress": String(format: "%.2f", info.progress),
                        "error": "",
                    ] as [String : Any]
                    
                    YcProductPlugin.methodChannel?.invokeMethod(
                        "upgradeState",
                        arguments: progressInfo
                    )
                    
                    if info.progress < 1.0 {
                        return
                    }
                }
                
                result(["code": code, "data": ""])
                
            }
        }
        
        
    }
}



// MARK: - 杰理表盘
extension YcProductPlugin {
    
    /// 切换表盘
    /// - Parameters:
    ///   - arguments: arguments description
    ///   - result: <#result description#>
    public func changeJieLiWatchFace(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let watchName = arguments as? String else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        
        YCProduct.settingJLDeviceWatchFace(watchName) { isSuccess in
            let code =
            isSuccess ? PluginState.succeed : PluginState.failed
            
            result(["code": code, "data": ""])
        }
    }
    
    /// 删除表盘
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func deleteJieLiWatchFace(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let watchName = arguments as? String else {
            result(["code": PluginState.failed,
                    "data": ""]
            )
            return
        }
        
        YCProduct.deleteJLDeviceWatchFace(watchName) { isSuccess in
            
            let code =
            isSuccess ? PluginState.succeed : PluginState.failed
            
            result(["code": code, "data": ""])
        }
    }
    
    
    /// 下载杰理表盘
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func installJieLiWatchFace(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let list = arguments as? [String],
              let watchName = list.first,
              let filePath = list.last,
              let data = NSData(contentsOfFile: filePath) else {
            
            result(["code": PluginState.failed,
                    "data": ""]
            )
            
            return
        }
        
        YCProduct.installJLDeviceWatchFace(watchName.uppercased(), dialData: data as Data) { state, progress in
            
            if state == .success {
                
                result(["code": PluginState.succeed,
                        "data": ""]
                )
                
            } else if state == .installing {
                
                let progressInfo = [
                    "code": DeviceUpdateState.installingWatchFace.rawValue,
                    "progress": String(format: "%.2f", progress),
                    "error": "",
                ] as [String : Any]
                
                YcProductPlugin.methodChannel?.invokeMethod(
                    "upgradeState",
                    arguments: progressInfo
                )
                
            } else {
                
                result(["code": PluginState.failed,
                        "data": ""]
                )
            }
        }
        
    }
    
    
    /// 查询设备参数
    /// - Parameters:
    ///   - call.arguments: <#call.arguments description#>
    ///   - result: <#result description#>
    public func queryDeviceDisplayParametersInfo(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        YCProduct.queryDeviceDisplayParameters { state, response in
            guard state == .succeed,
                  let info = response as? YCDeviceDisplayParametersInfo,
                  info.filletRadiusPixels > 0 else {
                
                result(["code": PluginState.failed,
                        "data": ""]
                )
                
                return
            }
            
            result([
                "code": PluginState.succeed,
                "data": [
                    "screenType": info.screenType.rawValue,
                    "widthPixels": info.widthPixels,
                    "heightPixels": info.heightPixels,
                    "filletRadiusPixels": info.filletRadiusPixels,
                    "thumbnailWidthPixels": info.thumbnailWidthPixels,
                    "thumbnailHeightPixels": info.thumbnailHeightPixels,
                    "thumbnailRadiusPixels": info.thumbnailRadiusPixels,
                ]
            ])
        }
    }
    
    
    
    /// 安装杰理自定义表盘
    /// - Parameters:
    ///   - arguments: <#arguments description#>
    ///   - result: <#result description#>
    public func installJieLiCustomWatchFace(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        
        guard let list = arguments as? [Any],
              list.count >= 11,
              let watchName = list[0] as? String,
              let backgroundPath = list[1] as? String,
              let backgroundImageWidth = list[2] as? Int,
              let backgroundImageHeight = list[3] as? Int,
              let filletRadiusPixels = list[4] as? Int,
              
              let thumbnailPath = list[5] as? String,
              let thumbnailWidth = list[6] as? Int,
              let thumbnailHeight = list[7] as? Int,
              let thumbnailRadiusPixels = list[8] as? Int,
                
              let timePosition = list[9] as? Int,
              let timeTextColor = list[10] as? Int,
              
                let backgroundImage = UIImage(contentsOfFile: backgroundPath),
              let thumbnail = UIImage(contentsOfFile: thumbnailPath),
              
                let timeLocation = YCDeviceFaceTimePosition(rawValue: UInt8(timePosition))
                
        else {
            
            result(["code": PluginState.failed,
                    "data": ""]
            )
            
            return
        }
        
        
        // 尺寸
        let backgroundImageSize =
            CGSize(width: Double(backgroundImageWidth),
                     height: Double(backgroundImageHeight)
                )
        
        let thumbnailSize =
            CGSize(width: Double(thumbnailWidth),
                     height: Double(thumbnailHeight)
            )
        
        YCProduct.convertJLCustomWatchFaceInfo(
            watchName,
            backgroundImage: backgroundImage,
            size: backgroundImageSize,
            completion: { customWatchName, dialData in
                
                YCProduct.convertJLCustomThumbnail(
                    watchName,
                    image: thumbnail,
                    size: thumbnailSize
                ) { thumbnailName, thumbnailData in
                    
                    YCProduct.installJLDeviceWatchFace(
                        customWatchName,
                        dialData: dialData ?? Data()
                    ) { state, progress in
                        
                        if state == .success {
                        
                            YCProduct.installJLDeviceWatchFace(
                                thumbnailName,
                                dialData: thumbnailData ?? Data()
                            ) { state, progress in
                                
                                if state == .success {
                                     
                                    YCProduct.setJLCustomDialParameter(
                                        timeLocation: timeLocation,
                                        fontColor: UInt16(timeTextColor)
                                    ) { state, response in
                                        
                                         
                                        YCProduct.settingJLDeviceWatchFace(watchName) { isSuccess in
                                            
                                            result(["code": isSuccess ? PluginState.succeed : PluginState.failed,
                                                    "data": ""]
                                            )
                                        }
                                    }
                                    
                                } else if state == .installing {
                                    
                                    let thumbnailProgress =
                                    progress * 0.4 + 0.6
                                    
                                    let progressInfo = [
                                        "code": DeviceUpdateState.installingWatchFace.rawValue,
                                        "progress": String(format: "%.2f", thumbnailProgress),
                                        "error": "",
                                    ] as [String : Any]
                                    
                                    YcProductPlugin.methodChannel?.invokeMethod(
                                        "upgradeState",
                                        arguments: progressInfo
                                    )
                                    
                                } else {
                                    
                                    result(["code": PluginState.failed,
                                            "data": ""]
                                    )
                                }
                            }
                            
                        } else if state == .installing {
                            
                            let customProgress = progress * 0.6
                            
                            let progressInfo = [
                                "code": DeviceUpdateState.installingWatchFace.rawValue,
                                "progress": String(format: "%.2f", customProgress),
                                "error": "",
                            ] as [String : Any]
                            
                            YcProductPlugin.methodChannel?.invokeMethod(
                                "upgradeState",
                                arguments: progressInfo
                            )
                            
                        } else {
                            
                            result(["code": PluginState.failed,
                                    "data": ""]
                            )
                        }
                        
                    }
                }
                
            })
        
    }

    // 发送图片到杰理设备
    public func writeImageToJLDevice(
        _ arguments: Any?,
        result: @escaping FlutterResult
    ) {
        guard let argsList = arguments as? [Any], argsList.count == 2 else {
                result([
                    "code": -1, // 失败码（可替换为你项目中的PluginState.failed.rawValue）
                    "data": "参数格式错误，必须传入[Data, String]格式的数组"
                ])
                return
            }
            
            // 解析第一个参数：图片二进制数据（Data）
            guard let imageData = argsList[0] as? Data else {
                result([
                    "code": -1,
                    "data": "第一个参数必须是图片二进制数据（Data类型）"
                ])
                return
            }
            
            // 解析第二个参数：文件名（String），默认值BGP_W111
            let fileName = (argsList[1] as? String) ?? "BGP_W111"
        YCProduct.writeImageToJLDevice(imageData: imageData,fileName: fileName) { progressValue in
            let progressResult = [
                            "code": 0,          // 进度标识码（可自定义，比如 1001 代表传输中）
                            "progress": progressValue, // 原始进度值（0~1）
                            "message": "传输中",
                            "isFinish": false   // 标记是否完成，方便Flutter区分进度/结果
                        ] as [String: Any]
                        // 实时返回进度给Flutter（Flutter侧会多次收到这个回调）
                        result(progressResult)
        } completion: { isSuccess, errorMsg in
            let finalResult = [
                            "code": isSuccess ? 1 : -1, // 1=成功，-1=失败
                            "progress": 1.0,            // 进度置为1（完成）
                            "message": isSuccess ? "图片写入成功" : (errorMsg ?? "图片写入失败"),
                            "isFinish": true            // 标记为最终结果
                        ] as [String: Any]
                        // 返回最终结果
                        result(finalResult)
        }

    }
    
}
