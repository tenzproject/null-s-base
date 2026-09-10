-- ============================================================================
-- KEVLAR SYSTEM — Database Migration
-- Run this SQL once to add kevlar items and tracking table
-- ============================================================================

-- 1. Add new kevlar items to the items table (unique = 1 for per-item metadata tracking)
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`, `unique`)
VALUES
  ('kevlar_light',  'Kevlar Léger',    2, 0, 1, 1),
  ('kevlar_medium', 'Kevlar Standard', 3, 0, 1, 1),
  ('kevlar_heavy',  'Kevlar Lourd',    4, 0, 1, 1)
ON DUPLICATE KEY UPDATE `unique` = 1, `label` = VALUES(`label`), `weight` = VALUES(`weight`);

-- 2. Create kevlar tracking table (durability persistence)
CREATE TABLE IF NOT EXISTS `vkevlars` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(60) NOT NULL,
  `item_name` VARCHAR(50) NOT NULL,
  `unique_id` VARCHAR(100) NOT NULL,
  `durability` FLOAT NOT NULL DEFAULT 100,
  `equipped` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uk_unique_id` (`unique_id`),
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_equipped` (`identifier`, `equipped`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
