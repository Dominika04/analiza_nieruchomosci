# Analiza skupień lokalnych rynków nieruchomości w Polsce

## 📌 O projekcie
Projekt badawczy realizowany w ramach studiów na SGGW, mający na celu wielowymiarową typologię i segmentację powiatów oraz miast na prawach powiatu w Polsce. Analiza koncentruje się na wyodrębnieniu jednorodnych grup (klastrów) o podobnym poziomie rozwoju gospodarczego i demograficznego oraz ocenie, jak te czynniki wpływają na wycenę nieruchomości mieszkalnych.

Projekt jest szczególnie istotny w kontekście analityki bankowej i oceny ryzyka regionalnego, pokazując silną polaryzację polskiego rynku.

## 📊 Dane
* **Źródło:** Główny Urząd Statystyczny (Bank Danych Lokalnych).
* **Zakres czasowy:** Dane za rok 2024.
* **Jednostki:** Wszystkie powiaty ziemskie oraz miasta na prawach powiatu w Polsce.
* **Zmienne diagnostyczne (aktywne):** Wskaźnik urbanizacji, stopa bezrobocia, saldo migracji, przeciętne wynagrodzenie, baza noclegowa (turystyka), struktura ludności (obciążenie demograficzne), liczba sprzedanych lokali na 1000 mieszkańców.
* **Zmienna profilująca (pasywna):** Mediana cen za $1~m^2$ lokali mieszkalnych.

## 🛠 Technologie i Metodyka
### Stack technologiczny
* **Język:** R
* **Kluczowe pakiety:** `stats` (kmeans, hclust), `factoextra` (wizualizacja klastrów), `ggplot2` (histogramy), `corrplot` (macierze korelacji).

### Metody analityczne
1. **Preprocessing:** Czyszczenie danych, obsługa braków danych oraz standaryzacja zmiennych (z-score).
2. **Feature Selection:** Analiza współliniowości przy użyciu macierzy korelacji Pearsona (wyeliminowanie zmiennych nadmiarowych, np. powierzchni lokali).
3. **Uczenie nienadzorowane (Clustering):**
   * **Metoda Warda:** Hierarchiczne łączenie skupień minimalizujące przyrost sumy kwadratów błędów (ESS).
   * **Algorytm K-średnich:** Optymalizacja wariancji wewnątrzgrupowej dla $k=5$ oraz $k=8$.
4. **Redukcja wymiarowości:** Analiza Głównych Składowych (PCA) wykorzystana do wizualizacji wielowymiarowych klastrów na płaszczyźnie 2D.
5. **Profilowanie:** Interpretacja klastrów z wykorzystaniem zmiennej pasywnej (ceny).

## 📈 Kluczowe wnioski (Insights)
* **Silna polaryzacja:** Rynek nieruchomości w Polsce jest wyraźnie podzielony na dynamiczne metropolie, strefy suburbanizacji oraz obszary w zapaści demograficznej.
* **Efekt "Obwarzanka":** Zidentyfikowano dynamicznie rozwijające się powiaty podmiejskie (wysokie saldo migracji, najniższe bezrobocie), gdzie ceny są napędzane przez nowe inwestycje deweloperskie i popyt zamożniejszych rodzin.
* **Oderwanie cen od lokalnej gospodarki:** W enklawach turystycznych (nadmorskich i górskich) ceny nieruchomości są determinowane przez kapitał zewnętrzny i inwestycyjny (second homes), a nie przez lokalne zarobki mieszkańców.
* **Zapaść prowincji:** Regiony o wysokim bezrobociu i ujemnej migracji cechują się minimalną płynnością rynku i najniższymi cenami.
