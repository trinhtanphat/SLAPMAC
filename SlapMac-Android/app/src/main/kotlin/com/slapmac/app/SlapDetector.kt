package com.slapmac.app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlin.math.abs
import kotlin.math.sqrt

class SlapDetector(context: Context) : SensorEventListener {
    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

    var sensitivity = 1.5
    var cooldownMs = 1500L
    var onSlapDetected: (() -> Unit)? = null
    var isRunning = false
        private set

    private var lastSlapTime = 0L
    private var previousMagnitude = 0.0
    private var baselineMagnitude = 9.81
    private var calibrationCount = 0
    private val calibrationTotal = 50

    fun start() {
        if (accelerometer == null || isRunning) return
        isRunning = true
        calibrationCount = 0
        baselineMagnitude = 9.81
        sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_GAME)
    }

    fun stop() {
        isRunning = false
        sensorManager.unregisterListener(this)
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (!isRunning || event.sensor.type != Sensor.TYPE_ACCELEROMETER) return

        val x = event.values[0].toDouble()
        val y = event.values[1].toDouble()
        val z = event.values[2].toDouble()
        val magnitude = sqrt(x * x + y * y + z * z)

        // Calibration phase
        if (calibrationCount < calibrationTotal) {
            baselineMagnitude = maxOf(baselineMagnitude, magnitude)
            calibrationCount++
            previousMagnitude = magnitude
            return
        }

        val delta = abs(magnitude - previousMagnitude)
        previousMagnitude = magnitude

        // Adapt baseline slowly
        baselineMagnitude = baselineMagnitude * 0.98 + magnitude * 0.02

        // Detection threshold inversely proportional to sensitivity
        val threshold = 2.0 / sensitivity.coerceIn(0.5, 4.0)

        if (delta > threshold) {
            val now = System.currentTimeMillis()
            // Extended suppression: 1 slap = 1 sound
            val suppressionMs = maxOf(cooldownMs * 2, 3000L)
            if (now - lastSlapTime >= suppressionMs) {
                lastSlapTime = now
                onSlapDetected?.invoke()
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
}
