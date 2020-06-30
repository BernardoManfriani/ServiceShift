%PARAMETRI IN INPUT

int: k; %Ore a settimana
int: h; %Ore al giorno
int: n; %Numero di infermieri
int: D; %Infermieri turno giornaliero
int: N; %Infermieri turno notturno

var int: a;
var int: b;

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
/*
output
      [" ORE PER TURNO"] ++
      ["\nINF "] ++
      ["\(i) "|i in INFERMIERI]++
      ["\n"] ++
      ["L  |"]++["\(orexturno[i,j]) " | i in INFERMIERI, j = 1]++["\n"] ++
      ["Ma |"]++["\(orexturno[i,j]) " | i in INFERMIERI, j = 2]++["\n"] ++ 
      ["Me |"]++["\(orexturno[i,j]) " | i in INFERMIERI, j = 3]++["\n"] ++ 
      ["G  |"]++["\(orexturno[i,j]) " | i in INFERMIERI, j = 4]++["\n"] ++ 
      ["V  |"]++["\(orexturno[i,j]) " | i in INFERMIERI, j = 5]++["\n"] ++ 
      ["S  |"]++["\(orexturno[i,j]) " | i in INFERMIERI, j = 6]++["\n"] ++
      ["D  |"]++["\(orexturno[i,j]) " | i in INFERMIERI, j = 7]++["\n\n"] ++
      [" ORE INIZIO TURNO"] ++
      ["\n"] ++
      ["L  |"]++[" \(oreinizio[i,j]) " | i in INFERMIERI, j = 1]++["\n"] ++
      ["Ma |"]++[" \(oreinizio[i,j]) " | i in INFERMIERI, j = 2]++["\n"] ++ 
      ["Me |"]++[" \(oreinizio[i,j]) " | i in INFERMIERI, j = 3]++["\n"] ++ 
      ["G  |"]++[" \(oreinizio[i,j]) " | i in INFERMIERI, j = 4]++["\n"] ++ 
      ["V  |"]++[" \(oreinizio[i,j]) " | i in INFERMIERI, j = 5]++["\n"] ++ 
      ["S  |"]++[" \(oreinizio[i,j]) " | i in INFERMIERI, j = 6]++["\n"] ++
      ["D  |"]++[" \(oreinizio[i,j]) " | i in INFERMIERI, j = 7]++["\n\n"] ++ 
      [" ORE FINE TURNO"] ++
      ["\n"] ++
      ["L  |"]++[" \(orefine[i,j]) " | i in INFERMIERI, j = 1]++["\n"] ++
      ["Ma |"]++[" \(orefine[i,j]) " | i in INFERMIERI, j = 2]++["\n"] ++ 
      ["Me |"]++[" \(orefine[i,j]) " | i in INFERMIERI, j = 3]++["\n"] ++ 
      ["G  |"]++[" \(orefine[i,j]) " | i in INFERMIERI, j = 4]++["\n"] ++ 
      ["V  |"]++[" \(orefine[i,j]) " | i in INFERMIERI, j = 5]++["\n"] ++ 
      ["S  |"]++[" \(orefine[i,j]) " | i in INFERMIERI, j = 6]++["\n"] ++
      ["D  |"]++[" \(orefine[i,j]) " | i in INFERMIERI, j = 7]++["\n\n"];
      /*++
      ["\nORE "] ++
      ["\(ORARI[i+1]) "|i in ORARI]++
      ["\n"] ++
      ["L  |"]++["\(infermierixora[i,j]) " | i in ORARI, j = 1]++["\n"] ++
      ["Ma |"]++["\(infermierixora[i,j]) " | i in ORARI, j = 2]++["\n"] ++ 
      ["Me |"]++["\(infermierixora[i,j]) " | i in ORARI, j = 3]++["\n"] ++ 
      ["G  |"]++["\(infermierixora[i,j]) " | i in ORARI, j = 4]++["\n"] ++ 
      ["V  |"]++["\(infermierixora[i,j]) " | i in ORARI, j = 5]++["\n"] ++ 
      ["S  |"]++["\(infermierixora[i,j]) " | i in ORARI, j = 6]++["\n"] ++
      ["D  |"]++["\(infermierixora[i,j]) " | i in ORARI, j = 7]++["\n"];
      
      
%
%constraint forall(j in 1..7)(count(i in INFERMIERI)(oreinizio[i,j] = 22) >= N);
                                   
                                   

%constraint forall(i in INFERMIERI,j in 1..7)(if ((oreinizio[i,j] != 22 /\ (orefine[i,j] - oreinizio[i,j]) > 0)) then a = oreinizio[i,j] /\ b = orefine[i,j] /\ forall(z in a..b )(infermierixora[z,j] = infermierixora[z,j] + 1 ) else true endif);

%In ogni momento del giorno (6:00 - 22:00) devono essere presenti in reparto almeno almeno D infermieri
%constraint forall(j in 1..7)(count(i in INFERMIERI)(oreinizio[i,j] = 6 /\ (orefine[i,j] - oreinizio[i,j]) > 0) >= D);

%constraint forall(i in INFERMIERI,j in 1..7)((oreinizio[i,j] != 22 /\ (orefine[i,j] - oreinizio[i,j]) > 0) -> a =  1);

%constraint forall(j in 1..7)(count(i in INFERMIERI)(oreinizio[i,j] = 6 + h /\ (orefine[i,j] - oreinizio[i,j]) > 0) = D);
/*
constraint forall(i in INFERMIERI, j in 1..7)(
  if (oreinizio[i,j] != 22 /\ orefine[i,j] != 6 /\ orexturno[i,j] >= 0) 
    then (infermierixora[oreinizio[i,j],j] = 1 /\ infermierixora[orefine[i,j] ,j] = 0) 
  else infermierixora[oreinizio[i,j],j] = 0 endif);

constraint forall(i in INFERMIERI, j in 1..7)(
  if (oreinizio[i,j] != 22 /\  orexturno[i,j] >= 0) 
    then (infermierixora[oreinizio[i,j],j] = 1 /\ infermierixora[orefine[i,j] ,j] = 1) 
  else infermierixora[oreinizio[i,j],j] = 0 endif);
*/
/*constraint forall(i in INFERMIERI, j in 1..7)(
  if (orexturno[i,j] > 0 ) then (count(z in INFERMIERI)(oreinizio[z,j] = oreinizio[i,j]) = infermierixora[oreinizio[i,j],j])
                                  /\ 
                                  count(z in INFERMIERI)(orefine[z,j] = orefine[i,j]) = infermierixora[orefine[i,j],j]
                                    else true endif);*/
                                    
                                    
                                    

%constraint forall(i in INFERMIERI,j in 1..7)((oreinizio[i,j] != 22 /\ (orefine[i,j] - oreinizio[i,j]) > 0) -> (forall(k in oreinizio[i,j]..orefine[i,j])(infermierixora[k,j] = infermierixora[k,j] + 1)));

%constraint forall(i in INFERMIERI,j in 1..7)((oreinizio[i,j] = 22 \/ (orefine[i,j] - oreinizio[i,j]) <= 0) -> (infermierixora[oreinizio[i,j],j] = 0));                                           

%constraint forall(i in INFERMIERI,j in 1..7)((oreinizio[i,j] != 22 /\ (orefine[i,j] - oreinizio[i,j]) > 0) -> (infermierixora[oreinizio[i,j],j] = 1));
         
      
%output["Calendario\n L  Ma Me G  V  S  D  L  Ma Me G  V  S  D  L  Ma Me G  V  S  D \n OREXTURNO\(OREXTURNO)\noreinizio\(oreinizio)\norefine  \(orefine)"];


/*
set of int: infermieri = 1..numInf;
array[infermieri,GIORNI] of var 1..numInf: calendario;
array[1..3,1..4] of var 1..5: M;
%array[GIORNI,inf] of int : oreSettimanali;

%constraint assert(forall(i in GIORNI, j in infermieri)(calendario[i,j] == 1),"errore: troppe ore in un giorno");


  %var 1..h: l;
  %var 1..h: m;
  %var 1..h: me;
  %var 1..h: g;
  %var 1..h: v;
  %var 1..h: s;
  %var 1..h: d;
  %constraint l+m+me+g+v+s+d >= k;

solve satisfy;

output["\(calendario) | \(M)"];