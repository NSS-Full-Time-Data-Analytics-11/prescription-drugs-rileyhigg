--1. 
 --a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
	--Report the npi and the total number of claims. 1881634483, 99707.
	
SELECT npi, SUM (total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC;

    
 --b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  
 ----specialty_description, and the total number of claims. Bruce Pendley Family Practice 99707.
 
 SELECT npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM (total_claim_count) AS total_claims
 FROM prescriber INNER join prescription USING (npi)
 GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
 ORDER BY total_claims DESC
 LIMIT 5;
 
 --2. 
 --a. Which specialty had the most total number of claims (totaled over all drugs)? Family Practice
 
 SELECT specialty_description, SUM (total_claim_count) AS total_claims
 FROM prescriber INNER join prescription USING (npi)
 GROUP BY specialty_description
 ORDER BY total_claims DESC
 LIMIT 5;
 

 --b. Which specialty had the most total number of claims for opioids?
 
 SELECT specialty_description, SUM (total_claim_count) AS opioid_drug_sum
 FROM drug INNER JOIN prescription USING (drug_name)
 		   INNER JOIN prescriber USING (npi)
 WHERE opioid_drug_flag = 'Y'
 GROUP BY specialty_description
 ORDER BY opioid_drug_sum DESC
 LIMIT 5;

 --c. **Challenge Question:** Are there any specialties that appear in the prescriber table 
   ---that have no associated prescriptions in the prescription table? Yes, 15
   
 SELECT specialty_description, COUNT (total_claim_count) AS claim_count
 FROM prescriber FULL JOIN prescription USING (npi)
 GROUP BY specialty_description
 ORDER BY claim_count;
 

 --d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, 
  --- report the percentage of total claims by that specialty which are for opioids. Which specialties have a
  --- high percentage of opioids?
  
  
-- 3. 
 --a. Which drug (generic_name) had the highest total drug cost?
 
SELECT generic_name, SUM (total_drug_cost) AS drug_cost
FROM drug INNER JOIN prescription USING (drug_name)
GROUP BY generic_name
ORDER BY drug_cost DESC
LIMIT 10;


 --b. Which drug (generic_name) has the hightest total cost per day? 
 ---**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
 
 SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2) AS cost_per_day
 FROM prescription LEFT JOIN drug USING (drug_name)
 GROUP BY generic_name
 ORDER BY cost_per_day DESC
 LIMIT 5;
 
 
-- 4. 
--a. For each drug in the drug table, return the drug name and then a column named 'drug_type' 
 --- which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs 
 --- which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
 
 SELECT drug_name, 
 		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			 ELSE  'neither'
			 END AS drug_type
 FROM drug;
 

--b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) 
 --- on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
 
 SELECT SUM (total_drug_cost) AS money, 
 		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			 ELSE  'neither'
			 END AS drug_type 			
 FROM drug LEFT JOIN prescription USING (drug_name)
 GROUP BY drug_type;
 		
			 
--5. 
--  a. How many CBSAs are in Tennessee?
--  **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT (DISTINCT cbsaname)
FROM cbsa
WHERE cbsaname LIKE '%TN%';


--  b. Which cbsa has the largest combined population? Nasvhille 1830410  Which has the smallest? Morristown 116352
--  Report the CBSA name and total population.

SELECT SUM(population) AS sum_population, cbsaname
FROM population INNER JOIN cbsa USING (fipscounty)
GROUP BY cbsaname
ORDER BY sum_population DESC;



--  c. What is the largest (in terms of population) county which is not included in a CBSA?
--  Report the county name and population.
 
WITH non_cbsa AS ((SELECT fipscounty
 				  FROM population)
 				  EXCEPT
 				 (SELECT fipscounty
				  FROM cbsa))
				  
SELECT fipscounty, population, county
FROM non_cbsa LEFT JOIN population USING (fipscounty)
			  LEFT JOIN fips_county USING (fipscounty)
ORDER BY population DESC;

-- 6. 
--  a. Find all rows in the prescription table where total_claims is at least 3000. 
--  Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--  b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, total_claim_count,
			CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			 	 WHEN opioid_drug_flag = 'N' THEN 'non-opioid'
			 	 END AS opioid_status
FROM prescription LEFT JOIN drug USING (drug_name)
WHERE total_claim_count >= 3000;

--  c. Add another column to you answer from the previous part which gives the prescriber 
--  first and last name associated with each row.
 
SELECT drug_name, total_claim_count, nppes_provider_last_org_name, nppes_provider_first_name,
			CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			 	 WHEN opioid_drug_flag = 'N' THEN 'non-opioid'
			 	 END AS opioid_status
FROM prescription LEFT JOIN drug USING (drug_name)
				  LEFT JOIN prescriber USING (npi)
WHERE total_claim_count > 3000;

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville 
  -- and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

  -- a. First, create a list of all npi/drug_name combinations for pain management specialists 
  ---(specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'),
  ---where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. 
  ---You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, drug_name
FROM prescriber CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
  AND nppes_provider_city = 'NASHVILLE'
  AND opioid_drug_flag = 'Y'
ORDER BY npi, drug_name;


  -- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, 
  ---whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
  
WITH prescriber_drug_combo AS (SELECT npi, drug_name
							  FROM prescriber CROSS JOIN drug
							  WHERE specialty_description = 'Pain Management'
  								AND nppes_provider_city = 'NASHVILLE'
 								AND opioid_drug_flag = 'Y')

SELECT prescriber_drug_combo.npi, prescriber_drug_combo.drug_name, COALESCE (total_claim_count, 0) AS number_of_claims
FROM prescriber_drug_combo LEFT JOIN prescription ON prescriber_drug_combo.npi = prescription.npi
						   AND prescriber_drug_combo.drug_name = prescription.drug_name
ORDER BY npi, prescriber_drug_combo.drug_name;

  -- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
  ---Hint - Google the COALESCE function.


