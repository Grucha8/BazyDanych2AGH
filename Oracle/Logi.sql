CREATE TABLE rezerwacje_log
(
  id int GENERATED ALWAYS AS IDENTITY,
  id_rezerwacji INT,
  data DATE,
  status CHAR(1)
)

