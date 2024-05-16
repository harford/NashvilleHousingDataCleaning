-- Cleaning data with SQL Queries

SELECT *
FROM NashvilleHousing

/*
Clean up the SaleDate column
The field is currently set up as a date time data type, however there is no time data available
To clean it up we will remove the time
*/

SELECT SaleDate, CONVERT(Date,SaleDate)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

/*
Populate the NULL values in the PropertyAddress column
Some addresses are missing but they can be populated by matching up Parcel IDs
*/

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL

SELECT NH_Table1.ParcelID
		, NH_Table1.PropertyAddress
		, NH_Table2.ParcelID
		, NH_Table2.PropertyAddress
		, ISNULL(NH_Table1.PropertyAddress, NH_Table2.PropertyAddress)
FROM NashvilleHousing AS NH_Table1
JOIN NashvilleHousing AS NH_Table2
	ON NH_Table1.ParcelID = NH_Table2.ParcelID
	AND NH_Table1.UniqueID <> NH_Table2.UniqueID
WHERE NH_Table1.PropertyAddress IS NULL

UPDATE NH_Table1
SET PropertyAddress = ISNULL(NH_Table1.PropertyAddress, NH_Table2.PropertyAddress)
FROM NashvilleHousing AS NH_Table1
JOIN NashvilleHousing AS NH_Table2
	ON NH_Table1.ParcelID = NH_Table2.ParcelID
	AND NH_Table1.UniqueID <> NH_Table2.UniqueID
WHERE NH_Table1.PropertyAddress IS NULL

/*
Breaking out the address into individual columns
Currently the entire address is contained in one cell
We will break up the address into different columns; address, city, and state
*/

-- Parsing the property address with the use of substrings

SELECT PropertyAddress
FROM NashvilleHousing

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS address
	, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS city
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertyAddressSubstring nvarchar(100);

UPDATE NashvilleHousing
SET PropertyAddressSubstring = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousing
ADD PropertyCitySubstring nvarchar(100);

UPDATE NashvilleHousing
SET PropertyCitySubstring = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT *
FROM NashvilleHousing

-- Parsing the owner address with the use of parse name

SELECT OwnerAddress
FROM NashvilleHousing

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerAddressSubstring
		, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCitySubstring
		, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerStateSubstring
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerAddressSubstring nvarchar(100);

UPDATE NashvilleHousing
SET OwnerAddressSubstring = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerCitySubstring nvarchar(100);

UPDATE NashvilleHousing
SET OwnerCitySubstring = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerStateSubstring nvarchar(100);

UPDATE NashvilleHousing
SET OwnerStateSubstring = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT *
FROM NashvilleHousing

/*
Standardize the values in the SoldAsVacant column
This column contains both Y/N values as well as Yes/No
There are more records that use the Yes/No format than the Y/N format so we'll eliminate the single letters in favor of the actual words
*/

SELECT DISTINCT(SoldAsVacant)
		, COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
		, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END AS SoldAsVacantStandardized
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END

/*
Remove duplicates
Some rows of data have been duplicated
We will identify and remove the duplicate values from the table
*/

WITH RowNumberCTE AS
(
SELECT *
		, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueId) AS RowNumber
FROM NashvilleHousing
)
DELETE
FROM RowNumberCTE
WHERE RowNumber > 1

/*
Delete unused columns
Now that we have split out the addresses we no longer need the original address columns
We also do not need the original sale date column anymore
*/

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, SaleDate

SELECT *
FROM NashvilleHousing