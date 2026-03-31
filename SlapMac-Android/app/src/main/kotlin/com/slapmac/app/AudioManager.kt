package com.slapmac.app

import android.content.Context
import android.content.res.AssetFileDescriptor
import android.media.MediaPlayer
import android.util.Log

class AudioManager(private val context: Context) {
    private val soundFiles = mutableListOf<String>()
    private var mediaPlayer: MediaPlayer? = null
    var volume: Float = 1.0f
    var isEnabled = true
    val soundCount: Int get() = soundFiles.size

    init {
        loadSounds()
    }

    private fun loadSounds() {
        val extensions = setOf("mp3", "wav", "m4a", "ogg")
        try {
            val assets = context.assets.list("audio") ?: emptyArray()
            for (file in assets) {
                val ext = file.substringAfterLast('.', "").lowercase()
                if (ext in extensions) {
                    soundFiles.add("audio/$file")
                }
            }
            Log.d("SlapMac", "Loaded ${soundFiles.size} sound(s)")
        } catch (e: Exception) {
            Log.e("SlapMac", "Failed to load sounds: ${e.message}")
        }
    }

    fun playRandomSound() {
        if (!isEnabled || soundFiles.isEmpty()) return

        try {
            mediaPlayer?.release()
            val file = soundFiles.random()
            val afd: AssetFileDescriptor = context.assets.openFd(file)
            mediaPlayer = MediaPlayer().apply {
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()
                setVolume(volume.coerceIn(0f, 1f), volume.coerceIn(0f, 1f))
                prepare()
                start()
            }
            Log.d("SlapMac", "Playing: $file")
        } catch (e: Exception) {
            Log.e("SlapMac", "Playback error: ${e.message}")
        }
    }

    fun release() {
        mediaPlayer?.release()
        mediaPlayer = null
    }
}
