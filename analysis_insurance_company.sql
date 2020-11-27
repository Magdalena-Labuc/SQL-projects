WITH w_lata AS
(
SELECT w.id,
	w.stan_wniosku,
	date_part('year', w.data_utworzenia) as rok_wniosku,
	sp.identyfikator_podrozy
FROM wnioski w
	JOIN podroze p
	ON p.id_wniosku = w.id 
	JOIN szczegoly_podrozy sp
	ON p.id = sp.id_podrozy 
WHERE date_part('year',w.data_utworzenia) > '2015' AND w.stan_wniosku <> 'nowy' AND sp.identyfikator_podrozy NOT LIKE '%----%'
ORDER BY rok_wniosku
),


r_lotu AS 
(
SELECT kod_polaczenia, 
	wylot_nazwa_kraju, 
	przylot_nazwa_kraju,
	wylot_nazwa_regionu,
	przylot_nazwa_regionu,
	CASE 
	WHEN wylot_nazwa_kraju = przylot_nazwa_kraju THEN 'lot_krajowy'
	WHEN split_part(wylot_nazwa_regionu, ':', 1) = split_part(przylot_nazwa_regionu, ':', 1) THEN 'lot_regionalny'
	ELSE 'lot_miêdzykontynentalny'
	END AS rodzaj_lotu
FROM o_trasy
),


wsp_loty AS
(
SELECT rl.rodzaj_lotu,
	wl.rok_wniosku,
	count(wl.id) AS liczba_wnioskow,
	count(CASE WHEN wl.stan_wniosku = 'wyplacony' THEN wl.id END)::numeric / count(wl.id) as ws_wyplat
	FROM w_lata wl
	JOIN r_lotu rl
	ON rl.kod_polaczenia = wl.identyfikator_podrozy
	GROUP BY wl.rok_wniosku, rl.rodzaj_lotu
	ORDER BY rok_wniosku
)

SELECT *,
((wsp_loty.ws_wyplat - lag(wsp_loty.ws_wyplat) over (partition by rodzaj_lotu))/ lag(wsp_loty.ws_wyplat) over (partition by rodzaj_lotu)) as wsp_yoy
FROM wsp_loty
