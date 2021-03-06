% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/shrinkCoef.R
\name{shrinkCoef}
\alias{shrinkCoef}
\title{Get coefficients of ridge regression or lasso}
\usage{
shrinkCoef(object, nsim, mu, sigma, type = "ridge", constr = list(),
  multicore = FALSE, ncores = detectCores() - 1, cluster = NULL,
  verbose = TRUE, clean = TRUE, ...)
}
\arguments{
\item{object}{An object of class "synlik".}

\item{nsim}{Number of summary statistics to be simulated.}

\item{mu}{mean around which the parameters will be simulated.}

\item{sigma}{covariance matrix used to simulate the parameters.}

\item{...}{additional arguments to be passed to object@simulator and object@summaries.
In general I would avoid using it and including in object@extraArgs everything they need.}
}
\value{
A list where [["ridgeCoef"]] is a matrix where the i-th row contains the ridge-regression coefficient
        resulting from regressing the i-th parameter on the statistics; [["meanStats"]] is a vector containing
        the means of the simulated statistics; [["sdevStats"]] is a vector containing the standard deviations of the 
        simulated statistics; [["penalty"]] is a vector of optimal penalties from each ridge regression.
}
\description{
This function simulates parameters in an hypercube and uses these parameters sets
             to simulated statistics from the model. The simulated values of each parameter 
             are then ridge-regressed on the simulated statistic. The function finds the optimal
             penalty and return a set of regression coefficients.
}
\author{
Matteo Fasiolo <matteo.fasiolo@gmail.com>, re-using much code from \code{MASS::lm.ridge()}.
}

