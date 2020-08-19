%PARAMETRI IN INPUT

int: k; %Ore a settimana
int: h; %Ore al giorno
int: n; %Numero di infermieri
int: D; %Infermieri turno giornaliero
int: N; %Infermieri turno notturno

set of int: ORARI = 0..23; 
set of int: ORARIGIORNO = 6..22;
set of int: ORARINOTTE = {0,1,2,3,4,5,6,22,23};
set of int: INFERMIERI = 1..n;
set of int: TURNI = 1..7;

% VARIABILI DECISIONALI 

array[INFERMIERI,1..7] of var int: orexturno; %Mantiene le ore giornaliere di ogni infermiere
array[INFERMIERI,1..7] of var int: oreinizio; %Indica l'inizio di ogni turno per ogni infermiere
array[INFERMIERI,1..7] of var int: orefine; %Indica la fine di ogni turno per ogni infermiere
array[ORARIGIORNO,1..7] of var int: infermierixora; %Mantiene il numero di infermieri presenti ogni ora

    
%La somma delle ore settimanali deve essere k;
constraint forall(i in INFERMIERI)(sum(j in 1..7)(orexturno[i,j]) >= k);

%Ore per turno devono essere positive, minori di h a meno che non sia in orari notturni (=8);
constraint forall(i in INFERMIERI, j in 1..7)(
  (oreinizio[i,j] in ORARI /\ orefine[i,j] in ORARI)  %L'ora di inizio e di fine devono essere contenuto delle ore di un giorno (0..23)
  /\ 
  ((orexturno[i,j] >= 0) %Ore per turno devono essere positive
  /\ 
  (orexturno[i,j] <= h \/ (oreinizio[i,j] = 22 /\ orefine[i,j] = 6 /\ orexturno[i,j] = 8))) %Ore per turno devono essere minori di h a meno che non sia in orari notturni (=8);                                                                  
  /\
  ((oreinizio[i,j] in ORARIGIORNO /\ orefine[i,j]  in ORARIGIORNO) \/ (oreinizio[i,j] = 22 /\ orefine[i,j] = 6)) %Se l'inizio è durante il giorno anche la fine deve esserlo. altrimenti si ha un turno notturno, l' inizio è alle 22 e la fine è alle 6 
  /\
  ((if oreinizio[i,j] = 22 then orexturno[i,j] = 8 /\ orefine[i,j] = 6 else true endif) %Se l'orario è notturno allora le ore del turno devono essere 8,
  /\ 
  (if oreinizio[i,j] != 22 then (orefine[i,j] - oreinizio[i,j] = orexturno[i,j]) else true endif)) %Se l'roario è diurno, le ore del turno sono date dalla differenza dell'ora di fine turno e dell'ora di inizio turno 
  /\
  ((if oreinizio[i,j] = 22 then ((j = 6 -> orexturno[i,j+1] = 0) /\ (j < 6 -> orexturno[i,j+1] = 0 /\ orexturno[i,j+2] = 0)) else true endif))
  /\
  (if orexturno[i,j] = 0 then (oreinizio[i,j] = 6 /\ orefine[i,j] = 6) else true endif) ); %Chi ha il giorno di riposo, per convenzione, inizia e finisce il turno alle 6.

                                                                                     
                                              

constraint forall(i in INFERMIERI) %Ogni infermiere deve effettuare almeno un turno di 8 ore notturne a settimana
    (count(j in 1..7)
        (oreinizio[i,j] = 22 /\ orefine[i,j] = 6 ) >= 1);

                                    
constraint forall(i in ORARIGIORNO, j in 1..7) %Riempimento matrice di conteggio infermieri per ogni ora del giorno
  (infermierixora[i,j] = count(z in INFERMIERI)((orexturno[z,j] > 0 ) 
  /\ 
  (oreinizio[z,j] = i \/ (oreinizio[z,j] < i /\ (orefine[z,j]) > i))));
  
%In ogni momento del giorno (6:00 - 22:00) devono essere presenti in reparto almeno almeno D infermieri
constraint forall(i in ORARIGIORNO where i != 22, j in 1..7 )
  (infermierixora[i,j] >= D);
  

%In ogni momento della notte (22:00-6:00) devono essere presenti in reparto almeno N infermieri.
constraint forall(j in 1..7)(infermierixora[22,j] >= N);

solve satisfy;


output ["  ORE PER TURNO"] ++["\n\n"] ++
       [ show_int(3,i) ++ " " 
       | i in 1..7]++["\n\n"] ++
       [ show_int(3,orexturno[i,j]) ++ 
         if  j==7 then "     \(i)\n" else " " endif |
         i in INFERMIERI, j in 1..7] ++ ["\n\n"] ++
         ["  ORE INIZIO TURNO"] ++["\n\n"] ++
       [  show_int(3,i) ++ " " 
       | i in 1..7]++["\n\n"] ++
       [show_int(3,oreinizio[i,j]) ++ 
         if j==7 then "     \(i)\n" else " " endif |
         i in INFERMIERI, j in 1..7] ++ ["\n\n"] ++
         ["  ORE FINE TURNO"] ++["\n\n"] ++
       [   show_int(3,i) ++ " " 
       | i in 1..7]++["\n\n"] ++
       [ show_int(3,orefine[i,j]) ++ 
         if j == 7 then "     \(i)\n" else " " endif |
         i in INFERMIERI, j in 1..7] ++ ["\n\n"] ++
         [" INFERMIERI PER ORA"] ++["\n\n"] ++
       [   show_int(3,i) ++ " " 
       | i in 1..7]++["\n\n"] ++
       [ show_int(3,infermierixora[i,j]) ++
         if j = 7 then "     \(i)\n" else " " endif |
         i in ORARIGIORNO , j in 1..7] ++ ["\n\n"];  