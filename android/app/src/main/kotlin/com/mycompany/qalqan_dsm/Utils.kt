package com.mycompany.qalqan_dsm

import java.io.*
import java.io.ByteArrayInputStream
import java.time.LocalDateTime
import com.mycompany.qalqan_dsm.MainActivity.Companion.outputDirectory
import com.mycompany.qalqan_dsm.MainActivity.Companion.keys
import com.mycompany.qalqan_dsm.MainActivity.Companion.qalqan
import com.mycompany.qalqan_dsm.MainActivity.Companion.keyfilename
import android.util.Log

object Utils {

    // результаты decryptInternal
    private var lastOutputFile: String = ""
    private var decryptedText:  String = ""

    /** Flutter вызывает, чтобы узнать, куда пишет Kotlin */
    fun getOutputDir(): String = outputDirectory.absolutePath

    /** Геттеры для MainActivity */
    fun getLastOutputFile(): String = lastOutputFile
    fun getDecryptedText(): String  = decryptedText

    /** Шифрует произвольный файл по пути и возвращает имя нового файла */
    @OptIn(ExperimentalUnsignedTypes::class)
    fun encryptFile(path: String, keyType: String): String {
        val bytes = File(path).readBytes()
        return encryptData(ByteArrayInputStream(bytes), bytes.size, 1, File(path).name, keyType)
    }

    /** Шифрует фото-файл по пути */
    @OptIn(ExperimentalUnsignedTypes::class)
    fun encryptPhoto(path: String, keyType: String): String {
        val bytes = File(path).readBytes()
        return encryptData(ByteArrayInputStream(bytes), bytes.size, 2, null, keyType)
    }

    /** Шифрует видео-файл по пути */
    @OptIn(ExperimentalUnsignedTypes::class)
    fun encryptVideo(path: String, keyType: String): String {
        val bytes = File(path).readBytes()
        return encryptData(ByteArrayInputStream(bytes), bytes.size, 3, null, keyType)
    }

    /** Шифрует текстовое сообщение и возвращает имя .bin */
    @OptIn(ExperimentalUnsignedTypes::class)
    fun encryptText(text: String, keyType: String): String {
        val bytes = text.toByteArray()
        return encryptData(ByteArrayInputStream(bytes), bytes.size, 4, null, keyType)
    }

    /** Шифрует аудио-файл по пути (например, .3gp) */
    @OptIn(ExperimentalUnsignedTypes::class)
    fun encryptAudio(path: String, keyType: String): String {
        val ub = File(path).readBytes().toUByteArray()
        return encryptData(ByteArrayInputStream(ub.toByteArray()), ub.size, 5, null, keyType)
    }

    /**
     * Основная функция, копирует код MenuPageActivity.encryptfiledata:
     * data  — входной InputStream,
     * flen  — длина в байтах,
     * type  — 1..5 (file, photo, video, text, audio),
     * origName — оригинальное имя (для type=1), иначе null.
     */
    @OptIn(ExperimentalUnsignedTypes::class)
    private fun encryptData(
        data: ByteArrayInputStream,
        flen: Int,
        type: Int,
        origName: String?,
        keyType: String
    ): String {
        val now = LocalDateTime.now()
        val time = "${now.year}_${now.monthValue}_${now.dayOfMonth}_${now.hour}_${now.minute}"
        val outName = if (type == 1 && origName != null) {
            "${origName}.bin"
        } else {
            "file_${time}.bin"
        }

        val outFile = File(outputDirectory, outName)
        val out = outFile.outputStream()

        var iv = UByteArray(qalqan.BLOCKLEN)
        val rKey = UByteArray(qalqan.EXPKLEN)
        var rnds: Int = 0

        // Выбор типа ключа: All или Session
        val useAll = keyType.equals("all", ignoreCase = true)
        val key: UByteArray
        if (useAll) {
            rnds = (0 until keys.cirkeys.size).shuffled().first()
            key = keys.cirkeys[rnds]
        } else {
            rnds = 0
            key = keys.skeys.removeAt(0)
            // удаляем старый ключ-файл
            deletekeys(keyfilename)
        }

        qalqan.kexp(key, rKey, qalqan.DEFKLEN)

        for (i in 0 until 4) {
            iv[i] = iv[i] xor now.hour.toUByte()
            iv[i + 4] = iv[i + 4] xor now.second.toUByte()
            iv[i + 8] = iv[i + 8] xor now.minute.toUByte()
            iv[i + 12] = iv[i + 12] xor now.monthValue.toUByte()
        }
        iv = qalqan.encrypt(rKey, iv, qalqan.DEFKLEN)

        val serviceInfo = UByteArray(qalqan.BLOCKLEN).apply {
            this[0] = 0x00.toUByte()
            this[1] = keys.user_num.toUByte()
            this[2] = 0x04.toUByte()
            this[3] = qalqan.DEFKLEN.toUByte()
            this[4] = when (type) {
                1 -> 0x00.toUByte()
                2 -> 0x77.toUByte()
                3 -> 0x88.toUByte()
                4 -> 0x66.toUByte()
                else -> 0x55.toUByte()
            }
            if(useAll)
                this[5] = 0x00.toUByte()
            else
                this[5] = 0x01.toUByte()
            this[6] = rnds.toUByte()
            this[7] = keys.cur_skey.toUByte()
        }
        val serviceHash = qalqan.encrypt(keys.rKiKey, serviceInfo, qalqan.DEFKLEN)

        // 6) записываем заголовок + хэш
        out.write(serviceInfo.asByteArray())
        out.write(serviceHash.asByteArray())

        // 7) собственно OFB-шифрование данных
        qalqan.encrypt_ofb_data(rKey, iv.asByteArray(), flen, data, out)
        out.close()

        // 8) дописываем имитационный код
        appendHashToFile(outName, keys.rKiKey)

        // 9) увеличиваем счётчик сессионного ключа
        keys.cur_skey += 1

        return outName
    }

    /** Полная реализация deletekeys, как в MenuPageActivity */
    @OptIn(ExperimentalUnsignedTypes::class)
    fun deletekeys(file: File) {
        val outstream = file.outputStream()

        val usrnum = UByteArray(qalqan.BLOCKLEN)
        for (i in 0 until qalqan.BLOCKLEN) {
            usrnum[i] = keys.keys[i]
        }
        outstream.write(usrnum.toByteArray())

        val kik = UByteArray(qalqan.DEFKLEN)
        var temp1 = UByteArray(qalqan.BLOCKLEN)
        for (i in 0 until qalqan.DEFKLEN step qalqan.BLOCKLEN) {
            for (j in 0 until qalqan.BLOCKLEN) {
                temp1[j] = keys.kikey[i + j]
            }
            temp1 = qalqan.encrypt(keys.rKeKey, temp1, qalqan.DEFKLEN)
            for (k in 0 until qalqan.BLOCKLEN) {
                kik[k + i] = temp1[k]
            }
        }
        outstream.write(kik.toByteArray())

        val encrKeys = keys.cirkeys.flatten().toUByteArray()
        for (i in 0 until encrKeys.size step qalqan.BLOCKLEN) {
            val curKey = UByteArray(qalqan.BLOCKLEN)
            for (j in 0 until qalqan.BLOCKLEN) {
                curKey[j] = encrKeys[i + j]
            }
            val tmp = qalqan.encrypt(keys.rKeKey, curKey, qalqan.DEFKLEN)
            outstream.write(tmp.toByteArray())
        }

        keys.skeys.removeAt(0)
        val encrSkeys = keys.skeys.flatten().toUByteArray()
        for (i in 0 until encrSkeys.size step qalqan.BLOCKLEN) {
            val curKey = UByteArray(qalqan.BLOCKLEN)
            for (j in 0 until qalqan.BLOCKLEN) {
                curKey[j] = encrSkeys[i + j]
            }
            val tmp = qalqan.encrypt(keys.rKeKey, curKey, qalqan.DEFKLEN)
            outstream.write(tmp.toByteArray())
        }
        outstream.close()
        appendHashToFile(file.name, keys.rKiKey)
    }

    /** Точно как раньше: дописываем в конец hmac-хеш */
    @OptIn(ExperimentalUnsignedTypes::class)
    fun appendHashToFile(filename: String, userKey: UByteArray) {
        // берём папку из MainActivity
        val file = File(MainActivity.outputDirectory, filename)
        file.inputStream().use { input ->
            // вычисляем имитационный код
            val hash = MainActivity.qalqan.qalqanImit(userKey, file.length(), input)
            // дописываем в конец
            file.appendBytes(hash.asByteArray())
        }
    }

    /**
     * Расшифровка общего файла.
     * Возвращает Map-like payload:
     * 1..5 = коды, 3/4/5 прилагают lastOutputFile/text
     */

    /** Принимает полный путь и сразу расшифровывает */
    fun decryptFileFullPath(fullPath: String): Int {
        val infile = File(fullPath)
        // если нужно — скопировать в outputDirectory или сразу читать из него
        val name = infile.name
        if (infile.parentFile?.absolutePath != outputDirectory.absolutePath) {
            infile.copyTo(File(outputDirectory, name), overwrite = true)
        }
        return decryptFile(name)
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun decryptFile(infileName: String): Int {

        val infile = File(outputDirectory, infileName)
        if (!infile.exists()) return 1  // файл не найден

        Log.d("QalqanDecrypt", "=== decryptFile start ===")
        Log.d("QalqanDecrypt", "Input file: ${infile.absolutePath}")
        Log.d("QalqanDecrypt", "File exists: ${infile.exists()}, length=${infile.length()}")

        val totalLen     = infile.length()
        val serviceInfo  = UByteArray(qalqan.BLOCKLEN)
        val realServHash = UByteArray(qalqan.BLOCKLEN)

        // 1) Сервисный хеш
        FileInputStream(infile).use { stream ->
            Log.d("QalqanDecrypt", "Reading serviceInfo + serviceHash")
            stream.read(serviceInfo.asByteArray())
            stream.read(realServHash.asByteArray())

            Log.d("QalqanDecrypt", "serviceInfo: ${serviceInfo.joinToString { it.toString(16).padStart(2,'0') }}")
            Log.d("QalqanDecrypt", "realServiceHash: ${realServHash.joinToString { it.toString(16).padStart(2,'0') }}")

            val computed = qalqan.encrypt(keys.rKiKey, serviceInfo, qalqan.DEFKLEN)
            Log.d("QalqanDecrypt", "computedServiceHash: ${computed.joinToString { it.toString(16).padStart(2,'0') }}")
            if (realServHash.zip(computed.asList()).any { (r, c) -> r != c }) {
                Log.e("QalqanDecrypt", "Service hash mismatch → abort code=1")
                return 1
            }
        }

        // 2) Общий HMAC
        if (!checkHash(infile, keys.rKiKey)) {
            Log.e("QalqanDecrypt", "Overall HMAC mismatch → abort code=2")
            return 2
        }

        // 3) Расшифровка контента
        FileInputStream(infile).use { dataStream ->
            dataStream.skip((qalqan.BLOCKLEN * 2).toLong())
            val flen = totalLen - (qalqan.BLOCKLEN * 3)
            Log.d("QalqanDecrypt", "Skipping header. Data length to decrypt = $flen bytes")

            // Выбор ключа
            val rkey = UByteArray(qalqan.EXPKLEN)
            if (serviceInfo[5] == 0x00.toUByte()) {
                val idx = serviceInfo[6].toInt()
                Log.d("QalqanDecrypt", "Using ALL key at index $idx")
                qalqan.kexp(keys.cirkeys[idx], rkey, qalqan.DEFKLEN)
            } else {
                val idx = serviceInfo[7].toInt()
                Log.d("QalqanDecrypt", "Using SESSION key at index $idx")
                qalqan.kexp(keys.skeys[idx], rkey, qalqan.DEFKLEN)
                keys.cur_skey += 1
                Log.d("QalqanDecrypt", "Session key consumed, cur_skey now ${keys.cur_skey}")
                deletekeys(keyfilename)
            }

            // Вспомогательная лямбда для записи в outputDirectory
            fun writeOut(ext: String, block: (FileOutputStream) -> Unit): String {
                val name = "dec_${infile.nameWithoutExtension}.$ext"
                val outFile = File(MainActivity.cacheDirectory, name)
                FileOutputStream(outFile).use { os: FileOutputStream -> block(os) }
                lastOutputFile = name
                return name
            }

            return when (serviceInfo[4].toInt()) {
                0x77 -> { writeOut("jpg") { os -> qalqan.decrypt_ofb(rkey, flen, dataStream, os) }; 3 }
                0x88 -> { writeOut("mp4") { os -> qalqan.decrypt_ofb(rkey, flen, dataStream, os) }; 4 }
                0x66 -> {
                    val buff = UByteArray(flen.toInt())
                    qalqan.decrypt_ofb_data(rkey, flen, dataStream, buff)
                    decryptedText = buff.toByteArray().toString(Charsets.UTF_8)
                    5
                }
                0x55 -> { writeOut("3gp") { os -> qalqan.decrypt_ofb(rkey, flen, dataStream, os) }; 7 }
                else -> { // generic file: strip only the trailing ".bin"
                    val baseName = infile.nameWithoutExtension  // из "clear.txt.bin" получит "clear.txt"
                    val outFile = File(outputDirectory, baseName)
                    FileOutputStream(outFile).use { os ->
                        Log.d("QalqanDecrypt", "Writing generic file: ${outFile.absolutePath}")
                        qalqan.decrypt_ofb(rkey, flen, dataStream, os)
                    }
                    lastOutputFile = baseName
                    Log.d("QalqanDecrypt", "Finished generic decrypt → $baseName")
                    6
                }
            }
        }
    }

    /** Общая проверка HMAC для файла */
    @OptIn(ExperimentalUnsignedTypes::class)
    fun checkHash(infile: File, userKey: UByteArray): Boolean {
        val total = infile.length()
        FileInputStream(infile).use { stream ->
            Log.d("QalqanDecrypt", "checkHash start — file=${infile.absolutePath} total=$total")

            // Считаем HMAC по первым total - BLOCKLEN байтам (это serviceInfo + serviceHash + data)
            val computed = qalqan.qalqanImit(userKey, total - qalqan.BLOCKLEN, stream)
            Log.d("QalqanDecrypt", "computed HMAC: ${computed.joinToString("") { it.toString(16).padStart(2,'0') }}")

            // Теперь находимся **именно** в позиции (total - BLOCKLEN)
            // читаем «реальный» HMAC, который был дописан в конце
            val real = ByteArray(qalqan.BLOCKLEN)
            stream.read(real)
            Log.d("QalqanDecrypt", "   real HMAC: ${real.joinToString("") { (it.toUByte()).toString(16).padStart(2,'0') }}")

            return real.withIndex().all { (i, b) -> b.toUByte() == computed[i] }
        }
    }
}