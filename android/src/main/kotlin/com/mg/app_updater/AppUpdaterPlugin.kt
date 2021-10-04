package com.mg.app_updater

//import com.king.app.updater.AppUpdater
//import com.king.app.updater.callback.UpdateCallback
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel

/// 事件 tag
class EventTag {
    companion object {
        const val event = "event"
        const val value = "value"
    }
}

class Event {
    companion object {
        const val progress = "process"
        const val finish = "finish"
        const val cancel = "cancel"
        const val error = "error"
        const val start = "start"
        const val onDownloading = "onDownloading"
    }
}

class AppUpdaterPlugin : FlutterPlugin, EventChannel.StreamHandler {

//    private var updater: AppUpdater? = null

//    private val retryCount = 20
//
//    private var lastDownloadTag = 0

    private lateinit var channel: EventChannel

    private var downloadStatus: MutableMap<Int, DownloadStatus> = mutableMapOf()

    override fun onListen(p0: Any?, p1: EventChannel.EventSink?) {

//        lastDownloadTag += 1
//
//        // 給此次的下載一個標示
//        val currentTag = lastDownloadTag
//
//        downloadStatus[currentTag] = NONE
//
//        val url = p0.toString()
//        println("監聽到下載更新請求~~: $url")
//
//        // 如果當前是否有正在下載的, 停止
//        stopCurrentDownload()
//
//        // 啟動新的下載
//        startDownload(url, p1, currentTag)
//
//        // 迴圈 retryCount次 直到當前的tag狀態確實啟動下載
//        Thread(Runnable {
//            outer@ for (i in 0..retryCount) {
//                Thread.sleep(1000)
//                println("循環等待可以下載的時機")
//                if (lastDownloadTag == currentTag) {
//                    when (downloadStatus[currentTag]) {
//                        DOWNLOADING -> {
//                            // 已經開始下載, 不用再等待
//                            break@outer
//                        }
//                        END -> {
//                            // 已經下載完畢, 不用再等待
//                            break@outer
//                        }
//                        ERROR -> {
//                            // 發生錯誤, 不再等待
//                            break@outer
//                        }
//                        NONE -> {
//                            // 尚未開始下載, 繼續等待, 但不做任何事情
//                            println("等待結果...")
//                        }
//                        NEED_REPEAT -> {
//                            // 下載被阻擋, 繼續呼叫下載請求
//                            println("下載被阻擋, 重新呼叫下載")
//                            startDownload(url, p1, currentTag)
//                        }
//                    }
//                } else {
//                    println("舊tag $currentTag 不再進行等待, 最新為 $lastDownloadTag")
//                    break@outer
//                }
//            }
//        }).start()
//
//        println("線程離開")

    }

    override fun onCancel(p0: Any?) {
        println("appUpdate - 與 flutter 連結斷開, 取消下載")
        stopCurrentDownload()
    }

    private fun startDownload(url: String, sink: EventChannel.EventSink?, tag: Int) {
//        updater = AppUpdater(context, url).setUpdateCallback(object : UpdateCallback {
//
//            private fun sendData(event: String, value: Any?) {
//                val data = mapOf(EventTag.event to event, EventTag.value to value)
//                sink?.success(data)
//            }
//
//            override fun onFinish(file: File?) {
//                println("appUpdate - onFinish $file")
//                updater = null
//                sendData(Event.finish, null)
//            }
//
//            override fun onDownloading(isDownloading: Boolean) {
//                println("appUpdate - onDownloading = $isDownloading")
//                if (isDownloading) {
//                    // 不可重複下載, 標示需要重新呼叫下載
//                    downloadStatus[tag] = NEED_REPEAT
//                }
//                sendData(Event.onDownloading, isDownloading)
//            }
//
//            override fun onCancel() {
//                println("appUpdate - onCancel")
//                downloadStatus[tag] = END
//                sendData(Event.cancel, null)
//            }
//
//            override fun onProgress(progress: Int, total: Int, isChange: Boolean) {
//                val percent = (progress * 1.0 / total * 100).toInt()
//                if (isChange) {
//                    sendData(Event.progress, percent)
//                }
//            }
//
//            override fun onError(e: Exception?) {
//                println("appUpdate - onError $e")
//                downloadStatus[tag] = ERROR
//                updater = null
//                sendData(Event.error, e?.message)
//            }
//
//            override fun onStart(url: String?) {
//                println("appUpdate - onStart $url")
//                downloadStatus[tag] = DOWNLOADING
//                sendData(Event.start, null)
//            }
//
//        })
//        updater?.start()
    }

    /// 斷開當前的下載
    private fun stopCurrentDownload() {
        // 斷開當前的下載
//        if (updater != null) {
//            println("當前有正在下載的物件, 取消")
//            updater?.stop()
//            updater = null
//        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = EventChannel(binding.binaryMessenger, "app_updater")
        channel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setStreamHandler(null)
    }

}

enum class DownloadStatus {
    DOWNLOADING,
    END,
    ERROR,
    NONE,
    NEED_REPEAT,
}