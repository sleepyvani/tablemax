// DbHelper.js — Database-type-aware helper functions
// Usage: import "DbHelper.js" as DB

function isSQL(dbType) {
    var t = (dbType || "").toLowerCase()
    return ["postgres", "mysql", "sqlite", "mssql", "mariadb"].indexOf(t) >= 0
}
function isMongo(dbType) { return (dbType || "").toLowerCase() === "mongodb" }
function isRedis(dbType) { return (dbType || "").toLowerCase() === "redis" }

function tableLabel(dbType) {
    if (isMongo(dbType)) return "COLLECTIONS"
    if (isRedis(dbType)) return "KEYS"
    return "TABLES"
}

function columnLabel(dbType) {
    if (isMongo(dbType)) return "Fields"
    if (isRedis(dbType)) return ""
    return "Columns"
}

function entitySingular(dbType) {
    if (isMongo(dbType)) return "collection"
    if (isRedis(dbType)) return "key"
    return "table"
}

function nodeBadge(dbType, nodeType) {
    if (nodeType === "database") return "D"
    if (isMongo(dbType)) return nodeType === "table" ? "C" : "F"   // Collection / Field
    if (isRedis(dbType)) return nodeType === "table" ? "K" : "V"   // Key / Value
    return nodeType === "table" ? "T" : "C"                        // Table / Column
}

function dbAccent(dbType) {
    var t = (dbType || "").toLowerCase()
    switch (t) {
        case "postgres":  return "#336791"
        case "mysql":     return "#00758f"
        case "mariadb":   return "#003545"
        case "sqlite":    return "#44A6C6"
        case "mongodb":   return "#00ed64"
        case "redis":     return "#d82c20"
        case "mssql":     return "#CC2927"
        default:          return "#6366f1"
    }
}

function buildSelectQuery(dbType, entityName) {
    if (isMongo(dbType))
        return '{"find": "' + entityName + '", "limit": 20}'
    if (isRedis(dbType))
        return "KEYS " + entityName + "*"
    return 'SELECT * FROM "' + entityName + '" LIMIT 100'
}

function queryPlaceholder(dbType) {
    if (isMongo(dbType))
        return '{"find": "collection", "filter": {"key": "value"}}'
    if (isRedis(dbType))
        return "GET key_name\nSET key value\nKEYS *"
    return "SELECT * FROM table_name\nWHERE id = 1;"
}

function queryMode(dbType) {
    if (isMongo(dbType)) return "JSON"
    if (isRedis(dbType)) return "CLI"
    return "SQL"
}

function displayName(dbType) {
    var t = (dbType || "").toLowerCase()
    switch (t) {
        case "postgres":  return "PostgreSQL"
        case "mysql":     return "MySQL"
        case "mariadb":   return "MariaDB"
        case "sqlite":    return "SQLite"
        case "mongodb":   return "MongoDB"
        case "redis":     return "Redis"
        case "mssql":     return "SQL Server"
        default:          return dbType || "Database"
    }
}
