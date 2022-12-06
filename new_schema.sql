
CREATE TABLE IF NOT EXISTS `maker_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `category_id` int(11) NOT NULL,
  `status_id` int(11) NOT NULL,
  `requestor_name` varchar(255) NOT NULL,
  `requestor_email` varchar(255) NOT NULL,
  `requestor_phone` varchar(50) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `created` datetime NOT NULL,
  `updated` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`uuid`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

-- Add admin_notes column to events table
ALTER TABLE `events` ADD COLUMN `admin_notes` text NULL AFTER `description`;

-- Add Events Read-only access
INSERT INTO `permissions` VALUES (9, 'Events Admin Read-only');

-- Add category id to resources
ALTER TABLE `resources` ADD COLUMN `category_id` int(11) NULL AFTER `name`;

-- Fix one of the durations of the preset_events
UPDATE `preset_events` SET `duration`=60 where `id`=10;