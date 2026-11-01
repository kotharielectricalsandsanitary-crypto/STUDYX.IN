
package com.example.studyx

import android.app.Activity
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView

class BlockedAppActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = LinearLayout(this)
        root.orientation = LinearLayout.VERTICAL
        root.gravity = Gravity.CENTER
        root.setPadding(32, 40, 32, 40)
        root.setBackgroundColor(Color.rgb(8, 10, 15))

        val card = LinearLayout(this)
        card.orientation = LinearLayout.VERTICAL
        card.gravity = Gravity.CENTER
        card.setPadding(32, 38, 32, 38)

        val cardBackground = GradientDrawable()
        cardBackground.setColor(Color.rgb(18, 21, 29))
        cardBackground.cornerRadius = 32f
        cardBackground.setStroke(1, Color.rgb(45, 49, 60))
        card.background = cardBackground

        val iconContainer = TextView(this)
        iconContainer.text = "🛡"
        iconContainer.textSize = 42f
        iconContainer.gravity = Gravity.CENTER

        val iconBackground = GradientDrawable()
        iconBackground.setColor(Color.rgb(28, 35, 48))
        iconBackground.cornerRadius = 100f
        iconContainer.background = iconBackground

        val iconParams = LinearLayout.LayoutParams(92, 92)
        iconParams.gravity = Gravity.CENTER
        card.addView(iconContainer, iconParams)

        addSpace(card, 24)

        val brand = TextView(this)
        brand.text = "STUDYX"
        brand.textSize = 13f
        brand.setTextColor(Color.rgb(130, 150, 255))
        brand.setTypeface(Typeface.DEFAULT, Typeface.BOLD)
        brand.gravity = Gravity.CENTER
        brand.letterSpacing = 0.18f

        card.addView(
            brand,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        addSpace(card, 8)

        val title = TextView(this)
        title.text = "Focus Mode"
        title.textSize = 30f
        title.setTextColor(Color.WHITE)
        title.setTypeface(Typeface.DEFAULT, Typeface.BOLD)
        title.gravity = Gravity.CENTER

        card.addView(
            title,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        addSpace(card, 14)

        val message = TextView(this)
        message.text =
            "Your entertainment limit has been reached.\n\n" +
            "It's time to get back to your study session."

        message.textSize = 17f
        message.setTextColor(Color.rgb(180, 185, 198))
        message.gravity = Gravity.CENTER
        message.setLineSpacing(5f, 1.0f)

        card.addView(
            message,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        addSpace(card, 26)

        val status = TextView(this)
        status.text = "●  FOCUS MODE ACTIVE"
        status.textSize = 13f
        status.setTextColor(Color.rgb(150, 255, 190))
        status.setTypeface(Typeface.DEFAULT, Typeface.BOLD)
        status.gravity = Gravity.CENTER

        val statusBackground = GradientDrawable()
        statusBackground.setColor(Color.rgb(20, 45, 35))
        statusBackground.cornerRadius = 50f
        statusBackground.setStroke(1, Color.rgb(45, 90, 65))
        status.background = statusBackground
        status.setPadding(26, 14, 26, 14)

        card.addView(
            status,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        addSpace(card, 30)

        val button = TextView(this)
        button.text = "Return to StudyX"
        button.textSize = 16f
        button.setTextColor(Color.WHITE)
        button.setTypeface(Typeface.DEFAULT, Typeface.BOLD)
        button.gravity = Gravity.CENTER

        val buttonBackground = GradientDrawable()
        buttonBackground.setColor(Color.rgb(75, 92, 220))
        buttonBackground.cornerRadius = 22f
        button.background = buttonBackground
        button.setPadding(24, 18, 24, 18)

        button.setOnClickListener {
            finish()
        }

        card.addView(
            button,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                58
            )
        )

        val cardParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        cardParams.gravity = Gravity.CENTER

        root.addView(card, cardParams)

        addSpace(root, 24)

        val footer = TextView(this)
        footer.text = "Protect your focus. Build your future."
        footer.textSize = 13f
        footer.setTextColor(Color.rgb(100, 105, 120))
        footer.gravity = Gravity.CENTER

        root.addView(
            footer,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )

        setContentView(root)
    }

    private fun addSpace(parent: LinearLayout, height: Int) {
        val space = View(this)

        parent.addView(
            space,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                height
            )
        )
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        moveTaskToBack(true)
    }
}
