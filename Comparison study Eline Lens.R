start_time <- Sys.time()
#nsim : number of replications
#nperm: number of permutations
#rho: correlation between pre and post
#distribution: which distribution to use
#how big the meanDifferences should be
permu <- function(nsim, nperm, rho, n, distribution, meanDiff = 0) {
  n1 <- n + 1
  n2 <- 2 * n
  tcrit <- qt(0.95, n - 1)
  PSUB <- BOV <- BM1 <- BM2 <- BD <- BW1 <- BW2 <- BW3 <- c()
  #-------------------Generate Permutation Matrices------------------------------#
  P1 <- P2 <- B1 <- B2 <- matrix(0, nrow = n2, ncol = nperm)
  B3 <- matrix(0, nrow = n, ncol = nperm)
  for (h in 1:nperm) {
    P1[, h] <- sample(1:n2)
    P2[, h] <- c(t(apply(matrix(1:n2, ncol = 2), 1, sample)))
    B1[, h] <- sample(1:n2, replace = TRUE)
    B2[, h] <- c(apply(matrix(1:n2, ncol = 2), 2, sample, replace = TRUE))
    B3[, h] <- sample(1:n, replace = TRUE)
  }
  W1 <- matrix(rbinom(n * nperm, 1, 0.5), ncol = nperm)
  dd1 <- (W1 == 0)
  W1[dd1] <- -1
  W2 <- matrix(rbinom(n * nperm, 1, (sqrt(5) - 1) / (2 * sqrt(5))), ncol = nperm)
  dd21 <- (W2 == 1)
  dd22 <- (W2 == 0)
  W2[dd21] <- (1 + sqrt(5)) / 2
  W2[dd22] <- (1 - sqrt(5)) / 2
  W3 <- matrix(rnorm(n * nperm), ncol = nperm)
  #-----------------------Data Generation------------------------------#
  tpp <- numeric(nsim)
  x <- matrix(0, ncol = nsim, nrow = n2)
  for (h in 1:nsim) {
    x11 <- rnorm(n)
    x22 <- rho * x11 + sqrt(1 - rho^2) * rnorm(n)
    if (distribution == "Normal") {
      x[, h] <- c(x11, x22)
    }
    if (distribution == "Exp") {
      x[, h] <- c(qexp(pnorm(x11)), qexp(pnorm(x22)))
    }
    if (distribution == "LNorm") {
      x[, h] <- c(qlnorm(pnorm(x11)), qlnorm(pnorm(x22)))
    }
    if (distribution == "Gamma") {
      x[, h] <- c(qgamma(pnorm(x11),shape = 2), qgamma(pnorm(x22),shape = 2)) #transform to gamma
    }
    
    #adds mean difference
    x[1:n,h] <- x[1:n,h] + meanDiff
    
    ##adds t-test
    tpp[h] <- t.test(x[1:n,h],x[n1:n2,h], paired = TRUE)$p.value < 0.05
  }
  x1 <- x[1:n, ]
  x2 <- x[n1:n2, ]
  #--------Compute Means and Variances------------------------------------#
  diffs <- x1 - x2
  mdiff <- colMeans(diffs)
  vdiff <- (colSums(diffs^2) - n * mdiff^2) / (n - 1)
  Tpar <- sqrt(n) * (mdiff) / sqrt(vdiff)
  NaT <- is.na(Tpar)
  Tpar[NaT] <- 5000
  #--------------Start of Simulation Loop----------------------------------#
  for (s in 1:nsim) {
    xx <- x[, s]
    #-----------------------Permutation per Subject--------------------------------#
    xP2 <- matrix(xx[P2], ncol = nperm)
    xP21 <- xP2[1:n, ]
    xP22 <- xP2[n1:n2, ]
    DP2 <- xP21 - xP22
    mDP2 <- colMeans(DP2)
    vDP2 <- (colSums(DP2^2) - n * mDP2^2) / (n - 1)
    TP2 <- sqrt(n) * mDP2 / sqrt(vDP2)
    NAP2 <- is.na(TP2)
    TP2[NAP2] <- 5000
    PSUB1 <- 2*min(c(mean(Tpar[s] <= TP2),mean(Tpar[s] >= TP2)))
    PSUB[s] <- (PSUB1 < 0.05)
  }
  result <- data.frame(
    Distribution = distribution,
    rho = rho,
    tTest = mean(tpp),
    PSUB = mean(PSUB))
  return(result)
}
sample_size <- c(7, 10, 75, 135, 200)
distribution <- c("Normal","LNorm", "Gamma", "Exp")
rho <- c(0.3,0.5,0.9)
meanDiff <- c(0.0, 0.5) #0 for type I error rate, 1 for power (for power any value unequal 1 works and corresponds to different magnitude of differences)
Design <- expand.grid(samp=sample_size,dist=distribution,rho=rho,meanDiff=meanDiff)
n_permutations <- 1000 # 10^4 in your original paper
n_simulations <- 1000 # 10^4 in your original paper
prop_reject_Eline <- numeric(nrow(Design)) # 
prop_reject_t_test <- numeric(nrow(Design)) # 
for (i in 1:nrow(Design)){
  tmp <- permu(n_simulations, n_permutations, Design$rho[i], Design$samp[i], distribution = Design$dist[i], meanDiff = Design$meanDiff[i])
  prop_reject_t_test[i] <- tmp[['tTest']]
  prop_reject_Eline[i] <- tmp[['PSUB']]
}
results_Eline <- cbind(Design,prop_reject_Eline,prop_reject_t_test)
end_time <- Sys.time()
time_taken<-- c(end_time - start_time)
