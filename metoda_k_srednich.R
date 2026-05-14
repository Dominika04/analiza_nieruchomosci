#install.packages(c("dplyr", "factoextra", "cluster"))
#install.packages(c("sf", "ggplot2", "geodata"))
library(dplyr)
library(factoextra)
library(cluster)
library(sf) 
library(ggplot2)
library(geodata)

# Wczytanie i przygotowanie danych
dane <- read.csv("dane.csv", sep=";", dec=",", colClasses = c("kod" = "character"))

# Ustawienie nazw wierszy na kod powiatów
rownames(dane) <- dane$kod

# Wybór tylko kolumn numerycznych do obliczeń
dane_numeryczne <- dane %>% select(cena, obrót, wynagrodzenie, turystyka, migracja, bezrobocie, urbanizacja, struktura_ludności)

# Standaryzacja i czyszczenie
dane_numeryczne <- dane_numeryczne %>%
  mutate(across(where(is.character), ~ as.numeric(gsub(",", ".", gsub(" ", "", .)))))

# Usunięcie wierszy z brakami danych (NA)
dane_czyste <- na.omit(dane_numeryczne)

# >>> GŁÓWNA ZMIANA: Tworzymy nowy obiekt bez kolumny 'cena' do klastrowania
zmienne_do_klastrowania <- dane_czyste %>% select(-cena)

# Skalowanie danych
dane_skalowane <- scale(zmienne_do_klastrowania)

# Klasteryzacja K-średnich
# Ustawienie ziarna losowości, żeby wyniki podziału były zawsze powtarzalne
set.seed(123) 

# Docelowa analiza k-średnich na 8 klastrów
wynik_kmeans <- kmeans(dane_skalowane, centers = 5, nstart = 25)

# Wizualizacja klastrów na płaszczyźnie 2D (PCA)
fviz_cluster(wynik_kmeans, data = dane_skalowane,
             geom = "point",
             ellipse.type = "convex",
             ggtheme = theme_minimal(),
             main = "Podział powiatów na klastry (Algorytm K-średnich, k=5)")

# Doklejamy numery klastrów do oryginalnych, NIESKALOWANYCH danych
dane_czyste$Klaster <- as.factor(wynik_kmeans$cluster)

# Liczymy średnie wartości dla każdej ze zmiennych w rozbiciu na 8 klastrów
profile_klastrow <- aggregate(. ~ Klaster, data = dane_czyste, FUN = mean)

# Wyświetlamy ostateczną tabelę z profilami dla K-średnich
print("Profile klastrów dla algorytmu K-średnich (k=5):")
print(profile_klastrow)


profile_klastrow_gt <- profile_klastrow %>%
  rename(
    Cena = cena,
    Obrót = obrót,
    Wynagrodzenie = wynagrodzenie,
    Turystyka = turystyka,
    Migracja = migracja, 
    Bezrobocie = bezrobocie,
    Urbanizacja = urbanizacja,
    `Struktura ludności` = struktura_ludności
  ) %>%
  mutate(across(where(is.numeric), ~ round(., 0)))

# Stworzenie i formatowanie tabeli gt
# Przypisujemy całą tabelę do obiektu 'tabela_gt', żeby móc ją później zapisać
tabela_gt <- profile_klastrow_gt %>%
  gt() %>%
  tab_header(
    title = "Profile klastrów rynku nieruchomości",
    subtitle = "Średnie wartości cech diagnostycznych i zmiennej profilującej w podziale na grupy"
  ) %>%
  opt_align_table_header(align = "left") %>%
  # Wyśrodkowanie kolumn z liczbami dla lepszej czytelności:
  cols_align(
    align = "center",
    columns = c(Cena, Obrót, Wynagrodzenie, Turystyka, Migracja, Bezrobocie, Urbanizacja, 'Struktura ludności')
  ) %>%
  tab_options(
    heading.title.font.weight = "bold",
    table.border.top.color = "black",
    table.border.bottom.color = "black",
    table_body.hlines.color = "gray90"
  )

# Wyświetl tabelę
tabela_gt



# Przygotowanie Mapy
mapa_polska <- gadm(country = "POL", level = 2, path = tempdir())
mapa_sf <- st_as_sf(mapa_polska)

# Przygotowanie danych do łączenia
dane_czyste$kod <- dane[rownames(dane_czyste), "kod"]

# Czyszczenie kodów (usuwamy spacje)
mapa_sf$CC_2 <- trimws(as.character(mapa_sf$CC_2))
dane_czyste$kod <- trimws(as.character(dane_czyste$kod))

# Łączenie mapy z danymi o klastrach
mapa_klastry <- merge(mapa_sf, dane_czyste, by.x = "CC_2", by.y = "kod", all.x = TRUE)

# plik przestrzenny
mapa_klastry <- st_as_sf(mapa_klastry)

# Rysowanie i zapis Mapy
mapa_wykres <- ggplot(data = mapa_klastry) +
  geom_sf(aes(fill = Klaster), color = "white", size = 0.1) + 
  scale_fill_brewer(palette = "Set1", na.value = "grey90") +  
  theme_void() + 
  labs(
    title = "Typologia polskich rynków nieruchomości",
    subtitle = "Analiza niehierarchiczna (K-średnich, k=5)",
    fill = "Numer Klastra"
  ) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
    plot.subtitle = element_text(hjust = 0.5, size = 12)
  )

# Zapis mapy do pliku
ggsave("Mapa_Klastry_Kmeans.png", plot = mapa_wykres, width = 10, height = 10, dpi = 300)

