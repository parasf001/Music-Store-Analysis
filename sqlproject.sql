create database sqlproject

 use sqlproject

select * from album$
select * from artist
select * from customer
select * from employee
select * from invoice
select * from invoice_line
select * from media_type
select * from playlist
select * from playlist_track
select * from track$
select * from genre

--Project Phase I
----1. Who is the senior most employee based on job title?

SELECT top 1 first_name,last_name,title
FROM employee
ORDER BY levels DESC

----using cte----

WITH CTE AS (select first_name,last_name,title,row_number()over(order by levels desc) as rnk from employee)
select first_name,last_name,title from CTE where rnk=1


---2. Which countries have the most Invoices?

select billing_country,count(invoice_id) as num_of_invioce from invoice
group by billing_country order by count(invoice_id) desc


------using cte----
WITH CTE AS(
SELECT billing_country , COUNT(invoice_id) as cnt , dense_rank() OVER(ORDER BY COUNT(invoice_id) DESC) as ran
FROM invoice
GROUP BY billing_country)

SELECT billing_country , cnt
FROM CTE
ORDER BY cnt DESC;

--3. What are top 3 values of total invoice? 


with cte as (select  total, dense_rank() over (order by total desc ) as rnk from invoice)
select distinct total from cte where rnk <=3
order by total desc



--4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money.
-----Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals 

select top 1 billing_city,sum(total) as invoice_total 
from invoice group by billing_city
order by invoice_total desc

--5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
---Write a query that returns the person who has spent the most money 
SELECT TOP 1 C.customer_id,C.first_name+ ' '+C.last_name as Cust_Name, SUM(I.total) as TotalSpent
FROM customer C
INNER JOIN invoice I
ON C.customer_id = I.customer_id
GROUP BY C.customer_id, C.first_name, C.last_name
ORDER BY TotalSpent DESC;

---using subquary---
Select TOP 1 Cust_Name,customer_id,TotalSpent from (select c.customer_id,c.first_name+' '+c.last_name as Cust_Name, SUM(I.total) as TotalSpent
from customer C INNER JOIN invoice I ON C.customer_id=I.customer_id GROUP BY C.customer_id, C.first_name, C.last_name)AS Customer_Spending 
order by TotalSpent DESC



--Project Phase II

---1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
---Return your list ordered alphabetically by email starting with A 

select DISTINCT c.first_name,c.last_name,c.email,g.name
from customer c inner join invoice i
on c.customer_id=i.customer_id
inner join invoice_line il on
i.invoice_id=il.invoice_id
inner join track$ t on il.track_id=t.track_id
inner join genre g on t.genre_id=g.genre_id
where g.name like 'Rock' 
ORDER BY c.email;

-----USING SUBQUARY----
select distinct email,first_name, last_name from Customer C inner join invoice i on C.customer_id=i.customer_id
inner join invoice_line il on i.invoice_id=il.invoice_id where track_id IN(
select track_id from track$ t join genre g on t.genre_id=g.genre_id 
where g.name like 'Rock') order by email 



---2. Let's invite the artists who have written the most rock music in our dataset.
--Write a query that returns the Artist name and total track count of the top 10 rock bands 


SELECT TOP 10 A.name as ArtistName, COUNT(T.track_id) as  total_track_count
FROM artist A
INNER JOIN album$ AL
ON A.artist_id = AL.artist_id
INNER JOIN track$ T
ON AL.album_id = T.album_id
INNER JOIN genre G
ON T.genre_id = G.genre_id
WHERE G.name ='Rock'
GROUP BY A.name
ORDER BY total_track_count DESC;


---------Using CTE and Windows Function----------

with cte as (select A.name as ArtistName,COUNT(T.track_id) as total_track_count, rank() over (order by count(T.track_id) desc) as rnk 
from artist A inner join album$ AL ON A.artist_id=AL.artist_id
inner join track$ T on AL.album_id=T.album_id
inner join genre G on T.genre_id=G.genre_id
where G.name='Rock'
group by A.name)

select ArtistName,total_track_count from cte where rnk<=10



--3. Return all the track names that have a song length longer than the average song length.
--Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first

SELECT name, milliseconds
FROM track$
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track$)
ORDER BY milliseconds DESC;


--Project Phase III
---1. Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent 


SELECT  C.first_name+' '+ C.last_name as cust_name, A.name as artist_name, SUM(IL.unit_price * IL.quantity)total_spent
FROM customer C
INNER JOIN invoice I
ON C.customer_id = I.customer_id
INNER JOIN invoice_line IL
ON I.invoice_id = IL.invoice_id
INNER JOIN track$ T
ON IL.track_id = T.track_id
INNER JOIN album$ AL
ON T.album_id = AL.album_id
INNER JOIN artist A
ON AL.artist_id = A.artist_id
GROUP BY C.first_name, C.last_name, A.name
ORDER BY total_spent DESC

--Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
--with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
--the maximum number of purchases is shared return all Genres. 

 with CTE as (
 
 select c.country,  g.name as music_genre, count(invl.quantity) as max_purchases,
 row_number() over( partition by c.country order by count(invl.quantity) desc) as ranking
 from customer c 
 join invoice inv on inv.customer_id = c.customer_id
 join invoice_line invl on inv.invoice_id = invl.invoice_id
 join track$ t on t.track_id = invl.track_id
 join genre g on g.genre_id = t.genre_id
 group by c.country,g.name 
 )
 
select * from cte
where ranking = 1
order by max_purchases desc



--3. Write a query that determines the customer that has spent the most on music for each country. 
--Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount

WITH CTE AS(
SELECT I.billing_country as country,C.first_name+' '+ C.last_name as cust_name , SUM(I.total)total_spendings, DENSE_RANK() OVER(partition by I. billing_country ORDER BY SUM(I.total) DESC)ran
FROM customer C
INNER JOIN invoice I
ON C.customer_id = I.customer_id
GROUP BY I.billing_country, C.first_name, C.last_name)

SELECT country, cust_name, total_spendings
FROM CTE
WHERE ran = 1;


----Others Insights------

--- What is the most popular mediatype by number of times invoiced?---
  SELECT m.Name, COUNT(*) AS times_invoiced
  FROM media_type m
  JOIN track$ t
  ON t.media_type_id = m.media_type_id
  JOIN invoice_line l
  ON l.track_id = t.track_id
  GROUP BY m.name
  ORDER BY COUNT(*) DESC;
  
  ---How much was spent over all on each genre?
  SELECT G.name,
  	round(SUM(IL.unit_price),2) as totla_price
  FROM customer C
  JOIN invoice I ON I.customer_id = C.customer_id
  JOIN invoice_line IL ON IL.invoice_id = I.invoice_id
  JOIN track$ T ON T.track_id = IL.track_id
  JOIN genre G ON G.genre_id = T.genre_id
  GROUP BY G.name
  ORDER BY 	SUM(IL.unit_price) DESC
  
---How many users per country?
  SELECT C.country,
  	COUNT(C.customer_id) as users
  FROM customer C
  GROUP BY C.country
  ORDER BY COUNT(C.customer_id)desc
  
---how many songs per genre the music store has?
  SELECT G.name,
  COUNT(T.track_id)as total_song
  FROM track$ T
  JOIN genre G ON T.genre_id = G.genre_id
  GROUP BY G.name
  ORDER BY COUNT(T.track_id) DESC
  
  
   


