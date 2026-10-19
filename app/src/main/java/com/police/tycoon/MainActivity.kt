package com.police.tycoon

import android.app.Activity
import android.os.Bundle
import android.graphics.Color
import android.graphics.Typeface
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import android.content.res.ColorStateList

class MainActivity : Activity() {
    private val bg = Color.rgb(10, 16, 32)
    private val panel = Color.rgb(20, 29, 51)
    private val blue = Color.rgb(54, 126, 245)
    private val white = Color.rgb(239, 244, 255)
    private val muted = Color.rgb(160, 176, 202)
    private var money = 1200
    private var reputation = 0
    private var officers = 3
    private var stationLevel = 1
    private var callsHandled = 0
    private var calls = 2
    private lateinit var stats: TextView
    private lateinit var feed: TextView
    private lateinit var root: LinearLayout
    private val prefs by lazy { getSharedPreferences("police_tycoon_save", MODE_PRIVATE) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        money = prefs.getInt("money", 1200)
        reputation = prefs.getInt("rep", 0)
        officers = prefs.getInt("officers", 3)
        stationLevel = prefs.getInt("station", 1)
        callsHandled = prefs.getInt("handled", 0)
        calls = prefs.getInt("calls", 2)
        buildUi()
    }

    private fun buildUi() {
        val scroll = ScrollView(this).apply { setBackgroundColor(bg) }
        root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(22), dp(20), dp(28))
            setBackgroundColor(bg)
        }
        scroll.addView(root)
        setContentView(scroll)
        text("🚔  POLICE TYCOON", 27, white, true)
        text("ГОРОД НУЖДАЕТСЯ В ТЕБЕ", 12, muted, true).setPadding(0, dp(4), 0, dp(18))
        stats = TextView(this).apply {
            setTextColor(white); textSize = 15f
            setPadding(dp(16), dp(16), dp(16), dp(16))
            background = rounded(panel, 18)
        }
        root.addView(stats, matchWrap())
        updateStats()
        text("📟  ДЕЖУРНАЯ ЧАСТЬ", 18, white, true).setPadding(0, dp(22), 0, dp(8))
        text("Поступают новые вызовы. Выбирай задачу и отправляй патруль.", 14, muted, false)
        actionButton("🚨  Принять вызов • ограбление", blue) { handleCall("Ограбление", 180, 12) }
        actionButton("🚓  Принять вызов • нарушение порядка", Color.rgb(40, 92, 170)) { handleCall("Нарушение порядка", 90, 6) }
        actionButton("🔎  Расследовать дело", Color.rgb(93, 69, 180)) { handleCall("Расследование", 130, 10) }
        text("🏢  РАЗВИТИЕ УПРАВЛЕНИЯ", 18, white, true).setPadding(0, dp(22), 0, dp(8))
        actionButton("👮  Нанять офицера • $350", panel) {
            if (money >= 350) { money -= 350; officers++; log("Новый офицер принят на службу.") }
            else toast("Недостаточно средств")
            saveAndRefresh()
        }
        actionButton("🏗️  Улучшить участок • $600", panel) {
            val cost = stationLevel * 600
            if (money >= cost) { money -= cost; stationLevel++; calls++; log("Участок улучшен до уровня $stationLevel.") }
            else toast("Нужно $cost")
            saveAndRefresh()
        }
        actionButton("📋  Закрыть смену • бонус $250", Color.rgb(20, 112, 91)) {
            money += 250 + officers * 20
            reputation += 3
            calls += 1
            log("Смена завершена. Выплачена зарплата и бонус.")
            saveAndRefresh()
        }
        text("📡  РАДИОЖУРНАЛ", 18, white, true).setPadding(0, dp(22), 0, dp(8))
        feed = TextView(this).apply {
            text = "• Диспетчерская готова к работе.\n• На смене офицеров: $officers."
            setTextColor(muted); textSize = 14f
            setPadding(dp(16), dp(14), dp(16), dp(14))
            background = rounded(panel, 16)
        }
        root.addView(feed, matchWrap())
        actionButton("↻  Сбросить сохранение", Color.rgb(93, 42, 55)) {
            money = 1200; reputation = 0; officers = 3; stationLevel = 1; callsHandled = 0; calls = 2
            log("Начато новое дежурство.")
            saveAndRefresh()
        }
        text("Police Tycoon • версия 1.0 • Прогресс сохраняется на устройстве", 11, muted, false).setPadding(0, dp(18), 0, 0)
    }

    private fun handleCall(name: String, reward: Int, rep: Int) {
        if (calls <= 0) { toast("Вызовов нет. Улучши участок или закрой смену."); return }
        calls--; callsHandled++
        money += reward + officers * 8
        reputation += rep
        log("Вызов «$name» выполнен. Награда: \${reward + officers * 8}.")
        saveAndRefresh()
    }
    private fun updateStats() {
        stats.text = "💵  БЮДЖЕТ   \${money}\n⭐  РЕПУТАЦИЯ   $reputation\n👮  ОФИЦЕРЫ   $officers     🏢 УЧАСТОК   ур. $stationLevel\n📟  ВЫЗОВЫ   $calls     ✓ ЗАДАНИЙ   $callsHandled"
    }
    private fun log(message: String) {
        if (!::feed.isInitialized) return
        feed.text = "• $message\n" + feed.text.toString().take(650)
    }
    private fun saveAndRefresh() {
        prefs.edit().putInt("money", money).putInt("rep", reputation).putInt("officers", officers)
            .putInt("station", stationLevel).putInt("handled", callsHandled).putInt("calls", calls).apply()
        updateStats()
    }
    private fun text(value: String, size: Int, color: Int, bold: Boolean): TextView {
        val v = TextView(this).apply {
            text = value; textSize = size.toFloat(); setTextColor(color)
            if (bold) typeface = Typeface.DEFAULT_BOLD
        }
        root.addView(v, matchWrap())
        return v
    }
    private fun actionButton(label: String, color: Int, action: () -> Unit) {
        val b = Button(this).apply {
            text = label; textSize = 14f; isAllCaps = false; setTextColor(white)
            backgroundTintList = ColorStateList.valueOf(color)
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), dp(8), dp(12), dp(8))
            setOnClickListener { action() }
        }
        val p = LinearLayout.LayoutParams(-1, dp(56))
        p.topMargin = dp(8)
        root.addView(b, p)
    }
    private fun rounded(color: Int, radius: Int) = android.graphics.drawable.GradientDrawable().apply {
        setColor(color); cornerRadius = dp(radius).toFloat()
    }
    private fun matchWrap() = LinearLayout.LayoutParams(-1, -2)
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private fun toast(message: String) = Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
}
