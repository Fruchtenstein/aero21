-- MySQL dump 10.13  Distrib 8.0.22, for Linux (x86_64)
--
-- Host: 127.0.0.1    Database: aero21
-- ------------------------------------------------------
-- Server version	8.0.22

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `log`
--

DROP TABLE IF EXISTS `log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `log` (
  `runid` bigint NOT NULL,
  `runnerid` bigint DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `distance` double DEFAULT NULL,
  `time` int DEFAULT NULL,
  `type` varchar(30) DEFAULT NULL,
  `workout_type` int DEFAULT NULL,
  `commute` int DEFAULT NULL,
  `private` tinyint DEFAULT NULL,
  `start_date_local` datetime DEFAULT NULL,
  `timezone` varchar(50) DEFAULT NULL,
  `utc_offset` varchar(30) DEFAULT NULL,
  `name` text,
  `elapsed_time` int DEFAULT NULL,
  `total_elevation_gain` double DEFAULT NULL,
  `start_latitude` double DEFAULT NULL,
  `start_longitude` double DEFAULT NULL,
  `end_latitude` double DEFAULT NULL,
  `end_longitude` double DEFAULT NULL,
  `location_city` varchar(100) DEFAULT NULL,
  `location_state` varchar(100) DEFAULT NULL,
  `location_country` varchar(100) DEFAULT NULL,
  `kudos_count` int DEFAULT NULL,
  `comment_count` int DEFAULT NULL,
  `photo_count` int DEFAULT NULL,
  `summary_polyline` longtext,
  `gear_id` varchar(100) DEFAULT NULL,
  `visibility` varchar(20) DEFAULT NULL,
  `pin` tinyint DEFAULT '0',
  PRIMARY KEY (`runid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `playoff`
--

DROP TABLE IF EXISTS `playoff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `playoff` (
  `teamid` tinyint DEFAULT NULL,
  `bracket` tinyint DEFAULT NULL,
  `wins` tinyint DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `points`
--

DROP TABLE IF EXISTS `points`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `points` (
  `teamid` tinyint NOT NULL,
  `week` tinyint NOT NULL,
  `points` int DEFAULT NULL,
  `pcts` float DEFAULT NULL,
  `distance` float DEFAULT NULL,
  `goal` float DEFAULT NULL,
  PRIMARY KEY (`teamid`,`week`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `runners`
--

DROP TABLE IF EXISTS `runners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `runners` (
  `runnerid` bigint NOT NULL,
  `runnername` varchar(50) DEFAULT NULL,
  `username` varchar(20) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `teamid` tinyint DEFAULT NULL,
  `goal` double DEFAULT NULL,
  `sex` tinyint DEFAULT NULL,
  `acctoken` varchar(40) DEFAULT NULL,
  `reftoken` varchar(40) DEFAULT NULL,
  `city` varchar(50) DEFAULT NULL,
  `state` varchar(50) DEFAULT NULL,
  `country` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`runnerid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `teams`
--

DROP TABLE IF EXISTS `teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teams` (
  `teamid` tinyint NOT NULL,
  `teamname` varchar(60) DEFAULT NULL,
  `goal` float DEFAULT NULL,
  PRIMARY KEY (`teamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `teamwlog`
--

DROP TABLE IF EXISTS `teamwlog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teamwlog` (
  `teamid` tinyint NOT NULL,
  `week` tinyint NOT NULL,
  `distance` float DEFAULT NULL,
  `time` int DEFAULT NULL,
  `goal` float DEFAULT NULL,
  PRIMARY KEY (`teamid`,`week`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `titles`
--

DROP TABLE IF EXISTS `titles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `titles` (
  `runnerid` bigint DEFAULT NULL,
  `date` date DEFAULT NULL,
  `title` varchar(500) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wlog`
--

DROP TABLE IF EXISTS `wlog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `wlog` (
  `runnerid` bigint NOT NULL,
  `week` tinyint NOT NULL,
  `distance` float DEFAULT NULL,
  `time` int DEFAULT NULL,
  PRIMARY KEY (`runnerid`,`week`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `wonders`
--

DROP TABLE IF EXISTS `wonders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `wonders` (
  `week` tinyint NOT NULL,
  `type` varchar(10) NOT NULL,
  `runnerid` bigint DEFAULT NULL,
  `teamid` tinyint DEFAULT NULL,
  `wonder` varchar(250) DEFAULT NULL,
  PRIMARY KEY (`week`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-01-05 14:11:00
