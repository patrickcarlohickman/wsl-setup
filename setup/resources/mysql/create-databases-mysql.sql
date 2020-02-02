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
 * Laravel version databases. Character set and collation changed in Laravel 5.4.
 */

CREATE DATABASE IF NOT EXISTS `laravel41` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE 'utf8_unicode_ci' ;
GRANT ALL ON `laravel41`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `laravel42` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE 'utf8_unicode_ci' ;
GRANT ALL ON `laravel42`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `laravel50` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE 'utf8_unicode_ci' ;
GRANT ALL ON `laravel50`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `laravel51` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE 'utf8_unicode_ci' ;
GRANT ALL ON `laravel51`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `laravel52` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE 'utf8_unicode_ci' ;
GRANT ALL ON `laravel52`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `laravel53` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE 'utf8_unicode_ci' ;
GRANT ALL ON `laravel53`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `laravel54` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE 'utf8mb4_unicode_ci' ;
GRANT ALL ON `laravel54`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `laravel55` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE 'utf8mb4_unicode_ci' ;
GRANT ALL ON `laravel55`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `laravel56` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE 'utf8mb4_unicode_ci' ;
GRANT ALL ON `laravel56`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `laravel57` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE 'utf8mb4_unicode_ci' ;
GRANT ALL ON `laravel57`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `laravel58` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE 'utf8mb4_unicode_ci' ;
GRANT ALL ON `laravel58`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `laravel6x` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE 'utf8mb4_unicode_ci' ;
GRANT ALL ON `laravel6x`.* TO 'homestead'@'%' ;

/*
 * Lumen version databases. Character set and collation changed in Lumen 5.6.
 */

CREATE DATABASE IF NOT EXISTS `lumen50` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE 'utf8_unicode_ci' ;
GRANT ALL ON `lumen50`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `lumen51` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE 'utf8_unicode_ci' ;
GRANT ALL ON `lumen51`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `lumen52` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE 'utf8_unicode_ci' ;
GRANT ALL ON `lumen52`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `lumen53` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE 'utf8_unicode_ci' ;
GRANT ALL ON `lumen53`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `lumen54` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE 'utf8_unicode_ci' ;
GRANT ALL ON `lumen54`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `lumen55` DEFAULT CHARACTER SET utf8 DEFAULT COLLATE 'utf8_unicode_ci' ;
GRANT ALL ON `lumen55`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `lumen56` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE 'utf8mb4_unicode_ci' ;
GRANT ALL ON `lumen56`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `lumen57` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE 'utf8mb4_unicode_ci' ;
GRANT ALL ON `lumen57`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `lumen58` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE 'utf8mb4_unicode_ci' ;
GRANT ALL ON `lumen58`.* TO 'homestead'@'%' ;

CREATE DATABASE IF NOT EXISTS `lumen6x` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE 'utf8mb4_unicode_ci' ;
GRANT ALL ON `lumen6x`.* TO 'homestead'@'%' ;

/*
 * Flush privileges after all databases are created.
 */

FLUSH PRIVILEGES ;
