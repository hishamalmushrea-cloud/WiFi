package com.netcontrol.app.native

import android.content.Context
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * جسر فحص صلاحيات الجذر (Root) على Android.
 *
 * يجمع عدة مؤشرات — لا يكفي مؤشر واحد لأن أجهزة Magisk الحديثة تخفي
 * جذرها (MagiskHide/DenyList):
 *  1. وجود su binary في مسارات النظام المعتادة.
 *  2. تطبيقات إدارة الجذر المثبتة (Magisk/SuperSU/KernelSU…).
 *  3. وسوم البناء test-keys (بدل release-keys الرسمية).
 *  4. قابلية تنفيذ su فعلياً (أقوى دليل، لكنه بطيء نسبياً).
 */
class RootCheckerChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, NativeChannels.CHANNEL_ROOT)

    fun register(name: String) {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "detect" -> result.success(detect())
            else -> result.notImplemented()
        }
    }

    private fun detect(): Map<String, Any> {
        val evidence = mutableListOf<String>()

        if (checkSuBinary()) evidence.add("su binary موجود في مسار نظام")
        if (checkRootApps()) evidence.add("تطبيق إدارة جذر مثبت (Magisk/SuperSU/KernelSU)")
        if (checkTestKeys()) evidence.add("Build.TAGS يحتوي test-keys")

        val suExecutable = checkSuExecutable()
        if (suExecutable) evidence.add("تنفيذ su -c id نجح")

        val methods = buildList {
            if (checkSuBinary()) add("su_path")
            if (checkRootApps()) add("root_app")
            if (checkTestKeys()) add("test_keys")
            if (suExecutable) add("su_exec")
        }

        return mapOf(
            "isRooted" to (suExecutable || evidence.isNotEmpty()),
            "methods" to methods,
            "evidence" to evidence,
        )
    }

    /** 1) البحث عن su في المسارات الشائعة (قابل للتنفيذ). */
    private fun checkSuBinary(): Boolean {
        val paths = listOf(
            "/system/bin/su", "/system/xbin/su", "/sbin/su",
            "/data/local/xbin/su", "/data/local/bin/su",
            "/system/sd/xbin/su", "/system/bin/failsafe/su",
            "/data/local/su", "/su/bin/su", "/apex/com.android.runtime/bin/su",
            "/debug_ramdisk/su", "/mnt/vendor/persist/su",
        )
        return paths.any { File(it).exists() }
    }

    /** 2) حزم إدارة الجذر المعروفة. */
    private fun checkRootApps(): Boolean {
        val packages = listOf(
            "com.topjohnwu.magisk", "eu.chainfire.supersu",
            "com.koushikdutta.superuser", "com.thirdparty.superuser",
            "com.kingroot.kinguser", "com.kingo.root",
            "me.weishu.kernelsu", "com.zachspong.temprootremovejb",
        )
        return try {
            val pm = context.packageManager
            packages.any { pkg ->
                @Suppress("DEPRECATION")
                pm.getInstalledApplications(0).any { it.packageName == pkg }
            }
        } catch (_: Exception) {
            false
        }
    }

    /** 3) test-keys بدل release-keys. */
    private fun checkTestKeys(): Boolean =
        Build.TAGS?.contains("test-keys") == true

    /** 4) المحاولة الفعلية لتنفيذ su — الدليل الأقوى. */
    private fun checkSuExecutable(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
            val output = process.inputStream.bufferedReader().readText()
            process.waitFor()
            output.contains("uid=0")
        } catch (_: Exception) {
            false
        }
    }
}
