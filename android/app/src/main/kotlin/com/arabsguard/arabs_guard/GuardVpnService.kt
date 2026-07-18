package com.arabsguard.arabs_guard

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.atomic.AtomicBoolean
import javax.net.ssl.SNIHostName
import javax.net.ssl.SSLParameters
import javax.net.ssl.SSLSocket
import javax.net.ssl.SSLSocketFactory

class GuardVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var worker: Thread? = null
    private val stopping = AtomicBoolean(false)

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        if (!isRunning) startTunnel()
        return START_STICKY
    }

    private fun startTunnel() {
        stopping.set(false)
        val configureIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        vpnInterface = Builder()
            .setSession("Arabs Guard family DNS")
            .setConfigureIntent(configureIntent)
            .setMtu(1500)
            .addAddress(TUN_ADDRESS, 32)
            .addDnsServer(TUN_DNS)
            .addRoute(TUN_DNS, 32)
            .setBlocking(true)
            .establish()

        val descriptor = vpnInterface ?: run {
            stopSelf()
            return
        }
        isRunning = true
        worker = Thread({ runDnsLoop(descriptor) }, "ArabsGuard-DNS").apply { start() }
    }

    private fun runDnsLoop(descriptor: ParcelFileDescriptor) {
        val input = FileInputStream(descriptor.fileDescriptor)
        val output = FileOutputStream(descriptor.fileDescriptor)
        val transport = DohTransport()
        val packet = ByteArray(32767)
        try {
            while (!stopping.get()) {
                val count = input.read(packet)
                if (count <= 0) continue
                val parsed = parseDnsPacket(packet, count) ?: continue
                try {
                    val dnsResponse = transport.query(parsed.payload)
                    val responsePacket = buildResponsePacket(parsed, dnsResponse)
                    output.write(responsePacket)
                    output.flush()
                } catch (_: IOException) {
                    // DNS failure is fail-closed for this query; the next query retries both endpoints.
                }
            }
        } catch (_: IOException) {
            // Closing the TUN descriptor is the normal way the worker is stopped.
        } finally {
            transport.close()
            isRunning = false
        }
    }

    private data class DnsPacket(
        val identification: Int,
        val sourceAddress: ByteArray,
        val destinationAddress: ByteArray,
        val sourcePort: Int,
        val destinationPort: Int,
        val payload: ByteArray,
    )

    private fun parseDnsPacket(packet: ByteArray, count: Int): DnsPacket? {
        if (count < 28 || (packet[0].toInt() ushr 4) != 4) return null
        val headerLength = (packet[0].toInt() and 0x0f) * 4
        if (headerLength < 20 || count < headerLength + 8) return null
        if ((packet[9].toInt() and 0xff) != 17) return null
        val totalLength = unsignedShort(packet, 2)
        if (totalLength > count || totalLength < headerLength + 8) return null
        val destinationPort = unsignedShort(packet, headerLength + 2)
        if (destinationPort != 53) return null
        val expectedDns = InetAddress.getByName(TUN_DNS).address
        val destinationAddress = packet.copyOfRange(16, 20)
        if (!destinationAddress.contentEquals(expectedDns)) return null
        val payloadOffset = headerLength + 8
        return DnsPacket(
            identification = unsignedShort(packet, 4),
            sourceAddress = packet.copyOfRange(12, 16),
            destinationAddress = destinationAddress,
            sourcePort = unsignedShort(packet, headerLength),
            destinationPort = destinationPort,
            payload = packet.copyOfRange(payloadOffset, totalLength),
        )
    }

    private fun buildResponsePacket(query: DnsPacket, dnsResponse: ByteArray): ByteArray {
        val totalLength = 20 + 8 + dnsResponse.size
        val buffer = ByteBuffer.allocate(totalLength).order(ByteOrder.BIG_ENDIAN)
        buffer.put(0x45.toByte())
        buffer.put(0)
        buffer.putShort(totalLength.toShort())
        buffer.putShort(query.identification.toShort())
        buffer.putShort(0)
        buffer.put(64)
        buffer.put(17)
        buffer.putShort(0)
        buffer.put(query.destinationAddress)
        buffer.put(query.sourceAddress)
        buffer.putShort(query.destinationPort.toShort())
        buffer.putShort(query.sourcePort.toShort())
        buffer.putShort((8 + dnsResponse.size).toShort())
        buffer.putShort(0) // IPv4 UDP checksum may be zero.
        buffer.put(dnsResponse)
        val bytes = buffer.array()
        val checksum = ipv4Checksum(bytes)
        bytes[10] = (checksum ushr 8).toByte()
        bytes[11] = checksum.toByte()
        return bytes
    }

    private fun unsignedShort(value: ByteArray, offset: Int): Int =
        ((value[offset].toInt() and 0xff) shl 8) or (value[offset + 1].toInt() and 0xff)

    private fun ipv4Checksum(packet: ByteArray): Int {
        var sum = 0L
        for (offset in 0 until 20 step 2) {
            sum += unsignedShort(packet, offset).toLong()
        }
        while (sum shr 16 != 0L) sum = (sum and 0xffff) + (sum shr 16)
        return sum.inv().toInt() and 0xffff
    }

    private inner class DohTransport {
        private var socket: SSLSocket? = null
        private var input: DataInputStream? = null
        private var output: DataOutputStream? = null
        private var endpointIndex = 0

        @Synchronized
        fun query(payload: ByteArray): ByteArray {
            var lastError: IOException? = null
            repeat(DOH_ENDPOINTS.size) {
                try {
                    ensureConnected()
                    val activeOutput = output ?: throw IOException("DNS transport not connected")
                    val activeInput = input ?: throw IOException("DNS transport not connected")
                    val requestHeaders = buildString {
                        append("POST $DOH_PATH HTTP/1.1\r\n")
                        append("Host: $DOH_HOSTNAME\r\n")
                        append("Accept: application/dns-message\r\n")
                        append("Content-Type: application/dns-message\r\n")
                        append("Content-Length: ${payload.size}\r\n")
                        append("Connection: keep-alive\r\n\r\n")
                    }
                    activeOutput.write(requestHeaders.toByteArray(Charsets.US_ASCII))
                    activeOutput.write(payload)
                    activeOutput.flush()
                    return readHttpResponse(activeInput)
                } catch (error: IOException) {
                    lastError = error
                    close()
                    endpointIndex = (endpointIndex + 1) % DOH_ENDPOINTS.size
                }
            }
            throw lastError ?: IOException("Encrypted DNS endpoints unavailable")
        }

        private fun readHttpResponse(activeInput: DataInputStream): ByteArray {
            val statusLine = readAsciiLine(activeInput)
            val statusCode = statusLine.split(' ').getOrNull(1)?.toIntOrNull()
                ?: throw IOException("Invalid DNS-over-HTTPS response")
            val headers = mutableMapOf<String, String>()
            while (true) {
                val line = readAsciiLine(activeInput)
                if (line.isEmpty()) break
                val separator = line.indexOf(':')
                if (separator <= 0) throw IOException("Invalid DNS-over-HTTPS header")
                headers[line.substring(0, separator).trim().lowercase()] =
                    line.substring(separator + 1).trim()
            }
            if (statusCode != 200) throw IOException("DNS-over-HTTPS returned HTTP $statusCode")

            val response = when {
                headers["transfer-encoding"]?.contains("chunked", ignoreCase = true) == true ->
                    readChunkedBody(activeInput)
                headers["content-length"] != null -> {
                    val length = headers.getValue("content-length").toIntOrNull()
                        ?: throw IOException("Invalid DNS-over-HTTPS content length")
                    if (length <= 0 || length > MAX_DNS_MESSAGE) {
                        throw IOException("Invalid DNS-over-HTTPS content length")
                    }
                    ByteArray(length).also(activeInput::readFully)
                }
                else -> throw IOException("DNS-over-HTTPS response length is missing")
            }
            if (response.isEmpty() || response.size > MAX_DNS_MESSAGE) {
                throw IOException("Invalid DNS-over-HTTPS response body")
            }
            if (headers["connection"]?.equals("close", ignoreCase = true) == true) close()
            return response
        }

        private fun readChunkedBody(activeInput: DataInputStream): ByteArray {
            val body = ByteArrayOutputStream()
            while (true) {
                val chunkSize = readAsciiLine(activeInput)
                    .substringBefore(';')
                    .trim()
                    .toIntOrNull(16)
                    ?: throw IOException("Invalid DNS-over-HTTPS chunk size")
                if (chunkSize < 0 || body.size() + chunkSize > MAX_DNS_MESSAGE) {
                    throw IOException("DNS-over-HTTPS response is too large")
                }
                if (chunkSize == 0) {
                    while (readAsciiLine(activeInput).isNotEmpty()) {
                        // Consume optional HTTP trailers.
                    }
                    break
                }
                val chunk = ByteArray(chunkSize)
                activeInput.readFully(chunk)
                body.write(chunk)
                if (readAsciiLine(activeInput).isNotEmpty()) {
                    throw IOException("Invalid DNS-over-HTTPS chunk terminator")
                }
            }
            return body.toByteArray()
        }

        private fun readAsciiLine(activeInput: DataInputStream): String {
            val line = ByteArrayOutputStream()
            while (line.size() <= MAX_HTTP_LINE) {
                val next = activeInput.read()
                if (next == -1) throw IOException("DNS-over-HTTPS connection closed")
                if (next == '\n'.code) return line.toString(Charsets.US_ASCII.name()).trimEnd('\r')
                line.write(next)
            }
            throw IOException("DNS-over-HTTPS header is too long")
        }

        private fun ensureConnected() {
            if (socket?.isConnected == true && socket?.isClosed == false) return
            val plainSocket = Socket()
            // Force Android to allocate the socket file descriptor before VpnService.protect().
            plainSocket.bind(InetSocketAddress(0))
            if (!protect(plainSocket)) {
                plainSocket.close()
                throw IOException("Could not protect DNS transport socket")
            }
            plainSocket.connect(InetSocketAddress(DOH_ENDPOINTS[endpointIndex], DOH_PORT), 5000)
            plainSocket.soTimeout = 7000
            val tls = (SSLSocketFactory.getDefault() as SSLSocketFactory)
                .createSocket(plainSocket, DOH_HOSTNAME, DOH_PORT, true) as SSLSocket
            tls.sslParameters = SSLParameters().apply {
                endpointIdentificationAlgorithm = "HTTPS"
                serverNames = listOf(SNIHostName(DOH_HOSTNAME))
            }
            tls.startHandshake()
            socket = tls
            input = DataInputStream(tls.inputStream)
            output = DataOutputStream(tls.outputStream)
        }

        fun close() {
            try {
                socket?.close()
            } catch (_: IOException) {
            }
            socket = null
            input = null
            output = null
        }
    }

    private fun buildNotification() = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL)
        .setSmallIcon(R.mipmap.ic_launcher)
        .setContentTitle("Arabs Guard is protecting DNS")
        .setContentText("Family filtering is active on this phone")
        .setContentIntent(
            PendingIntent.getActivity(
                this,
                0,
                Intent(this, MainActivity::class.java),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            ),
        )
        .setOngoing(true)
        .setCategory(NotificationCompat.CATEGORY_SERVICE)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .build()

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL,
                "Protection status",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shows when the family DNS guard is active"
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun stopTunnel() {
        stopping.set(true)
        try {
            vpnInterface?.close()
        } catch (_: IOException) {
        }
        vpnInterface = null
        worker?.interrupt()
        worker = null
        isRunning = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onRevoke() {
        stopTunnel()
        super.onRevoke()
    }

    override fun onDestroy() {
        stopTunnel()
        super.onDestroy()
    }

    companion object {
        const val ACTION_START = "com.arabsguard.arabs_guard.START"
        @Volatile var isRunning: Boolean = false
            private set

        private const val NOTIFICATION_CHANNEL = "arabs_guard_protection"
        private const val NOTIFICATION_ID = 2101
        private const val TUN_ADDRESS = "10.77.0.1"
        private const val TUN_DNS = "10.77.0.2"
        private const val DOH_HOSTNAME = "doh.cleanbrowsing.org"
        private const val DOH_PATH = "/doh/family-filter/"
        private const val DOH_PORT = 443
        private const val MAX_DNS_MESSAGE = 65535
        private const val MAX_HTTP_LINE = 8192
        private val DOH_ENDPOINTS = arrayOf("185.228.168.168", "185.228.169.168")
    }
}
