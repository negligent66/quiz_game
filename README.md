# Infinite Quiz

un quiz che va all'infinito, con un punteggio di sessione.  

## Descrizione  

Infinite Quiz è un'app mobile sviluppata con Flutter che permette all’utente di giocare a un quiz a con un flusso di domande infinito.  

Le domande vengono caricate in tempo reale dal servizio pubblico OpenTriviaDB e il punteggio della sessione viene visualizzato nella scheda Sessione.  

## Architettura  

---GameSession---: Stato globale della sessione  
QuizPage:	Logica principale del gioco  
ScorePage:	Visualizzazione delle statistiche  
OpenTriviaDB API:	Servizio che fornisce domande a scelta multipla  

## 
