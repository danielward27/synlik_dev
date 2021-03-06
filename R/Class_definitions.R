#####################################################################################################################

########################################## CLASS DEFINITIONS AND VALIDITY CHECKS ####################################

#####################################################################################################################

#' Dummy class
#' @description Class unions for internal use only
#' @name numericOrNULL-class
#' @rdname numericOrNULL-class
#' @exportClass numericOrNULL
setClassUnion("numericOrNULL", c("numeric", "NULL"))

#' Dummy class
#' @description Class unions for internal use only
#' @name ANYOrNULL-class
#' @rdname ANYOrNULL-class
#' @exportClass ANYOrNULL
setClassUnion("ANYOrNULL", c("ANY", "NULL"))

#' Dummy class
#' @description Class unions for internal use only
#' @name functionOrNULL-class
#' @rdname functionOrNULL-class
#' @exportClass functionOrNULL
setClassUnion("functionOrNULL", c("function", "NULL"))

#' Dummy class
#' @description Class unions for internal use only
#' @name numericORmatrix-class
#' @rdname numericORmatrix-class
#' @exportClass numericORmatrix
setClassUnion("numericORmatrix", c("numeric", "matrix"))

##################################
######### synlik: the base class
##################################

### Validity check

.check.synlik <- function(object)
{
  if(!is(object, "synlik")) stop("object has to be of class \"synlik\" ")
  
  errors <- character()
  
  if(length(object@param) == 0) errors <- c(errors, "length(param) == 0")
  if(is.null(names(object@param)) || any("" %in% names(object@param)) )
    errors <- c(errors, "param has to be a named vector")
  
  simulArgs <- names(as.list(args(object@simulator)))
  if( length(simulArgs) < 5 || !identical(simulArgs[1:3], c("param", "nsim", "extraArgs")) || simulArgs[length(simulArgs) - 1] != "...") 
    stop("The first 3 arguments of the simulator should be \"param\", \"nsim\" and \"extraArgs\" (in that order) and the last should be \"...\"")
  
  if( !is.null(object@summaries) )
  {
    statsArgs <- names(as.list(args(object@summaries)))
    if( length(statsArgs) < 4 || (statsArgs[1] != "x") || statsArgs[length(statsArgs) - 1] != "...") 
      stop("The first 2 argument of the \"summaries\" function should be \"x\" and \"extraArgs\" (in that order) and the last should be \"...\"")
  }
  
  if(length(errors) == 0) TRUE else errors
}


### Class Definition
#' \code{synlik-class}
#' 
#' @usage{synlik(...)}
#' @description{ Basic class for simulation-based approximate inference using Synthetic Likelihood methods.  }
#' 
#' \section{Slots}{
#' \describe{
#'    \item{param}{Named vector of parameters used by \code{object@@simulator} (\code{numeric}).}
#'    \item{simulator}{Function that simulates from the model (\code{function}). It has to have prototype \code{fun(param, nsim, extraArgs, ...)}. 
#'                     If \code{summaries()} is not specified the \code{simulator()} has output a matrix with \code{nsim} rows, where
#'                     each row is a vector of simulated statistics. Otherwise it can output any kind of object, and this output will be
#'                     passed to \code{summaries()}.}
#'    \item{summaries}{Function that transforms simulated data into summary statistics (\code{function}). 
#'                     It has to have prototype \code{fun(x, extraArgs, ...)} and it has to output a matrix with \code{nsim} rows, where
#'                     each row is a vector of simulated statistics. Parameter \code{x} contains the data.}
#'    \item{data}{Object containing the observed data or statistics (\code{ANY}).}
#'    \item{extraArgs}{List containing all the extra arguments to be passed to \code{object@@simulator} and \code{object@@summaries} (\code{list}).}
#'    \item{plotFun}{Function that will be used to plot \code{object@@data}. Prototype should be \code{fun(x, ...)} (\code{function}).}
#'  }
#'  
#' @name synlik-class
#' @rdname synlik-class
#' @references Simon N Wood. Statistical inference for noisy nonlinear ecological dynamic systems. Nature, 466(7310):1102--1104, 2010.
#' @author Matteo Fasiolo <matteo.fasiolo@@gmail.com>
#' @examples
#' #### Create Object
#' ricker_sl <- synlik(simulator = rickerSimul,
#'                     summaries = rickerStats,
#'                     param = c( logR = 3.8, logSigma = log(0.3), logPhi = log(10) ),
#'                     extraArgs = list("nObs" = 50, "nBurn" = 50),
#'                     plotFun = function(input, ...) 
#'                                 plot(drop(input), type = 'l', ylab = "Pop", xlab = "Time", ...)
#' )
#'  
#' # Simulate from the object
#' ricker_sl@@data <- simulate(ricker_sl)
#' ricker_sl@@extraArgs$obsData <- ricker_sl@@data # Needed by WOOD2010 statistics
#' 
#' plot(ricker_sl)      
#' @exportClass synlik
#'

setClass( "synlik",
          representation( param = "numeric",
                          simulator = "function",
                          summaries = "functionOrNULL",
                          data = "ANY",
                          extraArgs = "list",
                          plotFun = "functionOrNULL"
          ),
          prototype = prototype(
            param = numeric(),
            simulator = function() NULL,
            summaries = NULL,
            data = NULL, 
            extraArgs = list(),
            plotFun = NULL
          ),
          
          validity = .check.synlik
)

#' @param ... See section "Slots".
#' @rdname synlik-class
synlik <- function(...)
{
  # Expanding arguments and adding "synlik" class
  arg <- c("synlik", as.list(match.call(expand.dots = TRUE))[-1])
  
  do.call("new", arg)
}





##################################
######### smcmc: a synlik object after MCMC
##################################

### Validity check

.check.smcmc <- function(object)
{
  if(!is(object, "smcmc")) stop("object has to be of class \"smcmc\" ")
  
  if( !is.matrix(object@initPar) ) object@initPar <- t(object@initPar)
  
  errors <- character()
  
  if(length(object@initPar) == 0) errors <- c(errors, "length(initPar) should be > 0")
  
  if(length(errors) == 0) TRUE else errors
}


### Class Definition
#' \code{smcmc-class}
#' 
#' @description{ Object representing the results of MCMC estimation on an object of class \code{synlik}, from which it inherits.  }
#' 
#' \section{Slots}{
#' \describe{
#'    \item{initPar}{Vector of initial parameters where the MCMC chain will start (\code{numeric}).}
#'    \item{niter}{Number of MCMC iterations (\code{integer}).}
#'    \item{nsim}{Number of simulations from the simulator at each step of the MCMC algorithm (\code{integer}).}
#'    \item{burn}{Number of initial MCMC iterations that are discarded (\code{integer}).}
#'    \item{priorFun}{Function that takes a vector of parameters as input and the log-density of the prior
#'                    as output. If the output is not finite the proposed point will be discarded. (\code{function}).
#'                    The function needs to have signature \code{fun(x, ...)}, where \code{x} represents the input parameters (\code{function}).}
#'    \item{propCov}{Matrix representing the covariance matrix to be used to perturb the 
#'                   parameters at each step of the MCMC chain (\code{matrix}).}
#'    \item{targetRate}{Target rate for the adaptive MCMC sampler. Should be in (0, 1), default is NULL (no adaptation). The adaptation
#'                      uses the approach of Vihola (2011). (\code{numeric})}
#'    \item{recompute}{If TRUE the synthetic likelihood will be evaluated at the current and proposed positions in the parameter
#'                    space (thus doubling the computational effort). If FALSE the likelihood of the current
#'                    position won't be re-estimated (\code{logical}).}
#'    \item{multicore}{If TRUE the \code{object@@simulator} and \code{object@@summaries} functions will
#'                     be executed in parallel. That is the nsim simulations will be divided in multiple cores (\code{logical}).}
#'    \item{ncores}{Number of cores to use if multicore == TRUE (\code{integer}).}
#'    \item{accRate}{Acceptance rate of the MCMC chain, between 0 and 1 (\code{numeric}).}
#'    \item{chains}{Matrix of size niter by length(initPar) where the i-th row contains the position of the MCMC algorithm
#'                      in the parameter space at the i-th (\code{matrix}).}
#'    \item{llkChain}{Vector of niter elements where the i-th element is contains the estimate of the 
#'                       synthetic likelihood at the i-th iteration (\code{numeric}).}
#'    \item{control}{Control parameters used by the MCMC sampler: \itemize{
#'                   \item{\code{theta} = controls the speed of adaption. Should be between 0.5 and 1.
#'                                        A lower gamma leads to faster adaption.}
#'                   \item{\code{adaptStart} = iteration where the adaption starts. Default 0.}
#'                   \item{\code{adaptStop} = iteration where the adaption stops. Default \code{burn + niter}}
#'                   \item{\code{saveFile} = path to the file where the intermediate results will be stored (ex: "~/Res.RData").}
#'                   \item{\code{saveFreq} = frequency with which the intermediate results will be saved on \code{saveFile}.
#'                                           Default 100.}
#'                   \item{\code{verbose} = if \code{TRUE} intermediate posterior means will be printer.}
#'                   \item{\code{verbFreq} = frequency with which the intermediate posterior means will be printer. Default 500.}
#'                   \item{\code{initLoglik} = vector of length \code{ncores} giving the initial log-likelihood for each chain.
#'                                             Mainly for internal use by the \code{continue} generic.}
#'                   
#' } }
#'  }
#'  
#' @name smcmc-class
#' @rdname smcmc-class
#' @exportClass smcmc
#' @references Vihola, M. (2011) Robust adaptive Metropolis algorithm with coerced acceptance rate. 
#'             Statistics and Computing. 
#' @author Matteo Fasiolo <matteo.fasiolo@@gmail.com>
#' @examples
#' # Load "synlik" object
#' data(ricker_sl)
#'
#' plot(ricker_sl)
#'  
#' # MCMC estimation
#' set.seed(4235)
#' ricker_sl <- smcmc(ricker_sl, 
#'                    initPar = c(3.2, -1, 2.6),
#'                    niter = 50, 
#'                    burn = 3,
#'                    priorFun = function(input, ...) 1, 
#'                    propCov = diag( c(0.1, 0.1, 0.1) )^2, 
#'                    nsim = 200, 
#'                    multicore = FALSE)
#' 
#' # Continue with additional 50 iterations
#' ricker_sl <- continue(ricker_sl, niter = 50)
#' 
#' plot(ricker_sl)       
#'
setClass("smcmc",
         representation( initPar = "matrix",
                         niter = "integer",
                         nsim = "integer",
                         propCov = "matrix",
                         burn = "integer",
                         nchains = "integer",
                         priorFun = "function",
                         
                         targetRate = "numericOrNULL",
                         recompute = "logical",
                         multicore = "logical",
                         ncores = "integer",
                         control = "list",
                         
                         accRate = "numeric",
                         chains = "array",
                         llkChain = "matrix",
                         parStore = "array",
                         llkStore = "matrix"
         ),
         prototype = prototype(initPar = matrix( , 0, 0),
                               niter = 0L,
                               nsim = 0L, 
                               propCov = matrix( , 0, 0),
                               burn = 0L,
                               nchains = 1L,
                               priorFun = function(param, ...) 0,
                               
                               targetRate = NULL,
                               recompute = FALSE,
                               multicore = FALSE,
                               ncores = 1L,
                               control = list(),
                               
                               accRate = numeric(),
                               chains = matrix( , 0, 0),
                               llkChain = matrix( , 0, 0),
                               parStore = matrix( , 0, 0),
                               llkStore = matrix( , 0, 0)),
                               
         contains = "synlik",
         validity = .check.smcmc
)




##################################
######### synMaxlik: a synlik object after stochOptim
##################################

### Validity check

.check.synMaxlik <- function(object)
{
  if(!is(object, "synMaxlik")) stop("object has to be of class \"synMaxlik\" ")
  
  errors <- character()
  
  if(length(object@initPar) == 0) errors <- c(errors, "length(initPar) should be > 0")
  
  if(length(errors) == 0) TRUE else errors
}

### Class Definition
#' \code{synMaxlik-class}
#'
#' \describe{
#'    \item{initPar}{Vector of initial parameters from which the optimization starts (\code{numeric}).}
#'    \item{nIter}{Number of iterations of the optimization routine (\code{numeric}).}
#'    \item{nsim}{Number of simulations from the simulator at each step of the optimization routine (\code{numeric}).}
#'    \item{initCov}{Covariance matrix used to simulate the parameter at each step of the optimization routine (\code{matrix}).}
#'    \item{addRegr}{If FALSE the statistics calculated by \code{object@@summaries} will be used (SL approach). If TRUE the simulated 
#'                   parameters will be regressed on the statistics and the fitted values of the paramaters given the _observed_
#'                   statistics will be used as statistics (this is called SL+ approach) (\code{logical}).}
#'    \item{constr}{Named list of contraints on the parameters, it has 3 elements: 
#'                  [["indexes"]] = (numeric integers) indexes of the elements to check;
#'                  [["upper"]]  = (numeric) upper bounds for the elements in "indexes";
#'                  [["lower"]]  = (numeric) lower bounds for the elements in "indexes" (\code{list}).}
#'    \item{control}{Named list of control setting for the optimization routine (\code{list}).}
#'    \item{multicore}{If TRUE the \code{object@@simulator} and \code{object@@summaries} functions will
#'                     be executed in parallel. That is the nsim simulations will be divided in multiple cores (\code{logical}).}
#'    \item{ncores}{Number of cores to use if multicore == TRUE (\code{numeric}).}
#'    \item{resultPar}{Matrix typically nIter by length(initPar) where the i-th row contains the estimate of the 
#'                     parameters at the i-th iteration (\code{matrix}).}
#'    \item{resultGrad}{Matrix typically nIter by length(initPar) where the i-th row contains the estimate of the 
#'                     gradient of the synthetic likelihood at the i-th iteration (\code{matrix}).}
#'    \item{resultHess}{List of nIter elements where the i-th element is contains the estimate of the 
#'                     Hessian of the synthetic likelihood at the i-th iteration (\code{list}).}
#'    \item{resultCovar}{List of nIter elements where the i-th element is contains the estimate of the 
#'                     covariance matrix of the parameters at the i-th iteration (\code{list}).}
#'    \item{resultLoglik}{Vector of nIter elements where the i-th element is contains the estimate of the 
#'                         synthetic likelihood at the i-th iteration (\code{numeric}).}
#'  }
#' @name synMaxlik-class
#' @rdname synMaxlik-class
#' @author Matteo Fasiolo <matteo.fasiolo@@gmail.com>
#' @exportClass synMaxlik
.synMaxlik <-setClass("synMaxlik",
                      representation( initPar = "numeric",
                                      niter   = "integer",
                                      nsim    = "integer",
                                      initCov   = "matrix",
                                      addRegr  = "logical",
                                      constr = "list",
                                      control = "list",
                                      continueCtrl = "list",
                                      multicore = "logical",
                                      ncores = "integer",
                                      
                                      resultPar = "matrix",
                                      resultGrad = "matrix",
                                      resultHess  = "list",
                                      resultCovar = "list",
                                      resultLoglik = "numeric",
                                      
                                      storage = "list"
                      ),
                      prototype = prototype(initPar = numeric(),
                                            niter   = 0L,
                                            nsim    = 0L,
                                            initCov   = matrix( , 0, 0),
                                            addRegr  = TRUE,
                                            constr = list(),
                                            control = list(),
                                            continueCtrl = list(),
                                            multicore = FALSE,
                                            ncores = 1L,
                                            
                                            resultPar = matrix( , 0, 0),
                                            resultGrad = matrix( , 0, 0),
                                            resultHess = list(),
                                            resultCovar = list(),
                                            resultLoglik = numeric(),
                                            
                                            storage = list()
                      ),
                      contains = "synlik",
                      validity = .check.synMaxlik)




### Validity check

.check.sml <- function(object)
{
  if(!is(object, "sml")) stop("object has to be of class \"sml\" ")
  
  errors <- character()
  
  if(length(object@initPar) == 0) errors <- c(errors, "length(initPar) should be > 0")
  
  if(length(errors) == 0) TRUE else errors
}


### Class Definition
#' \code{sml-class}
#'
#' \describe{
#'    \item{initPar}{Vector of initial parameters from which the optimization starts (\code{numeric}).}
#'    \item{nIter}{Number of iterations of the optimization routine (\code{numeric}).}
#'    \item{nsim}{Number of simulations from the simulator at each step of the optimization routine (\code{numeric}).}
#'    \item{initCov}{Covariance matrix used to simulate the parameter at each step of the optimization routine (\code{matrix}).}
#'    \item{constr}{Named list of contraints on the parameters, it has 3 elements: 
#'                  [["indexes"]] = (numeric integers) indexes of the elements to check;
#'                  [["upper"]]  = (numeric) upper bounds for the elements in "indexes";
#'                  [["lower"]]  = (numeric) lower bounds for the elements in "indexes" (\code{list}).}
#'    \item{multicore}{If TRUE the \code{object@@simulator} and \code{object@@summaries} functions will
#'                     be executed in parallel. That is the nsim simulations will be divided in multiple cores (\code{logical}).}
#'    \item{ncores}{Number of cores to use if multicore == TRUE (\code{numeric}).}
#'    \item{estim}{Matrix typically nIter by length(initPar) where the i-th row contains the estimate of the 
#'                 parameters at the i-th iteration (\code{matrix}).}
#'    \item{simPar}{Matrix typically nIter * nP by length(initPar) where the i-th row contains the estimate of the 
#'                 parameters at the i-th iteration (\code{matrix}).}
#'    \item{resultHess}{List of nIter elements where the i-th element is contains the estimate of the 
#'                     Hessian of the synthetic likelihood at the i-th iteration (\code{list}).}
#'    \item{resultCovar}{List of nIter elements where the i-th element is contains the estimate of the 
#'                     covariance matrix of the parameters at the i-th iteration (\code{list}).}
#'    \item{resultLoglik}{Vector of nIter elements where the i-th element is contains the estimate of the 
#'                         synthetic likelihood at the i-th iteration (\code{numeric}).}
#'  }
#' @name sml-class
#' @rdname sml-class
#' @author Matteo Fasiolo <matteo.fasiolo@@gmail.com>
#' @exportClass sml
.sml <-setClass("sml",
                representation( initPar = "numeric",
                                initCov   = "matrix",
                                niter   = "integer",
                                nsim    = "integer",
                                np      = "integer",
                                priorFun = "functionOrNULL",
                                alpha = "numeric",
                                constr = "list",
                                temper = "numericOrNULL",
                                recycle = "logical",
                                multicore = "logical",
                                ncores = "integer",
                                
                                estim = "matrix",
                                simLogLik = "numeric",
                                simLogPrior = "numeric",
                                simPar  = "matrix"
                ),
                prototype = prototype(initPar = numeric(),
                                      initCov   = matrix( , 0, 0),
                                      niter   = 0L,
                                      nsim    = 0L,
                                      np      = 0L,
                                      priorFun = NULL,
                                      alpha = 0.95,
                                      constr = list(),
                                      temper = NULL,
                                      recycle = FALSE,
                                      multicore = FALSE,
                                      ncores = 1L,
                                      
                                      estim  = matrix( , 0, 0),
                                      simLogLik = numeric(),
                                      simLogPrior = numeric(),
                                      simPar = matrix( , 0, 0)
                                      
                ),
                contains = "synlik",
                validity = .check.sml)
