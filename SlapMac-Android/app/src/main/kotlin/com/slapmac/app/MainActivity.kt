package com.slapmac.app

import android.os.Bundle
import android.widget.Button
import android.widget.SeekBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    private lateinit var detector: SlapDetector
    private lateinit var audio: AudioManager
    private var slapCount = 0

    private lateinit var counterText: TextView
    private lateinit var toggleButton: Button
    private lateinit var testButton: Button
    private lateinit var soundsInfo: TextView
    private lateinit var sensitivitySlider: SeekBar
    private lateinit var sensitivityLabel: TextView
    private lateinit var volumeSlider: SeekBar
    private lateinit var volumeLabel: TextView
    private lateinit var cooldownSlider: SeekBar
    private lateinit var cooldownLabel: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        audio = AudioManager(this)
        detector = SlapDetector(this)

        bindViews()
        setupListeners()

        soundsInfo.text = "${audio.soundCount} sound(s) loaded"
        detector.start()
    }

    private fun bindViews() {
        counterText = findViewById(R.id.slapCounter)
        toggleButton = findViewById(R.id.toggleButton)
        testButton = findViewById(R.id.testButton)
        soundsInfo = findViewById(R.id.soundsInfo)
        sensitivitySlider = findViewById(R.id.sensitivitySlider)
        sensitivityLabel = findViewById(R.id.sensitivityLabel)
        volumeSlider = findViewById(R.id.volumeSlider)
        volumeLabel = findViewById(R.id.volumeLabel)
        cooldownSlider = findViewById(R.id.cooldownSlider)
        cooldownLabel = findViewById(R.id.cooldownLabel)
    }

    private fun setupListeners() {
        detector.onSlapDetected = {
            runOnUiThread {
                slapCount++
                counterText.text = slapCount.toString()
                audio.playRandomSound()
            }
        }

        toggleButton.setOnClickListener {
            if (detector.isRunning) {
                detector.stop()
                toggleButton.text = "▶ Resume"
            } else {
                detector.start()
                toggleButton.text = "⏸ Pause"
            }
        }

        testButton.setOnClickListener {
            audio.playRandomSound()
            slapCount++
            counterText.text = slapCount.toString()
        }

        // Sensitivity: 0.5 - 4.0 (slider 5-40, divide by 10)
        sensitivitySlider.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
                val value = progress / 10.0
                sensitivityLabel.text = "Sensitivity: ${"%.1f".format(value)}"
                detector.sensitivity = value
            }
            override fun onStartTrackingTouch(seekBar: SeekBar) {}
            override fun onStopTrackingTouch(seekBar: SeekBar) {}
        })

        // Volume: 0 - 100%
        volumeSlider.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
                volumeLabel.text = "Volume: $progress%"
                audio.volume = progress / 100f
            }
            override fun onStartTrackingTouch(seekBar: SeekBar) {}
            override fun onStopTrackingTouch(seekBar: SeekBar) {}
        })

        // Cooldown: 500 - 5000ms (slider 5-50, multiply by 100)
        cooldownSlider.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
                val ms = progress * 100
                cooldownLabel.text = "Cooldown: ${ms}ms"
                detector.cooldownMs = ms.toLong()
            }
            override fun onStartTrackingTouch(seekBar: SeekBar) {}
            override fun onStopTrackingTouch(seekBar: SeekBar) {}
        })
    }

    override fun onDestroy() {
        super.onDestroy()
        detector.stop()
        audio.release()
    }
}
