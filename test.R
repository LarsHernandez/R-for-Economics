
library(tidyverse)
library(statsDK)
library(gganimate)
library(zoo)

theme_set(theme_light())


data_A <- retrieve_data("FOLK1A", OMRÅDE = "000", CIVILSTAND="TOT")
data_B <- retrieve_data("FRDK118")

data_A$TID2 <- as.Date(as.yearqtr(data_A$TID, format = "%YQ%q"))
data_B$TID2 <- as.Date(as.yearqtr(data_B$TID, format = "%Y"))

data_A <- subset(data_A, data_A$KØN != "Total")
data_B <- subset(data_B, data_B$TID2 != "2018-01-01")

data_T <- rbind(data_A[,c(-1,-2)], data_B[,-1])

data_T$ALDER2 <- as.numeric(gsub("([0-9]+).*$", "\\1", data_T$ALDER))

data_T <- subset(data_T, data_T$ALDER != "Total")
data_T <- subset(data_T, format.Date(TID2, "%m") == "01")

data_T2 <- data_T %>% 
  group_by(KØN, ALDER, TID, ALDER2, TID2) %>% 
  summarize_all(funs(sum))

data_T2$TID3 <- as.integer(format(data_T2$TID2, "%Y"))

data_T3 <- data_T2 %>% 
  group_by(TID2) %>% 
  mutate(pop = sum(INDHOLD, na.rm=T))

data_T3$pop <- round(data_T3$pop, -3) 
data_T3$pop <- format(data_T3$pop, nsmall = 0, big.mark = ".")
data_T3$pop <- as.character(data_T3$pop)

data_ghost <- data_T3
data_ghost$aar <- data_ghost$TID3
data_ghost <- subset(data_ghost, data_ghost$aar == 2008)
data_ghost$TID3 <- NULL



p <- ggplot() + 
  geom_bar(data = subset(data_T3, data_T2$KØN == "Women"), 
           aes(ALDER2, INDHOLD, fill = KØN), 
           width = 1, stat = "identity", position = "dodge") +
  geom_bar(data = subset(data_T3, data_T2$KØN == "Men"),   
           aes(ALDER2, -INDHOLD, fill = KØN), 
           width = 1, stat = "identity", position = "dodge") +
  geom_bar(data = subset(data_ghost, data_ghost$KØN == "Women"), 
           aes(ALDER2, INDHOLD), 
           width = 1, stat = "identity", position = "dodge", 
           color = NA, fill = "#ffffff", alpha = 0.1) +
  geom_bar(data = subset(data_ghost, data_ghost$KØN == "Men"),
           aes(ALDER2, -INDHOLD), 
           width = 1, stat = "identity", position = "dodge", 
           color = NA, fill = "#ffffff", alpha = 0.1) +
  geom_rect(aes(xmin = 3.5, xmax = 16, ymin = -16400, ymax = 16300), 
            color="black", 
            fill = "black") +
  geom_text(data = data_T3, 
            aes(x = 10, y = 0, label = pop), 
            size = 14, color = "#f3f3f3") +
  coord_flip() +
  guides(fill = guide_legend(label.position = "bottom", title = NULL, label.vjust = 5)) + 
  scale_fill_manual(name = "",
                    breaks = c("Men", "Women"),
                    labels = c("Men", "Women"),
                    values = c("Men" = "#2171b5", "Women" = "#08306b")) +
  scale_x_continuous(limits = c(0, 120), 
                     breaks = round(seq(min(0), max(120), by = 10), 1)) +
  scale_y_continuous(limits = c(-51300, 48700), 
                     breaks = c(-45000, -30000, -15000, 0, 15000, 30000, 45000)) +
  labs(title = "How demographics are changing\nin Denmark between 2018 and 2060", 
       subtitle = "Year {frame_time}", 
       x = "Age", 
       caption = "Source: Danmarks Statistik\n") +
  transition_time(TID3) +
  ease_aes('linear') +
  theme(axis.title.x = element_blank(), 
        axis.title = element_text(size = 18),
        axis.text = element_text(size = 13),
        title = element_text(colour = "#404040", size = 32),
        plot.background = element_rect(fill = "#f3f3f3"),        
        plot.subtitle = element_text(color = "#666666", size = 19, margin = margin(t = 10, r = 0, b = 15, l = 0)),
        plot.caption = element_text(color = "#AAAAAA", size = 16),
        plot.margin = unit(c(2, 1.7, 0.6, 0.8), "cm"),
        panel.background = element_rect(fill = "#f3f3f3"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(size = 0.1, color = "#cccccc"),
        legend.key = element_rect(fill = "#f3f3f3", colour = "#f3f3f3"),
        legend.background = element_rect(fill = "#f3f3f3"),
        legend.text = element_text(size = 13),
        legend.key.width = unit(3, "cm"),
        legend.key.height = unit(0.5, "cm"),
        legend.position = "bottom")

animate(p, fps = 16, nframes = 212, width = 800, height = 800)
