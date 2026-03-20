// DbHelper.js — Database-type-aware helper functions
// Usage: import "DbHelper.js" as DB

function isSQL(dbType) {
    var t = (dbType || "").toLowerCase()
    return ["postgres", "mysql", "sqlite", "mssql", "mariadb", "clickhouse", "duckdb", "oracle"].indexOf(t) >= 0
}
function isClickHouse(dbType) { return (dbType || "").toLowerCase() === "clickhouse" }
function isDuckDB(dbType) { return (dbType || "").toLowerCase() === "duckdb" }
function isOracle(dbType) { return (dbType || "").toLowerCase() === "oracle" }
function isMSSQL(dbType) { return (dbType || "").toLowerCase() === "mssql" }
function isMySQL(dbType) { var t = (dbType||"").toLowerCase(); return t === "mysql" || t === "mariadb" }
function isPostgres(dbType) { return (dbType || "").toLowerCase() === "postgres" }
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
        case "postgres":    return "#336791"
        case "mysql":       return "#00758f"
        case "mariadb":     return "#003545"
        case "sqlite":      return "#44A6C6"
        case "mongodb":     return "#00ed64"
        case "redis":       return "#d82c20"
        case "mssql":       return "#CC2927"
        case "clickhouse":  return "#FFCC00"
        case "duckdb":      return "#FFD900"
        case "oracle":      return "#C3160B"
        default:            return "#6366f1"
    }
}

function buildSelectQuery(dbType, entityName) {
    if (isMongo(dbType))
        return '{"find": "' + entityName + '", "limit": 20}'
    if (isRedis(dbType))
        return "KEYS " + entityName + "*"
    if (isOracle(dbType))
        return 'SELECT * FROM "' + entityName + '" FETCH FIRST 100 ROWS ONLY'
    if (isMSSQL(dbType))
        return 'SELECT TOP 100 * FROM [' + entityName + ']'
    if (isClickHouse(dbType))
        return 'SELECT * FROM ' + entityName + ' LIMIT 100'
    if (isDuckDB(dbType))
        return 'SELECT * FROM ' + entityName + ' LIMIT 100'
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
        case "postgres":    return "PostgreSQL"
        case "mysql":       return "MySQL"
        case "mariadb":     return "MariaDB"
        case "sqlite":      return "SQLite"
        case "mongodb":     return "MongoDB"
        case "redis":       return "Redis"
        case "mssql":       return "SQL Server"
        case "clickhouse":  return "ClickHouse"
        case "duckdb":      return "DuckDB"
        case "oracle":      return "Oracle"
        default:            return dbType || "Database"
    }
}

function buildCreateTableSql(tableName, columns, dbType) {
    if (isMongo(dbType) || isRedis(dbType)) return "";
    var lines = [];
    for (var i = 0; i < columns.length; i++) {
        var c = columns[i];
        if (!c.name) continue;
        var line = '"' + c.name + '" ' + (c.type || "VARCHAR(255)");
        if (c.pk) line += " PRIMARY KEY";
        if (!c.nullable && !c.pk) line += " NOT NULL";
        if (c.defaultVal) {
            var isStr = isNaN(c.defaultVal) && c.defaultVal.toUpperCase() !== "NULL";
            line += " DEFAULT " + (isStr ? "'" + c.defaultVal + "'" : c.defaultVal);
        }
        lines.push(line);
    }
    if (lines.length === 0) return "";
    return 'CREATE TABLE "' + (tableName || "new_table") + '" (\n    ' + lines.join(",\n    ") + '\n);';
}

function buildAddColumnSql(tableName, column, dbType) {
    if (isMongo(dbType) || isRedis(dbType)) return "";
    var def = '"' + column.name + '" ' + (column.type || "VARCHAR(255)");
    if (!column.nullable) def += " NOT NULL";
    if (column.defaultVal) def += " DEFAULT " + column.defaultVal;
    return 'ALTER TABLE "' + tableName + '" ADD COLUMN ' + def + ';';
}

function buildDropColumnSql(tableName, columnName, dbType) {
    if (isMongo(dbType) || isRedis(dbType)) return "";
    return 'ALTER TABLE "' + tableName + '" DROP COLUMN "' + columnName + '";';
}

function isSqlite(dbType) { return (dbType || '').toLowerCase() === 'sqlite' }

// Build TRUNCATE command — DB-specific
function buildTruncateSql(tableName, dbType) {
    if (isMSSQL(dbType)) return 'TRUNCATE TABLE [' + tableName + ']'
    if (isOracle(dbType)) return 'TRUNCATE TABLE "' + tableName + '"'
    if (isClickHouse(dbType)) return 'TRUNCATE TABLE IF EXISTS ' + tableName
    if (isDuckDB(dbType)) return 'DELETE FROM ' + tableName  // DuckDB: no TRUNCATE
    return 'TRUNCATE TABLE "' + tableName + '"'
}

// Build DROP TABLE command — DB-specific
function buildDropTableSql(tableName, dbType) {
    if (isMSSQL(dbType)) return 'DROP TABLE IF EXISTS [' + tableName + ']'
    if (isOracle(dbType)) return 'DROP TABLE "' + tableName + '"'
    if (isClickHouse(dbType)) return 'DROP TABLE IF EXISTS ' + tableName
    if (isDuckDB(dbType)) return 'DROP TABLE IF EXISTS ' + tableName
    return 'DROP TABLE IF EXISTS "' + tableName + '"'
}

// Build RENAME TABLE command — DB-specific
function buildRenameSql(oldName, newName, dbType) {
    if (isMSSQL(dbType)) return "EXEC sp_rename '" + oldName + "', '" + newName + "'"
    if (isOracle(dbType)) return 'ALTER TABLE "' + oldName + '" RENAME TO "' + newName + '"'
    if (isMySQL(dbType)) return 'RENAME TABLE `' + oldName + '` TO `' + newName + '`'
    if (isClickHouse(dbType)) return 'RENAME TABLE ' + oldName + ' TO ' + newName
    return 'ALTER TABLE "' + oldName + '" RENAME TO "' + newName + '"'
}

// Build quoted identifier for DB
function quoteIdentifier(name, dbType) {
    if (isMSSQL(dbType)) return '[' + name + ']'
    if (isMySQL(dbType)) return '`' + name + '`'
    if (isOracle(dbType)) return '"' + name + '"'
    return '"' + name + '"'
}

// Build DROP INDEX command — DB-specific syntax
// MSSQL: DROP INDEX [table].[index]
// MySQL/MariaDB: DROP INDEX `idx` ON `table`
// ClickHouse: ALTER TABLE t DROP INDEX idx
// Postgres/Oracle/SQLite/DuckDB: DROP INDEX IF EXISTS "idx"
function buildDropIndexSql(indexName, tableName, dbType) {
    if (isMSSQL(dbType)) return 'DROP INDEX [' + tableName + '].[' + indexName + ']'
    if (isMySQL(dbType)) return 'DROP INDEX `' + indexName + '` ON `' + tableName + '`'
    if (isClickHouse(dbType)) return 'ALTER TABLE ' + tableName + ' DROP INDEX ' + indexName
    return 'DROP INDEX IF EXISTS "' + indexName + '"'
}
