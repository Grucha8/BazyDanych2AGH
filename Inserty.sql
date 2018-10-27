--wycieczki
INSERT INTO WYCIECZKI (NAZWA, KRAJ, DATA, OPIS, LICZBA_MIEJSC)
VALUES ('Zamek w Checinach', 'Polska', '2020-05-28', 'Zwiedzanie pieknego zamku w Checinach', 10);

-- osoby
INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Adam', 'Kowalski', '87654321', 'tel: 6623');
INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Jan', 'Nowak', '12345678', 'tel: 2312, dzwonić po 18.00');
INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Tomasz', 'Karkocha', '97052848521', 'email: karkochat@gmail.com');
INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Andrzej', 'Glowa', '74630192832', 'tel: 384935');
INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Mariusz', 'Golota', '23456123434', 'tel: 9845845');
INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Mariusz', 'Pudzianowski', '01212475631', 'email: pudzian@pudzian.pl');
INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Jaroslaw', 'Kaczynski', '09757763362', 'email: j.kaczynski@pis.pl');
INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Weronika', 'Herbert', '65847362082', 'tel: 956840942');
INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Joanna', 'Ibisz', '47539235212', 'tel: 49830234');
INSERT INTO osoby (imie, nazwisko, pesel, kontakt)
VALUES('Kinga', 'Golowicz', '54268363012', 'email: kinga.golowicz@wp.pl');

-- rezerwacje
INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (1,1,'N');
INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (2,2,'P');
INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (12, 29, 'N');
INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (12, 28, 'N');
INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (12, 26, 'Z');
INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (8, 21, 'A');
INSERT INTO rezerwacje(id_wycieczki, id_osoby, status)
VALUES (11, 22, 'Z');
INSERT INTO REZERWACJE(ID_WYCIECZKI, ID_OSOBY, STATUS)
VALUES (11, 28, 'N');

