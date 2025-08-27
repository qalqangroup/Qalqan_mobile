package com.mycompany.qalqan_dsm

import java.io.File
import java.security.MessageDigest
import java.util.*

class QKeys()
{
    val defklen: Int = 32
    val expklen: Int = 272
    private val blocklen = 16
    private val circnt: Int = 10
    private val maxskeycnt: Int = 100

    var user_num: Int = -1
    var cur_skey: Int = 0
    @OptIn(ExperimentalUnsignedTypes::class)
    var kikey = UByteArray(defklen)
    @OptIn(ExperimentalUnsignedTypes::class)
    var cirkeys = Vector<UByteArray>()
    @OptIn(ExperimentalUnsignedTypes::class)
    var skeys = Vector<UByteArray>()
    @OptIn(ExperimentalUnsignedTypes::class)
    var rKeKey = UByteArray(expklen)
    @OptIn(ExperimentalUnsignedTypes::class)
    var rKiKey = UByteArray(expklen)
    @OptIn(ExperimentalUnsignedTypes::class)
    var keys = UByteArray(blocklen + circnt*defklen + maxskeycnt*defklen)
    @OptIn(ExperimentalUnsignedTypes::class)
    fun AddKeys(_keys: UByteArray)
    {
        keys = _keys
    }
    @OptIn(ExperimentalUnsignedTypes::class)
    fun AddKikey(_key: UByteArray)
    {
        kikey = _key
    }
    @OptIn(ExperimentalUnsignedTypes::class)
    fun CopyKeys()
    {
        user_num = keys[0].toInt()
        for(i in 0 until circnt)
        {
            val ck = UByteArray(defklen)
            for(j in 0 until defklen)
                ck[j] = keys[blocklen + j + (i * defklen)]
            cirkeys.add(ck)
        }
        val skcnt = ((keys.size - blocklen) / defklen) - circnt
        cur_skey = maxskeycnt - skcnt
        for(i in 0 until skcnt)
        {
            val sk = UByteArray(defklen)
            for(j in 0 until defklen)
                sk[j] = keys[blocklen + j + (i * defklen + circnt * defklen)]
            skeys.add(sk)
        }
    }
}