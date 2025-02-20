/*
|----------------------------------------------------------------------
| International Organization for Standardization (ISO) Database Schema
|----------------------------------------------------------------------
| This script is a customized database for geographic information for
| the global standards for trusted goods and services. ISO is an
| independent, non-governmental international organization. It brings
| global experts together to agree on the best ways of doing things.
|
| Procured by Jason Monroe (jason@jasonmonroe.com)
| @link https://www.iso.org/home.html
| @link https://www.iso.org/obp/ui/#search
| @link https://www.iso.org/obp/ui/#iso:pub:PUB500001:en
| @link https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes
| @link https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
|
| Note: Storing latitude and longitude coordinates for the Haversine
| Formula.
*/

CREATE DATABASE IF NOT EXISTS iso;
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE iso;

CREATE TABLE location (
    id INT unsigned UNIQUE NOT NULL AUTO_INCREMENT,
    coordinates POINT NOT NULL SRID 4326, -- used for Geographic Information System
    SPATIAL INDEX(coordinates),  -- Enables efficient spatial queries
    latitude DECIMAL(11, 8), -- used for Haversine Formula (North to South)
    longitude DECIMAL(11, 8), -- used for Haversine Formula (East to West)
    status BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (id)
);

CREATE TABLE timezone (
    id INT unsigned UNIQUE NOT NULL AUTO_INCREMENT,
    standard_time_name VARCHAR(64) NOT NULL, -- i.e: Central Standard Time
    name VARCHAR(32) NOT NULL, -- i.e: America/Chicago
    offset VARCHAR(16), -- i.e: UTC+12:00
    group_offset BOOLEAN default FALSE, -- used to group timezones by offset to prevent displaying all timezones
    ordering INT UNSIGNED,     -- order by offset
    status BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (id)
);

CREATE TABLE language (
    id INT unsigned UNIQUE NOT NULL AUTO_INCREMENT,
    name VARCHAR(32) NOT NULL,
    local_name VARCHAR(32), -- name in local language
    iso_code VARCHAR(2) NOT NULL, -- ISO 639 alpha-2 codes
    status BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (id)
);

CREATE TABLE country (
    id INT unsigned UNIQUE NOT NULL AUTO_INCREMENT,
    short_name VARCHAR(64) UNIQUE NOT NULL,
    long_name VARCHAR(128) UNIQUE NOT NULL,
    local_name VARCHAR(64) UNIQUE,
    alpha_2_code VARCHAR(2) UNIQUE NOT NULL, -- iso code 2 chars
    alpha_3_code VARCHAR(4) , -- iso code 3 chars
    numeric_code INT(3) UNIQUE , -- ie: 840
    capital VARCHAR(64), -- optional
    capital_id INT UNSIGNED,    
    nationality_plural VARCHAR(32),
    nationality_singular VARCHAR(32),
    continent VARCHAR(16), -- i.e: Africa, Europe, North America, South America, Oceania, Asia, Middle East
    currency_code VARCHAR(4),
    currency_symbol VARCHAR(2),
    comment VARCHAR(255),
    location_id INT, -- if normalized
    -- coordinates POINT NOT NULL SRID 4326, -- used for Geographic Information System (GIS)
    -- SPATIAL INDEX(coordinates),  -- Enables efficient spatial queries
    -- latitude DECIMAL(11, 8), -- used for Haversine Formula
    -- longitude DECIMAL(11, 8), -- used for Haversine Formula
    status BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (id),
    FOREIGN KEY (location_id) REFERENCES location(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE region (
    id INT unsigned UNIQUE NOT NULL AUTO_INCREMENT,
    country_id INT unsigned NOT NULL,
    location_id INT,
    language_id INT,
    name VARCHAR(64) NOT NULL,
    iso_code VARCHAR(8) NOT NULL, -- 3166-2 iso code
    -- coordinates POINT NOT NULL SRID 4326, -- used for Geographic Information System
    -- SPATIAL INDEX(coordinates), -- enables efficient spatial queries
    -- latitude DECIMAL(11, 8), -- used for Haversine Formula
    -- longitude DECIMAL(11, 8), -- used for Haversine Formula
    status BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (id),
    FOREIGN KEY (country_id) REFERENCES country(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES location(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES language(id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Metropolitan area
-- Used to bundle cities of a suburban areas to a metropolitan area
CREATE TABLE metro (
    id INT unsigned UNIQUE NOT NULL AUTO_INCREMENT,
    city_id INT, -- used as a REFERENCES to the city proper of the metro (optional)
    name VARCHAR(64) NOT NULL,
    status BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (id)
);

CREATE TABLE city (
    id INT unsigned UNIQUE NOT NULL AUTO_INCREMENT,
    region_id INT UNSIGNED NOT NULL,
    metro_id INT UNSIGNED,    
    timezone_id INT UNSIGNED,
    location_id INT,
    name VARCHAR(64) NOT NULL,
    -- coordinates POINT NOT NULL SRID 4326, -- used for Geographic Information System
    -- SPATIAL INDEX(coordinates),  -- Enables efficient spatial queries
    -- latitude DECIMAL(11, 8), -- used for Haversine Formula
    -- longitude DECIMAL(11, 8), -- used for Haversine Formula
    status BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (id),
    FOREIGN KEY (region_id) REFERENCES region(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (metro_id) REFERENCES location(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (timezone_id) REFERENCES timezone(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES location(id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- CREATE indices
-- Index FOREIGN KEYs, UNIQUE and joined columns

-- Indices: location
CREATE SPATIAL INDEX idx_location_coordinates ON location(coordinates);
CREATE INDEX idx_location_lon ON location(longitude);
CREATE INDEX idx_location_lat ON location(latitude);

-- Indices: timezone
CREATE index idx_tz_name ON timezone(name);
CREATE index idx_tz_standard_name ON timezone(standard_time_name);
CREATE INDEX idx_tz_group_offset ON timezone(group_offset);

-- Indices: language
CREATE INDEX idx_language_name ON language(name);
CREATE INDEX idx_language_local_name ON language(local_name);
CREATE INDEX idx_language_code ON language(iso_code);

-- Indices: country
CREATE INDEX idx_country_short_name ON country(short_name);
CREATE INDEX idx_country_long_name ON country(long_name);
CREATE INDEX idx_country_local_name ON country(local_name);
CREATE INDEX idx_country_numeric_code ON country(numeric_code);
CREATE INDEX idx_country_location ON country(location_id);
CREATE INDEX idx_country_alpha_2_code ON country(alpha_2_code);
CREATE INDEX idx_country_alpha_3_code ON country(alpha_3_code);
CREATE INDEX idx_country_query ON country(short_name, location_id, alpha_2_code)
-- CREATE SPATIAL INDEX idx_country_coordinates ON country(coordinates);
-- CREATE INDEX idx_country_lon ON country(longitude);
-- CREATE INDEX idx_country_lat ON country(latitude);

-- Indices: region
CREATE INDEX idx_region_country ON region(country_id);
CREATE INDEX idx_region_language ON region(language_id);
CREATE INDEX idx_region_name ON region(name);
CREATE INDEX idx_region_iso_code ON region(iso_code);
CREATE INDEX idx_region_location ON region(location_id);
CREATE INDEX idx_region_query ON region(country_id, location_id, name);
-- CREATE SPATIAL INDEX idx_region_coordinates ON region(coordinates);
-- CREATE INDEX idx_region_lon ON region(longitude);
-- CREATE INDEX idx_region_lat ON region(latitude);

-- Indices: metro
CREATE INDEX idx_metro_city ON metro(city_id);
CREATE INDEX idx_metro_name ON metro(name);

-- Indices: city
CREATE INDEX idx_city_region ON city(region_id);
CREATE INDEX idx_city_metro ON city(metro_id);
CREATE INDEX idx_city_timezone ON city(timezone_id);
CREATE INDEX idx_city_location ON city(location_id);
CREATE INDEX idx_city_name ON city(name);
CREATE INDEX idx_city_query ON city(region_id, location_id, name, metro_id);
-- CREATE SPATIAL INDEX idx_city_coordinates ON city(coordinates);
-- CREATE INDEX idx_city_lon ON city(longitude);
-- CREATE INDEX idx_city_lat ON city(latitude);
