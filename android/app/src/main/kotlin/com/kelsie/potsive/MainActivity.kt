package com.kelsie.potsive

import android.util.Log
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.ihealth.communication.manager.iHealthDevicesManager
import android.content.pm.PackageManager
import java.security.MessageDigest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import com.ihealth.communication.manager.iHealthDevicesCallback
import com.ihealth.communication.manager.DiscoveryTypeEnum
import com.ihealth.communication.control.Bp550BTControl
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.kelsie.potsive/ihealth"
    private val EVENTS = "com.kelsie.potsive/ihealth/events"
    private var bluetoothGatt: BluetoothGatt? = null
    private var scanCallback: ScanCallback? = null
    private var isScanning: Boolean = false
    private var pendingConnectResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var callbackId: Int = -1
    private val macToControl = HashMap<String, Bp550BTControl>()
    private val mainHandler = Handler(Looper.getMainLooper())

    private fun emitEvent(data: Any) {
        try {
            if (Looper.myLooper() == Looper.getMainLooper()) {
                eventSink?.success(data)
            } else {
                mainHandler.post { eventSink?.success(data) }
            }
        } catch (_: Throwable) {}
    }

    private val BP_SERVICE = java.util.UUID.fromString("00001810-0000-1000-8000-00805f9b34fb")
    private val BP_MEASUREMENT_CHAR = java.util.UUID.fromString("00002a35-0000-1000-8000-00805f9b34fb")
    private val CCCD_UUID = java.util.UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Ensure iHealth SDK has a valid application context before any auth calls
        try {
            // Initialize SDK with Application instance and default flags
            iHealthDevicesManager.getInstance().init(application, 1, 1)
            Log.d("iHealth", "iHealthDevicesManager initialized with applicationContext")
        } catch (e: Exception) {
            Log.e("iHealth", "Failed to initialize iHealthDevicesManager", e)
        }

        // Register iHealth callback for KN-550BT
        try {
            if (callbackId == -1) {
                callbackId = iHealthDevicesManager.getInstance().registerClientCallback(object : iHealthDevicesCallback() {
                    override fun onScanDevice(mac: String?, deviceType: String?, rssi: Int, manufactorData: MutableMap<String, Any>?) {
                        val map = hashMapOf<String, Any?>(
                            "event" to "scan",
                            "mac" to mac,
                            "deviceType" to deviceType,
                            "rssi" to rssi,
                        )
                        emitEvent(map)
                    }

                    override fun onDeviceConnectionStateChange(mac: String?, deviceType: String?, status: Int, errorID: Int) {
                        val map = hashMapOf<String, Any?>(
                            "event" to "connection",
                            "mac" to mac,
                            "deviceType" to deviceType,
                            "status" to status,
                            "error" to errorID,
                        )
                        if (mac != null && status == iHealthDevicesManager.DEVICE_STATE_CONNECTED) {
                            try { iHealthDevicesManager.getInstance().getBp550BTControl(mac)?.let { macToControl[mac] = it } } catch (_: Throwable) {}
                        }
                        if (mac != null && status == iHealthDevicesManager.DEVICE_STATE_DISCONNECTED) {
                            macToControl.remove(mac)
                        }
                        emitEvent(map)
                    }

                    override fun onDeviceNotify(mac: String?, deviceType: String?, action: String?, message: String?) {
                        if (mac == null || action == null) return
                        try { Log.d("iHealth", "notify mac=$mac type=$deviceType action=$action msg=$message") } catch (_: Throwable) {}
                        when (action) {
                            // Newer format seen in logs
                            "offlinenum" -> {
                                try {
                                    val obj = JSONObject(message ?: return)
                                    val num = obj.optInt("offlinenum", 0)
                                    emitEvent(mapOf("event" to "bpOfflineNum", "mac" to mac, "count" to num))
                                } catch (_: Throwable) {}
                            }
                            "historicaldata_bp" -> {
                                try {
                                    val obj = JSONObject(message ?: return)
                                    val arr = obj.optJSONArray("data") ?: JSONArray()
                                    val list = ArrayList<Map<String, Any>>()
                                    for (i in 0 until arr.length()) {
                                        val o = arr.getJSONObject(i)
                                        val item = hashMapOf<String, Any>(
                                            "time" to o.optString("time", ""),
                                            "systolic" to o.optInt("sys", 0),
                                            "diastolic" to o.optInt("dia", 0),
                                            "heartRate" to o.optInt("heartRate", 0),
                                            "arrhythmia" to o.optBoolean("arrhythmia", false),
                                            "body_movement" to o.optBoolean("body_movement", false),
                                            "dataID" to o.optString("dataID", ""),
                                            "time_calibration" to o.optBoolean("time_calibration", false),
                                        )
                                        list.add(item)
                                    }
                                    emitEvent(mapOf("event" to "bpOfflineData", "mac" to mac, "records" to list))
                                } catch (_: Throwable) {}
                            }
                            // Older docs format
                            "action_historical_num_bp" -> {
                                try {
                                    val obj = JSONObject(message ?: return)
                                    val num = obj.optInt("historical_num_bp", 0)
                                    emitEvent(mapOf("event" to "bpOfflineNum", "mac" to mac, "count" to num))
                                } catch (_: Throwable) {}
                            }
                            "historical_data_bp" -> {
                                try {
                                    val arr = JSONArray(message ?: return)
                                    val list = ArrayList<Map<String, Any>>()
                                    for (i in 0 until arr.length()) {
                                        val o = arr.getJSONObject(i)
                                        val item = hashMapOf<String, Any>(
                                            "time" to o.optString("measurement_date_bp", ""),
                                            "systolic" to o.optInt("high_blood_pressure_bp", 0),
                                            "diastolic" to o.optInt("low_blood_pressure_bp", 0),
                                            "heartRate" to o.optInt("pulse_bp", 0),
                                            "ahr" to o.optInt("measurement_ahr_bp", 0),
                                            "hsd" to o.optInt("measurement_hsd_bp", 0),
                                        )
                                        list.add(item)
                                    }
                                    emitEvent(mapOf("event" to "bpOfflineData", "mac" to mac, "records" to list))
                                } catch (_: Throwable) {}
                            }
                            "action_historical_over_bp" -> {
                                emitEvent(mapOf("event" to "bpOfflineFinished", "mac" to mac))
                            }
                            "action_battery_bp" -> {
                                try {
                                    val obj = JSONObject(message ?: return)
                                    emitEvent(mapOf("event" to "bpBattery", "mac" to mac, "battery" to obj.optInt("battery_bp", -1)))
                                } catch (_: Throwable) {}
                            }
                        }
                    }
                })
                iHealthDevicesManager.getInstance().addCallbackFilterForDeviceType(callbackId, iHealthDevicesManager.TYPE_550BT)
            }
        } catch (e: Exception) {
            Log.e("iHealth", "Failed to register callback", e)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("iHealth", "Registering MethodChannel on $CHANNEL")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initIHealth" -> {
                        val ok = initIHealthSdk()
                        result.success(ok)
                    }
                    "scanBleOnce" -> {
                        scanBleOnce(result)
                    }
                    "connectToDevice" -> {
                        val address = call.argument<String>("address") ?: ""
                        connectToDevice(address, result)
                    }
                    "disconnectDevice" -> {
                        disconnectDevice()
                        result.success(true)
                    }
                    "sdkStartDiscovery" -> {
                        try {
                            iHealthDevicesManager.getInstance().startDiscovery(DiscoveryTypeEnum.BP550BT)
                            result.success(true)
                        } catch (t: Throwable) {
                            result.error("sdk_discovery_error", t.message, null)
                        }
                    }
                    "sdkStopDiscovery" -> {
                        try {
                            iHealthDevicesManager.getInstance().stopDiscovery()
                            result.success(true)
                        } catch (t: Throwable) {
                            result.error("sdk_discovery_error", t.message, null)
                        }
                    }
                    "sdkConnect" -> {
                        val mac = call.argument<String>("mac") ?: ""
                        try {
                            iHealthDevicesManager.getInstance().connectDevice("", mac, iHealthDevicesManager.TYPE_550BT)
                            result.success(true)
                        } catch (t: Throwable) {
                            result.error("sdk_connect_error", t.message, null)
                        }
                    }
                    "sdkGetOfflineNum" -> {
                        val mac = call.argument<String>("mac") ?: ""
                        val ctrl = macToControl[mac]
                        if (ctrl == null) {
                            result.error("no_ctrl", "No control for $mac", null)
                        } else {
                            try { ctrl.getOfflineNum() } catch (_: Throwable) {}
                            result.success(true)
                        }
                    }
                    "sdkGetOfflineData" -> {
                        val mac = call.argument<String>("mac") ?: ""
                        val ctrl = macToControl[mac]
                        if (ctrl == null) {
                            result.error("no_ctrl", "No control for $mac", null)
                        } else {
                            try { ctrl.getOfflineData() } catch (_: Throwable) {}
                            result.success(true)
                        }
                    }
                    "sdkTransferFinished" -> {
                        val mac = call.argument<String>("mac") ?: ""
                        val ctrl = macToControl[mac]
                        if (ctrl == null) {
                            result.error("no_ctrl", "No control for $mac", null)
                        } else {
                            try { ctrl.transferFinished() } catch (_: Throwable) {}
                            result.success(true)
                        }
                    }
                    "sdkDisconnect" -> {
                        val mac = call.argument<String>("mac") ?: ""
                        try {
                            macToControl.remove(mac)?.disconnect()
                        } catch (_: Throwable) {}
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                }
                override fun onCancel(args: Any?) {
                    eventSink = null
                }
            })
    }

    private fun logAppSignatures() {
    try {
        val pm = applicationContext.packageManager
        // GET_SIGNING_CERTIFICATES is the modern flag; fallback will use .signatures if needed
        val info = pm.getPackageInfo(applicationContext.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
        // signingInfo may be null on some devices / API combos; fall back to legacy signatures
        val signers = info.signingInfo?.apkContentsSigners ?: info.signatures

        if (signers == null || signers.isEmpty()) {
            Log.d("iHealth", "No signing certificates found for package ${applicationContext.packageName}")
            return
        }

        for (sig in signers) {
            try {
                val bytes = sig.toByteArray() // works for both Signature and whichever type is returned
                val sha256 = MessageDigest.getInstance("SHA-256").digest(bytes)
                    .joinToString(":") { "%02X".format(it) }
                val sha1 = MessageDigest.getInstance("SHA-1").digest(bytes)
                    .joinToString(":") { "%02X".format(it) }
                Log.d("iHealth", "Runtime APK signature SHA1: $sha1")
                Log.d("iHealth", "Runtime APK signature SHA256: $sha256")
            } catch (e: Exception) {
                Log.e("iHealth", "Failed while hashing signature", e)
            }
        }
    } catch (e: Exception) {
        Log.e("iHealth", "Failed to get signatures", e)
    }
}


    private fun initIHealthSdk(): Boolean {
        logAppSignatures()
        return try {
            // Ensure SDK has context prior to authentication
            try {
                iHealthDevicesManager.getInstance().init(application, 1, 1)
            } catch (_: Exception) {
                // ignore; already initialized in onCreate
            }

            val licenseBytes = assets.open("com_kelsie_potsive_android.pem").readBytes()
            Log.d("iHealth", "Read license bytes: ${licenseBytes.size}")
            val authResult = iHealthDevicesManager.getInstance().sdkAuthWithLicense(licenseBytes)
            Log.d("iHealth", "SDK auth result: $authResult")
            authResult
        } catch (e: Exception) {
            Log.e("iHealth", "SDK init failed", e)
            false
        }
    }

    private fun scanBleOnce(result: MethodChannel.Result) {
        if (isScanning) {
            result.error("already_scanning", "Scan already in progress", null)
            return
        }
        val bluetoothManager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = bluetoothManager.adapter
        if (adapter == null || !adapter.isEnabled) {
            result.error("bluetooth_off", "Bluetooth is off or unavailable", null)
            return
        }
        val scanner = adapter.bluetoothLeScanner
        if (scanner == null) {
            result.error("no_scanner", "BLE scanner unavailable", null)
            return
        }

        val found = LinkedHashMap<String, Map<String, Any?>>()
        val handler = Handler(Looper.getMainLooper())
        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, res: ScanResult) {
                try {
                    val device = res.device
                    if (device.address == null) return
                    // Heuristic: keep iHealth-looking devices and anything with a name
                    val name = device.name
                    if (name == null) return
                    val entry = mapOf(
                        "name" to name,
                        "address" to device.address,
                        "rssi" to res.rssi,
                    )
                    found[device.address] = entry
                } catch (_: Throwable) {}
            }
        }

        try {
            isScanning = true
            scanner.startScan(scanCallback)
        } catch (se: SecurityException) {
            result.error("permission_denied", "Missing BLUETOOTH_SCAN permission", null)
            return
        } catch (t: Throwable) {
            result.error("scan_error", t.message, null)
            return
        }

        handler.postDelayed({
            try {
                scanner.stopScan(scanCallback)
            } catch (_: Throwable) {}
            isScanning = false
            scanCallback = null
            result.success(found.values.toList())
        }, 6000)
    }

    private fun connectToDevice(address: String, result: MethodChannel.Result) {
        if (address.isBlank()) {
            result.error("bad_args", "address is required", null)
            return
        }
        val bluetoothManager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = bluetoothManager.adapter
        if (adapter == null || !adapter.isEnabled) {
            result.error("bluetooth_off", "Bluetooth is off or unavailable", null)
            return
        }
        val device = try { adapter.getRemoteDevice(address) } catch (_: IllegalArgumentException) { null }
        if (device == null) {
            result.error("no_device", "Device not found for $address", null)
            return
        }
        pendingConnectResult?.error("aborted", "Another connect in progress", null)
        pendingConnectResult = result

        bluetoothGatt?.close()
        bluetoothGatt = null

        try {
            bluetoothGatt = device.connectGatt(this, false, object : BluetoothGattCallback() {
                override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
                    super.onConnectionStateChange(gatt, status, newState)
                    if (newState == BluetoothProfile.STATE_CONNECTED) {
                        Log.d("BLE", "Connected to $address")
                        pendingConnectResult?.success(true)
                        pendingConnectResult = null
                        try { gatt.discoverServices() } catch (_: Throwable) {}
                    } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                        Log.d("BLE", "Disconnected from $address status=$status")
                        pendingConnectResult?.success(false)
                        pendingConnectResult = null
                        gatt.close()
                    }
                }

                override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
                    super.onServicesDiscovered(gatt, status)
                    try {
                        // Log available services/characteristics to help debugging
                        for (svc in gatt.services) {
                            Log.d("BLE", "Service: ${svc.uuid}")
                            for (c in svc.characteristics) {
                                Log.d(
                                    "BLE",
                                    "  Char: ${c.uuid} props=0x${Integer.toHexString(c.properties)}"
                                )
                            }
                        }

                        val bpService = gatt.getService(BP_SERVICE)
                        if (bpService != null) {
                            val ch = bpService.getCharacteristic(BP_MEASUREMENT_CHAR)
                            if (ch != null) {
                                val props = ch.properties
                                val supportsIndicate = (props and android.bluetooth.BluetoothGattCharacteristic.PROPERTY_INDICATE) != 0
                                val supportsNotify = (props and android.bluetooth.BluetoothGattCharacteristic.PROPERTY_NOTIFY) != 0
                                Log.d("BLE", "BP char properties indicate=$supportsIndicate notify=$supportsNotify")

                                gatt.setCharacteristicNotification(ch, true)
                                val cccd = ch.getDescriptor(CCCD_UUID)
                                if (cccd != null) {
                                    cccd.value = if (supportsIndicate)
                                        BluetoothGattDescriptor.ENABLE_INDICATION_VALUE
                                    else
                                        BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                                    val ok = gatt.writeDescriptor(cccd)
                                    Log.d("BLE", "CCCD write started: $ok value=${cccd.value?.joinToString { String.format("%02X", it) }}")
                                } else {
                                    Log.w("BLE", "CCCD descriptor not found for BP characteristic")
                                }
                                return
                            }
                        }

                        Log.w("BLE", "Blood Pressure service (0x1810) not found - trying proprietary notify char")
                        // Fallback: subscribe to first NOTIFY characteristic under proprietary service
                        for (svc in gatt.services) {
                            for (c in svc.characteristics) {
                                val props = c.properties
                                val supportsNotify = (props and android.bluetooth.BluetoothGattCharacteristic.PROPERTY_NOTIFY) != 0
                                if (supportsNotify) {
                                    try {
                                        gatt.setCharacteristicNotification(c, true)
                                        val cccd = c.getDescriptor(CCCD_UUID)
                                        if (cccd != null) {
                                            cccd.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                                            gatt.writeDescriptor(cccd)
                                            Log.d("BLE", "Subscribed to ${c.uuid} in ${svc.uuid}")
                                            return
                                        }
                                    } catch (t: Throwable) {
                                        Log.e("BLE", "Failed to subscribe ${c.uuid}", t)
                                    }
                                }
                            }
                        }
                    } catch (t: Throwable) {
                        Log.e("BLE", "Subscribe failed", t)
                    }
                }

                override fun onDescriptorWrite(gatt: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
                    super.onDescriptorWrite(gatt, descriptor, status)
                    if (descriptor.uuid == CCCD_UUID) {
                        Log.d("BLE", "CCCD write completed status=$status")
                    }
                }

                override fun onCharacteristicChanged(gatt: BluetoothGatt, characteristic: android.bluetooth.BluetoothGattCharacteristic) {
                    super.onCharacteristicChanged(gatt, characteristic)
                    val data = characteristic.value ?: return
                    if (characteristic.uuid == BP_MEASUREMENT_CHAR) {
                        val reading = parseBpMeasurement(data)
                        if (reading != null) {
                            emitEvent(reading)
                            return
                        }
                    }
                    // Fallback: emit raw hex for proprietary payloads so we can inspect
                    val hex = data.joinToString(" ") { String.format("%02X", it) }
                    val map = hashMapOf<String, Any>(
                        "event" to "raw",
                        "characteristic" to characteristic.uuid.toString(),
                        "service" to (characteristic.service?.uuid?.toString() ?: ""),
                        "payloadHex" to hex,
                        "timestamp" to System.currentTimeMillis(),
                    )
                    emitEvent(map)
                }
            })
        } catch (se: SecurityException) {
            pendingConnectResult?.error("permission_denied", "Missing BLUETOOTH_CONNECT permission", null)
            pendingConnectResult = null
        } catch (t: Throwable) {
            pendingConnectResult?.error("connect_error", t.message, null)
            pendingConnectResult = null
        }
    }

    private fun disconnectDevice() {
        try {
            bluetoothGatt?.disconnect()
        } catch (_: Throwable) {}
        try {
            bluetoothGatt?.close()
        } catch (_: Throwable) {}
        bluetoothGatt = null
    }

    // Parse Blood Pressure Measurement (0x2A35) per Bluetooth SIG
    private fun parseBpMeasurement(data: ByteArray): Map<String, Any>? {
        if (data.isEmpty()) return null
        var offset = 0
        val flags = data[offset].toInt() and 0xFF
        offset += 1
        // SFLOAT helpers
        fun readSfloat(): Double {
            val raw = ((data[offset + 1].toInt() and 0xFF) shl 8) or (data[offset].toInt() and 0xFF)
            offset += 2
            var mantissa = raw and 0x0FFF
            if (mantissa >= 0x0800) mantissa = -(0x1000 - mantissa)
            var exp = raw shr 12
            if (exp >= 0x8) exp = -(0x10 - exp)
            return mantissa * Math.pow(10.0, exp.toDouble())
        }

        val unitsKpa = (flags and 0x01) != 0 // 0 = mmHg, 1 = kPa
        var systolic = readSfloat()
        var diastolic = readSfloat()
        var mapVal = readSfloat() // mean arterial pressure

        if (unitsKpa) {
            // Convert kPa to mmHg
            val factor = 7.50062
            systolic *= factor
            diastolic *= factor
            mapVal *= factor
        }

        // Optional fields
        val timeStampPresent = (flags and 0x02) != 0
        if (timeStampPresent) {
            // Skip 7 bytes of timestamp
            offset += 7
        }

        var pulseRate: Double? = null
        val pulseRatePresent = (flags and 0x04) != 0
        if (pulseRatePresent) {
            pulseRate = readSfloat()
        }

        val result = hashMapOf<String, Any>(
            "systolic" to Math.round(systolic).toInt(),
            "diastolic" to Math.round(diastolic).toInt(),
            "map" to Math.round(mapVal).toInt(),
            "timestamp" to System.currentTimeMillis(),
        )
        if (pulseRate != null) {
            result["heartRate"] = Math.round(pulseRate).toInt()
        }
        return result
    }
}
   
