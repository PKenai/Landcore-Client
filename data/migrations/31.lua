function onUpdateDatabase()
	print("> Updating database to version 31 (virtual inventory items)")
	db.query([[
		CREATE TABLE IF NOT EXISTS `player_virtualinventoryitems` (
		  `player_id` int(11) NOT NULL,
		  `sid` int(11) NOT NULL,
		  `pid` int(11) NOT NULL DEFAULT '0',
		  `itemtype` smallint unsigned NOT NULL,
		  `count` smallint NOT NULL DEFAULT '0',
		  `attributes` blob NOT NULL,
		  UNIQUE KEY `player_id_2` (`player_id`, `sid`),
		  FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARACTER SET=utf8;
	]])
	return true
end

