#pragma once
#include <QObject>
#include <QColor>
#include <QSettings>

class ThemeProvider : public QObject {
    Q_OBJECT

    // ─── Dark Mode ───
    Q_PROPERTY(bool darkMode READ darkMode WRITE setDarkMode NOTIFY themeChanged)

    // ─── Colors ───
    Q_PROPERTY(QColor bg READ bg NOTIFY themeChanged)
    Q_PROPERTY(QColor bgSidebar READ bgSidebar NOTIFY themeChanged)
    Q_PROPERTY(QColor bgElevated READ bgElevated NOTIFY themeChanged)
    Q_PROPERTY(QColor bgSurface READ bgSurface NOTIFY themeChanged)
    Q_PROPERTY(QColor bgHover READ bgHover NOTIFY themeChanged)
    Q_PROPERTY(QColor bgActive READ bgActive NOTIFY themeChanged)
    Q_PROPERTY(QColor fg READ fg NOTIFY themeChanged)
    Q_PROPERTY(QColor fgMuted READ fgMuted NOTIFY themeChanged)
    Q_PROPERTY(QColor fgDim READ fgDim NOTIFY themeChanged)
    Q_PROPERTY(QColor border READ border NOTIFY themeChanged)
    Q_PROPERTY(QColor borderLight READ borderLight NOTIFY themeChanged)
    Q_PROPERTY(QColor borderFocus READ borderFocus NOTIFY themeChanged)
    Q_PROPERTY(QColor accent READ accent NOTIFY themeChanged)
    Q_PROPERTY(QColor accentHover READ accentHover NOTIFY themeChanged)
    Q_PROPERTY(QColor accentDim READ accentDim NOTIFY themeChanged)
    Q_PROPERTY(QColor success READ success NOTIFY themeChanged)
    Q_PROPERTY(QColor warning READ warning NOTIFY themeChanged)
    Q_PROPERTY(QColor error READ error NOTIFY themeChanged)
    Q_PROPERTY(QColor info READ info NOTIFY themeChanged)

    // Syntax
    Q_PROPERTY(QColor synKeyword READ synKeyword NOTIFY themeChanged)
    Q_PROPERTY(QColor synString READ synString NOTIFY themeChanged)
    Q_PROPERTY(QColor synNumber READ synNumber NOTIFY themeChanged)
    Q_PROPERTY(QColor synComment READ synComment NOTIFY themeChanged)
    Q_PROPERTY(QColor synFunction READ synFunction NOTIFY themeChanged)
    Q_PROPERTY(QColor synType READ synType NOTIFY themeChanged)

    // ─── Radius ───
    Q_PROPERTY(qreal r4 MEMBER m_r4 CONSTANT)
    Q_PROPERTY(qreal r6 MEMBER m_r6 CONSTANT)
    Q_PROPERTY(qreal r8 MEMBER m_r8 CONSTANT)
    Q_PROPERTY(qreal r12 MEMBER m_r12 CONSTANT)
    Q_PROPERTY(qreal rFull MEMBER m_rFull CONSTANT)

    // ─── Spacing ───
    Q_PROPERTY(qreal s2 MEMBER m_s2 CONSTANT)
    Q_PROPERTY(qreal s4 MEMBER m_s4 CONSTANT)
    Q_PROPERTY(qreal s6 MEMBER m_s6 CONSTANT)
    Q_PROPERTY(qreal s8 MEMBER m_s8 CONSTANT)
    Q_PROPERTY(qreal s12 MEMBER m_s12 CONSTANT)
    Q_PROPERTY(qreal s16 MEMBER m_s16 CONSTANT)
    Q_PROPERTY(qreal s20 MEMBER m_s20 CONSTANT)
    Q_PROPERTY(qreal s24 MEMBER m_s24 CONSTANT)

    // ─── Typography ───
    Q_PROPERTY(QString sans MEMBER m_sans CONSTANT)
    Q_PROPERTY(QString mono MEMBER m_mono CONSTANT)
    Q_PROPERTY(int t11 MEMBER m_t11 CONSTANT)
    Q_PROPERTY(int t12 MEMBER m_t12 CONSTANT)
    Q_PROPERTY(int t13 MEMBER m_t13 CONSTANT)
    Q_PROPERTY(int t14 MEMBER m_t14 CONSTANT)
    Q_PROPERTY(int t16 MEMBER m_t16 CONSTANT)
    Q_PROPERTY(int t20 MEMBER m_t20 CONSTANT)
    Q_PROPERTY(int t24 MEMBER m_t24 CONSTANT)

    // ─── Animation ───
    Q_PROPERTY(int fast MEMBER m_fast CONSTANT)
    Q_PROPERTY(int normal MEMBER m_normal CONSTANT)
    Q_PROPERTY(int slow MEMBER m_slow CONSTANT)

    // ═══ Backward compat for Flat* controls ═══
    Q_PROPERTY(QColor background READ bg NOTIFY themeChanged)
    Q_PROPERTY(QColor foreground READ fg NOTIFY themeChanged)
    Q_PROPERTY(QColor primary READ accent NOTIFY themeChanged)
    Q_PROPERTY(QColor primaryForeground READ white NOTIFY themeChanged)
    Q_PROPERTY(QColor secondary READ bgSurface NOTIFY themeChanged)
    Q_PROPERTY(QColor secondaryForeground READ fg NOTIFY themeChanged)
    Q_PROPERTY(QColor muted READ bgSurface NOTIFY themeChanged)
    Q_PROPERTY(QColor mutedForeground READ fgMuted NOTIFY themeChanged)
    Q_PROPERTY(QColor card READ bgElevated NOTIFY themeChanged)
    Q_PROPERTY(QColor cardForeground READ fg NOTIFY themeChanged)
    Q_PROPERTY(QColor popover READ bgElevated NOTIFY themeChanged)
    Q_PROPERTY(QColor popoverForeground READ fg NOTIFY themeChanged)
    Q_PROPERTY(QColor destructive READ error NOTIFY themeChanged)
    Q_PROPERTY(QColor destructiveForeground READ white NOTIFY themeChanged)
    Q_PROPERTY(QColor input READ borderLight NOTIFY themeChanged)
    Q_PROPERTY(QColor ring READ borderFocus NOTIFY themeChanged)
    Q_PROPERTY(QColor accentColor READ accentDim NOTIFY themeChanged)
    Q_PROPERTY(QColor accentForeground READ fg NOTIFY themeChanged)

    Q_PROPERTY(QString fontFamily MEMBER m_sans CONSTANT)
    Q_PROPERTY(QString monoFamily MEMBER m_mono CONSTANT)
    Q_PROPERTY(int fontSizeXs MEMBER m_fontSizeXs CONSTANT)
    Q_PROPERTY(int fontSizeSm MEMBER m_t12 CONSTANT)
    Q_PROPERTY(int fontSize MEMBER m_t13 CONSTANT)
    Q_PROPERTY(int fontSizeMd MEMBER m_t14 CONSTANT)
    Q_PROPERTY(int fontSizeLg MEMBER m_t16 CONSTANT)
    Q_PROPERTY(int fontSizeXl MEMBER m_t20 CONSTANT)
    Q_PROPERTY(int fontSize2xl MEMBER m_t24 CONSTANT)

    Q_PROPERTY(qreal radius MEMBER m_r6 CONSTANT)
    Q_PROPERTY(qreal radiusSm MEMBER m_r4 CONSTANT)
    Q_PROPERTY(qreal radiusMd MEMBER m_r8 CONSTANT)
    Q_PROPERTY(qreal radiusLg MEMBER m_r12 CONSTANT)
    Q_PROPERTY(qreal radiusFull MEMBER m_rFull CONSTANT)

    Q_PROPERTY(int duration MEMBER m_normal CONSTANT)
    Q_PROPERTY(int durationFast MEMBER m_fast CONSTANT)
    Q_PROPERTY(int durationSlow MEMBER m_slow CONSTANT)
    Q_PROPERTY(int durationModal MEMBER m_slow CONSTANT)

public:
    explicit ThemeProvider(QObject* p = nullptr) : QObject(p) {
        QSettings s("VaniStudio", "TableMax");
        m_dark = s.value("theme/darkMode", true).toBool();
        applyPalette();
    }

    bool darkMode() const { return m_dark; }

    void setDarkMode(bool v) {
        if (m_dark == v) return;
        m_dark = v;
        QSettings s("VaniStudio", "TableMax");
        s.setValue("theme/darkMode", v);
        applyPalette();
        emit themeChanged();
    }

    Q_INVOKABLE void toggleTheme() { setDarkMode(!m_dark); }

    // Color getters
    QColor bg() const { return m_bg; }
    QColor bgSidebar() const { return m_bgSidebar; }
    QColor bgElevated() const { return m_bgElevated; }
    QColor bgSurface() const { return m_bgSurface; }
    QColor bgHover() const { return m_bgHover; }
    QColor bgActive() const { return m_bgActive; }
    QColor fg() const { return m_fg; }
    QColor fgMuted() const { return m_fgMuted; }
    QColor fgDim() const { return m_fgDim; }
    QColor border() const { return m_border; }
    QColor borderLight() const { return m_borderLight; }
    QColor borderFocus() const { return m_borderFocus; }
    QColor accent() const { return m_accent; }
    QColor accentHover() const { return m_accentHover; }
    QColor accentDim() const { return m_accentDim; }
    QColor success() const { return m_success; }
    QColor warning() const { return m_warning; }
    QColor error() const { return m_error; }
    QColor info() const { return m_info; }
    QColor white() const { return m_white; }

    QColor synKeyword() const { return m_synKeyword; }
    QColor synString() const { return m_synString; }
    QColor synNumber() const { return m_synNumber; }
    QColor synComment() const { return m_synComment; }
    QColor synFunction() const { return m_synFunction; }
    QColor synType() const { return m_synType; }

signals:
    void themeChanged();

private:
    void applyPalette() {
        if (m_dark) {
            // ─── Dark (Vercel-inspired) ───
            m_bg        = QColor("#09090b");
            m_bgSidebar = QColor("#0c0c0e");
            m_bgElevated= QColor("#111113");
            m_bgSurface = QColor("#18181b");
            m_bgHover   = QColor("#1c1c1f");
            m_bgActive  = QColor("#222225");
            m_fg        = QColor("#fafafa");
            m_fgMuted   = QColor("#71717a");
            m_fgDim     = QColor("#52525b");
            m_border    = QColor("#27272a");
            m_borderLight= QColor("#3f3f46");
            m_borderFocus= QColor("#6366f1");
            m_accent    = QColor("#6366f1");
            m_accentHover= QColor("#818cf8");
            m_accentDim = QColor::fromRgbF(0.39f, 0.4f, 0.95f, 0.12f);
            m_success   = QColor("#4ade80");
            m_warning   = QColor("#fbbf24");
            m_error     = QColor("#f87171");
            m_info      = QColor("#60a5fa");
            m_white     = QColor("#ffffff");
            // Syntax
            m_synKeyword  = QColor("#c084fc");
            m_synString   = QColor("#4ade80");
            m_synNumber   = QColor("#60a5fa");
            m_synComment  = QColor("#52525b");
            m_synFunction = QColor("#fbbf24");
            m_synType     = QColor("#f87171");
        } else {
            // ─── Light (Vercel white) ───
            m_bg        = QColor("#ffffff");
            m_bgSidebar = QColor("#fafafa");
            m_bgElevated= QColor("#ffffff");
            m_bgSurface = QColor("#f4f4f5");
            m_bgHover   = QColor("#f0f0f1");
            m_bgActive  = QColor("#e4e4e7");
            m_fg        = QColor("#09090b");
            m_fgMuted   = QColor("#71717a");
            m_fgDim     = QColor("#a1a1aa");
            m_border    = QColor("#e4e4e7");
            m_borderLight= QColor("#d4d4d8");
            m_borderFocus= QColor("#6366f1");
            m_accent    = QColor("#6366f1");
            m_accentHover= QColor("#4f46e5");
            m_accentDim = QColor::fromRgbF(0.39f, 0.4f, 0.95f, 0.08f);
            m_success   = QColor("#16a34a");
            m_warning   = QColor("#d97706");
            m_error     = QColor("#dc2626");
            m_info      = QColor("#2563eb");
            m_white     = QColor("#ffffff");
            // Syntax
            m_synKeyword  = QColor("#7c3aed");
            m_synString   = QColor("#16a34a");
            m_synNumber   = QColor("#2563eb");
            m_synComment  = QColor("#a1a1aa");
            m_synFunction = QColor("#d97706");
            m_synType     = QColor("#dc2626");
        }
    }

    bool m_dark{true};

    // Colors (set by applyPalette)
    QColor m_bg, m_bgSidebar, m_bgElevated, m_bgSurface, m_bgHover, m_bgActive;
    QColor m_fg, m_fgMuted, m_fgDim;
    QColor m_border, m_borderLight, m_borderFocus;
    QColor m_accent, m_accentHover, m_accentDim;
    QColor m_success, m_warning, m_error, m_info, m_white;
    QColor m_synKeyword, m_synString, m_synNumber, m_synComment, m_synFunction, m_synType;

    // Static tokens
    qreal m_r4{4}, m_r6{6}, m_r8{8}, m_r12{12}, m_rFull{9999};
    qreal m_s2{2}, m_s4{4}, m_s6{6}, m_s8{8}, m_s12{12}, m_s16{16}, m_s20{20}, m_s24{24};
    QString m_sans{"Segoe UI"};
    QString m_mono{"Cascadia Code"};
    int m_t11{11}, m_t12{12}, m_t13{13}, m_t14{14}, m_t16{16}, m_t20{20}, m_t24{24};
    int m_fast{80}, m_normal{140}, m_slow{220};
    int m_fontSizeXs{10};
};
