-- widoki
-- a)
CREATE or REPLACE view wycieczki_osoby
  as
    select
      w.ID_WYCIECZKI,
      w.NAZWA,
      w.KRAJ,
      w.DATA,
      o.IMIE,
      o.NAZWISKO,
      r.STATUS
    from wycieczki w
      join REZERWACJE r on w.ID_WYCIECZKI = r.ID_WYCIECZKI
      join osoby o on r.ID_OSOBY = o.ID_OSOBY;

-- b)
create view wycieczki_osoby_potwierdzone
  as
    select
      w.KRAJ,
      w.data,
      w.nazwa,
      o.imie,
      o.nazwisko,
      r.status
    from WYCIECZKI w
      join REZERWACJE r on w.ID_WYCIECZKI = r.ID_WYCIECZKI
      join osoby o on r.ID_OSOBY = o.ID_OSOBY
    where
      r.STATUS = 'P';

-- c)
create view wycieczki_przyszle
  as
    select
      w.KRAJ,
      w.data,
      w.nazwa,
      o.imie,
      o.nazwisko,
      r.status
    from WYCIECZKI w
      join REZERWACJE r on w.ID_WYCIECZKI = r.ID_WYCIECZKI
      join osoby o on r.ID_OSOBY = o.ID_OSOBY
    where
      w.DATA > current_date;

-- d)
create or REPLACE FUNCTION zajete_miejsca (wycieczka in NUMBER)
  RETURN NUMBER
is
  miejsca NUMBER;
BEGIN
  select count(*)
    into miejsca
    from REZERWACJE r
    where r.ID_WYCIECZKI = wycieczka and not (r.STATUS = 'A');

  return miejsca;
END;


create view wycieczki_miejsca
  as
    select
      w.KRAJ,
      w.data,
      w.nazwa,
      w.LICZBA_MIEJSC,
      (w.liczba_miejsc - zajete_miejsca(w.ID_WYCIECZKI)) as liczba_wolnych_miejsc
    from WYCIECZKI w;

-- e)
create or REPLACE view dostepne_wycieczki
  as
    select
          w.ID_WYCIECZKI,
          w.KRAJ,
          w.data,
          w.NAZWA,
          w.LICZBA_MIEJSC,
          (w.liczba_miejsc - zajete_miejsca(w.ID_WYCIECZKI)) as liczba_wolnych_miejsc
    from WYCIECZKI w
    where w.DATA > CURRENT_DATE AND
      (w.liczba_miejsc - zajete_miejsca(w.ID_WYCIECZKI)) > 0;


-- f)
create view rezerwacje_do_anulowania
  AS
    SELECT
      r.STATUS,
      r.ID_WYCIECZKI,
      r.ID_OSOBY,
      w.NAZWA,
      w.DATA
    FROM REZERWACJE r
      join WYCIECZKI w on w.ID_WYCIECZKI = r.ID_WYCIECZKI
    WHERE current_date > (w.DATA - 10) and r.STATUS = 'N';
