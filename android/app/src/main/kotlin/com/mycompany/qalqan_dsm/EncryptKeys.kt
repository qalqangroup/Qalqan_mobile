package com.mycompany.qalqan_dsm

import java.io.File
import java.security.MessageDigest

import com.mycompany.qalqan_dsm.MainActivity.Companion.outputDirectory
import com.mycompany.qalqan_dsm.MainActivity.Companion.keys
import com.mycompany.qalqan_dsm.MainActivity.Companion.qalqan
import android.util.Log

@OptIn(ExperimentalUnsignedTypes::class)
object EncryptKeys {
    fun run(pwd: String): Boolean {
        return try {
            // 1) несколько SHA-512
            val md = MessageDigest.getInstance("SHA-512")
            md.update(pwd.toByteArray())
            var h = md.digest()
            repeat(999) { h = MessageDigest.getInstance("SHA-512").digest(h) }

            // 2) расширяем ключ
            val kekey = UByteArray(Qalqan().DEFKLEN) { i -> h[i].toUByte() }
            MainActivity.qalqan.kexp(kekey, MainActivity.keys.rKeKey, Qalqan().DEFKLEN)

            // 3) создаём файл
            val file = File(MainActivity.outputDirectory, "abc.bin")
            val out  = file.outputStream()

            // 4) пользовательские данные
            val usr = UByteArray(Qalqan().BLOCKLEN) { i -> MainActivity.keys.keys[i] }
            out.write(usr.toByteArray())

            // 5) шифруем kikey
            val kik = UByteArray(Qalqan().DEFKLEN)
            for (i in 0 until Qalqan().DEFKLEN step Qalqan().BLOCKLEN) {
                val block = MainActivity.keys.kikey.copyOfRange(i, i + Qalqan().BLOCKLEN)
                val enc   = MainActivity.qalqan.encrypt(MainActivity.keys.rKeKey, block, Qalqan().DEFKLEN)
                out.write(enc.toByteArray())
            }

            // 6) шифруем cirkeys
            MainActivity.keys.cirkeys.flatten().toUByteArray().chunked(Qalqan().BLOCKLEN).forEach { chunk ->
                val enc = MainActivity.qalqan.encrypt(MainActivity.keys.rKeKey, chunk.toUByteArray(), Qalqan().DEFKLEN)
                out.write(enc.toByteArray())
            }

            // 7) шифруем skeys
            MainActivity.keys.skeys.flatten().toUByteArray().chunked(Qalqan().BLOCKLEN).forEach { chunk ->
                val enc = MainActivity.qalqan.encrypt(MainActivity.keys.rKeKey, chunk.toUByteArray(), Qalqan().DEFKLEN)
                out.write(enc.toByteArray())
            }

            out.close()
            Log.d("EncryptKeys","Wrote abc.bin to ${file.absolutePath}, size=${file.length()}")

            Log.d("EncryptKeys","Before hash append size=${file.length()}")
            // 8) дописываем имитационный код
            Utils.appendHashToFile("abc.bin", MainActivity.keys.rKiKey)
            Log.d("EncryptKeys","After hash append size=${file.length()}")

            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
