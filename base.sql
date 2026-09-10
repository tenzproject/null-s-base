-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Hôte : ky92912-001.eu.clouddb.ovh.net:35799
-- Généré le : mer. 31 déc. 2025 à 15:39
-- Version du serveur : 8.4.6-6
-- Version de PHP : 8.1.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `fivem`
--

-- --------------------------------------------------------

--
-- Structure de la table `0resmon_delivery_employees`
--

CREATE TABLE `0resmon_delivery_employees` (
  `id` int NOT NULL,
  `user` varchar(64) COLLATE utf8mb4_general_ci NOT NULL,
  `profile` varchar(32) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `level` int DEFAULT NULL,
  `exp` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `0resmon_delivery_employees`
--

INSERT INTO `0resmon_delivery_employees` (`id`, `user`, `profile`, `level`, `exp`, `created_at`, `updated_at`) VALUES
(1, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'profile_1', 2, 0, '2024-08-06 17:58:45', '2024-08-06 18:25:47'),
(2, 'license:063e3a07b7e5204a49b87053d2fd572a89659886', 'profile_1', 1, 0, '2025-02-08 00:41:47', '2025-02-08 00:41:47'),
(3, 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'profile_1', 1, 0, '2025-02-08 15:23:08', '2025-02-08 15:23:08');

-- --------------------------------------------------------

--
-- Structure de la table `account_info`
--

CREATE TABLE `account_info` (
  `account_id` varchar(50) COLLATE utf8mb4_bin NOT NULL DEFAULT 'NULL',
  `license` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `steam` varchar(22) COLLATE utf8mb4_bin DEFAULT NULL,
  `xbl` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL,
  `discord` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL,
  `live` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL,
  `fivem` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL,
  `mail` varchar(265) COLLATE utf8mb4_bin DEFAULT NULL,
  `name` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL,
  `ip` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL,
  `guid` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL,
  `first_connection` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` text COLLATE utf8mb4_bin
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `account_info`
--

INSERT INTO `account_info` (`account_id`, `license`, `steam`, `xbl`, `discord`, `live`, `fivem`, `mail`, `name`, `ip`, `guid`, `first_connection`, `created_at`) VALUES
('null:4195031', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '', '', '', '', '', NULL, '', '', '', '2024-07-12 11:50:10', NULL),
('Pablo delrulio:8389441', 'license:063e3a07b7e5204a49b87053d2fd572a89659886', 'steam:11000015d685fc5', '', 'discord:1057427236199870525', '', 'fivem:4905132', NULL, 'Pablo delrulio', '25.36.123.48', '148618792037042696', '2025-02-08 00:35:57', NULL),
('Leo:378514', 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'steam:110000143004158', '', 'discord:639601196361056256', '', 'fivem:1412254', NULL, 'Leo', '109.128.235.150', '148618792132554758', '2025-02-08 15:20:28', NULL),
('Téo:4434179', 'license:4133ec7e123b91f87741530869df99d6366ab0d6', '', '', 'discord:1203329255006543924', '', '', NULL, 'Téo', '25.48.91.162', '148618792026809024', '2025-03-22 01:29:58', NULL),
('null:5221875', '', '', '', '', '', '', NULL, 'John Doe', NULL, NULL, '2025-04-15 20:12:19', NULL);

-- --------------------------------------------------------

--
-- Structure de la table `activity`
--

CREATE TABLE `activity` (
  `id` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `recolte` varchar(255) NOT NULL,
  `itemrecolte` varchar(255) NOT NULL,
  `traitement` varchar(255) NOT NULL,
  `itemtraitement` varchar(255) NOT NULL,
  `vente` varchar(255) NOT NULL,
  `PrixVente` varchar(255) NOT NULL,
  `illegal` int NOT NULL DEFAULT '0',
  `blipid` int DEFAULT '682'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

--
-- Déchargement des données de la table `activity`
--

INSERT INTO `activity` (`id`, `name`, `recolte`, `itemrecolte`, `traitement`, `itemtraitement`, `vente`, `PrixVente`, `illegal`, `blipid`) VALUES
(23, 'Acier', '{\"x\":231.6760711669922,\"y\":128.83132934570313,\"z\":102.59980773925781}', 'acier', '{\"x\":986.1491088867188,\"y\":-1922.2294921875,\"z\":31.13455963134765}', 'aciertraiter', '{\"x\":1189.81201171875,\"y\":-3105.815673828125,\"z\":5.65034198760986}', '75', 0, 237);

-- --------------------------------------------------------

--
-- Structure de la table `addon_account`
--

CREATE TABLE `addon_account` (
  `name` varchar(60) COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(100) COLLATE utf8mb4_bin NOT NULL,
  `shared` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `addon_account`
--

INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES
('property_dirtycash', 'Argent Sale Propriété', 0),
('society_410th', '410 TH', 1),
('society_667_ekip', '667 EKIP', 1),
('society_777', '777', 1),
('society_Bloods', 'bloods', 1),
('society_CartelDeCali', 'CartelDeCali', 1),
('society_Cosa Nostra', 'cosanostra', 1),
('society_Crips', 'Crips', 1),
('society_Madrazo', 'madrazo', 1),
('society_ambulance', 'Ambulance', 1),
('society_atlas', 'Atlas', 1),
('society_avocat', 'Avocat', 1),
('society_bahamas', 'Bahamas', 1),
('society_ballas', 'Ballas', 1),
('society_ballasg', 'Ballas Gang', 1),
('society_blackjackets2', 'BlackJackets2', 1),
('society_blackmarket', 'BlackMarket', 1),
('society_blc', 'Blanchisseur', 1),
('society_bloods', 'Bloods', 1),
('society_bluedragon2', 'Blue Dragon2', 1),
('society_boatshop', 'Concessionnaire Bateaux', 1),
('society_camorra', 'Camorra', 1),
('society_carshop', 'Concessionnaire Voitures', 1),
('society_carteldesinaloa', 'Cartel de Sinaloa', 1),
('society_comorra2', 'Comorra', 1),
('society_cosanostra', 'La Cosa Nostra', 1),
('society_families', 'Families', 1),
('society_fbi', 'FBI', 1),
('society_francsmacons', 'Frans-Maçons', 1),
('society_hommenoir', 'Homme En Noir', 1),
('society_hoova', 'Hoova', 1),
('society_journalist', 'Journaliste', 1),
('society_lacamorra', 'La Camorra', 1),
('society_lamainnoir', 'La main Noir', 1),
('society_lapegre', 'La Pégre', 1),
('society_lesplagues', 'Les Plagues', 1),
('society_losespadas', 'Los Espadas', 1),
('society_lostmc', 'Lost MC', 1),
('society_lostriples', 'Los Triples', 1),
('society_marabunta', 'Marabunta', 1),
('society_maracha', 'Maracha', 1),
('society_mecano', 'Mécano', 1),
('society_peakyblinders', 'Peaky Blinders', 1),
('society_planeshop', 'Concessionnaire Avions', 1),
('society_police', 'Police', 1),
('society_punisher', 'punisher', 1),
('society_punisher2', 'Punisher2', 1),
('society_realestateagent', 'Agent immobilier', 1),
('society_sheriff', 'Sheriff', 1),
('society_southside', 'SouthSide', 1),
('society_sylvester', 'Sylvester', 1),
('society_tabac', 'Tabac', 1),
('society_tata', 'tati', 1),
('society_taxi', 'Taxi', 1),
('society_unicorn', 'Unicorn', 1),
('society_vagos', 'Vagos', 1),
('society_vendetta2', 'Vendetta2', 1),
('society_vigne', 'Vigneron', 1),
('society_wader', 'Wader', 1),
('society_widowmaker', 'WidowMaker', 1),
('trunk_dirtycash', 'Argent Sale Coffre Véhicule', 0),
('tt', 'AZA', 1),
('yo', 'test', 1),
('society_blood', 'Bloods', 1),
('society_nullbar1', 'nullbar test 1', 1),
('society_bahamas', 'Bahamas', 1),
('society_beachcayo', 'Cayo Beach', 1),
('society_testnull', 'Test', 1),
('society_blood', 'Bloods', 1),
('society_ballas', 'Ballas', 1),
('society_families', 'Families', 1),
('society_vagos', 'Vagos', 1),
('society_vagos', 'Vagos', 1),
('society_vagos', 'Vagos', 1),
('society_vagos', 'Vagos', 1),
('society_blood', 'Bloods', 1),
('society_vagos', 'Vagos', 1),
('society_blood', 'Bloods', 1),
('society_vagos', 'Vagos', 1),
('society_unicorn', 'Unicorn', 1),
('society_unicorn', 'Unicorn', 1),
('society_bahama', 'Bahama', 1),
('society_cayo', 'Cayo Perico', 1),
('society_bmf', 'Black Mafia Families', 1),
('society_cahamas', 'Cahamas', 1),
('society_nullee', 'nulle', 1),
('society_gangnull', 'gangnull', 1),
('society_bnullv150', 'A DELETE', 1),
('society_bnullv150', 'A DELETE', 1),
('society_bnullv150', 'A DELETE', 1),
('society_testdenull', 'A DELETE', 1),
('society_test2', 'Test', 1),
('society_testencore', 'Test', 1),
('society_ENCOREE', 'ENCOREE', 1),
('society_test', 'TEST', 1),
('society_newtest', 'Testtttttttt', 1),
('society_testsetjob2', 'testsetjob2', 1),
('society_test', 'test', 1),
('society_testBar', 'TestBar', 1),
('society_testbar', 'TestBar', 1),
('society_testbar1', 'testbar1', 1),
('society_bloods', 'Bloods', 1),
('society_wingwangbar', 'Bar Wing Wang', 1),
('society_bloods', 'Bloods', 1);

-- --------------------------------------------------------

--
-- Structure de la table `addon_account_data`
--

CREATE TABLE `addon_account_data` (
  `id` int NOT NULL,
  `account_name` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `money` double NOT NULL,
  `owner` varchar(60) COLLATE utf8mb4_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Structure de la table `addon_inventory`
--

CREATE TABLE `addon_inventory` (
  `name` varchar(60) COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(100) COLLATE utf8mb4_bin NOT NULL,
  `shared` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `addon_inventory`
--

INSERT INTO `addon_inventory` (`name`, `label`, `shared`) VALUES
('property', 'Propriété', 0),
('society_410th', '410 TH', 1),
('society_667_ekip', '667 EKIP', 1),
('society_777', '777', 1),
('society_Bloods', 'bloods', 1),
('society_CJNG', 'cjng', 1),
('society_Cali', 'Cartel de cali', 1),
('society_CartelDeCali', 'CartelDeCali', 1),
('society_Cosa Nostra', 'cosanostra', 1),
('society_Crips', 'Crips', 1),
('society_MS13', 'Mafia', 1),
('society_Madrazo', 'madrazo', 1),
('society_MerryWeather', 'Mercenaire', 1),
('society_Opinel13', 'Opinel13', 1),
('society_Predis', 'predis', 1),
('society_Sinaloa', 'sinaloa', 1),
('society_Yakuza', 'yakuza', 1),
('society_ambulance', 'Ambulance', 1),
('society_atlas', 'Atlas', 1),
('society_avocat', 'Avocat', 1),
('society_bahamas', 'Bahamas', 1),
('society_bahamas_fridge', 'Bahamas (frigo)', 1),
('society_ballas', 'Ballas', 1),
('society_ballasg', 'Ballas Gang', 1),
('society_blackjackets2', 'BlackJackets2', 1),
('society_blackmarket', 'BlackMarket', 1),
('society_blc', 'Blanchisseur', 1),
('society_bloods', 'Bloods', 1),
('society_bluedragon2', 'Blue Dragon2', 1),
('society_boatshop', 'Concessionnaire Bateaux', 1),
('society_camorra', 'Camorra', 1),
('society_carshop', 'Concessionnaire Voitures', 1),
('society_carteldesinaloa', 'Cartel de Sinaloa', 1),
('society_comorra2', 'Comorra', 1),
('society_cosanostra', 'La Cosa Nostra', 1),
('society_families', 'Families', 1),
('society_fbi', 'FBI', 1),
('society_francsmacons', 'Frans-Maçons', 1),
('society_gordo', 'Gordo', 1),
('society_hommenoir', 'Homme En Noir', 1),
('society_hoova', 'Hoova', 1),
('society_journalist', 'Journaliste', 1),
('society_lacamorra', 'La Camorra', 1),
('society_lalegion', 'C.I.A', 1),
('society_lamainnoir', 'La Main Noir', 1),
('society_lapegre', 'La Pégre', 1),
('society_lesplagues', 'Les Plagues', 1),
('society_losespadas', 'Los Espadas', 1),
('society_lostmc', 'Lost MC', 1),
('society_lostriples', 'Los Triples', 1),
('society_marabunta', 'Marabunta', 1),
('society_maracha', 'Maracha', 1),
('society_mecano', 'Mécano', 1),
('society_merryweather', 'Aucun', 1),
('society_peakyblinders', 'Peaky Blinders', 1),
('society_planeshop', 'Concessionnaire Avions', 1),
('society_police', 'Police', 1),
('society_punisher', 'Punisher', 1),
('society_punisher2', 'Punisher2', 1),
('society_realestateagent', 'Agent immobilier', 1),
('society_sheriff', 'Sheriff', 1),
('society_southside', 'SouthSide', 1),
('society_sylvester', 'Sylvester', 1),
('society_tabac', 'Tabac', 1),
('society_tata', 'tati', 1),
('society_taxi', 'Taxi', 1),
('society_unicorn', 'Unicorn', 1),
('society_unicorn_fridge', 'Unicorn (frigo)', 1),
('society_vagos', 'Vagos', 1),
('society_vendetta2', 'Vendetta2', 1),
('society_vigne', 'Vigneron', 1),
('society_wader', 'Wader', 1),
('society_widowmaker', 'WidowMaker', 1),
('society_yiddish', 'Yiddish', 1),
('trunk', 'Coffre Véhicule', 0),
('tt', 'AZA', 1),
('yo', 'test', 1),
('society_blood', 'Bloods', 1),
('society_nullbar1', 'nullbar test 1', 1),
('society_bahamas', 'Bahamas', 1),
('society_beachcayo', 'Cayo Beach', 1),
('society_testnull', 'Test', 1),
('society_blood', 'Bloods', 1),
('society_ballas', 'Ballas', 1),
('society_families', 'Families', 1),
('society_vagos', 'Vagos', 1),
('society_vagos', 'Vagos', 1),
('society_vagos', 'Vagos', 1),
('society_vagos', 'Vagos', 1),
('society_blood', 'Bloods', 1),
('society_vagos', 'Vagos', 1),
('society_blood', 'Bloods', 1),
('society_vagos', 'Vagos', 1),
('society_unicorn', 'Unicorn', 1),
('society_unicorn', 'Unicorn', 1),
('society_bahama', 'Bahama', 1),
('society_cayo', 'Cayo Perico', 1),
('society_bmf', 'Black Mafia Families', 1),
('society_cahamas', 'Cahamas', 1),
('society_nullee', 'nulle', 1),
('society_gangnull', 'gangnull', 1),
('society_bnullv150', 'A DELETE', 1),
('society_bnullv150', 'A DELETE', 1),
('society_bnullv150', 'A DELETE', 1),
('society_testdenull', 'A DELETE', 1),
('society_test2', 'Test', 1),
('society_testencore', 'Test', 1),
('society_ENCOREE', 'ENCOREE', 1),
('society_test', 'TEST', 1),
('society_newtest', 'Testtttttttt', 1),
('society_testsetjob2', 'testsetjob2', 1),
('society_test', 'test', 1),
('society_testBar', 'TestBar', 1),
('society_testbar', 'TestBar', 1),
('society_testbar1', 'testbar1', 1),
('society_bloods', 'Bloods', 1),
('society_wingwangbar', 'Bar Wing Wang', 1),
('society_bloods', 'Bloods', 1);

-- --------------------------------------------------------

--
-- Structure de la table `addon_inventory_items`
--

CREATE TABLE `addon_inventory_items` (
  `id` int NOT NULL,
  `inventory_name` varchar(100) COLLATE utf8mb4_bin NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_bin NOT NULL,
  `count` int NOT NULL,
  `owner` varchar(60) COLLATE utf8mb4_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `addon_inventory_items`
--

INSERT INTO `addon_inventory_items` (`id`, `inventory_name`, `name`, `count`, `owner`) VALUES
(0, 'society_ambulance', 'medikit', 145, NULL),
(0, 'society_ambulance', 'bandage', 145, NULL),
(0, 'society_bahamas', 'mojito', 9, NULL),
(0, 'society_bahamas', 'beer', 5, NULL),
(0, 'society_bahamas', 'cocafrais', 5, NULL),
(0, 'society_bahamas', 'rhum', 1, NULL),
(0, 'society_nullbar1', 'rhum', 2, NULL),
(0, 'society_nullbar1', 'redbull', 1, NULL),
(0, 'society_nullbar1', 'beer', 1, NULL),
(0, 'society_nullbar1', 'vodka', 1, NULL),
(0, 'society_bahama', 'rhum', 1, NULL),
(0, 'society_bahama', 'fanta', 1, NULL),
(0, 'society_cahamas', 'rhum', 1, NULL),
(0, 'society_cahamas', 'icetea', 2, NULL),
(0, 'society_cahamas', 'cocafrais', 1, NULL),
(0, 'society_cahamas', 'mojito', 1, NULL),
(0, 'society_unicorn', 'Coca Frais', -2, NULL);

-- --------------------------------------------------------

--
-- Structure de la table `baninfo`
--

CREATE TABLE `baninfo` (
  `id` int NOT NULL,
  `license` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL,
  `identifier` varchar(25) COLLATE utf8mb4_bin DEFAULT NULL,
  `liveid` varchar(21) COLLATE utf8mb4_bin DEFAULT NULL,
  `xblid` varchar(21) COLLATE utf8mb4_bin DEFAULT NULL,
  `discord` varchar(30) COLLATE utf8mb4_bin DEFAULT NULL,
  `playerip` varchar(25) COLLATE utf8mb4_bin DEFAULT NULL,
  `playername` varchar(32) COLLATE utf8mb4_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `baninfo`
--

INSERT INTO `baninfo` (`id`, `license`, `identifier`, `liveid`, `xblid`, `discord`, `playerip`, `playername`) VALUES
(21, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', NULL, NULL, NULL, 'discord:447086574346436618', 'ip:109.88.221.74', 'null'),
(22, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(23, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(24, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(25, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(26, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(27, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(28, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(29, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(30, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(31, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(32, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(33, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(34, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(35, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(36, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(37, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(38, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(39, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(40, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(41, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(42, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(43, 'license:063e3a07b7e5204a49b87053d2fd572a89659886', NULL, 'live:914798523004960', 'xbl:2535473002434763', 'discord:1057427236199870525', 'ip:178.51.183.227', 'Pablo delrulio'),
(44, 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'steam:110000143004158', NULL, NULL, 'discord:639601196361056256', 'ip:109.128.235.150', 'Leo'),
(45, 'license:4133ec7e123b91f87741530869df99d6366ab0d6', NULL, NULL, NULL, 'discord:1203329255006543924', 'ip:25.48.91.162', 'Téo'),
(46, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(47, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(48, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(49, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(50, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(51, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(52, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(53, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(54, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(55, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(56, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(57, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(58, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(59, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(60, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(61, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Structure de la table `banlist`
--

CREATE TABLE `banlist` (
  `banid` int NOT NULL,
  `idunique` int DEFAULT NULL,
  `license` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `identifier` varchar(25) COLLATE utf8mb4_bin DEFAULT NULL,
  `liveid` varchar(21) COLLATE utf8mb4_bin DEFAULT NULL,
  `xblid` varchar(21) COLLATE utf8mb4_bin DEFAULT NULL,
  `discord` varchar(30) COLLATE utf8mb4_bin DEFAULT NULL,
  `playerip` varchar(25) COLLATE utf8mb4_bin DEFAULT NULL,
  `targetplayername` varchar(32) COLLATE utf8mb4_bin DEFAULT NULL,
  `sourceplayername` varchar(32) COLLATE utf8mb4_bin DEFAULT NULL,
  `reason` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `timeat` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `expiration` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `permanent` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Structure de la table `banlisthistory`
--

CREATE TABLE `banlisthistory` (
  `id` int NOT NULL,
  `license` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL,
  `identifier` varchar(25) COLLATE utf8mb4_bin DEFAULT NULL,
  `liveid` varchar(21) COLLATE utf8mb4_bin DEFAULT NULL,
  `xblid` varchar(21) COLLATE utf8mb4_bin DEFAULT NULL,
  `discord` varchar(30) COLLATE utf8mb4_bin DEFAULT NULL,
  `playerip` varchar(25) COLLATE utf8mb4_bin DEFAULT NULL,
  `targetplayername` varchar(32) COLLATE utf8mb4_bin DEFAULT NULL,
  `sourceplayername` varchar(32) COLLATE utf8mb4_bin DEFAULT NULL,
  `reason` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `timeat` int NOT NULL,
  `added` varchar(40) COLLATE utf8mb4_bin NOT NULL,
  `expiration` int NOT NULL,
  `permanent` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `banlisthistory`
--

INSERT INTO `banlisthistory` (`id`, `license`, `identifier`, `liveid`, `xblid`, `discord`, `playerip`, `targetplayername`, `sourceplayername`, `reason`, `timeat`, `added`, `expiration`, `permanent`) VALUES
(26, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', NULL, 'live:985154297909493', 'xbl:2535417306317880', 'discord:447086574346436618', '10.5.0.2', 'dev', 'Console', 'Raison Inconnue', 1741189078, 'Wed Mar  5 16:37:58 2025', 1741102678, 1);

-- --------------------------------------------------------

--
-- Structure de la table `bikeshop_history`
--

CREATE TABLE `bikeshop_history` (
  `id` int NOT NULL,
  `vendeur` varchar(50) NOT NULL,
  `acheteur` text NOT NULL,
  `data` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

-- --------------------------------------------------------

--
-- Structure de la table `bikeshop_vehicle`
--

CREATE TABLE `bikeshop_vehicle` (
  `id` int NOT NULL,
  `model` varchar(50) NOT NULL,
  `plate` text NOT NULL,
  `color` text NOT NULL,
  `price` text NOT NULL,
  `data` text NOT NULL,
  `sortis` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

--
-- Déchargement des données de la table `bikeshop_vehicle`
--

INSERT INTO `bikeshop_vehicle` (`id`, `model`, `plate`, `color`, `price`, `data`, `sortis`) VALUES
(477, 'faggio2', 'KFW 3498', '3', '4500', '{\"date\":\"17/02/2024 - 18:06:13\",\"serie\":86788}', 0),
(478, 'Avarus', 'ACW 4973', '3', '42000', '{\"serie\":80974,\"date\":\"17/02/2024 - 18:08:06\"}', 0),
(479, 'sanctus', 'GGR 7539', '1', '55500', '{\"serie\":21482,\"date\":\"17/02/2024 - 18:18:38\"}', 1),
(480, 'sanchez', 'UWC 8884', '3', '13500', '{\"serie\":85703,\"date\":\"17/02/2024 - 18:20:38\"}', 1),
(481, 'bati', 'GKT 3630', '2', '40000', '{\"date\":\"15/10/2024 - 21:21:50\",\"serie\":23894}', 0);

-- --------------------------------------------------------

--
-- Structure de la table `billing`
--

CREATE TABLE `billing` (
  `id` int NOT NULL,
  `identifier` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `sender` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `target_type` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `target` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `amount` int NOT NULL,
  `date` text COLLATE utf8mb4_bin
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `billing`
--

INSERT INTO `billing` (`id`, `identifier`, `sender`, `target_type`, `target`, `label`, `amount`, `date`) VALUES
(6, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Péage', 'society', 'police', 'Amende péage.', 24, '2025-05-05 22:25:37'),
(7, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Péage', 'society', 'police', 'Amende péage.', 24, '2025-05-05 22:25:37'),
(8, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Péage', 'society', 'police', 'Amende péage.', 24, '2025-07-09 16:22:20'),
(9, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Péage', 'society', 'police', 'Amende péage.', 24, '2025-07-10 22:56:31');

-- --------------------------------------------------------

--
-- Structure de la table `booster_users`
--

CREATE TABLE `booster_users` (
  `identifier` varchar(60) COLLATE utf8mb4_general_ci NOT NULL,
  `boost_id` varchar(8) COLLATE utf8mb4_general_ci NOT NULL,
  `time` bigint NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `cardealer_vehicles`
--

CREATE TABLE `cardealer_vehicles` (
  `id` int NOT NULL,
  `vehicle` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `price` int NOT NULL,
  `society` varchar(50) COLLATE utf8mb4_bin NOT NULL DEFAULT 'carshop'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Structure de la table `computers_mail_accounts`
--

CREATE TABLE `computers_mail_accounts` (
  `id` int NOT NULL,
  `identifier` varchar(40) COLLATE utf8mb4_bin NOT NULL,
  `username` varchar(16) COLLATE utf8mb4_bin NOT NULL,
  `password` varchar(32) COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `computers_mail_accounts`
--

INSERT INTO `computers_mail_accounts` (`id`, `identifier`, `username`, `password`) VALUES
(1, '5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null');

-- --------------------------------------------------------

--
-- Structure de la table `concess_history`
--

CREATE TABLE `concess_history` (
  `id` int NOT NULL,
  `vendeur` varchar(50) NOT NULL,
  `acheteur` text NOT NULL,
  `data` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

--
-- Déchargement des données de la table `concess_history`
--

INSERT INTO `concess_history` (`id`, `vendeur`, `acheteur`, `data`) VALUES
(1, 'Virtual Nado', 'LenoirduNet', '{\"serie\":65148,\"date\":\"12/09/2023 - 18:36:46\",\"plate\":\"JMB 8658\",\"model\":\"Blista\"}');

-- --------------------------------------------------------

--
-- Structure de la table `concess_vehicle`
--

CREATE TABLE `concess_vehicle` (
  `id` int NOT NULL,
  `model` varchar(50) NOT NULL,
  `plate` text NOT NULL,
  `color` text NOT NULL,
  `price` text NOT NULL,
  `data` text NOT NULL,
  `sortis` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

--
-- Déchargement des données de la table `concess_vehicle`
--

INSERT INTO `concess_vehicle` (`id`, `model`, `plate`, `color`, `price`, `data`, `sortis`) VALUES
(473, 'fugitive', 'JBH 6877', '1', '12500', '{\"date\":\"27/12/2023 - 11:04:03\",\"serie\":61423}', 0),
(474, 'italigto', 'EAY 2786', '1', '620000', '{\"serie\":87895,\"date\":\"29/12/2023 - 12:13:42\"}', 0),
(475, 'bfinjection', 'GOL 9772', '2', '16000', '{\"serie\":28373,\"date\":\"04/02/2024 - 03:07:29\"}', 0),
(476, 'blista', 'VNQ 7238', '3', '7000', '{\"date\":\"04/02/2024 - 03:08:16\",\"serie\":26550}', 0),
(477, 'btype3', 'QEU 1091', '1', '120000', '{\"date\":\"18/02/2024 - 02:47:32\",\"serie\":86915}', 0),
(478, 'blista', 'BDZ 0133', '1', '7000', '{\"serie\":65870,\"date\":\"20/05/2024 - 03:54:24\"}', 0),
(479, 'blista', 'CVI 9176', '1', '7000', '{\"date\":\"20/05/2024 - 03:56:09\",\"serie\":63044}', 0),
(480, 'patriot', 'LKK 3170', '1', '35000', '{\"date\":\"25/06/2024 - 20:28:41\",\"serie\":47388}', 0),
(481, 'blista', 'IXQ 6432', '2', '7000', '{\"serie\":32773,\"date\":\"20/09/2024 - 23:32:23\"}', 0);

-- --------------------------------------------------------

--
-- Structure de la table `datastore`
--

CREATE TABLE `datastore` (
  `name` varchar(60) COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(100) COLLATE utf8mb4_bin NOT NULL,
  `shared` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `datastore`
--

INSERT INTO `datastore` (`name`, `label`, `shared`) VALUES
('property', 'Propriété', 0),
('society_410th', '410 TH', 1),
('society_667_ekip', '667 EKIP', 1),
('society_777', '777', 1),
('society_Bloods', 'bloods', 1),
('society_CJNG', 'cjng', 1),
('society_Cali', 'Cartel de cali', 1),
('society_CartelDeCali', 'CartelDeCali', 1),
('society_Cosa Nostra', 'cosanostra', 1),
('society_Crips', 'Crips', 1),
('society_MS13', 'Mafia', 1),
('society_Madrazo', 'madrazo', 1),
('society_MerryWeather', 'Mercenaire', 1),
('society_Opinel13', 'Opinel13', 1),
('society_Predis', 'predis', 1),
('society_Sinaloa', 'sinaloa', 1),
('society_Yakuza', 'yakuza', 1),
('society_ambulance', 'Ambulance', 1),
('society_atlas', 'Atlas', 1),
('society_avocat', 'Avocat', 1),
('society_bahamas', 'Bahamas', 1),
('society_ballas', 'Ballas', 1),
('society_ballasg', 'Ballas Gang', 1),
('society_blackjackets2', 'BlackJackets2', 1),
('society_blackmarket', 'BlackMarket', 1),
('society_blc', 'Blanchisseur', 1),
('society_bloods', 'Bloods', 1),
('society_bluedragon2', 'Blue Dragon2', 1),
('society_boatshop', 'Concessionnaire Bateaux', 1),
('society_camorra', 'Camorra', 1),
('society_carshop', 'Concessionnaire Voitures', 1),
('society_carteldesinaloa', 'Cartel de Sinaloa', 1),
('society_comorra2', 'Comorra', 1),
('society_cosanostra', 'La Cosa Nostra', 1),
('society_families', 'Families', 1),
('society_fbi', 'FBI', 1),
('society_francsmacons', 'Frans-Maçons', 1),
('society_gordo', 'Gordo', 1),
('society_hommenoir', 'Homme En Noir', 1),
('society_hoova', 'Hoova', 1),
('society_journalist', 'Journaliste', 1),
('society_lacamorra', 'La Camorra', 1),
('society_lalegion', 'C.I.A', 1),
('society_lamainnoir', 'La Main Noir', 1),
('society_lapegre', 'La Pégre', 1),
('society_lesplagues', 'Les Plagues', 1),
('society_losespadas', 'Los Espadas', 1),
('society_lostmc', 'Lost MC', 1),
('society_lostriples', 'Los Triples', 1),
('society_marabunta', 'Marabunta', 1),
('society_maracha', 'Maracha', 1),
('society_mecano', 'Mécano', 1),
('society_merryweather', 'Aucun', 1),
('society_peakyblinders', 'Peaky Blinders', 1),
('society_punisher', 'punisher', 1),
('society_punisher2', 'Punisher2', 1),
('society_realestateagent', 'Agent immobilier', 1),
('society_southside', 'SouthSide', 1),
('society_sylvester', 'Sylvester', 1),
('society_tabac', 'Tabac', 1),
('society_tata', 'tati', 1),
('society_taxi', 'Taxi', 1),
('society_unicorn', 'Unicorn', 1),
('society_vagos', 'Vagos', 1),
('society_vendetta2', 'Vendetta2', 1),
('society_vigne', 'Vigneron', 1),
('society_wader', 'Wader', 1),
('society_widowmaker', 'WidowMaker', 1),
('society_yiddish', 'Yiddish', 1),
('trunk', 'Coffre Véhicule', 0),
('user_ears', 'Ears', 0),
('user_glasses', 'Glasses', 0),
('user_helmet', 'Helmet', 0),
('user_mask', 'Mask', 0),
('society_blood', 'Bloods', 1),
('society_bahamas', 'Bahamas', 1),
('society_beachcayo', 'Cayo Beach', 1),
('society_testnull', 'Test', 1),
('society_blood', 'Bloods', 1),
('society_ballas', 'Ballas', 1),
('society_families', 'Families', 1),
('society_vagos', 'Vagos', 1),
('society_vagos', 'Vagos', 1),
('society_vagos', 'Vagos', 1),
('society_vagos', 'Vagos', 1),
('society_blood', 'Bloods', 1),
('society_vagos', 'Vagos', 1),
('society_blood', 'Bloods', 1),
('society_vagos', 'Vagos', 1);

-- --------------------------------------------------------

--
-- Structure de la table `datastore_data`
--

CREATE TABLE `datastore_data` (
  `id` int NOT NULL,
  `name` varchar(60) COLLATE utf8mb4_bin NOT NULL,
  `data` longtext COLLATE utf8mb4_bin,
  `owner` varchar(60) COLLATE utf8mb4_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Structure de la table `dealership_sales`
--

CREATE TABLE `dealership_sales` (
  `id` int NOT NULL,
  `shop` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `seller` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `buyer` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `vehicle_data` longtext COLLATE utf8mb4_general_ci NOT NULL,
  `sale_price` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `dealership_sales`
--

INSERT INTO `dealership_sales` (`id`, `shop`, `seller`, `buyer`, `vehicle_data`, `sale_price`, `created_at`) VALUES
(1, 'bikeshop', 'Automatique', 'null', '{\"model\":\"bati\",\"price\":40000}', 40000, '2025-12-18 21:51:08');

-- --------------------------------------------------------

--
-- Structure de la table `drugs_circuits`
--

CREATE TABLE `drugs_circuits` (
  `id` int NOT NULL,
  `name` longtext COLLATE utf8mb4_general_ci,
  `label` longtext COLLATE utf8mb4_general_ci,
  `recolte` longtext COLLATE utf8mb4_general_ci,
  `traitement` longtext COLLATE utf8mb4_general_ci,
  `animtype` longtext COLLATE utf8mb4_general_ci,
  `animdict` longtext COLLATE utf8mb4_general_ci,
  `anim` longtext COLLATE utf8mb4_general_ci,
  `animtime` int DEFAULT NULL,
  `marker` tinyint(1) DEFAULT '0',
  `props` longtext COLLATE utf8mb4_general_ci,
  `name_pooch` longtext COLLATE utf8mb4_general_ci,
  `label_pooch` longtext COLLATE utf8mb4_general_ci,
  `animtype_t` longtext COLLATE utf8mb4_general_ci,
  `animdict_t` longtext COLLATE utf8mb4_general_ci,
  `anim_t` longtext COLLATE utf8mb4_general_ci,
  `animtime_t` int DEFAULT NULL,
  `marker_t` tinyint(1) DEFAULT '0',
  `props_t` longtext COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `drugs_circuits`
--

INSERT INTO `drugs_circuits` (`id`, `name`, `label`, `recolte`, `traitement`, `animtype`, `animdict`, `anim`, `animtime`, `marker`, `props`, `name_pooch`, `label_pooch`, `animtype_t`, `animdict_t`, `anim_t`, `animtime_t`, `marker_t`, `props_t`) VALUES
(7, 'champignonrecolte', 'Champignon', '[{\"x\":2216.1455078125,\"y\":5578.14111328125,\"z\":53.7916374206543},{\"x\":2218.43408203125,\"y\":5577.9169921875,\"z\":53.82825088500976},{\"x\":2220.382080078125,\"y\":5577.8271484375,\"z\":53.83190536499023},{\"x\":2222.98974609375,\"y\":5577.6826171875,\"z\":53.83428192138672},{\"x\":2225.3310546875,\"y\":5577.556640625,\"z\":53.79801559448242},{\"x\":2227.59423828125,\"y\":5577.3330078125,\"z\":53.83546447753906},{\"x\":2230.094970703125,\"y\":5577.13818359375,\"z\":53.92095184326172},{\"x\":2232.362548828125,\"y\":5576.9375,\"z\":54.01036834716797},{\"x\":2233.864990234375,\"y\":5578.11376953125,\"z\":54.01877212524414},{\"x\":2230.416748046875,\"y\":5578.3759765625,\"z\":53.98260116577148},{\"x\":2225.5439453125,\"y\":5578.65380859375,\"z\":53.86727142333984},{\"x\":2223.50341796875,\"y\":5578.78662109375,\"z\":53.88051986694336},{\"x\":2221.315185546875,\"y\":5579.00390625,\"z\":53.90009689331055},{\"x\":2218.89306640625,\"y\":5579.08740234375,\"z\":53.89134216308594},{\"x\":2215.717529296875,\"y\":5575.7626953125,\"z\":53.69360733032226},{\"x\":2218.015380859375,\"y\":5575.779296875,\"z\":53.63824844360351},{\"x\":2220.46484375,\"y\":5575.6171875,\"z\":53.6697883605957},{\"x\":2222.597412109375,\"y\":5575.51904296875,\"z\":53.6696548461914},{\"x\":2227.152587890625,\"y\":5575.24267578125,\"z\":53.68303680419922},{\"x\":2230.83984375,\"y\":5574.90673828125,\"z\":53.84728240966797}]', '[{\"x\":2713.98046875,\"y\":4137.1328125,\"z\":43.98134231567383},{\"x\":2715.5830078125,\"y\":4141.71142578125,\"z\":43.92259979248047},{\"x\":2711.267822265625,\"y\":4142.8583984375,\"z\":43.94112777709961},{\"x\":2709.508544921875,\"y\":4139.6064453125,\"z\":43.91287994384765},{\"x\":2712.334228515625,\"y\":4138.6845703125,\"z\":43.90403747558594},{\"x\":2716.06689453125,\"y\":4138.6240234375,\"z\":43.99352264404297},{\"x\":2715.919189453125,\"y\":4135.45166015625,\"z\":43.91329574584961},{\"x\":2711.233154296875,\"y\":4134.71826171875,\"z\":43.91748809814453}]', 'anim', 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 2000, 1, 'none', 'champignontraitement', 'Champignon Traité', 'scenario', 'PROP_HUMAN_BUM_BIN', 'none', 5000, 1, 'none'),
(13, 'fentanyl', 'Fentanyl', '[{\"z\":12.04475784301757,\"y\":-2663.315185546875,\"x\":38.53451156616211},{\"z\":12.04479885101318,\"y\":-2660.21240234375,\"x\":36.8017463684082},{\"z\":12.04480934143066,\"y\":-2658.8544921875,\"x\":35.04427337646484},{\"z\":12.04481983184814,\"y\":-2658.857177734375,\"x\":31.82087898254394},{\"z\":12.04481220245361,\"y\":-2655.532470703125,\"x\":31.50383949279785},{\"z\":12.04481220245361,\"y\":-2657.848388671875,\"x\":34.86322021484375},{\"z\":12.04481220245361,\"y\":-2661.31640625,\"x\":36.05581283569336},{\"z\":12.04482269287109,\"y\":-2664.218017578125,\"x\":35.20866775512695},{\"z\":12.04482269287109,\"y\":-2662.30908203125,\"x\":33.01615524291992},{\"z\":12.04482269287109,\"y\":-2657.340576171875,\"x\":31.4874210357666},{\"z\":12.04481410980224,\"y\":-2657.70166015625,\"x\":34.09476852416992},{\"z\":12.04481410980224,\"y\":-2661.2763671875,\"x\":37.90315246582031},{\"z\":12.04481410980224,\"y\":-2660.214599609375,\"x\":40.42884063720703},{\"z\":12.04481410980224,\"y\":-2658.03955078125,\"x\":37.99657821655273},{\"z\":12.04481792449951,\"y\":-2655.72900390625,\"x\":32.33344650268555},{\"z\":12.04482460021972,\"y\":-2656.557373046875,\"x\":29.25734329223632},{\"z\":12.04482460021972,\"y\":-2658.940673828125,\"x\":29.50640678405761},{\"z\":12.04481124877929,\"y\":-2658.253662109375,\"x\":34.85587692260742},{\"z\":12.04481124877929,\"y\":-2657.373291015625,\"x\":39.10504531860351},{\"z\":12.04481124877929,\"y\":-2655.167724609375,\"x\":39.22358703613281},{\"z\":12.04481601715087,\"y\":-2656.181640625,\"x\":35.79084777832031},{\"z\":12.04483127593994,\"y\":-2657.730712890625,\"x\":28.92869758605957},{\"z\":12.0450382232666,\"y\":-2656.355224609375,\"x\":26.32877349853515},{\"z\":12.04481792449951,\"y\":-2655.800048828125,\"x\":29.10146141052246},{\"z\":12.04480648040771,\"y\":-2656.7568359375,\"x\":33.50024032592773},{\"z\":12.04480648040771,\"y\":-2656.444580078125,\"x\":36.9344596862793},{\"z\":12.04480648040771,\"y\":-2657.516357421875,\"x\":39.82934188842773},{\"z\":12.04480934143066,\"y\":-2659.120849609375,\"x\":39.29705047607422}]', '[{\"x\":1343.7935791015626,\"y\":4389.41015625,\"z\":44.3437385559082},{\"x\":1341.1500244140626,\"y\":4390.1025390625,\"z\":44.34374618530273},{\"x\":1337.9681396484376,\"y\":4388.353515625,\"z\":44.34344482421875},{\"x\":1340.5526123046876,\"y\":4386.9033203125,\"z\":44.35046005249023},{\"x\":1344.6298828125,\"y\":4388.01953125,\"z\":44.34674835205078},{\"x\":1347.4947509765626,\"y\":4388.68408203125,\"z\":44.35349655151367},{\"x\":1348.397705078125,\"y\":4386.5537109375,\"z\":44.74093246459961},{\"x\":1342.8466796875,\"y\":4386.97998046875,\"z\":44.23745346069336},{\"x\":1340.6148681640626,\"y\":4388.8681640625,\"z\":44.33737564086914},{\"x\":1337.8311767578126,\"y\":4390.5478515625,\"z\":44.34309005737305},{\"x\":1335.578369140625,\"y\":4389.37255859375,\"z\":44.34256744384765},{\"x\":1334.1846923828126,\"y\":4391.9775390625,\"z\":44.34236526489258},{\"x\":1337.8642578125,\"y\":4392.43603515625,\"z\":44.34415435791015},{\"x\":1341.8021240234376,\"y\":4389.65380859375,\"z\":44.34373092651367},{\"x\":1343.3988037109376,\"y\":4387.81494140625,\"z\":44.3437385559082},{\"x\":1345.6583251953126,\"y\":4390.5419921875,\"z\":44.3437385559082}]', 'anim', 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 2000, 1, 'none', 'fentanyltraitement', 'Pochon de Fentanyl', 'scenario', 'PROP_HUMAN_BUM_BIN', 'none', 5000, 1, 'none');

-- --------------------------------------------------------

--
-- Structure de la table `drugs_sell`
--

CREATE TABLE `drugs_sell` (
  `id` int NOT NULL,
  `position` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `message` longtext COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `drugs_sell`
--

INSERT INTO `drugs_sell` (`id`, `position`, `message`) VALUES
(1, '{\"x\":223.64340209960938,\"y\":361.93609619140627,\"z\":106.01580047607422}', 'Salut, je viens d\'avoir ton contact, rejoins moi !'),
(4, '{\"x\":744.7858276367188,\"y\":-1226.4090576171876,\"z\":24.76889991760254}', 'Mon dealos préféré, tu aurais pas un peu de dobe pour moi ? Rejoins moi !'),
(5, '{\"x\":48.1136589050293,\"y\":-1617.7509765625,\"z\":29.35910987854004}', 'Salut, je viens d\'avoir ton contact, rejoins moi !'),
(6, '{\"x\":-337.1455993652344,\"y\":-1485.842041015625,\"z\":30.58897018432617}', 'J\'ai un paquet de fric pour toi, Rejoins moi !'),
(7, '{\"x\":866.59130859375,\"y\":-1061.0830078125,\"z\":28.92093086242675}', 'J\'ai envie de m\'évader, rejoins moi !'),
(8, '{\"x\":1139.843994140625,\"y\":-793.9586791992188,\"z\":57.59371185302734}', 'Salut, je viens d\'avoir ton contact, rejoins moi !'),
(9, '{\"x\":1116.4549560546876,\"y\":-975.5618286132813,\"z\":46.4276008605957}', 'J\'ai un paquet de fric pour toi, Rejoins moi !'),
(10, '{\"x\":1255.7490234375,\"y\":-728.9434814453125,\"z\":63.08428955078125}', 'Mon dealos préféré, tu aurais pas un peu de dobe pour moi ? Rejoins moi !'),
(11, '{\"x\":1347.6109619140626,\"y\":-579.915283203125,\"z\":74.27182006835938}', 'Tu est où ? J\'ai besoin de ta dobe, rejoins moi !'),
(12, '{\"x\":955.7034912109375,\"y\":-1060.512939453125,\"z\":36.9140510559082}', 'Tu as encore du produit magique ? Rejoins moi, je sais que je peux compter sur toi !'),
(14, '{\"x\":-337.54510498046877,\"y\":-937.4935913085938,\"z\":31.08061027526855}', 'Tu as encore du produit magique ? Rejoins moi, je sais que je peux compter sur toi !'),
(15, '{\"x\":-321.01458740234377,\"y\":-708.7540283203125,\"z\":32.90948867797851}', 'J\'ai besoin de ta dobe, rejoins moi à la position !'),
(16, '{\"x\":250.98289489746095,\"y\":-84.9937515258789,\"z\":69.94864654541016}', 'Mon dealos préféré, tu aurais pas un peu de dobe pour moi ? Rejoins moi !'),
(17, '{\"x\":-529.8306274414063,\"y\":-28.73513031005859,\"z\":44.48300170898437}', 'Salut, je viens d\'avoir ton contact, rejoins moi !'),
(18, '{\"x\":-1447.862060546875,\"y\":-366.66900634765627,\"z\":43.54209899902344}', 'J\'ai un paquet de fric pour toi, Rejoins moi !'),
(19, '{\"x\":-1665.5570068359376,\"y\":72.42794036865235,\"z\":63.42919158935547}', 'Tu est où ? J\'ai besoin de ta dobe, rejoins moi !'),
(20, '{\"x\":-1089.6529541015626,\"y\":-303.50421142578127,\"z\":37.64749908447265}', 'Tu as encore un peu de produit pour moi ? Rejoins moi !'),
(21, '{\"x\":67.83145904541016,\"y\":-582.4771728515625,\"z\":31.6286506652832}', 'J\'ai envie de m\'évader, rejoins moi !'),
(22, '{\"x\":508.6759948730469,\"y\":-609.5554809570313,\"z\":24.75115013122558}', 'Mon dealos préféré, tu aurais pas un peu de dobe pour moi ? Rejoins moi !'),
(23, '{\"x\":460.6315002441406,\"y\":-761.1773071289063,\"z\":27.35788917541504}', 'Tu as encore un peu de produit pour moi ? Rejoins moi !'),
(24, '{\"x\":469.0552062988281,\"y\":-585.181396484375,\"z\":28.49962997436523}', 'J\'ai envie de m\'évader, rejoins moi !'),
(25, '{\"x\":188.4803924560547,\"y\":-446.4894104003906,\"z\":41.65034103393555}', 'Tu as encore du produit magique ? Rejoins moi, je sais que je peux compter sur toi !'),
(26, '{\"x\":-113.11299896240235,\"y\":-603.218994140625,\"z\":36.28079986572265}', 'J\'ai besoin de ta dobe, rejoins moi à la position !'),
(27, '{\"x\":171.55740356445313,\"y\":-1235.2259521484376,\"z\":29.31716918945312}', 'Mon dealos préféré, tu aurais pas un peu de dobe pour moi ? Rejoins moi !'),
(28, '{\"x\":168.8957061767578,\"y\":-1074.22900390625,\"z\":29.19271087646484}', 'Salut, je viens d\'avoir ton contact, rejoins moi !'),
(29, '{\"x\":-1026.3599853515626,\"y\":-490.5504150390625,\"z\":36.95706939697265}', 'J\'ai un paquet de fric pour toi, Rejoins moi !'),
(30, '{\"x\":-1187.1409912109376,\"y\":-561.4119262695313,\"z\":27.69302940368652}', 'Tu as encore un peu de produit pour moi ? Rejoins moi !'),
(31, '{\"x\":-1625.845947265625,\"y\":-1013.4970092773438,\"z\":13.14282989501953}', 'J\'ai envie de m\'évader, rejoins moi !'),
(32, '{\"x\":-1478.70703125,\"y\":-1007.2210083007813,\"z\":6.27883720397949}', 'Salut, je viens d\'avoir ton contact, rejoins moi !'),
(33, '{\"x\":-1366.8370361328126,\"y\":-1118.6409912109376,\"z\":4.4401888847351}', 'J\'ai un paquet de fric pour toi, Rejoins moi !'),
(34, '{\"x\":-1307.5059814453126,\"y\":-1310.718017578125,\"z\":4.88076877593994}', 'J\'ai envie de m\'évader, rejoins moi !'),
(35, '{\"x\":-1249.5250244140626,\"y\":-1432.083984375,\"z\":4.32881879806518}', 'J\'ai besoin de ta dobe, rejoins moi à la position !'),
(36, '{\"x\":-1105.416015625,\"y\":-1289.6519775390626,\"z\":5.40987110137939}', 'J\'ai envie de m\'évader, rejoins moi !'),
(37, '{\"x\":-862.0740966796875,\"y\":-1225.4300537109376,\"z\":6.1647138595581}', 'Mon dealos préféré, tu aurais pas un peu de dobe pour moi ? Rejoins moi !'),
(38, '{\"x\":-770.1005859375,\"y\":-1068.8199462890626,\"z\":11.83907032012939}', 'Salut, je viens d\'avoir ton contact, rejoins moi !'),
(39, '{\"x\":-798.7150268554688,\"y\":372.9659118652344,\"z\":87.87606048583985}', 'J\'ai un paquet de fric pour toi, Rejoins moi !'),
(40, '{\"x\":-612.0228881835938,\"y\":333.997802734375,\"z\":85.1166763305664}', 'Tu as encore un peu de produit pour moi ? Rejoins moi !'),
(41, '{\"x\":-7.89298391342163,\"y\":-575.7495727539063,\"z\":37.74507904052734}', 'Tu est où ? J\'ai besoin de ta dobe, rejoins moi !'),
(42, '{\"x\":295.7923889160156,\"y\":-569.9384765625,\"z\":43.26082992553711}', 'Tu as encore du produit magique ? Rejoins moi, je sais que je peux compter sur toi !'),
(43, '{\"x\":382.614501953125,\"y\":-344.03131103515627,\"z\":46.81528091430664}', 'Mon dealos préféré, tu aurais pas un peu de dobe pour moi ? Rejoins moi !'),
(44, '{\"x\":274.8113098144531,\"y\":-326.7182922363281,\"z\":44.91986083984375}', 'Salut, je viens d\'avoir ton contact, rejoins moi !'),
(46, '{\"x\":-29.66706085205078,\"y\":-92.48367309570313,\"z\":57.25431060791015}', 'J\'ai envie de m\'évader, rejoins moi !'),
(47, '{\"x\":-359.9700012207031,\"y\":79.45751190185547,\"z\":63.18901824951172}', 'Tu as encore un peu de produit pour moi ? Rejoins moi !'),
(48, '{\"x\":-275.6081848144531,\"y\":201.5198974609375,\"z\":85.69867706298828}', 'Mon dealos préféré, tu aurais pas un peu de dobe pour moi ? Rejoins moi !'),
(49, '{\"x\":-448.37420654296877,\"y\":177.04269409179688,\"z\":75.20374298095703}', 'Salut, je viens d\'avoir ton contact, rejoins moi !');

-- --------------------------------------------------------

--
-- Structure de la table `fine_types`
--

CREATE TABLE `fine_types` (
  `id` int NOT NULL,
  `label` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `amount` int DEFAULT NULL,
  `category` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `fine_types`
--

INSERT INTO `fine_types` (`id`, `label`, `amount`, `category`) VALUES
(1, 'Usage abusif du klaxon', 50, 0),
(2, 'Franchir une ligne continue', 100, 0),
(3, 'Circulation à contresens', 150, 0),
(4, 'Demi-tour non autorisé', 250, 0),
(5, 'Circulation hors-route', 300, 0),
(6, 'Non-respect des distances de sécurité', 100, 0),
(7, 'Arrêt dangereux / interdit', 300, 0),
(8, 'Stationnement gênant / interdit', 300, 0),
(9, 'Non respect  de la priorité à droite', 200, 0),
(10, 'Non-respect à un véhicule prioritaire', 300, 0),
(11, 'Non-respect d\'un stop', 200, 0),
(12, 'Non-respect d\'un feu rouge', 400, 0),
(13, 'Dépassement dangereux', 500, 0),
(14, 'Véhicule non en état', 600, 0),
(15, 'Conduite sans permis', 2000, 0),
(16, 'Délit de fuite', 19680, 0),
(17, 'Excès de vitesse < 5 kmh', 2450, 0),
(18, 'Excès de vitesse 5-15 kmh', 4800, 0),
(19, 'Excès de vitesse 15-30 kmh', 8450, 0),
(20, 'Excès de vitesse > 30 kmh', 9980, 0),
(21, 'Entrave de la circulation', 2130, 1),
(22, 'Dégradation de la voie publique', 1300, 1),
(23, 'Trouble à l\'ordre publique', 1970, 1),
(24, 'Entrave opération de police', 15630, 1),
(25, 'Insulte envers / entre civils', 14300, 1),
(26, 'Outrage à agent de police', 19600, 1),
(27, 'Menace verbale ou intimidation evers civils', 9630, 1),
(28, 'Menace verbale ou intimidation envers policier', 8600, 1),
(29, 'Manifestation illégale', 4960, 1),
(30, 'Tentative de corruption', 17800, 1),
(31, 'Arme blanche sortie en ville', 21500, 2),
(32, 'Arme léthale sortie en ville', 27830, 2),
(33, 'Port d\'arme non autorisé (défaut de license)', 24600, 2),
(34, 'Port d\'arme illégal', 28900, 2),
(35, 'Pris en flag lockpick', 14600, 2),
(36, 'Vol de voiture', 13300, 2),
(37, 'Vente de drogue', 45600, 2),
(38, 'Fabriquation de drogue', 34650, 2),
(39, 'Possession de drogue', 39650, 2),
(40, 'Prise d\'ôtage civil', 75000, 2),
(41, 'Prise d\'ôtage agent de l\'état', 125000, 2),
(42, 'Braquage particulier', 86000, 2),
(43, 'Braquage magasin', 52000, 2),
(44, 'Braquage de banque', 136000, 2),
(45, 'Tir sur civil', 56300, 3),
(46, 'Tir sur agent de l\'état', 65300, 3),
(47, 'Tentative de meurtre sur civil', 65300, 3),
(48, 'Tentative de meurtre sur agent de l\'état', 72300, 3),
(49, 'Meurtre sur civil', 82300, 3),
(50, 'Meurte sur agent de l\'état', 102300, 3),
(51, 'Meurtre involontaire', 36000, 3),
(52, 'Escroquerie à l\'entreprise', 82360, 2),
(53, 'Vol de Vehicule Aeriens', 62220, 1),
(54, 'Default de permis Aeriens', 28920, 1),
(55, 'Default de permis de BATEAU', 22630, 1),
(56, 'Vol de Vehicule Aquatique', 42560, 1),
(57, 'Refus d\'obtempérer', 21300, 2),
(58, 'Usurpation d\'identité', 22300, 2),
(59, 'Complice du meurtre ', 35600, 2),
(60, 'Tentative de kidnapping', 36500, 2);

-- --------------------------------------------------------

--
-- Structure de la table `gangs`
--

CREATE TABLE `gangs` (
  `id` int NOT NULL,
  `gangname` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `posCoffre` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `KitArme` int DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `garage`
--

CREATE TABLE `garage` (
  `id` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `pos` varchar(255) NOT NULL,
  `SpawnPoint` varchar(255) NOT NULL,
  `DeletePoint` varchar(255) NOT NULL,
  `blip` int DEFAULT '0',
  `type` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

--
-- Déchargement des données de la table `garage`
--

INSERT INTO `garage` (`id`, `name`, `pos`, `SpawnPoint`, `DeletePoint`, `blip`, `type`) VALUES
(1, 'garage pc publique', '{\"x\":216.333649,\"y\":-810.221191,\"z\":30.71908950805664}\r\n', '{\"x\":227.3116912841797,\"y\":-803.3009643554688,\"z\":30.58198356628418}', '{\"x\":224.50521850585938,\"y\":-757.701171875,\"z\":30.82607269287109}', 1, 'car'),
(2, 'Garage Public', '{\"x\":-281.1623229980469,\"y\":-888.3617553710938,\"z\":31.31801033020019}', '{\"x\":-285.67706298828127,\"y\":-888.2235717773438,\"z\":31.08185195922851}', '{\"x\":-299.704345703125,\"y\":-884.7357788085938,\"z\":31.08185195922851}', 1, 'car'),
(3, 'Garage Public', '{\"x\":-722.2445678710938,\"y\":-912.8456420898438,\"z\":19.01392745971679}', '{\"x\":-722.7339477539063,\"y\":-912.9146118164063,\"z\":19.01392745971679}', '{\"x\":-728.7298583984375,\"y\":-909.7260131835938,\"z\":19.01388931274414}', 1, 'car'),
(4, 'Garage Public', '{\"x\":-1211.9598388671876,\"y\":-654.0685424804688,\"z\":25.90130805969238}', '{\"x\":-1214.73974609375,\"y\":-660.8720703125,\"z\":25.90131759643554}', '{\"x\":-1205.099609375,\"y\":-654.5797729492188,\"z\":25.90131568908691}', 1, 'car'),
(5, 'Garage Public', '{\"x\":-1986.127685546875,\"y\":-314.35418701171877,\"z\":48.10635375976562}', '{\"x\":-1989.98583984375,\"y\":-310.21746826171877,\"z\":48.10635375976562}', '{\"x\":-1997.25244140625,\"y\":-328.94683837890627,\"z\":48.10635375976562}', 1, 'car'),
(6, 'Garage Public', '{\"x\":-1686.698486328125,\"y\":26.69600486755371,\"z\":64.3938217163086}', '{\"x\":-1679.8631591796876,\"y\":28.82605934143066,\"z\":63.7923469543457}', '{\"x\":-1686.2559814453126,\"y\":38.10614776611328,\"z\":64.08543395996094}', 1, 'car'),
(7, 'Garage Public', '{\"x\":705.5806884765625,\"y\":596.56201171875,\"z\":128.91029357910157}', '{\"x\":704.4656982421875,\"y\":603.0009765625,\"z\":128.911376953125}', '{\"x\":712.3553466796875,\"y\":607.78564453125,\"z\":128.91136169433595}', 1, 'car'),
(8, 'Garage Public', '{\"x\":22.18633842468261,\"y\":-1103.6925048828126,\"z\":38.15179443359375}', '{\"x\":6.86266565322876,\"y\":-1099.4241943359376,\"z\":38.1562271118164}', '{\"x\":2.57470774650573,\"y\":-1095.1917724609376,\"z\":38.15629959106445}', 1, 'car'),
(9, 'Garage Public', '{\"x\":488.4778137207031,\"y\":-1307.55224609375,\"z\":29.26771354675293}', '{\"x\":494.5875549316406,\"y\":-1320.074951171875,\"z\":29.22133255004882}', '{\"x\":485.130126953125,\"y\":-1309.6558837890626,\"z\":29.24440193176269}', 1, 'car'),
(10, 'Garage Public', '{\"x\":1176.191162109375,\"y\":-1548.727783203125,\"z\":34.69927215576172}', '{\"x\":1179.7691650390626,\"y\":-1545.718994140625,\"z\":34.69251251220703}', '{\"x\":1184.068115234375,\"y\":-1546.580810546875,\"z\":34.69258880615234}', 1, 'car'),
(11, 'Garage Public', '{\"x\":275.7423400878906,\"y\":-344.983154296875,\"z\":45.17323303222656}', '{\"x\":274.38519287109377,\"y\":-338.01025390625,\"z\":44.9198989868164}', '{\"x\":282.3836975097656,\"y\":-341.5604553222656,\"z\":44.92012405395508}', 1, 'car'),
(12, 'Garage Public', '{\"x\":317.1949768066406,\"y\":2622.7568359375,\"z\":44.45741653442383}', '{\"x\":326.365478515625,\"y\":2623.51220703125,\"z\":44.49784088134765}', '{\"x\":337.03546142578127,\"y\":2619.00927734375,\"z\":44.49773788452148}', 1, 'car'),
(13, 'Garage Public', '{\"x\":1852.598876953125,\"y\":2585.040283203125,\"z\":45.6719970703125}', '{\"x\":1858.86865234375,\"y\":2584.735595703125,\"z\":45.6719970703125}', '{\"x\":1870.0810546875,\"y\":2587.84521484375,\"z\":45.67210006713867}', 1, 'car'),
(14, 'Garage Public', '{\"x\":-1134.834716796875,\"y\":2682.108154296875,\"z\":18.38982582092285}', '{\"x\":-1139.62158203125,\"y\":2676.166015625,\"z\":18.09388542175293}', '{\"x\":-1154.0048828125,\"y\":2675.304443359375,\"z\":18.09388160705566}', 1, 'car'),
(15, 'Garage Public', '{\"x\":1722.7640380859376,\"y\":6417.5302734375,\"z\":35.00059509277344}', '{\"x\":1718.3663330078126,\"y\":6419.1875,\"z\":33.42395401000976}', '{\"x\":1721.93310546875,\"y\":6427.865234375,\"z\":33.41590881347656}', 1, 'car'),
(16, 'Garage Public', '{\"x\":110.47647857666016,\"y\":6598.7666015625,\"z\":32.10720062255859}', '{\"x\":126.37586212158203,\"y\":6604.78173828125,\"z\":31.88282585144043}', '{\"x\":117.3412857055664,\"y\":6600.2021484375,\"z\":32.00531387329101}', 1, 'car'),
(17, 'Garage Public', '{\"x\":-233.4212188720703,\"y\":6200.03466796875,\"z\":31.9178409576416}', '{\"x\":-232.95692443847657,\"y\":6187.951171875,\"z\":31.48968696594238}', '{\"x\":-228.725830078125,\"y\":6197.7685546875,\"z\":31.48960304260254}', 1, 'car'),
(18, 'ds', '{\"x\":-424.2881774902344,\"y\":-41.47130584716797,\"z\":46.22497940063476}', '{\"x\":-425.0215148925781,\"y\":-42.14482116699219,\"z\":46.22695159912109}', '{\"x\":-425.0226135253906,\"y\":-42.14488220214844,\"z\":46.22690200805664}', 1, 'car'),
(19, 'Garage Public', '{\"x\":-281.158447265625,\"y\":-888.1629028320313,\"z\":31.31801033020019}', '{\"x\":-302.2349853515625,\"y\":-890.9591064453125,\"z\":31.08460807800293}', '{\"x\":-296.4377136230469,\"y\":-886.040283203125,\"z\":31.08461189270019}', 1, 'car'),
(20, 'Garage Public', '{\"x\":-721.27294921875,\"y\":-911.9166259765625,\"z\":19.01392936706543}', '{\"x\":-728.5021362304688,\"y\":-913.8211059570313,\"z\":19.01390647888183}', '{\"x\":-723.8494873046875,\"y\":-913.3230590820313,\"z\":19.01392555236816}', 1, 'car'),
(21, 'Garage Public', '{\"x\":-1211.911865234375,\"y\":-653.9109497070313,\"z\":25.90130805969238}', '{\"x\":-1214.0694580078126,\"y\":-658.8226928710938,\"z\":25.90130805969238}', '{\"x\":-1204.9818115234376,\"y\":-654.1412353515625,\"z\":25.90129089355468}', 1, 'car'),
(22, 'Garage Public', '{\"x\":-1986.5367431640626,\"y\":-314.5129699707031,\"z\":48.10635757446289}', '{\"x\":-1995.64208984375,\"y\":-317.7180480957031,\"z\":48.10634231567383}', '{\"x\":-1995.553955078125,\"y\":-330.4078063964844,\"z\":48.10636138916015}', 1, 'car'),
(23, 'Garage Public', '{\"x\":-324.3150634765625,\"y\":-1495.2025146484376,\"z\":30.67813301086425}', '{\"x\":-328.39276123046877,\"y\":-1490.5909423828126,\"z\":30.59180831909179}', '{\"x\":-330.4584045410156,\"y\":-1494.892822265625,\"z\":30.66927719116211}', 1, 'car'),
(24, 'Garage Public', '{\"x\":485.3675537109375,\"y\":-1306.2911376953126,\"z\":29.2984390258789}', '{\"x\":495.62451171875,\"y\":-1327.60107421875,\"z\":29.33966064453125}', '{\"x\":485.7243957519531,\"y\":-1309.4208984375,\"z\":29.25799369812011}', 1, 'car'),
(25, 'Garage Public', '{\"x\":1176.0753173828126,\"y\":-1549.1376953125,\"z\":34.79170989990234}', '{\"x\":1178.9451904296876,\"y\":-1540.6419677734376,\"z\":34.69258499145508}', '{\"x\":1184.240966796875,\"y\":-1545.2908935546876,\"z\":34.69258880615234}', 1, 'car'),
(26, 'Garage Public', '{\"x\":275.4795837402344,\"y\":-345.03271484375,\"z\":45.17339706420898}', '{\"x\":273.7806396484375,\"y\":-337.9766540527344,\"z\":44.91989135742187}', '{\"x\":290.4608154296875,\"y\":-338.0513916015625,\"z\":44.96252822875976}', 1, 'car'),
(27, 'Garage Public', '{\"x\":10.67648124694824,\"y\":-1052.0390625,\"z\":38.15171813964844}', '{\"x\":-1.42093360424041,\"y\":-1057.118896484375,\"z\":38.1562271118164}', '{\"x\":6.24046039581298,\"y\":-1062.4544677734376,\"z\":38.15629577636719}', 1, 'car'),
(28, 'Garage Public', '{\"x\":705.2754516601563,\"y\":597.3126220703125,\"z\":128.91067504882813}', '{\"x\":703.7396240234375,\"y\":605.3439331054688,\"z\":128.91134643554688}', '{\"x\":712.9791259765625,\"y\":607.7305908203125,\"z\":128.91139221191407}', 1, 'car'),
(29, 'Garage Public', '{\"x\":8.64642906188964,\"y\":-1055.22412109375,\"z\":38.15623092651367}', '{\"x\":-1.38369023799896,\"y\":-1050.063232421875,\"z\":38.15630340576172}', '{\"x\":5.70096015930175,\"y\":-1059.3992919921876,\"z\":38.1562271118164}', 1, 'car'),
(30, 'Garage', '{\"x\":10.80689907073974,\"y\":-1057.9365234375,\"z\":38.19691467285156}', '{\"x\":11.07605171203613,\"y\":-1060.17822265625,\"z\":38.33560943603515}', '{\"x\":14.03607559204101,\"y\":-1062.199462890625,\"z\":38.28231048583984}', 1, 'car'),
(31, 'Garage Public', '{\"x\":275.3267517089844,\"y\":-344.7299499511719,\"z\":45.17338562011719}', '{\"x\":273.1506652832031,\"y\":-335.0951232910156,\"z\":44.91989517211914}', '{\"x\":284.6639099121094,\"y\":-335.7740173339844,\"z\":44.92549896240234}', 1, 'car'),
(32, 'Garage Public', '{\"x\":-720.7835083007813,\"y\":-911.5565185546875,\"z\":19.02391624450683}', '{\"x\":-728.2463989257813,\"y\":-920.1041870117188,\"z\":19.01397323608398}', '{\"x\":-723.0249633789063,\"y\":-913.4775390625,\"z\":19.01392364501953}', 1, 'car'),
(33, 'Garage Public', '{\"x\":-281.2746887207031,\"y\":-887.9520874023438,\"z\":31.31801223754882}', '{\"x\":-297.0946960449219,\"y\":-892.4932250976563,\"z\":31.08457946777343}', '{\"x\":-293.4033508300781,\"y\":-886.0674438476563,\"z\":31.08460617065429}', 1, 'car'),
(34, 'Garage', '{\"x\":-1211.893310546875,\"y\":-654.0592041015625,\"z\":25.90130615234375}', '{\"x\":-1212.609375,\"y\":-660.5636596679688,\"z\":25.90130424499511}', '{\"x\":-1204.9375,\"y\":-654.587646484375,\"z\":25.90130996704101}', 1, 'car'),
(35, 'Garage', '{\"x\":275.6184997558594,\"y\":-345.0784606933594,\"z\":45.17338562011719}', '{\"x\":273.14471435546877,\"y\":-337.1061096191406,\"z\":44.91989517211914}', '{\"x\":277.7748107910156,\"y\":-336.4835205078125,\"z\":44.92933654785156}', 0, 'car'),
(36, 'Garage', '{\"x\":275.6184997558594,\"y\":-345.0784606933594,\"z\":45.17338562011719}', '{\"x\":273.14471435546877,\"y\":-337.1061096191406,\"z\":44.91989517211914}', '{\"x\":277.7748107910156,\"y\":-336.4835205078125,\"z\":44.92933654785156}', 1, 'car'),
(37, 'Garage', '{\"x\":-1212.0572509765626,\"y\":-653.88720703125,\"z\":25.90130615234375}', '{\"x\":-1214.2735595703126,\"y\":-660.1107177734375,\"z\":25.90131187438965}', '{\"x\":-1204.6539306640626,\"y\":-654.27685546875,\"z\":25.90130996704101}', 0, 'car'),
(38, 'Garage', '{\"x\":-1212.0572509765626,\"y\":-653.88720703125,\"z\":25.90130615234375}', '{\"x\":-1214.2735595703126,\"y\":-660.1107177734375,\"z\":25.90131187438965}', '{\"x\":-1204.6539306640626,\"y\":-654.27685546875,\"z\":25.90130996704101}', 1, 'car'),
(39, 'Garage Public', '{\"x\":275.7415466308594,\"y\":-344.6416015625,\"z\":45.17338943481445}', '{\"x\":270.8525390625,\"y\":-344.61749267578127,\"z\":44.91987228393555}', '{\"x\":276.75701904296877,\"y\":-340.50543212890627,\"z\":44.91989517211914}', 1, 'car'),
(40, 'Garage', '{\"x\":-8.32333469390869,\"y\":-1051.181640625,\"z\":38.15629196166992}', '{\"x\":-2.09699440002441,\"y\":-1055.559814453125,\"z\":38.15629196166992}', '{\"x\":-8.80652427673339,\"y\":-1053.7509765625,\"z\":38.15629196166992}', 1, 'car'),
(41, 'garage', '{\"x\":-1211.8839111328126,\"y\":-654.0714721679688,\"z\":25.90127563476562}', '{\"x\":-1212.7391357421876,\"y\":-661.5977783203125,\"z\":25.90130615234375}', '{\"x\":-1202.9556884765626,\"y\":-656.9345703125,\"z\":25.90131187438965}', 1, 'car'),
(42, 'garage', '{\"x\":-1986.256103515625,\"y\":-314.1958923339844,\"z\":48.10634994506836}', '{\"x\":-1993.3258056640626,\"y\":-320.36077880859377,\"z\":48.10634994506836}', '{\"x\":-1995.6678466796876,\"y\":-329.8697204589844,\"z\":48.10636138916015}', 1, 'car'),
(43, 'ga', '{\"x\":-1212.0206298828126,\"y\":-654.2402954101563,\"z\":25.90126419067382}', '{\"x\":-1211.8843994140626,\"y\":-662.1165771484375,\"z\":25.90131187438965}', '{\"x\":-1204.4163818359376,\"y\":-654.8096313476563,\"z\":25.90130233764648}', 1, 'car'),
(44, 'ds', '{\"x\":-2989.441162109375,\"y\":69.70613098144531,\"z\":11.6088171005249}', '{\"x\":-2989.58251953125,\"y\":80.74332427978516,\"z\":11.60851573944091}', '{\"x\":-2984.9775390625,\"y\":84.59327697753906,\"z\":11.5546064376831}', 1, 'car'),
(45, 'ds', '{\"x\":-2989.441162109375,\"y\":69.70613098144531,\"z\":11.6088171005249}', '{\"x\":-2989.58251953125,\"y\":80.74332427978516,\"z\":11.60851573944091}', '{\"x\":-2984.9775390625,\"y\":84.59327697753906,\"z\":11.5546064376831}', 1, 'car'),
(46, 'ds', '{\"x\":-2989.441162109375,\"y\":69.70613098144531,\"z\":11.6088171005249}', '{\"x\":-2989.58251953125,\"y\":80.74332427978516,\"z\":11.60851573944091}', '{\"x\":-2984.9775390625,\"y\":84.59327697753906,\"z\":11.5546064376831}', 1, 'car'),
(47, 'ADZ', '{\"x\":487.70159912109377,\"y\":-1310.7406005859376,\"z\":29.25969123840332}', '{\"x\":494.8143005371094,\"y\":-1330.61328125,\"z\":29.33870506286621}', '{\"x\":489.45819091796877,\"y\":-1309.2906494140626,\"z\":29.26336669921875}', 1, 'car'),
(48, 'QDS', '{\"x\":-980.0475463867188,\"y\":-1481.644775390625,\"z\":5.01036930084228}', '{\"x\":-977.8601684570313,\"y\":-1473.595458984375,\"z\":5.01916980743408}', '{\"x\":-981.6471557617188,\"y\":-1477.965087890625,\"z\":5.01319456100463}', 1, 'car'),
(49, 'GaqsdqaSZ', '{\"x\":713.1538696289063,\"y\":609.4894409179688,\"z\":128.9110565185547}', '{\"x\":709.7622680664063,\"y\":603.1895751953125,\"z\":128.911376953125}', '{\"x\":706.5435180664063,\"y\":610.923828125,\"z\":128.911376953125}', 1, 'car'),
(50, 'QSZD', '{\"x\":1854.544921875,\"y\":2624.268798828125,\"z\":45.67196655273437}', '{\"x\":1860.5068359375,\"y\":2600.2294921875,\"z\":45.67207336425781}', '{\"x\":1855.0133056640626,\"y\":2630.90673828125,\"z\":45.67207336425781}', 1, 'car'),
(52, 'GQSD', '{\"x\":-1134.6495361328126,\"y\":2682.7041015625,\"z\":18.46960258483886}', '{\"x\":-1155.224853515625,\"y\":2660.48046875,\"z\":18.09392166137695}', '{\"x\":-1141.5933837890626,\"y\":2680.125,\"z\":18.09388160705566}', 1, 'car'),
(53, 'sd', '{\"x\":1723.3546142578126,\"y\":6417.71044921875,\"z\":35.00066375732422}', '{\"x\":1719.0521240234376,\"y\":6420.271484375,\"z\":33.46787643432617}', '{\"x\":1720.651611328125,\"y\":6425.66357421875,\"z\":33.37966918945312}', 1, 'car'),
(54, 'sqd', '{\"x\":111.96714782714844,\"y\":6597.14453125,\"z\":32.13031768798828}', '{\"x\":119.1047134399414,\"y\":6599.2978515625,\"z\":32.01938247680664}', '{\"x\":121.26164245605469,\"y\":6594.5986328125,\"z\":32.03212356567383}', 1, 'car'),
(55, 'Test', '{\"x\":-567.723388671875,\"y\":337.8406982421875,\"z\":84.47013854980469}', '{\"x\":-561.0216674804688,\"y\":337.72271728515627,\"z\":84.41339111328125}', '{\"x\":-557.5020751953125,\"y\":337.3163146972656,\"z\":84.40624237060547}', 1, 'car'),
(56, 'Parking Rouge', '{\"x\":-359.2782287597656,\"y\":-689.1439819335938,\"z\":32.43617630004883}', '{\"x\":-329.7677001953125,\"y\":-700.8095703125,\"z\":32.91249465942383}', '{\"x\":-330.3623962402344,\"y\":-694.4468383789063,\"z\":32.95620346069336}', 1, 'car'),
(57, 'Casino Helico', '{\"x\":965.9915161132813,\"y\":42.02810287475586,\"z\":123.126708984375}', '{\"x\":965.8189086914063,\"y\":42.23862838745117,\"z\":123.1266860961914}', '{\"x\":965.8189086914063,\"y\":42.23862838745117,\"z\":123.1266860961914}', 0, 'aircraft'),
(59, 'barage', '{\"x\":1915.3787841796876,\"y\":582.7037963867188,\"z\":176.3673858642578}', '{\"x\":1908.9493408203126,\"y\":572.9859008789063,\"z\":175.82180786132813}', '{\"x\":1906.3446044921876,\"y\":565.2725219726563,\"z\":175.82180786132813}', 1, 'car'),
(61, 'Avion Paleto', '{\"x\":1758.372314453125,\"y\":3297.53564453125,\"z\":41.14773178100586}', '{\"x\":1749.0032958984376,\"y\":3267.734375,\"z\":41.24822235107422}', '{\"x\":1764.888427734375,\"y\":3268.42529296875,\"z\":41.40101623535156}', 1, 'aircraft'),
(63, 'Vagos', '{\"x\":336.7958679199219,\"y\":-2029.237548828125,\"z\":21.64860534667968}', '{\"x\":327.5935363769531,\"y\":-2034.8541259765626,\"z\":20.92280960083007}', '{\"x\":335.7603759765625,\"y\":-2039.5595703125,\"z\":21.14973068237304}', 0, 'car'),
(64, 'Bmf', '{\"x\":-1786.279541015625,\"y\":459.6932067871094,\"z\":128.30824279785157}', '{\"x\":-1792.8927001953126,\"y\":459.4860534667969,\"z\":128.2579345703125}', '{\"x\":-1783.71337890625,\"y\":463.8516540527344,\"z\":128.3078155517578}', 0, 'car'),
(65, 'Families', '{\"x\":-69.47804260253906,\"y\":-1408.720458984375,\"z\":29.38216018676757}', '{\"x\":-81.68330383300781,\"y\":-1411.2908935546876,\"z\":29.32081604003906}', '{\"x\":-80.06929016113281,\"y\":-1403.42919921875,\"z\":29.32172203063965}', 0, 'car'),
(66, 'cayo', '{\"x\":4519.830078125,\"y\":-4515.12060546875,\"z\":4.49329042434692}', '{\"x\":4513.33251953125,\"y\":-4517.9765625,\"z\":4.15400171279907}', '{\"x\":4502.64501953125,\"y\":-4537.15478515625,\"z\":4.1517276763916}', 1, 'car'),
(67, 'Ballas', '{\"x\":100.2291259765625,\"y\":-1958.8291015625,\"z\":20.79295349121093}', '{\"x\":104.98680877685547,\"y\":-1952.76171875,\"z\":20.60123634338379}', '{\"x\":115.0957260131836,\"y\":-1946.2481689453126,\"z\":20.59533500671386}', 0, 'car'),
(68, 'scarface_mansion', '{\"x\":-3274.708984375,\"y\":528.6134033203125,\"z\":12.26540184020996}', '{\"x\":-3280.62060546875,\"y\":528.25732421875,\"z\":12.26540184020996}', '{\"x\":-3277.423828125,\"y\":523.8026123046875,\"z\":12.26540184020996}', 0, 'car'),
(69, 'Garage Arménienne', '{\"x\":-128.4417266845703,\"y\":1009.5665283203125,\"z\":235.73220825195313}', '{\"x\":-123.23861694335938,\"y\":1001.3067626953125,\"z\":235.7322540283203}', '{\"x\":-115.29301452636719,\"y\":1005.409423828125,\"z\":235.76344299316407}', 0, 'car'),
(70, 'Cayo Villa', '{\"x\":4976.13525390625,\"y\":-5723.7080078125,\"z\":19.88018989562988}', '{\"x\":4976.19921875,\"y\":-5730.82763671875,\"z\":19.88018989562988}', '{\"x\":4971.75927734375,\"y\":-5739.05419921875,\"z\":19.88022232055664}', 0, 'car'),
(71, 'Garage Israélien', '{\"x\":379.5774230957031,\"y\":-11.43663501739502,\"z\":82.98738098144531}', '{\"x\":372.7960205078125,\"y\":-6.23082780838012,\"z\":82.99008178710938}', '{\"x\":370.73614501953127,\"y\":-15.14015388488769,\"z\":82.99065399169922}', 0, 'car'),
(73, 'blood', '{\"x\":-1560.7384033203126,\"y\":-381.3780517578125,\"z\":41.98134613037109}', '{\"x\":-1566.513916015625,\"y\":-389.47698974609377,\"z\":41.98134613037109}', '{\"x\":-1564.6627197265626,\"y\":-386.82720947265627,\"z\":41.98134613037109}', 0, 'car'),
(74, 'police', '{\"x\":58.91922378540039,\"y\":-377.0555114746094,\"z\":39.12662506103515}', '{\"x\":53.15455627441406,\"y\":-383.60736083984377,\"z\":39.12659454345703}', '{\"x\":54.13269424438476,\"y\":-379.9327392578125,\"z\":39.12664413452148}', 0, 'car'),
(75, 'police', '{\"x\":82.88471221923828,\"y\":-414.137451171875,\"z\":55.32618713378906}', '{\"x\":86.78742980957031,\"y\":-404.3686218261719,\"z\":55.32625579833984}', '{\"x\":86.78446197509766,\"y\":-404.3398742675781,\"z\":55.32625579833984}', 0, 'aircraft'),
(76, 'EMSALDORE', '{\"x\":-465.12567138671877,\"y\":-1019.5470581054688,\"z\":24.28877830505371}', '{\"x\":-456.93853759765627,\"y\":-1016.150634765625,\"z\":24.28875923156738}', '{\"x\":-456.67095947265627,\"y\":-1018.2870483398438,\"z\":24.28875923156738}', 0, 'car'),
(77, 'EMSALDOREHP', '{\"x\":-460.843994140625,\"y\":-1026.029296875,\"z\":38.2784538269043}', '{\"x\":-453.958251953125,\"y\":-1029.849853515625,\"z\":38.39682006835937}', '{\"x\":-453.9560546875,\"y\":-1029.849853515625,\"z\":38.39682006835937}', 0, 'aircraft'),
(80, 'null', '{\"x\":-1613.6466064453126,\"y\":-972.8616333007813,\"z\":13.01743984222412}', '{\"x\":-1613.451171875,\"y\":-972.5133056640625,\"z\":13.01743984222412}', '{\"x\":-1611.1690673828126,\"y\":-967.9315185546875,\"z\":13.01898002624511}', 1, 'car'),
(81, 'BCSO', '{\"x\":-460.2940979003906,\"y\":6028.3564453125,\"z\":31.48981094360351}', '{\"x\":-469.1943054199219,\"y\":6038.62353515625,\"z\":31.34040641784668}', '{\"x\":-472.3817443847656,\"y\":6035.435546875,\"z\":31.34040641784668}', 0, 'car'),
(82, 'cayo_villa_heli', '{\"x\":4897.9365234375,\"y\":-5739.0673828125,\"z\":26.35091590881347}', '{\"x\":4890.31005859375,\"y\":-5736.3984375,\"z\":26.35091590881347}', '{\"x\":4890.3017578125,\"y\":-5736.37646484375,\"z\":26.35091590881347}', 0, 'aircraft'),
(83, 'cahamas', '{\"x\":4932.03955078125,\"y\":-4889.18017578125,\"z\":3.85592436790466}', '{\"x\":4936.869140625,\"y\":-4891.76220703125,\"z\":3.84466814994812}', '{\"x\":4936.78125,\"y\":-4887.45751953125,\"z\":3.89478111267089}', 1, 'car'),
(84, 'police', '{\"x\":-1080.26513671875,\"y\":-832.0278930664063,\"z\":4.86836671829223}', '{\"x\":-1096.5081787109376,\"y\":-843.7421264648438,\"z\":4.87606191635131}', '{\"x\":-1096.07470703125,\"y\":-843.5022583007813,\"z\":4.87586736679077}', 0, 'car'),
(85, 'TestPolice', '{\"x\":-505.3570556640625,\"y\":-607.63720703125,\"z\":30.29792785644531}', '{\"x\":-516.548095703125,\"y\":-606.279052734375,\"z\":30.29812240600586}', '{\"x\":-513.1812133789063,\"y\":-596.0286254882813,\"z\":30.29811286926269}', 0, 'car');

-- --------------------------------------------------------

--
-- Structure de la table `gunfight_stats`
--

CREATE TABLE `gunfight_stats` (
  `id` int NOT NULL,
  `identifier` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `kills` int NOT NULL,
  `deaths` int NOT NULL,
  `ratio` float NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `gunfight_stats`
--

INSERT INTO `gunfight_stats` (`id`, `identifier`, `kills`, `deaths`, `ratio`, `name`) VALUES
(5, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 1, 32, 0, 'null');

-- --------------------------------------------------------

--
-- Structure de la table `illegal_laboratory`
--

CREATE TABLE `illegal_laboratory` (
  `id` int NOT NULL,
  `name` longtext COLLATE utf8mb4_general_ci,
  `type` longtext COLLATE utf8mb4_general_ci,
  `interior` longtext COLLATE utf8mb4_general_ci,
  `owner` longtext COLLATE utf8mb4_general_ci,
  `pos` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `illegal_laboratory`
--

INSERT INTO `illegal_laboratory` (`id`, `name`, `type`, `interior`, `owner`, `pos`) VALUES
(25, 'Weed By V', 'weed_laboratory', '[]', 'none', '{\"x\":967.6992797851563,\"y\":-1829.32275390625,\"z\":31.23728942871093}'),
(26, 'Meth By V', 'meth_laboratory', '[]', 'none', '{\"x\":-260.396484375,\"y\":-2657.380859375,\"z\":6.43123435974121}');

-- --------------------------------------------------------

--
-- Structure de la table `items`
--

CREATE TABLE `items` (
  `name` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `weight` float NOT NULL DEFAULT '1',
  `rare` tinyint(1) NOT NULL DEFAULT '0',
  `can_remove` tinyint(1) NOT NULL DEFAULT '1',
  `unique` int NOT NULL DEFAULT '0',
  `createAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `items`
--

INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`, `unique`, `createAt`) VALUES
('280burger_packaged', '280 Burger', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('2tomate', 'Tomate', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('3glace', 'Boule Glace', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('7up', '7up-Taste', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('7upfinale', '7up', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('BubbleTea', 'BubbleTea', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('CupCake', 'CupCake', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('acid-meth', 'Acide', 1.5, 0, 1, 0, '2025-04-13 18:35:27'),
('acier', 'Acier', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('acierrecolte', 'Acier', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('aciertraitement', 'Acier Traité', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('aciertraiter', 'Acier Traité', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('alcoolbrut', 'Alcool Brut', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('alcooldecontrebande', 'Alcool de Contrebande', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('ammo_pistol', 'Munitions Pistolet', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('ammo_rifle', 'Munitions Fusil', 0.12, 0, 1, 0, '2025-04-13 18:35:27'),
('ammo_shotgun', 'Munitions Pompe', 0.2, 0, 1, 0, '2025-04-13 18:35:27'),
('ammo_sniper', 'Munitions Sniper', 0.2, 0, 1, 0, '2025-04-13 18:35:27'),
('apple', 'Pomme', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('argent', 'Argent', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('armor', 'Kevlar Basic Noir', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('armor390', 'Kevlar Lourd Militaire', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('armor391', 'Kevlar Lourd Brun', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('armor392', 'Kevlar Lourd Noir', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('bag', 'Bag', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('bandage', 'Bandage', 0.2, 0, 1, 0, '2025-04-13 18:35:27'),
('bank_card', 'Carte Bancaire', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('bankcard', 'Carte d\'accès Banque', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('bankcard2', 'Carte d\'accès Banque', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('basenull', 'Base null', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('basic_cuff', 'Menottes Basique', 0.3, 0, 1, 0, '2025-04-13 18:35:27'),
('basic_key', 'Clefs de Menottes Basique', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('beef_cuit', 'Steack cuit', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('beer', 'Bière', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('blackphone', 'Boitier Darknet', 0, 0, 1, 0, '2025-04-13 18:35:27'),
('boeufdrussi', 'Boeuf', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('bois', 'Buche de Bois', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('boissoncola', 'Boisson Cola', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('boite_lettres', 'Carton de Lettres', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('boitepizza', 'Boite Pizza', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('boulesdetapioca', 'Boule de Tapioca', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('bread', 'Pain', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('bubble_tea', 'BubbleTea Tea', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('bubble_tea_bleu', 'BubbleTea Tea', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('bubble_tea_orange', 'Bubble Tea Orange', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('bubble_tea_violet', 'Bubble Tea Violet', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('bubbletea', 'Bubble Tea', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('bubbleteaargent', 'Bubble Tea Argent', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('bubbleteacitron', 'Bubble Tea Citron Vert', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('burger', 'Burger', 0.3, 0, 1, 0, '2025-04-13 18:35:27'),
('burger_burgershot', 'Burger de BurgerShot', 0.2, 0, 1, 0, '2025-04-13 18:35:27'),
('burgerdouble', 'Burger Double', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('cafe', 'Cafe', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('cagoule', 'Cagoule', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('caisse_afk_gold', 'Caisse AFK Gold', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('caisse_afk_legendaire', 'Caisse AFK Legendaire', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('caisse_arme', 'Caisse Arme', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('caisse_diamond', 'Caisse Légendaire', 0, 0, 1, 0, '2025-04-13 18:35:27'),
('caisse_fidelite', 'Caisse Fidéliter', 0, 0, 1, 0, '2025-04-13 18:35:27'),
('caisse_gold', 'Caisse Gold', 0, 0, 1, 0, '2025-04-13 18:35:27'),
('caisse_ruby', 'Caisse Ultime', 0, 0, 1, 0, '2025-04-13 18:35:27'),
('camera', 'Panel Caméra', 2, 0, 1, 0, '2025-04-13 18:35:27'),
('carokit', 'Kit carosserie', 3, 0, 1, 0, '2025-04-13 18:35:27'),
('carotool', 'Outils carosserie', 4, 0, 1, 0, '2025-04-13 18:35:27'),
('cayorecolte', 'Cayo', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('cayotraitement', 'Pochon de Cayo', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('ceinture_explosive', 'Ceinture Explosive', 5, 0, 1, 0, '2025-04-13 18:35:27'),
('champagne', 'Champagne', 0.4, 0, 1, 0, '2025-04-13 18:35:27'),
('champignonrecolte', 'Champignon', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('champignontraitement', 'Champignon Traité', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('chargeur', 'Chargeur', 0.8, 0, 1, 0, '2025-04-13 18:35:27'),
('cheese', 'Fromage', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('chest_100', 'Grand Coffre', 12, 0, 1, 0, '2025-04-13 18:35:27'),
('chest_25', 'Petit Coffre', 4, 0, 1, 0, '2025-04-13 18:35:27'),
('chest_50', 'Coffre Moyen', 7, 0, 1, 0, '2025-04-13 18:35:27'),
('chocolat', 'Chocolat', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('cigare', 'Cigare', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('cigarette', 'Cigarette', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('ciseaux', 'Ciseaux', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('classic_burger_burgershot', 'Classic Burger BurgerShot', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('classic_phone', 'Iphone Classic', -1, 0, 1, 0, '2025-04-13 18:35:27'),
('classicburger', 'Classic Burger', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('cleankit', 'Kit de nétoyage', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('coca', 'Coca-Cola', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('cocacola', 'Cola-Taste', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('cocafinale', 'Coca', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('cocafrais', 'Coca Frais', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('cocaine', 'Cocaine Pur', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('cocainerecolte', 'Cocaïne', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('cocainetraitement', 'Pochon de Cocaïne', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('cocavanille', 'Coca Cola Vanille', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('codeine', 'Codéine Pure', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('codeinetraitement', 'Codeine', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('coke_pooch', 'Pochon de Coke', 0.1, 0, 1, 0, '2025-05-01 18:10:32'),
('cola', 'Coca', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('composant_weapon', 'Composant d\'armes', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('cuivre', 'Cuivre', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('cuivreetamer', 'Cuivre étamé', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('defibrillateur', 'Défibrillateur', 2, 0, 1, 0, '2025-04-13 18:35:27'),
('delivery_tablet', 'Tablette de livraison', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('deo', 'Déodorant', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('dessertfraise', 'Dessert Fraise', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('dirt-weed', '1Kg Terre Minéraliser', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('doublecheese_packaged', 'Double Cheese', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('doublechesse_burgershot', 'Double Chesse BurgerShot', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('drill', 'Perceuse', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('drive', 'Permis de conduire', 0.2, 0, 1, 1, '2025-04-13 18:35:27'),
('eau', 'Eau Pure', 0.01, 0, 1, 0, '2025-04-13 18:35:27'),
('empty_pooch', 'Pochon Vide', 0.01, 0, 1, 0, '2025-04-13 18:35:27'),
('engrais-weed', 'Engrais', 3, 0, 1, 0, '2025-04-13 18:35:27'),
('fanta', 'Fanta', 1.4, 0, 1, 0, '2025-04-13 18:35:27'),
('femaleseed', 'Graine Femelle', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('fentanyl', 'Fentanyl', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('fentanyltraitement', 'Fentanyl Traité', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('firstaidkit', 'Trousse premier secours', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('fixkit', 'Kit réparation', 1.5, 0, 1, 0, '2025-04-13 18:35:27'),
('fixtool', 'Outils réparation', 2, 0, 1, 0, '2025-04-13 18:35:27'),
('fraises', 'Fraises', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('frites', 'Frites', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('fromage', 'Fromage', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('gauffredrusillas', 'Gauffre', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('gofast_tablet', 'Tablette GoFast', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('grand_cru', 'Grand cru', 0.2, 0, 1, 0, '2025-04-13 18:35:27'),
('grapperaisin', 'Grappe de raisin', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('hack_laptop', 'Ordinateur de Hack', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('handcuff', 'Serre câble ', 0.3, 0, 1, 0, '2025-04-13 18:35:27'),
('hazmat', 'Combinaison Hazmat', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('hotdog', 'Hot Dog', 0.3, 0, 1, 0, '2025-04-13 18:35:27'),
('ice', 'Glaçon', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('icetea', 'IceTea', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('id_card', 'ID Card', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('identity_card', 'Carte d\'identité', 0.1, 0, 1, 1, '2025-04-13 18:35:27'),
('jagerbomb', 'Jägermeister', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('jagercerbere', 'Jäger Cerbère', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('jetoncustom', 'Jeton Custom', 0, 0, 1, 0, '2025-04-13 18:35:27'),
('jewels', 'Bijou', 0.2, 0, 1, 0, '2025-04-13 18:35:27'),
('jumelles', 'Jumelles', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('jus_coca', 'Jus de coca', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('jus_raisin', 'Jus de raisin', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('jusfruit', 'Jus de fruits', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('ketamine', 'Ketamine', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('ketaminetraitement', 'Ketamine Traité', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('kevlar', 'Kevlar', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('lait', 'Lait', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('laptop', 'Laptop', -1, 0, 1, 0, '2025-04-13 18:35:27'),
('lettre', 'Lettre', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('levier', 'Levier', 2, 0, 1, 0, '2025-04-13 18:35:27'),
('lingotor', 'Lingot d\'or', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('lockpick', 'Pied de Biche', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('maleseed', 'Graine male', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('mdma', 'MDMA', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('mdmatraitement', 'MDMA Traite', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('medikit', 'Medikit', 2, 0, 1, 0, '2025-04-13 18:35:27'),
('menthe', 'Menthe', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('menu_classic_burgershot', 'Menu Classic Burgershot', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('metaux', 'Métaux', 2, 0, 1, 0, '2025-04-13 18:35:27'),
('meth_mixture', 'Mixture de Meth (Brute)', 1.5, 0, 1, 0, '2025-04-13 18:35:27'),
('meth_pooch', 'Pochon de Meth (1G)', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('methbrute', 'Plateau de Meth', 2, 0, 1, 0, '2025-04-13 18:35:27'),
('methrecolte', 'Méthamphétamine', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('methtraitement', 'Pochon de Méthamphétamine', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('mobilier', 'Mobilier', 5, 0, 1, 0, '2025-04-13 18:35:27'),
('nightvision', 'Casque de vision nocturne', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('opiumrecolte', 'Opium', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('opiumtraitement', 'Pochon d\'opium', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('oxygen_mask', 'Masque à Oxygène', 0.6, 0, 1, 0, '2025-04-13 18:35:27'),
('pack_of_frite', 'Packet de Frites', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('pain_legume_legume', 'Burger Végé', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('painburger', 'Pain Burger', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('papier', 'Papier', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('parachute', 'Parachute', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('patefraiche', 'Pate Fraiche', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('patesaumon_packaged', 'Pate au saumon', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('pelle', 'Pelle', 0.7, 0, 1, 0, '2025-04-13 18:35:27'),
('pepiteor', 'Pépite d\'or', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('pepperspray', 'Gazeuse', 1, 0, -1, 0, '2025-04-13 18:35:27'),
('pepsi', 'Pepsi', 0.2, 0, 1, 0, '2025-04-13 18:35:27'),
('pepsi2', 'Pepsi-Taste', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('pepsiingredient', 'Cola', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('permisconduire', 'Permis de Conduire', -1, 0, 1, 0, '2025-04-13 18:35:27'),
('phone', 'Téléphone', 0.3, 0, 1, 0, '2025-04-13 18:35:27'),
('phosphorus-meth', 'Phosphore rouge', 1.5, 0, 1, 0, '2025-04-13 18:35:27'),
('piluleoubli', 'GHB', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('pizzamargaritta_packaged', 'Pizza Margaritta', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('planche', 'Planche', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('plantpot', 'Pot de plante', 2, 0, 1, 0, '2025-04-13 18:35:27'),
('plastique', 'Plastique', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('plateau_meth_brute', 'Plateau Meth', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('pneu', 'Pneu', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('police_cuff', 'Menottes LSPD', 0.3, 0, 1, 0, '2025-04-13 18:35:27'),
('police_key', 'Clefs de Menottes LSPD', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('pomme', 'Pomme', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('pommedeterre', 'Pomme de terre', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('poster', 'Poster Personalisée', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('pot', 'Pot', 1.2, 0, 1, 0, '2025-04-13 18:35:27'),
('pseudoephedrine', 'Pseudoéphédrine', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('radiateur', 'Radiateur', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('radio', 'Radio', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('radiobox', 'Enceinte Portative', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('raisin', 'Raisin', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('redbull', 'Redbull', 0.3, 0, 1, 0, '2025-04-13 18:35:27'),
('repairkit', 'Repairkit', 2, 0, 1, 0, '2025-04-13 18:35:27'),
('rhum', 'Rhum', 1.5, 0, 1, 0, '2025-04-13 18:35:27'),
('ring', 'Ring', -1, 0, 1, 0, '2025-04-13 18:35:27'),
('rolex', 'Montre Rolex', 0, 0, 1, 0, '2025-04-13 18:35:27'),
('sacplein', 'Sac de Terre', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('sacvide', 'Sac Vide', 0.3, 0, 1, 0, '2025-04-13 18:35:27'),
('salade', 'Salade', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('salade1', 'Salade', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('saumon', 'Saumon', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('seauplein', 'Seau d\'eau', 0, 0, 1, 0, '2025-04-13 18:35:27'),
('sim', 'Carte Sim', 0, 0, 1, 0, '2025-04-13 18:35:27'),
('sim_card', 'Sim Card', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('soda', 'Soda', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('solvant-meth', 'Solvant', 1.5, 0, 1, 0, '2025-04-13 18:35:27'),
('spaghettibolo_packaged', 'Spaghetti Bolognaise', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('steak', 'Steak', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('sucre', 'Sucre', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('tabac', 'Tabac', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('tequila', 'Tequila', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('terresec', 'Sac de Terre Sec', 0, 0, 1, 0, '2025-04-13 18:35:27'),
('test', 'Test Recolte', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('testdrugs', 'Test Drugs', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('testdrugstraitement', 'testdrugetaiter', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('testfarm', 'testfarm', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('testfarm1', 'testfarm1', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('testfarm2', 'testfarm2', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('testraitement', 'Test Traité', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('testrestaurant', 'testrestaurant', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('testtraitement', 'Test Traité', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('the', 'The', 0.01, 0, 1, 0, '2025-04-13 18:35:27'),
('tomatedrusillas', 'Tomate', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('tomatemozza_packaged', 'Tomate Mozzarella', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('triplecheese_packaged', 'Triple Cheese', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('vanille', 'Vanille', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('vetement', 'Vêtement', 0, 0, 1, 0, '2025-04-13 18:35:27'),
('vin', 'Bouteille de vin', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('vodka', 'Vodka', 0.05, 0, 1, 0, '2025-04-13 18:35:27'),
('water', 'Bouteille d\'eau', 0.1, 0, 1, 0, '2025-04-13 18:35:27'),
('water-weed', '1L Eau Minéraliser', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('weapon', 'PPA', 0.2, 0, 1, 1, '2025-04-13 18:35:27'),
('weed_head', 'Tête de weed', 0.07, 0, 1, 0, '2025-04-13 18:35:27'),
('weed_plant', 'Plant de Weed', 3, 0, 1, 0, '2025-04-13 18:35:27'),
('weed_plant_dry', 'Plant de weed sèche', 2, 0, 1, 0, '2025-04-13 18:35:27'),
('weed_pooch', 'Pochon de weed (1g)', 0.01, 0, 1, 0, '2025-04-13 18:35:27'),
('weedrecolte', 'Weed', 1, 0, 1, 0, '2025-04-13 18:35:27'),
('weedscissors', 'Grand Ciseau', 0.6, 0, 1, 0, '2025-04-13 18:35:27'),
('weedtraitement', 'Pochon de Weed', 0.25, 0, 1, 0, '2025-04-13 18:35:27'),
('whisky', 'Whisky', 0.4, 0, 1, 0, '2025-04-13 18:35:27'),
('whiskycoca', 'Whisky-coca', 0.5, 0, 1, 0, '2025-04-13 18:35:27'),
('wood', 'Bois', 0.25, 0, 1, 0, '2025-12-13 00:22:44'),
('woodcutted', 'Bois coupé', 0.25, 0, 1, 0, '2025-12-13 00:22:44'),
('zetony', 'Jetons', -1, 0, 1, 0, '2025-04-13 18:35:27');

-- --------------------------------------------------------

--
-- Structure de la table `jobs`
--

CREATE TABLE `jobs` (
  `id` int NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `illegal` int DEFAULT '0',
  `whitelisted` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `jobs`
--

INSERT INTO `jobs` (`id`, `name`, `label`, `illegal`, `whitelisted`) VALUES
(24, 'bikeshop', 'Concessionnaire Moto', 0, 1),
(28, 'boatshop', 'Concessionnaire Bateaux', 0, 1),
(30, 'carshop', 'Concessionnaire Voitures', 0, 1),
(47, 'journalist', 'Weazel News', 0, 1),
(63, 'planeshop', 'Concessionnaire Avions', 0, 1),
(66, 'realestateagent', 'Agent immobilier', 0, 1),
(72, 'taxi', 'Taxi', 0, 1),
(76, 'unemployed2', 'Aucune', 0, 1),
(161, 'unemployed', 'Chomeur', 0, 0),
(162, 'bloods', 'Bloods', 1, 1),
(163, 'police', 'LSPD', 0, 1),
(164, 'burgershot', 'BurgerShot', 0, 1),
(165, 'unicorn', 'Unicorn', 0, 1),
(166, 'wingwangbar', 'Bar Wing Wang', 0, 1),
(167, 'stokemaster', 'Strokemaster', 0, 1),
(168, 'muffler', 'Mufflers Motors', 0, 1),
(169, 'testrestaurant', 'testrestaurant', 0, 1),
(170, 'emsnord', 'EMS - Nord', 0, 1),
(171, 'gouvernement', 'Gouvernement', 0, 0),
(172, 'ambulance', 'EMS', 0, 1),
(173, 'woodcutting', 'Wood Cutting', 0, 1),
(174, 'bennys', 'Benny\'s', 0, 1);

-- --------------------------------------------------------

--
-- Structure de la table `job_grades`
--

CREATE TABLE `job_grades` (
  `id` int NOT NULL,
  `job_name` varchar(50) COLLATE utf8mb4_bin DEFAULT NULL,
  `grade` int NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `salary` int NOT NULL DEFAULT '0',
  `mensuelpay` int NOT NULL DEFAULT '0',
  `skin_male` longtext COLLATE utf8mb4_bin NOT NULL,
  `skin_female` longtext COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `job_grades`
--

INSERT INTO `job_grades` (`id`, `job_name`, `grade`, `name`, `label`, `salary`, `mensuelpay`, `skin_male`, `skin_female`) VALUES
(14, 'taxi', 0, 'recrue', 'Recrue', 0, 0, '{}', '{}'),
(15, 'taxi', 1, 'novice', 'Novice', 0, 0, '{}', '{}'),
(16, 'taxi', 2, 'experimente', 'Experimente', 0, 0, '{}', '{}'),
(17, 'taxi', 3, 'uber', 'Uber', 0, 0, '{}', '{}'),
(18, 'taxi', 4, 'boss', 'Patron', 0, 0, '{}', '{}'),
(19, 'unemployed', 0, 'unemployed', 'RSA', 0, 0, '{}', '{}'),
(28, 'realestateagent', 0, 'location', 'Location', 0, 0, '{}', '{}'),
(29, 'realestateagent', 1, 'vendeur', 'Vendeur', 0, 0, '{}', '{}'),
(30, 'realestateagent', 2, 'gestion', 'Gestion', 0, 0, '{}', '{}'),
(31, 'realestateagent', 3, 'boss', 'Patron', 0, 0, '{}', '{}'),
(32, 'unemployed2', 0, 'unemployed2', 'Citoyen', 0, 0, '{}', '{}'),
(33, 'journalist', 0, 'stagiaire', 'Stagiaire', 0, 0, '{}', '{}'),
(34, 'journalist', 1, 'reporter', 'Reporter', 0, 0, '{}', '{}'),
(35, 'journalist', 2, 'investigator', 'Investigateur', 0, 0, '{}', '{}'),
(36, 'journalist', 3, 'boss', 'Directeur', 0, 0, '{}', '{}'),
(37, 'carshop', 0, 'novice', 'Novice', 0, 0, '{}', '{}'),
(38, 'carshop', 1, 'sergeant', 'Intermediaire', 0, 0, '{}', '{}'),
(39, 'carshop', 2, 'experienced', 'Experimente', 0, 0, '{}', '{}'),
(40, 'carshop', 3, 'boss', 'Patron', 0, 0, '{}', '{}'),
(231, 'bikeshop', 0, 'novice', 'Novice', 0, 0, '{}', '{}'),
(232, 'bikeshop', 1, 'sergeant', 'Intermediaire', 0, 0, '{}', '{}'),
(233, 'bikeshop', 2, 'experienced', 'Experimente', 0, 0, '{}', '{}'),
(234, 'bikeshop', 3, 'boss', 'Patron', 0, 0, '{}', '{}'),
(646, 'police', 6, 'boss', 'Chef', 10, 0, '{}', '{}'),
(647, 'police', 0, 'recruit', 'Recrue', 0, 0, '{}', '{}'),
(648, 'police', 5, 'intendent', 'Capitaine', 100, 0, '{}', '{}'),
(649, 'police', 4, 'lieutenant', 'Lieutenant', 0, 0, '{}', '{}'),
(650, 'police', 2, 'sergeant', 'Caporal', 0, 0, '{}', '{}'),
(651, 'police', 1, 'officer', 'Officier', 0, 0, '{}', '{}'),
(652, 'police', 3, 'chef', 'Sergent', 0, 0, '{}', '{}'),
(668, 'burgershot', 4, 'boss', 'Directeur', 0, 0, '{}', '{}'),
(669, 'burgershot', 3, 'chef-cuisine', 'Chef de Cuisine', 0, 0, '{}', '{}'),
(670, 'burgershot', 2, 'cuisine', 'Cuisinier', 0, 0, '{}', '{}'),
(671, 'burgershot', 0, 'stage', 'Stagiere', 0, 0, '{}', '{}'),
(672, 'burgershot', 1, 'employer', 'Employer', 0, 0, '{}', '{}'),
(685, 'stokemaster', 2, 'boss', 'PDG', 0, 0, '{}', '{}'),
(686, 'stokemaster', 1, 'responsable', 'Responsable', 0, 0, '{}', '{}'),
(687, 'stokemaster', 0, 'employer', 'Employer', 0, 0, '{}', '{}'),
(688, 'wingwangbar', 2, 'boss', 'PDG', 0, 0, '{}', '{}'),
(689, 'wingwangbar', 1, 'responsable', 'Responsable', 0, 0, '{}', '{}'),
(690, 'wingwangbar', 0, 'employer', 'Employer', 0, 0, '{}', '{}'),
(691, 'unicorn', 2, 'boss', 'PDG', 0, 0, '{}', '{}'),
(692, 'unicorn', 1, 'responsable', 'Responsable', 0, 0, '{}', '{}'),
(693, 'unicorn', 0, 'employer', 'Employer', 0, 0, '{}', '{}'),
(694, 'bloods', 1, 'membre', 'Membre', 0, 0, '{}', '{}'),
(695, 'bloods', 3, 'boss', 'Boss', 0, 0, '{}', '{}'),
(696, 'bloods', 2, 'gerant', 'Gérant', 0, 0, '{}', '{}'),
(697, 'bloods', 0, 'recrue', 'Recrue', 0, 0, '{}', '{}'),
(698, 'muffler', 2, 'boss', 'PDG', 0, 0, '{}', '{}'),
(699, 'muffler', 1, 'responsable', 'Responsable', 0, 0, '{}', '{}'),
(700, 'muffler', 0, 'employer', 'Employer', 0, 0, '{}', '{}'),
(701, 'testrestaurant', 0, 'stage', 'Stagiere', 0, 0, '{}', '{}'),
(702, 'testrestaurant', 1, 'employer', 'Employer', 0, 0, '{}', '{}'),
(703, 'testrestaurant', 4, 'boss', 'Directeur', 0, 0, '{}', '{}'),
(704, 'testrestaurant', 3, 'chef-cuisine', 'Chef de Cuisine', 0, 0, '{}', '{}'),
(705, 'testrestaurant', 2, 'cuisine', 'Cuisinier', 0, 0, '{}', '{}'),
(706, 'emsnord', 2, 'chief', 'Médecin-Chef', 0, 0, '{}', '{}'),
(707, 'emsnord', 1, 'doctor', 'Médecin', 0, 0, '{}', '{}'),
(708, 'emsnord', 0, 'ambulance', 'Ambulancier', 0, 0, '{}', '{}'),
(709, 'emsnord', 3, 'boss', 'Directeur', 0, 0, '{}', '{}'),
(710, 'gouvernement', 0, 'employe', 'Employé', 0, 0, '', ''),
(711, 'gouvernement', 1, 'garde', 'Garde du corp', 0, 0, '', ''),
(712, 'gouvernement', 2, 'secretaire', 'Secrétaire', 0, 0, '', ''),
(713, 'gouvernement', 3, 'ministre', 'Ministre', 0, 0, '', ''),
(714, 'gouvernement', 4, 'vicepresident', 'Vice-Président', 0, 0, '', ''),
(715, 'gouvernement', 5, 'boss', 'Président', 14, 1010, '', ''),
(716, 'ambulance', 3, 'boss', 'Directeur', 0, 0, '{}', '{}'),
(717, 'ambulance', 2, 'chief', 'Médecin-Chef', 0, 0, '{}', '{}'),
(718, 'ambulance', 1, 'doctor', 'Médecin', 0, 0, '{}', '{}'),
(719, 'ambulance', 0, 'ambulance', 'Ambulancier', 0, 0, '{}', '{}'),
(720, 'woodcutting', 2, 'boss', 'PDG', 0, 0, '{}', '{}'),
(721, 'woodcutting', 1, 'responsable', 'Responsable', 0, 0, '{}', '{}'),
(722, 'woodcutting', 0, 'employer', 'Employer', 0, 0, '{}', '{}'),
(723, 'bennys', 0, 'employer', 'Employer', 0, 0, '{}', '{}'),
(724, 'bennys', 2, 'boss', 'PDG', 0, 0, '{}', '{}'),
(725, 'bennys', 1, 'responsable', 'Responsable', 0, 0, '{}', '{}');

-- --------------------------------------------------------

--
-- Structure de la table `leboncoin`
--

CREATE TABLE `leboncoin` (
  `id` int DEFAULT NULL,
  `identifier` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `price` int DEFAULT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `label` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `count` int DEFAULT NULL,
  `type` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `vehicle` longtext COLLATE utf8mb4_general_ci,
  `plate` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `markers`
--

CREATE TABLE `markers` (
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `label` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `position` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `job` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `actionname` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `args1` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `args2` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `args3` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `args4` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `args5` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `blip` tinyint(1) DEFAULT '0',
  `blipname` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `blipsprit` int DEFAULT NULL,
  `blipcolor` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `markers`
--

INSERT INTO `markers` (`name`, `label`, `position`, `job`, `actionname`, `args1`, `args2`, `args3`, `args4`, `args5`, `blip`, `blipname`, `blipsprit`, `blipcolor`) VALUES
('Supp', 'supp', '{\"x\":-606.9451293945313,\"y\":-2199.66162109375,\"z\":5.99299907684326}', NULL, 'menultd', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Structure de la table `owned_properties`
--

CREATE TABLE `owned_properties` (
  `id` int NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_bin NOT NULL,
  `price` double NOT NULL,
  `rented` int NOT NULL,
  `owner` varchar(60) COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Structure de la table `owned_vehicles`
--

CREATE TABLE `owned_vehicles` (
  `owner` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `datetoremove` datetime DEFAULT NULL,
  `plate` varchar(12) COLLATE utf8mb4_bin NOT NULL,
  `label` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `model` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `vehicle` longtext COLLATE utf8mb4_bin NOT NULL,
  `coffre` text COLLATE utf8mb4_bin,
  `type` varchar(20) COLLATE utf8mb4_bin NOT NULL DEFAULT 'car',
  `state` tinyint(1) NOT NULL DEFAULT '0',
  `boutique` tinyint(1) NOT NULL DEFAULT '0',
  `garage` int NOT NULL DEFAULT '1',
  `glovebox` longtext COLLATE utf8mb4_bin,
  `trunk` longtext COLLATE utf8mb4_bin,
  `carseller` int DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Structure de la table `ox_doorlock`
--

CREATE TABLE `ox_doorlock` (
  `id` int UNSIGNED NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `data` longtext COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `ox_doorlock`
--

INSERT INTO `ox_doorlock` (`id`, `name`, `data`) VALUES
(3, 'police', '{\"maxDistance\":2,\"state\":1,\"heading\":218,\"model\":631614199,\"groups\":{\"police\":0},\"doors\":false,\"coords\":{\"x\":-1073.0653076171876,\"y\":-827.0891723632813,\"z\":5.63056373596191}}'),
(7, 'Test', '{\"groups\":{\"police\":0},\"maxDistance\":1,\"doors\":false,\"model\":452874391,\"state\":1,\"coords\":{\"x\":-1072.251708984375,\"y\":-823.23876953125,\"z\":9.92320156097412},\"heading\":217}'),
(8, 'Police', '{\"groups\":{\"police\":0},\"maxDistance\":3,\"doors\":false,\"model\":2065754417,\"state\":1,\"coords\":{\"x\":-1119.3819580078126,\"y\":-839.199462890625,\"z\":16.27415084838867},\"heading\":310,\"auto\":true}'),
(25, 'police', '{\"model\":-96679321,\"heading\":180,\"doors\":false,\"state\":1,\"maxDistance\":2,\"groups\":{\"police\":0},\"coords\":{\"x\":440.52008056640627,\"y\":-986.2334594726563,\"z\":30.82319259643554}}'),
(26, 'blood', '{\"model\":1641308239,\"coords\":{\"x\":-1558.910888671875,\"y\":-398.7169189453125,\"z\":42.29832077026367},\"state\":1,\"maxDistance\":2,\"doors\":false,\"passcode\":\"0894\",\"heading\":49}'),
(27, 'Cell 7', '{\"doors\":false,\"maxDistance\":2,\"heading\":250,\"model\":352245821,\"groups\":{\"police\":0},\"coords\":{\"x\":29.2170295715332,\"y\":-414.463134765625,\"z\":33.71266174316406},\"state\":1}'),
(28, 'Cell 6', '{\"doors\":false,\"maxDistance\":2,\"heading\":250,\"model\":352245821,\"groups\":{\"police\":0},\"coords\":{\"x\":31.20746231079101,\"y\":-408.98602294921877,\"z\":33.71266174316406},\"state\":1}'),
(29, 'Cell 5', '{\"doors\":false,\"maxDistance\":2,\"heading\":340,\"model\":352245821,\"groups\":{\"police\":0},\"coords\":{\"x\":30.84070968627929,\"y\":-403.0238952636719,\"z\":33.71266174316406},\"state\":1}'),
(30, 'Cell 4', '{\"doors\":false,\"maxDistance\":2,\"heading\":340,\"model\":352245821,\"groups\":{\"police\":0},\"coords\":{\"x\":25.63434982299804,\"y\":-401.13189697265627,\"z\":33.71266174316406},\"state\":1}'),
(31, 'Cell 3', '{\"doors\":false,\"maxDistance\":2,\"heading\":70,\"model\":352245821,\"coords\":{\"x\":19.02468109130859,\"y\":-402.1963195800781,\"z\":33.71197891235351},\"state\":0}'),
(32, 'Cell 2', '{\"doors\":false,\"maxDistance\":2,\"heading\":70,\"model\":352245821,\"groups\":{\"police\":0},\"coords\":{\"x\":17.03384017944336,\"y\":-407.6745910644531,\"z\":33.71197891235351},\"state\":1}'),
(33, 'Cell 1', '{\"doors\":false,\"maxDistance\":2,\"heading\":70,\"model\":352245821,\"groups\":{\"police\":0},\"coords\":{\"x\":15.14945983886718,\"y\":-412.85992431640627,\"z\":33.71197891235351},\"state\":1}'),
(34, 'Cell', '{\"doors\":false,\"maxDistance\":2,\"heading\":160,\"model\":352245821,\"groups\":{\"police\":0},\"coords\":{\"x\":18.04872131347656,\"y\":-420.2210388183594,\"z\":33.71197891235351},\"state\":1}'),
(35, 'Cell', '{\"doors\":false,\"maxDistance\":2,\"heading\":340,\"model\":352245821,\"groups\":{\"police\":0},\"coords\":{\"x\":24.26699066162109,\"y\":-422.37725830078127,\"z\":33.71197891235351},\"state\":1}'),
(36, 'Cell', '{\"doors\":false,\"maxDistance\":2,\"heading\":250,\"model\":690057750,\"groups\":{\"police\":0},\"coords\":{\"x\":29.50846099853515,\"y\":-419.7623291015625,\"z\":33.71136856079101},\"state\":1}'),
(37, 'LSPD Enter', '{\"doors\":false,\"maxDistance\":2,\"heading\":340,\"model\":817128356,\"groups\":{\"police\":0},\"coords\":{\"x\":40.71860122680664,\"y\":-434.7853088378906,\"z\":39.78453826904297},\"state\":1}'),
(42, 'vec3(-364.711060, -102.227928, 38.543480)', '{\"groups\":{\"lscustom\":0},\"coords\":{\"x\":-364.7110595703125,\"y\":-102.2279281616211,\"z\":38.54347991943359},\"maxDistance\":2,\"doors\":false,\"state\":1,\"heading\":160,\"model\":825452774}'),
(44, 'lscustom', '{\"groups\":{\"lscustom\":0},\"coords\":{\"x\":-351.7689208984375,\"y\":-148.6840057373047,\"z\":38.41513061523437},\"maxDistance\":2,\"doors\":false,\"state\":1,\"heading\":300,\"model\":213593528}'),
(45, 'Lscustom', '{\"groups\":{\"lscustom\":0},\"coords\":{\"x\":-349.8625793457031,\"y\":-151.9827880859375,\"z\":37.99273681640625},\"maxDistance\":2,\"doors\":false,\"state\":1,\"heading\":301,\"model\":-821497995}'),
(46, 'Instance', '{\"heading\":90,\"maxDistance\":0.1,\"hideUi\":true,\"groups\":{\"admin\":0},\"doors\":false,\"model\":-519068795,\"coords\":{\"x\":1066.655029296875,\"y\":-3184.08740234375,\"z\":-39.00739669799805},\"state\":1}'),
(47, 'Instance Coke', '{\"heading\":180,\"maxDistance\":0.1,\"hideUi\":true,\"groups\":{\"admin\":0},\"doors\":false,\"model\":-519068795,\"coords\":{\"x\":1089.3216552734376,\"y\":-3187.23291015625,\"z\":-38.84450531005859},\"state\":1}'),
(48, 'Instance Meth', '{\"heading\":270,\"maxDistance\":0.1,\"hideUi\":true,\"groups\":{\"admin\":0},\"doors\":false,\"model\":-519068795,\"coords\":{\"x\":996.6099853515625,\"y\":-3200.0419921875,\"z\":-36.16683197021484},\"state\":1}'),
(50, 'BCSO', '{\"groups\":{\"sheriff\":0},\"coords\":{\"x\":-437.8791198730469,\"y\":6013.654296875,\"z\":32.28851318359375},\"state\":1,\"maxDistance\":2,\"doors\":[{\"model\":965382714,\"coords\":{\"x\":-438.5865478515625,\"y\":6014.36181640625,\"z\":32.28851318359375},\"heading\":315},{\"model\":733214349,\"coords\":{\"x\":-437.17169189453127,\"y\":6012.947265625,\"z\":32.28851318359375},\"heading\":135}]}'),
(51, 'BCSO', '{\"groups\":{\"sheriff\":0},\"coords\":{\"x\":-454.1942138671875,\"y\":5997.3447265625,\"z\":32.28851318359375},\"state\":1,\"maxDistance\":2,\"doors\":[{\"model\":965382714,\"coords\":{\"x\":-453.48675537109377,\"y\":5996.63720703125,\"z\":32.28851318359375},\"heading\":135},{\"model\":733214349,\"coords\":{\"x\":-454.90167236328127,\"y\":5998.0517578125,\"z\":32.28851318359375},\"heading\":315}]}'),
(52, 'vec3(-450.717285, 6004.127930, 32.288513)', '{\"groups\":{\"sheriff\":0},\"coords\":{\"x\":-450.71728515625,\"y\":6004.1279296875,\"z\":32.28851318359375},\"state\":1,\"maxDistance\":2,\"doors\":[{\"model\":1857649811,\"coords\":{\"x\":-450.00982666015627,\"y\":6004.83544921875,\"z\":32.28851318359375},\"heading\":225},{\"model\":1362051455,\"coords\":{\"x\":-451.4247131347656,\"y\":6003.42041015625,\"z\":32.28851318359375},\"heading\":45}]}'),
(53, 'BCSO', '{\"groups\":{\"sheriff\":0},\"coords\":{\"x\":-443.6405029296875,\"y\":6006.97265625,\"z\":27.73100090026855},\"state\":1,\"heading\":315,\"maxDistance\":2,\"model\":-594854737,\"doors\":false}'),
(54, 'BCSO', '{\"groups\":{\"sheriff\":0},\"coords\":{\"x\":-442.24334716796877,\"y\":6012.61962890625,\"z\":27.73100090026855},\"state\":1,\"heading\":45,\"maxDistance\":2,\"model\":-594854737,\"doors\":false}'),
(55, 'BCSO', '{\"groups\":{\"sheriff\":0},\"coords\":{\"x\":-445.9456787109375,\"y\":6012.88037109375,\"z\":27.73100090026855},\"state\":1,\"heading\":135,\"maxDistance\":2,\"model\":-594854737,\"doors\":false}'),
(56, 'BCSO', '{\"groups\":{\"sheriff\":0},\"coords\":{\"x\":-448.9160461425781,\"y\":6015.85107421875,\"z\":27.73100090026855},\"state\":1,\"heading\":135,\"maxDistance\":2,\"model\":-594854737,\"doors\":false}'),
(57, 'BCSO', '{\"groups\":{\"sheriff\":0},\"coords\":{\"x\":-446.3604431152344,\"y\":6018.40673828125,\"z\":27.73100090026855},\"state\":1,\"heading\":135,\"maxDistance\":2,\"model\":-594854737,\"doors\":false}'),
(58, 'BCSO', '{\"groups\":{\"sheriff\":0},\"coords\":{\"x\":-443.39007568359377,\"y\":6015.43603515625,\"z\":27.73100090026855},\"state\":1,\"heading\":135,\"maxDistance\":2,\"model\":-594854737,\"doors\":false}'),
(59, 'BCSO', '{\"groups\":{\"sheriff\":0},\"coords\":{\"x\":-450.71728515625,\"y\":6004.1279296875,\"z\":27.58121490478515},\"state\":1,\"maxDistance\":2,\"doors\":[{\"model\":1362051455,\"coords\":{\"x\":-451.4247131347656,\"y\":6003.42041015625,\"z\":27.58121490478515},\"heading\":45},{\"model\":1857649811,\"coords\":{\"x\":-450.00982666015627,\"y\":6004.83544921875,\"z\":27.58121490478515},\"heading\":225}]}'),
(60, 'BCSO', '{\"groups\":{\"sheriff\":0},\"coords\":{\"x\":-450.71728515625,\"y\":6004.1279296875,\"z\":36.99581527709961},\"state\":1,\"maxDistance\":2,\"doors\":[{\"model\":1362051455,\"coords\":{\"x\":-451.4247131347656,\"y\":6003.42041015625,\"z\":36.99581527709961},\"heading\":45},{\"model\":1857649811,\"coords\":{\"x\":-450.00982666015627,\"y\":6004.83544921875,\"z\":36.99581527709961},\"heading\":225}]}'),
(61, 'Debug Porte', '{\"items\":[{\"name\":\"lockpick\"}],\"state\":1,\"doors\":[{\"heading\":170,\"coords\":{\"x\":-589.523681640625,\"y\":-1621.50146484375,\"z\":33.16101837158203},\"model\":812467272},{\"heading\":358,\"coords\":{\"x\":-590.8179931640625,\"y\":-1621.39501953125,\"z\":33.16170501708984},\"model\":812467272}],\"maxDistance\":2,\"coords\":{\"x\":-590.1708374023438,\"y\":-1621.4482421875,\"z\":33.16136169433594},\"lockpick\":true,\"lockSound\":\"metal_locker\",\"holdOpen\":true,\"unlockSound\":\"metal_locker\"}'),
(62, 'Debug', '{\"maxDistance\":2,\"heading\":299,\"coords\":{\"x\":-1002.146728515625,\"y\":-478.064208984375,\"z\":50.1166763305664},\"hideUi\":true,\"doors\":false,\"model\":-2030220382,\"state\":1}'),
(64, 'Cayo', '{\"coords\":{\"x\":5011.7490234375,\"y\":-5750.0712890625,\"z\":27.94474601745605},\"maxDistance\":2,\"doors\":false,\"holdOpen\":true,\"heading\":328,\"model\":-576022807,\"hideUi\":true,\"state\":0}'),
(65, 'unicorn_back', '{\"model\":401003935,\"doors\":false,\"state\":0,\"groups\":{\"unicorn\":0},\"maxDistance\":2,\"coords\":{\"x\":95.02094268798828,\"y\":-1285.5660400390626,\"z\":29.45546531677246},\"heading\":30}'),
(66, 'unicorn_main', '{\"model\":401003935,\"doors\":false,\"state\":1,\"groups\":{\"unicorn\":0},\"maxDistance\":2,\"coords\":{\"x\":127.99365234375,\"y\":-1298.55615234375,\"z\":29.41795921325683},\"heading\":30}'),
(67, 'unicorn_main_window', '{\"model\":-884268790,\"doors\":false,\"state\":1,\"groups\":{\"unicorn\":0},\"maxDistance\":2,\"coords\":{\"x\":125.1080322265625,\"y\":-1299.6849365234376,\"z\":29.482027053833},\"heading\":120}'),
(68, 'unicorn_main_window2', '{\"model\":-884268790,\"doors\":false,\"state\":1,\"groups\":{\"unicorn\":0},\"maxDistance\":2,\"coords\":{\"x\":122.09468078613281,\"y\":-1301.33203125,\"z\":29.50324058532715},\"heading\":120}'),
(69, 'unicorn_main2', '{\"model\":488457389,\"doors\":false,\"state\":1,\"groups\":{\"unicorn\":0},\"maxDistance\":2,\"coords\":{\"x\":116.80904388427735,\"y\":-1305.312255859375,\"z\":29.48757362365722},\"heading\":30}'),
(70, 'unicorn_boss', '{\"model\":401003935,\"doors\":false,\"state\":1,\"groups\":{\"unicorn\":2},\"maxDistance\":2,\"coords\":{\"x\":99.99822998046875,\"y\":-1296.19287109375,\"z\":29.4870319366455},\"heading\":120}'),
(71, 'unicorn_inside', '{\"model\":401003935,\"doors\":false,\"state\":1,\"groups\":{\"unicorn\":0},\"maxDistance\":2,\"coords\":{\"x\":100.87702941894531,\"y\":-1305.7593994140626,\"z\":21.26690101623535},\"heading\":30}'),
(72, 'unicorn_inside2', '{\"model\":401003935,\"doors\":false,\"state\":1,\"groups\":{\"unicorn\":0},\"maxDistance\":2,\"coords\":{\"x\":120.36138153076172,\"y\":-1294.495361328125,\"z\":21.28731727600097},\"heading\":30}'),
(73, 'unicorn_inside3', '{\"model\":401003935,\"doors\":false,\"state\":1,\"groups\":{\"unicorn\":0},\"maxDistance\":2,\"coords\":{\"x\":108.60093688964844,\"y\":-1272.70556640625,\"z\":21.27283477783203},\"heading\":30}'),
(74, 'unicorn_inside4', '{\"model\":401003935,\"doors\":false,\"state\":1,\"groups\":{\"unicorn\":0},\"maxDistance\":2,\"coords\":{\"x\":88.85199737548828,\"y\":-1284.089111328125,\"z\":21.27283477783203},\"heading\":210}'),
(75, 'ipllabo', '{\"model\":1427451548,\"state\":1,\"doors\":false,\"maxDistance\":2,\"hideUi\":true,\"heading\":270,\"coords\":{\"x\":-323.8175964355469,\"y\":-1356.84130859375,\"z\":31.65889930725097}}');

-- --------------------------------------------------------

--
-- Structure de la table `playerstattoos`
--

CREATE TABLE `playerstattoos` (
  `identifier` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `tattoos` longtext COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `playerstattoos`
--

INSERT INTO `playerstattoos` (`identifier`, `tattoos`) VALUES
('license:afaba2ad9bca10e18363adece691fdecbcababee', '[{\"name\":-504012739,\"cat\":-975527441}]'),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '[{\"cat\":-2086773,\"name\":-1953737187}]');

-- --------------------------------------------------------

--
-- Structure de la table `playtime`
--

CREATE TABLE `playtime` (
  `identifier` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `time` int NOT NULL DEFAULT '0',
  `login` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

--
-- Déchargement des données de la table `playtime`
--

INSERT INTO `playtime` (`identifier`, `time`, `login`) VALUES
('license:20c2c2a5b8a06e599de1a6d6213fe46c918461cb', 1319, 9),
('license:f650fef0df402e482db8c3714c506cc54c31b788', 600, 1);

-- --------------------------------------------------------

--
-- Structure de la table `properties_list`
--

CREATE TABLE `properties_list` (
  `id` int NOT NULL,
  `name` text COLLATE utf8mb4_general_ci,
  `info` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `price` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `isBuy` varchar(255) COLLATE utf8mb4_general_ci DEFAULT '0',
  `owner` text COLLATE utf8mb4_general_ci,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `parms` longtext COLLATE utf8mb4_general_ci,
  `immeuble` varchar(50) COLLATE utf8mb4_general_ci DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `properties_list`
--

INSERT INTO `properties_list` (`id`, `name`, `info`, `price`, `coords`, `isBuy`, `owner`, `data`, `parms`, `immeuble`) VALUES
(75400367, 'Middle75400367', '{\"label\":\"Opium Nights-75400367\",\"poids\":300,\"name\":\"Middle75400367\"}', '90000', '{\"COFFRE\":{\"x\":-623.0919189453125,\"y\":54.69309997558594,\"z\":96.59940338134766},\"ENTER\":{\"x\":-603.2899780273438,\"y\":59.7400016784668,\"z\":98.19999694824219},\"EXIT\":{\"x\":-736.7745971679688,\"y\":-2275.5419921875,\"z\":13.43743991851806}}', '1', 'bloods', '{\"item\":[],\"weapons\":[],\"accounts\":{\"cash\":0,\"dirtycash\":0}}', '{\"GradesAlloweds\":{\"Membre\":true,\"Recrue\":true,\"Gérant\":true,\"Boss\":true},\"PeopleAlloweds\":[]}', '7'),
(85430296, 'High85430296', '{\"label\":\"Maze Bank-85430296\",\"poids\":400,\"name\":\"High85430296\"}', '350000', '{\"ENTER\":{\"x\":-1451.3499755859376,\"y\":-523.6900024414063,\"z\":56.91999816894531},\"COFFRE\":{\"x\":-1456.83740234375,\"y\":-531.0899047851563,\"z\":55.9369010925293},\"EXIT\":{\"x\":-66.08767700195313,\"y\":-801.2213745117188,\"z\":44.22727966308594}}', '1', 'bloods', '{\"item\":[],\"accounts\":{\"dirtycash\":0,\"cash\":0},\"weapons\":[]}', '{\"PeopleAlloweds\":[],\"GradesAlloweds\":{\"Boss\":true,\"Membre\":true,\"Recrue\":true,\"Gérant\":true}}', '5'),
(99287501, 'stockage', '{\"name\":\"stockage\",\"label\":\"Stockage\",\"poids\":7500}', '100000', '{\"EXIT\":{\"x\":-102.9677963256836,\"y\":397.5170593261719,\"z\":112.43569946289063},\"COFFRE\":{\"x\":1103.033935546875,\"y\":-3101.6630859375,\"z\":-39.9990005493164},\"ENTER\":{\"x\":1088.183349609375,\"y\":-3099.354736328125,\"z\":-38.99990081787109}}', '0', NULL, NULL, NULL, '0');

-- --------------------------------------------------------

--
-- Structure de la table `race_tracks`
--

CREATE TABLE `race_tracks` (
  `id` int NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `checkpoints` text COLLATE utf8mb4_general_ci,
  `records` text COLLATE utf8mb4_general_ci,
  `creator` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `distance` int DEFAULT NULL,
  `raceid` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `sanction_list`
--

CREATE TABLE `sanction_list` (
  `target_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `staff_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `target_name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `type` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `raison` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `time` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `date` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `id` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `sanction_list`
--

INSERT INTO `sanction_list` (`target_id`, `staff_name`, `target_name`, `type`, `raison`, `time`, `date`, `id`) VALUES
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 30 secondes', '', '04/02/2024 | 14:02:54', 1),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 60 secondes', '', '04/02/2024 | 14:07:45', 2),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'null', 'Inconnu', 'JAIL', 'test pour 60 secondes', '', '04/02/2024 | 14:08:16', 3),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 40 secondes', '', '04/02/2024 | 23:29:47', 4),
('license:063e3a07b7e5204a49b87053d2fd572a89659886', 'null', 'Inconnu', 'JAIL', 'Prc pour 999 secondes', '', '04/02/2024 | 23:51:54', 5),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'WARN', 'test', '', '13/02/2024 | 00:06:59', 6),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 10 secondes', '', '11/04/2024 | 14:02:52', 7),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 100 secondes', '', '13/04/2024 | 17:19:03', 8),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 100 secondes', '', '13/04/2024 | 17:23:46', 9),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 100 secondes', '', '13/04/2024 | 17:30:56', 10),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 10 secondes', '', '13/04/2024 | 17:52:32', 11),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 10 secondes', '', '14/04/2024 | 01:11:29', 12),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 19 secondes', '', '18/04/2024 | 19:23:29', 13),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'hrp pour 1000 secondes', '', '20/04/2024 | 19:46:38', 14),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 100 secondes', '', '23/04/2024 | 21:14:23', 15),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 100 secondes', '', '23/04/2024 | 21:16:10', 16),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Sayko pour 1000 secondes', '', '24/04/2024 | 21:37:28', 17),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Sayko pour 1000 secondes', '', '24/04/2024 | 21:40:47', 18),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Sayko pour 1000 secondes', '', '24/04/2024 | 21:42:07', 19),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Sayko pour 1000 secondes', '', '24/04/2024 | 21:43:08', 20),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Sayko pour 50 secondes', '', '24/04/2024 | 21:44:13', 21),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Sayko pour 50 secondes', '', '24/04/2024 | 21:47:03', 22),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Sayko pour 50 secondes', '', '24/04/2024 | 21:47:37', 23),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Sayko pour 50 secondes', '', '24/04/2024 | 21:48:10', 24),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'null', 'Inconnu', 'JAIL', 'Vdev pour 1000 secondes', '', '29/04/2024 | 21:53:52', 25),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'null', 'CFQ', 'JAIL', 'Test pour 100 secondes', '', '29/04/2024 | 22:11:22', 26),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'null', 'CFQ', 'JAIL', 'Test pour 100 secondes', '', '29/04/2024 | 22:11:57', 27),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', '10 pour 10 secondes', '', '29/04/2024 | 22:29:35', 28),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', '10 pour 10 secondes', '', '29/04/2024 | 22:30:22', 29),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', '10 pour 10 secondes', '', '29/04/2024 | 22:42:26', 30),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', '1000 pour 100 secondes', '', '29/04/2024 | 22:44:15', 31),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 10 secondes', '', '29/04/2024 | 22:47:00', 32),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 10 secondes', '', '29/04/2024 | 22:48:36', 33),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'null', 'CFQ', 'JAIL', 'test pour 10 secondes', '', '29/04/2024 | 22:48:58', 34),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 10 secondes', '', '29/04/2024 | 22:50:43', 35),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 10 secondes', '', '29/04/2024 | 22:50:56', 36),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '(BCSO 36) null', '(BCSO 36) null', 'JAIL', 'test pour 100 secondes', '', '01/05/2024 | 01:10:15', 37),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', '(BCSO 36) null', 'CFQ', 'JAIL', 'test pour 100 secondes', '', '01/05/2024 | 01:10:43', 38),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '(BCSO 36) null', '(BCSO 36) null', 'JAIL', 'test pour 199 secondes', '', '04/05/2024 | 19:59:37', 39),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '(BCSO 36) null', '(BCSO 36) null', 'BAN', 'test pour -1jours', '', '05/05/2024 | 18:01:38', 40),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '(BCSO 36) null', '(BCSO 36) null', 'BAN', 'test pour -1jours', '', '05/05/2024 | 18:01:59', 41),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '(BCSO 36) null', '(BCSO 36) null', 'JAIL', 'test pour 100 secondes', '', '05/05/2024 | 18:54:13', 42),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '(BCSO 36) null', '(BCSO 36) null', 'BAN', 'test pour 100jours', '', '05/05/2024 | 18:54:55', 43),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '(BCSO 36) null', '(BCSO 36) null', 'BAN', 'test pour 100jours', '', '05/05/2024 | 18:58:32', 44),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '(BCSO 36) null', '(BCSO 36) null', 'JAIL', 'test pour 100 secondes', '', '06/05/2024 | 14:50:29', 45),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '(BCSO 36) null', '(BCSO 36) null', 'JAIL', 'Test pour 100 secondes', '', '06/05/2024 | 14:52:40', 46),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '(BCSO 36) null', '(BCSO 36) null', 'JAIL', 'test pour 100 secondes', '', '06/05/2024 | 14:53:52', 47),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', '(BCSO 36) null', 'CFQ', 'JAIL', 'test pour 100 secondes', '', '06/05/2024 | 15:01:46', 48),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', '(BCSO 36) null', 'CFQ', 'JAIL', 'Test pour 100 secondes', '', '06/05/2024 | 15:08:02', 49),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'Console', 'CFQ', 'JAIL', 'test pour 100 secondes', '', '06/05/2024 | 15:19:59', 50),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'Console', 'CFQ', 'JAIL', 'test pour 100 secondes', '', '06/05/2024 | 15:21:24', 51),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', '(BCSO 36) null', 'CFQ', 'JAIL', 'Test pour 100 secondes', '', '06/05/2024 | 15:23:33', 52),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', '(BCSO 36) null', 'CFQ', 'JAIL', 'test pour 100 secondes', '', '06/05/2024 | 15:23:58', 53),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '(BCSO 36) null', '(BCSO 36) null', 'JAIL', 'test pour 100 secondes', '', '06/05/2024 | 15:24:05', 54),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Test pour 6000 secondes', '', '14/05/2024 | 19:15:58', 55),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 600 secondes', '', '14/05/2024 | 19:21:24', 56),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 600 secondes', '', '14/05/2024 | 19:23:59', 57),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 7200 secondes', '', '14/05/2024 | 19:24:04', 58),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 7200 secondes', '', '14/05/2024 | 19:25:06', 59),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 7200 secondes', '', '14/05/2024 | 19:26:35', 60),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 120000 secondes', '', '14/05/2024 | 19:26:51', 61),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour -60 secondes', '', '14/05/2024 | 19:27:02', 62),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour -60 secondes', '', '14/05/2024 | 19:29:30', 63),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 60 secondes', '', '14/05/2024 | 19:29:39', 64),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour -60 secondes', '', '14/05/2024 | 19:32:12', 65),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour -60 secondes', '', '14/05/2024 | 19:32:59', 66),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour -60 secondes', '', '14/05/2024 | 19:34:13', 67),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour -60 secondes', '', '14/05/2024 | 19:34:42', 68),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour -60 secondes', '', '14/05/2024 | 19:34:58', 69),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour -60 secondes', '', '14/05/2024 | 19:35:55', 70),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour -60 secondes', '', '14/05/2024 | 19:36:07', 71),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour -60 secondes', '', '14/05/2024 | 19:36:29', 72),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour -60 secondes', '', '14/05/2024 | 19:36:33', 73),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 600 secondes', '', '14/05/2024 | 19:40:42', 74),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour -60 secondes', '', '14/05/2024 | 19:40:52', 75),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 5999999940 secondes', '', '14/05/2024 | 19:41:14', 76),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Test pour -30 secondes', '', '14/05/2024 | 19:49:37', 77),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Test pour -1 secondes', '', '14/05/2024 | 19:49:54', 78),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'BAN', 'Test pour -1jours', '', '14/05/2024 | 20:44:14', 79),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'BAN', 'Test pour -1jours', '', '14/05/2024 | 20:45:40', 80),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', '10 pour 600 secondes', '', '21/05/2024 | 21:30:22', 81),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 60 secondes', '', '21/05/2024 | 21:42:27', 82),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 600 secondes', '', '22/05/2024 | 21:12:06', 83),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'null', 'CFQ', 'JAIL', 'Test pour 60 secondes', '', '22/05/2024 | 21:12:21', 84),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 3000 secondes', '', '29/05/2024 | 18:52:36', 85),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Test pour 3600 secondes', '', '30/05/2024 | 21:59:12', 86),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'WARN', '1', '', '04/06/2024 | 21:43:25', 87),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'WARN', 'Test', '', '04/06/2024 | 21:43:30', 88),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 6000 secondes', '', '04/06/2024 | 22:42:24', 89),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'null', 'license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'BAN', 'Test pour 0jours', '', '05/06/2024 | 01:00:49', 90),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'null', 'license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'BAN', 'Test pour 0jours', '', '05/06/2024 | 01:02:57', 91),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'null', 'license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'BAN', 'test pour 12jours', '', '05/06/2024 | 01:03:12', 92),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'null', 'license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'BAN', 'Test pour 12jours', '', '05/06/2024 | 01:04:42', 93),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'null', 'license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'BAN', 'Test pour 0jours', '', '05/06/2024 | 01:13:28', 94),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'BAN', 'Test pour 0jours', '', '05/06/2024 | 01:14:46', 95),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'BAN', 'Test pour 0jours', '', '05/06/2024 | 01:15:38', 96),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'BAN', 'Test pour 10jours', '', '05/06/2024 | 01:16:28', 97),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'BAN', 'Test pour 10jours', '', '05/06/2024 | 01:17:16', 98),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test pour 6000 secondes', '', '22/06/2024 | 23:59:51', 99),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Test pour 3000 secondes', '', '23/06/2024 | 00:03:00', 100),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Test pour 3600 secondes', '', '23/06/2024 | 00:03:29', 101),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Test pour 3000 secondes', '', '23/06/2024 | 13:36:55', 102),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'WARN', 'Test', '', '25/06/2024 | 12:46:34', 103),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Test pour 60 secondes', '', '25/06/2024 | 12:53:01', 104),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Troll pour 60 secondes', '', '25/06/2024 | 13:52:22', 105),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Troll hrp  (60 min)', '', '25/06/2024 | 13:55:32', 106),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Troll hrp + Ment en voc + ntm + ntm fzkhnfoizhfzoiu bfizkuj fk zbef ubzf  (60 min)', '', '25/06/2024 | 13:55:46', 107),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'WARN', 'Base null', '', '25/06/2024 | 20:06:36', 108),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Test  (3600 min)', '', '25/06/2024 | 20:06:43', 109),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'Test  (3600 min)', '', '25/06/2024 | 20:09:25', 110),
('license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'null', 'license:05522abdb6933b6109e0fa6fc0330d9914f75291', 'BAN', 'Cheat pour 0jours', '', '25/06/2024 | 20:10:33', 111),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test  (600 min)', '', '08/08/2024 | 22:55:54', 112),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test  (600 min)', '', '12/08/2024 | 16:13:19', 113),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'dev', 'dev', 'JAIL', 'test  (3000 min)', '', '23/01/2025 | 23:57:16', 114),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'dev', 'dev', 'JAIL', 'test  (600 min)', '', '04/03/2025 | 21:53:15', 115),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'dev', 'dev', 'JAIL', 'test  (600 min)', '', '04/03/2025 | 21:56:07', 116),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'dev', 'dev', 'JAIL', 'test  (-1 min)', '', '04/03/2025 | 21:59:54', 117),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'WARN', 'test', '', '15/03/2025 | 19:08:35', 118),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test  (120 min)', NULL, '21/03/2025 | 15:08:12', 119),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'HRP + Troll  (900 min)', NULL, '13/04/2025 | 11:50:09', 120),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test  (600 min)', NULL, '13/04/2025 | 12:37:57', 121),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'null', 'null', 'JAIL', 'test  (600 min)', NULL, '22/04/2025 | 23:00:23', 122),
('license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'hq275101', 'Leo', 'JAIL', 'Test  (600 min)', NULL, '09/12/2025 | 19:15:00', 123),
('license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'hq275101', 'Leo', 'JAIL', 'Test  (900 min)', NULL, '09/12/2025 | 19:23:46', 124),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Console', 'hq275101', 'JAIL', 'test  (3600 min)', NULL, '09/12/2025 | 19:28:30', 125),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'hq275101', 'hq275101', 'JAIL', 'HRP + Insulte Staffs + Troll Véhicule + Tire en ville (parking central)  (300 min)', NULL, '09/12/2025 | 19:37:53', 126),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'hq275101', 'hq275101', 'JAIL', 'HRP + Insulte Staffs + Troll Véhicule + Tire en ville (parking central)  (300 min)', NULL, '09/12/2025 | 19:50:52', 127),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'hq275101', 'hq275101', 'JAIL', 'test  (3000 min)', NULL, '09/12/2025 | 20:14:56', 128),
('license:063e3a07b7e5204a49b87053d2fd572a89659886', 'Pablo delrulio', 'Pablo delrulio', 'JAIL', 'trop beau  (600 min)', NULL, '30/12/2025 | 06:16:05', 129);

-- --------------------------------------------------------

--
-- Structure de la table `society`
--

CREATE TABLE `society` (
  `id` int NOT NULL,
  `name` longtext COLLATE utf8mb4_general_ci NOT NULL,
  `label` varchar(255) COLLATE utf8mb4_general_ci DEFAULT 'Aucun',
  `legal` tinyint(1) DEFAULT '1',
  `data` longtext COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `society`
--

INSERT INTO `society` (`id`, `name`, `label`, `legal`, `data`) VALUES
(12, 'bikeshop', 'Concessionnaire Moto', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(16, 'carshop', 'Concessionnaire Voiture', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(18, 'realestateagent', 'Agent Immoblier', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(101, 'journaliste', 'Journaliste', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(133, 'bahamas', 'Bahamas', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(134, 'bloods', 'Bloods', 0, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(135, 'police', 'LSPD', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":{\"Politique de distribution des armes\":true,\"Politique de gestion des armes\":true,\"Politique d’arrestation\":true,\"Politique de sécurité publique\":true,\"Politique de contrôle des excès de force\":true,\"Politique de conservation de l\'environnement\":false},\"weapons\":[]}'),
(136, 'burgershot', 'BurgerShot', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":{\"Politique de Licence de Musique Live et Événements\":false,\"Politique de conservation de l\'environnement\":false,\"Politique de Licence de Vente d\'Alcool\":false},\"weapons\":[]}'),
(137, 'unicorn', 'Unicorn', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(138, 'wingwangbar', 'Bar Wing Wang', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(139, 'stokemaster', 'Strokemaster', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(140, 'muffler', 'Mufflers Motors', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(141, 'testrestaurant', 'testrestaurant', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(142, 'emsnord', 'EMS - Nord', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(143, 'gouvernement', 'Gouvernement', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}'),
(144, 'ambulance', 'EMS', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":{\"Politique de priorité\":false,\"Politique de conservation de l\'environnement\":false},\"weapons\":[]}'),
(145, 'woodcutting', 'Wood Cutting', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":{\"Politique de conservation de l\'environnement\":false},\"weapons\":[]}'),
(146, 'bennys', 'Benny\'s', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":{\"Politique de vérification\":false,\"Politique de conservation de l\'environnement\":false},\"weapons\":[]}'),
(147, 'taxi', 'Taxi', 1, '{\"accounts\":{\"cash\":0,\"dirtycash\":0},\"items\":[],\"politique\":[],\"weapons\":[]}');

-- --------------------------------------------------------

--
-- Structure de la table `society_moneywash`
--

CREATE TABLE `society_moneywash` (
  `id` int NOT NULL,
  `identifier` varchar(50) COLLATE utf8mb4_bin NOT NULL,
  `society` varchar(60) COLLATE utf8mb4_bin NOT NULL,
  `amount` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Structure de la table `staff`
--

CREATE TABLE `staff` (
  `idunique` int NOT NULL,
  `discord` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0',
  `name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `permission_group` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `date` varchar(250) COLLATE utf8mb4_general_ci NOT NULL,
  `nbrReport` int NOT NULL DEFAULT '0',
  `nbrReport_take_week` int DEFAULT '0',
  `nbrReport_close_week` int DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `staff`
--

INSERT INTO `staff` (`idunique`, `discord`, `name`, `permission_group`, `date`, `nbrReport`, `nbrReport_take_week`, `nbrReport_close_week`) VALUES
(1, '447086574346436618', 'null', 'fondateur', '23/03/2025 | 16:52:31', 12, 0, 0),
(12, '0', 'Test', 'mod', '27/01/2025 | 19:26:47', 0, 0, 0),
(14, '0', 'Pablo delrulio', 'fondateur', '08/02/2025 | 00:45:24', 2, 0, 0),
(15, '639601196361056300', 'Leo', 'fondateur', '12/02/2025 | 18:44:51', 1, 0, 0),
(16, '0', 'Téo', 'fondateur', '22/03/2025 | 02:36:53', 0, 0, 0);

-- --------------------------------------------------------

--
-- Structure de la table `starterpack`
--

CREATE TABLE `starterpack` (
  `identifier` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `take` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `tebex_histo`
--

CREATE TABLE `tebex_histo` (
  `id` int NOT NULL,
  `player` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `price` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `package_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `ip` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `date` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `month` varchar(255) COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `tebex_players_wallet`
--

CREATE TABLE `tebex_players_wallet` (
  `id` int NOT NULL,
  `identifiers` text COLLATE utf8mb4_general_ci NOT NULL,
  `idunique` int NOT NULL DEFAULT '0',
  `transaction` text COLLATE utf8mb4_general_ci,
  `price` text COLLATE utf8mb4_general_ci NOT NULL,
  `currency` text COLLATE utf8mb4_general_ci,
  `points` int NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `tebex_players_wallet`
--

INSERT INTO `tebex_players_wallet` (`id`, `identifiers`, `idunique`, `transaction`, `price`, `currency`, `points`, `created_at`, `updated_at`) VALUES
(27, '5521626', 1, 'Ajout de Coins par dev (U1)', '0', 'Points', 5000, '2025-03-02 23:39:09', '2025-03-02 23:39:09'),
(28, '5521626', 1, 'Achat d\'une caisse (Caisse Gold~s~)', '0', 'Points', -500, '2025-03-03 03:57:12', '2025-03-03 03:57:12'),
(29, '5521626', 1, 'Achat d\'une caisse (Caisse Gold~s~)', '0', 'Points', -500, '2025-03-03 03:57:12', '2025-03-03 03:57:12'),
(30, '5521626', 1, 'Achat d\'une caisse (Caisse Gold~s~)', '0', 'Points', -2250, '2025-03-03 03:57:23', '2025-03-03 03:57:23'),
(31, '5521626', 1, 'Achat d\'une caisse (Caisse Gold~s~)', '0', 'Points', -2250, '2025-03-03 03:57:23', '2025-03-03 03:57:23'),
(32, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-03-03 03:57:23', '2025-03-03 03:57:23'),
(33, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-03-03 03:57:23', '2025-03-03 03:57:23'),
(34, '5521626', 1, 'Ajout de Coins par dev (U1)', '0', 'Points', 10000, '2025-03-03 11:39:02', '2025-03-03 11:39:02'),
(35, '5521626', 1, 'Achat d\'une caisse (Caisse Ultime~s~)', '0', 'Points', -2000, '2025-03-03 11:39:10', '2025-03-03 11:39:10'),
(36, '5521626', 1, 'Achat d\'une caisse (Caisse Ultime~s~)', '0', 'Points', -2000, '2025-03-03 11:39:10', '2025-03-03 11:39:10'),
(37, '5521626', 0, NULL, '0', 'Points', -1500, '2025-03-03 12:18:32', '2025-03-03 12:18:32'),
(38, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -500, '2025-03-03 14:17:33', '2025-03-03 14:17:33'),
(39, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -500, '2025-03-03 14:17:33', '2025-03-03 14:17:33'),
(40, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -500, '2025-03-03 14:18:09', '2025-03-03 14:18:09'),
(41, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -500, '2025-03-03 14:18:09', '2025-03-03 14:18:09'),
(42, '5521626', 1, 'Achat d\'une caisse (Caisse Ultime)', '0', 'Points', -2000, '2025-03-03 14:18:58', '2025-03-03 14:18:58'),
(43, '5521626', 1, 'Achat d\'une caisse (Caisse Ultime)', '0', 'Points', -2000, '2025-03-03 14:18:58', '2025-03-03 14:18:58'),
(44, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-03-03 14:18:58', '2025-03-03 14:18:58'),
(45, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-03-03 14:18:58', '2025-03-03 14:18:58'),
(46, '5521626', 1, 'Ajout de Coins par dev (U1)', '0', 'Points', 2000, '2025-03-03 14:40:39', '2025-03-03 14:40:39'),
(47, '5521626', 1, 'Ajout de Coins par dev (U1)', '0', 'Points', 20000, '2025-03-03 14:40:49', '2025-03-03 14:40:49'),
(48, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -500, '2025-03-03 14:41:23', '2025-03-03 14:41:23'),
(49, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -500, '2025-03-03 14:41:23', '2025-03-03 14:41:23'),
(50, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -4500, '2025-03-03 14:49:49', '2025-03-03 14:49:49'),
(51, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -4500, '2025-03-03 14:49:49', '2025-03-03 14:49:49'),
(52, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-03-03 14:49:49', '2025-03-03 14:49:49'),
(53, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-03-03 14:49:49', '2025-03-03 14:49:49'),
(54, '5521626', 1, 'Achat de : Glock-17', '0', 'Points', -1200, '2025-03-03 14:53:29', '2025-03-03 14:53:29'),
(55, '5521626', 1, 'Achat de : Glock-17', '0', 'Points', -1200, '2025-03-03 14:53:29', '2025-03-03 14:53:29'),
(56, '5521626', 1, 'Achat d\'une caisse (Caisse Ultime)', '0', 'Points', -2000, '2025-03-03 14:56:54', '2025-03-03 14:56:54'),
(57, '5521626', 1, 'Achat d\'une caisse (Caisse Ultime)', '0', 'Points', -2000, '2025-03-03 14:56:54', '2025-03-03 14:56:54'),
(58, '5521626', 1, 'Achat d\'une caisse (Caisse Ultime)', '0', 'Points', -2000, '2025-03-03 14:56:55', '2025-03-03 14:56:55'),
(59, '5521626', 1, 'Achat d\'une caisse (Caisse Ultime)', '0', 'Points', -2000, '2025-03-03 14:56:55', '2025-03-03 14:56:55'),
(60, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-03-03 14:56:55', '2025-03-03 14:56:55'),
(61, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-03-03 14:56:55', '2025-03-03 14:56:55'),
(62, '5521626', 1, 'Ajout de Coins par dev (U1)', '0', 'Points', 10000, '2025-03-03 15:26:22', '2025-03-03 15:26:22'),
(63, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -500, '2025-03-03 15:26:38', '2025-03-03 15:26:38'),
(64, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -500, '2025-03-03 15:26:38', '2025-03-03 15:26:38'),
(65, '5521626', 1, 'Achat de : Aukadi A1', '0', 'Points', -1000, '2025-03-03 15:56:08', '2025-03-03 15:56:08'),
(66, '5521626', 1, 'Achat de : WMB M3 F80 2018 SPORT', '0', 'Points', -3000, '2025-03-03 16:02:19', '2025-03-03 16:02:19'),
(67, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-03-03 16:02:19', '2025-03-03 16:02:19'),
(68, '5521626', 1, 'Achat de : Gole', '0', 'Points', -3500, '2025-03-03 16:03:55', '2025-03-03 16:03:55'),
(69, '5521626', 5000, 'Ajout de Coins par dev (U1)', '0', 'Points', 5000, '2025-03-03 16:06:34', '2025-03-03 16:06:34'),
(70, '5521626', 1, 'Achat de : AK-47', '0', 'Points', -5000, '2025-03-03 16:07:05', '2025-03-03 16:07:05'),
(71, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-03-03 16:07:05', '2025-03-03 16:07:05'),
(72, '5521626', 1, 'WEAPON_SMG - 2043113590', '0', 'Points', -250, '2025-03-05 18:09:03', '2025-03-05 18:09:03'),
(73, '5521626', 1, 'WEAPON_SMG - -1023114086', '0', 'Points', -250, '2025-03-05 18:09:10', '2025-03-05 18:09:10'),
(74, '5521626', 1, 'WEAPON_SMG - 663170192', '0', 'Points', -250, '2025-03-05 18:09:16', '2025-03-05 18:09:16'),
(75, '5521626', 1, 'WEAPON_SMG - 2043113590', '0', 'Points', -250, '2025-03-05 18:09:24', '2025-03-05 18:09:24'),
(76, '5521626', 1, 'Ouverture de Caisse Légendaire : Vous avez gagner un(e) 250 000$', '0', 'Box', 0, '2025-03-06 18:54:57', '2025-03-06 18:54:57'),
(77, '5521626', 1, 'Ouverture de Caisse Légendaire : Vous avez gagner un(e) 250 000$', '0', 'Box', 0, '2025-03-06 18:59:56', '2025-03-06 18:59:56'),
(78, '5521626', 1, 'Ouverture de Caisse Légendaire : Vous avez gagner un(e) 250 000$', '0', 'Box', 0, '2025-03-06 19:02:09', '2025-03-06 19:02:09'),
(79, '5521626', 1, 'Ouverture de Caisse Légendaire : Vous avez gagner un(e) Raptor 150', '0', 'Box', 0, '2025-03-06 19:02:17', '2025-03-06 19:02:17'),
(80, '5521626', 1, 'Ouverture de Caisse Légendaire : Vous avez gagner un(e) AK Blastak', '0', 'Box', 0, '2025-03-06 19:30:59', '2025-03-06 19:30:59'),
(81, '5521626', 1, 'Ajout de Coins par dev', '0', 'Points', 1000, '2025-03-08 20:10:16', '2025-03-08 20:10:16'),
(82, '5521626', 1, 'Ajout de Coins par dev', '0', 'Points', 10000, '2025-03-08 20:10:18', '2025-03-08 20:10:18'),
(83, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-03-08 20:10:20', '2025-03-08 20:10:20'),
(84, '5521626', 1, 'WEAPON_SMG - 2043113590', '0', 'Points', -250, '2025-03-08 20:10:20', '2025-03-08 20:10:20'),
(85, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -500, '2025-03-11 18:00:56', '2025-03-11 18:00:56'),
(86, '5521626', 0, NULL, '0', 'Points', -3000, '2025-03-12 18:14:37', '2025-03-12 18:14:37'),
(87, '5521626', 1, 'Ajout de Coins par Console', '0', 'Points', 1000, '2025-03-13 19:43:27', '2025-03-13 19:43:27'),
(88, '5521626', 1, 'Ajout de Coins par Console', '0', 'Points', 1000, '2025-03-13 19:43:34', '2025-03-13 19:43:34'),
(89, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -500, '2025-03-23 16:02:58', '2025-03-23 16:02:58'),
(90, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) Electric Scooter', '0', 'Box', 0, '2025-03-23 16:03:26', '2025-03-23 16:03:26'),
(91, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -500, '2025-03-23 16:11:06', '2025-03-23 16:11:06'),
(92, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) Renault Clio 5', '0', 'Box', 0, '2025-03-23 16:11:11', '2025-03-23 16:11:11'),
(93, '5521626', 1, 'Achat d\'une caisse (Caisse Gold)', '0', 'Points', -4500, '2025-03-23 16:13:02', '2025-03-23 16:13:02'),
(94, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-03-23 16:13:02', '2025-03-23 16:13:02'),
(95, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) Mxrb', '0', 'Box', 0, '2025-03-23 16:13:07', '2025-03-23 16:13:07'),
(96, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) Twingo', '0', 'Box', 0, '2025-03-23 16:13:17', '2025-03-23 16:13:17'),
(97, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) Cayenne', '0', 'Box', 0, '2025-03-23 16:14:46', '2025-03-23 16:14:46'),
(98, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) Bmci', '0', 'Box', 0, '2025-03-23 16:14:52', '2025-03-23 16:14:52'),
(99, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) Smc690', '0', 'Box', 0, '2025-03-23 16:16:17', '2025-03-23 16:16:17'),
(100, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) V250', '0', 'Box', 0, '2025-03-23 16:18:45', '2025-03-23 16:18:45'),
(101, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) MT125', '0', 'Box', 0, '2025-03-23 16:19:45', '2025-03-23 16:19:45'),
(102, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) Renault Clio 5', '0', 'Box', 0, '2025-03-23 16:19:52', '2025-03-23 16:19:52'),
(103, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) 750 000$', '0', 'Box', 0, '2025-03-23 16:21:10', '2025-03-23 16:21:10'),
(104, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) MT125', '0', 'Box', 0, '2025-03-23 16:22:27', '2025-03-23 16:22:27'),
(105, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) Audi Rs3', '0', 'Box', 0, '2025-03-23 16:24:41', '2025-03-23 16:24:41'),
(106, '5521626', 1, 'Ouverture de Caisse Fidelité : Vous avez gagner un(e) 500 000$', '0', 'Box', 0, '2025-03-23 16:25:53', '2025-03-23 16:25:53'),
(107, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) Twingo', '0', 'Box', 0, '2025-03-23 16:29:13', '2025-03-23 16:29:13'),
(108, '5521626', 1, 'WEAPON_ASSAULTRIFLE - -1323216997', '0', 'Points', -250, '2025-03-25 22:07:44', '2025-03-25 22:07:44'),
(109, '5521626', 1, 'WEAPON_HKUMP - -1331471085', '0', 'Points', -250, '2025-03-26 22:16:54', '2025-03-26 22:16:54'),
(110, '5521626', 1, 'Achat de : Sultan Unique', '0', 'Points', -1000, '2025-04-10 18:09:51', '2025-04-10 18:09:51'),
(111, '5521626', 1, 'Achat de : Sultan Unique', '0', 'Points', -1000, '2025-04-10 18:36:51', '2025-04-10 18:36:51'),
(112, '5521626', 1, 'Achat de : Sultan Unique', '0', 'Points', -1000, '2025-04-10 18:41:26', '2025-04-10 18:41:26'),
(113, '5521626', 1, 'Ajout de Coins par null', '0', 'Points', 10000, '2025-04-10 18:41:56', '2025-04-10 18:41:56'),
(114, '5521626', 1, 'Achat de : Sultan RS', '0', 'Points', -2500, '2025-04-10 18:42:02', '2025-04-10 18:42:02'),
(115, '5521626', 1, 'Récompense fideliter', '0', 'Points', 0, '2025-04-10 18:42:02', '2025-04-10 18:42:02'),
(116, '5521626', 1, 'WEAPON_PISTOL - 899381934', '0', 'Points', -250, '2025-04-13 11:39:47', '2025-04-13 11:39:47'),
(117, '5521626', 1, 'WEAPON_PISTOL - -316253668', '0', 'Points', -250, '2025-04-13 11:39:51', '2025-04-13 11:39:51'),
(118, '5521626', 1, 'WEAPON_PISTOL - 1709866683', '0', 'Points', -250, '2025-04-13 11:40:06', '2025-04-13 11:40:06'),
(119, '5521626', 0, NULL, '0', 'Points', -1500, '2025-04-13 12:21:31', '2025-04-13 12:21:31'),
(120, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) Audi Rs3', '0', 'Box', 0, '2025-05-30 17:25:50', '2025-05-30 17:25:50'),
(121, '5521626', 1, 'Ouverture de Caisse Gold : Vous avez gagner un(e) Smc690', '0', 'Box', 0, '2025-05-30 17:29:16', '2025-05-30 17:29:16'),
(122, '5521626', 1, 'Ouverture de Caisse Légendaire : Vous avez gagner un(e) Mercedes GLE', '0', 'Box', 0, '2025-05-30 17:33:10', '2025-05-30 17:33:10'),
(123, '5521626', 1, 'Ouverture de Caisse Légendaire : Vous avez gagner un(e) Savage', '0', 'Box', 0, '2025-05-30 17:34:04', '2025-05-30 17:34:04'),
(124, '5521626', 1, 'Ouverture de Caisse Légendaire : Vous avez gagner un(e) Velar', '0', 'Box', 0, '2025-05-30 17:34:52', '2025-05-30 17:34:52');

-- --------------------------------------------------------

--
-- Structure de la table `tebex_null_fidelite`
--

CREATE TABLE `tebex_null_fidelite` (
  `id` int NOT NULL,
  `license` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0',
  `havebuy` int NOT NULL DEFAULT '0',
  `totalbuy` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `tebex_null_fidelite`
--

INSERT INTO `tebex_null_fidelite` (`id`, `license`, `havebuy`, `totalbuy`) VALUES
(8, '5521626', 2950, 52950),
(9, '5365910', 3200, 33200),
(10, '4905132', 500, 5500),
(11, '1412254', 0, 5000);

-- --------------------------------------------------------

--
-- Structure de la table `territoriesshop`
--

CREATE TABLE `territoriesshop` (
  `id` int NOT NULL,
  `territories_id` int DEFAULT '0',
  `name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `label` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `type` varchar(24) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'item',
  `price` int NOT NULL DEFAULT '100',
  `points` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `territoriesshop`
--

INSERT INTO `territoriesshop` (`id`, `territories_id`, `name`, `label`, `type`, `price`, `points`) VALUES
(1, 0, 'WEAPON_KNIFE', 'Couteau', 'weapon', 100, 100),
(2, 0, 'kevlar', 'Kevlar', 'item', 135, 23),
(3, 1, 'WEAPON_COMBATPISTOL', 'Pistolet de combat', 'weapon', 1650, 100);

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

CREATE TABLE `users` (
  `idunique` int NOT NULL,
  `name` varchar(25) COLLATE utf8mb4_bin DEFAULT NULL,
  `eval_staff` int DEFAULT NULL,
  `identifier` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `discord` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `fivem` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `permission_group` varchar(50) COLLATE utf8mb4_bin DEFAULT 'user',
  `permission_level` int DEFAULT '0',
  `streamer` int NOT NULL DEFAULT '0',
  `position` longtext COLLATE utf8mb4_bin,
  `skin` longtext COLLATE utf8mb4_bin,
  `accounts` longtext COLLATE utf8mb4_bin,
  `inventory` longtext COLLATE utf8mb4_bin,
  `loadout` longtext COLLATE utf8mb4_bin,
  `job` varchar(50) COLLATE utf8mb4_bin DEFAULT 'unemployed',
  `job_grade` int DEFAULT '0',
  `job2` varchar(50) COLLATE utf8mb4_bin DEFAULT 'unemployed2',
  `job2_grade` int DEFAULT '0',
  `status` longtext COLLATE utf8mb4_bin,
  `playtime` int NOT NULL DEFAULT '0',
  `lastConnection` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `firstname` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `lastname` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `dateofbirth` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `sex` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
  `height` longtext COLLATE utf8mb4_bin,
  `xp` int DEFAULT '1',
  `clothes` varchar(1000) COLLATE utf8mb4_bin DEFAULT NULL,
  `smells` text COLLATE utf8mb4_bin,
  `ata` int DEFAULT NULL,
  `afk_point` int DEFAULT '0',
  `afk_time` int DEFAULT '0',
  `apps` text COLLATE utf8mb4_bin,
  `widget` text COLLATE utf8mb4_bin,
  `bt` text COLLATE utf8mb4_bin,
  `charinfo` text COLLATE utf8mb4_bin,
  `metadata` mediumtext COLLATE utf8mb4_bin,
  `cryptocurrency` longtext COLLATE utf8mb4_bin,
  `cryptocurrencytransfers` text COLLATE utf8mb4_bin,
  `tattoo` longtext COLLATE utf8mb4_bin
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `users`
--

INSERT INTO `users` (`idunique`, `name`, `eval_staff`, `identifier`, `discord`, `fivem`, `permission_group`, `permission_level`, `streamer`, `position`, `skin`, `accounts`, `inventory`, `loadout`, `job`, `job_grade`, `job2`, `job2_grade`, `status`, `playtime`, `lastConnection`, `firstname`, `lastname`, `dateofbirth`, `sex`, `height`, `xp`, `clothes`, `smells`, `ata`, `afk_point`, `afk_time`, `apps`, `widget`, `bt`, `charinfo`, `metadata`, `cryptocurrency`, `cryptocurrencytransfers`, `tattoo`) VALUES
(1, 'null', 3, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '447086574346436618', '', 'fondateur', 0, 1, '{\"y\":2124.60009765625,\"z\":61.79999923706055,\"x\":-1557.5}', '{\"watches_2\":0,\"pants_2\":0,\"complexion_2\":0,\"jaw_1\":0,\"helmet_1\":-1,\"cheeks_2\":0,\"sex\":0,\"chain_1\":-1,\"skin_md_weight\":0,\"lipstick_3\":0,\"watches_1\":-1,\"blush_3\":0,\"blemishes_1\":0,\"eye_color\":5,\"beard_4\":0,\"bodyb_3\":-1,\"eyebrows_3\":0,\"bodyb_2\":0,\"makeup_4\":0,\"bproof_1\":-1,\"bags_1\":40,\"beard_2\":10,\"ears_1\":41,\"sun_2\":0,\"jaw_2\":0,\"age_2\":0,\"glasses_1\":-1,\"hair_color_1\":0,\"torso_2\":0,\"beard_3\":0,\"bracelets_2\":0,\"chain_2\":0,\"eyebrows_2\":10,\"bracelets_1\":-1,\"tshirt_1\":0,\"eyebrows_4\":0,\"bodyb_1\":-1,\"decals_1\":0,\"mom\":36,\"torso_1\":7,\"beard_1\":1,\"eye_squint\":0,\"blemishes_2\":0,\"hair_1\":1,\"age_1\":0,\"complexion_1\":0,\"eyebrows_6\":0,\"nose_6\":0,\"blush_2\":0,\"shoes_2\":0,\"nose_5\":1,\"eyebrows_5\":0,\"sun_1\":0,\"bags_2\":0,\"bodyb_4\":0,\"chest_1\":0,\"nose_3\":7,\"dad\":0,\"chest_2\":0,\"hair_color_2\":0,\"blush_1\":0,\"lipstick_2\":0,\"chest_3\":0,\"makeup_2\":0,\"nose_2\":3,\"eyebrows_1\":1,\"chin_1\":0,\"ears_2\":0,\"moles_2\":0,\"nose_1\":0,\"chin_2\":0,\"chin_3\":0,\"moles_1\":0,\"lipstick_4\":0,\"helmet_2\":0,\"mask_1\":-1,\"lipstick_1\":0,\"hair_2\":0,\"lip_thickness\":0,\"arms\":4,\"arms_2\":0,\"makeup_3\":0,\"face_md_weight\":100,\"makeup_1\":0,\"decals_2\":0,\"nose_4\":0,\"shoes_1\":6,\"cheeks_1\":6,\"neck_thickness\":0,\"pants_1\":6,\"bproof_2\":0,\"chin_4\":0,\"tshirt_2\":0,\"cheeks_3\":10,\"glasses_2\":0,\"mask_2\":0}', '[{\"money\":8653,\"name\":\"cash\"},{\"money\":115379,\"name\":\"dirtycash\"},{\"money\":828903,\"name\":\"bank\"},{\"money\":0,\"name\":\"chip\"},{\"money\":184,\"name\":\"fidelcoins\"}]', '[{\"unique\":false,\"metadata\":[],\"count\":7,\"name\":\"dirt-weed\"},{\"unique\":false,\"metadata\":[],\"count\":19,\"name\":\"water-weed\"},{\"unique\":false,\"metadata\":[],\"count\":1,\"name\":\"7upfinale\"},{\"unique\":false,\"metadata\":[],\"count\":104,\"name\":\"acid-meth\"},{\"unique\":false,\"metadata\":[],\"count\":4,\"name\":\"acier\"},{\"unique\":false,\"metadata\":[],\"count\":2,\"name\":\"aciertraiter\"},{\"unique\":false,\"metadata\":[],\"count\":136,\"name\":\"wood\"},{\"unique\":false,\"metadata\":[],\"count\":39,\"name\":\"woodcutted\"},{\"unique\":false,\"metadata\":[],\"count\":7,\"name\":\"water\"},{\"unique\":false,\"metadata\":[],\"count\":1,\"name\":\"caisse_fidelite\"},{\"unique\":false,\"metadata\":[],\"count\":98,\"name\":\"caisse_gold\"},{\"unique\":false,\"metadata\":[],\"count\":25,\"name\":\"caisse_diamond\"},{\"extra\":{\"identifier\":7306},\"unique\":true,\"metadata\":{\"birthday\":\"2000-01-01\",\"lastname\":\"bucket\",\"sex\":\"Mâle\",\"firstname\":\"c\",\"creation\":1743816197},\"count\":1,\"name\":\"identity_card\"},{\"unique\":false,\"metadata\":[],\"count\":18,\"name\":\"ceinture_explosive\"},{\"unique\":false,\"metadata\":[],\"count\":39,\"name\":\"champignonrecolte\"},{\"unique\":false,\"metadata\":[],\"count\":10,\"name\":\"basic_key\"},{\"unique\":false,\"metadata\":[],\"count\":1,\"name\":\"police_key\"},{\"unique\":false,\"metadata\":[],\"count\":100,\"name\":\"hazmat\"},{\"unique\":false,\"metadata\":[],\"count\":16,\"name\":\"engrais-weed\"},{\"unique\":false,\"metadata\":[],\"count\":8,\"name\":\"femaleseed\"},{\"unique\":false,\"metadata\":[],\"count\":20,\"name\":\"maleseed\"},{\"unique\":false,\"metadata\":[],\"count\":1,\"name\":\"weedscissors\"},{\"unique\":false,\"metadata\":[],\"count\":3,\"name\":\"kevlar\"},{\"unique\":false,\"metadata\":[],\"count\":9,\"name\":\"medikit\"},{\"unique\":false,\"metadata\":[],\"count\":10,\"name\":\"basic_cuff\"},{\"unique\":false,\"metadata\":[],\"count\":1,\"name\":\"police_cuff\"},{\"unique\":false,\"metadata\":[],\"count\":75,\"name\":\"meth_mixture\"},{\"unique\":false,\"metadata\":[],\"count\":33,\"name\":\"mobilier\"},{\"unique\":false,\"metadata\":[],\"count\":2154,\"name\":\"ammo_rifle\"},{\"unique\":false,\"metadata\":[],\"count\":1255,\"name\":\"ammo_pistol\"},{\"unique\":false,\"metadata\":[],\"count\":751,\"name\":\"ammo_shotgun\"},{\"unique\":false,\"metadata\":[],\"count\":1876,\"name\":\"ammo_sniper\"},{\"unique\":false,\"metadata\":[],\"count\":1,\"name\":\"hack_laptop\"},{\"extra\":{\"identifier\":2895},\"unique\":true,\"metadata\":{\"sex\":\"Mâle\",\"licenses\":{\"dmv\":true,\"drive_truck\":true,\"weapon\":true,\"drive_bike\":true,\"drive\":true},\"lastname\":\"bucket\",\"birthday\":\"2000-01-01\",\"firstname\":\"c\",\"creation\":1743364518},\"count\":1,\"name\":\"weapon\"},{\"extra\":{\"identifier\":2714},\"unique\":true,\"metadata\":{\"sex\":\"Mâle\",\"licenses\":{\"dmv\":true,\"drive_truck\":true,\"weapon\":true,\"drive_bike\":true,\"drive\":true},\"lastname\":\"2\",\"birthday\":\"2000-01-01\",\"firstname\":\"drive\",\"creation\":1743299589},\"count\":1,\"name\":\"drive\"},{\"extra\":{\"identifier\":9977},\"unique\":true,\"metadata\":{\"sex\":\"Mâle\",\"licenses\":{\"dmv\":true,\"drive_truck\":true,\"weapon\":true,\"drive_bike\":true,\"drive\":true},\"lastname\":\"bucket\",\"birthday\":\"2000-01-01\",\"firstname\":\"c\",\"creation\":1743816199},\"count\":1,\"name\":\"drive\"},{\"unique\":false,\"metadata\":[],\"count\":104,\"name\":\"phosphorus-meth\"},{\"unique\":false,\"metadata\":[],\"count\":74,\"name\":\"weed_plant\"},{\"unique\":false,\"metadata\":[],\"count\":104,\"name\":\"weed_plant_dry\"},{\"unique\":false,\"metadata\":[],\"count\":5,\"name\":\"plateau_meth_brute\"},{\"unique\":false,\"metadata\":[],\"count\":95,\"name\":\"empty_pooch\"},{\"unique\":false,\"metadata\":[],\"count\":100,\"name\":\"coke_pooch\"},{\"unique\":false,\"metadata\":[],\"count\":103,\"name\":\"meth_pooch\"},{\"unique\":false,\"metadata\":[],\"count\":78,\"name\":\"weed_pooch\"},{\"unique\":false,\"metadata\":[],\"count\":3,\"name\":\"poster\"},{\"unique\":false,\"metadata\":[],\"count\":93,\"name\":\"plantpot\"},{\"unique\":false,\"metadata\":[],\"count\":104,\"name\":\"pseudoephedrine\"},{\"unique\":false,\"metadata\":[],\"count\":1,\"name\":\"radio\"},{\"unique\":false,\"metadata\":[],\"count\":12,\"name\":\"salade\"},{\"unique\":false,\"metadata\":[],\"count\":10,\"name\":\"solvant-meth\"},{\"unique\":false,\"metadata\":[],\"count\":4,\"name\":\"steak\"},{\"unique\":false,\"metadata\":[],\"count\":10,\"name\":\"gofast_tablet\"},{\"unique\":false,\"metadata\":[],\"count\":1,\"name\":\"delivery_tablet\"},{\"unique\":false,\"metadata\":[],\"count\":1,\"name\":\"phone\"},{\"unique\":false,\"metadata\":[],\"count\":99,\"name\":\"weed_head\"}]', '[{\"components\":[],\"durability\":43.40000000000001,\"serialnumber\":\"LD7K0ZYPMFGJ7VW\",\"metadata\":{\"description\":\"\",\"label\":\"Fusil a pompe de Combat\"},\"permanent\":true,\"allcomponents\":[],\"ammo\":250,\"name\":\"WEAPON_COMBATSHOTGUN\"},{\"components\":[],\"durability\":30.79999999999995,\"serialnumber\":\"T0I12DDKJH7YDK7\",\"metadata\":{\"description\":\"\",\"label\":\"Carabine à canon scié\"},\"permanent\":true,\"allcomponents\":[{\"hash\":-2052698631,\"label\":\"Finition de luxe\",\"name\":\"luxary_finish\"}],\"ammo\":250,\"name\":\"WEAPON_SAWNOFFSHOTGUN\"},{\"metadata\":{\"description\":\"\",\"label\":\"Sniper Lourd Mk II\"},\"components\":[],\"ammo\":250,\"permanent\":true,\"serialnumber\":\"EZ1K8P4OKMM6T8N\",\"durability\":100.09999999999988,\"name\":\"WEAPON_HEAVYSNIPER_MK2\"},{\"components\":[],\"durability\":20.9,\"serialnumber\":\"8I3894WV7LB5DEL\",\"metadata\":{\"description\":\"Arme give par null\",\"label\":\"Navy Revolver Unique\"},\"permanent\":true,\"allcomponents\":[],\"ammo\":250,\"name\":\"WEAPON_NAVYREVOLVER\"},{\"durability\":6.59999999999999,\"components\":[],\"ammo\":100,\"permanent\":false,\"allcomponents\":[{\"hash\":-1101075946,\"label\":\"Chargeur par défaut\",\"name\":\"clip_default\"},{\"hash\":-1323216997,\"label\":\"Chargeur grande capacité\",\"name\":\"clip_extended\"},{\"hash\":-604986051,\"label\":\"Chargeur tambour\",\"name\":\"clip_drum\"},{\"hash\":2076495324,\"label\":\"Torche\",\"name\":\"flashlight\"},{\"hash\":-1657815255,\"label\":\"Viseur\",\"name\":\"scope\"},{\"hash\":-1489156508,\"label\":\"Réducteur de son\",\"name\":\"suppressor\"},{\"hash\":202788691,\"label\":\"Poignée\",\"name\":\"grip\"},{\"hash\":1319990579,\"label\":\"Finition de luxe\",\"name\":\"luxary_finish\"}],\"metadata\":[],\"name\":\"WEAPON_ASSAULTRIFLE\"},{\"durability\":0,\"components\":[],\"ammo\":100,\"permanent\":false,\"allcomponents\":[{\"hash\":-767279652,\"label\":\"Viseur\",\"name\":\"scope\"},{\"hash\":-1135289737,\"label\":\"Lunette\",\"name\":\"scope_advanced\"},{\"hash\":-1489156508,\"label\":\"Réducteur de son\",\"name\":\"suppressor\"},{\"hash\":1077065191,\"label\":\"Finition de luxe\",\"name\":\"luxary_finish\"}],\"metadata\":[],\"name\":\"WEAPON_SNIPERRIFLE\"},{\"metadata\":{\"police\":true},\"components\":[],\"ammo\":1,\"permanent\":false,\"serialnumber\":\"DKFLEDGDEO6ZCY2\",\"durability\":0,\"name\":\"WEAPON_STUNGUN\"},{\"metadata\":{\"police\":true},\"components\":[],\"ammo\":1,\"permanent\":false,\"serialnumber\":\"AXJ3Z7RI83BW1WI\",\"durability\":0,\"name\":\"WEAPON_NIGHTSTICK\"},{\"metadata\":{\"police\":true},\"components\":[],\"ammo\":1,\"permanent\":false,\"serialnumber\":\"R2NGN7YKF4OEHS0\",\"durability\":0,\"name\":\"WEAPON_COMBATPISTOL\"},{\"metadata\":{\"police\":true},\"components\":[],\"ammo\":1,\"permanent\":false,\"serialnumber\":\"7J6KII0XCMR4UH7\",\"durability\":0,\"name\":\"WEAPON_SMG\"},{\"metadata\":{\"police\":true},\"components\":[],\"ammo\":1,\"permanent\":false,\"serialnumber\":\"OZUMG2V0B0K5RTQ\",\"durability\":0,\"name\":\"WEAPON_ASSAULTSMG\"},{\"metadata\":{\"police\":true},\"components\":[],\"ammo\":1,\"permanent\":false,\"serialnumber\":\"8JT5A83PJ2OT0U7\",\"durability\":0,\"name\":\"WEAPON_PUMPSHOTGUN\"},{\"metadata\":{\"police\":true},\"components\":[],\"ammo\":1,\"permanent\":false,\"serialnumber\":\"P8CJWX71AB1PJAR\",\"durability\":0,\"name\":\"WEAPON_CARBINERIFLE\"},{\"metadata\":{\"gouvernement\":true},\"components\":[],\"ammo\":1,\"permanent\":false,\"serialnumber\":\"BFVLMYI3BBZFLXV\",\"durability\":0,\"name\":\"WEAPON_FLASHLIGHT\"}]', 'police', 4, 'bloods', 2, 'null', 1319, '2025-12-31 04:00:23', 'John', 'Doe', '2002-01-02', '0', '197', 293000, '{\"top\":{\"label\":\"Chill 2\",\"data\":{\"decals_1\":0,\"decals_2\":0,\"tshirt_2\":0,\"tshirt_1\":0,\"torso_1\":7,\"arms\":4,\"torso_2\":0},\"name\":996115},\"shoes\":{\"label\":\"test\",\"data\":{\"shoes_1\":6,\"shoes_2\":0},\"name\":996122},\"pants\":{\"label\":\"Short\",\"data\":{\"pants_1\":6,\"pants_2\":0},\"name\":996119}}', '[]', 10, 5, 7, '[{\"blockedjobs\":[],\"color\":\"img/apps/phone.png\",\"tooltipPos\":\"top\",\"app\":\"phone\",\"bottom\":true,\"Alerts\":0,\"icon\":\"fa fa-phone-alt\",\"slot\":1,\"job\":false,\"tooltipText\":\"Phone\"},{\"blockedjobs\":[],\"color\":\"img/apps/gallery.png\",\"app\":\"photos\",\"bottom\":true,\"Alerts\":0,\"icon\":\"fab fa-spotify\",\"slot\":2,\"job\":false,\"tooltipText\":\"Gallery\"},{\"blockedjobs\":[],\"color\":\"img/apps/messages.png\",\"app\":\"messages\",\"bottom\":true,\"Alerts\":0,\"icon\":\"fas fa-university\",\"slot\":3,\"job\":false,\"tooltipText\":\"Messages\"},{\"blockedjobs\":[],\"color\":\"img/apps/settings.png\",\"tooltipPos\":\"top\",\"app\":\"settings\",\"bottom\":true,\"Alerts\":0,\"icon\":\"fa fa-cog\",\"slot\":4,\"job\":false,\"tooltipText\":\"Settings\"},{\"Alerts\":0,\"icon\":\"fab fa-spotify\",\"color\":\"img/apps/clock.png\",\"job\":false,\"slot\":5,\"app\":\"clock\",\"tooltipText\":\"Clock\",\"blockedjobs\":[]},{\"Alerts\":0,\"icon\":\"fab fa-spotify\",\"color\":\"img/apps/camera.png\",\"job\":false,\"slot\":6,\"app\":\"camera\",\"tooltipText\":\"Camera\",\"blockedjobs\":[]},{\"Alerts\":0,\"icon\":\"fas fa-envelope\",\"color\":\"img/apps/mail.png\",\"job\":false,\"slot\":7,\"app\":\"mail\",\"tooltipText\":\"Mail\",\"blockedjobs\":[]},{\"Alerts\":0,\"icon\":\"fas fa-university\",\"color\":\"img/apps/banksign.png\",\"job\":false,\"slot\":8,\"app\":\"bank\",\"tooltipText\":\"Bank\",\"blockedjobs\":[]},{\"Alerts\":0,\"icon\":\"fab fa-spotify\",\"color\":\"img/apps/system_calendar_1.png\",\"job\":false,\"slot\":9,\"app\":\"calendar\",\"tooltipText\":\"Calendar\",\"blockedjobs\":[]},{\"Alerts\":0,\"icon\":\"&nbsp;\",\"color\":\"img/apps/weather.png\",\"job\":false,\"slot\":10,\"app\":\"weather\",\"tooltipText\":\"Weather\",\"blockedjobs\":[]},{\"Alerts\":0,\"icon\":\"fab fa-spotify\",\"color\":\"img/apps/notes.png\",\"job\":false,\"slot\":11,\"app\":\"notes\",\"tooltipText\":\"Notes\",\"blockedjobs\":[]},{\"Alerts\":0,\"icon\":\"fab fa-spotify\",\"color\":\"img/apps/calculator.png\",\"job\":false,\"slot\":12,\"app\":\"calculator\",\"tooltipText\":\"Calculator\",\"blockedjobs\":[]},{\"Alerts\":0,\"icon\":\"fas fa-user-tie\",\"color\":\"img/apps/appstore.png\",\"job\":false,\"slot\":13,\"app\":\"store\",\"tooltipText\":\"App Store\",\"blockedjobs\":[]},{\"blockedjobs\":[],\"color\":\"img/apps/music.png\",\"app\":\"music\",\"bottom\":true,\"Alerts\":0,\"icon\":\"\",\"slot\":14,\"job\":false,\"tooltipText\":\"Music\"},{\"blockedjobs\":[],\"color\":\"img/apps/ping.png\",\"app\":\"ping\",\"bottom\":true,\"Alerts\":0,\"icon\":\"\",\"slot\":15,\"job\":false,\"tooltipText\":\"Ping\"},{\"Alerts\":0,\"blockedjobs\":[],\"color\":\"img/apps/yellow_pages.png\",\"slot\":16,\"app\":\"advert\",\"job\":false,\"tooltipText\":\"Yellow Pages\"},{\"Alerts\":0,\"blockedjobs\":[],\"color\":\"nui://qs-smartphone/html/img/apps/discord.png\",\"slot\":17,\"app\":\"group-chats\",\"job\":false,\"tooltipText\":\"Discord\"},{\"Alerts\":0,\"blockedjobs\":[],\"color\":\"nui://qs-smartphone/html/img/apps/spotify.png\",\"slot\":18,\"app\":\"spotify\",\"job\":false,\"tooltipText\":\"Spotify\"},{\"Alerts\":0,\"blockedjobs\":[],\"color\":\"nui://qs-smartphone/html/img/apps/tinder.png\",\"slot\":19,\"app\":\"tinder\",\"job\":false,\"tooltipText\":\"Tinder\"},{\"Alerts\":0,\"blockedjobs\":[],\"color\":\"nui://qs-smartphone/html/img/apps/instagram.png\",\"slot\":20,\"app\":\"instagram\",\"job\":false,\"tooltipText\":\"Instagram\"},{\"Alerts\":0,\"blockedjobs\":[],\"color\":\"img/apps/youtube.png\",\"slot\":21,\"app\":\"youtube\",\"job\":false,\"tooltipText\":\"YouTube\"},{\"Alerts\":0,\"blockedjobs\":[],\"color\":\"img/apps/whatsapp.png\",\"slot\":22,\"app\":\"whatsapp\",\"job\":false,\"tooltipText\":\"WhatsApp\"}]', '{\"widget_gorunum\":false}', '0', '{\"lastname\":\"Mike\",\"account\":\"V7413127828\",\"phone\":\"788347294\",\"firstname\":\"Mike\"}', '{\"walletid\":\"QS-26694378\",\"cryptoid\":\"cpt-Ak466\",\"phone\":{\"InstalledApps\":[]},\"CryptoCurrency\":[]}', NULL, NULL, NULL),
(19, 'Pablo delrulio', NULL, 'license:063e3a07b7e5204a49b87053d2fd572a89659886', '1057427236199870525', '4905132', 'fondateur', 0, 0, '{\"z\":63.4000015258789,\"y\":2120.800048828125,\"x\":-1559.5}', '{\"shoes_2\":0,\"torso_2\":0,\"chain_1\":-1,\"lipstick_1\":0,\"skin_md_weight\":0,\"blush_3\":0,\"bproof_2\":0,\"eyebrows_4\":0,\"blemishes_1\":0,\"watches_1\":-1,\"chain_2\":0,\"makeup_4\":0,\"glasses_2\":0,\"blemishes_2\":0,\"hair_2\":0,\"face_md_weight\":100,\"tshirt_1\":15,\"mask_1\":-1,\"sun_2\":0,\"eyebrows_1\":30,\"nose_4\":10,\"nose_1\":10,\"chin_4\":0,\"dad\":0,\"complexion_1\":0,\"eye_squint\":0,\"pants_2\":0,\"nose_6\":0,\"pants_1\":61,\"mask_2\":0,\"ears_2\":0,\"ears_1\":-1,\"age_2\":0,\"beard_1\":3,\"nose_3\":10,\"jaw_1\":0,\"bodyb_1\":-1,\"eyebrows_6\":0,\"blush_1\":0,\"bracelets_2\":0,\"chest_2\":0,\"chest_1\":0,\"mom\":0,\"age_1\":0,\"bodyb_2\":0,\"moles_2\":0,\"hair_color_1\":0,\"helmet_2\":0,\"lipstick_4\":0,\"arms_2\":0,\"lipstick_3\":0,\"blush_2\":0,\"beard_2\":10,\"hair_1\":42,\"moles_1\":0,\"watches_2\":0,\"makeup_1\":0,\"eyebrows_3\":0,\"hair_color_2\":0,\"cheeks_2\":0,\"glasses_1\":-1,\"shoes_1\":34,\"eye_color\":0,\"neck_thickness\":0,\"helmet_1\":-1,\"tshirt_2\":0,\"chin_1\":0,\"bags_2\":0,\"nose_5\":10,\"torso_1\":15,\"cheeks_3\":10,\"eyebrows_2\":10,\"bracelets_1\":-1,\"nose_2\":0,\"complexion_2\":0,\"chin_2\":0,\"jaw_2\":0,\"makeup_3\":0,\"arms\":15,\"lip_thickness\":0,\"makeup_2\":0,\"bags_1\":-1,\"sun_1\":0,\"bproof_1\":-1,\"sex\":0,\"lipstick_2\":0,\"bodyb_3\":-1,\"chest_3\":0,\"decals_1\":0,\"beard_3\":0,\"cheeks_1\":0,\"chin_3\":0,\"decals_2\":0,\"beard_4\":0,\"bodyb_4\":0,\"eyebrows_5\":0}', '[{\"name\":\"cash\",\"money\":14680},{\"name\":\"dirtycash\",\"money\":0},{\"name\":\"bank\",\"money\":19820},{\"name\":\"chip\",\"money\":0},{\"name\":\"fidelcoins\",\"money\":0}]', '[]', '[]', 'unemployed', 0, 'unemployed2', 0, '[{\"name\":\"hunger\",\"val\":1000000,\"percent\":100.0},{\"name\":\"thirst\",\"val\":1000000,\"percent\":100.0},{\"name\":\"drunk\",\"val\":0,\"percent\":0.0},{\"name\":\"drug\",\"val\":0,\"percent\":0.0}]', 0, '2025-12-31 02:57:57', 'Pablo', 'Delrulio', '2000-02-01', '0', '189', 1, '[]', '[]', NULL, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Structure de la table `users_tig`
--

CREATE TABLE `users_tig` (
  `id` int NOT NULL,
  `identifier` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `time` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `author` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `job` varchar(255) COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `user_licenses`
--

CREATE TABLE `user_licenses` (
  `id` int NOT NULL,
  `type` varchar(60) COLLATE utf8mb4_bin NOT NULL,
  `owner` varchar(60) COLLATE utf8mb4_bin NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- --------------------------------------------------------

--
-- Structure de la table `vbank`
--

CREATE TABLE `vbank` (
  `id` int NOT NULL,
  `identifier` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0',
  `history` longtext COLLATE utf8mb4_general_ci NOT NULL,
  `bankid` longtext COLLATE utf8mb4_general_ci NOT NULL,
  `Virement` longtext COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vbank`
--

INSERT INTO `vbank` (`id`, `identifier`, `history`, `bankid`, `Virement`) VALUES
(1, 'license:222c46fedf9fa74880e63ab731894be3fb57c497', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"03.03.2022 - 13:08:06\",\"type\":\"Création\"}}', 'IBAN-1646312886', NULL),
(2, 'license:676c7031a7e3c4b1fe6d534ebfbfe1ae4af49d16', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"type\":\"Création\",\"amount\":0,\"Date\":\"03.03.2022 - 13:18:46\",\"Title\":\"Création du Compte\"}}', 'IBAN-1646313526', NULL),
(3, 'license:840e2bbb73619a49876134911513efcd6e975c6c', '{\"1\":{\"Title\":\"Création du Compte\",\"Date\":\"03.03.2022 - 13:46:51\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"type\":\"Création\"}}', 'IBAN-1646315211', NULL),
(4, 'license:3b812812ad65ece34da9a84c3d7aa2bb1257f2a7', '{\"1\":{\"Title\":\"Création du Compte\",\"type\":\"Création\",\"Date\":\"03.03.2022 - 14:10:42\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0}}', 'IBAN-1646316642', NULL),
(5, 'license:afaba2ad9bca10e18363adece691fdecbcababee', '{\"1\":{\"Date\":\"04.03.2022 - 13:09:17\",\"type\":\"Création\",\"amount\":0,\"Title\":\"Création du Compte\",\"Description\":\"Ouverture d\'un compte Bancaire.\"}}', 'IBAN-1646399357', NULL),
(6, 'license:d7b1a029b3e0d095633bb27dc9f31e5ac130ca62', '{\"1\":{\"amount\":0,\"Date\":\"04.03.2022 - 22:45:48\",\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\"}}', 'IBAN-1646433948', NULL),
(7, 'license:23eb122fbc001b121afd443767a90c32ce8d58b2', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"05.03.2022 - 00:35:12\",\"type\":\"Création\"}}', 'IBAN-1646440512', NULL),
(8, 'license:17f2b8a5c19f26e1e136c114dfe204bc708ee87e', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"type\":\"Création\",\"amount\":0,\"Date\":\"05.03.2022 - 00:38:20\",\"Title\":\"Création du Compte\"}}', 'IBAN-1646440700', NULL),
(9, 'license:74722e5d83c23057107334ec41dc2c5539369201', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"type\":\"Création\",\"amount\":0,\"Date\":\"05.03.2022 - 08:38:50\",\"Title\":\"Création du Compte\"}}', 'IBAN-1646469530', NULL),
(10, 'license:1543c0430465cae3b2710706634749fbcfd7c567', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"05.03.2022 - 10:04:20\",\"type\":\"Création\"}}', 'IBAN-1646474660', NULL),
(11, 'license:f5788bac547691e212faa76eb9e71f46da796d50', '{\"1\":{\"Title\":\"Création du Compte\",\"type\":\"Création\",\"Date\":\"05.03.2022 - 10:07:21\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0}}', 'IBAN-1646474841', NULL),
(12, 'license:5b545b297e209cdabcc80b0d8644571fd87de093', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"05.03.2022 - 12:08:59\",\"type\":\"Création\"}}', 'IBAN-1646482139', NULL),
(13, 'license:d9725f63efe9d0d53a0883c78cb79f14db186780', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"05.03.2022 - 12:13:06\",\"type\":\"Création\"}}', 'IBAN-1646482386', NULL),
(14, 'license:8b2dd308c0f10d32e5a363e13f7d1d016161668f', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"05.03.2022 - 13:29:37\",\"type\":\"Création\"}}', 'IBAN-1646486977', NULL),
(15, 'license:a0e80b30c01ed966e9e9af43980587c7b526bace', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"05.03.2022 - 18:17:23\",\"type\":\"Création\"}}', 'IBAN-1646504243', NULL),
(16, 'license:d4e9cbeaacc2b0ce1d1c8ce7f53ee71b8183867c', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"05.03.2022 - 19:26:58\",\"type\":\"Création\"}}', 'IBAN-1646508418', NULL),
(17, 'license:efd104ae3a0f12892e88c17f63c0d08cd80f2b49', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"05.03.2022 - 19:37:11\",\"type\":\"Création\"}}', 'IBAN-1646509031', NULL),
(18, 'license:17d8f0a88f62475eac0559a09a7a06355ba9b2ec', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"05.03.2022 - 21:52:09\",\"type\":\"Création\"}}', 'IBAN-1646517129', NULL),
(19, 'license:6b4fbc2620bf3fe8fe144b88ecde934e50ac49c9', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"06.03.2022 - 01:01:53\",\"type\":\"Création\"}}', 'IBAN-1646528513', NULL),
(20, 'license:44730fcd67e41f528b8916be9fdce29964561530', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"06.03.2022 - 01:04:08\",\"type\":\"Création\"}}', 'IBAN-1646528648', NULL),
(21, 'license:07091b465a1b387c8a6d6968d6c841dcaeae2d57', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"06.03.2022 - 02:13:41\",\"type\":\"Création\"}}', 'IBAN-1646532821', NULL),
(22, 'license:cf5d504aad8457773961dd28b37ce37e16db8923', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"06.03.2022 - 02:55:11\",\"type\":\"Création\"}}', 'IBAN-1646535311', NULL),
(23, 'license:c33553d0860e631beb5586d1947bb3ccdbdb4ce4', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"06.03.2022 - 09:33:51\",\"type\":\"Création\"}}', 'IBAN-1646559231', NULL),
(24, 'license:ca1d88031d0d25bcca2ab217cbe329177c25cff9', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"06.03.2022 - 15:52:24\",\"type\":\"Création\"}}', 'IBAN-1646581944', NULL),
(25, 'license:5203102308639a36633cfce5e4a45ac9bab82a93', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"06.03.2022 - 18:13:07\",\"type\":\"Création\"}}', 'IBAN-1646590387', NULL),
(26, 'license:63b7781c2a1bc429c70113ad64f73ae69ce0a789', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"06.03.2022 - 20:14:45\",\"type\":\"Création\"}}', 'IBAN-1646597685', NULL),
(27, 'license:5e6b1e3c9912bca10bbf0a2258cab659480d5e21', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"06.03.2022 - 20:46:18\",\"type\":\"Création\"}}', 'IBAN-1646599578', NULL),
(28, 'license:42514dcf5b5f34d8d249a01f66ccdffec3f74833', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"06.03.2022 - 21:55:31\",\"type\":\"Création\"}}', 'IBAN-1646603731', NULL),
(29, 'license:e8a849c4ebb701efb4f651c6bf596d80252cad42', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"07.03.2022 - 00:04:32\",\"type\":\"Création\"}}', 'IBAN-1646611472', NULL),
(30, 'license:f57cbaffc364f51fc165f2a95dad2b59b43aa3c8', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"07.03.2022 - 10:47:16\",\"type\":\"Création\"}}', 'IBAN-1646650036', NULL),
(31, 'license:33d330aae30191a8ae6fe52c2015d5a6576f3d59', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"07.03.2022 - 16:25:53\",\"type\":\"Création\"}}', 'IBAN-1646670353', NULL),
(32, 'license:08bee9809c7e7f8bfdcd7b840afc08b58279f780', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"07.03.2022 - 16:40:50\",\"type\":\"Création\"}}', 'IBAN-1646671250', NULL),
(33, 'license:5839bd0648b6519bb31d5e395685d41d4b96cf35', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"07.03.2022 - 16:57:28\",\"type\":\"Création\"}}', 'IBAN-1646672248', NULL),
(34, 'license:80019cf46f860351cfd79dc1d174f4e52f234034', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"07.03.2022 - 17:44:09\",\"type\":\"Création\"}}', 'IBAN-1646675049', NULL),
(35, 'license:e7b2e663bbf6a24a12b25818893434f812b9c45b', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"08.03.2022 - 01:12:59\",\"type\":\"Création\"}}', 'IBAN-1646701979', NULL),
(36, 'license:4108734c231c4d79813c0dba44ad9533d79b2bcc', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"08.03.2022 - 08:34:26\",\"type\":\"Création\"}}', 'IBAN-1646728466', NULL),
(37, 'license:4e2da4d529d2cc3f1c508c526e90d3158e921f98', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"08.03.2022 - 14:00:10\",\"type\":\"Création\"}}', 'IBAN-1646748010', NULL),
(38, 'license:0952c2029a28248d70dc879a193c1b91aa5475fe', '{\"1\":{\"Date\":\"08.03.2022 - 21:56:56\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0,\"Title\":\"Création du Compte\",\"type\":\"Création\"}}', 'IBAN-1646776616', NULL),
(39, 'license:12374a551ca0dc681bed492fe4cd1fc449f757c7', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"Date\":\"13.03.2022 - 21:33:56\",\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\"}}', 'IBAN-1647207236', NULL),
(40, 'license:b1f8da2dd131b53847efd3ffcba54272e195074c', '{\"1\":{\"Title\":\"Création du Compte\",\"Date\":\"01.09.2023 - 13:34:34\",\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0}}', 'IBAN-1693568074', NULL),
(41, 'license:bcf52b6beeca38a9415fcb001978f2f119bc6d8b', '{\"1693664175 1433\":{\"Date\":\"02.09.2023 - 16:16:15\",\"type\":\"Retrait\",\"Title\":\"Retrait ATM\",\"Description\":\"Retrait d\'argent dans un ATM\",\"amount\":\"~r~-173025~s~\"},\"1\":{\"Date\":\"01.09.2023 - 13:36:10\",\"type\":\"Création\",\"Title\":\"Création du Compte\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0}}', 'IBAN-1693568170', NULL),
(42, 'license:d79af36dac56042d5efa0895eacbc0f820bcf30e', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"01.09.2023 - 13:36:14\",\"type\":\"Création\",\"Title\":\"Création du Compte\",\"amount\":0}}', 'IBAN-1693568174', NULL),
(43, 'license:01f8848f0c65c6b3def380dedd07462111424884', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\",\"Date\":\"01.09.2023 - 13:38:05\",\"amount\":0,\"type\":\"Création\"}}', 'IBAN-1693568285', NULL),
(44, 'license:8f3efc571db0bc5610899318d4b9f0957638ae93', '{\"1\":{\"type\":\"Création\",\"amount\":0,\"Title\":\"Création du Compte\",\"Date\":\"01.09.2023 - 13:39:16\",\"Description\":\"Ouverture d\'un compte Bancaire.\"}}', 'IBAN-1693568356', NULL),
(45, 'license:a240bbbbd6d623670a868e36866e5fcf5cfce7db', '{\"1\":{\"Title\":\"Création du Compte\",\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0,\"Date\":\"01.09.2023 - 13:40:06\"}}', 'IBAN-1693568406', NULL),
(46, 'license:999cb2d6b4034cd9512270362d025923b3241b37', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\",\"Date\":\"01.09.2023 - 13:44:42\",\"amount\":0,\"type\":\"Création\"}}', 'IBAN-1693568682', NULL),
(47, 'license:ae51be4e2aa5bfe5b53c0dfc72dd8890ad46b1ab', '{\"1\":{\"Title\":\"Création du Compte\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"01.09.2023 - 16:07:21\",\"amount\":0,\"type\":\"Création\"}}', 'IBAN-1693577241', NULL),
(48, 'license:48eb2a3e02fe5ad9de7f7547191fd460bbc6c39d', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\",\"Date\":\"02.09.2023 - 13:33:56\",\"amount\":0,\"type\":\"Création\"},\"1694286640 3340\":{\"Description\":\"Retrait d\'argent dans un ATM\",\"Title\":\"Retrait ATM\",\"Date\":\"09.09.2023 - 21:10:40\",\"amount\":\"~r~-500000~s~\",\"type\":\"Retrait\"}}', 'IBAN-1693654436', NULL),
(49, 'license:9dea66e5caaa571002b1307512c5b573bb839ac8', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\",\"Date\":\"02.09.2023 - 19:32:05\",\"amount\":0,\"type\":\"Création\"}}', 'IBAN-1693675925', NULL),
(50, 'license:346acf14b8bf5c712671f02aae47799a4b05df7d', '{\"1\":{\"amount\":0,\"Title\":\"Création du Compte\",\"Date\":\"07.09.2023 - 09:36:28\",\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\"}}', 'IBAN-1694072188', NULL),
(51, 'license:ee06581f3257f92d47c668d187dcba72f07fa670', '{\"1\":{\"Title\":\"Création du Compte\",\"type\":\"Création\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"08.09.2023 - 20:11:17\"}}', 'IBAN-1694196677', NULL),
(52, 'license:5e6a800478d254b22318d4ee8cc2fa5983738b77', '{\"1\":{\"Title\":\"Création du Compte\",\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0,\"Date\":\"08.09.2023 - 20:12:10\"}}', 'IBAN-1694196730', NULL),
(53, 'license:9c03986b5c779d1c28a368ab1177d7f4499a502f', '{\"1\":{\"Date\":\"08.09.2023 - 20:16:59\",\"type\":\"Création\",\"Title\":\"Création du Compte\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0}}', 'IBAN-1694197019', NULL),
(54, 'license:b33919d54572f8a8ba7f31e2d4b12cdaff6acf4a', '{\"1\":{\"type\":\"Création\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"08.09.2023 - 20:25:36\",\"Title\":\"Création du Compte\"}}', 'IBAN-1694197536', NULL),
(55, 'license:8b7f4a127fe449c0e19217055c530b268cfc8d49', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\",\"Date\":\"09.09.2023 - 19:10:59\",\"amount\":0,\"type\":\"Création\"}}', 'IBAN-1694279459', NULL),
(56, 'license:11a5e110451a188671ac70acf0fbb7d6cf103446', '{\"1\":{\"type\":\"Création\",\"Title\":\"Création du Compte\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"09.09.2023 - 19:15:31\",\"amount\":0}}', 'IBAN-1694279731', NULL),
(57, 'license:d95018e2b7b13ef05f32e8d6e9103991cae93f47', '{\"1\":{\"Title\":\"Création du Compte\",\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0,\"Date\":\"09.09.2023 - 19:31:46\"}}', 'IBAN-1694280706', NULL),
(58, 'license:f9fdb2052fc009eece7ec33394a33363048ca6ac', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"type\":\"Création\",\"amount\":0,\"Date\":\"09.09.2023 - 19:35:35\",\"Title\":\"Création du Compte\"}}', 'IBAN-1694280935', NULL),
(59, 'license:5913c9c0a2383b2bbb17a943e19a9a7859c4b781', '{\"1\":{\"Date\":\"09.09.2023 - 19:45:55\",\"type\":\"Création\",\"Title\":\"Création du Compte\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0}}', 'IBAN-1694281555', NULL),
(60, 'license:891c698c56f892fa5b3e4faae0a228427e00ef79', '{\"1\":{\"Title\":\"Création du Compte\",\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0,\"Date\":\"09.09.2023 - 19:55:00\"}}', 'IBAN-1694282100', NULL),
(61, 'license:165d5c7145fad94ddcce47c29e8a5286cdb78228', '{\"1\":{\"Title\":\"Création du Compte\",\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0,\"Date\":\"09.09.2023 - 20:05:05\"}}', 'IBAN-1694282705', NULL),
(62, 'license:82d5b75a7147b642889f5a6e7caf0ba9b7cf5d1a', '{\"1\":{\"Title\":\"Création du Compte\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"type\":\"Création\",\"Date\":\"09.09.2023 - 20:30:53\",\"amount\":0}}', 'IBAN-1694284253', NULL),
(63, 'license:d3cba8cb1794d74204b5e953fb1bf089bdc17293', '{\"1\":{\"Title\":\"Création du Compte\",\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0,\"Date\":\"09.09.2023 - 20:42:33\"}}', 'IBAN-1694284953', NULL),
(64, 'license:611429849fd2c2a374aa9968ed57eaacf05da3d9', '{\"1\":{\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"10.09.2023 - 12:31:55\",\"Title\":\"Création du Compte\",\"amount\":0}}', 'IBAN-1694345515', NULL),
(65, 'license:b0c4de03fa544590a349d27e19c3c98856e5f446', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\",\"Date\":\"10.09.2023 - 16:29:16\",\"amount\":0,\"type\":\"Création\"}}', 'IBAN-1694359756', NULL),
(66, 'license:c61d547fe006eb0e70a976d7869528863f5cade7', '{\"1\":{\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0,\"Date\":\"10.09.2023 - 16:34:02\",\"Title\":\"Création du Compte\"}}', 'IBAN-1694360042', NULL),
(67, 'license:3aa062f5ba4f99929980851a973c0857c9252c1c', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\",\"Date\":\"10.09.2023 - 16:46:46\",\"amount\":0,\"type\":\"Création\"}}', 'IBAN-1694360806', NULL),
(68, 'license:40126a5511d8e55ecdf0370af6d693bc40050180', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\",\"Date\":\"10.09.2023 - 19:40:03\",\"amount\":0,\"type\":\"Création\"}}', 'IBAN-1694371203', NULL),
(69, 'license:824f9aaa4aad7650ebc7bd71f52caf21cba74cc8', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\",\"Date\":\"10.09.2023 - 19:42:32\",\"amount\":0,\"type\":\"Création\"}}', 'IBAN-1694371352', NULL),
(70, 'license:79e72fd6e9d138540e6464959ccfef0eb3616279', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\",\"Date\":\"10.09.2023 - 19:55:16\",\"amount\":0,\"type\":\"Création\"}}', 'IBAN-1694372116', NULL),
(71, 'license:758c70a176d12b7f74a3eea0fe9266129a5a2b3b', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\",\"Date\":\"10.09.2023 - 21:22:30\",\"amount\":0,\"type\":\"Création\"}}', 'IBAN-1694377350', NULL),
(72, 'license:92d1733ec239bae294d4feddca868149c97359ba', '{\"1\":{\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"11.09.2023 - 16:52:54\",\"Title\":\"Création du Compte\",\"amount\":0}}', 'IBAN-1694447574', NULL),
(73, 'license:46c96f00eb3bb7171d91b0a21b241c95435544a8', '{\"1\":{\"amount\":0,\"Title\":\"Création du Compte\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"type\":\"Création\",\"Date\":\"11.09.2023 - 17:01:31\"}}', 'IBAN-1694448091', NULL),
(74, 'license:f8fce620e02728f87a68e9ef0f63c440a1b534d2', '{\"1\":{\"Title\":\"Création du Compte\",\"amount\":0,\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"12.09.2023 - 18:06:39\"}}', 'IBAN-1694538399', NULL),
(75, 'license:b582ecf2a3bacadac01a421308556d3e2fad5901', '{\"1\":{\"Title\":\"Création du Compte\",\"Date\":\"13.09.2023 - 01:05:04\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"type\":\"Création\",\"amount\":0}}', 'IBAN-1694563504', NULL),
(76, 'license:6d6acb0b9ebbcdbf53ff878b1143701ca0a9bb5b', '{\"1\":{\"amount\":0,\"Title\":\"Création du Compte\",\"Date\":\"14.09.2023 - 11:58:48\",\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\"}}', 'IBAN-1694689128', NULL),
(77, 'license:b9c6ccfa09b8c4ada614bddb28c3653e05b26c29', '{\"1\":{\"Title\":\"Création du Compte\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"amount\":0,\"Date\":\"14.09.2023 - 13:22:31\",\"type\":\"Création\"}}', 'IBAN-1694694151', NULL),
(78, 'license:e005c9ef708ec4ed738f7e19025284915b24be86', '{\"1\":{\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Title\":\"Création du Compte\",\"amount\":0,\"type\":\"Création\",\"Date\":\"15.09.2023 - 17:37:37\"}}', 'IBAN-1694795857', NULL),
(79, 'license:17f321280a311afa676cd4260573a85363932c82', '{\"1\":{\"type\":\"Création\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"26.12.2023 - 19:00:49\",\"Title\":\"Création du Compte\"}}', 'IBAN-1703613649', NULL),
(92, 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', '{\"1\":{\"Title\":\"Création du Compte\",\"type\":\"Création\",\"Date\":\"08.02.2025 - 15:23:06\",\"amount\":0,\"Description\":\"Ouverture d\'un compte Bancaire.\"}}', 'IBAN-1739028186', NULL),
(95, 'license:4133ec7e123b91f87741530869df99d6366ab0d6', '{\"1\":{\"type\":\"Création\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"Date\":\"22.03.2025 - 02:35:55\",\"amount\":0,\"Title\":\"Création du Compte\"}}', 'IBAN-1742607355', NULL),
(96, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '{\"1\":{\"amount\":0,\"Date\":\"25.08.2024 - 17:44:32\",\"Title\":\"Création du Compte\",\"Description\":\"Ouverture d\'un compte Bancaire.\",\"type\":\"Création\"}}', 'IBAN-1724600672', NULL),
(97, 'license:063e3a07b7e5204a49b87053d2fd572a89659886', '{\"1\":{\"type\":\"Création\",\"Title\":\"Création du Compte\",\"amount\":0,\"Date\":\"08.02.2025 - 00:41:46\",\"Description\":\"Ouverture d\'un compte Bancaire.\"}}', 'IBAN-1738975306', NULL);

-- --------------------------------------------------------

--
-- Structure de la table `vchest`
--

CREATE TABLE `vchest` (
  `id` int NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `ownerId` int DEFAULT NULL,
  `ownerName` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `weight` int NOT NULL,
  `upgrade` text COLLATE utf8mb4_general_ci,
  `model` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `pos` varchar(1000) COLLATE utf8mb4_general_ci NOT NULL,
  `rotation` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vchest`
--

INSERT INTO `vchest` (`id`, `name`, `ownerId`, `ownerName`, `weight`, `upgrade`, `model`, `pos`, `rotation`, `date`) VALUES
(19, 'vSuperette', 1, 'null', 100, '{}', 'prop_mil_crate_01', '{\"x\":-1219.7535400390626,\"y\":-915.9859008789063,\"z\":10.90706443786621}', '{\"x\":0.0,\"y\":-0.0,\"z\":0.0}', '2024-09-17 21:12:05'),
(20, 'Test', 1, 'null', 25, '[]', 'prop_drop_armscrate_01b', '{\"x\":-629.3187866210938,\"y\":196.3958740234375,\"z\":69.1148681640625}', '{\"x\":10.37075233459472,\"y\":-4.38687181472778,\"z\":-0.39830109477043}', '2024-10-01 19:56:07');

-- --------------------------------------------------------

--
-- Structure de la table `vclothes`
--

CREATE TABLE `vclothes` (
  `id` int NOT NULL,
  `type` varchar(60) COLLATE utf8mb4_general_ci NOT NULL,
  `identifier` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `name` longtext COLLATE utf8mb4_general_ci,
  `data` longtext COLLATE utf8mb4_general_ci,
  `trunk` varchar(20) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vclothes`
--

INSERT INTO `vclothes` (`id`, `type`, `identifier`, `name`, `data`, `trunk`) VALUES
(996038, 'top', 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'Test', '{\"decals_2\":0,\"arms\":184,\"tshirt_1\":15,\"tshirt_2\":0,\"torso_2\":0,\"torso_1\":589,\"decals_1\":0}', '0'),
(996039, 'top', 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'OEOEE', '{\"decals_2\":0,\"arms\":184,\"tshirt_1\":15,\"decals_1\":0,\"tshirt_2\":0,\"torso_1\":589,\"torso_2\":0}', '0'),
(996040, 'pants', 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'OEOEE', '{\"pants_2\":0,\"pants_1\":289}', '0'),
(996041, 'shoes', 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'OEOEE', '{\"shoes_1\":303,\"shoes_2\":0}', '0'),
(996042, 'top', 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'TEST', '{\"decals_2\":0,\"arms\":184,\"tshirt_1\":15,\"decals_1\":0,\"tshirt_2\":0,\"torso_1\":589,\"torso_2\":0}', '0'),
(996043, 'pants', 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'TEST', '{\"pants_2\":0,\"pants_1\":289}', '0'),
(996044, 'shoes', 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'TEST', '{\"shoes_1\":283,\"shoes_2\":4}', '0'),
(996045, 'glasses', 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'Lunette', '{\"glasses_2\":5,\"glasses_1\":70}', '0'),
(996046, 'glasses', 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', 'Lulu', '{\"glasses_2\":0,\"glasses_1\":30}', '0'),
(996047, 'glasses', 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', NULL, '{\"glasses_2\":0,\"glasses_1\":30}', '0'),
(996097, 'top', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'New', '{\"tshirt_1\":15,\"torso_1\":572,\"decals_2\":0,\"decals_1\":0,\"torso_2\":2,\"tshirt_2\":0,\"arms\":19}', '0'),
(996098, 'pants', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'New', '{\"pants_2\":0,\"pants_1\":169}', '0'),
(996099, 'shoes', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'New', '{\"shoes_1\":117,\"shoes_2\":0}', '0'),
(996100, 'mask', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '.', '{\"mask_2\":0,\"mask_1\":169}', '0'),
(996101, 'ear', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Airpods', '{\"ears_1\":41,\"ears_2\":0}', '0'),
(996102, 'neck', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Trap', '{\"chain_2\":0,\"chain_1\":200}', '0'),
(996103, 'neck', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Holster 1', '{\"chain_2\":0,\"chain_1\":186}', '0'),
(996104, 'hat', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Gucci', '{\"helmet_1\":181,\"helmet_2\":0}', '0'),
(996105, 'glasses', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '.', '{\"glasses_1\":45,\"glasses_2\":0}', '0'),
(996106, 'bag', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', NULL, '{\"bags_2\":0,\"bags_1\":39}', '0'),
(996107, 'bag', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Test', '{\"bags_2\":0,\"bags_1\":40}', '0'),
(996108, 'top', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Grise', '{\"arms\":4,\"tshirt_2\":0,\"torso_1\":14,\"decals_1\":0,\"torso_2\":7,\"decals_2\":0,\"tshirt_1\":15}', '0'),
(996109, 'shoes', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Grise', '{\"shoes_1\":1,\"shoes_2\":0}', '0'),
(996110, 'pants', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Grise', '{\"pants_2\":1,\"pants_1\":1}', '0'),
(996111, 'gillet', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'GPB Noir', '{\"bproof_2\":1,\"bproof_1\":1}', '0'),
(996112, 'top', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Test', '{\"arms\":4,\"tshirt_1\":15,\"decals_1\":0,\"torso_2\":1,\"tshirt_2\":0,\"torso_1\":14,\"decals_2\":0}', '0'),
(996113, 'pants', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Test', '{\"pants_1\":5,\"pants_2\":0}', '0'),
(996114, 'shoes', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Test', '{\"shoes_2\":0,\"shoes_1\":6}', '0'),
(996115, 'top', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Chill 2', '{\"torso_1\":7,\"torso_2\":0,\"decals_2\":0,\"tshirt_1\":0,\"arms\":4,\"tshirt_2\":0,\"decals_1\":0}', '0'),
(996116, 'shoes', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Chill 2', '{\"shoes_1\":6,\"shoes_2\":0}', '0'),
(996117, 'pants', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Chill 2', '{\"pants_2\":0,\"pants_1\":5}', '0'),
(996118, 'pants', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Pour le monde', '{\"pants_2\":2,\"pants_1\":0}', '0'),
(996119, 'pants', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Short', '{\"pants_1\":6,\"pants_2\":0}', '0'),
(996120, 'top', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'test', '{\"decals_2\":0,\"arms\":4,\"tshirt_2\":0,\"torso_1\":7,\"decals_1\":0,\"tshirt_1\":0,\"torso_2\":0}', '0'),
(996121, 'pants', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'test', '{\"pants_1\":6,\"pants_2\":0}', '0'),
(996122, 'shoes', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'test', '{\"shoes_2\":0,\"shoes_1\":6}', '0'),
(996123, 'pants', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'test', '{\"pants_2\":1,\"pants_1\":16}', '0'),
(996124, 'top', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'test', '{\"torso_1\":8,\"arms\":8,\"decals_1\":0,\"decals_2\":0,\"tshirt_1\":15,\"torso_2\":0,\"tshirt_2\":0}', '0'),
(996125, 'pants', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'test', '{\"pants_2\":1,\"pants_1\":16}', '0'),
(996126, 'shoes', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'test', '{\"shoes_1\":0,\"shoes_2\":0}', '0'),
(996127, 'top', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Juck', '{\"torso_2\":0,\"tshirt_2\":0,\"arms\":1,\"decals_1\":0,\"decals_2\":0,\"tshirt_1\":2,\"torso_1\":6}', '0'),
(996128, 'top', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Test', '{\"decals_1\":0,\"tshirt_1\":2,\"decals_2\":0,\"tshirt_2\":0,\"torso_1\":6,\"torso_2\":0,\"arms\":1}', '0'),
(996129, 'pants', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Test', '{\"pants_2\":1,\"pants_1\":16}', '0'),
(996130, 'shoes', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Test', '{\"shoes_2\":0,\"shoes_1\":0}', '0'),
(996131, 'top', 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'test', '{\"torso_2\":0,\"tshirt_2\":0,\"tshirt_1\":4,\"decals_1\":0,\"decals_2\":0,\"arms\":1,\"torso_1\":4}', '0'),
(996132, 'top', 'license:063e3a07b7e5204a49b87053d2fd572a89659886', 'Pablo', '{\"arms\":15,\"torso_1\":55,\"tshirt_2\":0,\"tshirt_1\":15,\"torso_2\":0,\"decals_1\":0,\"decals_2\":0}', '0'),
(996134, 'top', 'license:063e3a07b7e5204a49b87053d2fd572a89659886', 'Pablo', '{\"decals_2\":0,\"arms\":4,\"tshirt_2\":0,\"torso_2\":0,\"tshirt_1\":3,\"torso_1\":3,\"decals_1\":0}', '0'),
(996135, 'pants', 'license:063e3a07b7e5204a49b87053d2fd572a89659886', 'Pablo', '{\"pants_2\":0,\"pants_1\":1}', '0'),
(996136, 'shoes', 'license:063e3a07b7e5204a49b87053d2fd572a89659886', 'Pablo', '{\"shoes_2\":0,\"shoes_1\":6}', '0'),
(996137, 'top', 'license:063e3a07b7e5204a49b87053d2fd572a89659886', 'Pablo', '{\"decals_2\":0,\"arms\":15,\"tshirt_2\":0,\"torso_2\":0,\"tshirt_1\":15,\"torso_1\":15,\"decals_1\":0}', '0'),
(996138, 'shoes', 'license:063e3a07b7e5204a49b87053d2fd572a89659886', 'Pablo', '{\"shoes_2\":0,\"shoes_1\":34}', '0'),
(996139, 'pants', 'license:063e3a07b7e5204a49b87053d2fd572a89659886', 'Pablo', '{\"pants_2\":0,\"pants_1\":21}', '0'),
(996140, 'top', 'license:063e3a07b7e5204a49b87053d2fd572a89659886', NULL, '{\"tshirt_1\":15,\"torso_2\":0,\"decals_1\":0,\"decals_2\":0,\"arms\":15,\"tshirt_2\":0,\"torso_1\":15}', '0'),
(996141, 'shoes', 'license:063e3a07b7e5204a49b87053d2fd572a89659886', NULL, '{\"shoes_2\":0,\"shoes_1\":34}', '0'),
(996142, 'pants', 'license:063e3a07b7e5204a49b87053d2fd572a89659886', NULL, '{\"pants_2\":0,\"pants_1\":61}', '0');

-- --------------------------------------------------------

--
-- Structure de la table `vehicles`
--

CREATE TABLE `vehicles` (
  `model` varchar(60) COLLATE utf8mb4_bin NOT NULL,
  `name` varchar(60) COLLATE utf8mb4_bin NOT NULL,
  `price` int NOT NULL,
  `category` varchar(60) COLLATE utf8mb4_bin DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

--
-- Déchargement des données de la table `vehicles`
--

INSERT INTO `vehicles` (`model`, `name`, `price`, `category`) VALUES
('adder', 'Adder', 500000, 'super'),
('akuma', 'Akuma', 102000, 'motorcycles'),
('alpha', 'Alpha', 142500, 'sports'),
('asbo', 'Asbo', 68000, 'compacts'),
('asea', 'Asea', 18750, 'sedans'),
('autarch', 'Autarch', 900000, 'super'),
('avarus', 'Avarus', 125000, 'motorcycles'),
('bagger', 'Bagger', 65000, 'motorcycles'),
('baller2', 'Baller', 50000, 'suvs'),
('baller3', 'Baller Sport', 75000, 'suvs'),
('banshee', 'Banshee', 105000, 'sports'),
('banshee2', 'Banshee 900R', 125000, 'super'),
('bati', 'Bati 801', 128000, 'motorcycles'),
('bestiagts', 'Bestia GTS', 187500, 'sports'),
('bf400', 'BF400', 100000, 'motorcycles'),
('bfinjection', 'Bf Injection', 15000, 'offroad'),
('bifta', 'Bifta', 15000, 'offroad'),
('bison', 'Bison', 45000, 'vans'),
('blade', 'Blade', 22500, 'muscle'),
('blazer', 'Blazer', 60000, 'motorcycles'),
('blazer3', 'Blazer Hot Road', 75000, 'motorcycles'),
('blazer4', 'Blazer Sport', 100000, 'motorcycles'),
('blista', 'Blista', 10500, 'compacts'),
('blista2', 'Blista Sport', 28000, 'sports'),
('bmx', 'BMX (velo)', 150, 'motorcycles'),
('bobcatxl', 'Bobcat XL', 32000, 'vans'),
('brawler', 'Brawler', 142500, 'offroad'),
('brioso', 'Brioso R/A', 30000, 'compacts'),
('btype', 'Btype', 110000, 'sportsclassics'),
('btype2', 'Btype Hotroad', 155000, 'sportsclassics'),
('btype3', 'Btype Luxe', 120000, 'sportsclassics'),
('buccaneer', 'Buccaneer', 27000, 'muscle'),
('buccaneer2', 'Buccaneer Rider', 33750, 'muscle'),
('buffalo', 'Buffalo', 61500, 'sports'),
('buffalo2', 'Buffalo S', 90000, 'sports'),
('bullet', 'Bullet', 90000, 'super'),
('burrito3', 'Burrito', 19000, 'vans'),
('calico', 'Calico', 65000, 'sports'),
('camper', 'Camper', 35000, 'vans'),
('caracara2', 'Caracara', 1500000, 'offroad'),
('carbonizzare', 'Carbonizzare', 112500, 'sports'),
('carbonrs', 'Carbon RS', 120000, 'motorcycles'),
('casco', 'Casco', 30000, 'sportsclassics'),
('cavalcade2', 'Cavalcade', 40000, 'suvs'),
('cheburek', 'Cheburek', 24000, 'sportsclassics'),
('cheetah', 'Cheetah', 22000, 'super'),
('cheetah2', 'Cheetah Retro', 440000, 'sportsclassics'),
('chimera', 'Chimera', 88500, 'motorcycles'),
('chino', 'Chino', 20250, 'muscle'),
('chino2', 'Chino Luxe', 27000, 'muscle'),
('cliffhanger', 'Cliffhanger', 90000, 'motorcycles'),
('club', 'Club', 48000, 'compacts'),
('cogcabrio', 'Cognoscenti Cabrio', 55000, 'coupes'),
('cognoscenti', 'Cognoscenti', 52500, 'sedans'),
('comet2', 'Comet', 112500, 'sports'),
('comet4', 'Comet Safari', 600000, 'sports'),
('comet5', 'Comet GT', 1200000, 'sports'),
('comet6', 'Comet 6', 55000, 'sports'),
('contender', 'Contender', 135000, 'suvs'),
('coquette', 'Coquette', 97500, 'sports'),
('coquette2', 'Coquette Classic', 40000, 'sportsclassics'),
('coquette3', 'Coquette BlackFin', 63750, 'muscle'),
('cruiser', 'Cruiser (velo)', 180, 'motorcycles'),
('cyclone', 'Cyclone', 1890000, 'super'),
('cypher', 'Cypher', 90000, 'sports'),
('daemon', 'Daemon', 75000, 'motorcycles'),
('daemon2', 'Daemon High', 28500, 'motorcycles'),
('defiler', 'Defiler', 75000, 'motorcycles'),
('diabolus', 'Diabolus', 140000, 'motorcycles'),
('diabolus2', 'Diabolus Custom', 150000, 'motorcycles'),
('dinghy3', 'Dinghy', 15000000, 'superboat'),
('dominator', 'Dominator', 88000, 'muscle'),
('dominator3', 'Dominator GTX Vapid', 292500, 'muscle'),
('dominator7', 'Dominator 7', 70000, 'muscle'),
('double', 'Double T', 100500, 'motorcycles'),
('drafter', '8F Drafter', 1500000, 'sports'),
('dubsta', 'Dubsta', 45000, 'suvs'),
('dubsta2', 'Dubsta Luxuary', 60000, 'suvs'),
('dubsta3', 'Bubsta 6x6', 266250, 'offroad'),
('dukes', 'Dukes', 31500, 'muscle'),
('dune', 'Dune Buggy', 22500, 'offroad'),
('elegy', 'Elegy Retro Custom', 675000, 'sports'),
('elegy2', 'Elegy', 38500, 'sports'),
('ellie', 'Ellie', 64000, 'muscle'),
('emperor', 'Emperor', 11250, 'sedans'),
('enduro', 'Enduro', 50000, 'motorcycles'),
('entityxf', 'Entity XF', 210000, 'super'),
('esskey', 'Esskey', 60000, 'motorcycles'),
('euros', 'Euros', 80000, 'sports'),
('everon', 'Everon', 120000, 'offroad'),
('exemplar', 'Exemplar', 52500, 'coupes'),
('f620', 'F620', 33000, 'coupes'),
('faction', 'Faction', 22500, 'muscle'),
('faction2', 'Faction Rider', 33750, 'muscle'),
('faction3', 'Faction XL', 63750, 'muscle'),
('faggio', 'Faggio', 17500, 'motorcycles'),
('faggio2', 'Vespa', 15000, 'motorcycles'),
('fcr', 'FCR 1000', 165000, 'motorcycles'),
('felon', 'Felon', 47250, 'coupes'),
('felon2', 'Felon GT', 47250, 'coupes'),
('feltzer2', 'Feltzer', 57750, 'sports'),
('feltzer3', 'Stirling GT', 65000, 'sportsclassics'),
('fixter', 'Fixter (velo)', 50, 'motorcycles'),
('fmj', 'FMJ', 185000, 'super'),
('fq2', 'Fhantom', 12500, 'suvs'),
('freecrawler', 'Freecrawler', 120000, 'offroad'),
('fugitive', 'Fugitive', 30000, 'sedans'),
('furoregt', 'Furore GT', 67500, 'sports'),
('fusilade', 'Fusilade', 60000, 'sports'),
('futo', 'Futo', 80000, 'sports'),
('futo2', 'Futo 2', 75000, 'sports'),
('gargoyle', 'Gargoyle', 150000, 'motorcycles'),
('gauntlet', 'Gauntlet', 41250, 'muscle'),
('gauntlet3', 'Gauntlet Retro', 48000, 'muscle'),
('gb200', 'GB200', 247500, 'sports'),
('gburrito', 'Gang Burrito', 45000, 'vans'),
('gburrito2', 'Burrito', 29000, 'vans'),
('glendale', 'Glendale', 18750, 'sedans'),
('glendale2', 'Glendale Custom', 26250, 'sedans'),
('granger', 'Grabger', 50000, 'suvs'),
('gresley', 'Gresley', 30000, 'suvs'),
('growler', 'Growler', 80000, 'sports'),
('gt500', 'GT 500', 785000, 'sportsclassics'),
('guardian', 'Guardian', 187500, 'offroad'),
('hakuchou', 'Hakuchou', 180000, 'motorcycles'),
('hakuchou2', 'Hakuchou Sport', 200000, 'motorcycles'),
('hermes', 'Hermes', 607500, 'muscle'),
('hexer', 'Hexer', 55000, 'motorcycles'),
('hotknife', 'Hotknife', 142500, 'muscle'),
('huntley', 'Huntley S', 40000, 'suvs'),
('hustler', 'Hustler', 600000, 'muscle'),
('infernus', 'Infernus', 180000, 'super'),
('innovation', 'Innovation', 60000, 'motorcycles'),
('intruder', 'Intruder', 18750, 'sedans'),
('issi2', 'Issi', 11250, 'compacts'),
('italigto', 'Itali GTO', 684000, 'sports'),
('jackal', 'Jackal', 47250, 'coupes'),
('jester', 'Jester', 97500, 'sports'),
('jester2', 'Jester(Racecar)', 202500, 'sports'),
('jester4', 'Jester 4', 90000, 'sports'),
('jetmax', 'Jetmax', 14000000, 'superboat'),
('journey', 'Journey', 6500, 'vans'),
('jugular', 'Jugular', 1200000, 'sports'),
('kamacho', 'Kamacho', 390000, 'offroad'),
('kanjo', 'Kanjo', 120000, 'compacts'),
('khamelion', 'Khamelion', 112500, 'sports'),
('komoda', 'Komoda', 1125000, 'sports'),
('kuruma', 'Kuruma', 900000, 'sports'),
('landstalker', 'Landstalker', 35000, 'suvs'),
('le7b', 'RE-7B', 325000, 'super'),
('locust', 'Locust', 80000, 'sports'),
('lynx', 'Lynx', 60000, 'sports'),
('mamba', 'Mamba', 135000, 'sports'),
('manana', 'Manana', 12800, 'sportsclassics'),
('manana2', 'Manana Custom', 44000, 'sportsclassics'),
('manchez', 'Manchez', 75000, 'motorcycles'),
('marquis', 'Marquis', 11000000, 'superboat'),
('massacro', 'Massacro', 97500, 'sports'),
('massacro2', 'Massacro(Racecar)', 195000, 'sports'),
('mesa', 'Mesa', 16000, 'suvs'),
('mesa3', 'Mesa Trail', 32500, 'suvs'),
('minivan', 'Minivan', 8000, 'vans'),
('minivan2', 'Minivan Custom', 15000, 'vans'),
('monroe', 'Monroe', 55000, 'sportsclassics'),
('moonbeam', 'Moonbeam', 18000, 'vans'),
('moonbeam2', 'Moonbeam Rider', 35000, 'vans'),
('nemesis', 'Nemesis', 84000, 'motorcycles'),
('neon', 'Neon', 900000, 'sports'),
('nightblade', 'Nightblade', 165000, 'motorcycles'),
('nightshade', 'Nightshade', 127500, 'muscle'),
('ninef', '9F', 97500, 'sports'),
('ninef2', '9F Cabrio', 120000, 'sports'),
('novak', 'Novak', 140000, 'suvs'),
('omnis', 'Omnis', 120000, 'sports'),
('oracle2', 'Oracle XS', 29250, 'coupes'),
('osiris', 'Osiris', 190000, 'super'),
('outlaw', 'Outlaw', 850000, 'motorcycles'),
('panto', 'Panto', 4500, 'compacts'),
('paradise', 'Paradise', 10000, 'vans'),
('pariah', 'Pariah', 2137500, 'sports'),
('patriot', 'Patriot', 35000, 'suvs'),
('pcj', 'PCJ-600', 90000, 'motorcycles'),
('penumbra', 'Penumbra', 45000, 'sports'),
('penumbra2', 'Penumbra FF', 157500, 'sports'),
('pfister811', 'Pfister', 145000, 'super'),
('phoenix', 'Phoenix', 22500, 'muscle'),
('picador', 'Picador', 40500, 'muscle'),
('pigalle', 'Pigalle', 20000, 'sportsclassics'),
('prairie', 'Prairie', 13500, 'compacts'),
('premier', 'Premier', 15000, 'sedans'),
('previon', 'Previon', 45000, 'sports'),
('primo', 'Primo', 22500, 'sedans'),
('primo2', 'Primo Custom', 33750, 'sedans'),
('prototipo', 'X80 Proto', 2500000, 'super'),
('radi', 'Radius', 29000, 'suvs'),
('raiden', 'raiden', 2100000, 'sports'),
('rapidgt', 'Rapid GT', 82500, 'sports'),
('rapidgt2', 'Rapid GT Convertible', 112500, 'sports'),
('rapidgt3', 'Rapid GT3', 88500, 'sportsclassics'),
('raptor', 'Raptor', 750000, 'motorcycles'),
('reaper', 'Reaper', 150000, 'super'),
('rebel2', 'Rebel', 52500, 'offroad'),
('rebla', 'Rebla', 964000, 'suvs'),
('regina', 'Regina', 11250, 'sedans'),
('remus', 'Remus', 30000, 'sports'),
('retinue', 'Retinue', 61500, 'sportsclassics'),
('riata', 'riata', 337500, 'offroad'),
('rocoto', 'Rocoto', 33000, 'suvs'),
('rrocket', 'Rocket', 1250000, 'motorcycles'),
('rt3000', 'RT3000', 45000, 'sports'),
('ruffian', 'Ruffian', 105000, 'motorcycles'),
('rumpo', 'Rumpo', 15000, 'vans'),
('rumpo3', 'Rumpo Trail', 19500, 'vans'),
('ruston', 'Ruston', 80000, 'sports'),
('sabregt', 'Sabre Turbo', 20000, 'muscle'),
('sabregt2', 'Sabre GT', 41250, 'muscle'),
('sanchez', 'Sanchez', 50000, 'motorcycles'),
('sanchez2', 'Sanchez Sport', 60000, 'motorcycles'),
('sanctus', 'Sanctus', 180000, 'motorcycles'),
('sandking', 'Sandking', 75000, 'offroad'),
('savestra', 'Savestra', 990000, 'sportsclassics'),
('sc1', 'SC 1', 800000, 'super'),
('schafter2', 'Schafter', 90000, 'sedans'),
('schafter3', 'Schafter V12', 300000, 'sports'),
('schlagen', 'Schlagen', 1200000, 'sports'),
('scorcher', 'Scorcher (velo)', 100, 'motorcycles'),
('seashark', 'SeaShark', 11000000, 'superboat'),
('seashark2', 'Seashark2', 12500000, 'superboat'),
('seminole', 'Seminole', 150000, 'suvs'),
('seminole2', 'Seminole Frontiere', 200000, 'suvs'),
('sentinel', 'Sentinel', 36000, 'coupes'),
('sentinel2', 'Sentinel XS', 33750, 'coupes'),
('sentinel3', 'Sentinel Classique', 48750, 'sports'),
('seven70', 'Seven 70', 60000, 'sports'),
('sheava', 'ETR1', 220000, 'super'),
('slamvan3', 'Slam Van', 18750, 'muscle'),
('sovereign', 'Sovereign', 130000, 'motorcycles'),
('speeder', 'Speeder', 14000000, 'superboat'),
('squalo', 'Squalo', 11000000, 'superboat'),
('stinger', 'Stinger', 80000, 'sportsclassics'),
('stingergt', 'Stinger GT', 75000, 'sportsclassics'),
('streiter', 'Streiter', 900000, 'sports'),
('stretch', 'Stretch (entreprise seulement)', 101250, 'sedans'),
('stryder', 'Stryder', 80000, 'motorcycles'),
('sugoi', 'Sugoï', 400000, 'sports'),
('sultan', 'Sultan', 90000, 'sports'),
('sultan2', 'Sultan Retro', 562500, 'sports'),
('sultan3', 'Sultan 3', 65000, 'sports'),
('sultanrs', 'Sultan RS', 200000, 'super'),
('suntrap', 'Stuntrap', 12500000, 'superboat'),
('superd', 'Super Diamond', 146250, 'sedans'),
('surano', 'Surano', 82500, 'sports'),
('surfer', 'Surfer', 12000, 'vans'),
('t20', 'T20', 500000, 'super'),
('tailgater2', 'Tailgater 2', 85000, 'sports'),
('tampa', 'Tampa', 18750, 'muscle'),
('tampa2', 'Drift Tampa', 120000, 'sports'),
('thrust', 'Thrust', 130000, 'motorcycles'),
('tornado2', 'Tornado', 36000, 'sportsclassics'),
('tornado5', 'Tornado Lowrider', 28000, 'sportsclassics'),
('toro', 'Toro', 12500000, 'superboat'),
('toros', 'Toros', 200000, 'suvs'),
('tribike3', 'Tri bike (velo)', 150, 'motorcycles'),
('trophytruck', 'Trophy Truck', 100000, 'offroad'),
('trophytruck2', 'Trophy Truck Limited', 127500, 'offroad'),
('tropic', 'Tropic', 11500000, 'superboat'),
('tropos', 'Tropos', 262500, 'sports'),
('tulip', 'Tulip', 48000, 'muscle'),
('turismor', 'Turismo R', 340000, 'super'),
('tyrus', 'Tyrus', 600000, 'super'),
('vacca', 'Vacca', 120000, 'super'),
('vader', 'Vader', 66000, 'motorcycles'),
('vagrant', 'Vagrant', 1500000, 'motorcycles'),
('vamos', 'Vamos', 64000, 'muscle'),
('vectre', 'Vectre', 85000, 'sports'),
('verlierer2', 'Verlierer', 112500, 'sports'),
('vigero', 'Vigero', 22500, 'muscle'),
('virgo', 'Virgo', 22500, 'muscle'),
('virgo2', 'Virgo Lowrider', 40000, 'muscle'),
('virgo3', 'Virgo Luxe', 52000, 'muscle'),
('viseris', 'Viseris', 875000, 'sportsclassics'),
('visione', 'Visione', 2250000, 'super'),
('voltic', 'Voltic', 900000, 'super'),
('voodoo', 'Voodoo', 15000, 'muscle'),
('vortex', 'Vortex', 115000, 'motorcycles'),
('vstr', 'VSTR', 637500, 'sports'),
('warrener', 'Warrener', 7500, 'sedans'),
('washington', 'Washington', 9000, 'sedans'),
('weevil', 'Weevil', 52000, 'compacts'),
('windsor', 'Windsor', 90000, 'coupes'),
('windsor2', 'Windsor Drop', 120000, 'coupes'),
('wolfsbane', 'Woflsbane', 90000, 'motorcycles'),
('xls', 'XLS', 21000, 'suvs'),
('yosemite', 'Yosemite', 135000, 'muscle'),
('yosemite2', 'Yosemite Lowrider', 192000, 'muscle'),
('youga', 'Youga', 10800, 'vans'),
('youga2', 'Youga Luxuary', 6000, 'vans'),
('youga3', 'Yougo Lowrider', 80000, 'vans'),
('z190', 'Z190', 90000, 'sportsclassics'),
('zentorno', 'Zentorno', 700000, 'super'),
('zion', 'Zion', 40500, 'coupes'),
('zion2', 'Zion Cabrio', 48000, 'coupes'),
('zion3', 'Zion Classique', 200000, 'sportsclassics'),
('zombiea', 'Zombie', 105000, 'motorcycles'),
('zombieb', 'Zombie Luxuary', 120000, 'motorcycles'),
('zr350', 'ZR350', 80000, 'sports'),
('ztype', 'Z-Type', 22000, 'sportsclassics');

-- --------------------------------------------------------

--
-- Structure de la table `vente_leboncoin`
--

CREATE TABLE `vente_leboncoin` (
  `identifier` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `price` int DEFAULT NULL,
  `id` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `vfictifveh`
--

CREATE TABLE `vfictifveh` (
  `id` int NOT NULL,
  `model` varchar(25) COLLATE utf8mb4_general_ci NOT NULL,
  `color` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `pos` text COLLATE utf8mb4_general_ci NOT NULL,
  `rotation` text COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vfictifveh`
--

INSERT INTO `vfictifveh` (`id`, `model`, `color`, `pos`, `rotation`) VALUES
(1, '-687279910', '#000000', '{\"x\":-46.25,\"y\":0.75,\"z\":68.68841552734375}', '{\"x\":0.0,\"y\":-0.0,\"z\":0.0}');

-- --------------------------------------------------------

--
-- Structure de la table `vgangs`
--

CREATE TABLE `vgangs` (
  `gangname` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `ganglabel` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `posCoffre` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `point` int NOT NULL DEFAULT '0',
  `zone` text COLLATE utf8mb4_general_ci,
  `KitArme` int DEFAULT '0',
  `FabArme` int NOT NULL DEFAULT '0',
  `perms_coffre` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '{"2":false,"3":true,"0":false,"1":false}',
  `perms_recruter` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '{"2":false,"3":true,"0":false,"1":false}',
  `perms_promouvoir` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '{"2":false,"3":true,"0":false,"1":false}',
  `perms_gestionmembre` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '{"2":false,"3":true,"0":false,"1":false}',
  `perms_vente` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '{"2":false,"3":true,"0":false,"1":false}',
  `perms_fabrication` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '{"2":false,"3":true,"0":false,"1":false}'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vgangs`
--

INSERT INTO `vgangs` (`gangname`, `ganglabel`, `posCoffre`, `point`, `zone`, `KitArme`, `FabArme`, `perms_coffre`, `perms_recruter`, `perms_promouvoir`, `perms_gestionmembre`, `perms_vente`, `perms_fabrication`) VALUES
('bloods', 'Bloods', '{\"x\":-1562.0,\"y\":-382.0,\"z\":48.0}', 0, '[{\"x\":-1530.12646484375,\"y\":-387.38409423828127},{\"x\":-1518.5445556640626,\"y\":-398.46868896484377},{\"x\":-1590.2474365234376,\"y\":-478.5396728515625},{\"x\":-1621.8880615234376,\"y\":-450.4790344238281},{\"x\":-1623.43212890625,\"y\":-432.0404357910156},{\"x\":-1564.562255859375,\"y\":-356.9784240722656}]', 1, 1, '{\"2\":false,\"3\":true,\"0\":false,\"1\":false}', '{\"2\":false,\"3\":true,\"0\":false,\"1\":false}', '{\"2\":false,\"3\":true,\"0\":false,\"1\":false}', '{\"2\":false,\"3\":true,\"0\":false,\"1\":false}', '{\"2\":false,\"3\":true,\"0\":false,\"1\":false}', '{\"2\":false,\"3\":true,\"0\":false,\"1\":false}');

-- --------------------------------------------------------

--
-- Structure de la table `vgarderobe`
--

CREATE TABLE `vgarderobe` (
  `id` int NOT NULL,
  `identifier` varchar(60) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `name` longtext COLLATE utf8mb4_general_ci,
  `data` longtext COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vgarderobe`
--

INSERT INTO `vgarderobe` (`id`, `identifier`, `name`, `data`) VALUES
(80, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'Basic', '{\"torso_2\":0,\"torso_1\":548,\"tshirt_2\":0,\"decals_1\":0,\"pants_1\":169,\"arms\":1,\"shoes_1\":156,\"pants_2\":0,\"tshirt_1\":15,\"shoes_2\":2}');

-- --------------------------------------------------------

--
-- Structure de la table `vhistoevalstaff`
--

CREATE TABLE `vhistoevalstaff` (
  `id` int NOT NULL,
  `idunique` int NOT NULL,
  `reason` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `staffidunique` int NOT NULL,
  `oldeval` int DEFAULT NULL,
  `neweval` int NOT NULL,
  `date` varchar(255) COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vhistoevalstaff`
--

INSERT INTO `vhistoevalstaff` (`id`, `idunique`, `reason`, `staffidunique`, `oldeval`, `neweval`, `date`) VALUES
(6, 1, 'GG super scene rp', 1, 3, 5, '2024/08/09 00:19:50'),
(7, 1, 'Troll sur scene fleeca', 1, 5, 2, '2024/08/09 00:21:22'),
(8, 1, 'Troll en scene', 1, 2, 4, '2024/08/09 00:22:18'),
(9, 1, 'HRP + Troll + Freekill', 1, 4, 0, '2024/08/09 00:22:54'),
(10, 1, 'null', 1, 0, 5, '2024/08/09 00:58:13'),
(11, 1, 'HRP + Troll = Fk', 1, 5, 0, '2024/08/10 01:32:17'),
(12, 1, 'Test', 1, 0, 4, '2024/08/27 15:36:55'),
(13, 1, 'Good', 1, 4, 5, '2025/04/05 15:05:16'),
(14, 1, 'Scene RP avec la LSPD', 1, 5, 3, '2025/04/13 11:49:21');

-- --------------------------------------------------------

--
-- Structure de la table `vhistoriquesociety`
--

CREATE TABLE `vhistoriquesociety` (
  `id` int NOT NULL,
  `society` text COLLATE utf8mb4_general_ci NOT NULL,
  `label` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `info` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `time` datetime DEFAULT CURRENT_TIMESTAMP,
  `count` int DEFAULT NULL,
  `type` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vhistoriquesociety`
--

INSERT INTO `vhistoriquesociety` (`id`, `society`, `label`, `info`, `time`, `count`, `type`) VALUES
(1, 'police', 'Gains : Dépot d\'Argent Sale', '~n~Auteur: dev (1)~n~', '2025-01-28 23:20:48', 10, NULL),
(2, 'police', 'Gains : Dépot d\'Argent', '~n~Auteur: dev (1)~n~', '2025-01-28 23:20:52', 10000, NULL),
(3, 'police', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-24 23:29:11', 10000, NULL),
(4, 'police', 'Dépense : Retrait d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-24 23:29:25', -10000, NULL),
(5, 'gouvernement', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-24 23:33:19', 10000, NULL),
(6, 'gouvernement', 'Dépense : Retrait d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-24 23:33:23', -10000, NULL),
(7, 'gouvernement', 'Gains : Taxes (retrait)', 'De l\'entreprise: Gouvernement\nType de taxes: retrait', '2025-03-24 23:33:23', 1000, NULL),
(8, 'police', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-24 23:34:17', 5000, NULL),
(9, 'police', 'Dépense : Retrait d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-24 23:34:21', -5000, NULL),
(10, 'gouvernement', 'Gains : Taxes (retrait)', 'De l\'entreprise: LSPD\nType de taxes: retrait', '2025-03-24 23:34:21', 500, NULL),
(11, 'police', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:27:00', 10000, NULL),
(12, 'gouvernement', 'Gains : Taxes (retrait)', 'De l\'entreprise: LSPD\nType de taxes: retrait', '2025-03-25 16:27:04', 1000, NULL),
(13, 'police', 'Dépense : Retrait d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:27:04', -10000, NULL),
(14, 'police', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:28:43', 10000, NULL),
(15, 'police', 'Dépense : Retrait d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:28:47', -10000, NULL),
(16, 'gouvernement', 'Gains : Taxes (retrait)', 'De l\'entreprise: LSPD\nType de taxes: retrait', '2025-03-25 16:28:47', 1000, NULL),
(17, 'police', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:34:29', 10000, NULL),
(18, 'police', 'Dépense : Retrait d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:34:31', -10000, NULL),
(19, 'gouvernement', 'Gains : Taxes (retrait)', 'De l\'entreprise: LSPD\nType de taxes: retrait', '2025-03-25 16:34:31', 1000, NULL),
(20, 'police', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:39:44', 10000, NULL),
(21, 'police', 'Dépense : Retrait d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:39:48', -10000, NULL),
(22, 'gouvernement', 'Gains : Taxes (retrait)', 'De l\'entreprise: LSPD\nType de taxes: retrait', '2025-03-25 16:39:48', 1000, NULL),
(23, 'police', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:40:47', 10000, NULL),
(24, 'police', 'Dépense : Retrait d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:40:51', -10000, NULL),
(25, 'gouvernement', 'Gains : Taxes (retrait)', 'De l\'entreprise: LSPD\nType de taxes: retrait', '2025-03-25 16:40:51', 1000, NULL),
(26, 'police', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:44:57', 10000, NULL),
(27, 'police', 'Dépense : Retrait d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:45:00', -10000, NULL),
(28, 'gouvernement', 'Gains : Taxes (retrait)', 'De l\'entreprise: LSPD\nType de taxes: retrait', '2025-03-25 16:45:00', 1000, NULL),
(29, 'police', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:45:43', 10000, NULL),
(30, 'police', 'Dépense : Retrait d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 16:45:46', -10000, NULL),
(31, 'gouvernement', 'Gains : Taxes (retrait)', 'De l\'entreprise: LSPD\nType de taxes: retrait', '2025-03-25 16:45:46', 1000, NULL),
(32, 'police', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 18:20:15', 10000, NULL),
(33, 'police', 'Dépense : Retrait d\'Argent', '~n~Auteur: null (1)~n~', '2025-03-25 18:20:18', -10000, NULL),
(34, 'gouvernement', 'Gains : Taxes (retrait)', 'De l\'entreprise: LSPD\nType de taxes: retrait', '2025-03-25 18:20:18', 1000, NULL),
(35, 'carshop', 'Gains : Dépot d\'Argent', '~n~Auteur: John Doe (1)~n~', '2025-09-08 21:27:51', 10000, NULL),
(36, 'carshop', 'Gains : Dépot d\'Argent', '~n~Auteur: John Doe (1)~n~', '2025-09-08 21:27:55', 5000, NULL),
(37, 'police', 'Gains : Dépot d\'Argent', '~n~Auteur: hq275101 (1)~n~', '2025-12-10 20:30:51', 10, NULL),
(38, 'gouvernement', 'Gains : Taxes (retrait)', 'De l\'entreprise: LSPD\nType de taxes: retrait', '2025-12-10 20:30:58', 1, NULL),
(39, 'police', 'Dépense : Retrait d\'Argent', '~n~Auteur: hq275101 (1)~n~', '2025-12-10 20:30:58', -5, NULL),
(40, 'police', 'Gains : Dépot d\'Argent Sale', '~n~Auteur: hq275101 (1)~n~', '2025-12-10 20:31:02', 100, NULL),
(41, 'police', 'Dépense : Retrait d\'Argent Sale', '~n~Auteur: hq275101 (1)~n~', '2025-12-10 20:31:05', -100, NULL),
(42, 'woodcutting', 'Gains : Vente 1x Bois coupé', '~n~Auteur: hq275101 (1)~n~Total Gagner : 500$~n~', '2025-12-13 12:58:00', 1000, NULL),
(43, 'woodcutting', 'Gains : Vente 1x Bois coupé', '~n~Auteur: hq275101 (1)~n~Total Gagner : 1000$~n~', '2025-12-13 12:58:01', 1000, NULL),
(44, 'woodcutting', 'Gains : Vente 1x Bois coupé', '~n~Auteur: hq275101 (1)~n~Total Gagner : 1500$~n~', '2025-12-13 12:58:03', 1000, NULL),
(45, 'woodcutting', 'Gains : Vente 1x Bois coupé', '~n~Auteur: hq275101 (1)~n~Total Gagner : 2000$~n~', '2025-12-13 12:58:04', 1000, NULL),
(46, 'woodcutting', 'Gains : Vente 1x Bois coupé', '~n~Auteur: hq275101 (1)~n~Total Gagner : 2500$~n~', '2025-12-13 12:58:06', 1000, NULL),
(47, 'woodcutting', 'Gains : Vente 1x Bois coupé', '~n~Auteur: hq275101 (1)~n~Total Gagner : 500$~n~', '2025-12-13 13:22:05', 1000, NULL),
(48, 'woodcutting', 'Gains : Vente 1x Bois coupé', '~n~Auteur: hq275101 (1)~n~Total Gagner : 1000$~n~', '2025-12-13 13:22:07', 1000, NULL),
(49, 'woodcutting', 'Gains : Vente 1x Bois coupé', '~n~Auteur: hq275101 (1)~n~Total Gagner : 1500$~n~', '2025-12-13 13:22:08', 1000, NULL),
(50, 'woodcutting', 'Gains : Vente 1x Bois coupé', '~n~Auteur: hq275101 (1)~n~Total Gagner : 2000$~n~', '2025-12-13 13:22:10', 1000, NULL),
(51, 'bennys', 'Gains : Facture', '~n~Auteur: hq275101 (1)~n~Client: hq275101~n~', '2025-12-13 14:42:50', 7200, NULL),
(52, 'carshop', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-12-18 22:23:29', 10000, NULL),
(53, 'carshop', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-12-18 22:25:36', 10000, NULL),
(54, 'carshop', 'Achat véhicule stock', 'Véhicule: BLISTA\nPlaque: KLMNOPQRSTU 0123234567890123456\nPar: null', '2025-12-18 22:25:44', -7000, NULL),
(55, 'carshop', 'Gains : Dépot d\'Argent', '~n~Auteur: null (1)~n~', '2025-12-18 22:30:13', 20000, NULL),
(56, 'carshop', 'Achat véhicule stock', 'Véhicule: BLISTA\nPlaque:  678\nPar: null', '2025-12-18 22:30:20', -7000, NULL),
(57, 'carshop', 'Véhicule retiré du stock', 'Véhicule: BLISTA\nPlaque:  678\nPar: null', '2025-12-18 22:31:22', 0, NULL),
(58, 'carshop', 'Achat véhicule stock', 'Véhicule: BLISTA\nPlaque: QRSTUVWXYW \nPar: null', '2025-12-18 22:31:41', -7000, NULL),
(59, 'carshop', 'Vente automatique', 'Véhicule: BLISTA\nPlaque: EFGHEFGHIJKLMNOPQRSTUVWXYABCDEFGH 3801234567\nAcheteur: null', '2025-12-18 22:35:37', 4200, NULL),
(60, 'carshop', 'Vente automatique', 'Véhicule: BLISTA\nPlaque: GHIJKLMNOPQRSTUVWXYZ 781234512345\nAcheteur: null', '2025-12-18 22:36:30', 4200, NULL),
(61, 'carshop', 'Vente automatique', 'Véhicule: BLISTA\nPlaque: 077916\nAcheteur: null', '2025-12-18 22:39:12', 4200, NULL),
(62, 'carshop', 'Vente automatique', 'Véhicule: ISSI2\nPlaque: DGKB2915\nAcheteur: null', '2025-12-18 22:43:44', 3000, NULL),
(63, 'bikeshop', 'Vente automatique', 'Véhicule: AKUMA\nPlaque: YISX6196\nAcheteur: null', '2025-12-18 22:45:25', 10800, NULL),
(64, 'bikeshop', 'Vente automatique', 'Véhicule: BATI\nPlaque: UYER2189\nAcheteur: null', '2025-12-18 22:51:08', 24000, NULL);

-- --------------------------------------------------------

--
-- Structure de la table `vips`
--

CREATE TABLE `vips` (
  `identifier` varchar(50) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0',
  `vip` tinyint NOT NULL DEFAULT '0',
  `expiration` int NOT NULL DEFAULT '0',
  `type` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Basic'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vips`
--

INSERT INTO `vips` (`identifier`, `vip`, `expiration`, `type`) VALUES
('license:063e3a07b7e5204a49b87053d2fd572a89659886', 0, 1751300205, 'Basic'),
('license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 1, 1806063769, 'Premium');

-- --------------------------------------------------------

--
-- Structure de la table `visdead`
--

CREATE TABLE `visdead` (
  `id` int NOT NULL,
  `license` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `visdead`
--

INSERT INTO `visdead` (`id`, `license`) VALUES
(6614, 'license:d5978481098e92d4daafbbef17620e54dec79196'),
(6615, 'license:c48b0294f78a28f6f264a7adfa68a5b3f4cdc4f9'),
(6616, 'license:c036013c3d6f5a5e951dfc69633cdbc51ddf4232'),
(6617, 'license:6b4fbc2620bf3fe8fe144b88ecde934e50ac49c9'),
(6619, 'license:33d330aae30191a8ae6fe52c2015d5a6576f3d59'),
(6620, 'license:e7b2e663bbf6a24a12b25818893434f812b9c45b'),
(6622, 'license:8f3efc571db0bc5610899318d4b9f0957638ae93'),
(6623, 'license:9dea66e5caaa571002b1307512c5b573bb839ac8'),
(6624, 'license:611429849fd2c2a374aa9968ed57eaacf05da3d9'),
(6625, 'license:e005c9ef708ec4ed738f7e19025284915b24be86'),
(6626, 'license:ee06581f3257f92d47c668d187dcba72f07fa670');

-- --------------------------------------------------------

--
-- Structure de la table `vjails`
--

CREATE TABLE `vjails` (
  `jailId` int NOT NULL,
  `identifier` varchar(70) COLLATE utf8mb4_general_ci NOT NULL,
  `idunique` int DEFAULT NULL,
  `time` int DEFAULT '0',
  `raison` varchar(50) COLLATE utf8mb4_general_ci DEFAULT 'Raison introuvable',
  `update_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `staffname` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `inventory` longtext COLLATE utf8mb4_general_ci,
  `jailname` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vjails`
--

INSERT INTO `vjails` (`jailId`, `identifier`, `idunique`, `time`, `raison`, `update_at`, `staffname`, `inventory`, `jailname`) VALUES
(125, 'license:05522abdb6933b6109e0fa6fc0330d9914f75291', NULL, 60, 'Test', '2024-05-22 17:12:21', 'null', NULL, 'CFQ'),
(150, 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', NULL, 900, 'Test', '2025-12-09 18:23:46', 'hq275101', NULL, 'Leo');

-- --------------------------------------------------------

--
-- Structure de la table `vlester`
--

CREATE TABLE `vlester` (
  `id` int NOT NULL,
  `time` text COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Structure de la table `vlogs`
--

CREATE TABLE `vlogs` (
  `id` int NOT NULL,
  `type` tinytext COLLATE utf8mb4_general_ci NOT NULL,
  `data` text COLLATE utf8mb4_general_ci NOT NULL,
  `date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vlogs`
--

INSERT INTO `vlogs` (`id`, `type`, `data`, `date`) VALUES
(14007, 'connexion', '{\"discord\":\"447086574346436618\",\"ip\":\"178.51.206.143\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 32ms\",\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"name\":\"null\"}', '2025-12-21 01:15:19'),
(14008, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a pris son service\"}', '2025-12-21 01:15:25'),
(14009, 'dv', '{\"logs_title\":\"Delete Véhicule\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a supprimé radius: 1\"}', '2025-12-21 01:16:06'),
(14010, 'dv', '{\"logs_title\":\"Delete Véhicule\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a supprimé radius: 1\"}', '2025-12-21 01:22:49'),
(14011, 'deconnexion', '{\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\",\"idunique\":1,\"name\":\"null\"}', '2025-12-21 01:23:01'),
(14012, 'connexion', '{\"ip\":\"178.51.206.143\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"name\":\"null\"}', '2025-12-21 21:42:33'),
(14013, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-21 21:42:43'),
(14014, 'car', '{\"logs_title\":\"Spawn Véhicule\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a spawn sultan2\"}', '2025-12-21 21:43:30'),
(14015, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a pris son service\"}', '2025-12-21 21:45:39'),
(14016, 'setjob', '{\"idunique_cible\":1,\"logs_message\":\"null a défini le job de null sur police (grade 4)\",\"logs_title\":\"SetJob\",\"name_cible\":\"null\",\"idunique\":1,\"name\":\"null\"}', '2025-12-21 21:46:12'),
(14017, 'setjob2', '{\"idunique_cible\":1,\"logs_message\":\"null a défini le job de null sur bloods (grade 2)\",\"logs_title\":\"SetJob2\",\"name_cible\":\"null\",\"idunique\":1,\"name\":\"null\"}', '2025-12-21 21:46:37'),
(14018, 'setjob2', '{\"idunique_cible\":1,\"logs_message\":\"null a défini le job de null sur bloods (grade 2)\",\"logs_title\":\"SetJob2\",\"name_cible\":\"null\",\"idunique\":1,\"name\":\"null\"}', '2025-12-21 21:46:39'),
(14019, 'deconnexion', '{\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\",\"idunique\":1,\"name\":\"null\"}', '2025-12-21 21:48:00'),
(14020, 'connexion', '{\"discord\":\"447086574346436618\",\"ip\":\"178.51.206.143\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 40ms\",\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"name\":\"null\"}', '2025-12-23 11:17:52'),
(14021, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-23 11:18:01'),
(14022, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a pris son service\"}', '2025-12-23 11:19:18'),
(14023, 'deconnexion', '{\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\",\"idunique\":1,\"name\":\"null\"}', '2025-12-23 11:23:42'),
(14024, 'connexion', '{\"name\":\"null\",\"ip\":\"178.51.206.143\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"logs_title\":\"Connexion\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 33ms\"}', '2025-12-23 16:50:33'),
(14025, 'mort', '{\"idunique\":1,\"logs_title\":\"Mort\",\"name\":\"null\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-23 16:50:36'),
(14026, 'deconnexion', '{\"name\":\"null\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: [txAdmin] Server restarting (admin request).\"}', '2025-12-23 17:04:46'),
(14027, 'connexion', '{\"idunique\":1,\"logs_title\":\"Connexion\",\"discord\":\"447086574346436618\",\"ip\":\"178.51.206.143\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-26 14:45:23'),
(14028, 'mort', '{\"name\":\"null\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\",\"idunique\":1}', '2025-12-26 14:45:24'),
(14029, 'deconnexion', '{\"idunique\":1,\"logs_title\":\"Déconnexion\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-26 14:47:53'),
(14030, 'connexion', '{\"ip\":\"178.51.206.143\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 29ms\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_title\":\"Connexion\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-26 22:52:19'),
(14031, 'mort', '{\"idunique\":1,\"logs_title\":\"Mort\",\"name\":\"null\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-26 22:52:21'),
(14032, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-26 22:56:37'),
(14033, 'connexion', '{\"ip\":\"178.51.206.143\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 34ms\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"logs_title\":\"Connexion\"}', '2025-12-27 17:32:16'),
(14034, 'mort', '{\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Mort\"}', '2025-12-27 17:32:18'),
(14035, 'deconnexion', '{\"discord\":\"447086574346436618\",\"name\":\"null\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: [txAdmin] Server restarting (admin request).\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"logs_title\":\"Déconnexion\"}', '2025-12-27 17:38:39'),
(14036, 'connexion', '{\"idunique\":1,\"ip\":\"109.88.221.74\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Connexion\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 50ms\",\"discord\":\"447086574346436618\",\"name\":\"null\"}', '2025-12-29 17:48:58'),
(14037, 'mort', '{\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1,\"name\":\"null\"}', '2025-12-29 17:49:12'),
(14038, 'prise-service', '{\"logs_title\":\"Staff\",\"logs_message\":\"null a pris son service\",\"idunique\":1,\"name\":\"null\"}', '2025-12-29 17:49:20'),
(14039, 'deconnexion', '{\"idunique\":1,\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Déconnexion\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: [txAdmin] Server restarting (admin request).\",\"name\":\"null\"}', '2025-12-29 17:54:24'),
(14040, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 21ms\",\"idunique\":1,\"discord\":\"447086574346436618\",\"ip\":\"109.88.221.74\",\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\"}', '2025-12-29 17:55:56'),
(14041, 'prise-service', '{\"idunique\":1,\"logs_message\":\"null a pris son service\",\"logs_title\":\"Staff\",\"name\":\"null\"}', '2025-12-29 17:56:21'),
(14042, 'deconnexion', '{\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: [txAdmin] Server restarting (admin request).\",\"idunique\":1,\"discord\":\"447086574346436618\",\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\"}', '2025-12-29 18:04:30'),
(14043, 'connexion', '{\"discord\":\"447086574346436618\",\"logs_title\":\"Connexion\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 31ms\",\"ip\":\"109.88.221.74\",\"name\":\"null\"}', '2025-12-29 18:17:02'),
(14044, 'mort', '{\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1,\"name\":\"null\"}', '2025-12-29 18:17:04'),
(14045, 'prise-service', '{\"logs_title\":\"Staff\",\"logs_message\":\"null a pris son service\",\"idunique\":1,\"name\":\"null\"}', '2025-12-29 18:17:32'),
(14046, 'connexion', '{\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_title\":\"Connexion\",\"name\":\"null\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 40ms\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-29 18:21:02'),
(14047, 'deconnexion', '{\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_title\":\"Déconnexion\",\"name\":\"null\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Impossible de vous identifier, une personne joue déjà avec votre compte Rockstar sur le Serveur.\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-29 18:21:03'),
(14048, 'connexion', '{\"name\":\"null\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Connexion\",\"discord\":\"447086574346436618\",\"ip\":\"109.88.221.74\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 31ms\"}', '2025-12-29 18:24:30'),
(14049, 'prise-service', '{\"logs_title\":\"Staff\",\"idunique\":1,\"name\":\"null\",\"logs_message\":\"null a pris son service\"}', '2025-12-29 18:24:38'),
(14050, 'deconnexion', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Déconnexion\",\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-29 19:15:09'),
(14051, 'connexion', '{\"name\":\"null\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Connexion\",\"discord\":\"447086574346436618\",\"ip\":\"109.88.221.74\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 29ms\"}', '2025-12-29 19:16:20'),
(14052, 'prise-service', '{\"logs_title\":\"Staff\",\"idunique\":1,\"name\":\"null\",\"logs_message\":\"null a pris son service\"}', '2025-12-29 19:18:27'),
(14053, 'connexion', '{\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"ip\":\"109.88.221.74\",\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Connexion\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 35ms\"}', '2025-12-29 19:22:26'),
(14054, 'deconnexion', '{\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Déconnexion\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Impossible de vous identifier, une personne joue déjà avec votre compte Rockstar sur le Serveur.\"}', '2025-12-29 19:22:27'),
(14055, 'connexion', '{\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"name\":\"null\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 31ms\",\"discord\":\"447086574346436618\",\"logs_title\":\"Connexion\"}', '2025-12-29 19:24:37'),
(14056, 'mort', '{\"name\":\"null\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1,\"logs_title\":\"Mort\"}', '2025-12-29 19:24:39'),
(14057, 'prise-service', '{\"name\":\"null\",\"logs_message\":\"null a pris son service\",\"idunique\":1,\"logs_title\":\"Staff\"}', '2025-12-29 19:25:28'),
(14058, 'deconnexion', '{\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Déconnexion\",\"name\":\"null\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Server shutting down: Quit command executed.\",\"discord\":\"447086574346436618\",\"idunique\":1}', '2025-12-29 19:44:01'),
(14059, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 36ms\",\"idunique\":1,\"discord\":\"447086574346436618\",\"logs_title\":\"Connexion\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"ip\":\"109.88.221.74\"}', '2025-12-29 20:07:33'),
(14060, 'deconnexion', '{\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Déconnexion\"}', '2025-12-29 20:10:20'),
(14061, 'connexion', '{\"name\":\"null\",\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 76ms\",\"discord\":\"447086574346436618\",\"ip\":\"109.88.221.74\"}', '2025-12-29 20:17:05'),
(14062, 'deconnexion', '{\"name\":\"null\",\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"447086574346436618\",\"idunique\":1}', '2025-12-29 20:17:34'),
(14063, 'connexion', '{\"logs_title\":\"Connexion\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 60ms\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"idunique\":1,\"ip\":\"109.88.221.74\"}', '2025-12-29 20:21:35'),
(14064, 'mort', '{\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1,\"name\":\"null\"}', '2025-12-29 20:21:36'),
(14065, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1}', '2025-12-29 20:22:02'),
(14066, 'connexion', '{\"name\":\"null\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"logs_title\":\"Connexion\"}', '2025-12-29 20:24:30'),
(14067, 'prise-service', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Staff\",\"logs_message\":\"null a pris son service\"}', '2025-12-29 20:24:35'),
(14068, 'deconnexion', '{\"name\":\"null\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\"}', '2025-12-29 20:24:36'),
(14069, 'connexion', '{\"name\":\"null\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"logs_title\":\"Connexion\"}', '2025-12-29 20:26:51'),
(14070, 'prise-service', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Staff\",\"logs_message\":\"null a pris son service\"}', '2025-12-29 20:26:56'),
(14071, 'deconnexion', '{\"name\":\"null\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\"}', '2025-12-29 20:28:35'),
(14072, 'connexion', '{\"name\":\"null\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 31ms\",\"logs_title\":\"Connexion\"}', '2025-12-29 20:32:38'),
(14073, 'prise-service', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Staff\",\"logs_message\":\"null a pris son service\"}', '2025-12-29 20:32:49'),
(14074, 'deconnexion', '{\"name\":\"null\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\"}', '2025-12-29 20:32:50'),
(14075, 'connexion', '{\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"ip\":\"109.88.221.74\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 33ms\",\"idunique\":1}', '2025-12-29 20:34:40'),
(14076, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":1}', '2025-12-29 20:35:19'),
(14077, 'connexion', '{\"logs_title\":\"Connexion\",\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"idunique\":1,\"ip\":\"109.88.221.74\"}', '2025-12-29 21:34:09'),
(14078, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1}', '2025-12-29 21:34:34'),
(14079, 'connexion', '{\"logs_title\":\"Connexion\",\"ip\":\"109.88.221.74\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 31ms\",\"idunique\":1,\"discord\":\"447086574346436618\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-29 21:41:33'),
(14080, 'connexion', '{\"idunique\":1,\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"ip\":\"109.88.221.74\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 176ms\",\"logs_title\":\"Connexion\"}', '2025-12-29 21:43:20'),
(14081, 'deconnexion', '{\"idunique\":1,\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Impossible de vous identifier, une personne joue déjà avec votre compte Rockstar sur le Serveur.\",\"logs_title\":\"Déconnexion\"}', '2025-12-29 21:43:21'),
(14082, 'connexion', '{\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 35ms\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"logs_title\":\"Connexion\"}', '2025-12-29 21:45:40'),
(14083, 'deconnexion', '{\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Déconnexion\"}', '2025-12-29 21:46:33'),
(14084, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 33ms\",\"logs_title\":\"Connexion\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\",\"name\":\"null\"}', '2025-12-29 22:58:34'),
(14085, 'mort', '{\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1}', '2025-12-29 22:58:34'),
(14086, 'deconnexion', '{\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"name\":\"null\"}', '2025-12-29 23:01:14'),
(14087, 'connexion', '{\"discord\":\"447086574346436618\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 36ms\",\"logs_title\":\"Connexion\",\"ip\":\"109.88.221.74\"}', '2025-12-29 23:04:12'),
(14088, 'mort', '{\"name\":\"null\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\",\"idunique\":1}', '2025-12-29 23:04:14'),
(14089, 'deconnexion', '{\"discord\":\"447086574346436618\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\",\"idunique\":1}', '2025-12-29 23:04:58'),
(14090, 'connexion', '{\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"name\":\"null\",\"ip\":\"109.88.221.74\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 35ms\",\"logs_title\":\"Connexion\"}', '2025-12-29 23:07:07'),
(14091, 'mort', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-29 23:07:08'),
(14092, 'deconnexion', '{\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"name\":\"null\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\"}', '2025-12-29 23:08:14'),
(14093, 'connexion', '{\"discord\":\"447086574346436618\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 36ms\",\"logs_title\":\"Connexion\",\"name\":\"null\"}', '2025-12-29 23:15:58'),
(14094, 'deconnexion', '{\"discord\":\"447086574346436618\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\",\"name\":\"null\"}', '2025-12-29 23:21:02'),
(14095, 'connexion', '{\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"logs_title\":\"Connexion\"}', '2025-12-29 23:24:36'),
(14096, 'mort', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-29 23:24:37'),
(14097, 'prise-service', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Staff\",\"logs_message\":\"null a pris son service\"}', '2025-12-29 23:25:26'),
(14098, 'quitte-service', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Staff\",\"logs_message\":\"null a quitter son service\"}', '2025-12-29 23:32:59'),
(14099, 'car', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Spawn Véhicule\",\"logs_message\":\"null a spawn sultanrs\"}', '2025-12-29 23:33:08'),
(14100, 'dv', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Delete Véhicule\",\"logs_message\":\"null a supprimé radius: 1\"}', '2025-12-29 23:33:10'),
(14101, 'prise-service', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Staff\",\"logs_message\":\"null a pris son service\"}', '2025-12-29 23:33:12'),
(14102, 'quitte-service', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Staff\",\"logs_message\":\"null a quitter son service\"}', '2025-12-29 23:33:19'),
(14103, 'connexion', '{\"name\":\"null\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 43ms\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Connexion\",\"idunique\":1,\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\"}', '2025-12-29 23:36:57'),
(14104, 'deconnexion', '{\"name\":\"null\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Impossible de vous identifier, une personne joue déjà avec votre compte Rockstar sur le Serveur.\",\"logs_title\":\"Déconnexion\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\"}', '2025-12-29 23:37:00'),
(14105, 'connexion', '{\"discord\":\"447086574346436618\",\"name\":\"null\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"ip\":\"109.88.221.74\",\"logs_title\":\"Connexion\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 31ms\"}', '2025-12-29 23:41:38'),
(14106, 'deconnexion', '{\"discord\":\"447086574346436618\",\"name\":\"null\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Déconnexion\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 00:04:16'),
(14107, 'connexion', '{\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 43ms\",\"idunique\":1,\"discord\":\"447086574346436618\",\"name\":\"null\",\"ip\":\"109.88.221.74\"}', '2025-12-30 00:05:35'),
(14108, 'connexion', '{\"logs_title\":\"Connexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 32ms\",\"idunique\":14,\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\",\"ip\":\"178.51.183.227\"}', '2025-12-30 00:06:40'),
(14109, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"idunique\":14,\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 00:08:20'),
(14110, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"discord\":\"447086574346436618\",\"name\":\"null\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 00:21:28'),
(14111, 'connexion', '{\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 42ms\",\"name\":\"Pablo delrulio\",\"idunique\":17,\"ip\":\"178.51.183.227\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\"}', '2025-12-30 00:36:06'),
(14112, 'deconnexion', '{\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"Pablo delrulio\",\"discord\":\"1057427236199870525\",\"idunique\":17,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 00:43:13'),
(14113, 'connexion', '{\"name\":\"Pablo delrulio\",\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 42ms\",\"ip\":\"178.51.183.227\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\",\"idunique\":18}', '2025-12-30 01:41:39'),
(14114, 'mort', '{\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_title\":\"Mort\",\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\"}', '2025-12-30 01:41:40'),
(14115, 'prise-service', '{\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 01:43:58'),
(14116, 'connexion', '{\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"discord\":\"1057427236199870525\",\"ip\":\"178.51.183.227\",\"logs_title\":\"Connexion\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 43ms\"}', '2025-12-30 01:52:07'),
(14117, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\"}', '2025-12-30 01:52:07'),
(14118, 'car', '{\"logs_title\":\"Spawn Véhicule\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a spawn sultanrs\"}', '2025-12-30 02:08:08'),
(14119, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 02:08:16'),
(14120, 'car', '{\"logs_title\":\"Spawn Véhicule\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a spawn sultanrs\"}', '2025-12-30 02:13:04'),
(14121, 'dv', '{\"logs_title\":\"Delete Véhicule\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a supprimé radius: 1\"}', '2025-12-30 02:13:05'),
(14122, 'deconnexion', '{\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"discord\":\"1057427236199870525\",\"logs_title\":\"Déconnexion\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 02:15:06'),
(14123, 'connexion', '{\"logs_title\":\"Connexion\",\"discord\":\"1057427236199870525\",\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 46ms\",\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\"}', '2025-12-30 06:07:34'),
(14124, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"discord\":\"1057427236199870525\",\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"Pablo delrulio\"}', '2025-12-30 06:09:39'),
(14125, 'connexion', '{\"discord\":\"1057427236199870525\",\"idunique\":18,\"logs_title\":\"Connexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 30ms\",\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\"}', '2025-12-30 06:10:25'),
(14126, 'prise-service', '{\"idunique\":18,\"logs_message\":\"Pablo delrulio a pris son service\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\"}', '2025-12-30 06:11:44'),
(14127, 'deconnexion', '{\"discord\":\"1057427236199870525\",\"idunique\":18,\"logs_title\":\"Déconnexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"Pablo delrulio\"}', '2025-12-30 06:16:26'),
(14128, 'connexion', '{\"idunique\":18,\"ip\":\"178.51.183.227\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 45ms\",\"logs_title\":\"Connexion\"}', '2025-12-30 06:17:25'),
(14129, 'prise-service', '{\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio a pris son service\",\"logs_title\":\"Staff\"}', '2025-12-30 06:18:23'),
(14130, 'deconnexion', '{\"idunique\":18,\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 06:22:38'),
(14131, 'connexion', '{\"idunique\":18,\"ip\":\"178.51.183.227\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 31ms\",\"logs_title\":\"Connexion\"}', '2025-12-30 06:23:14'),
(14132, 'mort', '{\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\"}', '2025-12-30 06:23:14'),
(14133, 'deconnexion', '{\"idunique\":18,\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 06:30:18'),
(14134, 'connexion', '{\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"ip\":\"178.51.183.227\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 46ms\",\"logs_title\":\"Connexion\"}', '2025-12-30 06:46:15'),
(14135, 'deconnexion', '{\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 06:49:31'),
(14136, 'connexion', '{\"idunique\":18,\"logs_title\":\"Connexion\",\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 40ms\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"ip\":\"178.51.183.227\"}', '2025-12-30 06:50:20'),
(14137, 'mort', '{\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\",\"idunique\":18,\"name\":\"Pablo delrulio\"}', '2025-12-30 06:50:20'),
(14138, 'connexion', '{\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\",\"ip\":\"178.51.183.227\",\"logs_title\":\"Connexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"idunique\":18,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 44ms\"}', '2025-12-30 06:52:05'),
(14139, 'deconnexion', '{\"name\":\"Pablo delrulio\",\"discord\":\"1057427236199870525\",\"logs_title\":\"Déconnexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"idunique\":18,\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Impossible de vous identifier, une personne joue déjà avec votre compte Rockstar sur le Serveur.\"}', '2025-12-30 06:52:09'),
(14140, 'connexion', '{\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 37ms\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"ip\":\"178.51.183.227\",\"logs_title\":\"Connexion\",\"idunique\":18,\"name\":\"Pablo delrulio\"}', '2025-12-30 06:53:22'),
(14141, 'prise-service', '{\"idunique\":18,\"logs_message\":\"Pablo delrulio a pris son service\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\"}', '2025-12-30 06:55:26'),
(14142, 'create-report', '{\"idunique\":18,\"logs_message\":\"Le joueur Pablo delrulio (U18) a fais un report : fdfdfdfdf\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Logs Joueur\"}', '2025-12-30 06:55:41'),
(14143, 'goto', '{\"name\":\"Pablo delrulio\",\"name_cible\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio (U18)\\n /goto le joueur Pablo delrulio (U18)\",\"logs_title\":\"Logs Staff\",\"idunique_auteur\":18,\"idunique_cible\":18}', '2025-12-30 06:55:50'),
(14144, 'take-report', '{\"logs_message\":\"Le Staff Pablo delrulio (U18) a prit le report de Pablo delrulio (RU1 U18)\",\"name_cible\":\"Pablo delrulio\",\"logs_title\":\"Logs Staff\",\"idunique\":18,\"name\":\"Pablo delrulio\",\"idunique_cible\":18}', '2025-12-30 06:55:50'),
(14145, 'msgstaff', '{\"name\":\"Pablo delrulio\",\"name_cible\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio (U18)\\n /msgstaff (dsdsdsdsdsd) le joueur Pablo delrulio (U18)\",\"logs_title\":\"Logs Staff\",\"idunique_auteur\":18,\"idunique_cible\":18}', '2025-12-30 06:56:00'),
(14146, 'dv', '{\"idunique\":18,\"logs_message\":\"Pablo delrulio a supprimé radius: 1\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Delete Véhicule\"}', '2025-12-30 06:56:21'),
(14147, 'deconnexion', '{\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\",\"idunique\":18,\"name\":\"Pablo delrulio\"}', '2025-12-30 07:01:11'),
(14148, 'connexion', '{\"logs_title\":\"Connexion\",\"discord\":\"1057427236199870525\",\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"idunique\":18,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 34ms\"}', '2025-12-30 07:02:46'),
(14149, 'connexion', '{\"name\":\"Pablo delrulio\",\"ip\":\"178.51.183.227\",\"idunique\":18,\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 40ms\",\"logs_title\":\"Connexion\"}', '2025-12-30 07:06:12'),
(14150, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"idunique\":18,\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Impossible de vous identifier, une personne joue déjà avec votre compte Rockstar sur le Serveur.\"}', '2025-12-30 07:06:15'),
(14151, 'connexion', '{\"idunique\":18,\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 33ms\",\"ip\":\"178.51.183.227\",\"logs_title\":\"Connexion\"}', '2025-12-30 07:06:55'),
(14152, 'deconnexion', '{\"idunique\":18,\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 07:10:35'),
(14153, 'connexion', '{\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\",\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 34ms\",\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\"}', '2025-12-30 07:11:24'),
(14154, 'deconnexion', '{\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\",\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: [txAdmin] Server restarting (admin request).\",\"name\":\"Pablo delrulio\"}', '2025-12-30 07:12:31'),
(14155, 'connexion', '{\"discord\":\"1057427236199870525\",\"idunique\":18,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 30ms\",\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\"}', '2025-12-30 07:13:29'),
(14156, 'prise-service', '{\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a pris son service\",\"logs_title\":\"Staff\"}', '2025-12-30 07:14:43'),
(14157, 'msgstaff', '{\"name_cible\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio (U18)\\n /msgstaff (dsdsds) le joueur Pablo delrulio (U18)\",\"idunique_cible\":18,\"logs_title\":\"Logs Staff\",\"idunique_auteur\":18,\"name\":\"Pablo delrulio\"}', '2025-12-30 07:15:47'),
(14158, 'bring', '{\"name_cible\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio (U18)\\n /bring le joueur Pablo delrulio (U18)\",\"idunique_cible\":18,\"logs_title\":\"Logs Staff\",\"idunique_auteur\":18,\"name\":\"Pablo delrulio\"}', '2025-12-30 07:15:51'),
(14159, 'goto', '{\"name_cible\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio (U18)\\n /tpa le joueur Pablo delrulio (U18)\",\"idunique_cible\":18,\"logs_title\":\"Logs Staff\",\"idunique_auteur\":18,\"name\":\"Pablo delrulio\"}', '2025-12-30 07:15:51'),
(14160, 'jail', '{\"logs_message\":\"Pablo delrulio a jail Pablo delrulio (18) pendant : 600 secondes\",\"logs_title\":\"Logs Staff\"}', '2025-12-30 07:16:05'),
(14161, 'deconnexion', '{\"discord\":\"1057427236199870525\",\"idunique\":18,\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 07:18:01'),
(14162, 'connexion', '{\"name\":\"Pablo delrulio\",\"idunique\":18,\"discord\":\"1057427236199870525\",\"ip\":\"178.51.183.227\",\"logs_title\":\"Connexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 31ms\"}', '2025-12-30 07:18:54'),
(14163, 'prise-service', '{\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\",\"idunique\":18}', '2025-12-30 07:19:34'),
(14164, 'freeze', '{\"idunique_cible\":18,\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio (U18)\\n /freeze le joueur Pablo delrulio (U18)\",\"logs_title\":\"Logs Staff\",\"idunique_auteur\":18,\"name_cible\":\"Pablo delrulio\"}', '2025-12-30 07:19:46'),
(14165, 'freeze', '{\"idunique_cible\":18,\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio (U18)\\n /unfreeze le joueur Pablo delrulio (U18)\",\"logs_title\":\"Logs Staff\",\"idunique_auteur\":18,\"name_cible\":\"Pablo delrulio\"}', '2025-12-30 07:19:48'),
(14166, 'deconnexion', '{\"name\":\"Pablo delrulio\",\"idunique\":18,\"discord\":\"1057427236199870525\",\"logs_title\":\"Déconnexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Server->client connection timed out. Last seen 9510 msec ago.\"}', '2025-12-30 07:25:33'),
(14167, 'connexion', '{\"name\":\"Pablo delrulio\",\"idunique\":18,\"ip\":\"178.51.183.227\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 55ms\",\"discord\":\"1057427236199870525\"}', '2025-12-30 07:29:51'),
(14168, 'prise-service', '{\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\",\"idunique\":18}', '2025-12-30 07:31:59'),
(14169, 'unjail', '{\"logs_message\":\"Pablo delrulio \\nA unjail : license:063e3a07b7e5204a49b87053d2fd572a89659886 (18)\",\"logs_title\":\"Action staff\"}', '2025-12-30 07:32:16'),
(14170, 'give-item', '{\"idunique_cible\":18,\"name\":\"Pablo delrulio\",\"name_cible\":\"Pablo delrulio\",\"logs_title\":\"Logs Staff\",\"logs_message\":\"Le joueur : Pablo delrulio (U18) a give l\'item Bouteille d\'eau (x10) a Pablo delrulio (U18)\",\"idunique\":18}', '2025-12-30 07:32:51'),
(14171, 'use-item', '{\"name\":\"Pablo delrulio\",\"logs_title\":\"Use Item\",\"logs_message\":\"Pablo delrulio a utilisé water\",\"idunique\":18}', '2025-12-30 07:32:57'),
(14172, 'freeze', '{\"idunique_cible\":18,\"name\":\"Pablo delrulio\",\"name_cible\":\"Pablo delrulio\",\"idunique_auteur\":18,\"logs_title\":\"Logs Staff\",\"logs_message\":\"Pablo delrulio (U18)\\n /freeze le joueur Pablo delrulio (U18)\"}', '2025-12-30 07:33:19'),
(14173, 'freeze', '{\"idunique_cible\":18,\"name\":\"Pablo delrulio\",\"name_cible\":\"Pablo delrulio\",\"idunique_auteur\":18,\"logs_title\":\"Logs Staff\",\"logs_message\":\"Pablo delrulio (U18)\\n /unfreeze le joueur Pablo delrulio (U18)\"}', '2025-12-30 07:33:20'),
(14174, 'freeze', '{\"idunique_cible\":18,\"name\":\"Pablo delrulio\",\"name_cible\":\"Pablo delrulio\",\"idunique_auteur\":18,\"logs_title\":\"Logs Staff\",\"logs_message\":\"Pablo delrulio (U18)\\n /freeze le joueur Pablo delrulio (U18)\"}', '2025-12-30 07:33:46'),
(14175, 'freeze', '{\"idunique_cible\":18,\"name\":\"Pablo delrulio\",\"name_cible\":\"Pablo delrulio\",\"idunique_auteur\":18,\"logs_title\":\"Logs Staff\",\"logs_message\":\"Pablo delrulio (U18)\\n /unfreeze le joueur Pablo delrulio (U18)\"}', '2025-12-30 07:33:47'),
(14176, 'quitte-service', '{\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a quitter son service\",\"idunique\":18}', '2025-12-30 07:34:43'),
(14177, 'prise-service', '{\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\",\"idunique\":18}', '2025-12-30 07:34:43'),
(14178, 'deconnexion', '{\"idunique\":18,\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"1057427236199870525\"}', '2025-12-30 07:37:17'),
(14179, 'connexion', '{\"ip\":\"178.51.183.227\",\"logs_title\":\"Connexion\",\"name\":\"Pablo delrulio\",\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 40ms\",\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-30 07:38:50'),
(14180, 'prise-service', '{\"idunique\":18,\"logs_message\":\"Pablo delrulio a pris son service\",\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\"}', '2025-12-30 07:39:16'),
(14181, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"name\":\"Pablo delrulio\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"idunique\":18,\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 07:40:23'),
(14182, 'connexion', '{\"name\":\"Pablo delrulio\",\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 39ms\",\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"ip\":\"178.51.183.227\",\"logs_title\":\"Connexion\"}', '2025-12-30 07:41:47'),
(14183, 'prise-service', '{\"idunique\":18,\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 07:42:10'),
(14184, 'quitte-service', '{\"idunique\":18,\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio a quitter son service\"}', '2025-12-30 07:42:12'),
(14185, 'prise-service', '{\"idunique\":18,\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 07:42:12'),
(14186, 'quitte-service', '{\"idunique\":18,\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio a quitter son service\"}', '2025-12-30 07:42:20'),
(14187, 'prise-service', '{\"idunique\":18,\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 07:42:22'),
(14188, 'deconnexion', '{\"name\":\"Pablo delrulio\",\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 07:43:56'),
(14189, 'connexion', '{\"idunique\":18,\"ip\":\"178.51.183.227\",\"logs_title\":\"Connexion\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 39ms\"}', '2025-12-30 07:45:09'),
(14190, 'mort', '{\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_title\":\"Mort\",\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\"}', '2025-12-30 07:45:10'),
(14191, 'prise-service', '{\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 07:45:41'),
(14192, 'quitte-service', '{\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a quitter son service\"}', '2025-12-30 07:45:45'),
(14193, 'prise-service', '{\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 07:46:00'),
(14194, 'quitte-service', '{\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a quitter son service\"}', '2025-12-30 07:46:06'),
(14195, 'prise-service', '{\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 07:46:19'),
(14196, 'deconnexion', '{\"idunique\":18,\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 07:49:50'),
(14197, 'connexion', '{\"idunique\":18,\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\",\"ip\":\"178.51.183.227\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 30ms\",\"discord\":\"1057427236199870525\"}', '2025-12-30 07:50:57'),
(14198, 'prise-service', '{\"logs_title\":\"Staff\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a pris son service\",\"name\":\"Pablo delrulio\"}', '2025-12-30 07:51:22'),
(14199, 'quitte-service', '{\"logs_title\":\"Staff\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a quitter son service\",\"name\":\"Pablo delrulio\"}', '2025-12-30 07:56:12'),
(14200, 'prise-service', '{\"logs_title\":\"Staff\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a pris son service\",\"name\":\"Pablo delrulio\"}', '2025-12-30 07:56:16');
INSERT INTO `vlogs` (`id`, `type`, `data`, `date`) VALUES
(14201, 'quitte-service', '{\"logs_title\":\"Staff\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a quitter son service\",\"name\":\"Pablo delrulio\"}', '2025-12-30 07:56:19'),
(14202, 'prise-service', '{\"logs_title\":\"Staff\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a pris son service\",\"name\":\"Pablo delrulio\"}', '2025-12-30 07:56:21'),
(14203, 'create-report', '{\"logs_title\":\"Logs Joueur\",\"idunique\":18,\"logs_message\":\"Le joueur Pablo delrulio (U18) a fais un report : dfdfdfd\",\"name\":\"Pablo delrulio\"}', '2025-12-30 07:56:55'),
(14204, 'deconnexion', '{\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: [txAdmin] Server restarting (admin request).\",\"discord\":\"1057427236199870525\"}', '2025-12-30 07:58:04'),
(14205, 'connexion', '{\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 31ms\",\"idunique\":18,\"discord\":\"1057427236199870525\",\"ip\":\"178.51.183.227\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Connexion\"}', '2025-12-30 07:58:44'),
(14206, 'prise-service', '{\"logs_message\":\"Pablo delrulio a pris son service\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_title\":\"Staff\"}', '2025-12-30 07:59:06'),
(14207, 'deconnexion', '{\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Server->client connection timed out. Last seen 41221 msec ago.\",\"idunique\":18,\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 08:01:01'),
(14208, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 39ms\",\"idunique\":1,\"discord\":\"447086574346436618\",\"ip\":\"109.88.221.74\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"logs_title\":\"Connexion\"}', '2025-12-30 11:55:45'),
(14209, 'mort', '{\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Mort\"}', '2025-12-30 11:55:58'),
(14210, 'prise-service', '{\"logs_message\":\"null a pris son service\",\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Staff\"}', '2025-12-30 12:03:54'),
(14211, 'deconnexion', '{\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":1,\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 12:31:48'),
(14212, 'connexion', '{\"logs_title\":\"Connexion\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 29ms\"}', '2025-12-30 12:35:24'),
(14213, 'mort', '{\"logs_title\":\"Mort\",\"idunique\":1,\"name\":\"null\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-30 12:35:25'),
(14214, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 12:44:19'),
(14215, 'connexion', '{\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 40ms\",\"logs_title\":\"Connexion\",\"name\":\"null\",\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\"}', '2025-12-30 12:47:36'),
(14216, 'mort', '{\"logs_title\":\"Mort\",\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"name\":\"null\"}', '2025-12-30 12:47:37'),
(14217, 'mort', '{\"logs_title\":\"Mort\",\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"name\":\"null\"}', '2025-12-30 13:31:22'),
(14218, 'prise-service', '{\"logs_title\":\"Staff\",\"idunique\":1,\"logs_message\":\"null a pris son service\",\"name\":\"null\"}', '2025-12-30 14:09:59'),
(14219, 'deconnexion', '{\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"logs_title\":\"Déconnexion\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"null\"}', '2025-12-30 14:17:18'),
(14220, 'connexion', '{\"name\":\"null\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_title\":\"Connexion\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 31ms\",\"ip\":\"109.88.221.74\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 14:24:22'),
(14221, 'mort', '{\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"name\":\"null\",\"idunique\":1}', '2025-12-30 14:24:23'),
(14222, 'deconnexion', '{\"name\":\"null\",\"discord\":\"447086574346436618\",\"logs_title\":\"Déconnexion\",\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 14:27:41'),
(14223, 'connexion', '{\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"ip\":\"109.88.221.74\",\"logs_title\":\"Connexion\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 31ms\"}', '2025-12-30 14:34:34'),
(14224, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 37ms\",\"idunique\":1,\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\"}', '2025-12-30 14:37:03'),
(14225, 'deconnexion', '{\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Impossible de vous identifier, une personne joue déjà avec votre compte Rockstar sur le Serveur.\",\"idunique\":1,\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"discord\":\"447086574346436618\"}', '2025-12-30 14:37:04'),
(14226, 'connexion', '{\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 33ms\",\"logs_title\":\"Connexion\",\"ip\":\"109.88.221.74\"}', '2025-12-30 14:58:11'),
(14227, 'mort', '{\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1}', '2025-12-30 14:58:22'),
(14228, 'deconnexion', '{\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Server->client connection timed out. Last seen 43341 msec ago.\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 15:01:12'),
(14229, 'connexion', '{\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"logs_title\":\"Connexion\",\"ip\":\"109.88.221.74\"}', '2025-12-30 15:04:27'),
(14230, 'mort', '{\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1}', '2025-12-30 15:04:38'),
(14231, 'deconnexion', '{\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 15:06:01'),
(14232, 'connexion', '{\"name\":\"null\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 40ms\",\"idunique\":1,\"ip\":\"109.88.221.74\",\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 15:17:20'),
(14233, 'mort', '{\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-30 15:17:22'),
(14234, 'deconnexion', '{\"name\":\"null\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":1,\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 15:20:30'),
(14235, 'connexion', '{\"logs_title\":\"Connexion\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"ip\":\"109.88.221.74\"}', '2025-12-30 15:26:07'),
(14236, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"name\":\"null\"}', '2025-12-30 15:28:11'),
(14237, 'connexion', '{\"name\":\"null\",\"logs_title\":\"Connexion\",\"ip\":\"109.88.221.74\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 82ms\"}', '2025-12-30 15:30:44'),
(14238, 'deconnexion', '{\"name\":\"null\",\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 15:34:03'),
(14239, 'connexion', '{\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_title\":\"Connexion\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"ip\":\"109.88.221.74\"}', '2025-12-30 15:40:42'),
(14240, 'deconnexion', '{\"name\":\"null\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_title\":\"Déconnexion\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 15:41:48'),
(14241, 'connexion', '{\"logs_title\":\"Connexion\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"ip\":\"109.88.221.74\",\"name\":\"null\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 41ms\",\"discord\":\"447086574346436618\"}', '2025-12-30 15:50:58'),
(14242, 'mort', '{\"idunique\":1,\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"name\":\"null\"}', '2025-12-30 15:51:00'),
(14243, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"447086574346436618\"}', '2025-12-30 15:51:32'),
(14244, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 39ms\",\"logs_title\":\"Connexion\",\"name\":\"null\",\"ip\":\"109.88.221.74\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"idunique\":1}', '2025-12-30 16:23:12'),
(14245, 'mort', '{\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"name\":\"null\",\"logs_title\":\"Mort\",\"idunique\":1}', '2025-12-30 16:23:13'),
(14246, 'mort', '{\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"name\":\"null\",\"logs_title\":\"Mort\",\"idunique\":1}', '2025-12-30 16:23:38'),
(14247, 'deconnexion', '{\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"idunique\":1}', '2025-12-30 16:23:44'),
(14248, 'connexion', '{\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 40ms\",\"discord\":\"1057427236199870525\",\"idunique\":18,\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Connexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-30 16:28:05'),
(14249, 'mort', '{\"logs_title\":\"Mort\",\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\",\"name\":\"Pablo delrulio\",\"idunique\":18}', '2025-12-30 16:28:06'),
(14250, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 40ms\",\"discord\":\"447086574346436618\",\"idunique\":1,\"ip\":\"109.88.221.74\",\"name\":\"null\",\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 16:28:08'),
(14251, 'mort', '{\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"name\":\"null\",\"idunique\":1}', '2025-12-30 16:28:10'),
(14252, 'deconnexion', '{\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"447086574346436618\",\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 16:28:50'),
(14253, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 45ms\",\"discord\":\"447086574346436618\",\"idunique\":1,\"ip\":\"109.88.221.74\",\"name\":\"null\",\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 16:30:42'),
(14254, 'prise-service', '{\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\",\"name\":\"Pablo delrulio\",\"idunique\":18}', '2025-12-30 16:30:57'),
(14255, 'quitte-service', '{\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a quitter son service\",\"name\":\"Pablo delrulio\",\"idunique\":18}', '2025-12-30 16:31:00'),
(14256, 'prise-service', '{\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\",\"name\":\"Pablo delrulio\",\"idunique\":18}', '2025-12-30 16:31:02'),
(14257, 'deconnexion', '{\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"1057427236199870525\",\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_title\":\"Déconnexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-30 16:31:10'),
(14258, 'deconnexion', '{\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"447086574346436618\",\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 16:36:16'),
(14259, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 32ms\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"ip\":\"109.88.221.74\",\"logs_title\":\"Connexion\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 16:47:21'),
(14260, 'mort', '{\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1}', '2025-12-30 16:47:25'),
(14261, 'deconnexion', '{\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"logs_title\":\"Déconnexion\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 16:49:08'),
(14262, 'connexion', '{\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 32ms\",\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\",\"ip\":\"178.51.183.227\",\"logs_title\":\"Connexion\",\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-30 18:26:15'),
(14263, 'deconnexion', '{\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Déconnexion\",\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-30 18:37:30'),
(14264, 'connexion', '{\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"discord\":\"1057427236199870525\",\"logs_title\":\"Connexion\",\"ip\":\"178.51.183.227\",\"idunique\":18,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 43ms\",\"name\":\"Pablo delrulio\"}', '2025-12-30 18:39:32'),
(14265, 'deconnexion', '{\"discord\":\"1057427236199870525\",\"logs_title\":\"Déconnexion\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\"}', '2025-12-30 18:41:33'),
(14266, 'connexion', '{\"logs_title\":\"Connexion\",\"discord\":\"1057427236199870525\",\"ip\":\"178.51.183.227\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 56ms\",\"name\":\"Pablo delrulio\",\"idunique\":18}', '2025-12-30 18:43:46'),
(14267, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: [txAdmin] Server restarting (admin request).\",\"name\":\"Pablo delrulio\",\"idunique\":18}', '2025-12-30 18:45:04'),
(14268, 'connexion', '{\"name\":\"Pablo delrulio\",\"ip\":\"178.51.183.227\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 36ms\",\"idunique\":18,\"logs_title\":\"Connexion\"}', '2025-12-30 18:45:46'),
(14269, 'mort', '{\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\",\"idunique\":18,\"logs_title\":\"Mort\"}', '2025-12-30 18:45:47'),
(14270, 'connexion', '{\"name\":\"null\",\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 40ms\",\"idunique\":1,\"logs_title\":\"Connexion\"}', '2025-12-30 18:47:31'),
(14271, 'deconnexion', '{\"name\":\"null\",\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":1,\"logs_title\":\"Déconnexion\"}', '2025-12-30 18:48:17'),
(14272, 'prise-service', '{\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio a pris son service\",\"idunique\":18,\"logs_title\":\"Staff\"}', '2025-12-30 18:49:03'),
(14273, 'deconnexion', '{\"name\":\"Pablo delrulio\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Server->client connection timed out. Last seen 103 msec ago.\",\"idunique\":18,\"logs_title\":\"Déconnexion\"}', '2025-12-30 18:49:32'),
(14274, 'connexion', '{\"logs_title\":\"Connexion\",\"idunique\":18,\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"ip\":\"178.51.183.227\",\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 43ms\"}', '2025-12-30 18:51:52'),
(14275, 'prise-service', '{\"logs_title\":\"Staff\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a pris son service\",\"name\":\"Pablo delrulio\"}', '2025-12-30 18:52:36'),
(14276, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"idunique\":18,\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 19:00:55'),
(14277, 'connexion', '{\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 30ms\",\"idunique\":18,\"discord\":\"1057427236199870525\",\"logs_title\":\"Connexion\"}', '2025-12-30 19:02:10'),
(14278, 'mort', '{\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\",\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_title\":\"Mort\"}', '2025-12-30 19:02:11'),
(14279, 'prise-service', '{\"logs_message\":\"Pablo delrulio a pris son service\",\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\"}', '2025-12-30 19:03:59'),
(14280, 'deconnexion', '{\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":18,\"discord\":\"1057427236199870525\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 19:08:52'),
(14281, 'connexion', '{\"discord\":\"1057427236199870525\",\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Connexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"idunique\":18,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 42ms\"}', '2025-12-30 19:10:56'),
(14282, 'connexion', '{\"discord\":\"447086574346436618\",\"ip\":\"109.88.221.74\",\"name\":\"null\",\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 40ms\"}', '2025-12-30 19:13:54'),
(14283, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-30 19:14:09'),
(14284, 'deconnexion', '{\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Déconnexion\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: [txAdmin] You have been kicked: for unknown reason.\"}', '2025-12-30 19:16:02'),
(14285, 'deconnexion', '{\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 19:18:37'),
(14286, 'connexion', '{\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 41ms\",\"discord\":\"1057427236199870525\",\"ip\":\"178.51.183.227\",\"logs_title\":\"Connexion\"}', '2025-12-30 19:20:03'),
(14287, 'mort', '{\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_title\":\"Mort\"}', '2025-12-30 19:20:04'),
(14288, 'prise-service', '{\"logs_message\":\"Pablo delrulio a pris son service\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_title\":\"Staff\"}', '2025-12-30 19:21:36'),
(14289, 'create-report', '{\"logs_message\":\"Le joueur Pablo delrulio (U18) a fais un report : dsdsdsdssd\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_title\":\"Logs Joueur\"}', '2025-12-30 19:28:54'),
(14290, 'goto', '{\"name\":\"Pablo delrulio\",\"name_cible\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio (U18)\\n /goto le joueur Pablo delrulio (U18)\",\"idunique_auteur\":18,\"idunique_cible\":18,\"logs_title\":\"Logs Staff\"}', '2025-12-30 19:29:01'),
(14291, 'take-report', '{\"idunique_cible\":18,\"name_cible\":\"Pablo delrulio\",\"logs_message\":\"Le Staff Pablo delrulio (U18) a prit le report de Pablo delrulio (RU1 U18)\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_title\":\"Logs Staff\"}', '2025-12-30 19:29:02'),
(14292, 'close-report', '{\"idunique_cible\":18,\"name_cible\":\"Pablo delrulio\",\"logs_message\":\"Le Staff Pablo delrulio (U18) a close le report de Pablo delrulio (RU1 U18)\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_title\":\"Logs Staff\"}', '2025-12-30 19:29:04'),
(14293, 'deconnexion', '{\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"1057427236199870525\",\"idunique\":18,\"logs_title\":\"Déconnexion\"}', '2025-12-30 19:32:13'),
(14294, 'connexion', '{\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Connexion\",\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 35ms\"}', '2025-12-30 19:33:08'),
(14295, 'mort', '{\"name\":\"null\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1,\"logs_title\":\"Mort\"}', '2025-12-30 19:33:11'),
(14296, 'deconnexion', '{\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Déconnexion\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: [txAdmin] Server restarting (admin request).\"}', '2025-12-30 19:33:16'),
(14297, 'connexion', '{\"logs_title\":\"Connexion\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 41ms\",\"idunique\":18,\"ip\":\"178.51.183.227\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"discord\":\"1057427236199870525\"}', '2025-12-30 19:34:04'),
(14298, 'connexion', '{\"logs_title\":\"Connexion\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"idunique\":1,\"ip\":\"109.88.221.74\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"discord\":\"447086574346436618\"}', '2025-12-30 19:34:13'),
(14299, 'prise-service', '{\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\",\"name\":\"Pablo delrulio\",\"idunique\":18}', '2025-12-30 19:36:36'),
(14300, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"discord\":\"447086574346436618\"}', '2025-12-30 19:38:49'),
(14301, 'connexion', '{\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 54ms\",\"ip\":\"178.51.183.227\",\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\",\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\"}', '2025-12-30 19:47:25'),
(14302, 'mort', '{\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\",\"name\":\"Pablo delrulio\",\"idunique\":18}', '2025-12-30 19:47:25'),
(14303, 'prise-service', '{\"logs_message\":\"Pablo delrulio a pris son service\",\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\",\"idunique\":18}', '2025-12-30 19:47:53'),
(14304, 'mort', '{\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\",\"name\":\"Pablo delrulio\",\"idunique\":18}', '2025-12-30 19:52:19'),
(14305, 'deconnexion', '{\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\",\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\"}', '2025-12-30 19:53:42'),
(14306, 'connexion', '{\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 38ms\",\"ip\":\"178.51.183.227\",\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\",\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\"}', '2025-12-30 20:02:04'),
(14307, 'prise-service', '{\"logs_message\":\"Pablo delrulio a pris son service\",\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\",\"idunique\":18}', '2025-12-30 20:02:59'),
(14308, 'deconnexion', '{\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":18,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\",\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\"}', '2025-12-30 20:04:41'),
(14309, 'connexion', '{\"ip\":\"109.88.221.74\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"logs_title\":\"Connexion\",\"name\":\"null\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"idunique\":1}', '2025-12-30 20:26:18'),
(14310, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"null\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1}', '2025-12-30 20:26:20'),
(14311, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"null\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1}', '2025-12-30 20:26:44'),
(14312, 'deconnexion', '{\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\",\"name\":\"null\",\"discord\":\"447086574346436618\",\"idunique\":1}', '2025-12-30 20:26:52'),
(14313, 'connexion', '{\"logs_title\":\"Connexion\",\"ip\":\"109.88.221.74\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 37ms\",\"name\":\"null\",\"idunique\":1,\"discord\":\"447086574346436618\"}', '2025-12-30 20:50:28'),
(14314, 'mort', '{\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1}', '2025-12-30 20:50:30'),
(14315, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"null\",\"idunique\":1,\"discord\":\"447086574346436618\"}', '2025-12-30 20:56:27'),
(14316, 'connexion', '{\"ip\":\"109.88.221.74\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Connexion\",\"name\":\"null\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 39ms\"}', '2025-12-30 20:57:33'),
(14317, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-30 20:57:35'),
(14318, 'deconnexion', '{\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Déconnexion\",\"name\":\"null\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 20:59:17'),
(14319, 'connexion', '{\"ip\":\"109.88.221.74\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 29ms\",\"logs_title\":\"Connexion\",\"name\":\"null\",\"discord\":\"447086574346436618\",\"idunique\":1}', '2025-12-30 21:01:55'),
(14320, 'mort', '{\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-30 21:02:39'),
(14321, 'prise-service', '{\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Staff\",\"logs_message\":\"null a pris son service\"}', '2025-12-30 21:02:54'),
(14322, 'revive', '{\"name_cible\":\"null\",\"logs_message\":\"null (U1) a /revive lui meme\",\"logs_title\":\"Logs Staff\",\"name\":\"null\",\"idunique_cible\":1,\"idunique\":1}', '2025-12-30 21:02:55'),
(14323, 'deconnexion', '{\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\",\"name\":\"null\",\"discord\":\"447086574346436618\",\"idunique\":1}', '2025-12-30 21:12:46'),
(14324, 'connexion', '{\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"logs_title\":\"Connexion\",\"name\":\"null\",\"ip\":\"109.88.221.74\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\"}', '2025-12-30 21:16:39'),
(14325, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"null\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1}', '2025-12-30 21:16:41'),
(14326, 'connexion', '{\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"idunique\":18,\"logs_title\":\"Connexion\",\"name\":\"Pablo delrulio\",\"ip\":\"178.51.183.227\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 32ms\"}', '2025-12-30 21:17:45'),
(14327, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio a pris son service\",\"idunique\":18}', '2025-12-30 21:19:18'),
(14328, 'goto', '{\"name_cible\":\"null\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Logs Staff\",\"idunique_auteur\":18,\"logs_message\":\"Pablo delrulio (U18)\\n /tpa le joueur null (U1)\",\"idunique_cible\":1}', '2025-12-30 21:19:23'),
(14329, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"null\",\"logs_message\":\"null a pris son service\",\"idunique\":1}', '2025-12-30 21:19:45'),
(14330, 'deconnexion', '{\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"idunique\":18,\"logs_title\":\"Déconnexion\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 21:21:16'),
(14331, 'connexion', '{\"ip\":\"109.88.221.74\",\"logs_title\":\"Connexion\",\"idunique\":1,\"name\":\"null\",\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 40ms\"}', '2025-12-30 21:21:22'),
(14332, 'connexion', '{\"ip\":\"109.88.221.74\",\"logs_title\":\"Connexion\",\"idunique\":1,\"name\":\"null\",\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 31ms\"}', '2025-12-30 21:21:24'),
(14333, 'mort', '{\"name\":\"null\",\"logs_title\":\"Mort\",\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-30 21:21:25'),
(14334, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"idunique\":1,\"name\":\"null\",\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 21:21:29'),
(14335, 'connexion', '{\"idunique\":18,\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Connexion\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 30ms\"}', '2025-12-30 21:22:22'),
(14336, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\"}', '2025-12-30 21:22:22'),
(14337, 'connexion', '{\"idunique\":1,\"ip\":\"109.88.221.74\",\"name\":\"null\",\"logs_title\":\"Connexion\",\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 21ms\"}', '2025-12-30 21:25:33'),
(14338, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-30 21:25:35'),
(14339, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a pris son service\"}', '2025-12-30 21:26:08'),
(14340, 'heal', '{\"logs_title\":\"Commande Admin\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a utilisé la commande /heal\"}', '2025-12-30 21:26:10'),
(14341, 'dv', '{\"logs_title\":\"Delete Véhicule\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a supprimé radius: 1\"}', '2025-12-30 21:26:36'),
(14342, 'quitte-service', '{\"logs_title\":\"Staff\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a quitter son service\"}', '2025-12-30 21:26:56'),
(14343, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a pris son service\"}', '2025-12-30 21:27:40'),
(14344, 'deconnexion', '{\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Déconnexion\",\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 21:32:44'),
(14345, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 21:34:59'),
(14346, 'deconnexion', '{\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_title\":\"Déconnexion\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Vous avez été Wipe...\"}', '2025-12-30 21:35:07'),
(14347, 'connexion', '{\"idunique\":18,\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Connexion\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 30ms\"}', '2025-12-30 21:36:49'),
(14348, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 21:37:31'),
(14349, 'deconnexion', '{\"idunique\":18,\"name\":\"Pablo delrulio\",\"logs_title\":\"Déconnexion\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 21:39:16'),
(14350, 'connexion', '{\"ip\":\"178.51.183.227\",\"logs_title\":\"Connexion\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 34ms\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-30 21:40:23'),
(14351, 'register', '{\"idunique_auteur\":18,\"logs_title\":\"Logs Staff\",\"logs_message\":\"Pablo delrulio (U18)\\n /register\",\"name\":\"Pablo delrulio\"}', '2025-12-30 21:41:01'),
(14352, 'register', '{\"idunique_auteur\":18,\"logs_title\":\"Logs Staff\",\"logs_message\":\"Pablo delrulio (U18)\\n /register\",\"name\":\"Pablo delrulio\"}', '2025-12-30 21:41:12'),
(14353, 'register', '{\"idunique_auteur\":18,\"logs_title\":\"Logs Staff\",\"logs_message\":\"Pablo delrulio (U18)\\n /register\",\"name\":\"Pablo delrulio\"}', '2025-12-30 21:41:15'),
(14354, 'register', '{\"idunique_auteur\":18,\"logs_title\":\"Logs Staff\",\"logs_message\":\"Pablo delrulio (U18)\\n /register\",\"name\":\"Pablo delrulio\"}', '2025-12-30 21:42:12'),
(14355, 'prise-service', '{\"idunique\":18,\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\",\"name\":\"Pablo delrulio\"}', '2025-12-30 21:43:06'),
(14356, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Quit: quit\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-30 21:44:22'),
(14357, 'connexion', '{\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 45ms\",\"name\":\"Pablo delrulio\",\"idunique\":18,\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\",\"ip\":\"178.51.183.227\"}', '2025-12-30 21:45:52'),
(14358, 'register', '{\"idunique_auteur\":18,\"logs_message\":\"Pablo delrulio (U18)\\n /register\",\"logs_title\":\"Logs Staff\",\"name\":\"Pablo delrulio\"}', '2025-12-30 21:46:22'),
(14359, 'deconnexion', '{\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"discord\":\"1057427236199870525\",\"idunique\":18,\"logs_title\":\"Déconnexion\",\"name\":\"Pablo delrulio\"}', '2025-12-30 21:46:37'),
(14360, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 37ms\",\"name\":\"null\",\"idunique\":1,\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Connexion\",\"ip\":\"109.88.221.74\"}', '2025-12-30 21:46:38'),
(14361, 'deconnexion', '{\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: [txAdmin] Server restarting (admin request).\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_title\":\"Déconnexion\",\"name\":\"null\"}', '2025-12-30 21:46:39'),
(14362, 'connexion', '{\"idunique\":19,\"discord\":\"1057427236199870525\",\"logs_title\":\"Connexion\",\"name\":\"Pablo delrulio\",\"ip\":\"178.51.183.227\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 33ms\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-30 21:48:30'),
(14363, 'register', '{\"name\":\"Pablo delrulio\",\"idunique_auteur\":19,\"logs_title\":\"Logs Staff\",\"logs_message\":\"Pablo delrulio (U19)\\n /register\"}', '2025-12-30 21:49:50'),
(14364, 'connexion', '{\"idunique\":1,\"discord\":\"447086574346436618\",\"logs_title\":\"Connexion\",\"name\":\"null\",\"ip\":\"109.88.221.74\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 38ms\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 21:49:59'),
(14365, 'prise-service', '{\"idunique\":19,\"name\":\"Pablo delrulio\",\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 21:51:58'),
(14366, 'deconnexion', '{\"idunique\":1,\"discord\":\"447086574346436618\",\"logs_title\":\"Déconnexion\",\"name\":\"null\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 21:52:06'),
(14367, 'connexion', '{\"idunique\":1,\"discord\":\"447086574346436618\",\"logs_title\":\"Connexion\",\"name\":\"null\",\"ip\":\"109.88.221.74\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 34ms\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 21:54:23'),
(14368, 'mort', '{\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-30 21:54:25'),
(14369, 'deconnexion', '{\"idunique\":1,\"discord\":\"447086574346436618\",\"logs_title\":\"Déconnexion\",\"name\":\"null\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 21:55:18'),
(14370, 'connexion', '{\"idunique\":1,\"discord\":\"447086574346436618\",\"logs_title\":\"Connexion\",\"name\":\"null\",\"ip\":\"109.88.221.74\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 20ms\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 21:56:22'),
(14371, 'deconnexion', '{\"idunique\":1,\"discord\":\"447086574346436618\",\"logs_title\":\"Déconnexion\",\"name\":\"null\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-30 21:56:52'),
(14372, 'deconnexion', '{\"idunique\":19,\"discord\":\"1057427236199870525\",\"logs_title\":\"Déconnexion\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-30 22:01:25'),
(14373, 'connexion', '{\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\",\"idunique\":19,\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 33ms\",\"logs_title\":\"Connexion\"}', '2025-12-30 22:24:30'),
(14374, 'deconnexion', '{\"name\":\"Pablo delrulio\",\"idunique\":19,\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 22:36:49'),
(14375, 'connexion', '{\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\",\"idunique\":19,\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 41ms\",\"logs_title\":\"Connexion\"}', '2025-12-30 22:38:16'),
(14376, 'prise-service', '{\"name\":\"Pablo delrulio\",\"idunique\":19,\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 22:43:32'),
(14377, 'quitte-service', '{\"name\":\"Pablo delrulio\",\"idunique\":19,\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a quitter son service\"}', '2025-12-30 22:43:33'),
(14378, 'prise-service', '{\"name\":\"Pablo delrulio\",\"idunique\":19,\"logs_title\":\"Staff\",\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-30 22:46:23'),
(14379, 'deconnexion', '{\"name\":\"Pablo delrulio\",\"idunique\":19,\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\"}', '2025-12-30 22:48:11'),
(14380, 'connexion', '{\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 34ms\",\"name\":\"Pablo delrulio\",\"ip\":\"178.51.183.227\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\",\"idunique\":19,\"discord\":\"1057427236199870525\"}', '2025-12-30 22:49:18'),
(14381, 'mort', '{\"idunique\":19,\"logs_title\":\"Mort\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\"}', '2025-12-30 22:55:06'),
(14382, 'mort', '{\"idunique\":19,\"logs_title\":\"Mort\",\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\"}', '2025-12-30 22:55:08'),
(14383, 'deconnexion', '{\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\",\"idunique\":19,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"discord\":\"1057427236199870525\"}', '2025-12-30 22:58:52'),
(14384, 'connexion', '{\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\",\"idunique\":19,\"logs_title\":\"Connexion\",\"ip\":\"178.51.183.227\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 31ms\"}', '2025-12-30 23:00:10'),
(14385, 'deconnexion', '{\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Déconnexion\",\"idunique\":19,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-30 23:09:17'),
(14386, 'connexion', '{\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 38ms\",\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\",\"discord\":\"1057427236199870525\"}', '2025-12-30 23:10:52'),
(14387, 'connexion', '{\"idunique\":1,\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 39ms\",\"ip\":\"109.88.221.74\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Connexion\",\"discord\":\"447086574346436618\"}', '2025-12-30 23:13:18'),
(14388, 'deconnexion', '{\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"logs_title\":\"Déconnexion\",\"discord\":\"447086574346436618\"}', '2025-12-30 23:13:19'),
(14389, 'deconnexion', '{\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"logs_title\":\"Déconnexion\",\"discord\":\"1057427236199870525\"}', '2025-12-30 23:19:46'),
(14390, 'connexion', '{\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 31ms\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"discord\":\"447086574346436618\",\"name\":\"null\"}', '2025-12-30 23:20:50'),
(14391, 'prise-service', '{\"logs_title\":\"Staff\",\"logs_message\":\"null a pris son service\",\"idunique\":1,\"name\":\"null\"}', '2025-12-30 23:21:18'),
(14392, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":1,\"discord\":\"447086574346436618\",\"name\":\"null\"}', '2025-12-30 23:21:28'),
(14393, 'connexion', '{\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 31ms\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"discord\":\"447086574346436618\",\"name\":\"null\"}', '2025-12-30 23:22:11');
INSERT INTO `vlogs` (`id`, `type`, `data`, `date`) VALUES
(14394, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":1,\"discord\":\"447086574346436618\",\"name\":\"null\"}', '2025-12-30 23:23:09'),
(14395, 'connexion', '{\"logs_title\":\"Connexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 32ms\",\"ip\":\"178.51.183.227\",\"idunique\":19,\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\"}', '2025-12-30 23:27:27'),
(14396, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":19,\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\"}', '2025-12-30 23:31:37'),
(14397, 'connexion', '{\"logs_title\":\"Connexion\",\"ip\":\"178.51.183.227\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"discord\":\"1057427236199870525\",\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 39ms\",\"name\":\"Pablo delrulio\"}', '2025-12-30 23:34:49'),
(14398, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"discord\":\"1057427236199870525\",\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"Pablo delrulio\"}', '2025-12-30 23:38:29'),
(14399, 'connexion', '{\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 31ms\",\"discord\":\"1057427236199870525\",\"ip\":\"178.51.183.227\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\",\"name\":\"Pablo delrulio\"}', '2025-12-30 23:44:15'),
(14400, 'deconnexion', '{\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"1057427236199870525\",\"idunique\":19,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\",\"name\":\"Pablo delrulio\"}', '2025-12-30 23:46:05'),
(14401, 'connexion', '{\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 35ms\",\"discord\":\"1057427236199870525\",\"ip\":\"178.51.183.227\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\",\"name\":\"Pablo delrulio\"}', '2025-12-30 23:46:39'),
(14402, 'deconnexion', '{\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"1057427236199870525\",\"idunique\":19,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\",\"name\":\"Pablo delrulio\"}', '2025-12-30 23:47:44'),
(14403, 'connexion', '{\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 35ms\",\"ip\":\"178.51.183.227\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"idunique\":19,\"discord\":\"1057427236199870525\",\"logs_title\":\"Connexion\"}', '2025-12-31 00:18:39'),
(14404, 'deconnexion', '{\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"1057427236199870525\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"idunique\":19,\"logs_title\":\"Déconnexion\"}', '2025-12-31 00:19:43'),
(14405, 'connexion', '{\"name\":\"Pablo delrulio\",\"idunique\":19,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"ip\":\"178.51.183.227\",\"discord\":\"1057427236199870525\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 43ms\",\"logs_title\":\"Connexion\"}', '2025-12-31 00:20:51'),
(14406, 'mort', '{\"name\":\"Pablo delrulio\",\"idunique\":19,\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\"}', '2025-12-31 00:20:52'),
(14407, 'mort', '{\"name\":\"Pablo delrulio\",\"idunique\":19,\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\"}', '2025-12-31 00:21:20'),
(14408, 'deconnexion', '{\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"discord\":\"1057427236199870525\",\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\"}', '2025-12-31 00:24:32'),
(14409, 'connexion', '{\"logs_title\":\"Connexion\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 36ms\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\",\"discord\":\"447086574346436618\"}', '2025-12-31 00:29:31'),
(14410, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-31 00:29:33'),
(14411, 'connexion', '{\"logs_title\":\"Connexion\",\"ip\":\"178.51.183.227\",\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 43ms\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"name\":\"Pablo delrulio\",\"discord\":\"1057427236199870525\"}', '2025-12-31 00:29:49'),
(14412, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"Pablo delrulio\",\"idunique\":19,\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\"}', '2025-12-31 00:29:49'),
(14413, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a pris son service\"}', '2025-12-31 00:30:01'),
(14414, 'annoncestaff', '{\"logs_title\":\"Logs Staff\",\"idunique_auteur\":1,\"name\":\"null\",\"logs_message\":\"Le Staff : null (U1)\\n/annoncestaff (tu dev ?)\"}', '2025-12-31 00:30:21'),
(14415, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"Pablo delrulio\",\"idunique\":19,\"logs_message\":\"Pablo delrulio a pris son service\"}', '2025-12-31 00:30:40'),
(14416, 'msgstaff', '{\"logs_title\":\"Logs Staff\",\"idunique_cible\":1,\"logs_message\":\"Pablo delrulio (U19)\\n /msgstaff (oui) le joueur null (U1)\",\"idunique_auteur\":19,\"name\":\"Pablo delrulio\",\"name_cible\":\"null\"}', '2025-12-31 00:30:49'),
(14417, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"Pablo delrulio\",\"discord\":\"1057427236199870525\"}', '2025-12-31 00:34:08'),
(14418, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"null\",\"discord\":\"447086574346436618\"}', '2025-12-31 00:34:08'),
(14419, 'connexion', '{\"logs_title\":\"Connexion\",\"discord\":\"1057427236199870525\",\"ip\":\"178.51.183.227\",\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 38ms\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-31 02:52:06'),
(14420, 'mort', '{\"logs_title\":\"Mort\",\"logs_message\":\"Pablo delrulio est mort\\n\\nCause: Inconnu\",\"idunique\":19,\"name\":\"Pablo delrulio\"}', '2025-12-31 02:52:07'),
(14421, 'connexion', '{\"logs_title\":\"Connexion\",\"discord\":\"447086574346436618\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-31 02:52:45'),
(14422, 'mort', '{\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1,\"name\":\"null\"}', '2025-12-31 02:52:47'),
(14423, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"discord\":\"1057427236199870525\",\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-31 02:53:35'),
(14424, 'prise-service', '{\"logs_title\":\"Staff\",\"logs_message\":\"null a pris son service\",\"idunique\":1,\"name\":\"null\"}', '2025-12-31 02:54:06'),
(14425, 'connexion', '{\"logs_title\":\"Connexion\",\"discord\":\"1057427236199870525\",\"ip\":\"178.51.183.227\",\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 39ms\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-31 02:54:18'),
(14426, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"discord\":\"1057427236199870525\",\"idunique\":19,\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"name\":\"Pablo delrulio\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\"}', '2025-12-31 02:54:35'),
(14427, 'deconnexion', '{\"logs_title\":\"Déconnexion\",\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: [txAdmin] Server restarting (admin request).\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-31 02:54:38'),
(14428, 'connexion', '{\"name\":\"null\",\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Connexion\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 34ms\"}', '2025-12-31 02:55:57'),
(14429, 'mort', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-31 02:55:58'),
(14430, 'connexion', '{\"name\":\"Pablo delrulio\",\"ip\":\"178.51.183.227\",\"discord\":\"1057427236199870525\",\"idunique\":19,\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Connexion\",\"logs_message\":\"Pablo delrulio s\'est connecté au serveur\\n\\nPing: 33ms\"}', '2025-12-31 02:56:19'),
(14431, 'deconnexion', '{\"name\":\"Pablo delrulio\",\"logs_message\":\"Pablo delrulio s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"1057427236199870525\",\"license\":\"license:063e3a07b7e5204a49b87053d2fd572a89659886\",\"logs_title\":\"Déconnexion\",\"idunique\":19}', '2025-12-31 02:57:57'),
(14432, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 32ms\",\"discord\":\"447086574346436618\",\"idunique\":1,\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"ip\":\"109.88.221.74\",\"logs_title\":\"Connexion\"}', '2025-12-31 03:00:00'),
(14433, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 36ms\",\"discord\":\"447086574346436618\",\"idunique\":1,\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"ip\":\"109.88.221.74\",\"logs_title\":\"Connexion\"}', '2025-12-31 03:00:02'),
(14434, 'mort', '{\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Mort\"}', '2025-12-31 03:00:03'),
(14435, 'prise-service', '{\"logs_message\":\"null a pris son service\",\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Staff\"}', '2025-12-31 03:01:32'),
(14436, 'deconnexion', '{\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"discord\":\"447086574346436618\",\"idunique\":1,\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Déconnexion\"}', '2025-12-31 03:02:05'),
(14437, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"discord\":\"447086574346436618\",\"idunique\":1,\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"ip\":\"109.88.221.74\",\"logs_title\":\"Connexion\"}', '2025-12-31 03:03:08'),
(14438, 'mort', '{\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Mort\"}', '2025-12-31 03:03:10'),
(14439, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 32ms\",\"ip\":\"109.88.221.74\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"logs_title\":\"Connexion\",\"idunique\":1}', '2025-12-31 03:10:57'),
(14440, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 21ms\",\"ip\":\"109.88.221.74\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"logs_title\":\"Connexion\",\"idunique\":1}', '2025-12-31 03:10:58'),
(14441, 'mort', '{\"name\":\"null\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\",\"idunique\":1}', '2025-12-31 03:10:59'),
(14442, 'prise-service', '{\"idunique\":1,\"logs_message\":\"null a pris son service\",\"logs_title\":\"Staff\",\"name\":\"null\"}', '2025-12-31 03:14:10'),
(14443, 'dv', '{\"idunique\":1,\"logs_message\":\"null a supprimé radius: 1\",\"logs_title\":\"Delete Véhicule\",\"name\":\"null\"}', '2025-12-31 03:15:37'),
(14444, 'deconnexion', '{\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"logs_title\":\"Déconnexion\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-31 03:15:38'),
(14445, 'connexion', '{\"name\":\"null\",\"ip\":\"109.88.221.74\",\"logs_title\":\"Connexion\",\"discord\":\"447086574346436618\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 32ms\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-31 03:27:04'),
(14446, 'deconnexion', '{\"discord\":\"447086574346436618\",\"name\":\"null\",\"logs_title\":\"Déconnexion\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"idunique\":1,\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-31 03:30:48'),
(14447, 'connexion', '{\"ip\":\"109.88.221.74\",\"name\":\"null\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 21ms\",\"logs_title\":\"Connexion\",\"idunique\":1,\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-31 03:38:26'),
(14448, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-31 03:38:28'),
(14449, 'mort', '{\"logs_title\":\"Mort\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-31 03:39:11'),
(14450, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a pris son service\"}', '2025-12-31 03:39:14'),
(14451, 'revive', '{\"name\":\"null\",\"name_cible\":\"null\",\"idunique_cible\":1,\"logs_title\":\"Logs Staff\",\"logs_message\":\"null (U1) a /revive lui meme\",\"idunique\":1}', '2025-12-31 03:39:15'),
(14452, 'deconnexion', '{\"name\":\"null\",\"discord\":\"447086574346436618\",\"logs_title\":\"Déconnexion\",\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-31 03:39:27'),
(14453, 'connexion', '{\"ip\":\"109.88.221.74\",\"name\":\"null\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 33ms\",\"logs_title\":\"Connexion\",\"idunique\":1,\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-31 03:40:28'),
(14454, 'prise-service', '{\"logs_title\":\"Staff\",\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null a pris son service\"}', '2025-12-31 03:41:20'),
(14455, 'deconnexion', '{\"name\":\"null\",\"discord\":\"447086574346436618\",\"logs_title\":\"Déconnexion\",\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-31 03:41:25'),
(14456, 'connexion', '{\"ip\":\"109.88.221.74\",\"name\":\"null\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 44ms\",\"logs_title\":\"Connexion\",\"idunique\":1,\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-31 03:42:02'),
(14457, 'deconnexion', '{\"name\":\"null\",\"discord\":\"447086574346436618\",\"logs_title\":\"Déconnexion\",\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\"}', '2025-12-31 03:43:06'),
(14458, 'connexion', '{\"idunique\":1,\"logs_title\":\"Connexion\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 35ms\",\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"name\":\"null\"}', '2025-12-31 03:44:07'),
(14459, 'connexion', '{\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"logs_title\":\"Connexion\",\"idunique\":1}', '2025-12-31 03:47:25'),
(14460, 'connexion', '{\"ip\":\"109.88.221.74\",\"discord\":\"447086574346436618\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 20ms\",\"logs_title\":\"Connexion\",\"idunique\":1}', '2025-12-31 03:47:27'),
(14461, 'mort', '{\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"logs_title\":\"Mort\",\"name\":\"null\"}', '2025-12-31 03:47:27'),
(14462, 'deconnexion', '{\"discord\":\"447086574346436618\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"logs_title\":\"Déconnexion\",\"idunique\":1}', '2025-12-31 03:47:51'),
(14463, 'connexion', '{\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 30ms\",\"idunique\":1,\"ip\":\"109.88.221.74\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Connexion\",\"discord\":\"447086574346436618\",\"name\":\"null\"}', '2025-12-31 03:49:11'),
(14464, 'mort', '{\"logs_title\":\"Mort\",\"idunique\":1,\"name\":\"null\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-31 03:49:13'),
(14465, 'connexion', '{\"discord\":\"447086574346436618\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"logs_title\":\"Connexion\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 36ms\"}', '2025-12-31 03:54:42'),
(14466, 'connexion', '{\"discord\":\"447086574346436618\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"logs_title\":\"Connexion\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 32ms\"}', '2025-12-31 03:54:44'),
(14467, 'mort', '{\"name\":\"null\",\"idunique\":1,\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-31 03:54:44'),
(14468, 'deconnexion', '{\"discord\":\"447086574346436618\",\"name\":\"null\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"idunique\":1,\"logs_title\":\"Déconnexion\",\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\"}', '2025-12-31 03:55:10'),
(14469, 'connexion', '{\"logs_title\":\"Connexion\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_message\":\"null s\'est connecté au serveur\\n\\nPing: 32ms\",\"ip\":\"109.88.221.74\",\"idunique\":1,\"name\":\"null\",\"discord\":\"447086574346436618\"}', '2025-12-31 03:55:47'),
(14470, 'mort', '{\"logs_title\":\"Mort\",\"idunique\":1,\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"name\":\"null\"}', '2025-12-31 03:55:58'),
(14471, 'mort', '{\"idunique\":1,\"name\":\"null\",\"logs_title\":\"Mort\",\"logs_message\":\"null est mort\\n\\nCause: Inconnu\"}', '2025-12-31 03:57:06'),
(14472, 'deconnexion', '{\"name\":\"null\",\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"discord\":\"447086574346436618\",\"logs_title\":\"Déconnexion\"}', '2025-12-31 03:57:19'),
(14473, 'mort', '{\"logs_message\":\"null est mort\\n\\nCause: Inconnu\",\"idunique\":1,\"logs_title\":\"Mort\",\"name\":\"null\"}', '2025-12-31 03:58:44'),
(14474, 'deconnexion', '{\"discord\":\"447086574346436618\",\"idunique\":1,\"logs_message\":\"null s\'est déconnecté\\n\\nRaison: Déconnexion volontaire\",\"license\":\"license:5474636beca7e2658e6f77079a1e6c47f98af4b6\",\"logs_title\":\"Déconnexion\",\"name\":\"null\"}', '2025-12-31 04:00:23');

-- --------------------------------------------------------

--
-- Structure de la table `voutfit`
--

CREATE TABLE `voutfit` (
  `id` int NOT NULL,
  `job` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `label` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `value` longtext COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `voutfit`
--

INSERT INTO `voutfit` (`id`, `job`, `label`, `value`) VALUES
(77, 'police', 'Test', '{\"bproof_2\":0,\"chain_2\":0,\"torso_1\":4,\"bags_1\":40,\"shoes_2\":0,\"tshirt_1\":4,\"decals_1\":0,\"torso_2\":0,\"arms\":1,\"bproof_1\":-1,\"bags_2\":0,\"mask_2\":0,\"helmet_1\":-1,\"chain_1\":-1,\"mask_1\":-1,\"glasses_2\":0,\"helmet_2\":0,\"pants_2\":1,\"tshirt_2\":0,\"shoes_1\":0,\"pants_1\":16,\"arms_2\":0,\"decals_2\":0,\"glasses_1\":-1}'),
(968, 'testbar', 'Test', '{\"arms\":0,\"bproof_1\":0,\"decals_2\":0,\"glasses_2\":0,\"bags_2\":0,\"torso_1\":0,\"bproof_2\":0,\"torso_2\":0,\"pants_1\":0,\"decals_1\":0,\"bags_1\":117,\"helmet_2\":0,\"helmet_1\":-1,\"mask_2\":0,\"chain_2\":0,\"shoes_1\":0,\"shoes_2\":0,\"glasses_1\":0,\"tshirt_2\":0,\"arms_2\":0,\"pants_2\":0,\"chain_1\":0,\"mask_1\":0,\"tshirt_1\":0}');

-- --------------------------------------------------------

--
-- Structure de la table `vsafezone`
--

CREATE TABLE `vsafezone` (
  `id` int NOT NULL,
  `name` varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  `pos` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `points` text COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vsafezone`
--

INSERT INTO `vsafezone` (`id`, `name`, `pos`, `points`) VALUES
(1, 'centralpark', '{\"x\":223.05967712402345,\"y\":-808.9253540039063,\"z\":30.62263870239257}', '[{\"x\":190.65597534179688,\"y\":-699.6787719726563},{\"x\":301.6822814941406,\"y\":-747.9944458007813},{\"x\":270.87542724609377,\"y\":-835.6273193359375},{\"x\":330.4577941894531,\"y\":-828.826171875},{\"x\":282.6182556152344,\"y\":-937.8915405273438},{\"x\":248.7435760498047,\"y\":-1026.21240234375},{\"x\":179.23532104492188,\"y\":-1005.5494995117188},{\"x\":135.75341796875,\"y\":-987.0179443359375},{\"x\":91.11309051513672,\"y\":-974.3184204101563}]'),
(2, 'Parking Rouge', '{\"x\":-353.35595703125,\"y\":-821.8330078125,\"z\":31.49366950988769}', '[{\"x\":-360.7058410644531,\"y\":-825.2479248046875},{\"x\":-334.5447692871094,\"y\":-824.9188842773438},{\"x\":-334.4112243652344,\"y\":-786.5838012695313},{\"x\":-319.6253356933594,\"y\":-773.88671875},{\"x\":-289.47039794921877,\"y\":-784.5670776367188},{\"x\":-285.9737243652344,\"y\":-779.1682739257813},{\"x\":-278.39068603515627,\"y\":-782.4354248046875},{\"x\":-274.20477294921877,\"y\":-777.580078125},{\"x\":-266.717041015625,\"y\":-752.6675415039063},{\"x\":-311.1621398925781,\"y\":-736.2266845703125},{\"x\":-305.5755310058594,\"y\":-719.9564208984375},{\"x\":-339.4119873046875,\"y\":-707.6029052734375},{\"x\":-355.7781982421875,\"y\":-707.8689575195313}]');

-- --------------------------------------------------------

--
-- Structure de la table `vsociety`
--

CREATE TABLE `vsociety` (
  `id` int NOT NULL,
  `name` longtext COLLATE utf8mb4_general_ci NOT NULL,
  `label` varchar(255) COLLATE utf8mb4_general_ci DEFAULT 'Aucun',
  `legal` tinyint(1) DEFAULT '1',
  `data` longtext COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vsociety`
--

INSERT INTO `vsociety` (`id`, `name`, `label`, `legal`, `data`) VALUES
(81, 'blood', 'blood', 1, '{\"clothes\":[{\"label\":\"Testy\",\"name\":1},{\"label\":\"Asd\",\"name\":2},null,{\"label\":\"t\",\"name\":4}],\"weapons\":{\"WEAPON_CROWBAR\":{\"name\":\"WEAPON_CROWBAR\",\"label\":\"Pied de biche\",\"count\":1},\"WEAPON_ASSAULTSMG\":{\"name\":\"WEAPON_ASSAULTSMG\",\"label\":\"Smg d\'assaut\",\"count\":1},\"WEAPON_HEAVYSNIPER_MK2\":{\"name\":\"WEAPON_HEAVYSNIPER_MK2\",\"label\":\"Sniper Lourd Mk II\",\"count\":1},\"WEAPON_HEAVYSNIPER\":{\"name\":\"WEAPON_HEAVYSNIPER\",\"label\":\"Fusil de sniper lourd\",\"count\":1},\"GADGET_PARACHUTE\":{\"name\":\"GADGET_PARACHUTE\",\"label\":\"Parachute\",\"count\":1},\"WEAPON_ASSAULTRIFLE\":{\"name\":\"WEAPON_ASSAULTRIFLE\",\"label\":\"Fusil d\'assaut\",\"count\":1}},\"items\":{\"defibrillateur\":{\"name\":\"defibrillateur\",\"label\":\"Défibrillateur\",\"count\":\"1\"},\"blue_phone\":{\"name\":\"blue_phone\",\"label\":\"Blue Phone\",\"count\":\"1\"},\"burger\":{\"name\":\"burger\",\"label\":\"Burger\",\"count\":\"3\"},\"bread\":{\"name\":\"bread\",\"label\":\"Pain\",\"count\":\"3\"},\"bandage\":{\"name\":\"bandage\",\"label\":\"Bandage\",\"count\":\"1\"},\"phone\":{\"name\":\"phone\",\"label\":\"Téléphone\",\"count\":9.0},\"armor\":{\"name\":\"armor\",\"label\":\"Kevlar\",\"count\":\"5.0\"},\"acierrecolte\":{\"name\":\"acierrecolte\",\"label\":\"Acier\",\"count\":\"11\"}},\"maxWeight\":500,\"accounts\":[{\"name\":\"cash\",\"count\":700.0},{\"name\":\"dirtycash\",\"count\":197.0}],\"weight\":50}'),
(82, 'testnull', 'testnull', 1, '{\"clothes\":[],\"weapons\":[],\"items\":{\"bread\":{\"name\":\"bread\",\"label\":\"Pain\",\"count\":\"1\"}},\"maxWeight\":500,\"accounts\":[{\"name\":\"cash\",\"count\":0},{\"name\":\"dirtycash\",\"count\":0}],\"weight\":50}'),
(83, 'null_lester', 'null_lester', 1, '{\"clothes\":[],\"weapons\":{\"WEAPON_REVOLVER\":{\"name\":\"WEAPON_REVOLVER\",\"label\":\"Revolver\",\"count\":1},\"WEAPON_HEAVYPISTOL\":{\"name\":\"WEAPON_HEAVYPISTOL\",\"label\":\"Pistolet lourd\",\"count\":1},\"WEAPON_FLASHLIGHT\":{\"name\":\"WEAPON_FLASHLIGHT\",\"label\":\"Lampe torche\",\"count\":1}},\"items\":{\"armor\":{\"name\":\"armor\",\"label\":\"Kevlar\",\"count\":\"1\"},\"bread\":{\"name\":\"bread\",\"label\":\"Pain\",\"count\":\"1\"}},\"maxWeight\":500,\"accounts\":[{\"name\":\"cash\",\"count\":0},{\"name\":\"dirtycash\",\"count\":0}],\"weight\":50}');

-- --------------------------------------------------------

--
-- Structure de la table `vstash`
--

CREATE TABLE `vstash` (
  `id` int NOT NULL,
  `pos` text COLLATE utf8mb4_general_ci NOT NULL,
  `passwork` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vstash`
--

INSERT INTO `vstash` (`id`, `pos`, `passwork`) VALUES
(1, '{\"x\":114.8919225,\"y\":-1074.697754,\"z\":29.192348}', NULL);

-- --------------------------------------------------------

--
-- Structure de la table `vstorage`
--

CREATE TABLE `vstorage` (
  `id` int NOT NULL,
  `name` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `coffre` text COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vstorage`
--

INSERT INTO `vstorage` (`id`, `name`, `coffre`) VALUES
(2, 'staffchest', '{\"cash\":0,\"items\":[],\"clothes\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(3, 'police', '{\"clothes\":[],\"cash\":0,\"dirtycash\":0,\"items\":[{\"unique\":false,\"name\":\"caisse_fidelite\",\"count\":8,\"metadata\":[]},{\"unique\":false,\"name\":\"weedscissors\",\"count\":2,\"metadata\":[]},{\"unique\":false,\"name\":\"weed_head\",\"count\":10,\"metadata\":[]}],\"loadout\":[{\"components\":[],\"durability\":0,\"name\":\"WEAPON_PISTOL\",\"permanent\":false,\"metadata\":[]}]}'),
(4, 'burgershot', '{\"items\":[],\"cash\":0,\"maxWeight\":1000,\"dirtycash\":0,\"loadout\":[],\"clothes\":[]}'),
(5, 'unicorn', '{\"cash\":0,\"items\":[],\"clothes\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(6, 'labo_coffre_1', '{\"maxWeight\":1000,\"dirtycash\":0,\"loadout\":[],\"clothes\":[],\"cash\":0,\"items\":[{\"count\":100,\"weight\":1,\"name\":\"plantpot\"},{\"count\":200,\"weight\":1,\"name\":\"engrais-weed\"},{\"count\":100,\"weight\":1,\"name\":\"maleseed\"},{\"count\":100,\"weight\":1,\"name\":\"femaleseed\"},{\"count\":7,\"weight\":1,\"name\":\"hazmat\"},{\"count\":8,\"weight\":1,\"name\":\"deo\"},{\"count\":50,\"weight\":1,\"name\":\"dirt-weed\"},{\"count\":15,\"weight\":1,\"name\":\"weedscissors\"},{\"count\":100,\"weight\":1,\"name\":\"water-weed\"},{\"name\":\"empty_pooch\",\"weight\":1,\"count\":1000},{\"count\":200,\"weight\":1,\"name\":\"weed_plant\"},{\"name\":\"weed_plant_dry\",\"weight\":1,\"count\":200},{\"count\":1000,\"weight\":1,\"name\":\"weed_pooch\"}]}'),
(7, 'labo_coffre_4', '{\"dirtycash\":0,\"loadout\":[],\"cash\":0,\"clothes\":[],\"items\":[],\"maxWeight\":1000}'),
(8, 'bloods', '{\"items\":[],\"dirtycash\":0,\"cash\":0,\"maxWeight\":1000,\"loadout\":[{\"weight\":5,\"name\":\"WEAPON_PISTOL\"}],\"clothes\":[]}'),
(9, 'labo_coffre_6', '{\"clothes\":[],\"items\":[{\"name\":\"hazmat\",\"count\":1}],\"loadout\":[],\"dirtycash\":0,\"cash\":0,\"maxWeight\":1000}'),
(10, 'labo_coffre_5', '{\"clothes\":[],\"loadout\":[],\"items\":[{\"name\":\"engrais-weed\",\"weight\":1,\"count\":199},{\"weight\":1,\"name\":\"weed_pooch\",\"count\":3010}],\"maxWeight\":1000,\"cash\":0,\"dirtycash\":0}'),
(11, 'itemlist', '{\"dirtycash\":9999999999,\"loadout\":[{\"name\":\"WEAPON_KNIFE\"},{\"name\":\"WEAPON_NIGHTSTICK\"},{\"name\":\"WEAPON_HAMMER\"},{\"name\":\"WEAPON_BAT\"},{\"name\":\"WEAPON_GOLFCLUB\"},{\"name\":\"WEAPON_CROWBAR\"},{\"name\":\"WEAPON_NAVYREVOLVER\"},{\"name\":\"WEAPON_GADGETPISTOL\"},{\"name\":\"WEAPON_COMBATSHOTGUN\"},{\"name\":\"WEAPON_MILITARYRIFLE\"},{\"name\":\"WEAPON_STONE_HATCHET\"},{\"name\":\"WEAPON_SCAR17FM\"},{\"name\":\"WEAPON_HKUMP\"},{\"name\":\"WEAPON_M4A1FM\"},{\"name\":\"WEAPON_GLOCK\"},{\"name\":\"WEAPON_DOUBLEBARRELFM\"},{\"name\":\"WEAPON_PISTOL\"},{\"name\":\"WEAPON_COMBATPISTOL\"},{\"name\":\"WEAPON_APPISTOL\"},{\"name\":\"WEAPON_PISTOL50\"},{\"name\":\"WEAPON_REVOLVER\"},{\"name\":\"WEAPON_SNSPISTOL\"},{\"name\":\"WEAPON_HEAVYPISTOL\"},{\"name\":\"WEAPON_VINTAGEPISTOL\"},{\"name\":\"WEAPON_MICROSMG\"},{\"name\":\"WEAPON_SMG\"},{\"name\":\"WEAPON_ASSAULTSMG\"},{\"name\":\"WEAPON_MINISMG\"},{\"name\":\"WEAPON_MACHINEPISTOL\"},{\"name\":\"WEAPON_COMBATPDW\"},{\"name\":\"WEAPON_PUMPSHOTGUN\"},{\"name\":\"WEAPON_SAWNOFFSHOTGUN\"},{\"name\":\"WEAPON_ASSAULTSHOTGUN\"},{\"name\":\"WEAPON_BULLPUPSHOTGUN\"},{\"name\":\"WEAPON_HEAVYSHOTGUN\"},{\"name\":\"WEAPON_ASSAULTRIFLE\"},{\"name\":\"WEAPON_CARBINERIFLE\"},{\"name\":\"WEAPON_ADVANCEDRIFLE\"},{\"name\":\"WEAPON_SPECIALCARBINE\"},{\"name\":\"WEAPON_BULLPUPRIFLE\"},{\"name\":\"WEAPON_COMPACTRIFLE\"},{\"name\":\"WEAPON_MG\"},{\"name\":\"WEAPON_COMBATMG\"},{\"name\":\"WEAPON_GUSENBERG\"},{\"name\":\"WEAPON_SNIPERRIFLE\"},{\"name\":\"WEAPON_HEAVYSNIPER\"},{\"name\":\"WEAPON_MARKSMANRIFLE\"},{\"name\":\"WEAPON_GRENADELAUNCHER\"},{\"name\":\"WEAPON_RPG\"},{\"name\":\"WEAPON_MINIGUN\"},{\"name\":\"WEAPON_GRENADE\"},{\"name\":\"WEAPON_STICKYBOMB\"},{\"name\":\"WEAPON_SMOKEGRENADE\"},{\"name\":\"WEAPON_BZGAS\"},{\"name\":\"WEAPON_MOLOTOV\"},{\"name\":\"WEAPON_FIREEXTINGUISHER\"},{\"name\":\"WEAPON_PETROLCAN\"},{\"name\":\"WEAPON_DIGISCANNER\"},{\"name\":\"WEAPON_BALL\"},{\"name\":\"WEAPON_BOTTLE\"},{\"name\":\"WEAPON_DAGGER\"},{\"name\":\"WEAPON_FIREWORK\"},{\"name\":\"WEAPON_MUSKET\"},{\"name\":\"WEAPON_STUNGUN\"},{\"name\":\"WEAPON_HOMINGLAUNCHER\"},{\"name\":\"WEAPON_PROXMINE\"},{\"name\":\"WEAPON_SNOWBALL\"},{\"name\":\"WEAPON_FLAREGUN\"},{\"name\":\"WEAPON_GARBAGEBAG\"},{\"name\":\"WEAPON_HANDCUFFS\"},{\"name\":\"WEAPON_MARKSMANPISTOL\"},{\"name\":\"WEAPON_KNUCKLE\"},{\"name\":\"WEAPON_HATCHET\"},{\"name\":\"WEAPON_RAILGUN\"},{\"name\":\"WEAPON_MACHETE\"},{\"name\":\"WEAPON_SWITCHBLADE\"},{\"name\":\"WEAPON_DBSHOTGUN\"},{\"name\":\"WEAPON_AUTOSHOTGUN\"},{\"name\":\"WEAPON_BATTLEAXE\"},{\"name\":\"WEAPON_COMPACTLAUNCHER\"},{\"name\":\"WEAPON_PIPEBOMB\"},{\"name\":\"WEAPON_POOLCUE\"},{\"name\":\"WEAPON_WRENCH\"},{\"name\":\"WEAPON_FLASHLIGHT\"},{\"name\":\"GADGET_NIGHTVISION\"},{\"name\":\"GADGET_PARACHUTE\"},{\"name\":\"WEAPON_FLARE\"},{\"name\":\"WEAPON_DOUBLEACTION\"},{\"name\":\"WEAPON_SNSPISTOL_MK2\"},{\"name\":\"WEAPON_REVOLVER_MK2\"},{\"name\":\"WEAPON_SPECIALCARBINE_MK2\"},{\"name\":\"WEAPON_BULLPUPRIFLE_MK2\"},{\"name\":\"WEAPON_PUMPSHOTGUN_MK2\"},{\"name\":\"WEAPON_MARKSMANRIFLE_MK2\"},{\"name\":\"WEAPON_ASSAULTRIFLE_MK2\"},{\"name\":\"WEAPON_CARBINERIFLE_MK2\"},{\"name\":\"WEAPON_COMBATMG_MK2\"},{\"name\":\"WEAPON_HEAVYSNIPER_MK2\"},{\"name\":\"WEAPON_PISTOL_MK2\"},{\"name\":\"WEAPON_SMG_MK2\"},{\"name\":\"WEAPON_HEAVYREVOLVER_MK2\"},{\"name\":\"WEAPON_HUNTSMAN\"},{\"name\":\"WEAPON_KATANA\"},{\"name\":\"WEAPON_REDL\"},{\"name\":\"WEAPON_AKORUS\"},{\"name\":\"WEAPON_MILITARM4\"},{\"name\":\"WEAPON_GOLDM\"},{\"name\":\"WEAPON_PREDATOR\"},{\"name\":\"WEAPON_KINETIC\"},{\"name\":\"WEAPON_SCARSC\"},{\"name\":\"WEAPON_TEC9M\"},{\"name\":\"WEAPON_TEC9MF\"},{\"name\":\"WEAPON_TEC9MB\"},{\"name\":\"WEAPON_BLASTAK\"},{\"name\":\"WEAPON_BLASTM4\"},{\"name\":\"WEAPON_SIG550\"},{\"name\":\"WEAPON_BLACKSNIPER\"},{\"name\":\"WEAPON_SOVEREIGN\"},{\"name\":\"WEAPON_GLOCK17\"},{\"name\":\"WEAPON_COACHGUN\"},{\"name\":\"WEAPON_SHOTGUNK\"},{\"name\":\"WEAPON_VSCO\"},{\"name\":\"WEAPON_BLUERIOT\"},{\"name\":\"WEAPON_ANCIENT\"},{\"name\":\"WEAPON_SNAKE\"},{\"name\":\"WEAPON_HELL\"},{\"name\":\"WEAPON_OBLIVION\"},{\"name\":\"WEAPON_ALIEN\"},{\"name\":\"WEAPON_MIDGARD\"},{\"name\":\"WEAPON_CHAINSAW\"},{\"name\":\"WEAPON_SPECIALHAMMER\"},{\"name\":\"WEAPON_PENIS\"},{\"name\":\"WEAPON_MAZE\"},{\"name\":\"WEAPON_REVOLVERVAMP\"},{\"name\":\"WEAPON_GUARD\"},{\"name\":\"WEAPON_GRAU\"},{\"name\":\"WEAPON_SCAR17\"},{\"name\":\"WEAPON_M19\"},{\"name\":\"WEAPON_SPIDERAK\"},{\"name\":\"WEAPON_PUMPKIN\"},{\"name\":\"WEAPON_BONEPER\"},{\"name\":\"WEAPON_DESERTPURPLE\"},{\"name\":\"WEAPON_REVOLVERULTRA\"},{\"name\":\"WEAPON_AKS74U\"}],\"cash\":9999999999,\"maxWeight\":-1,\"items\":[{\"count\":999999,\"name\":\"soda\",\"weight\":0.5},{\"count\":999999,\"name\":\"salade\",\"weight\":0.25},{\"count\":999999,\"name\":\"terresec\",\"weight\":0},{\"count\":999999,\"name\":\"ammo_sniper\",\"weight\":0.2},{\"count\":999999,\"name\":\"pain_legume_legume\",\"weight\":1},{\"count\":999999,\"name\":\"beer\",\"weight\":0.1},{\"count\":999999,\"name\":\"lingotor\",\"weight\":0.5},{\"count\":999999,\"name\":\"cocainetraitement\",\"weight\":0.25},{\"count\":999999,\"name\":\"testrestaurant\",\"weight\":1},{\"count\":999999,\"name\":\"zetony\",\"weight\":-1},{\"count\":999999,\"name\":\"whiskycoca\",\"weight\":0.5},{\"count\":999999,\"name\":\"basic_cuff\",\"weight\":0.3},{\"count\":999999,\"name\":\"saumon\",\"weight\":1},{\"count\":999999,\"name\":\"acierrecolte\",\"weight\":0.25},{\"count\":999999,\"name\":\"weedtraitement\",\"weight\":0.25},{\"count\":999999,\"name\":\"composant_weapon\",\"weight\":1},{\"count\":999999,\"name\":\"boissoncola\",\"weight\":1},{\"count\":999999,\"name\":\"tabac\",\"weight\":0.25},{\"count\":999999,\"name\":\"weedrecolte\",\"weight\":1},{\"count\":999999,\"name\":\"hack_laptop\",\"weight\":1},{\"count\":999999,\"name\":\"camera\",\"weight\":2},{\"count\":999999,\"name\":\"weed_pooch\",\"weight\":0.01},{\"count\":999999,\"name\":\"bubbletea\",\"weight\":1},{\"count\":999999,\"name\":\"weed_plant_dry\",\"weight\":2},{\"count\":999999,\"name\":\"identity_card\",\"weight\":0.1},{\"count\":999999,\"name\":\"3glace\",\"weight\":1},{\"count\":999999,\"name\":\"pepsi\",\"weight\":0.2},{\"count\":999999,\"name\":\"cocafinale\",\"weight\":1},{\"count\":999999,\"name\":\"test\",\"weight\":1},{\"count\":999999,\"name\":\"cleankit\",\"weight\":1},{\"count\":999999,\"name\":\"weapon\",\"weight\":0.2},{\"count\":999999,\"name\":\"water-weed\",\"weight\":1},{\"count\":999999,\"name\":\"radiateur\",\"weight\":1},{\"count\":999999,\"name\":\"lettre\",\"weight\":0.25},{\"count\":999999,\"name\":\"cheese\",\"weight\":1},{\"count\":999999,\"name\":\"vodka\",\"weight\":0.05},{\"count\":999999,\"name\":\"vin\",\"weight\":0.25},{\"count\":999999,\"name\":\"bankcard2\",\"weight\":1},{\"count\":999999,\"name\":\"doublecheese_packaged\",\"weight\":1},{\"count\":999999,\"name\":\"plastique\",\"weight\":1},{\"count\":999999,\"name\":\"7upfinale\",\"weight\":1},{\"count\":999999,\"name\":\"bankcard\",\"weight\":1},{\"count\":999999,\"name\":\"pneu\",\"weight\":0.5},{\"count\":999999,\"name\":\"280burger_packaged\",\"weight\":1},{\"count\":999999,\"name\":\"mdmatraitement\",\"weight\":0.25},{\"count\":999999,\"name\":\"caisse_fidelite\",\"weight\":0},{\"count\":999999,\"name\":\"tomatemozza_packaged\",\"weight\":1},{\"count\":999999,\"name\":\"methbrute\",\"weight\":2},{\"count\":999999,\"name\":\"planche\",\"weight\":0.25},{\"count\":999999,\"name\":\"aciertraiter\",\"weight\":1},{\"count\":999999,\"name\":\"plantpot\",\"weight\":2},{\"count\":999999,\"name\":\"the\",\"weight\":0.01},{\"count\":999999,\"name\":\"drive\",\"weight\":0.2},{\"count\":999999,\"name\":\"ammo_shotgun\",\"weight\":0.2},{\"count\":999999,\"name\":\"bubble_tea_violet\",\"weight\":1},{\"count\":999999,\"name\":\"cocafrais\",\"weight\":0.1},{\"count\":999999,\"name\":\"testraitement\",\"weight\":1},{\"count\":999999,\"name\":\"sim\",\"weight\":0},{\"count\":999999,\"name\":\"drill\",\"weight\":0.25},{\"count\":999999,\"name\":\"basenull\",\"weight\":1},{\"count\":999999,\"name\":\"dirt-weed\",\"weight\":1},{\"count\":999999,\"name\":\"basic_key\",\"weight\":0.1},{\"count\":999999,\"name\":\"jusfruit\",\"weight\":0.5},{\"count\":999999,\"name\":\"bubbleteacitron\",\"weight\":1},{\"count\":999999,\"name\":\"caisse_afk_gold\",\"weight\":1},{\"count\":999999,\"name\":\"bubble_tea_bleu\",\"weight\":1},{\"count\":999999,\"name\":\"testfarm1\",\"weight\":0.25},{\"count\":999999,\"name\":\"fentanyl\",\"weight\":0.25},{\"count\":999999,\"name\":\"testfarm\",\"weight\":0.25},{\"count\":999999,\"name\":\"fanta\",\"weight\":1.4},{\"count\":999999,\"name\":\"testdrugstraitement\",\"weight\":1},{\"count\":999999,\"name\":\"ketamine\",\"weight\":0.25},{\"count\":999999,\"name\":\"testdrugs\",\"weight\":1},{\"count\":999999,\"name\":\"caisse_ruby\",\"weight\":0},{\"count\":999999,\"name\":\"ceinture_explosive\",\"weight\":5},{\"count\":999999,\"name\":\"apple\",\"weight\":0.1},{\"count\":999999,\"name\":\"tequila\",\"weight\":0.5},{\"count\":999999,\"name\":\"weedscissors\",\"weight\":0.6},{\"count\":999999,\"name\":\"caisse_gold\",\"weight\":0},{\"count\":999999,\"name\":\"sucre\",\"weight\":1},{\"count\":999999,\"name\":\"solvant-meth\",\"weight\":1.5},{\"count\":999999,\"name\":\"cocavanille\",\"weight\":1},{\"count\":999999,\"name\":\"hazmat\",\"weight\":1},{\"count\":999999,\"name\":\"steak\",\"weight\":1},{\"count\":999999,\"name\":\"alcooldecontrebande\",\"weight\":1},{\"count\":999999,\"name\":\"spaghettibolo_packaged\",\"weight\":1},{\"count\":999999,\"name\":\"sim_card\",\"weight\":1},{\"count\":999999,\"name\":\"cagoule\",\"weight\":1},{\"count\":999999,\"name\":\"seauplein\",\"weight\":0},{\"count\":999999,\"name\":\"salade1\",\"weight\":1},{\"count\":999999,\"name\":\"7up\",\"weight\":0.1},{\"count\":999999,\"name\":\"rhum\",\"weight\":1.5},{\"count\":999999,\"name\":\"lockpick\",\"weight\":1},{\"count\":999999,\"name\":\"nightvision\",\"weight\":1},{\"count\":999999,\"name\":\"sacvide\",\"weight\":0.3},{\"count\":999999,\"name\":\"fixtool\",\"weight\":2},{\"count\":999999,\"name\":\"fentanyltraitement\",\"weight\":0.25},{\"count\":999999,\"name\":\"sacplein\",\"weight\":0.5},{\"count\":999999,\"name\":\"CupCake\",\"weight\":1},{\"count\":999999,\"name\":\"opiumrecolte\",\"weight\":1},{\"count\":999999,\"name\":\"boitepizza\",\"weight\":1},{\"count\":999999,\"name\":\"coke_pooch\",\"weight\":0.1},{\"count\":999999,\"name\":\"cigare\",\"weight\":0.5},{\"count\":999999,\"name\":\"rolex\",\"weight\":0},{\"count\":999999,\"name\":\"codeine\",\"weight\":1},{\"count\":999999,\"name\":\"cocaine\",\"weight\":1},{\"count\":999999,\"name\":\"mdma\",\"weight\":0.25},{\"count\":999999,\"name\":\"burger_burgershot\",\"weight\":0.2},{\"count\":999999,\"name\":\"bubble_tea_orange\",\"weight\":1},{\"count\":999999,\"name\":\"bubble_tea\",\"weight\":1},{\"count\":999999,\"name\":\"burgerdouble\",\"weight\":1},{\"count\":999999,\"name\":\"lait\",\"weight\":1},{\"count\":999999,\"name\":\"engrais-weed\",\"weight\":3},{\"count\":999999,\"name\":\"carokit\",\"weight\":3},{\"count\":999999,\"name\":\"argent\",\"weight\":1},{\"count\":999999,\"name\":\"caisse_diamond\",\"weight\":0},{\"count\":999999,\"name\":\"cuivreetamer\",\"weight\":0.5},{\"count\":999999,\"name\":\"id_card\",\"weight\":1},{\"count\":999999,\"name\":\"levier\",\"weight\":2},{\"count\":999999,\"name\":\"raisin\",\"weight\":0.5},{\"count\":999999,\"name\":\"jetoncustom\",\"weight\":0},{\"count\":999999,\"name\":\"papier\",\"weight\":0.25},{\"count\":999999,\"name\":\"firstaidkit\",\"weight\":1},{\"count\":999999,\"name\":\"grapperaisin\",\"weight\":0.5},{\"count\":999999,\"name\":\"doublechesse_burgershot\",\"weight\":1},{\"count\":999999,\"name\":\"water\",\"weight\":0.1},{\"count\":999999,\"name\":\"triplecheese_packaged\",\"weight\":1},{\"count\":999999,\"name\":\"pot\",\"weight\":1.2},{\"count\":999999,\"name\":\"weed_head\",\"weight\":0.07},{\"count\":999999,\"name\":\"pommedeterre\",\"weight\":0.1},{\"count\":999999,\"name\":\"bandage\",\"weight\":0.2},{\"count\":999999,\"name\":\"champagne\",\"weight\":0.4},{\"count\":999999,\"name\":\"gofast_tablet\",\"weight\":1},{\"count\":999999,\"name\":\"acid-meth\",\"weight\":1.5},{\"count\":999999,\"name\":\"pomme\",\"weight\":0.1},{\"count\":999999,\"name\":\"police_key\",\"weight\":0.1},{\"count\":999999,\"name\":\"handcuff\",\"weight\":0.3},{\"count\":999999,\"name\":\"police_cuff\",\"weight\":0.3},{\"count\":999999,\"name\":\"pelle\",\"weight\":0.7},{\"count\":999999,\"name\":\"ciseaux\",\"weight\":1},{\"count\":999999,\"name\":\"bois\",\"weight\":0.25},{\"count\":999999,\"name\":\"caisse_arme\",\"weight\":1},{\"count\":999999,\"name\":\"testfarm2\",\"weight\":0.25},{\"count\":999999,\"name\":\"cola\",\"weight\":0.1},{\"count\":999999,\"name\":\"fromage\",\"weight\":0.25},{\"count\":999999,\"name\":\"fraises\",\"weight\":1},{\"count\":999999,\"name\":\"vetement\",\"weight\":0},{\"count\":999999,\"name\":\"pepperspray\",\"weight\":1},{\"count\":999999,\"name\":\"burger\",\"weight\":0.3},{\"count\":999999,\"name\":\"cuivre\",\"weight\":0.5},{\"count\":999999,\"name\":\"tomatedrusillas\",\"weight\":1},{\"count\":999999,\"name\":\"armor\",\"weight\":0.5},{\"count\":999999,\"name\":\"pizzamargaritta_packaged\",\"weight\":1},{\"count\":999999,\"name\":\"piluleoubli\",\"weight\":1},{\"count\":999999,\"name\":\"ketaminetraitement\",\"weight\":0.25},{\"count\":999999,\"name\":\"chargeur\",\"weight\":0.8},{\"count\":999999,\"name\":\"gauffredrusillas\",\"weight\":1},{\"count\":999999,\"name\":\"phosphorus-meth\",\"weight\":1.5},{\"count\":999999,\"name\":\"frites\",\"weight\":0.5},{\"count\":999999,\"name\":\"caisse_afk_legendaire\",\"weight\":1},{\"count\":999999,\"name\":\"phone\",\"weight\":0.3},{\"count\":999999,\"name\":\"permisconduire\",\"weight\":-1},{\"count\":999999,\"name\":\"pepsiingredient\",\"weight\":1},{\"count\":999999,\"name\":\"opiumtraitement\",\"weight\":1},{\"count\":999999,\"name\":\"jagerbomb\",\"weight\":0.5},{\"count\":999999,\"name\":\"pepsi2\",\"weight\":0.1},{\"count\":999999,\"name\":\"grand_cru\",\"weight\":0.2},{\"count\":999999,\"name\":\"poster\",\"weight\":1},{\"count\":999999,\"name\":\"testtraitement\",\"weight\":1},{\"count\":999999,\"name\":\"patesaumon_packaged\",\"weight\":1},{\"count\":999999,\"name\":\"weed_plant\",\"weight\":3},{\"count\":999999,\"name\":\"parachute\",\"weight\":1},{\"count\":999999,\"name\":\"bag\",\"weight\":1},{\"count\":999999,\"name\":\"radiobox\",\"weight\":0.5},{\"count\":999999,\"name\":\"painburger\",\"weight\":1},{\"count\":999999,\"name\":\"pack_of_frite\",\"weight\":1},{\"count\":999999,\"name\":\"oxygen_mask\",\"weight\":0.6},{\"count\":999999,\"name\":\"mobilier\",\"weight\":5},{\"count\":999999,\"name\":\"methtraitement\",\"weight\":1},{\"count\":999999,\"name\":\"deo\",\"weight\":0.5},{\"count\":999999,\"name\":\"methrecolte\",\"weight\":1},{\"count\":999999,\"name\":\"femaleseed\",\"weight\":0.1},{\"count\":999999,\"name\":\"dessertfraise\",\"weight\":1},{\"count\":999999,\"name\":\"chest_50\",\"weight\":7},{\"count\":999999,\"name\":\"meth_pooch\",\"weight\":0.1},{\"count\":999999,\"name\":\"meth_mixture\",\"weight\":1.5},{\"count\":999999,\"name\":\"metaux\",\"weight\":2},{\"count\":999999,\"name\":\"armor391\",\"weight\":0.5},{\"count\":999999,\"name\":\"cayotraitement\",\"weight\":1},{\"count\":999999,\"name\":\"bubbleteaargent\",\"weight\":1},{\"count\":999999,\"name\":\"menu_classic_burgershot\",\"weight\":1},{\"count\":999999,\"name\":\"bread\",\"weight\":0.1},{\"count\":999999,\"name\":\"carotool\",\"weight\":4},{\"count\":999999,\"name\":\"whisky\",\"weight\":0.4},{\"count\":999999,\"name\":\"delivery_tablet\",\"weight\":1},{\"count\":999999,\"name\":\"2tomate\",\"weight\":1},{\"count\":999999,\"name\":\"BubbleTea\",\"weight\":1},{\"count\":999999,\"name\":\"maleseed\",\"weight\":0.1},{\"count\":999999,\"name\":\"laptop\",\"weight\":-1},{\"count\":999999,\"name\":\"repairkit\",\"weight\":2},{\"count\":999999,\"name\":\"cocacola\",\"weight\":0.1},{\"count\":999999,\"name\":\"classic_phone\",\"weight\":-1},{\"count\":999999,\"name\":\"boite_lettres\",\"weight\":0.25},{\"count\":999999,\"name\":\"jus_raisin\",\"weight\":0.5},{\"count\":999999,\"name\":\"boeufdrussi\",\"weight\":1},{\"count\":999999,\"name\":\"cafe\",\"weight\":0.1},{\"count\":999999,\"name\":\"acier\",\"weight\":1},{\"count\":999999,\"name\":\"jewels\",\"weight\":0.2},{\"count\":999999,\"name\":\"jagercerbere\",\"weight\":0.5},{\"count\":999999,\"name\":\"champignonrecolte\",\"weight\":1},{\"count\":999999,\"name\":\"beef_cuit\",\"weight\":1},{\"count\":999999,\"name\":\"patefraiche\",\"weight\":1},{\"count\":999999,\"name\":\"icetea\",\"weight\":0.1},{\"count\":999999,\"name\":\"blackphone\",\"weight\":0},{\"count\":999999,\"name\":\"ice\",\"weight\":0.1},{\"count\":999999,\"name\":\"empty_pooch\",\"weight\":0.01},{\"count\":999999,\"name\":\"classic_burger_burgershot\",\"weight\":1},{\"count\":999999,\"name\":\"radio\",\"weight\":0.5},{\"count\":999999,\"name\":\"ammo_rifle\",\"weight\":0.12},{\"count\":999999,\"name\":\"jumelles\",\"weight\":0.25},{\"count\":999999,\"name\":\"jus_coca\",\"weight\":0.5},{\"count\":999999,\"name\":\"pepiteor\",\"weight\":0.5},{\"count\":999999,\"name\":\"chest_100\",\"weight\":12},{\"count\":999999,\"name\":\"cocainerecolte\",\"weight\":0.25},{\"count\":999999,\"name\":\"kevlar\",\"weight\":1},{\"count\":999999,\"name\":\"ammo_pistol\",\"weight\":0.1},{\"count\":999999,\"name\":\"menthe\",\"weight\":0.1},{\"count\":999999,\"name\":\"medikit\",\"weight\":2},{\"count\":999999,\"name\":\"armor392\",\"weight\":0.5},{\"count\":999999,\"name\":\"aciertraitement\",\"weight\":0.25},{\"count\":999999,\"name\":\"coca\",\"weight\":1},{\"count\":999999,\"name\":\"alcoolbrut\",\"weight\":1},{\"count\":999999,\"name\":\"cayorecolte\",\"weight\":1},{\"count\":999999,\"name\":\"chest_25\",\"weight\":4},{\"count\":999999,\"name\":\"vanille\",\"weight\":0.1},{\"count\":999999,\"name\":\"chocolat\",\"weight\":0.1},{\"count\":999999,\"name\":\"champignontraitement\",\"weight\":1},{\"count\":999999,\"name\":\"armor390\",\"weight\":0.5},{\"count\":999999,\"name\":\"cigarette\",\"weight\":0.1},{\"count\":999999,\"name\":\"classicburger\",\"weight\":1},{\"count\":999999,\"name\":\"pseudoephedrine\",\"weight\":0.5},{\"count\":999999,\"name\":\"ring\",\"weight\":-1},{\"count\":999999,\"name\":\"bank_card\",\"weight\":0.1},{\"count\":999999,\"name\":\"hotdog\",\"weight\":0.3},{\"count\":999999,\"name\":\"defibrillateur\",\"weight\":2},{\"count\":999999,\"name\":\"redbull\",\"weight\":0.3},{\"count\":999999,\"name\":\"boulesdetapioca\",\"weight\":1},{\"count\":999999,\"name\":\"codeinetraitement\",\"weight\":1},{\"count\":999999,\"name\":\"plateau_meth_brute\",\"weight\":1},{\"count\":999999,\"name\":\"eau\",\"weight\":0.01},{\"count\":999999,\"name\":\"fixkit\",\"weight\":1.5}],\"clothes\":[{\"label\":\"Vetement Haut\",\"data\":{\"torso_2\":0,\"torso_1\":15},\"id\":1,\"type\":\"top\",\"name\":\"top\"},{\"label\":\"Vetement Chaussure\",\"data\":{\"shoes_2\":0,\"shoes_1\":15},\"id\":1,\"type\":\"shoes\",\"name\":\"shoes\"},{\"label\":\"Vetement Bas\",\"data\":{\"pants_1\":15,\"pants_2\":0},\"id\":1,\"type\":\"pants\",\"name\":\"pants\"}]}'),
(12, 'labo_coffre_2', '{\"cash\":0,\"items\":[],\"clothes\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(13, 'bikeshop', '{\"cash\":0,\"items\":[],\"clothes\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(14, 'proprieties_stockage', '{\"items\":[{\"count\":11,\"name\":\"cocafrais\",\"weight\":1},{\"count\":2,\"name\":\"cola\",\"weight\":1},{\"count\":2,\"name\":\"caisse_fidelite\",\"weight\":1},{\"count\":2,\"name\":\"deo\",\"weight\":1},{\"name\":\"hazmat\",\"count\":2}],\"maxWeight\":1000,\"dirtycash\":0,\"loadout\":[],\"clothes\":[],\"cash\":0}'),
(24, 'proprieties_High85430296', '{\"items\":[],\"clothes\":[],\"cash\":0,\"maxWeight\":1000,\"loadout\":[],\"dirtycash\":0}'),
(25, 'labo_coffre_3', '{\"cash\":0,\"items\":[],\"clothes\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(26, 'gouvernement', '{\"cash\":0,\"items\":[],\"clothes\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(27, 'emsnord', '{\"cash\":0,\"items\":[],\"clothes\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(28, 'stash_ambulance', '{\"cash\":0,\"items\":[],\"clothes\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(29, 'labo_coffre_big_1', '{\"maxWeight\":1000,\"clothes\":[],\"items\":[{\"metadata\":[],\"unique\":false,\"name\":\"empty_pooch\",\"count\":167}],\"loadout\":[],\"dirtycash\":0,\"cash\":0}'),
(30, 'labo_coffre_big_3', '{\"loadout\":[{\"permanent\":false,\"metadata\":[],\"components\":[],\"name\":\"WEAPON_KNIFE\",\"durability\":0}],\"cash\":0,\"clothes\":[],\"items\":[{\"count\":201,\"weight\":1,\"name\":\"weed_head\",\"metadata\":[],\"unique\":false},{\"count\":2471,\"weight\":1,\"name\":\"weed_pooch\",\"metadata\":[],\"unique\":false}],\"dirtycash\":0,\"maxWeight\":1000}'),
(31, 'labo_coffre_big_2', '{\"items\":[{\"weight\":1,\"name\":\"water-weed\",\"unique\":false,\"metadata\":[],\"count\":90},{\"weight\":1,\"name\":\"engrais-weed\",\"count\":90,\"metadata\":[],\"unique\":false},{\"weight\":1,\"unique\":false,\"name\":\"weed_plant_dry\",\"metadata\":[],\"count\":200},{\"weight\":1,\"unique\":false,\"count\":900,\"metadata\":[],\"name\":\"empty_pooch\"},{\"weight\":1,\"name\":\"dirt-weed\",\"unique\":false,\"metadata\":[],\"count\":90},{\"name\":\"weedscissors\",\"unique\":false,\"count\":2,\"metadata\":[]}],\"maxWeight\":1000,\"cash\":0,\"clothes\":[],\"dirtycash\":0,\"loadout\":[]}'),
(32, 'labo_dropbox_1', '{\"dirtycash\":0,\"maxWeight\":1000,\"cash\":0,\"clothes\":[],\"loadout\":[],\"items\":[{\"label\":\"Phosphore rouge\",\"name\":\"phosphorus-meth\",\"weight\":1.5,\"count\":1},{\"label\":\"Pochon Vide\",\"name\":\"empty_pooch\",\"weight\":0.01,\"count\":1},{\"label\":\"Pseudoéphédrine\",\"name\":\"pseudoephedrine\",\"weight\":0.5,\"count\":2},{\"label\":\"Solvant\",\"name\":\"solvant-meth\",\"weight\":1.5,\"count\":1},{\"label\":\"Acide\",\"name\":\"acid-meth\",\"weight\":1.5,\"count\":2},{\"count\":1,\"name\":\"water-weed\",\"weight\":1,\"label\":\"1L Eau Minéraliser\"},{\"label\":\"Engrais\",\"name\":\"engrais-weed\",\"weight\":3,\"count\":1},{\"label\":\"Grand Ciseau\",\"name\":\"weedscissors\",\"weight\":0.6,\"count\":1}]}'),
(33, 'labo_dropbox_2', '{\"items\":[{\"weight\":0.6,\"name\":\"weedscissors\",\"count\":2,\"label\":\"Grand Ciseau\"},{\"count\":2,\"name\":\"plantpot\",\"label\":\"Pot de plante\",\"weight\":2},{\"weight\":1,\"name\":\"dirt-weed\",\"label\":\"1Kg Terre Minéraliser\",\"count\":1},{\"label\":\"1L Eau Minéraliser\",\"name\":\"water-weed\",\"count\":3,\"weight\":1}],\"maxWeight\":1000,\"cash\":0,\"dirtycash\":0,\"loadout\":[],\"clothes\":[]}'),
(34, 'proprieties_Middle75400367', '{\"cash\":0,\"items\":[],\"dirtycash\":0,\"clothes\":[],\"maxWeight\":1000,\"loadout\":[]}'),
(35, 'carshop', '{\"cash\":0,\"items\":[],\"clothes\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}');

-- --------------------------------------------------------

--
-- Structure de la table `vtrunk`
--

CREATE TABLE `vtrunk` (
  `id` int NOT NULL,
  `owner` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `plate` varchar(12) COLLATE utf8mb4_general_ci NOT NULL,
  `coffre` text COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vtrunk`
--

INSERT INTO `vtrunk` (`id`, `owner`, `plate`, `coffre`) VALUES
(1, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '60NMT459', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(2, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '46XJS448', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(3, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '05BNT865', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(4, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '68EJT689', '{\"loadout\":[],\"cash\":0,\"dirtycash\":0,\"maxWeight\":1000,\"items\":[]}'),
(5, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '69BAK420', '{\"items\":[{\"weight\":1,\"name\":\"icetea\",\"count\":1},{\"count\":1,\"name\":\"frites\"}],\"cash\":0,\"maxWeight\":1000,\"loadout\":[],\"dirtycash\":0}'),
(6, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '60MEG218', '{\"items\":[{\"count\":1,\"name\":\"suit_hazmat\"}],\"cash\":0,\"maxWeight\":1000,\"dirtycash\":0,\"loadout\":[]}'),
(7, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '46RQP801', '{\"maxWeight\":1000,\"items\":[{\"count\":1,\"name\":\"suit_hazmat\"}],\"loadout\":[],\"dirtycash\":0,\"cash\":0}'),
(8, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '68QIX119', '{\"loadout\":[],\"dirtycash\":0,\"cash\":0,\"maxWeight\":1000,\"items\":[]}'),
(9, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '03RBD498', '{\"cash\":0,\"loadout\":[],\"items\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(10, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '44GVW367', '{\"dirtycash\":0,\"loadout\":[],\"items\":[],\"cash\":0,\"maxWeight\":1000}'),
(11, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '26MJB193', '{\"loadout\":[],\"cash\":0,\"maxWeight\":1000,\"dirtycash\":0,\"items\":[]}'),
(12, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '63GUA969', '{\"cash\":0,\"loadout\":[],\"items\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(13, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '09LNY026', '{\"items\":[],\"dirtycash\":0,\"maxWeight\":1000,\"loadout\":[{\"name\":\"WEAPON_KNIFE\",\"metadata\":[]}],\"cash\":0}'),
(14, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '81BSH460', '{\"loadout\":[],\"cash\":0,\"items\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(15, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '49IBV793', '{\"items\":[{\"name\":\"icetea\",\"count\":2}],\"dirtycash\":0,\"maxWeight\":1000,\"cash\":0,\"loadout\":[]}'),
(16, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '01PPO476', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(17, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '69NPX848', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(18, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '08VGV457', '{\"cash\":0,\"loadout\":[{\"metadata\":{\"description\":\"\",\"label\":\"Pistolet de combat\"},\"name\":\"WEAPON_COMBATPISTOL\"}],\"items\":[{\"count\":1,\"name\":\"jumelles\",\"weight\":1},{\"count\":3,\"weight\":1,\"name\":\"engrais-weed\"},{\"count\":1,\"weight\":1,\"name\":\"drill\"},{\"count\":2,\"name\":\"steak\",\"weight\":1},{\"count\":3,\"weight\":1,\"name\":\"frites\"},{\"count\":1,\"weight\":1,\"name\":\"champagne\"},{\"count\":1,\"name\":\"kevlar\"}],\"maxWeight\":1000,\"dirtycash\":0}'),
(19, 'license:b0d1903bf398c04273055765afe05cd1a2d1c7c0', '82UBG193', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(20, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '68LKO045', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(21, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '61CIM458', '{\"cash\":0,\"items\":[{\"name\":\"ammo_rifle\",\"weight\":1,\"count\":34},{\"weight\":1,\"name\":\"water\",\"count\":1},{\"name\":\"champagne\",\"count\":3}],\"loadout\":[],\"maxWeight\":1000,\"dirtycash\":0}'),
(22, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '63ZDK603', '{\"maxWeight\":1000,\"dirtycash\":0,\"loadout\":[],\"items\":[{\"name\":\"vodka\",\"count\":9}],\"cash\":0}'),
(23, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '60SNN840', '{\"items\":[{\"count\":2,\"name\":\"caisse_fidelite\"}],\"maxWeight\":1000,\"loadout\":[],\"cash\":0,\"dirtycash\":0}'),
(24, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '05WMH156', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(25, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '66OWM156', '{\"cash\":0,\"loadout\":[],\"maxWeight\":1000,\"items\":[{\"weight\":1,\"count\":1,\"name\":\"ammo_pistol\"},{\"name\":\"caisse_diamond\",\"count\":1}],\"dirtycash\":0}'),
(26, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '62HKN258', '{\"loadout\":[],\"maxWeight\":1000,\"items\":[],\"cash\":0,\"dirtycash\":0}'),
(27, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'XUTP835 ', '{\"items\":[],\"cash\":0,\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(28, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '64WQR498', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(29, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '24LAS885', '{\"dirtycash\":0,\"items\":[],\"cash\":0,\"loadout\":[{\"permanent\":false,\"name\":\"WEAPON_CARBINERIFLE\",\"weight\":5,\"components\":[],\"metadata\":{\"police\":true},\"durability\":0},{\"permanent\":false,\"name\":\"WEAPON_SMG\",\"components\":[],\"metadata\":{\"police\":true},\"durability\":0}],\"maxWeight\":1000}'),
(30, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '62FCS103', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(31, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '42MPG971', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(32, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '88XWE779', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(33, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '07MGS219', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(34, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '46PSW830', '{\"loadout\":[],\"cash\":0,\"items\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(35, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '81ZVB783', '{\"loadout\":[],\"dirtycash\":0,\"cash\":0,\"items\":[{\"count\":1,\"metadata\":{\"firstname\":\"c\",\"creation\":1743288298,\"lastname\":\"bucket\",\"sex\":\"Mâle\",\"birthday\":\"2000-01-01\"},\"name\":\"identity_card\"}],\"maxWeight\":1000}'),
(36, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '44FHN434', '{\"cash\":0,\"items\":[{\"weight\":1,\"metadata\":{\"sex\":\"Mâle\",\"creation\":1743291000,\"birthday\":\"2000-01-01\",\"lastname\":\"bucket\",\"firstname\":\"c\",\"licenses\":{\"dmv\":true,\"weapon\":true,\"drive_truck\":true,\"drive_bike\":true,\"drive\":true}},\"count\":1,\"name\":\"drive\"},{\"name\":\"ammo_rifle\",\"metadata\":[],\"count\":2,\"weight\":1},{\"weight\":1,\"metadata\":{\"creation\":1743288298,\"birthday\":\"2000-01-01\",\"sex\":\"Mâle\",\"firstname\":\"c\",\"lastname\":\"bucket\"},\"count\":1,\"name\":\"identity_card\"},{\"name\":\"weapon\",\"metadata\":{\"licenses\":{\"dmv\":true,\"weapon\":true,\"drive_truck\":true,\"drive_bike\":true,\"drive\":true},\"creation\":1743291000,\"birthday\":\"2000-01-01\",\"sex\":\"Mâle\",\"firstname\":\"c\",\"lastname\":\"bucket\"},\"count\":1}],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(37, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '28GLS255', '{\"maxWeight\":1000,\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0}'),
(38, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '27VQB372', '{\"items\":[{\"metadata\":{\"lastname\":\"FakeLast\",\"sex\":\"Mâle\",\"creation\":1743292854,\"birthday\":\"2000-01-01\",\"firstname\":\"FakeFirst\"},\"count\":2,\"name\":\"identity_card\"}],\"maxWeight\":1000,\"cash\":0,\"loadout\":[],\"dirtycash\":0}'),
(39, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '42JUR941', '{\"items\":[],\"maxWeight\":1000,\"cash\":0,\"loadout\":[],\"dirtycash\":0}'),
(40, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '66WAI266', '{\"maxWeight\":1000,\"cash\":0,\"dirtycash\":0,\"items\":[],\"loadout\":[]}'),
(41, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '87DZU328', '{\"items\":[{\"weight\":1,\"metadata\":{\"creation\":1743291000,\"birthday\":\"2000-01-01\",\"firstname\":\"c\",\"lastname\":\"bucket\",\"licenses\":{\"drive_truck\":true,\"dmv\":true,\"drive\":true,\"drive_bike\":true,\"weapon\":true},\"sex\":\"Mâle\"},\"count\":1,\"name\":\"drive\"},{\"metadata\":{\"creation\":1743291000,\"birthday\":\"2000-01-01\",\"firstname\":\"c\",\"lastname\":\"bucket\",\"licenses\":{\"drive_truck\":true,\"dmv\":true,\"drive\":true,\"drive_bike\":true,\"weapon\":true},\"sex\":\"Mâle\"},\"count\":1,\"name\":\"weapon\"}],\"loadout\":[],\"cash\":0,\"dirtycash\":0,\"maxWeight\":1000}'),
(42, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '08CIH970', '{\"items\":[{\"name\":\"weapon\",\"count\":2,\"metadata\":{\"sex\":\"Mâle\",\"creation\":1743291000,\"lastname\":\"bucket\",\"birthday\":\"2000-01-01\",\"licenses\":{\"drive_truck\":true,\"drive_bike\":true,\"weapon\":true,\"drive\":true,\"dmv\":true},\"firstname\":\"c\"},\"weight\":1},{\"name\":\"drive\",\"count\":2,\"metadata\":{\"sex\":\"Mâle\",\"firstname\":\"c\",\"lastname\":\"bucket\",\"birthday\":\"2000-01-01\",\"licenses\":{\"drive_truck\":true,\"drive_bike\":true,\"drive\":true,\"dmv\":true,\"weapon\":true},\"creation\":1743291000}}],\"maxWeight\":1000,\"cash\":0,\"loadout\":[],\"dirtycash\":0}'),
(43, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '68GZL088', '{\"items\":[{\"name\":\"identity_card\",\"count\":1,\"metadata\":{\"sex\":\"Mâle\",\"lastname\":\"bucket\",\"birthday\":\"2000-01-01\",\"creation\":1743295530,\"firstname\":\"c\"}}],\"maxWeight\":1000,\"cash\":0,\"loadout\":[],\"dirtycash\":0}'),
(44, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '61SDR133', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(45, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '28MTM505', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(46, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '45TES710', '{\"items\":[{\"metadata\":{\"creation\":1743298523,\"sex\":\"Mâle\",\"firstname\":\"c\",\"birthday\":\"2000-01-01\",\"lastname\":\"bucket\"},\"count\":1,\"name\":\"identity_card\"}],\"dirtycash\":0,\"maxWeight\":1000,\"loadout\":[],\"cash\":0}'),
(47, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '46WLW083', '{\"cash\":0,\"loadout\":[],\"items\":[],\"maxWeight\":1000,\"dirtycash\":0}'),
(48, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '40KTC957', '{\"cash\":0,\"dirtycash\":0,\"maxWeight\":1000,\"items\":[{\"count\":1,\"name\":\"identity_card\",\"metadata\":{\"sex\":\"Mâle\",\"creation\":1743298997,\"firstname\":\"c\",\"birthday\":\"2000-01-01\",\"lastname\":\"bucket\"}}],\"loadout\":[]}'),
(49, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '64GCI145', '{\"dirtycash\":0,\"cash\":0,\"items\":[],\"loadout\":[],\"maxWeight\":1000}'),
(50, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '64NAE207', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(51, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '44WSX569', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(52, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '43MVN881', '{\"maxWeight\":1000,\"cash\":0,\"items\":[],\"dirtycash\":0,\"loadout\":[]}'),
(53, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '03GDQ802', '{\"items\":[],\"cash\":0,\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(54, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '80SRM170', '{\"cash\":0,\"loadout\":[],\"items\":[],\"maxWeight\":1000,\"dirtycash\":0}'),
(55, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '25GLQ442', '{\"cash\":0,\"items\":[],\"maxWeight\":1000,\"loadout\":[],\"dirtycash\":0}'),
(56, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '22DVE734', '{\"maxWeight\":1000,\"loadout\":[],\"cash\":0,\"dirtycash\":0,\"items\":[{\"unique\":true,\"count\":1,\"weight\":1,\"metadata\":{\"firstname\":\"carte\",\"sex\":\"Mâle\",\"lastname\":\"1\",\"creation\":1743299588,\"birthday\":\"2000-01-01\"},\"name\":\"identity_card\",\"extra\":{\"identifier\":29}},{\"unique\":true,\"count\":1,\"metadata\":{\"firstname\":\"carte\",\"sex\":\"Mâle\",\"creation\":1743299588,\"birthday\":\"2000-01-01\",\"lastname\":\"2\"},\"name\":\"identity_card\",\"extra\":{\"identifier\":30}}]}'),
(57, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '06ZMV774', '{\"dirtycash\":0,\"loadout\":[],\"cash\":0,\"maxWeight\":1000,\"items\":[{\"extra\":{\"identifier\":30},\"name\":\"identity_card\",\"count\":1,\"unique\":true,\"metadata\":{\"lastname\":\"2\",\"birthday\":\"2000-01-01\",\"creation\":1743299588,\"firstname\":\"carte\",\"sex\":\"Mâle\"}}]}'),
(58, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '26TKG886', '{\"loadout\":[],\"cash\":0,\"maxWeight\":1000,\"dirtycash\":0,\"items\":[]}'),
(59, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '02CRV789', '{\"dirtycash\":0,\"items\":[],\"cash\":0,\"loadout\":[],\"maxWeight\":1000}'),
(60, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '41MBC700', '{\"loadout\":[],\"cash\":0,\"dirtycash\":0,\"maxWeight\":1000,\"items\":[]}'),
(61, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '40HAN924', '{\"items\":[],\"dirtycash\":0,\"cash\":0,\"maxWeight\":1000,\"loadout\":[]}'),
(62, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '01JCA842', '{\"dirtycash\":0,\"items\":[],\"maxWeight\":1000,\"loadout\":[],\"cash\":0}'),
(63, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '83JXB929', '{\"items\":[],\"maxWeight\":1000,\"dirtycash\":0,\"cash\":0,\"loadout\":[]}'),
(64, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '68ZTA148', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(65, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '02BSL315', '{\"items\":[],\"cash\":0,\"maxWeight\":1000,\"loadout\":[],\"dirtycash\":0}'),
(66, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '88BFR366', '{\"dirtycash\":0,\"cash\":0,\"maxWeight\":1000,\"loadout\":[],\"items\":[{\"count\":1,\"weight\":1,\"extra\":{\"identifier\":5216},\"metadata\":{\"licenses\":{\"drive_truck\":true,\"dmv\":true,\"drive\":true,\"weapon\":true,\"drive_bike\":true},\"firstname\":\"weapon1\",\"sex\":\"Mâle\",\"lastname\":\"1\",\"birthday\":\"2000-01-01\",\"creation\":1743301897},\"unique\":true,\"name\":\"weapon\"},{\"count\":1,\"weight\":1,\"unique\":true,\"name\":\"weapon\",\"metadata\":{\"birthday\":\"2000-01-01\",\"firstname\":\"weapon2\",\"sex\":\"Mâle\",\"lastname\":\"2\",\"licenses\":{\"drive_truck\":true,\"dmv\":true,\"drive\":true,\"weapon\":true,\"drive_bike\":true},\"creation\":1743301930},\"extra\":{\"identifier\":5183}},{\"count\":1,\"weight\":1,\"name\":\"drive\",\"unique\":true,\"metadata\":{\"licenses\":{\"drive_truck\":true,\"drive\":true,\"dmv\":true,\"weapon\":true,\"drive_bike\":true},\"creation\":1743299589,\"birthday\":\"2000-01-01\",\"lastname\":\"1\",\"sex\":\"Mâle\",\"firstname\":\"drive\"},\"extra\":{\"identifier\":1670}},{\"count\":1,\"weight\":1,\"extra\":{\"identifier\":5329},\"name\":\"identity_card\",\"metadata\":[],\"unique\":true},{\"count\":1,\"unique\":true,\"extra\":{\"identifier\":5515},\"metadata\":{\"birthday\":\"2000-01-01\",\"creation\":1743299589,\"licenses\":{\"drive_truck\":true,\"drive\":true,\"dmv\":true,\"weapon\":true,\"drive_bike\":true},\"lastname\":\"2\",\"sex\":\"Mâle\",\"firstname\":\"drive\"},\"name\":\"drive\"}]}'),
(67, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '00IYT616', '{\"dirtycash\":0,\"cash\":0,\"maxWeight\":1000,\"loadout\":[],\"items\":[]}'),
(68, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '21RMA838', '{\"maxWeight\":1000,\"cash\":0,\"loadout\":[],\"dirtycash\":0,\"items\":[]}'),
(69, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '02UTA792', '{\"loadout\":[],\"cash\":0,\"items\":[{\"count\":1,\"extra\":{\"identifier\":4997},\"unique\":true,\"name\":\"weapon\",\"metadata\":[]}],\"dirtycash\":0,\"maxWeight\":1000}'),
(70, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '65IJR472', '{\"loadout\":[],\"cash\":0,\"items\":[{\"count\":1,\"extra\":[],\"unique\":true,\"name\":\"weapon\",\"metadata\":[]}],\"dirtycash\":0,\"maxWeight\":1000}'),
(71, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '47CXW337', '{\"loadout\":[],\"cash\":0,\"items\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(72, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '60MHN552', '{\"loadout\":[],\"cash\":0,\"maxWeight\":1000,\"dirtycash\":0,\"items\":[]}'),
(73, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '05ZVC043', '{\"maxWeight\":1000,\"loadout\":[],\"items\":[{\"name\":\"weapon\",\"count\":1,\"unique\":true,\"weight\":1,\"metadata\":[],\"extra\":[]},{\"name\":\"identity_card\",\"extra\":[],\"unique\":true,\"metadata\":[],\"weight\":1,\"count\":1},{\"name\":\"drive\",\"extra\":[],\"unique\":true,\"count\":1,\"metadata\":[],\"weight\":1}],\"cash\":0,\"dirtycash\":0}'),
(74, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '60XGI842', '{\"items\":[{\"weight\":1,\"extra\":{\"identifier\":2483},\"name\":\"identity_card\",\"metadata\":[],\"count\":1,\"unique\":true}],\"dirtycash\":0,\"cash\":0,\"maxWeight\":1000,\"loadout\":[]}'),
(75, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', 'TGIR911 ', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(76, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '41ZMQ624', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(77, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '24GKT177', '{\"dirtycash\":0,\"loadout\":[],\"cash\":0,\"items\":[{\"unique\":false,\"name\":\"dirt-weed\",\"weight\":1,\"metadata\":[],\"count\":6},{\"metadata\":[],\"name\":\"water-weed\",\"unique\":false,\"count\":15}],\"maxWeight\":1000}'),
(78, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '85EKB051', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(79, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '88NYT198', '{\"cash\":0,\"items\":[],\"loadout\":[],\"dirtycash\":0,\"maxWeight\":1000}'),
(80, 'license:5474636beca7e2658e6f77079a1e6c47f98af4b6', '26WVX804', '{\"items\":[{\"count\":1,\"metadata\":[],\"name\":\"caisse_fidelite\",\"unique\":false}],\"maxWeight\":1000,\"dirtycash\":0,\"cash\":0,\"loadout\":[]}');

-- --------------------------------------------------------

--
-- Structure de la table `vusableitem`
--

CREATE TABLE `vusableitem` (
  `id` int NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `label` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `type` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'hunger',
  `number` varchar(255) COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `vusableitem`
--

INSERT INTO `vusableitem` (`id`, `name`, `label`, `type`, `number`) VALUES
(1, 'coca', 'Coca Cola', 'water', '60'),
(2, 'cocafrais', 'Coca Frais', 'thirst', '0.26'),
(3, 'vodka', 'Vodka', 'drunk', '0.14'),
(4, 'champagne', 'Champagne', 'drunk', '0.05'),
(5, 'cola', 'Coca', 'thirst', '0.28'),
(6, 'weed_pooch', 'Pochon de weed (1g)', 'drug', '25');

-- --------------------------------------------------------

--
-- Structure de la table `weedplants`
--

CREATE TABLE `weedplants` (
  `id` int NOT NULL,
  `owner` varchar(2555) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `inLabo` int NOT NULL DEFAULT '0',
  `coords` longtext COLLATE utf8mb4_general_ci NOT NULL,
  `rotation` text COLLATE utf8mb4_general_ci,
  `time` int NOT NULL,
  `fertilizer` longtext COLLATE utf8mb4_general_ci NOT NULL,
  `water` longtext COLLATE utf8mb4_general_ci NOT NULL,
  `gender` varchar(45) COLLATE utf8mb4_general_ci NOT NULL,
  `hasBase` int NOT NULL DEFAULT '0'
) ;

--
-- Déchargement des données de la table `weedplants`
--

INSERT INTO `weedplants` (`id`, `owner`, `inLabo`, `coords`, `rotation`, `time`, `fertilizer`, `water`, `gender`, `hasBase`) VALUES
(55, '{\"firstname\":\"John\",\"lastname\":\"Doe\",\"name\":\"null\",\"idunique\":1}', 0, '{\"x\":-1568.3338623046876,\"y\":-384.44439697265627,\"z\":37.0923843383789}', '{\"x\":0.0,\"y\":0.0,\"z\":0.0}', 1744546720, '[]', '[]', 'female', 0),
(56, '{\"lastname\":\"Doe\",\"name\":\"null\",\"idunique\":1,\"firstname\":\"John\"}', 1, '{\"x\":-311.5210876464844,\"y\":-1354.024658203125,\"z\":23.33037376403808}', '{\"x\":0.0,\"y\":-0.0,\"z\":0.0}', 1746797316, '[]', '[]', 'female', 2),
(57, '{\"name\":\"John Doe\",\"lastname\":\"Doe\",\"firstname\":\"John\",\"idunique\":1}', 1, '{\"x\":-311.5298156738281,\"y\":-1355.4730224609376,\"z\":23.33386611938476}', '{\"x\":0.0,\"y\":-0.0,\"z\":0.0}', 1748627737, '[]', '[]', 'female', 0),
(58, '{\"name\":\"John Doe\",\"lastname\":\"Doe\",\"firstname\":\"John\",\"idunique\":1}', 2, '{\"x\":-311.5298156738281,\"y\":-1355.4730224609376,\"z\":23.33386611938476}', '{\"x\":0.0,\"y\":-0.0,\"z\":0.0}', 1748697170, '[]', '[]', 'female', 2),
(59, '{\"idunique\":1,\"lastname\":\"Doe\",\"firstname\":\"John\",\"name\":\"John Doe\"}', 0, '{\"x\":-1116.6068115234376,\"y\":-778.2149047851563,\"z\":17.52321434020996}', '{\"x\":0.0,\"y\":0.0,\"z\":0.0}', 1759613078, '[]', '[]', 'female', 2);

-- --------------------------------------------------------

--
-- Structure de la table `world_props`
--

CREATE TABLE `world_props` (
  `id` int NOT NULL,
  `name` longtext COLLATE utf8mb4_general_ci,
  `owner` longtext COLLATE utf8mb4_general_ci,
  `label` longtext COLLATE utf8mb4_general_ci,
  `position` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `instance` int DEFAULT NULL,
  `heading` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `iid` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Déchargement des données de la table `world_props`
--

INSERT INTO `world_props` (`id`, `name`, `owner`, `label`, `position`, `instance`, `heading`, `iid`) VALUES
(50, 'prop_table_04', '{\"years\":2025,\"day\":28,\"month\":3,\"firstName\":\"Staff\",\"lastName\":\"\",\"min\":51,\"Name\":\"AdminProps:null\",\"UniqueID\":0,\"hours\":22}', 'Table d\'exterieur 2', '{\"x\":562.445068359375,\"y\":-959.3505859375,\"z\":10.01221847534179}', NULL, '{\"x\":0.0,\"y\":-0.0,\"z\":0.0}', 114151061),
(101, 'prop_bench_02', '{\"hours\":0,\"day\":27,\"UniqueID\":18,\"month\":11,\"Name\":\"Inconnu\",\"min\":15,\"lastName\":\"Doe\",\"years\":2025,\"firstName\":\"John\"}', 'Banc 4', '{\"x\":-405.4494323730469,\"y\":111.02751922607422,\"z\":64.35846710205078}', NULL, '{\"x\":0.0,\"y\":-0.0,\"z\":179.1950225830078}', 73131433);

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `0resmon_delivery_employees`
--
ALTER TABLE `0resmon_delivery_employees`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `account_info`
--
ALTER TABLE `account_info`
  ADD PRIMARY KEY (`account_id`);

--
-- Index pour la table `activity`
--
ALTER TABLE `activity`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `baninfo`
--
ALTER TABLE `baninfo`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `banlist`
--
ALTER TABLE `banlist`
  ADD PRIMARY KEY (`banid`);

--
-- Index pour la table `banlisthistory`
--
ALTER TABLE `banlisthistory`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `bikeshop_vehicle`
--
ALTER TABLE `bikeshop_vehicle`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `billing`
--
ALTER TABLE `billing`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `booster_users`
--
ALTER TABLE `booster_users`
  ADD PRIMARY KEY (`identifier`);

--
-- Index pour la table `computers_mail_accounts`
--
ALTER TABLE `computers_mail_accounts`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `concess_history`
--
ALTER TABLE `concess_history`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `concess_vehicle`
--
ALTER TABLE `concess_vehicle`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `dealership_sales`
--
ALTER TABLE `dealership_sales`
  ADD PRIMARY KEY (`id`),
  ADD KEY `shop` (`shop`),
  ADD KEY `created_at` (`created_at`);

--
-- Index pour la table `drugs_circuits`
--
ALTER TABLE `drugs_circuits`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `drugs_sell`
--
ALTER TABLE `drugs_sell`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `fine_types`
--
ALTER TABLE `fine_types`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `gangs`
--
ALTER TABLE `gangs`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `garage`
--
ALTER TABLE `garage`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `gunfight_stats`
--
ALTER TABLE `gunfight_stats`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `illegal_laboratory`
--
ALTER TABLE `illegal_laboratory`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `items`
--
ALTER TABLE `items`
  ADD PRIMARY KEY (`name`);

--
-- Index pour la table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `name` (`name`);

--
-- Index pour la table `job_grades`
--
ALTER TABLE `job_grades`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `markers`
--
ALTER TABLE `markers`
  ADD PRIMARY KEY (`name`);

--
-- Index pour la table `owned_vehicles`
--
ALTER TABLE `owned_vehicles`
  ADD PRIMARY KEY (`plate`);

--
-- Index pour la table `ox_doorlock`
--
ALTER TABLE `ox_doorlock`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `properties_list`
--
ALTER TABLE `properties_list`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `race_tracks`
--
ALTER TABLE `race_tracks`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `sanction_list`
--
ALTER TABLE `sanction_list`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `society`
--
ALTER TABLE `society`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `society_moneywash`
--
ALTER TABLE `society_moneywash`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `staff`
--
ALTER TABLE `staff`
  ADD PRIMARY KEY (`idunique`);

--
-- Index pour la table `starterpack`
--
ALTER TABLE `starterpack`
  ADD PRIMARY KEY (`identifier`);

--
-- Index pour la table `tebex_histo`
--
ALTER TABLE `tebex_histo`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `tebex_players_wallet`
--
ALTER TABLE `tebex_players_wallet`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `tebex_null_fidelite`
--
ALTER TABLE `tebex_null_fidelite`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `territoriesshop`
--
ALTER TABLE `territoriesshop`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`idunique`);

--
-- Index pour la table `users_tig`
--
ALTER TABLE `users_tig`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `user_licenses`
--
ALTER TABLE `user_licenses`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vbank`
--
ALTER TABLE `vbank`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vchest`
--
ALTER TABLE `vchest`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vclothes`
--
ALTER TABLE `vclothes`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vfictifveh`
--
ALTER TABLE `vfictifveh`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vgangs`
--
ALTER TABLE `vgangs`
  ADD PRIMARY KEY (`gangname`);

--
-- Index pour la table `vgarderobe`
--
ALTER TABLE `vgarderobe`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vhistoevalstaff`
--
ALTER TABLE `vhistoevalstaff`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vhistoriquesociety`
--
ALTER TABLE `vhistoriquesociety`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vips`
--
ALTER TABLE `vips`
  ADD PRIMARY KEY (`identifier`);

--
-- Index pour la table `visdead`
--
ALTER TABLE `visdead`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vjails`
--
ALTER TABLE `vjails`
  ADD PRIMARY KEY (`jailId`);

--
-- Index pour la table `vlester`
--
ALTER TABLE `vlester`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vlogs`
--
ALTER TABLE `vlogs`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `voutfit`
--
ALTER TABLE `voutfit`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vsafezone`
--
ALTER TABLE `vsafezone`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vsociety`
--
ALTER TABLE `vsociety`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vstash`
--
ALTER TABLE `vstash`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vstorage`
--
ALTER TABLE `vstorage`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vtrunk`
--
ALTER TABLE `vtrunk`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `vusableitem`
--
ALTER TABLE `vusableitem`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `weedplants`
--
ALTER TABLE `weedplants`
  ADD PRIMARY KEY (`id`);

--
-- Index pour la table `world_props`
--
ALTER TABLE `world_props`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `id` (`id`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `0resmon_delivery_employees`
--
ALTER TABLE `0resmon_delivery_employees`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pour la table `activity`
--
ALTER TABLE `activity`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT pour la table `baninfo`
--
ALTER TABLE `baninfo`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

--
-- AUTO_INCREMENT pour la table `banlist`
--
ALTER TABLE `banlist`
  MODIFY `banid` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT pour la table `banlisthistory`
--
ALTER TABLE `banlisthistory`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=27;

--
-- AUTO_INCREMENT pour la table `bikeshop_vehicle`
--
ALTER TABLE `bikeshop_vehicle`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=482;

--
-- AUTO_INCREMENT pour la table `billing`
--
ALTER TABLE `billing`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT pour la table `computers_mail_accounts`
--
ALTER TABLE `computers_mail_accounts`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `concess_history`
--
ALTER TABLE `concess_history`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `concess_vehicle`
--
ALTER TABLE `concess_vehicle`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=482;

--
-- AUTO_INCREMENT pour la table `dealership_sales`
--
ALTER TABLE `dealership_sales`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `drugs_circuits`
--
ALTER TABLE `drugs_circuits`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT pour la table `drugs_sell`
--
ALTER TABLE `drugs_sell`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- AUTO_INCREMENT pour la table `gangs`
--
ALTER TABLE `gangs`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `garage`
--
ALTER TABLE `garage`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=86;

--
-- AUTO_INCREMENT pour la table `gunfight_stats`
--
ALTER TABLE `gunfight_stats`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT pour la table `illegal_laboratory`
--
ALTER TABLE `illegal_laboratory`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT pour la table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=175;

--
-- AUTO_INCREMENT pour la table `job_grades`
--
ALTER TABLE `job_grades`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=726;

--
-- AUTO_INCREMENT pour la table `ox_doorlock`
--
ALTER TABLE `ox_doorlock`
  MODIFY `id` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=76;

--
-- AUTO_INCREMENT pour la table `properties_list`
--
ALTER TABLE `properties_list`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=99287502;

--
-- AUTO_INCREMENT pour la table `race_tracks`
--
ALTER TABLE `race_tracks`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `sanction_list`
--
ALTER TABLE `sanction_list`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=130;

--
-- AUTO_INCREMENT pour la table `society`
--
ALTER TABLE `society`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=148;

--
-- AUTO_INCREMENT pour la table `society_moneywash`
--
ALTER TABLE `society_moneywash`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `tebex_histo`
--
ALTER TABLE `tebex_histo`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT pour la table `tebex_players_wallet`
--
ALTER TABLE `tebex_players_wallet`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=125;

--
-- AUTO_INCREMENT pour la table `tebex_null_fidelite`
--
ALTER TABLE `tebex_null_fidelite`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT pour la table `territoriesshop`
--
ALTER TABLE `territoriesshop`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `idunique` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- AUTO_INCREMENT pour la table `users_tig`
--
ALTER TABLE `users_tig`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT pour la table `user_licenses`
--
ALTER TABLE `user_licenses`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT pour la table `vbank`
--
ALTER TABLE `vbank`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=98;

--
-- AUTO_INCREMENT pour la table `vchest`
--
ALTER TABLE `vchest`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT pour la table `vclothes`
--
ALTER TABLE `vclothes`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=996143;

--
-- AUTO_INCREMENT pour la table `vfictifveh`
--
ALTER TABLE `vfictifveh`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `vgarderobe`
--
ALTER TABLE `vgarderobe`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=81;

--
-- AUTO_INCREMENT pour la table `vhistoevalstaff`
--
ALTER TABLE `vhistoevalstaff`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT pour la table `vhistoriquesociety`
--
ALTER TABLE `vhistoriquesociety`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=65;

--
-- AUTO_INCREMENT pour la table `visdead`
--
ALTER TABLE `visdead`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6639;

--
-- AUTO_INCREMENT pour la table `vjails`
--
ALTER TABLE `vjails`
  MODIFY `jailId` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=156;

--
-- AUTO_INCREMENT pour la table `vlester`
--
ALTER TABLE `vlester`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `vlogs`
--
ALTER TABLE `vlogs`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14475;

--
-- AUTO_INCREMENT pour la table `vsafezone`
--
ALTER TABLE `vsafezone`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT pour la table `vsociety`
--
ALTER TABLE `vsociety`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=84;

--
-- AUTO_INCREMENT pour la table `vstash`
--
ALTER TABLE `vstash`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT pour la table `vstorage`
--
ALTER TABLE `vstorage`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT pour la table `vtrunk`
--
ALTER TABLE `vtrunk`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=81;

--
-- AUTO_INCREMENT pour la table `vusableitem`
--
ALTER TABLE `vusableitem`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT pour la table `weedplants`
--
ALTER TABLE `weedplants`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `world_props`
--
ALTER TABLE `world_props`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=102;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
