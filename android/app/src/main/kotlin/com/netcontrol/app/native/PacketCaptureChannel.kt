package com.netcontrol.app.native

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * جسر التقاط الحزم المباشر عبر EventChannel.
 *
 * الالتقاط الحقيقي لحزم الواجهة اللاسلكية يتطلب صلاحيات جذر:
 * نشغّل `tcpdump` عبر `su` على الواجهة wlan0 ونمرّر سطور الملخص
 * أولاً بأول إلى Dart (العرض والتحليل يتمان هناك فيبقى الجسر خفيفاً).
 *
 * إن لم يكن tcpdump متوفراً (روم لا يضمّنه)، نُرجع حدث خطأ واضح
 * فتعرض الواجهة تلميح تثبيت بدل الانهيار — تدهور آمن.
 */
class PacketCaptureChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : EventChannel.StreamHandler {

    private var process: Process? = null
    private var readerThread: Thread? = null
    private var eventSink: EventChannel.EventSink? = null

    private val eventChannel = EventChannel(messenger, NativeChannels.CHANNEL_CAPTURE)

    fun register(name: String) {
        eventChannel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        startCapture()
    }

    override fun onCancel(arguments: Any?) {
        stopCapture()
        eventSink = null
    }

    private fun startCapture() {
        try {
            // -l: تخزين مؤقت صفري للأسطر، -n: بدون DNS (أداء وخصوصية)،
            // -i wlan0: الواجهة اللاسلكية.
            val process = ProcessBuilder(
                "su", "-c",
                "tcpdump -l -n -i wlan0 -s 96 2>/dev/null"
            ).redirectErrorStream(false).start()
            this.process = process

            readerThread = Thread {
                try {
                    BufferedReader(InputStreamReader(process.inputStream)).use { reader ->
                        var line = reader.readLine()
                        while (line != null) {
                            if (line.isNotBlank()) eventSink?.success(line.trim())
                            line = reader.readLine()
                        }
                    }
                } catch (_: Exception) {
                    eventSink?.error("CAPTURE_ENDED", "توقف التقاط الحزم.", null)
                }
            }.also { it.start() }
        } catch (_: Exception) {
            eventSink?.error(
                "NO_TCPDUMP",
                "التقاط الحزم يتطلب Root وأداة tcpdump على الجهاز.",
                null,
            )
        }
    }

    private fun stopCapture() {
        try {
            process?.destroy()
        } catch (_: Exception) {
            // تجاهل: العملية قد تكون انتهت أصلاً.
        }
        process = null
        readerThread?.interrupt()
        readerThread = null
    }
}
