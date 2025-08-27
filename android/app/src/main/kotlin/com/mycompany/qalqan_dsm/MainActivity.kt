package com.mycompany.qalqan_dsm

import android.os.Bundle
import android.os.Environment
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

// Qalqan SDK и утилиты
import com.mycompany.qalqan_dsm.QKeys
import com.mycompany.qalqan_dsm.Qalqan
import com.mycompany.qalqan_dsm.Utils

class MainActivity : FlutterActivity() {

    companion object {
        lateinit var keys: QKeys
        lateinit var qalqan: Qalqan
        lateinit var outputDirectory: File   // каталог для сохранения файлов приложения
        lateinit var keyfilename: File       // файл с ключом abc.bin
        lateinit var cacheDirectory: File    // временные файлы (расшифровка и пр.)
    }

    private val CHANNEL = "com.qalqan/app"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ✅ App-specific каталог на внешнем накопителе (не требует MANAGE_EXTERNAL_STORAGE
        //    и READ/WRITE_EXTERNAL_STORAGE на современных версиях Android)
        outputDirectory = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: filesDir
        if (!outputDirectory.exists()) outputDirectory.mkdirs()

        // Временные файлы
        cacheDirectory = applicationContext.cacheDir
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        keys = QKeys()
        qalqan = Qalqan()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Дешифрование ключа при запуске
                    "decryptKey" -> {
                        val path = call.argument<String>("filePath")!!
                        keyfilename = File(path)
                        val pwd = call.argument<String>("password")!!
                        val ok = pasrefileAndDecrypt(keyfilename, pwd)
                        if (ok) result.success(true) else result.error(
                            "DECRYPT_ERROR", "Invalid password or file", null
                        )
                    }

                    "encryptKeys" -> {
                        Log.d("MainActivity", "🔐 encryptKeys() invoked with pwd=${call.argument<String>("password")}")
                        val pwd = call.argument<String>("password")!!
                        val ok  = EncryptKeys.run(pwd)
                        Log.d("MainActivity", "🔐 EncryptKeys.run returned $ok")
                        if (ok) result.success(true)
                        else    result.error("ENCRYPT_ERROR", "Cannot save keys", null)
                    }

                    // Шифрование разных типов
                    "encryptFile" -> {
                        val path = call.argument<String>("path")!!
                        val kt = call.argument<String>("keyType")!!
                        val out = Utils.encryptFile(path, kt)
                        result.success(out)
                    }
                    "encryptPhoto" -> {
                        val path = call.argument<String>("path")!!
                        val kt = call.argument<String>("keyType")!!
                        val out = Utils.encryptPhoto(path, kt)
                        result.success(out)
                    }
                    "encryptVideo" -> {
                        val path = call.argument<String>("path")!!
                        val kt = call.argument<String>("keyType")!!
                        val out = Utils.encryptVideo(path, kt)
                        result.success(out)
                    }
                    "encryptAudio" -> {
                        val path = call.argument<String>("path")!!
                        val kt = call.argument<String>("keyType")!!
                        val out = Utils.encryptAudio(path, kt)
                        result.success(out)
                    }
                    "encryptText" -> {
                        val txt = call.argument<String>("text")!!
                        val kt = call.argument<String>("keyType")!!
                        val out = Utils.encryptText(txt, kt)
                        result.success(out)
                    }

                    // Дешифрование
                    "decryptFile" -> {
                        val fullPath = call.argument<String>("filePath")!!
                        val code = Utils.decryptFileFullPath(fullPath)
                        val payload = when (code) {
                            5 -> mapOf("code" to code, "text" to Utils.getDecryptedText())
                            3, 4, 7 -> mapOf("code" to code, "fileName" to Utils.getLastOutputFile())
                            else -> mapOf("code" to code)
                        }
                        result.success(payload)
                    }

                    // Пути директорий
                    "getOutputDir" -> result.success(outputDirectory.absolutePath)
                    "getCacheDir"  -> result.success(cacheDirectory.absolutePath)

                    else -> result.notImplemented()
                }
            }
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    private fun pasrefileAndDecrypt(filename: File, pwd: String): Boolean {
        val md = MessageDigest.getInstance("SHA-512")
        md.update(pwd.toByteArray())
        var h = md.digest()
        repeat(999) { h = MessageDigest.getInstance("SHA-512").digest(h) }

        val kekey = UByteArray(32) { i -> h[i].toUByte() }
        qalqan.kexp(kekey, keys.rKeKey, 32)

        val bytes = filename.readBytes()
        val blocklen = 16
        val flen = bytes.size - blocklen

        val kik = UByteArray(32)
        var tmp = UByteArray(blocklen)
        for (i in 0 until 32 step blocklen) {
            for (j in 0 until blocklen) tmp[j] = bytes[blocklen + i + j].toUByte()
            tmp = qalqan.decrypt(keys.rKeKey, tmp, 32)
            for (k in 0 until blocklen) kik[k + i] = tmp[k]
        }
        keys.AddKikey(kik)
        qalqan.kexp(keys.kikey, keys.rKiKey, 32)

        val imit = qalqan.qalqanImit(keys.rKiKey, flen.toLong(), filename.inputStream())
        for (i in 0 until blocklen) if (imit[i] != bytes[flen + i].toUByte()) return false

        val decr = UByteArray(bytes.size - blocklen - 32)
        qalqan.decrypt_ecb_data(keys.rKeKey, (flen - 32).toLong(), bytes, decr)
        keys.AddKeys(decr)
        keys.CopyKeys()
        return true
    }
}
