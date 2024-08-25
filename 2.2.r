Sys.setlocale("LC_CTYPE", "russian")
  
  path <- 'C:/Users/Downloads/IFX.csv'
  
  ifx <- read.csv(path, sep=';')
  
  url<-'https://iss.moex.com/iss/history/engines/stock/markets/index/boards/rtsi/securities/MCFTR.csv?start='
  
  dat <- data.frame()
  for (i in seq(0,10000,by=100)) {
    temp <- read.csv(paste0(url,i),skip=1,sep=';')
    if (nrow(temp)==0) break
    if (nrow(dat)==0) {dat <- temp} else {dat <- rbind(dat,temp)}
  }
  mcftr <- dat[c('TRADEDATE','CLOSE')]
  
  mcftr$TRADEDATE <- as.Date(mcftr$TRADEDATE)
  
  ifx$TRADEDATE <- as.Date(ifx$Дата,'%d.%m.%Y')
  
  ifx$CLOSE <- ifx$IFX.Cbonds
  
  ifx <- ifx[names(mcftr)]
  
  ifx$id <- 'IFX'
  
  mcftr$id <- 'MCFTR'
  
  dat <- rbind(ifx,mcftr)
  
  #install.packages('tidyr') 
  #install.packages('dplyr') 
  library(tidyr)
  library(dplyr)
  
  dat2 <- spread(dat,id,CLOSE)
  
  temp <- dat2 %>%                           
    fill(IFX) %>%                              
    fill(MCFTR) %>%                             
    mutate(year=as.numeric(format(TRADEDATE,'%Y'))) %>% 
    filter(!is.na(MCFTR)) %>%  
    mutate(rIFX = IFX/lag(IFX,1)-1, 
           rMCFTR = MCFTR/lag(MCFTR,1)-1) 

otvet = data.frame()

for (start in 2004:2023) {
   for (end in start:2023) {
   t <- temp %>%
   filter(year %in% start:end)
    rp<-c() # накопители 
    sp<-c()
          
    for (w1 in seq(0,1,by=0.01)) { # акции
            
    w2 <- 1-w1 #облигации
            
    r1 <- mean(t$rMCFTR) #средняя доходность
    r2 <- mean(t$rIFX)   
            
    rp <- c(rp,100*250*(w1*r1 + w2*r2)) #годовая доходность портфеля (250 рабочих дней в году)
            
    s1 <- sd(t$rMCFTR) #отклонение
    s2 <- sd(t$rIFX)   
    ro <- cor(t$rIFX,t$rMCFTR) #корреляция
            
    sp <- c(sp,sqrt(s1^2*w1^2 + s2^2*w2^2 + 2*s1*s2*w1*w2*ro)*sqrt(250)*100) #годовой риск
    }
    colfunc <- colorRampPalette(c('darkgreen','red'))
    plot(sp,rp,xlab='Risk',ylab='Return',
    col=colfunc(length(rp)),pch=19, ylim=c(0,20),xlim=c(0,40), main=paste0(start,'-',end))
    text(head(sp,1),head(rp,1),label='Bonds')
    text(tail(sp,1),tail(rp,1),label='Stocks')
    b <- data.frame(start=start, end=end, h = end-start+1, wBonds = 1 - seq(0,1,by=0.01), wStocks = seq(0,1,by=0.01),
    return = rp, risk = sp)
    if (nrow(otvet)==0) {otvet=b} else{otvet=rbind(otvet,b)}
  }
}
#zadacha 1------------------------------------------
zadaсha1 <- function(otvet, horizon, strategy) {
  if (strategy == 'Акции') {
    otvet <- otvet %>%
    filter(h %in% horizon) %>%
    filter(wStocks %in% 1)
    maxreturn <- otvet$return[which.max(otvet$return)]
    startperiod <- otvet$start[which.max(otvet$return)]
    endperiod <- otvet$end[which.max(otvet$return)]
  }
  if (strategy == 'Облигации') {
    otvet <- otvet %>%
    filter(h %in% horizon) %>%
    filter(wBonds %in% 1)
    maxreturn <- otvet$return[which.max(otvet$return)]
    startperiod <- otvet$start[which.max(otvet$return)]
    endperiod <- otvet$end[which.max(otvet$return)]
  }
  if (strategy == '60/40') {
    otvet <- otvet %>%
    filter(h %in% horizon) %>%
    filter(wStocks %in% 0.6)
    maxreturn <- otvet$return[which.max(otvet$return)]
    startperiod <- otvet$start[which.max(otvet$return)]
    endperiod <- otvet$end[which.max(otvet$return)]
  }
  return(finallyperiod = paste0(startperiod,'-', endperiod))
}
period1 <- zadaсha1(otvet, 3, '60/40')
period1

#zadacha2---------------------------
s <- (rp-8)/sp

zadaсha2 <- function(otvet, horizon, strategy) {
  if (strategy == 'Акции') {
    otvet2 <- otvet %>%
    filter(h %in% horizon) %>%
    filter(wStocks %in% 1)
    otvet2$s <- (otvet2$return-8)/otvet2$risk
    maxs <- otvet2$s[which.max(otvet2$s)]
    startperiod <- otvet2$start[which.max(otvet2$s)]
    endperiod <- otvet2$end[which.max(otvet2$s)]
  }
  if (strategy == 'Облигации') {
    otvet2 <- otvet %>%
    filter(h %in% horizon) %>%
    filter(wStocks %in% 0)
    otvet2$s <- (otvet2$return-8)/otvet2$risk
    maxs <- otvet2$s[which.max(otvet2$s)]
    startperiod <- otvet2$start[which.max(otvet2$s)]
    endperiod <- otvet2$end[which.max(otvet2$s)]
  }
  if (strategy == '60/40') {
    otvet2 <- otvet %>%
    filter(h %in% horizon) %>%
    filter(wStocks %in% 0.6)
    otvet2$s <- (otvet2$return-8)/otvet2$risk
    maxs <- otvet2$s[which.max(otvet2$s)]
    startperiod <- otvet2$start[which.max(otvet2$s)]
    endperiod <- otvet2$end[which.max(otvet2$s)]
  }
  return(finallyperiod = paste0(startperiod,'-', endperiod))
}
period2 <- zadaсha2(otvet, 5, 'Облигации')
period2

#zadacha3-------------------------
path1<- 'C:/Users/Downloads/xau.csv'

xau <- read.csv(path1, sep=';')

url<-'https://iss.moex.com/iss/history/engines/stock/markets/index/boards/rtsi/securities/MCFTR.csv?start='

dat <- data.frame()
for (i in seq(0,10000,by=100)) {
  temp <- read.csv(paste0(url,i),skip=1,sep=';')
  if (nrow(temp)==0) break
  if (nrow(dat)==0) {dat <- temp} else {dat <- rbind(dat,temp)}
}
mcftr <- dat[c('TRADEDATE','CLOSE')]

mcftr$TRADEDATE <- as.Date(mcftr$TRADEDATE)

xau$TRADEDATE <- as.Date(xau$Дата,'%d.%m.%Y')

xau$id <- 'XAU'

mcftr$id <- 'MCFTR'

library(dplyr)

xau <- xau[!is.na(xau$USD.RUB..FX.),]
xau <- xau[xau$USD.RUB..FX. != "",] #удаляем пропущенные значения

xau <- xau[!is.na(xau$XAU.USD..FX.),]
xau <- xau[xau$XAU.USD..FX. != "",]

zoloto <- xau %>%
  mutate(USD = as.numeric(gsub(" ", "", gsub(",", ".", XAU.USD..FX.))),
         RUB = as.numeric(gsub(",", ".", USD.RUB..FX.))) %>%
  mutate(CLOSE = as.numeric(USD*RUB)) #стоимость золота в рублях


zoloto <- zoloto[names(mcftr)]

dat <- rbind(zoloto,mcftr)

library(tidyr)

dat2 <- spread(dat,id,CLOSE)

temp <- dat2 %>%                           
  fill(XAU) %>%                              
  fill(MCFTR) %>%                             
  mutate(year=as.numeric(format(TRADEDATE,'%Y'))) %>% 
  filter(!is.na(MCFTR)) %>%
  filter(!is.na(XAU)) %>%
  mutate(rMCFTR = MCFTR/lag(MCFTR,1)-1, 
         rXAU = XAU/lag(XAU,1)-1)

otvet <- data.frame()

for (start in 2006:2023) {
  for (end in start:2023) {
    t <- temp %>%
      filter(year %in% start:end)
    rp<-c() # nakopiteli
    sp<-c()
    
    for (w1 in seq(0,1,by=0.01)) { # акции
      
      w2 <- 1-w1 # bonds
      
      r1 <- mean(t$rMCFTR)
      r2 <- mean(t$rXAU)   
      
      rp <- c(rp,100*250*(w1*r1 + w2*r2))  
      
      s1 <- sd(t$rMCFTR) 
      s2 <- sd(t$rXAU)   
      ro <- cor(t$rXAU,t$rMCFTR) 
      
      sp <- c(sp,sqrt(s1^2*w1^2 + s2^2*w2^2 + 2*s1*s2*w1*w2*ro)*sqrt(250)*100) 
    }
    colfunc <- colorRampPalette(c('darkgreen','red'))
    plot(sp,rp,xlab='Risk',ylab='Return',
         col=colfunc(length(rp)),pch=19, ylim=c(0,20),xlim=c(0,40), main=paste0(start,'-',end))
    text(head(sp,1),head(rp,1),label='Gold')
    text(tail(sp,1),tail(rp,1),label='Stocks')
    b <- data.frame(start=start, end=end, h = end-start+1, wGold = 1 - seq(0,1,by=0.01), wStocks = seq(0,1,by=0.01),
                    return = rp, risk = sp)
    if (nrow(otvet)==0) {otvet=b} else{otvet=rbind(otvet,b)}
  }
}


zadaсha3 <- function(otvet, horizon, strategy) {
  if (strategy == 'Акции') {
    otvet <- otvet %>%
      filter(h %in% horizon) %>%
      filter(wStocks %in% 1)
    maxreturn <- otvet$return[which.max(otvet$return)]
    startperiod <- otvet$start[which.max(otvet$return)]
    endperiod <- otvet$end[which.max(otvet$return)]
  }
  if (strategy == 'Золото') {
    otvet <- otvet %>%
      filter(h %in% horizon) %>%
      filter(wGold %in% 1)
    maxreturn <- otvet$return[which.max(otvet$return)]
    startperiod <- otvet$start[which.max(otvet$return)]
    endperiod <- otvet$end[which.max(otvet$return)]
  }
  if (strategy == '60/40') {
    otvet <- otvet %>%
      filter(h %in% horizon) %>%
      filter(wStocks %in% 0.6)
    maxreturn <- otvet$return[which.max(otvet$return)]
    startperiod <- otvet$start[which.max(otvet$return)]
    endperiod <- otvet$end[which.max(otvet$return)]
  }
  return(finallyperiod = paste0(startperiod,'-', endperiod))
}
period3 <- zadaсha3(otvet, 5, 'Золото')
period3
         
