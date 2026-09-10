package com.netcontrol.app.native

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.net.Inet4Address
import java.net.NetworkInterface

/**
 * جسر معلومات الشبكة على Android:
 *  - getNetworkInfo: عنوان البوابة والقناع الشبكي للشبكة الحالية.
 *  - getArpTable:   جدول ARP من /proc/net/arp (IP → MAC) لاكتشاف الأجهزة.
 *  - scanWifi:      نقاط الوصول المحيطة عبر WifiManager (يتطلب موافقة
 *                   الموقع على كل إصدارات Android).
 *
 * نُرجع بيانات خام بأسماء مفاتيح يفهمها مستودع Dart؛ وأي فشل صلاحية
 * يُعاد كـ PlatformException برسالة عربية ليُعامل بالتدهور الآمن.
 */
class NetworkChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, NativeChannels.CHANNEL_NETWORK)

    fun register(name: String) {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getNetworkInfo" -> result.success(getNetworkInfo())
            "getArpTable" -> result.success(getArpTable())
            "getWifiRssi" -> result.success(getWifiRssi())
            "scanWifi" -> try {
                result.success(scanWifi())
            } catch (e: PermissionDeniedException) {
                result.error("PERMISSION_DENIED", e.message, null)
            }
            else -> result.notImplemented()
        }
    }

    /** استثناء داخلي: وُصل قبل رد القناة حتى لا نرسل ردّين. */
    private class PermissionDeniedException(message: String) : Exception(message)

    // ───────────────────── معلومات الشبكة ─────────────────────

    private fun getNetworkInfo(): Map<String, Any?> {
        val wifi = context.applicationContext
            .getSystemService(Context.WIFI_SERVICE) as? WifiManager

        var gateway: String? = null
        var subnet: String? = null

        @Suppress("DEPRECATION")
        val dhcp = wifi?.dhcpInfo
        if (dhcp != null) {
            gateway = intToIp(dhcp.gateway)
            subnet = intToIp(dhcp.netmask)
        }

        // احتياط: استنتاج البوابة من واجهة الشبكة عند فشل DhcpInfo.
        if (gateway == null) gateway = findGatewayFromInterface()

        return mapOf(
            "gateway" to gateway,
            "subnet" to subnet,
        )
    }

    private fun intToIp(value: Int): String? {
        if (value == 0) return null
        return "${value and 0xFF}.${value shr 8 and 0xFF}.${value shr 16 and 0xFF}.${value shr 24 and 0xFF}"
    }

    private fun findGatewayFromInterface(): String? {
        return try {
            for (iface in NetworkInterface.getNetworkInterfaces()) {
                if (!Regex("wlan|ap|eth|swlan").containsMatchIn(iface.name)) continue
                for (addr in iface.interfaceAddresses) {
                    val ip = addr.address
                    if (ip is Inet4Address) {
                        // تقدير تقريبي: أول عنوان في الشبكة الفرعية /24.
                        val parts = ip.hostAddress?.split(".") ?: continue
                        if (parts.size == 4) return "${parts[0]}.${parts[1]}.${parts[2]}.1"
                    }
                }
            }
            null
        } catch (_: Exception) {
            null
        }
    }

    // ───────────────────── RSSI الشبكة الحالية ─────────────────────

    /**
     * قوة إشارة الشبكة المتصلة حالياً بوحدة dBm.
     *
     * تُستخدم للخريطة الحرارية (أخذ عينات حقيقية أثناء التنقل).
     * تُعاد null عند إيقاف WiFi أو غياب اتصال أو رفض الصلاحية —
     * فيُعامل المستودع في Dart بالتدهور الآمن (إدخال يدوي).
     */
    private fun getWifiRssi(): Int? {
        val wifi = context.applicationContext
            .getSystemService(Context.WIFI_SERVICE) as? WifiManager ?: return null

        @Suppress("DEPRECATION")
        return try {
            val rssi = wifi.connectionInfo.rssi
            // ‏-9999 هي قيمة INVALID_RSSI الموثقة (الثابت نفسه ليس
            // عاماً في كل إصدارات SDK فيفشل حلّه) — وطبقة Dart
            // (RssiUtils.isValidRssi) ترشّح القيم غير المنطقية أيضاً.
            if (rssi == -9999) null else rssi
        } catch (_: SecurityException) {
            null
        }
    }

    // ───────────────────── جدول ARP ─────────────────────

    /**
     * يقرأ /proc/net/arp — سطر لكل جهاز معروف محلياً:
     *   IP address  HW type  Flags  HW address  Mask  Device
     */
    private fun getArpTable(): Map<String, String> {
        val table = HashMap<String, String>()
        try {
            BufferedReader(FileReader(File("/proc/net/arp"))).use { reader ->
                reader.readLine() // عنوان الأعمدة
                var line = reader.readLine()
                while (line != null) {
                    val parts = line.split(Regex("\\s+")).filter { it.isNotBlank() }
                    if (parts.size >= 4 && parts[3].matches(Regex("([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}"))) {
                        table[parts[0]] = parts[3].uppercase()
                    }
                    line = reader.readLine()
                }
            }
        } catch (_: Exception) {
            // بعض الأجهزة تمنع القراءة بدون root — نُرجع ما جمعناه.
        }
        return table
    }

    // ───────────────────── مسح WiFi ─────────────────────

    private fun scanWifi(): List<Map<String, Any?>> {
        if (!hasLocationPermission()) {
            throw PermissionDeniedException("يلزم منح صلاحية الموقع لمسح شبكات WiFi.")
        }

        val wifi = context.applicationContext
            .getSystemService(Context.WIFI_SERVICE) as? WifiManager
            ?: return emptyList()

        // نطلب مسحاً جديداً (قد يُقيّده النظام على Android 9+؛ نقرأ النتائج).
        @Suppress("DEPRECATION")
        try {
            wifi.startScan()
        } catch (_: SecurityException) {
            // صلاحية غير متاحة في هذا السياق — نكتفي بالنتائج المخزنة مؤقتاً.
        }

        @Suppress("DEPRECATION")
        val results = try {
            wifi.scanResults
        } catch (_: SecurityException) {
            throw PermissionDeniedException("يلزم صلاحية الموقع للمسح.")
        }

        return results.map { sr ->
            mapOf(
                "bssid" to sr.BSSID,
                "ssid" to sr.SSID,
                "rssi" to sr.level,
                "frequency" to sr.frequency,
                "channel" to frequencyToChannel(sr.frequency),
                "capabilities" to sr.capabilities,
                "timestamp" to sr.timestamp,
            )
        }
    }

    /** يحوّل التردد بالميغاهرتز إلى رقم قناة WiFi قياسي. */
    private fun frequencyToChannel(freq: Int): Int = when {
        freq in 2412..2484 -> (freq - 2412) / 5 + 1
        freq == 2484 -> 14
        freq in 5170..5825 -> (freq - 5170) / 5 + 34
        freq in 5955..7115 -> (freq - 5955) / 5 + 1 // 6 GHz (قناة 1 = 5955)
        else -> 0
    }

    private fun hasLocationPermission(): Boolean {
        val fine = context.checkSelfPermission(
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        // Android 13+ يستبدلها بـ NEARBY_WIFI_DEVICES لكن الموقع ما زال يعمل.
        val nearby = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.checkSelfPermission(
                Manifest.permission.NEARBY_WIFI_DEVICES
            ) == PackageManager.PERMISSION_GRANTED
        } else true
        return fine || nearby
    }
}
