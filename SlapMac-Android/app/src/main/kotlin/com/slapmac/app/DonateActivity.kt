package com.slapmac.app

import android.graphics.BitmapFactory
import android.os.Bundle
import android.widget.Button
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity

class DonateActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_donate)

        // Load QR code images from assets
        try {
            assets.open("qrcode/momo.jpeg").use { stream ->
                val bitmap = BitmapFactory.decodeStream(stream)
                findViewById<ImageView>(R.id.momoQR).setImageBitmap(bitmap)
            }
        } catch (_: Exception) {}

        try {
            assets.open("qrcode/techcombank.jpeg").use { stream ->
                val bitmap = BitmapFactory.decodeStream(stream)
                findViewById<ImageView>(R.id.techcombankQR).setImageBitmap(bitmap)
            }
        } catch (_: Exception) {}

        findViewById<Button>(R.id.backButton).setOnClickListener {
            finish()
        }
    }
}
