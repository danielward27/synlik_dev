########
#' Extract estimates from \code{smcmc} objects
#'
#' @param object  ("smcmc") object.
#' @param method  if set to "bayes" then the output will be the empirical covariance matrix
#'                of the chain(s). In set to "mle" then a quadratic model will be fitted
#'                through the likelihood evaluations and the output covariance will be the 
#'                inverse of the negative Hessian.  
#' @param nreps   (integer) number of simulations used to tilt the negative Hessian (-H)
#'                toward positive definiteness (PD). Used only if the -H is not PD and \code{method == "asym"}.
#' @param boot    (logical) relevant only if -H is not PD. 
#'                If TRUE hessians will be simulated by resampling parameters and likelihoods. 
#'                If FALSE hessians will be simulated the asymptotic distribution of the regression
#'                coefficients.
#' @author Matteo Fasiolo <matteo.fasiolo@@gmail.com>
#' @method coef smcmc
#' @export
#' 

coef.smcmc <- function(object, method = "bayes", nreps = 1000, boot = TRUE, quant = 0.9, ...)
{ 
  # Including only parameters that were estimated
  varPar <- diag(object@propCov) > 0
  
  mcmcObj <- list("initPar" = object@initPar,
                  "propCov" = object@propCov, 
                  "chains"  = object@chains,
                  "llkStore" = object@llkStore,
                  "parStore" = object@parStore)
  
  parEstim <- coef.mcmc(object = mcmcObj,
                        method = method,
                        nreps = nreps, 
                        boot = boot, 
                        quant = quant,
                        ...)
  
  return(parEstim) 
}

setMethod("coef",
          signature = signature(object = "smcmc"),
          definition = coef.smcmc
)