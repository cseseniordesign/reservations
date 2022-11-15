
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

--Update-user-table-default-password
ALTER TABLE `reservation`.`users` 
CHANGE COLUMN `password_hash` `password_hash` VARCHAR(255) NULL DEFAULT '$2a$12$RGRjbe3xauqpFLf3eMskVOITvZgrHsDdZ/0zr03zxFNQM3k3HFOHS';

--Add expiration_reminders-table
CREATE TABLE `expiration_reminders` (
  `ID` INT(11) NOT NULL AUTO_INCREMENT,
  `first_reminder` INT(11) NOT NULL,
  `second_reminder` INT(11) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

INSERT INTO `reservation`.`expiration_reminders` (`ID`, `first_reminder`, `second_reminder`) VALUES ('1', '3', '0');