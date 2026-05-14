#install.packages(c("dplyr", "factoextra", "cluster"))
#install.packages(c("sf", "ggplot2", "geodata"))
library(dplyr)
library(ggplot2)
library(sf)
library(geodata)

# Wczytanie i przygotowanie danych 
dane <- read.csv("dane.csv", sep=";", dec=",", colClasses = c("kod" = "character"))

# Ustawienie nazw wierszy na kod powiatów (będą widoczne na wykresach)
rownames(dane) <- dane$kod

# Wybór tylko kolumn numerycznych do obliczeń
dane_numeryczne <- dane %>% select(cena, obrót, wynagrodzenie, turystyka, migracja, bezrobocie, urbanizacja, struktura_ludności)

dane_numeryczne <- dane_numeryczne %>%
  mutate(across(where(is.character), ~ as.numeric(gsub(",", ".", gsub(" ", "", .)))))

# Usunięcie wierszy z brakami danych (NA)
dane_czyste <- na.omit(dane_numeryczne)

dane_do_klasteryzacji <- dane_czyste %>% select(-cena)

# Skalowanie (standaryzacja) danych
dane_skalowane <- scale(dane_do_klasteryzacji)

# Klasteryzacja Hierarchiczna (Metoda Warda)
# Obliczanie macierzy odległości
odleglosci <- dist(dane_skalowane, method = "euclidean")

# Tworzenie dendrogramu
drzewo_warda <- hclust(odleglosci, method = "ward.D2")

# Rysowanie dendrogramu z ramkami dla 5 klastrów
plot(drzewo_warda, cex = 0.5, main = "Dendrogram - Metoda Warda", xlab = "Powiaty")
rect.hclust(drzewo_warda, k = 5, border = 2:6) 

# Przypisanie klastrów i Profilowanie 
dane_czyste$Klaster <- as.factor(cutree(drzewo_warda, k = 5))

# Liczymy średnie wartości dla każdej ze zmiennych w rozbiciu na 5 klastrów
profile_klastrow <- aggregate(. ~ Klaster, data = dane_czyste, FUN = mean)

# Zaokrąglanie wyników
profile_klastrow <- profile_klastrow %>%
  mutate(
    # Te kolumny zaokrąglamy do całości (0 miejsc po przecinku):
    across(c(cena, turystyka, wynagrodzenie, migracja, obrót, bezrobocie, urbanizacja), ~ round(., 0)),
  )

# Wyświetlamy ostateczną tabelę z profilami dla metody Warda
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


# Lista z oryginalnymi danymi i przypisanymi klastrami
wyniki_klastrow <- list(data = dane_skalowane, cluster = as.numeric(dane_czyste$Klaster))

# Generowanie wykresu
wykres_fviz <- fviz_cluster(
  wyniki_klastrow,
  geom = "point",            
  ellipse.type = "norm",     
  palette = "Set1",          
  main = "Wizualizacja klastrów w przestrzeni 2D",
  ggtheme = theme_minimal() 
)

# Wyświetlenie i zapis
print(wykres_fviz)


# Przygotowanie Mapy 
mapa_polska <- gadm(country = "POL", level = 2, path = tempdir())
mapa_sf <- st_as_sf(mapa_polska)

# Przygotowanie danych do łączenia
dane_czyste$kod <- dane[rownames(dane_czyste), "kod"]

# Czyszczenie kodów (usuwamy ewentualne ukryte spacje i wymuszamy tekst)
mapa_sf$CC_2 <- trimws(as.character(mapa_sf$CC_2))
dane_czyste$kod <- trimws(as.character(dane_czyste$kod))

# Łączenie danych z mapą
mapa_klastry <- merge(mapa_sf, dane_czyste, by.x = "CC_2", by.y = "kod", all.x = TRUE)

# Plik przestrzenny
mapa_klastry <- st_as_sf(mapa_klastry)

# Rysowanie mapy (Metoda Warda)
mapa_wykres <- ggplot(data = mapa_klastry) +
  geom_sf(aes(fill = Klaster), color = "white", size = 0.1) + 
  scale_fill_brewer(palette = "Set1", na.value = "grey90") +  
  theme_void() + 
  labs(
    title = "Typologia polskich rynków nieruchomości",
    subtitle = "Analiza hierarchiczna (Metoda Warda, k=5)",
    fill = "Numer Klastra"
  ) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
    plot.subtitle = element_text(hjust = 0.5, size = 12)
  )
# Zapis pliku
ggsave("Mapa_Klastry_Ward.png", plot = mapa_wykres, width = 10, height = 10, dpi = 300)

# Sprawdzenie braków 
table(is.na(mapa_klastry$Klaster))
class(mapa_klastry)
dev.off()

