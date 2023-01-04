--Cleaning Data in SQL  Queries

SELECT *
FROM HousingProjectSQL.dbo.NashvilleHousing




--Standardizing Date format
Select SaleDate, CONVERT(Date,  SaleDate)
FROM HousingProjectSQL.dbo.NashvilleHousing

Update NashvilleHousing
SET SaleDate =  Convert(Date,SaleDate)

--------------------------------------
------------------------------Populating Null Property Address Data
-----Checking for Null Values
SELECT *
FROM HousingProjectSQL.dbo.NashvilleHousing
WHERE  PropertyAddress  is NULL
ORDER BY ParcelID
--There are 29 rows with NULL Values


SELECT *
FROM HousingProjectSQL.dbo.NashvilleHousing
ORDER  BY ParcelID
--Rows with matching Parcel IDS have the same PropertyAddress

--Do a self join to populate NULL PropertyAddress with maching Parcel ID
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingProjectSQL.dbo.NashvilleHousing a
JOIN HousingProjectSQL.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingProjectSQL.dbo.NashvilleHousing a
JOIN HousingProjectSQL.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
	WHERE a.PropertyAddress IS NULL


--------------------------Formatting Addresses and breaking them down to individual columns for easier readability (Address, City, State)
SELECT *
FROM HousingProjectSQL.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL
--Commas are delimiters for the city

--Using Substring and CHARINDEX to split the Address column

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, Len(PropertyAddress)) as City
FROM HousingProjectSQL.dbo.NashvilleHousing


--Altering tables (Adding tables with new columns and updating table)
ALTER TABLE NashvilleHousing
Add PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertySplitCity =  SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, Len(PropertyAddress)) 


--Checking updated Table
SELECT *
FROM HousingProjectSQL.dbo.NashvilleHousing

------------------------DONE--------------------
--Checking for Null values in OwnerAddress column
SELECT *
FROM HousingProjectSQL.dbo.NashvilleHousing
WHERE OwnerAddress IS NULL

--Splitting OwnerAddress into 3 columns (Address,City,State) using PARSENAME
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)
FROM HousingProjectSQL.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress =  PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitCity =  PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) 

ALTER TABLE NashvilleHousing
Add OwnerSplitState NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitState =  PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) 

--CHECKING
SELECT * 
FROM HousingProjectSQL.dbo.NashvilleHousing

--DONE




---------CHANGING SoldAsVacant 'Y' 'N' value to 'Yes' and 'No'
--Initial Check
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM HousingProjectSQL.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


--Using CASE WHEN to replace 'y' 'n' 
SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'NO'
	 ELSE SoldAsVacant
	 END
From HousingProjectSQL.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
				   WHEN SoldAsVacant = 'N' THEN 'NO'
				   ELSE SoldAsVacant
				   END


-----REMOVING DUPLICATES
--USING A CTE 

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID
					) row_num

FROM HousingProjectSQL.dbo.NashvilleHousing
--ORDER BY ParcelID
)
SELECT *  
FROM RowNumCTE
WHERE row_num >1
--ORDER BY PropertyAddress
--row_num will show 2 if there are duplicates based on what we partitioned by. Then create a CTE so that we can use a WHERE clause
-- 104 rows found to be duplicates, replace SELECT with DELETE to delete duplicate rows



----------Deleting unused columns

SELECT * 
FROM HousingProjectSQL.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress,OwnerAddress,TaxDistrict,SaleDate

--Data table cleaned and ready for analysis