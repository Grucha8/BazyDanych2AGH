-- procedury / funckcje
-- a)
-- dodatkowe typy do zwracania tabeli
create or replace type uczestnicy_wyczieczki_type as OBJECT (
  kraj VARCHAR2(50),
  data_ DATE,
  nazwa_wycieczki VARCHAR2(100),
  imie VARCHAR2(50),
  nazwisko VARCHAR2(50),
  status_rezerwacji char(1)
);

CREATE OR REPLACE type uczestnicy_wycieczki_table as TABLE OF uczestnicy_wyczieczki_type;


create or REPLACE FUNCTION uczestnicy_wycieczki (id_wycieczki_i in number)
  return uczestnicy_wycieczki_table
AS
  id_exist NUMBER(1);
  uczestnicy uczestnicy_wycieczki_table;
  BEGIN
    uczestnicy := uczestnicy_wycieczki_table();

    SELECT CASE
      WHEN exists(SELECT *
                  FROM WYCIECZKI w
                  WHERE w.ID_WYCIECZKI = id_wycieczki_i)
        THEN 1
        ELSE 0
    END
      INTO id_exist
      FROM dual;

    IF id_exist = 0 THEN
      raise_application_error(-20001, 'wycieczka nie istnieje');
    END IF;

    SELECT uczestnicy_wyczieczki_type(wo.KRAJ, wo.data, wo.NAZWA, wo.IMIE, wo.NAZWISKO, wo.STATUS)
    BULK COLLECT into uczestnicy
    FROM wycieczki_osoby wo
    where wo.ID_WYCIECZKI = id_wycieczki_i;

    RETURN uczestnicy;
  END;

SELECT *
  FROM uczestnicy_wycieczki(12) w
WHERE w.status_rezerwacji = 'N';

-- b)
create or REPLACE FUNCTION rezerwacje_osoby(id_osoby_i in NUMBER)
  RETURN uczestnicy_wycieczki_table
AS
  id_exist NUMBER(1);
  wycieczki uczestnicy_wycieczki_table;
  BEGIN
    wycieczki := uczestnicy_wycieczki_table();

    SELECT CASE
      WHEN exists(SELECT *
                  FROM OSOBY o
                  WHERE o.ID_OSOBY = id_osoby_i)
        THEN 1
        ELSE 0
    END
      INTO id_exist
      FROM dual;

    IF id_exist = 0 THEN
      raise_application_error(-20001, 'Osoba o takim id nie istnieje');
    END IF;

    SELECT uczestnicy_wyczieczki_type(w.KRAJ, w.DATA, w.NAZWA, o.IMIE, o.NAZWISKO, r.STATUS)
    BULK COLLECT INTO wycieczki
    FROM rezerwacje r
      join OSOBY o ON r.ID_OSOBY = o.ID_OSOBY
      JOIN WYCIECZKI w ON r.ID_WYCIECZKI = w.ID_WYCIECZKI
    WHERE r.ID_OSOBY = id_osoby_i;

    return wycieczki;
  END;

SELECT *
FROM REZERWACJE_OSOBY(5);

-- c)
CREATE or REPLACE FUNCTION przyszle_rezerwacje (id_osoby_i in NUMBER)
  return uczestnicy_wycieczki_table
AS
  id_exist NUMBER(1);
  rezerwacje_ uczestnicy_wycieczki_table;
  BEGIN
    rezerwacje_ := uczestnicy_wycieczki_table();

    SELECT CASE
      WHEN exists(SELECT *
                  FROM OSOBY o
                  WHERE o.ID_OSOBY = id_osoby_i)
        THEN 1
        ELSE 0
    END
      INTO id_exist
      FROM dual;

    IF id_exist = 0 THEN
       raise_application_error(-20001, 'Osoba o takim id nie istnieje');
    END IF;

     SELECT uczestnicy_wyczieczki_type(w.KRAJ, w.DATA, w.NAZWA, o.IMIE, o.NAZWISKO, r.STATUS)
     BULK COLLECT INTO rezerwacje_
     FROM rezerwacje r
      join OSOBY o ON r.ID_OSOBY = o.ID_OSOBY
      JOIN WYCIECZKI w ON r.ID_WYCIECZKI = w.ID_WYCIECZKI
     WHERE r.ID_OSOBY = id_osoby_i AND w.DATA > current_date AND r.STATUS != 'A';

     return rezerwacje_;
  END;

SELECT *
FROM przyszle_rezerwacje(26);

-- d)
create or replace type przyszle_wycieczki_type as OBJECT (
  id_wyczieczki NUMBER,
  kraj VARCHAR2(50),
  data_ DATE,
  nazwa_wycieczki VARCHAR2(100),
  opis_wycieczki VARCHAR2(200),
  liczba_wolnych_miejsc NUMBER
);

CREATE or REPLACE type przyszle_wycieczki_table as TABLE OF przyszle_wycieczki_type;


CREATE or REPLACE FUNCTION przyszle_wycieczki (kraj_i in VARCHAR2, data_od in DATE, data_do in DATE)
  return przyszle_wycieczki_table
AS
  kraj_exist NUMBER(1);
  dostepne_wycieczki_ przyszle_wycieczki_table;
BEGIN
  dostepne_wycieczki_ := przyszle_wycieczki_table();

  SELECT CASE
      WHEN exists(SELECT *
                  FROM WYCIECZKI w
                  WHERE w.KRAJ = kraj_i)
        THEN 1
        ELSE 0
    END
      INTO kraj_exist
      FROM dual;

    IF kraj_exist = 0 THEN
       raise_application_error(-20001, 'Nie ma takiego kraju');
    END IF;

  SELECT przyszle_wycieczki_type(w.ID_WYCIECZKI, w.KRAJ, w.DATA, w.NAZWA, w.OPIS, w.LICZBA_MIEJSC - ZAJETE_MIEJSCA(w.ID_WYCIECZKI))
  BULK COLLECT INTO dostepne_wycieczki_
  FROM WYCIECZKI w
    JOIN REZERWACJE r ON w.ID_WYCIECZKI = r.ID_WYCIECZKI
  WHERE (w.DATA >= data_od) AND (w.DATA <= data_do) AND (w.KRAJ = kraj_i) AND (w.liczba_miejsc - zajete_miejsca(w.ID_WYCIECZKI)) > 0;

  RETURN dostepne_wycieczki_;
END;

SELECT *
FROM TABLE (przyszle_wycieczki('Polska', '2017:02:03', '2020:01:01'));