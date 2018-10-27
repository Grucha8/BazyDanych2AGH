-- procedury modyfikujace dane
-- a)
CREATE or REPLACE PROCEDURE dodaj_rezerwacje(id_wycieczki_i in NUMBER, id_osoby_i in NUMBER)
AS
  id_w_exist NUMBER;
  id_o_exist NUMBER;
  czy_da_sie_dodac NUMBER;
  BEGIN
    IF id_wycieczki_i is NULL OR id_osoby_i is NULL THEN
      raise_application_error(-20001, 'Musisz podac argumenty');
    END IF;

    SELECT CASE
      WHEN exists(SELECT *
                  FROM dostepne_wycieczki w
                  WHERE w.ID_WYCIECZKI = id_wycieczki_i)
        THEN 1
        ELSE 0
    END
      INTO id_w_exist
      FROM dual;

    SELECT CASE
      WHEN exists(SELECT *
                  FROM OSOBY o
                  WHERE o.ID_OSOBY = id_osoby_i)
        THEN 1
        ELSE 0
    END
      INTO id_o_exist
      FROM dual;

    if id_w_exist = 0 THEN
      raise_application_error(-20000, 'nie ma takiej wycieczki');
    END IF;
    if id_o_exist = 0 THEN
      raise_application_error(-20000, 'nie ma takigo id osoby');
    END IF;

    -- dodajemy
    INSERT INTO REZERWACJE(ID_WYCIECZKI, ID_OSOBY, STATUS)
    VALUES (id_wycieczki_i, id_osoby_i, 'N');

  END;

BEGIN
  dodaj_rezerwacje(1, 25);
END;

-- b)
CREATE OR REPLACE PROCEDURE zmien_status_rezerwacji (id_rezerwacji_i in NUMBER, status_i in CHAR)
  AS
  id_r_exist NUMBER;
  status_is_valid NUMBER;
  czy_da_sie_zmienic NUMBER;
  status_obecny CHAR(1);
  BEGIN
    SELECT CASE
      WHEN exists(SELECT *
                  FROM REZERWACJE r
                    JOIN WYCIECZKI w ON w.ID_WYCIECZKI = r.ID_WYCIECZKI
                  WHERE r.NR_REZERWACJI = id_rezerwacji_i AND w.DATA > current_date)
        THEN 1
        ELSE 0
    END
      INTO id_r_exist
      FROM dual;

    IF status_i IN ('N', 'P', 'Z', 'A') THEN
      SELECT 1 INTO status_is_valid FROM dual;
    ELSE
      SELECT 0 INTO status_is_valid FROM dual;
    END IF;

    IF id_r_exist = 0 THEN
      raise_application_error(-20000, 'Nie ma takiej rezerwacji lub nie da sie zmienic jej statusu');
    END IF;
    IF status_is_valid = 0 THEN
      raise_application_error(-20000, 'Zly status, mozliwe opcje: N, P, Z, A');
    END IF;
    -- =========

    SELECT r.STATUS
    INTO status_obecny
    FROM REZERWACJE r
    WHERE r.NR_REZERWACJI = id_rezerwacji_i and ROWNUM = 1;

    IF (status_obecny = 'N' AND status_i = 'N') THEN
      raise_application_error(-20000, 'Nie da sie zmienic statusu z Nowy na Nowy');
    END IF;
    IF (status_obecny = 'P' AND status_i IN ('N', 'P')) THEN
      raise_application_error(-20000, 'Nie da sie P=>N i P=>P');
    END IF;
    IF (status_obecny = 'Z' AND status_i IN ('N', 'P', 'Z')) THEN
      raise_application_error(-20000, 'Status "Potwierdzona i zaplacona" da sie tylko zmienic na Anulowana');
    END IF;
    IF status_obecny = 'A' THEN
      raise_application_error(-20000, 'Nie da sie zmienic statusu Anulowany');
    END IF;

    UPDATE REZERWACJE r
    SET r.STATUS = status_i
    WHERE r.NR_REZERWACJI = id_rezerwacji_i;
  END;

BEGIN
  zmien_status_rezerwacji(23, 'A');
END;

-- c)
