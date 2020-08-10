--Which tracks appeared in the most playlists? how many playlist did they appear in?
SELECT tracks.name, playlist_track.TrackId, count(playlist_track.TrackId) as 'Playlists',
        playlists.name 
FROM tracks
JOIN playlist_track on tracks.TrackId =
     playlist_track.TrackId
JOIN playlists on  playlist_track.PlaylistId =
     playlists.PlaylistId
	 GROUP by playlist_track.TrackId
	 order by count(playlist_track.TrackId) DESC;
	 
--Which track generated the most revenue? 
SELECT tracks.name, tracks.TrackId, ifnull(SUM(invoice_items.UnitPrice * invoice_items.Quantity),0) AS 'Revenue', 
albums.Title, genres.Name 
FROM tracks
LEFT JOIN invoice_items ON invoice_items.TrackId = tracks.TrackId
JOIN albums ON albums.AlbumId = tracks.AlbumId
JOIN genres ON genres.GenreId = tracks.GenreId
GROUP BY tracks.TrackId
ORDER BY sum(invoice_items.UnitPrice * invoice_items.Quantity) DESC;

--which album? 
SELECT tracks.name, tracks.TrackId, ifnull(SUM(invoice_items.UnitPrice * invoice_items.Quantity),0) AS 'Revenue', 
albums.Title
FROM tracks
LEFT JOIN invoice_items ON invoice_items.TrackId = tracks.TrackId
JOIN albums ON albums.AlbumId = tracks.AlbumId
GROUP BY albums.AlbumId
ORDER BY sum(invoice_items.UnitPrice * invoice_items.Quantity) DESC;

--which genre?
SELECT genres.GenreId, genres.Name ,ifnull(round(SUM(invoice_items.UnitPrice * invoice_items.Quantity),2),0) AS 'Revenue' 
FROM tracks
LEFT JOIN invoice_items ON invoice_items.TrackId = tracks.TrackId
JOIN genres ON genres.GenreId = tracks.GenreId
GROUP BY genres.GenreId
ORDER BY sum(invoice_items.UnitPrice * invoice_items.Quantity) DESC;

-- Which countries have the highest sales revenue? What percent of total revenue does each country make up?
--What percent of total revenue does each country make up?
SELECT customers.Country, ifnull(round(SUM(invoice_items.UnitPrice * invoice_items.Quantity),2),0) AS 'Revenue',
round((ifnull(round(SUM(invoice_items.UnitPrice * invoice_items.Quantity),2),0) /
(SELECT SUM(invoice_items.UnitPrice * invoice_items.Quantity) FROM invoice_items) * 100),2) AS 'Pct Country Rev'
from customers
LEFT JOIN invoices on customers. CustomerId =
		  invoices.CustomerId
JOIN invoice_items on invoices.InvoiceId =
	 invoice_items.InvoiceId
GROUP BY customers.Country
ORDER BY SUM(invoice_items.UnitPrice * invoice_items.Quantity) DESC;

--How many customers did each employee support,
-- what is the average revenue for each sale,
-- and what is their total sale?
SELECT  employees.EmployeeId, employees.FirstName, count(DISTINCT customers.CustomerId) AS '# Of Customers',
ifnull(round(AVG(invoices.total),2),0) as 'Avg Rev', -- FOR EACH SALE NOT BY CUSTOMER!!!
ifnull(round(SUM(invoices.total),2),0) as 'Total Sale'
FROM employees
LEFT JOIN customers ON customers.SupportRepId = employees.EmployeeId
JOIN invoices ON invoices.CustomerId = customers.CustomerId
GROUP BY customers.SupportRepId
ORDER BY SUM(invoices.total) DESC;

-- Additional Challenges
-- Intermediate Challenge
-- Do longer or shorter length albums tend to generate more revenue?

WITH album_tracks as (SELECT tracks.AlbumId as 'AlbumID', sum(tracks.Milliseconds) / 1000 / 60 as 'Length'
   FROM tracks
   GROUP BY tracks.AlbumId)
   SELECT tracks.AlbumId, albums.Title, album_tracks.length, 
   round(sum(invoice_items.UnitPrice * invoice_items.Quantity),2) as 'Revenue'
   FROM tracks
   JOIN invoice_items on invoice_items.TrackId =
        tracks.TrackId
   JOIN album_tracks on album_tracks.AlbumID = tracks.AlbumId
   JOIN albums on albums.AlbumId = tracks.AlbumId
   GROUP BY tracks.AlbumId
   ORDER BY round(sum(invoice_items.UnitPrice * invoice_items.Quantity),2) DESC;
   
--Is the number of times a track appear in any playlist a good indicator of sales?

WITH pl_trk as (SELECT playlist_track.TrackId as 'TrackID', count(playlist_track.PlaylistId) as 'Playlist_Num'
FROM playlist_track
GROUP BY playlist_track.TrackId
ORDER BY count(playlist_track.PlaylistId) DESC)
   SELECT tracks.TrackId, tracks.Name, pl_trk.Playlist_Num,
   round(sum(invoice_items.UnitPrice * invoice_items.Quantity),2) as 'Sales'
   FROM tracks
   JOIN invoice_items on invoice_items.TrackId =
        tracks.TrackId
   JOIN pl_trk on pl_trk.TrackID = tracks.TrackId
   group by pl_trk.TrackId
   ORDER BY round(sum(invoice_items.UnitPrice * invoice_items.Quantity),2) DESC;

-- Short version of the previous Query   
WITH pl_trk as (SELECT playlist_track.TrackId as 'TrackID', count(playlist_track.TrackId) as 'Playlist_Num'
FROM playlist_track
GROUP BY playlist_track.TrackId
ORDER BY count(playlist_track.TrackId) DESC)
   SELECT pl_trk.TrackId, pl_trk.Playlist_Num,
   round(sum(invoice_items.UnitPrice * invoice_items.Quantity),2) as 'Sales'
   FROM pl_trk
   JOIN invoice_items on invoice_items.TrackId =
        pl_trk.TrackId
   group by pl_trk.TrackId
   ORDER BY round(sum(invoice_items.UnitPrice * invoice_items.Quantity),2) DESC;

--Advanced Challenge

--How much revenue is generated each year, and what is its percent change from the previous year?

WITH yearly_sales as (SELECT CAST(strftime('%Y',invoices.InvoiceDate) AS int) as 'Year', 
                             sum(invoices.Total) as 'Total'
	FROM invoices
	group by Year
	order by Year DESC)
    , last_year_sales as (SELECT CAST(strftime('%Y',invoices.InvoiceDate) AS int) as 'Prev_Year', 
     sum(invoices.Total) as 'Prev_Total'
	 FROM invoices
     group by Prev_Year
	 order by Prev_Year DESC)
SELECT yearly_sales.Year, yearly_sales.Total, last_year_sales.Prev_Year, last_year_sales.Prev_Total,
      round(((yearly_sales.Total - last_year_sales.Prev_Total) / last_year_sales.Prev_Total) * 100,2) as 'Change'
FROM yearly_sales
JOIN last_year_sales on last_year_sales.Prev_Year = Yearly_Sales.Year -1
GROUP BY Year
ORDER BY Year;


