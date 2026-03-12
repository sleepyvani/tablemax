// FormatHelper.js — Value display formatting utilities
// Usage: import "FormatHelper.js" as Fmt

// Truncate string with ellipsis
function truncate(str, maxLen) {
    if (!str) return ""
    maxLen = maxLen || 40
    return str.length > maxLen ? str.substring(0, maxLen) + "…" : str
}

// Format row count with thousands separator: 1234 → "1,234"
function formatNumber(n) {
    if (n === null || n === undefined) return "0"
    return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
}

// Format row count with label: 1234 → "1,234 rows"
function formatRowCount(n) {
    if (n === null || n === undefined || n === 0) return "0 rows"
    return formatNumber(n) + (n === 1 ? " row" : " rows")
}

// Smart exec time: 0.3 → "0.3 ms", 1234 → "1.2 s"
function formatExecTime(ms) {
    if (ms === null || ms === undefined) return ""
    if (ms < 1) return ms.toFixed(2) + " ms"
    if (ms < 1000) return ms.toFixed(1) + " ms"
    return (ms / 1000).toFixed(2) + " s"
}

// Detect value type for coloring
function valueType(val) {
    if (val === null || val === undefined || val === "NULL") return "null"
    var s = String(val)
    if (s === "true" || s === "false") return "bool"
    if (s !== "" && !isNaN(s)) return "number"
    if (s.length === 0) return "empty"
    return "text"
}

// Format bytes: 1024 → "1 KB", 1048576 → "1 MB"
function formatBytes(bytes) {
    if (!bytes || bytes === 0) return "0 B"
    var units = ["B", "KB", "MB", "GB"]
    var i = 0
    var b = bytes
    while (b >= 1024 && i < units.length - 1) { b /= 1024; i++ }
    return (i === 0 ? b : b.toFixed(1)) + " " + units[i]
}

// Time ago: returns "just now", "2m ago", "1h ago", "3d ago"
function timeAgo(dateStr) {
    if (!dateStr) return ""
    var now = new Date()
    var then = new Date(dateStr)
    var diff = Math.floor((now - then) / 1000)

    if (diff < 60) return "just now"
    if (diff < 3600) return Math.floor(diff / 60) + "m ago"
    if (diff < 86400) return Math.floor(diff / 3600) + "h ago"
    if (diff < 604800) return Math.floor(diff / 86400) + "d ago"
    return Math.floor(diff / 604800) + "w ago"
}
