CREATE TABLE IF NOT EXISTS Sensoriant_Allowed_Platform_Names
(
  id VARCHAR(36) DEFAULT (uuid()) PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  created_at DATETIME DEFAULT (now()),
  updated_at DATETIME DEFAULT (now())
);
CREATE TABLE IF NOT EXISTS Sensoriant_Allowed_Platform_Measurements
(
  id VARCHAR(36) DEFAULT (uuid()) PRIMARY KEY,
  measurement VARCHAR(255) NOT NULL UNIQUE,
  created_at DATETIME DEFAULT (now()),
  updated_at DATETIME DEFAULT (now())
);
CREATE TABLE IF NOT EXISTS Sensoriant_Allowed_Project_Ids
(
  id VARCHAR(36) DEFAULT (uuid()) PRIMARY KEY,
  project_id VARCHAR(255) NOT NULL UNIQUE,
  created_at DATETIME DEFAULT (now()),
  updated_at DATETIME DEFAULT (now())
);
CREATE TABLE IF NOT EXISTS Sensoriant_Platforms
(
  id VARCHAR(36) DEFAULT (uuid()) PRIMARY KEY,
  project_id VARCHAR(255) NOT NULL,
  project_number VARCHAR(255) NOT NULL,
  zone VARCHAR(255) NOT NULL,
  instance_id VARCHAR(255) NOT NULL UNIQUE,
  instance_name VARCHAR(255) NOT NULL,
  instance_creation_timestamp INT NOT NULL,
  cloud_provider VARCHAR(255) NOT NULL,

  platform_id_hash VARCHAR(255) NOT NULL,
  platform_signing_key TEXT NOT NULL,
  platform_encryption_key TEXT NOT NULL,
  measurement VARCHAR(255) NOT NULL,
  storage_bucket_name VARCHAR(255) NOT NULL,
  algorithm_registry_name VARCHAR(255) NOT NULL,
  release_version VARCHAR(255) NOT NULL,

  agent_id VARCHAR(255) NOT NULL,

  created_at DATETIME DEFAULT (now()),
  updated_at DATETIME DEFAULT (now())
);
CREATE TABLE IF NOT EXISTS Sensoriant_Platform_Tokens
(
  id VARCHAR(36) DEFAULT (uuid()) PRIMARY KEY,
  used TINYINT DEFAULT 0 NOT NULL,
  cloud_provider VARCHAR(255) NOT NULL,
  private_key TEXT NOT NULL,
  public_key TEXT NOT NULL,
  ssh_public_key TEXT NOT NULL,
  username VARCHAR(255) NOT NULL,
  created_at DATETIME DEFAULT (now()),
  updated_at DATETIME DEFAULT (now())
);
