package com.mycompany.qalqan_dsm

import java.io.ByteArrayInputStream
import java.io.FileInputStream
import java.io.FileOutputStream

class Qalqan {
    val BLOCKLEN: Int = 16
    val DEFKLEN: Int = 32
    val EXPKLEN: Int = 272
    private val SHIFT: Int = 17

    @OptIn(ExperimentalUnsignedTypes::class)
    val sb = ubyteArrayOf(	0xd1.toUByte(), 0xb5.toUByte(), 0xa6.toUByte(), 0x74.toUByte(), 0x2f.toUByte(), 0xb2.toUByte(), 0x03.toUByte(), 0x77.toUByte(), 0xae.toUByte(), 0xb3.toUByte(), 0x60.toUByte(), 0x95.toUByte(), 0xfd.toUByte(), 0xf8.toUByte(), 0xc7.toUByte(), 0xf0.toUByte(),
        0x2b.toUByte(), 0xce.toUByte(), 0xa5.toUByte(), 0x91.toUByte(), 0x4c.toUByte(), 0x6f.toUByte(), 0xf3.toUByte(), 0x4f.toUByte(), 0x82.toUByte(), 0x01.toUByte(), 0x45.toUByte(), 0x76.toUByte(), 0x9f.toUByte(), 0xed.toUByte(), 0x41.toUByte(), 0xfb.toUByte(),
        0xac.toUByte(), 0x4e.toUByte(), 0x5e.toUByte(), 0x04.toUByte(), 0xeb.toUByte(), 0xf9.toUByte(), 0xf1.toUByte(), 0x3a.toUByte(), 0x1f.toUByte(), 0xe2.toUByte(), 0x8e.toUByte(), 0xe7.toUByte(), 0x85.toUByte(), 0x35.toUByte(), 0xdb.toUByte(), 0x52.toUByte(),
        0x78.toUByte(), 0xa1.toUByte(), 0xfc.toUByte(), 0xa2.toUByte(), 0xde.toUByte(), 0x68.toUByte(), 0x02.toUByte(), 0x4d.toUByte(), 0xf6.toUByte(), 0xdd.toUByte(), 0xcf.toUByte(), 0xa3.toUByte(), 0xdc.toUByte(), 0x6b.toUByte(), 0x81.toUByte(), 0x44.toUByte(),
        0x2a.toUByte(), 0x5d.toUByte(), 0x1e.toUByte(), 0xe0.toUByte(), 0x53.toUByte(), 0x71.toUByte(), 0x3b.toUByte(), 0xc1.toUByte(), 0xcc.toUByte(), 0x9d.toUByte(), 0x80.toUByte(), 0xd5.toUByte(), 0x84.toUByte(), 0x00.toUByte(), 0x24.toUByte(), 0x4b.toUByte(),
        0xb6.toUByte(), 0x83.toUByte(), 0x0d.toUByte(), 0x87.toUByte(), 0x7e.toUByte(), 0x86.toUByte(), 0xca.toUByte(), 0x96.toUByte(), 0xbe.toUByte(), 0x5a.toUByte(), 0xe6.toUByte(), 0xd0.toUByte(), 0xd4.toUByte(), 0xd8.toUByte(), 0x55.toUByte(), 0xc0.toUByte(),
        0x05.toUByte(), 0xe5.toUByte(), 0xe9.toUByte(), 0x5b.toUByte(), 0x47.toUByte(), 0xe4.toUByte(), 0x2d.toUByte(), 0x34.toUByte(), 0x13.toUByte(), 0x88.toUByte(), 0x48.toUByte(), 0x32.toUByte(), 0x38.toUByte(), 0xb9.toUByte(), 0xda.toUByte(), 0xc9.toUByte(),
        0x42.toUByte(), 0x29.toUByte(), 0xd7.toUByte(), 0xf2.toUByte(), 0x9b.toUByte(), 0x6d.toUByte(), 0xe8.toUByte(), 0x8d.toUByte(), 0x12.toUByte(), 0x7c.toUByte(), 0x8c.toUByte(), 0x3f.toUByte(), 0xbc.toUByte(), 0x3c.toUByte(), 0x1b.toUByte(), 0xc5.toUByte(),
        0x69.toUByte(), 0x22.toUByte(), 0x97.toUByte(), 0xaa.toUByte(), 0x73.toUByte(), 0x0a.toUByte(), 0x0c.toUByte(), 0x8a.toUByte(), 0x90.toUByte(), 0x31.toUByte(), 0xc4.toUByte(), 0x33.toUByte(), 0xe1.toUByte(), 0x8b.toUByte(), 0x9c.toUByte(), 0x63.toUByte(),
        0x5f.toUByte(), 0xf5.toUByte(), 0xf7.toUByte(), 0xff.toUByte(), 0x79.toUByte(), 0x49.toUByte(), 0xd3.toUByte(), 0xc6.toUByte(), 0x7b.toUByte(), 0x1a.toUByte(), 0x39.toUByte(), 0xc8.toUByte(), 0x6e.toUByte(), 0x72.toUByte(), 0xd9.toUByte(), 0xc3.toUByte(),
        0x62.toUByte(), 0x28.toUByte(), 0xbd.toUByte(), 0xbb.toUByte(), 0xfa.toUByte(), 0x2e.toUByte(), 0xbf.toUByte(), 0x43.toUByte(), 0x06.toUByte(), 0x0b.toUByte(), 0x7a.toUByte(), 0x64.toUByte(), 0x5c.toUByte(), 0x92.toUByte(), 0x37.toUByte(), 0x3d.toUByte(),
        0x66.toUByte(), 0x26.toUByte(), 0x51.toUByte(), 0xef.toUByte(), 0x0f.toUByte(), 0xa9.toUByte(), 0x14.toUByte(), 0x70.toUByte(), 0x16.toUByte(), 0x17.toUByte(), 0x10.toUByte(), 0x19.toUByte(), 0x93.toUByte(), 0x09.toUByte(), 0x59.toUByte(), 0x15.toUByte(),
        0xfe.toUByte(), 0x4a.toUByte(), 0xcb.toUByte(), 0x2c.toUByte(), 0xcd.toUByte(), 0xb8.toUByte(), 0x94.toUByte(), 0xab.toUByte(), 0xdf.toUByte(), 0xa7.toUByte(), 0x0e.toUByte(), 0x30.toUByte(), 0xaf.toUByte(), 0x56.toUByte(), 0x23.toUByte(), 0xb1.toUByte(),
        0xb0.toUByte(), 0x58.toUByte(), 0x7d.toUByte(), 0xc2.toUByte(), 0x1d.toUByte(), 0x50.toUByte(), 0x20.toUByte(), 0x61.toUByte(), 0x25.toUByte(), 0x89.toUByte(), 0xa0.toUByte(), 0x6c.toUByte(), 0x11.toUByte(), 0x54.toUByte(), 0x98.toUByte(), 0xb7.toUByte(),
        0x18.toUByte(), 0x21.toUByte(), 0xad.toUByte(), 0x3e.toUByte(), 0xd2.toUByte(), 0xea.toUByte(), 0x40.toUByte(), 0xd6.toUByte(), 0xf4.toUByte(), 0xa4.toUByte(), 0x8f.toUByte(), 0xa8.toUByte(), 0x08.toUByte(), 0x57.toUByte(), 0xba.toUByte(), 0xee.toUByte(),
        0x75.toUByte(), 0x6a.toUByte(), 0x07.toUByte(), 0x99.toUByte(), 0x7f.toUByte(), 0x1c.toUByte(), 0xe3.toUByte(), 0x46.toUByte(), 0x67.toUByte(), 0xec.toUByte(), 0x27.toUByte(), 0x36.toUByte(), 0xb4.toUByte(), 0x65.toUByte(), 0x9e.toUByte(), 0x9a.toUByte())

    @OptIn(ExperimentalUnsignedTypes::class)
    val isb = ubyteArrayOf(0x4d.toUByte(), 0x19.toUByte(), 0x36.toUByte(), 0x06.toUByte(), 0x23.toUByte(), 0x60.toUByte(), 0xa8.toUByte(), 0xf2.toUByte(), 0xec.toUByte(), 0xbd.toUByte(), 0x85.toUByte(), 0xa9.toUByte(), 0x86.toUByte(), 0x52.toUByte(), 0xca.toUByte(), 0xb4.toUByte(),
        0xba.toUByte(), 0xdc.toUByte(), 0x78.toUByte(), 0x68.toUByte(), 0xb6.toUByte(), 0xbf.toUByte(), 0xb8.toUByte(), 0xb9.toUByte(), 0xe0.toUByte(), 0xbb.toUByte(), 0x99.toUByte(), 0x7e.toUByte(), 0xf5.toUByte(), 0xd4.toUByte(), 0x42.toUByte(), 0x28.toUByte(),
        0xd6.toUByte(), 0xe1.toUByte(), 0x81.toUByte(), 0xce.toUByte(), 0x4e.toUByte(), 0xd8.toUByte(), 0xb1.toUByte(), 0xfa.toUByte(), 0xa1.toUByte(), 0x71.toUByte(), 0x40.toUByte(), 0x10.toUByte(), 0xc3.toUByte(), 0x66.toUByte(), 0xa5.toUByte(), 0x04.toUByte(),
        0xcb.toUByte(), 0x89.toUByte(), 0x6b.toUByte(), 0x8b.toUByte(), 0x67.toUByte(), 0x2d.toUByte(), 0xfb.toUByte(), 0xae.toUByte(), 0x6c.toUByte(), 0x9a.toUByte(), 0x27.toUByte(), 0x46.toUByte(), 0x7d.toUByte(), 0xaf.toUByte(), 0xe3.toUByte(), 0x7b.toUByte(),
        0xe6.toUByte(), 0x1e.toUByte(), 0x70.toUByte(), 0xa7.toUByte(), 0x3f.toUByte(), 0x1a.toUByte(), 0xf7.toUByte(), 0x64.toUByte(), 0x6a.toUByte(), 0x95.toUByte(), 0xc1.toUByte(), 0x4f.toUByte(), 0x14.toUByte(), 0x37.toUByte(), 0x21.toUByte(), 0x17.toUByte(),
        0xd5.toUByte(), 0xb2.toUByte(), 0x2f.toUByte(), 0x44.toUByte(), 0xdd.toUByte(), 0x5e.toUByte(), 0xcd.toUByte(), 0xed.toUByte(), 0xd1.toUByte(), 0xbe.toUByte(), 0x59.toUByte(), 0x63.toUByte(), 0xac.toUByte(), 0x41.toUByte(), 0x22.toUByte(), 0x90.toUByte(),
        0x0a.toUByte(), 0xd7.toUByte(), 0xa0.toUByte(), 0x8f.toUByte(), 0xab.toUByte(), 0xfd.toUByte(), 0xb0.toUByte(), 0xf8.toUByte(), 0x35.toUByte(), 0x80.toUByte(), 0xf1.toUByte(), 0x3d.toUByte(), 0xdb.toUByte(), 0x75.toUByte(), 0x9c.toUByte(), 0x15.toUByte(),
        0xb7.toUByte(), 0x45.toUByte(), 0x9d.toUByte(), 0x84.toUByte(), 0x03.toUByte(), 0xf0.toUByte(), 0x1b.toUByte(), 0x07.toUByte(), 0x30.toUByte(), 0x94.toUByte(), 0xaa.toUByte(), 0x98.toUByte(), 0x79.toUByte(), 0xd2.toUByte(), 0x54.toUByte(), 0xf4.toUByte(),
        0x4a.toUByte(), 0x3e.toUByte(), 0x18.toUByte(), 0x51.toUByte(), 0x4c.toUByte(), 0x2c.toUByte(), 0x55.toUByte(), 0x53.toUByte(), 0x69.toUByte(), 0xd9.toUByte(), 0x87.toUByte(), 0x8d.toUByte(), 0x7a.toUByte(), 0x77.toUByte(), 0x2a.toUByte(), 0xea.toUByte(),
        0x88.toUByte(), 0x13.toUByte(), 0xad.toUByte(), 0xbc.toUByte(), 0xc6.toUByte(), 0x0b.toUByte(), 0x57.toUByte(), 0x82.toUByte(), 0xde.toUByte(), 0xf3.toUByte(), 0xff.toUByte(), 0x74.toUByte(), 0x8e.toUByte(), 0x49.toUByte(), 0xfe.toUByte(), 0x1c.toUByte(),
        0xda.toUByte(), 0x31.toUByte(), 0x33.toUByte(), 0x3b.toUByte(), 0xe9.toUByte(), 0x12.toUByte(), 0x02.toUByte(), 0xc9.toUByte(), 0xeb.toUByte(), 0xb5.toUByte(), 0x83.toUByte(), 0xc7.toUByte(), 0x20.toUByte(), 0xe2.toUByte(), 0x08.toUByte(), 0xcc.toUByte(),
        0xd0.toUByte(), 0xcf.toUByte(), 0x05.toUByte(), 0x09.toUByte(), 0xfc.toUByte(), 0x01.toUByte(), 0x50.toUByte(), 0xdf.toUByte(), 0xc5.toUByte(), 0x6d.toUByte(), 0xee.toUByte(), 0xa3.toUByte(), 0x7c.toUByte(), 0xa2.toUByte(), 0x58.toUByte(), 0xa6.toUByte(),
        0x5f.toUByte(), 0x47.toUByte(), 0xd3.toUByte(), 0x9f.toUByte(), 0x8a.toUByte(), 0x7f.toUByte(), 0x97.toUByte(), 0x0e.toUByte(), 0x9b.toUByte(), 0x6f.toUByte(), 0x56.toUByte(), 0xc2.toUByte(), 0x48.toUByte(), 0xc4.toUByte(), 0x11.toUByte(), 0x3a.toUByte(),
        0x5b.toUByte(), 0x00.toUByte(), 0xe4.toUByte(), 0x96.toUByte(), 0x5c.toUByte(), 0x4b.toUByte(), 0xe7.toUByte(), 0x72.toUByte(), 0x5d.toUByte(), 0x9e.toUByte(), 0x6e.toUByte(), 0x2e.toUByte(), 0x3c.toUByte(), 0x39.toUByte(), 0x34.toUByte(), 0xc8.toUByte(),
        0x43.toUByte(), 0x8c.toUByte(), 0x29.toUByte(), 0xf6.toUByte(), 0x65.toUByte(), 0x61.toUByte(), 0x5a.toUByte(), 0x2b.toUByte(), 0x76.toUByte(), 0x62.toUByte(), 0xe5.toUByte(), 0x24.toUByte(), 0xf9.toUByte(), 0x1d.toUByte(), 0xef.toUByte(), 0xb3.toUByte(),
        0x0f.toUByte(), 0x26.toUByte(), 0x73.toUByte(), 0x16.toUByte(), 0xe8.toUByte(), 0x91.toUByte(), 0x38.toUByte(), 0x92.toUByte(), 0x0d.toUByte(), 0x25.toUByte(), 0xa4.toUByte(), 0x1f.toUByte(), 0x32.toUByte(), 0x0c.toUByte(), 0xc0.toUByte(), 0x93.toUByte())


    private fun rNDS(nr: Int): Int {
        return 16 + (nr - 32) / BLOCKLEN
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun kexp(key: UByteArray, rkey: UByteArray, keylen: Int){
        val r0 = UByteArray(17)
        val r1 = UByteArray(15)
        var step = 0
        var s = SHIFT
        val addk = keylen - 32
        for(i in 0 until 15){
            r0[i] = key[2 * i]
            r1[i] = key[2 * i + 1]
        }
        r0[15] = key[30]
        r0[16] = key[31]
        for(r in 0 until rNDS(keylen)){
            for(k in 0 until BLOCKLEN + s){
                var t0 = (sb[r0[0].toInt()] + r0[1] + sb[r0[3].toInt()] + r0[7] + sb[r0[12].toInt()] + r0[16]).toInt()
                var t1 = (sb[r1[0].toInt()] + r1[3] + sb[r1[9].toInt()] + r1[12] + sb[r1[14].toInt()]).toInt()
                for(i in 0 until 14){
                    r0[i] = r0[i + 1]
                    r1[i] = r1[i + 1]
                }
                r0[14] = r0[15]
                r0[15] = r0[16]
                if(k >= s){
                    rkey[r * BLOCKLEN + k - s] = (t0 + r1[4].toInt()).toUByte()
                    if(step < addk){
                        if(step.and(1) == 1){
                            t0 += (key[32 + step]).toInt()
                        }else{
                            t1 += (key[32 + step]).toInt()
                        }
                        step++
                    }
                }
                r0[16] = t0.toUByte()
                r1[14] = t1.toUByte()
            }
            s = 0
        }
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun addRkeyX(block: UByteArray, rkey: UByteArray, nr: Int): UByteArray{
        val res = UByteArray(BLOCKLEN)
        if(nr == 0){
            for(i in 0 until BLOCKLEN){
                res[i] = block[i] xor (rkey[i])
            }
        }else{
            for(i in 0 until BLOCKLEN){
                res[i] = block[i] xor rkey[nr * BLOCKLEN + i]
            }
        }
        return res
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun addRK(block: UByteArray, rkey: UByteArray, nr: Int): UByteArray{
        val res = UByteArray(BLOCKLEN)
        var tmp = block[0].toInt() + rkey[BLOCKLEN * nr].toInt()
        res[0] = tmp.toUByte()
        tmp /= 256
        for(i in 1 until BLOCKLEN){
            tmp += block[i].toInt() + rkey[BLOCKLEN * nr + i].toInt()
            res[i] = tmp.toUByte()
            tmp /= 256
        }
        return res
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun sbox(block: UByteArray): UByteArray{
        val res = UByteArray(BLOCKLEN)
        for(i in 0 until BLOCKLEN){
            res[i] = sb[block[i].toInt()]
        }
        return res
    }

    private val c0 = arrayOf(1, 17, 14)
    private fun rotl(value: UInt, shift: Int): UInt {
        return (value shl shift) or (value shr (32 - shift))
    }
    private fun linOp(din: Array<UInt>, dout: Array<UInt>) {
        dout[0] = din[0] xor rotl(din[1], c0[0]) xor rotl(din[2], c0[1]) xor rotl(din[3], c0[2])
        dout[1] = din[1] xor rotl(din[2], c0[0]) xor rotl(din[3], c0[1]) xor rotl(dout[0], c0[2])
        dout[2] = din[2] xor rotl(din[3], c0[0]) xor rotl(dout[0], c0[1]) xor rotl(dout[1], c0[2])
        dout[3] = din[3] xor rotl(dout[0], c0[0]) xor rotl(dout[1], c0[1]) xor rotl(dout[2], c0[2])
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun encrypt(rkey: UByteArray, clear: UByteArray, klen: Int): UByteArray{
        var block = addRK(clear, rkey, 0)
        var block2 = sbox(block)
        val blk = arrayOf(0u, 0u, 0u, 0u)
        var blk2 = Array(4){index -> (block2[index*4 + 3].toUInt() shl 24) or
                (block2[index*4 + 2].toUInt() shl 16) or
                (block2[index*4 + 1].toUInt() shl 8) or
                (block2[index*4].toUInt())}
        linOp(blk2, blk)
        for(i in blk.indices){
            block[i * 4 + 3] = (blk[i] shr 24).toUByte()
            block[i * 4 + 2] = (blk[i] shr 16).toUByte()
            block[i * 4 + 1] = (blk[i] shr 8).toUByte()
            block[i * 4] = (blk[i]).toUByte()
        }
        for(i in 1 until rNDS(klen) - 1){
            block2 = addRkeyX(block, rkey, i)
            block2 = sbox(block2)
            blk2 = Array(4){j -> (block2[j*4 + 3].toUInt() shl 24) or
                            (block2[j*4 + 2].toUInt() shl 16) or
                            (block2[j*4 + 1].toUInt() shl 8) or
                            (block2[j*4].toUInt())}
            linOp(blk2, blk)
            for(j in blk.indices){
                block[j * 4 + 3] = (blk[j] shr 24).toUByte()
                block[j * 4 + 2] = (blk[j] shr 16).toUByte()
                block[j * 4 + 1] = (blk[j] shr 8).toUByte()
                block[j * 4] = (blk[j]).toUByte()
            }
        }
        block = addRK(block, rkey, rNDS(klen) - 1)
        return block
    }

    private fun invlinOp(din: Array<UInt>, dout: Array<UInt>) {
        dout[3] = din[3] xor rotl(din[0], c0[0]) xor rotl(din[1], c0[1]) xor rotl(din[2], c0[2])
        dout[2] = din[2] xor rotl(dout[3], c0[0]) xor rotl(din[0], c0[1]) xor rotl(din[1], c0[2])
        dout[1] = din[1] xor rotl(dout[2], c0[0]) xor rotl(dout[3], c0[1]) xor rotl(din[0], c0[2])
        dout[0] = din[0] xor rotl(dout[1], c0[0]) xor rotl(dout[2], c0[1]) xor rotl(dout[3], c0[2])
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun invsbox(block: UByteArray): UByteArray{
        val res = UByteArray(BLOCKLEN)
        for(i in 0 until BLOCKLEN){
            res[i] = isb[block[i].toInt()]
        }
        return res
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun invaddRK(block: UByteArray, rkey: UByteArray, nr: Int): UByteArray{
        val res = UByteArray(BLOCKLEN)
        var tmp = block[0].toInt() - rkey[BLOCKLEN * nr].toInt()
        res[0] = tmp.toUByte()
        tmp = tmp shr 8
        for(i in 1 until BLOCKLEN){
            tmp += block[i].toInt() - rkey[BLOCKLEN * nr + i].toInt()
            res[i] = tmp.toUByte()
            tmp = tmp shr 8
        }
        return res
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun decrypt(rkey: UByteArray, clear: UByteArray, klen: Int): UByteArray{
        var block = invaddRK(clear, rkey, rNDS(klen) - 1)
        var block2 = UByteArray(BLOCKLEN)
        var blk = Array(4){index -> (block[index*4 + 3].toUInt() shl 24) or
                (block[index*4 + 2].toUInt() shl 16) or
                (block[index*4 + 1].toUInt() shl 8) or
                (block[index*4].toUInt())}
        val blk2 = arrayOf(0u, 0u, 0u, 0u)
        for(i in rNDS(klen) - 2 downTo 1){
            invlinOp(blk, blk2)
            for(j in blk2.indices){
                block2[j * 4 + 3] = (blk2[j] shr 24).toUByte()
                block2[j * 4 + 2] = (blk2[j] shr 16).toUByte()
                block2[j * 4 + 1] = (blk2[j] shr 8).toUByte()
                block2[j * 4] = (blk2[j]).toUByte()}
            block2 = invsbox(block2)
            block = addRkeyX(block2, rkey, i)
            blk = Array(4){index -> (block[index*4 + 3].toUInt() shl 24) or
                    (block[index*4 + 2].toUInt() shl 16) or
                    (block[index*4 + 1].toUInt() shl 8) or
                    (block[index*4].toUInt())}
        }
        blk = Array(4){index -> (block[index*4 + 3].toUInt() shl 24) or
                (block[index*4 + 2].toUInt() shl 16) or
                (block[index*4 + 1].toUInt() shl 8) or
                (block[index*4].toUInt())}
        invlinOp(blk, blk2)
        for(i in blk2.indices){
            block2[i * 4 + 3] = (blk2[i] shr 24).toUByte()
            block2[i * 4 + 2] = (blk2[i] shr 16).toUByte()
            block2[i * 4 + 1] = (blk2[i] shr 8).toUByte()
            block2[i * 4] = (blk2[i]).toUByte()}
        block2 = invsbox(block2)
        block2 = invaddRK(block2, rkey, 0)
        return block2
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun append(buf: UByteArray, len: Int){
        val addLen = BLOCKLEN - len
        if(addLen == 0){
            buf[0] = 0x80.toUByte()
            for(i in 1 until BLOCKLEN - 1)
                buf[i] = 0x00.toUByte()
            buf[15] = 0x01.toUByte()
        }
        else if(addLen == 1)
                buf[15] = 0x81.toUByte()
        else {
            buf[len] = 0x80.toUByte()
            for(i in 1 until addLen - 1)
                buf[len + i] = 0x00.toUByte()
            buf[15] = 0x01.toUByte()
        }
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun remove(buf: UByteArray): Int {
        var i = BLOCKLEN - 2
        if(buf[BLOCKLEN - 1] != 0x01.toUByte()) {
            if (buf[BLOCKLEN - 1] != 0x81.toUByte())
                return BLOCKLEN - 1
            else
                return BLOCKLEN
        }
        while (buf[i] == 0x00.toUByte()){
            i -= 1
            if( i == 0)
                return BLOCKLEN
        }
        if( buf[i] != 0x80.toUByte())
            return BLOCKLEN
        return i
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun decrypt_ofb(rkey: UByteArray, fileSize: Long, infile: FileInputStream, outfile: FileOutputStream){
        val tmp_buf = UByteArray(BLOCKLEN)
        val iv = UByteArray(BLOCKLEN)
        val cipher_buf = UByteArray(BLOCKLEN)
        var clear_buf: UByteArray

        infile.read(iv.asByteArray())
        clear_buf = encrypt(rkey, iv, DEFKLEN)
        for(i in 0 until BLOCKLEN)
            tmp_buf[i] = clear_buf[i]
        infile.read(cipher_buf.asByteArray())
        for(i in 0 until BLOCKLEN)
            clear_buf[i] = clear_buf[i] xor cipher_buf[i]
        outfile.write(clear_buf.asByteArray())
        for(i in BLOCKLEN until fileSize - (BLOCKLEN * 2) step 16){
            clear_buf = encrypt(rkey, tmp_buf, DEFKLEN)
            for(k in 0 until BLOCKLEN)
                tmp_buf[k] = clear_buf[k]
            infile.read(cipher_buf.asByteArray())
            for(j in 0 until BLOCKLEN)
                clear_buf[j] = clear_buf[j] xor cipher_buf[j]
            outfile.write(clear_buf.asByteArray())
        }
        clear_buf = encrypt(rkey, tmp_buf, DEFKLEN)
        infile.read(cipher_buf.asByteArray())
        for(j in 0 until BLOCKLEN)
            clear_buf[j] = clear_buf[j] xor cipher_buf[j]
        val rest = remove(clear_buf)
        if (rest != BLOCKLEN)
            outfile.write(clear_buf.asByteArray(), 0, rest)
    }

    /*@OptIn(ExperimentalUnsignedTypes::class)
    fun decrypt_ecb_data(rkey: UByteArray, fileSize: Long, infile: FileInputStream, decrtext: UByteArray){
        val cipher_buf = UByteArray(BLOCKLEN)
        var clear_buf = UByteArray(BLOCKLEN)

        for(k in 0 until BLOCKLEN*3 step BLOCKLEN)
        {
            infile.read(cipher_buf.asByteArray())
            for(u in 0 until BLOCKLEN)
                decrtext[(k+u).toInt()] = cipher_buf[u]
        }
        val t: Int = BLOCKLEN
        for (t in BLOCKLEN until fileSize step 16) {
            infile.read(cipher_buf.asByteArray())
            clear_buf = decrypt(rkey, cipher_buf, DEFKLEN)
            for (y in 0 until BLOCKLEN)
                decrtext[(t+y).toInt()] = clear_buf[y];
        }
    }*/
    @OptIn(ExperimentalUnsignedTypes::class)
    fun decrypt_ecb_data(rkey: UByteArray, Size: Long, indata: ByteArray, decrtext: UByteArray){
        val cipher_buf = UByteArray(BLOCKLEN)
        var clear_buf: UByteArray

        for(i in 0 until BLOCKLEN)
            decrtext[i] = indata[i].toUByte()
        for (t in BLOCKLEN until Size step 16) {
            for(i in 0 until BLOCKLEN)
                cipher_buf[i] = indata[(DEFKLEN + t + i).toInt()].toUByte()
            clear_buf = decrypt(rkey, cipher_buf, DEFKLEN)
            for (y in 0 until BLOCKLEN)
                decrtext[(t+y).toInt()] = clear_buf[y]
        }
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun decrypt_ofb_data(rkey: UByteArray, fileSize: Long, infile: FileInputStream, decrtext: UByteArray){
        val tmp_buf = UByteArray(BLOCKLEN)
        val iv = UByteArray(BLOCKLEN)
        val cipher_buf = UByteArray(BLOCKLEN)
        var clear_buf: UByteArray

        infile.read(iv.asByteArray())
        clear_buf = encrypt(rkey, iv, DEFKLEN)

        if((fileSize - (BLOCKLEN*2)).toInt() > 0) {
            for(i in 0 until BLOCKLEN)
                tmp_buf[i] = clear_buf[i]
            infile.read(cipher_buf.asByteArray())
            for(i in 0 until BLOCKLEN)
                clear_buf[i] = clear_buf[i] xor cipher_buf[i]
            for(i in 0 until BLOCKLEN)
                decrtext[i] = clear_buf[i]
            val t: Int = BLOCKLEN
            for (t in BLOCKLEN until fileSize - (BLOCKLEN * 2) step 16) {
                clear_buf = encrypt(rkey, tmp_buf, DEFKLEN)
                for (k in 0 until BLOCKLEN)
                    tmp_buf[k] = clear_buf[k]
                infile.read(cipher_buf.asByteArray())
                for (j in 0 until BLOCKLEN)
                    clear_buf[j] = clear_buf[j] xor cipher_buf[j]
                for (y in 0 until BLOCKLEN)
                    decrtext[(t+y).toInt()] = clear_buf[y]
            }
            clear_buf = encrypt(rkey, tmp_buf, DEFKLEN)
            infile.read(cipher_buf.asByteArray())
            for (j in 0 until BLOCKLEN)
                clear_buf[j] = clear_buf[j] xor cipher_buf[j]
            val rest = remove(clear_buf)
            if (rest != BLOCKLEN) {
                for (i in 0 until rest)
                    decrtext[(t+i)] = clear_buf[i]
            }
        }
        else if((fileSize - (BLOCKLEN*2)).toInt() == 0)
        {
            infile.read(cipher_buf.asByteArray())
            for (j in 0 until BLOCKLEN)
                clear_buf[j] = clear_buf[j] xor cipher_buf[j]
            val rest = remove(clear_buf)
            if (rest != BLOCKLEN) {
                for (i in 0 until rest)
                    decrtext[i] = clear_buf[i]
            }
        }
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun qalqanImit(rkey: UByteArray, fileSize: Long, infile: FileInputStream): UByteArray{
        val modLen = fileSize % BLOCKLEN
        var cipher_buf = UByteArray(BLOCKLEN)
        val clear_buf = UByteArray(BLOCKLEN)
        if(modLen.toInt() == 0){
            infile.read(clear_buf.asByteArray())
            cipher_buf = encrypt(rkey, clear_buf, DEFKLEN)
            for(i in BLOCKLEN until fileSize step 16){
                infile.read(clear_buf.asByteArray())
                for(j in 0 until BLOCKLEN)
                    cipher_buf[j] = cipher_buf[j] xor clear_buf[j]
                cipher_buf = encrypt(rkey, cipher_buf, DEFKLEN)
            }
            return cipher_buf
        }
        if(modLen.toInt() != 0){
            infile.read(clear_buf.asByteArray())
            cipher_buf = encrypt(rkey, clear_buf, DEFKLEN)
            for(i in BLOCKLEN until fileSize - modLen step 16){
                infile.read(clear_buf.asByteArray())
                for(j in 0 until BLOCKLEN)
                    cipher_buf[j] = cipher_buf[j] xor clear_buf[j]
                cipher_buf = encrypt(rkey, cipher_buf, DEFKLEN)
            }
            infile.read(clear_buf.asByteArray())
            append(clear_buf, modLen.toInt())
            for(j in 0 until BLOCKLEN)
                cipher_buf[j] = cipher_buf[j] xor clear_buf[j]
            cipher_buf = encrypt(rkey, cipher_buf, DEFKLEN)
            return cipher_buf
        }
        return cipher_buf
    }

    @OptIn(ExperimentalUnsignedTypes::class)
    fun encrypt_ofb_data(rkey: UByteArray, iv: ByteArray, len: Int, data: ByteArrayInputStream, outfile: FileOutputStream){
        val modLen = len % BLOCKLEN
        val tmp_buf = UByteArray(BLOCKLEN)
        var cipher_buf: UByteArray
        val clear_buf = UByteArray(BLOCKLEN)
        if(len < BLOCKLEN)
        {
            outfile.write(iv)
            cipher_buf = encrypt(rkey, iv.asUByteArray(), DEFKLEN)
            data.read(clear_buf.asByteArray())
            append(clear_buf, modLen)
            for (j in 0 until BLOCKLEN)
                cipher_buf[j] = cipher_buf[j] xor clear_buf[j]
            outfile.write(cipher_buf.asByteArray())
        }
        else {
            if (modLen == 0) {
                outfile.write(iv)
                cipher_buf = encrypt(rkey, iv.asUByteArray(), DEFKLEN)
                for (i in 0 until BLOCKLEN)
                    tmp_buf[i] = cipher_buf[i]
                data.read(clear_buf.asByteArray())
                for (i in 0 until BLOCKLEN)
                    cipher_buf[i] = cipher_buf[i] xor clear_buf[i]
                outfile.write(cipher_buf.asByteArray())
                for (i in BLOCKLEN until len step 16) {
                    data.read(clear_buf.asByteArray())
                    cipher_buf = encrypt(rkey, tmp_buf, DEFKLEN)
                    for (k in 0 until BLOCKLEN)
                        tmp_buf[k] = cipher_buf[k]
                    for (j in 0 until BLOCKLEN)
                        cipher_buf[j] = cipher_buf[j] xor clear_buf[j]
                    outfile.write(cipher_buf.asByteArray())
                }
                val resbuf = UByteArray(BLOCKLEN)
                append(resbuf, BLOCKLEN)
                cipher_buf = encrypt(rkey, tmp_buf, DEFKLEN)
                for (j in 0 until BLOCKLEN)
                    cipher_buf[j] = cipher_buf[j] xor resbuf[j]
                outfile.write(cipher_buf.asByteArray())
            }
            if (modLen != 0) {
                outfile.write(iv)
                cipher_buf = encrypt(rkey, iv.asUByteArray(), DEFKLEN)
                for (i in 0 until BLOCKLEN)
                    tmp_buf[i] = cipher_buf[i]
                data.read(clear_buf.asByteArray())
                for (i in 0 until BLOCKLEN)
                    cipher_buf[i] = cipher_buf[i] xor clear_buf[i]
                outfile.write(cipher_buf.asByteArray())
                for (i in BLOCKLEN until len - modLen step 16) {
                    data.read(clear_buf.asByteArray())
                    cipher_buf = encrypt(rkey, tmp_buf, DEFKLEN)
                    for (k in 0 until BLOCKLEN)
                        tmp_buf[k] = cipher_buf[k]
                    for (j in 0 until BLOCKLEN)
                        cipher_buf[j] = cipher_buf[j] xor clear_buf[j]
                    outfile.write(cipher_buf.asByteArray())
                }
                data.read(clear_buf.asByteArray())
                append(clear_buf, modLen)
                cipher_buf = encrypt(rkey, tmp_buf, DEFKLEN)
                for (j in 0 until BLOCKLEN)
                    cipher_buf[j] = cipher_buf[j] xor clear_buf[j]
                outfile.write(cipher_buf.asByteArray())
            }
        }
    }
}