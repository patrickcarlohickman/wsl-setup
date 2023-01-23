/*
 * This sql script is used to create all the mysql databases for the system.
 *
 * CREATE DATABASE IF NOT EXISTS `dbname` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE 'utf8mb4_unicode_ci' ;
 * GRANT ALL ON `dbname`.* TO 'username'@'%' ;
 *
 * mysql -u root -p < create-databases-mysql.sql
 */

/*
 * Application databases.
 */

CREATE DATABASE IF NOT EXISTS `homestead` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE 'utf8mb4_unicode_ci' ;
GRANT ALL ON `homestead`.* TO 'homestead'@'%' ;

/*
 * Flush privileges after all databases are created.
 */

FLUSH PRIVILEGES ;
