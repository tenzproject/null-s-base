-- ============================================================================
-- Null Doorlock — Schéma DB
-- ============================================================================
CREATE TABLE IF NOT EXISTS `Null_doorlock` (
    `id`         INT(11) NOT NULL AUTO_INCREMENT,
    `label`      VARCHAR(64)  DEFAULT NULL,
    `locked`     TINYINT(1)   NOT NULL DEFAULT 1,
    `doors`      LONGTEXT     NOT NULL,          -- JSON: liste des portes physiques {model, x, y, z, heading}
    `groups`     LONGTEXT     DEFAULT NULL,      -- JSON: { jobName = grade } autorisés
    `items`      LONGTEXT     DEFAULT NULL,      -- JSON: liste d'items qui ouvrent
    `code`       VARCHAR(32)  DEFAULT NULL,
    `admin_rank` VARCHAR(32)  DEFAULT NULL,
    `lockpick`   TINYINT(1)   NOT NULL DEFAULT 1, -- crochetage autorisé
    `autolock`   INT(11)      DEFAULT NULL,      -- secondes avant re-verrouillage auto (NULL = off)
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
