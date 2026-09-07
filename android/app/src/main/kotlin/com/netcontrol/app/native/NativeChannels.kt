package com.netcontrol.app.native

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger

/**
 * تسجيل كل الجسور الأصلية (Method/Event Channels) مع محرّك Flutter.
 *
 * سبب المركزية: يبقي MainActivity نظيفاً ويضمن ترتيب تسجيل ثابتاً
 * (القنوات تُنشأ مرة واحدة مع الـ engine وتُعاد استخدامها).
 */
object NativeChannels {

    const val CHANNEL_ROOT = "com.netcontrol.app/root_check"
    const val CHANNEL_NETWORK = "com.netcontrol.app/network"
    const val CHANNEL_CAPTURE = "com.netcontrol.app/packet_capture"

    fun register(context: Context, engine: FlutterEngine) {
        val messenger: BinaryMessenger = engine.dartExecutor.binaryMessenger

        RootCheckerChannel(context, messenger).register(CHANNEL_ROOT)
        NetworkChannel(context, messenger).register(CHANNEL_NETWORK)
        PacketCaptureChannel(context, messenger).register(CHANNEL_CAPTURE)
    }
}
