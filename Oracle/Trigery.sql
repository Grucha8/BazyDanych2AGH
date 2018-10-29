-- zmiana/dodanie rezerwacji
CREATE OR REPLACE TRIGGER rezerwacje_log_trigger_insert_update
  AFTER INSERT OR UPDATE ON REZERWACJE
  FOR EACH ROW
  WHEN (NEW.NR_REZERWACJI > 0)
  BEGIN
    INSERT INTO REZERWACJE_LOG(ID_REZERWACJI, DATA, STATUS)
    VALUES (:NEW.NR_REZERWACJI, current_date, :new.STATUS);
  END;

-- usuniecie rezerwacji
CREATE OR REPLACE TRIGGER rezerwacje_log_trigger_delete
  AFTER DELETE ON REZERWACJE
  FOR EACH ROW
  WHEN (OLD.NR_REZERWACJI > 0)
  BEGIN
    INSERT INTO REZERWACJE_LOG(ID_REZERWACJI, DATA, STATUS)
    VALUES (:OLD.NR_REZERWACJI, current_date, :OLD.STATUS);
  END;


-- zmodyfikowane procedury
CREATE or REPLACE PROCEDURE dodaj_rezerwacje_3 (id_wycieczki_i in NUMBER, id_osoby_i in NUMBER)
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
                  FROM dostepne_wycieczki_2 w
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

    -- punkt 7: aktualizujemy pole liczba_wolnych_miejsc
    UPDATE WYCIECZKI w
    SET w.LICZBA_WOLNYCH_MIEJSC = w.LICZBA_WOLNYCH_MIEJSC - 1
    WHERE w.ID_WYCIECZKI = id_wycieczki_i;
END;


CREATE OR REPLACE PROCEDURE zmien_status_rezerwacji_3 (id_rezerwacji_i in NUMBER, status_i in CHAR)
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

    -- punkt 7: jesli anulujemy to zmieniamy liczbe wolnychmiejsc
    IF status_i = 'N' THEN
      UPDATE WYCIECZKI w
      SET w.LICZBA_WOLNYCH_MIEJSC = w.LICZBA_WOLNYCH_MIEJSC + 1
      WHERE w.ID_WYCIECZKI = (SELECT r.ID_WYCIECZKI
                              FROM REZERWACJE r
                              WHERE r.NR_REZERWACJI = id_rezerwacji_i);
    END IF;
END;

BEGIN
  DODAJ_REZERWACJE_3(21, 28);
END;


-- punkt 9 -------------------------------------------------------------
CREATE OR REPLACE TRIGGER liczba_wolnych_miejsc_trigger_insert
  AFTER INSERT ON REZERWACJE
  FOR EACH ROW
  WHEN (NEW.STATUS IN ('N', 'P', 'Z'))
  BEGIN
      UPDATE WYCIECZKI w
      SET w.LICZBA_WOLNYCH_MIEJSC = w.LICZBA_WOLNYCH_MIEJSC - 1
      WHERE w.ID_WYCIECZKI = :NEW.ID_WYCIECZKI;
  END;


CREATE OR REPLACE TRIGGER liczba_wolnych_miejsc_trigger_update
  AFTER UPDATE OF STATUS ON REZERWACJE
  FOR EACH ROW
  WHEN (NEW.STATUS = 'N' AND OLD.STATUS <> 'N')               -- drugi nie powinien sie wydazyc
  BEGIN
    UPDATE WYCIECZKI w
    SET w.LICZBA_WOLNYCH_MIEJSC = w.LICZBA_WOLNYCH_MIEJSC + 1
    WHERE w.ID_WYCIECZKI = :NEW.ID_WYCIECZKI;
  END;

CREATE OR REPLACE TRIGGER liczba_wolnych_miejsc_trigger_wycieczki
  AFTER UPDATE OF LICZBA_MIEJSC ON WYCIECZKI
  FOR EACH ROW
  WHEN (NEW.LICZBA_MIEJSC <> OLD.LICZBA_MIEJSC)
  BEGIN
    UPDATE WYCIECZKI w
      SET w.LICZBA_WOLNYCH_MIEJSC = w.LICZBA_WOLNYCH_MIEJSC + (:NEW.LICZBA_MIEJSC - :OLD.LICZBA_MIEJSC)
    WHERE w.ID_WYCIECZKI = :NEW.ID_WYCIECZKI;
  END;


-- zmodyfikowane procedury
CREATE or REPLACE PROCEDURE dodaj_rezerwacje_4 (id_wycieczki_i in NUMBER, id_osoby_i in NUMBER)
AS
  id_w_exist NUMBER;
  id_o_exist NUMBER;
  czy_da_sie_dodac NUMBER;
  id_rezerwacji_r NUMBER;
  BEGIN
    IF id_wycieczki_i is NULL OR id_osoby_i is NULL THEN
      raise_application_error(-20001, 'Musisz podac argumenty');
    END IF;

    SELECT CASE
      WHEN exists(SELECT *
                  FROM dostepne_wycieczki_2 w
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

CREATE OR REPLACE PROCEDURE zmien_status_rezerwacji_4 (id_rezerwacji_i in NUMBER, status_i in CHAR)
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


CREATE OR REPLACE PROCEDURE zmien_liczbe_miejsc_4(id_wycieczki_i in NUMBER, liczba_miejsc_i in NUMBER)
  AS
    id_w_exists NUMBER;
    liczba_wolnych_miejsc_obecnie NUMBER;
    liczba_miejsc_obecnie NUMBER;
  BEGIN
    -- sprawdzanie czy id istnieje i czy w przyszlosci
    SELECT CASE
      WHEN exists(SELECT *
                  FROM WYCIECZKI w
                  WHERE w.ID_WYCIECZKI = id_wycieczki_i AND w.DATA > current_date)
        THEN 1
        ELSE 0
    END
      INTO id_w_exists
      FROM dual;

    IF id_w_exists = 0 THEN
      raise_application_error(-20000, 'Nie ma takiej wycieczki lub juz sie odbyla');
    END IF;

    -- zdobadz obecna liczbe miejsc i wolnych miejsc
    SELECT w.LICZBA_WOLNYCH_MIEJSC, w.LICZBA_MIEJSC
    INTO liczba_wolnych_miejsc_obecnie, liczba_miejsc_obecnie
    FROM WYCIECZKI w
    WHERE w.ID_WYCIECZKI = id_wycieczki_i;

    -- sprawdzamy czy nowa liczba miejsc jset poprawna
    IF (liczba_wolnych_miejsc_obecnie - (liczba_miejsc_obecnie - liczba_miejsc_i)) < 0 THEN
      raise_application_error(-20000, 'Nowa wartosc jest za mala');
    END IF;

    UPDATE WYCIECZKI w
    SET w.LICZBA_MIEJSC = liczba_miejsc_i
    WHERE w.ID_WYCIECZKI = id_wycieczki_i;

END;