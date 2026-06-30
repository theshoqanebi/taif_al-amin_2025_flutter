-- ============================================================================
-- 1) ITEMS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS Items
(
    id        INTEGER UNIQUE,
    item_name TEXT,
    count     REAL,
    price     INTEGER,
    date      TEXT,
    belongTo  TEXT,
    PRIMARY KEY (id AUTOINCREMENT)
);

-- ============================================================================
-- 2) SELLS TABLE (Main Sales)
-- ============================================================================
CREATE TABLE IF NOT EXISTS Sells
(
    id               INTEGER UNIQUE,
    bill             TEXT,
    name             TEXT,
    phone            TEXT,
    address          TEXT,
    date             TEXT,
    payment_uuid     TEXT,
    discount_details TEXT,
    PRIMARY KEY (id AUTOINCREMENT)
);

-- ============================================================================
-- 3) ADDITIONAL AMOUNT TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS additionalAmount (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    bill        TEXT,
    count       TEXT,  -- m4: Changed from REAL to TEXT
    price       REAL,
    description TEXT,
    totalPrice  REAL,
    belongTo    TEXT,
    sells_id    INTEGER,  -- m2: Added FK link
    FOREIGN KEY (sells_id) REFERENCES Sells(id)
);

CREATE INDEX IF NOT EXISTS idx_additionalAmount_sells_id ON additionalAmount(sells_id);

-- ============================================================================
-- 4) MULTI SELLS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS multiSells (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    bill        TEXT,
    count       TEXT,  -- m4: Changed from REAL to TEXT
    price       REAL,
    description TEXT,
    totalPrice  REAL,
    sells_id    INTEGER,  -- m2: Added FK link
    FOREIGN KEY (sells_id) REFERENCES Sells(id)
);

CREATE INDEX IF NOT EXISTS idx_multiSells_sells_id ON multiSells(sells_id);

-- ============================================================================
-- 5) SELLS MODELS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS sellsModels
(
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    name         TEXT,
    uuid         TEXT,
    ten_chairs   INTEGER,
    eight_chairs INTEGER,
    seven_chairs INTEGER,
    three        INTEGER,
    two          INTEGER,
    chair        INTEGER,
    diwan        INTEGER,
    hidden       INTEGER DEFAULT 0
);

-- ============================================================================
-- 6) EXHIBITIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS Exhibitions
(
    id               INTEGER,
    bill             TEXT,
    date             TEXT,
    payed_amount     INTEGER,
    discount         INTEGER,
    discount_details TEXT,
    notes            TEXT,
    currency         TEXT,
    exchange_rate    REAL,        -- USD bills only: دولار -> دينار, set per bill
    belongTo         TEXT,
    PRIMARY KEY (id AUTOINCREMENT)
);

-- ============================================================================
-- 7) EXHIBITIONS INFO TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS exhibitionsInfo
(
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    bill     INTEGER,
    name     TEXT,
    phone    TEXT,
    address  TEXT,
    belongTo TEXT UNIQUE
);

-- ============================================================================
-- 9) EXHIBITIONS ADDITIONAL AMOUNT TABLE
-- ============================================================================


CREATE TABLE IF NOT EXISTS ExhibitionsAdditionalAmount
(
    id       INTEGER UNIQUE,
    bill     TEXT,
    name     TEXT,
    count    REAL,
    price    INTEGER,
    belongTo TEXT,
    PRIMARY KEY (id AUTOINCREMENT)
);


-- ============================================================================
-- 8) EXHIBITIONS MODELS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS ExhibitionsModels
(
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    name         TEXT,
    uuid         TEXT,
    ten_chairs   INTEGER,
    eight_chairs INTEGER,
    seven_chairs INTEGER,
    three        INTEGER,
    two          INTEGER,
    chair        INTEGER,
    diwan        INTEGER,
    belongTo     TEXT,
    hidden       INTEGER DEFAULT 0
);


-- ============================================================================
-- 10) EXHIBITIONS MULTI SELLS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS ExhibitionsMultiSells
(
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    bill       TEXT,
    model_id   INTEGER,
    type       TEXT,
    set_number INTEGER,
    count      REAL,
    color      TEXT,
    belongTo   TEXT
);

-- ============================================================================
-- 11) TRANSPORT TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS Transport (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    price       INTEGER,
    date        INTEGER,  -- m1: Changed from TEXT to INTEGER
    notes       TEXT
);

-- ============================================================================
-- 12) CUSTOMERS DEBTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS CustomersDebts (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    bill        TEXT,
    bill_number INTEGER,
    customer    TEXT,
    debt        REAL,
    debt_date   INTEGER,  -- m1: Changed from TEXT to INTEGER
    sells_id    INTEGER,  -- m2: Added FK link
    FOREIGN KEY (sells_id) REFERENCES Sells(id)
);

CREATE INDEX IF NOT EXISTS idx_CustomersDebts_sells_id ON CustomersDebts(sells_id);

-- ============================================================================
-- 13) CUSTOMERS PAYMENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS CustomersPayments (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    customer        TEXT,
    paidAmount      REAL,
    payment_date    INTEGER,  -- m1: Changed from TEXT to INTEGER
    notes           TEXT
);

-- ============================================================================
-- 14) ON US DEBTS TABLE — debts the business owes to someone else
-- (separate ledger from CustomersDebts, which is money owed TO the business)
-- ============================================================================
CREATE TABLE IF NOT EXISTS OnUsDebts (
    id       INTEGER,
    name     TEXT,
    date     TEXT,
    bill     TEXT,
    tPrice   INTEGER,
    notes    TEXT,
    currency TEXT,
    PRIMARY KEY (id AUTOINCREMENT)
);

-- ============================================================================
-- 15) ON US PAYMENTS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS OnUsPayments (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    debt_id        INTEGER NOT NULL,
    payment_amount INTEGER NOT NULL,
    payment_date   TEXT NOT NULL,
    notes          TEXT,
    FOREIGN KEY (debt_id) REFERENCES OnUsDebts(id) ON DELETE CASCADE
);

-- ============================================================================
-- 16) SUPPLIES TABLE (m5: New table replacing Fabric, Sponges, Woods, Paints)
-- ============================================================================
CREATE TABLE IF NOT EXISTS Supplies (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    bill      TEXT,
    date      INTEGER,
    tPrice    INTEGER,
    pPrice    INTEGER,
    notes     TEXT,
    belongTo  TEXT,
    type      TEXT NOT NULL,  -- 'paint', 'sponge', 'wood', 'fabric'
    currency  TEXT NOT NULL DEFAULT 'IQD',  -- 'IQD' or 'USD'
    exchange_rate REAL        -- USD records only: دولار -> دينار, set per record
);
