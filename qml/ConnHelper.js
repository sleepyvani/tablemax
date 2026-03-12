// ConnHelper.js — Connection string building utilities
// Usage: import "ConnHelper.js" as Conn

function defaultPort(dbType) {
    var t = (dbType || "").toLowerCase()
    switch (t) {
        case "postgres":  return "5432"
        case "mysql":     return "3306"
        case "mariadb":   return "3306"
        case "mongodb":   return "27017"
        case "redis":     return "6379"
        case "mssql":     return "1433"
        case "sqlite":    return ""
        default:          return ""
    }
}

function defaultUser(dbType) {
    var t = (dbType || "").toLowerCase()
    switch (t) {
        case "postgres":  return "postgres"
        case "mysql":     return "root"
        case "mariadb":   return "root"
        case "mongodb":   return "admin"
        case "mssql":     return "sa"
        case "redis":     return ""
        case "sqlite":    return ""
        default:          return ""
    }
}

function defaultDatabase(dbType) {
    var t = (dbType || "").toLowerCase()
    switch (t) {
        case "postgres":  return "postgres"
        case "mysql":     return "mydb"
        case "mariadb":   return "mydb"
        case "mongodb":   return "admin"
        case "mssql":     return "master"
        default:          return ""
    }
}

function needsAuth(dbType) {
    var t = (dbType || "").toLowerCase()
    return t !== "sqlite" && t !== "redis"
}

function needsDatabase(dbType) {
    var t = (dbType || "").toLowerCase()
    return t !== "sqlite" && t !== "redis"
}

function needsHost(dbType) {
    return (dbType || "").toLowerCase() !== "sqlite"
}

function connStrPlaceholder(dbType) {
    var t = (dbType || "").toLowerCase()
    switch (t) {
        case "postgres":  return "postgresql://user:pass@localhost:5432/mydb"
        case "mysql":     return "mysql://user:pass@localhost:3306/mydb"
        case "mariadb":   return "mysql://user:pass@localhost:3306/mydb"
        case "sqlite":    return "C:\\path\\to\\database.db"
        case "mongodb":   return "mongodb://user:pass@localhost:27017/admin"
        case "redis":     return "redis://localhost:6379"
        case "mssql":     return "Server=localhost;Database=db;User=sa;Password=pass"
        default:          return ""
    }
}

function buildConnStr(dbType, host, port, user, pass, db, redisPass) {
    var t = (dbType || "").toLowerCase()
    var h = host || "localhost"
    var p = port || ""

    if (t === "sqlite") return host || ""  // host = file path for SQLite
    if (t === "redis") {
        var rp = redisPass || ""
        return "redis://" + (rp ? ":" + rp + "@" : "") + h + (p ? ":" + p : "")
    }

    var u = user || ""
    var pw = pass || ""
    var auth = u ? u + (pw ? ":" + pw : "") + "@" : ""
    var hp = h + (p ? ":" + p : "")

    if (t === "postgres") return "postgresql://" + auth + hp + "/" + (db || "")
    if (t === "mysql" || t === "mariadb") return "mysql://" + auth + hp + "/" + (db || "")
    if (t === "mongodb") return "mongodb://" + auth + hp + "/" + (db || "")
    if (t === "mssql") {
        var s = "Server=" + h + (p ? "," + p : "") + ";Database=" + (db || "")
        if (u) s += ";User=" + u
        if (pw) s += ";Password=" + pw
        return s
    }
    return h
}
