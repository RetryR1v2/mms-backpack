CREATE TABLE `mms_backpack` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`backpackid` VARCHAR(50) NULL DEFAULT NULL COLLATE 'armscii8_general_ci',
	`backpackmodel` VARCHAR(50) NULL DEFAULT NULL COLLATE 'armscii8_general_ci',
	`inventorylimit` INT(11) NULL DEFAULT NULL,
	PRIMARY KEY (`id`) USING BTREE
)
COLLATE='armscii8_general_ci'
ENGINE=InnoDB
AUTO_INCREMENT=2
;
