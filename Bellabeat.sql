-- Column names and data types were checked

Select
	*
FROM 
	INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_NAME = 'daily_activity';

Select
	*
FROM 
	INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_NAME = 'sleepday_merged';

-- Checked the distinict Id numbers for the datasets. Daily_activity has 33 participants while Sleepday_merged only has 24. 

Select
	count(distinct id)
From 
	daily_activity;

Select
	count(distinct id)
From 
	sleepday_merged;
 
 -- There are 77 instances where users' steps were not tracked. All sleep minutes tracked were > 0 minutes. There are 4 instances where calories were tracked as 0. 
 
Select 
	*
From 
	daily_activity
Where
	TotalSteps = 0;
    
Select 
	*
From 
	sleepday_merged
Where
	TotalMinutesAsleep = 0;

Select 
	*
From 
	daily_activity
Where
	Calories = 0;
 
 -- A new date column was created with the date data type for both datasets
 
Alter Table
	daily_activity 
ADD COLUMN 
	new_date DATE;
UPDATE 
	daily_activity 
SET 
	new_date = STR_TO_DATE(ActivityDate, '%m/%d/%Y');

ALTER TABLE 
	sleepday_merged
ADD COLUMN 
	new_date DATE;
UPDATE 
	sleepday_merged 
SET 
	new_date = STR_TO_DATE(Date, '%m/%d/%Y');


-- Added Activity_Level column to daily_activity. 

Alter Table
	daily_activity
Add
	Activity_Level TEXT
As (
	CASE 
    When TotalSteps > 10000 then 'Active'
    When TotalSteps >= 7500 then 'Somewhat Active'
    When TotalSteps < 5000 then 'Sedentary'
    Else 'Low Active' End);

Select 
	Id, TotalSteps, Activity_Level
From 
	daily_activity;

-- Added Calorie_Level column to daily_activity. 

Alter Table
	daily_activity
Add
	Calorie_Level TEXT
As (
	CASE 
    When Calories > 3000 then 'Extra Calories'
    When Calories < 1600 then 'Low Calories'
    Else 'Expected Calories' End);
    
Select 
	Id, Calories, Calorie_Level
From 
	daily_activity;

-- Added Sleep_Level column to sleepday_merged. 

Alter Table
	sleepday_merged
Add
	Sleep_Level TEXT
As (
	CASE 
    When (TotalMinutesAsleep/60) > 9 then 'Over Sleep'
    When (TotalMinutesAsleep/60) < 7 then 'Under Sleep'
    Else 'Good Sleep' End);

Select 
	Id, (TotalMinutesAsleep/60), Sleep_Level
From 
	sleepday_merged;


-- Added Asleep_Hours column to sleepday_merged. 

Alter Table
	sleepday_merged
Add
	Asleep_Hours Decimal(18,8)
As 
	(TotalMinutesAsleep/60);
   
Select 
	Id, TotalMinutesAsleep, (TotalMinutesAsleep/60), Asleep_Hours
From 
	sleepday_merged;
    
-- Created a table looking at the average total steps per user ID across the days tracked & determining overall Activity level based on steps per 10000steps.org.
-- Instances where 0 steps were tracked were not included in the avg. 

Create Table Activity_Level_Steps
Select 
	Id, Count(Id) as Days_Tracked_Steps, Avg(TotalSteps) as Avg_Total_Steps, 
    CASE 
    When Avg(TotalSteps) > 10000 then 'Active'
    When Avg(TotalSteps) >= 7500 then 'Somewhat Active'
    When Avg(TotalSteps) < 5000 then 'Sedentary'
    Else 'Low Active'
    End as Activity_Level
From
	`bellabeat`.`daily_activity`
Where
	TotalSteps > 0
Group By
	Id
Order By
	Avg(TotalSteps);


-- Created a table looking at the average total sleep & gave a rating based on Adult Sleep requirements per sleepfoundation.org 

Create Table Sleep_Rating_Avg
Select
	Id, Count(id) as Days_Tracked_Sleep, Avg(TotalMinutesAsleep), Avg(TotalMinutesAsleep)/60 as Asleep_Hours,
	CASE 
    When Avg(TotalMinutesAsleep)/60 > 9 then 'Over Sleep'
    When Avg(TotalMinutesAsleep)/60 < 7 then 'Under Sleep'
    Else 'Good Sleep'
    End as Sleep_Rating
From
	sleepday_merged
Group by
	Id
Order By
	Asleep_Hours;
    
-- Created a table looking at avg calories eaten. I included the days of 0 calories as they could have been intentional. 
-- Since we do not know the ages/genders of participants that limits the understanding of participants' calorie levels.
    
Create Table Calories_Tracked
Select 
	Id, Count(Id) as Days_Tracked_Calories, Avg(Calories) as Avg_Calories,
	CASE 
    When Avg(Calories) > 3000 then 'Extra Calories'
    When Avg(Calories) < 1600 then 'Low Calories'
    Else 'Expected Calories'
    End as Calorie_Level
From
	`bellabeat`.`daily_activity`
Group By
	Id
Order By
	Avg(Calories);

-- Joined the Activity_Level_Steps, Sleep_Rating_Avg, & Calories_Tracked tables to see if there were correlations for users' averages of 
-- steps, sleep, and calories for the days tracked. 

Select
	Steps.Id, Steps.Avg_Total_Steps, Steps.Activity_Level, Sleep.Asleep_Hours, Sleep.Sleep_Rating, Calories.Avg_Calories, Calories.Calorie_Level
From bellabeat.Activity_Level_Steps as Steps
Left Join 
	bellabeat.Sleep_Rating_Avg as Sleep
ON Steps.Id = Sleep.Id
Left Join
	bellabeat.Calories_Tracked as Calories
ON Steps.Id = Calories.Id
Order by
	Steps.Avg_Total_Steps;

-- Only 1 sedentary user had good sleep whereas ALL but 1 sedentary user ate within the expected calorie range. Sleep data was not available for 
-- most of the low active users and all but 2 low active users ate within the expected calorie range. All but 1 somewhat active user had good 
-- sleep and only 2 ate extra calories. 2 active users did not have sleep data and the rest all under slept. 4 of the 7 active users ate expected calories. 
