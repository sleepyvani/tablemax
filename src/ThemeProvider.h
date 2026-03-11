#pragma once
#include <QObject>
#include <QColor>

class ThemeProvider : public QObject {
    Q_OBJECT

    // ─── Colors ───
    Q_PROPERTY(QColor bg MEMBER m_bg CONSTANT)
    Q_PROPERTY(QColor bgSidebar MEMBER m_bgSidebar CONSTANT)
    Q_PROPERTY(QColor bgElevated MEMBER m_bgElevated CONSTANT)
    Q_PROPERTY(QColor bgSurface MEMBER m_bgSurface CONSTANT)
    Q_PROPERTY(QColor bgHover MEMBER m_bgHover CONSTANT)
    Q_PROPERTY(QColor bgActive MEMBER m_bgActive CONSTANT)
    Q_PROPERTY(QColor fg MEMBER m_fg CONSTANT)
    Q_PROPERTY(QColor fgMuted MEMBER m_fgMuted CONSTANT)
    Q_PROPERTY(QColor fgDim MEMBER m_fgDim CONSTANT)
    Q_PROPERTY(QColor border MEMBER m_border CONSTANT)
    Q_PROPERTY(QColor borderLight MEMBER m_borderLight CONSTANT)
    Q_PROPERTY(QColor borderFocus MEMBER m_borderFocus CONSTANT)
    Q_PROPERTY(QColor accent MEMBER m_accent CONSTANT)
    Q_PROPERTY(QColor accentHover MEMBER m_accentHover CONSTANT)
    Q_PROPERTY(QColor accentDim MEMBER m_accentDim CONSTANT)
    Q_PROPERTY(QColor success MEMBER m_success CONSTANT)
    Q_PROPERTY(QColor warning MEMBER m_warning CONSTANT)
    Q_PROPERTY(QColor error MEMBER m_error CONSTANT)
    Q_PROPERTY(QColor info MEMBER m_info CONSTANT)

    // Syntax
    Q_PROPERTY(QColor synKeyword MEMBER m_synKeyword CONSTANT)
    Q_PROPERTY(QColor synString MEMBER m_synString CONSTANT)
    Q_PROPERTY(QColor synNumber MEMBER m_synNumber CONSTANT)
    Q_PROPERTY(QColor synComment MEMBER m_synComment CONSTANT)
    Q_PROPERTY(QColor synFunction MEMBER m_synFunction CONSTANT)
    Q_PROPERTY(QColor synType MEMBER m_synType CONSTANT)

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
    Q_PROPERTY(QColor background MEMBER m_bg CONSTANT)
    Q_PROPERTY(QColor foreground MEMBER m_fg CONSTANT)
    Q_PROPERTY(QColor primary MEMBER m_accent CONSTANT)
    Q_PROPERTY(QColor primaryForeground MEMBER m_white CONSTANT)
    Q_PROPERTY(QColor secondary MEMBER m_bgSurface CONSTANT)
    Q_PROPERTY(QColor secondaryForeground MEMBER m_fg CONSTANT)
    Q_PROPERTY(QColor muted MEMBER m_bgSurface CONSTANT)
    Q_PROPERTY(QColor mutedForeground MEMBER m_fgMuted CONSTANT)
    Q_PROPERTY(QColor card MEMBER m_bgElevated CONSTANT)
    Q_PROPERTY(QColor cardForeground MEMBER m_fg CONSTANT)
    Q_PROPERTY(QColor popover MEMBER m_bgElevated CONSTANT)
    Q_PROPERTY(QColor popoverForeground MEMBER m_fg CONSTANT)
    Q_PROPERTY(QColor destructive MEMBER m_error CONSTANT)
    Q_PROPERTY(QColor destructiveForeground MEMBER m_white CONSTANT)
    Q_PROPERTY(QColor input MEMBER m_borderLight CONSTANT)
    Q_PROPERTY(QColor ring MEMBER m_borderFocus CONSTANT)
    Q_PROPERTY(QColor accentColor MEMBER m_accentDim CONSTANT)
    Q_PROPERTY(QColor accentForeground MEMBER m_fg CONSTANT)

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
    explicit ThemeProvider(QObject* p = nullptr) : QObject(p) {}

private:
    QColor m_bg{"#0a0a0f"};
    QColor m_bgSidebar{"#0d0d14"};
    QColor m_bgElevated{"#111118"};
    QColor m_bgSurface{"#16161f"};
    QColor m_bgHover{"#1a1a24"};
    QColor m_bgActive{"#1e1e2a"};
    QColor m_fg{"#e4e4e9"};
    QColor m_fgMuted{"#6b6b80"};
    QColor m_fgDim{"#4a4a5e"};
    QColor m_border{"#1e1e2a"};
    QColor m_borderLight{"#2a2a38"};
    QColor m_borderFocus{"#6366f1"};
    QColor m_accent{"#6366f1"};
    QColor m_accentHover{"#818cf8"};
    QColor m_accentDim = QColor::fromRgbF(0.39f, 0.4f, 0.95f, 0.12f);
    QColor m_success{"#34d399"};
    QColor m_warning{"#fbbf24"};
    QColor m_error{"#f87171"};
    QColor m_info{"#60a5fa"};
    QColor m_white{"#ffffff"};

    QColor m_synKeyword{"#c084fc"};
    QColor m_synString{"#34d399"};
    QColor m_synNumber{"#60a5fa"};
    QColor m_synComment{"#4a4a5e"};
    QColor m_synFunction{"#fbbf24"};
    QColor m_synType{"#f87171"};

    qreal m_r4{4}, m_r6{6}, m_r8{8}, m_r12{12}, m_rFull{9999};
    qreal m_s2{2}, m_s4{4}, m_s6{6}, m_s8{8}, m_s12{12}, m_s16{16}, m_s20{20}, m_s24{24};
    QString m_sans{"Segoe UI"};
    QString m_mono{"Cascadia Code"};
    int m_t11{11}, m_t12{12}, m_t13{13}, m_t14{14}, m_t16{16}, m_t20{20}, m_t24{24};
    int m_fast{80}, m_normal{140}, m_slow{220};
    int m_fontSizeXs{10};
};
