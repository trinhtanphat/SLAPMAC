package com.slapmac.app

import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.SeekBar
import android.widget.Spinner
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : AppCompatActivity() {
    companion object {
        private const val TAGS_API = "https://api.github.com/repos/trinhtanphat/SLAPMAC/tags?per_page=20"
        private const val RELEASES_URL = "https://github.com/trinhtanphat/SLAPMAC/releases/latest"
    }

    private lateinit var detector: SlapDetector
    private lateinit var audio: AudioManager
    private lateinit var prefs: SharedPreferences
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
    private lateinit var donateButton: Button
    private lateinit var versionLabel: TextView
    private lateinit var updateStatus: TextView
    private lateinit var checkUpdateButton: Button
    private lateinit var updateNowButton: Button
    private lateinit var languageSpinner: Spinner
    private var latestTag: String? = null
    private var languageCode: String = "en"

    private data class LanguageOption(val code: String, val label: String)

    private var languages = mutableListOf(
        LanguageOption("en", "🇺🇸 English"), LanguageOption("vi", "🇻🇳 Tieng Viet"), LanguageOption("es", "🇪🇸 Espanol"),
        LanguageOption("fr", "🇫🇷 Francais"), LanguageOption("de", "🇩🇪 Deutsch"), LanguageOption("it", "🇮🇹 Italiano"),
        LanguageOption("pt", "🇵🇹 Portugues"), LanguageOption("ru", "🇷🇺 Russkiy"), LanguageOption("ja", "🇯🇵 Nihongo"),
        LanguageOption("ko", "🇰🇷 Hangug-eo"), LanguageOption("zh-CN", "🇨🇳 JianTi ZhongWen"), LanguageOption("zh-TW", "🇹🇼 FanTi ZhongWen"),
        LanguageOption("th", "🇹🇭 Thai"), LanguageOption("id", "🇮🇩 Bahasa Indonesia"), LanguageOption("ms", "🇲🇾 Bahasa Melayu"),
        LanguageOption("hi", "🇮🇳 Hindi"), LanguageOption("ar", "🇸🇦 Arabic"), LanguageOption("tr", "🇹🇷 Turkce"),
        LanguageOption("pl", "🇵🇱 Polski"), LanguageOption("nl", "🇳🇱 Nederlands")
    )
    private var externalI18n = mapOf<String, Map<String, String>>()

    private val baseI18n = mapOf(
        "pause" to "⏸ Pause", "resume" to "▶ Resume", "test" to "🔊 Test Sound", "sounds" to "%d sound(s) loaded",
        "sens" to "Sensitivity: %.1f", "vol" to "Volume: %d%%", "cool" to "Cooldown: %dms", "version" to "Version: v%s",
        "check" to "Check Update", "update" to "Update Now", "checking" to "Checking GitHub tags...", "new" to "New version available: %s",
        "uptodate" to "Up to date (%s).", "uptodateYou" to "You're up to date (%s).", "failed" to "Update check failed. Try again later.", "notags" to "No release tags found."
    )

    private val i18n = mapOf(
        "en" to baseI18n,
        "vi" to (baseI18n + mapOf("pause" to "⏸ Tam dung", "resume" to "▶ Tiep tuc", "test" to "🔊 Thu am thanh", "sounds" to "%d am thanh da tai", "sens" to "Do nhay: %.1f", "vol" to "Am luong: %d%%", "cool" to "Do tre: %dms", "version" to "Phien ban: v%s", "check" to "Kiem tra cap nhat", "update" to "Cap nhat ngay", "checking" to "Dang kiem tra GitHub tags...", "new" to "Co ban moi: %s", "uptodate" to "Da moi nhat (%s).", "uptodateYou" to "Ban dang o ban moi nhat (%s).", "failed" to "Kiem tra cap nhat that bai.", "notags" to "Khong tim thay tag release.")),
        "es" to (baseI18n + mapOf("check" to "Buscar actualizacion", "update" to "Actualizar ahora")),
        "fr" to (baseI18n + mapOf("check" to "Verifier la mise a jour", "update" to "Mettre a jour")),
        "de" to (baseI18n + mapOf("check" to "Update pruefen", "update" to "Jetzt updaten")),
        "it" to (baseI18n + mapOf("check" to "Controlla aggiornamento", "update" to "Aggiorna ora")),
        "pt" to (baseI18n + mapOf("check" to "Verificar atualizacao", "update" to "Atualizar agora")),
        "ru" to (baseI18n + mapOf("check" to "Proverit obnovlenie", "update" to "Obnovit")),
        "ja" to (baseI18n + mapOf("check" to "Koshin chekku", "update" to "Ima sugu koshin")),
        "ko" to (baseI18n + mapOf("check" to "Eobdeiteu hwagin", "update" to "Jigeum eobdeiteu")),
        "zh-CN" to (baseI18n + mapOf("check" to "Jian cha geng xin", "update" to "Li ji geng xin")),
        "zh-TW" to (baseI18n + mapOf("check" to "Jian cha geng xin", "update" to "Li ji geng xin")),
        "th" to (baseI18n + mapOf("check" to "Truat sop update", "update" to "Update ton ni")),
        "id" to (baseI18n + mapOf("check" to "Cek pembaruan", "update" to "Perbarui sekarang")),
        "ms" to (baseI18n + mapOf("check" to "Semak kemas kini", "update" to "Kemas kini sekarang")),
        "hi" to (baseI18n + mapOf("check" to "Update check karo", "update" to "Abhi update karo")),
        "ar" to (baseI18n + mapOf("check" to "Tahqiq min altahdith", "update" to "Haddith alan")),
        "tr" to (baseI18n + mapOf("check" to "Guncellemeyi kontrol et", "update" to "Simdi guncelle")),
        "pl" to (baseI18n + mapOf("check" to "Sprawdz aktualizacje", "update" to "Aktualizuj teraz")),
        "nl" to (baseI18n + mapOf("check" to "Controleer update", "update" to "Nu updaten"))
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        prefs = getSharedPreferences("slapmac", MODE_PRIVATE)
        languageCode = prefs.getString("language", "en") ?: "en"
        loadI18nAsset()

        audio = AudioManager(this)
        detector = SlapDetector(this)

        bindViews()
        setupListeners()

        applyLanguage()
        detector.start()
        checkForUpdates(false)
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
        donateButton = findViewById(R.id.donateButton)
        versionLabel = findViewById(R.id.versionLabel)
        updateStatus = findViewById(R.id.updateStatus)
        checkUpdateButton = findViewById(R.id.checkUpdateButton)
        updateNowButton = findViewById(R.id.updateNowButton)
        languageSpinner = findViewById(R.id.languageSpinner)

        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_dropdown_item, languages.map { it.label })
        languageSpinner.adapter = adapter
        val idx = languages.indexOfFirst { it.code == languageCode }.coerceAtLeast(0)
        languageSpinner.setSelection(idx)
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

        // Donate
        donateButton.setOnClickListener {
            startActivity(Intent(this, DonateActivity::class.java))
        }

        checkUpdateButton.setOnClickListener {
            checkForUpdates(true)
        }

        updateNowButton.setOnClickListener {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(RELEASES_URL)))
        }

        languageSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                val newCode = languages[position].code
                if (newCode != languageCode) {
                    languageCode = newCode
                    prefs.edit().putString("language", languageCode).apply()
                    applyLanguage()
                }
            }

            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }
    }

    private fun t(key: String): String {
        return externalI18n[languageCode]?.get(key)
            ?: externalI18n["en"]?.get(key)
            ?: i18n[languageCode]?.get(key)
            ?: i18n["en"]?.get(key)
            ?: key
    }

    private fun loadI18nAsset() {
        try {
            val raw = assets.open("i18n.json").bufferedReader().use { it.readText() }
            val root = JSONObject(raw)

            val options = root.optJSONArray("languageOptions") ?: JSONArray()
            val loaded = mutableListOf<LanguageOption>()
            for (i in 0 until options.length()) {
                val obj = options.optJSONObject(i) ?: continue
                val code = obj.optString("code", "").trim()
                val label = obj.optString("label", "").trim()
                val flag = obj.optString("flag", "").trim()
                if (code.isNotEmpty() && label.isNotEmpty() && flag.isNotEmpty()) {
                    loaded.add(LanguageOption(code, "${flagToEmoji(flag)} $label"))
                }
            }
            if (loaded.isNotEmpty()) {
                languages = loaded
            }

            val translationsObj = root.optJSONObject("translations") ?: JSONObject()
            val map = mutableMapOf<String, Map<String, String>>()
            val langKeys = translationsObj.keys()
            while (langKeys.hasNext()) {
                val code = langKeys.next()
                val obj = translationsObj.optJSONObject(code) ?: continue
                val dict = mutableMapOf<String, String>()
                val dictKeys = obj.keys()
                while (dictKeys.hasNext()) {
                    val k = dictKeys.next()
                    dict[k] = obj.optString(k)
                }
                map[code] = dict
            }
            if (map.isNotEmpty()) {
                externalI18n = map
            }
        } catch (_: Exception) {
            // Keep in-code fallback translations.
        }
    }

    private fun flagToEmoji(code: String): String {
        if (code.length != 2) return ""
        val upper = code.uppercase()
        val first = Character.codePointAt(upper, 0) - 65 + 0x1F1E6
        val second = Character.codePointAt(upper, 1) - 65 + 0x1F1E6
        return String(Character.toChars(first)) + String(Character.toChars(second))
    }

    private fun applyLanguage() {
        toggleButton.text = if (detector.isRunning) t("pause") else t("resume")
        testButton.text = t("test")
        soundsInfo.text = t("sounds").format(audio.soundCount)
        sensitivityLabel.text = t("sens").format(sensitivitySlider.progress / 10.0)
        volumeLabel.text = t("vol").format(volumeSlider.progress)
        cooldownLabel.text = t("cool").format(cooldownSlider.progress * 100)
        versionLabel.text = t("version").format(BuildConfig.VERSION_NAME)
        checkUpdateButton.text = t("check")
        updateNowButton.text = t("update")
    }

    private fun parseVersion(version: String): List<Int> {
        return version.split(".").take(3).map { it.toIntOrNull() ?: 0 }
    }

    private fun compareVersions(a: String, b: String): Int {
        val av = parseVersion(a)
        val bv = parseVersion(b)
        for (i in 0..2) {
            val ai = av.getOrElse(i) { 0 }
            val bi = bv.getOrElse(i) { 0 }
            if (ai > bi) return 1
            if (ai < bi) return -1
        }
        return 0
    }

    private fun checkForUpdates(manual: Boolean) {
        checkUpdateButton.isEnabled = false
        updateNowButton.isEnabled = false
        updateStatus.text = t("checking")

        Thread {
            try {
                val conn = (URL(TAGS_API).openConnection() as HttpURLConnection).apply {
                    connectTimeout = 10000
                    readTimeout = 10000
                    setRequestProperty("Accept", "application/vnd.github+json")
                    setRequestProperty("User-Agent", "SlapMac-Android")
                }

                val body = conn.inputStream.bufferedReader().use { it.readText() }
                conn.disconnect()

                val tags = JSONArray(body)
                var newest: String? = null
                val regex = Regex("^v?\\d+\\.\\d+\\.\\d+$")

                for (i in 0 until tags.length()) {
                    val name = tags.getJSONObject(i).optString("name", "")
                    if (regex.matches(name)) {
                        newest = name
                        break
                    }
                }

                runOnUiThread {
                    checkUpdateButton.isEnabled = true
                    if (newest == null) {
                        latestTag = null
                        updateStatus.text = t("notags")
                        updateNowButton.isEnabled = false
                        return@runOnUiThread
                    }

                    latestTag = newest
                    val latestVersion = newest.removePrefix("v")
                    val cmp = compareVersions(latestVersion, BuildConfig.VERSION_NAME)

                    if (cmp > 0) {
                        updateStatus.text = t("new").format(newest)
                        updateNowButton.isEnabled = true
                    } else {
                        updateStatus.text = if (manual) t("uptodateYou").format(newest) else t("uptodate").format(newest)
                        updateNowButton.isEnabled = false
                    }
                }
            } catch (_: Exception) {
                runOnUiThread {
                    checkUpdateButton.isEnabled = true
                    latestTag = null
                    updateStatus.text = t("failed")
                    updateNowButton.isEnabled = false
                }
            }
        }.start()
    }

    override fun onDestroy() {
        super.onDestroy()
        detector.stop()
        audio.release()
    }
}
