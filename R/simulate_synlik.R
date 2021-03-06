.simulate.synlik  <- function(object,
                              nsim, 
                              seed = NULL,
                              param = object@param, 
                              stats = FALSE,
                              clean = TRUE,
                              multicore = !is.null(cluster),
                              cluster = NULL,
                              ncores = detectCores() - 1,
                              verbose = TRUE,
                              ...)
{
  if(!is(object, "synlik")) stop("object has to be of class \"synlik\" ")
  
  # Reduce the object to "synlik" so that I avoid moving around all the additional slots of the "synMaxlik" class
  if( !class(object)[[1]] != "synlik" ) object <- as(object, "synlik")
  
  if(is.null(seed) == FALSE) set.seed(seed)
  
  # I copy these function so I can mtrace() them
  simulator <- object@simulator
  summaries <- object@summaries
  extraArgs <- object@extraArgs
  
  if( multicore ){ 
    # Force evaluation of everything in the environment, so it will available to singleChain on cluster
    .forceEval(ALL = TRUE)
    
    tmp <- .clusterSetUp(cluster = cluster, ncores = ncores, libraries = "synlik", exportALL = TRUE)
    cluster <- tmp$cluster
    ncores <- tmp$ncores
    clusterCreated <- tmp$clusterCreated
    registerDoSNOW(cluster)
  }
  
  # Divide simulations between nodes
  coresSchedule <- if(multicore) c( rep(floor(nsim / ncores), ncores - 1), floor(nsim / ncores) + nsim %% ncores) else nsim
  
  # Launch simulations
  withCallingHandlers({
    tmp <- alply(.data = coresSchedule,
                 .margins = 1,
                 .fun = function(input, ...){
                   # Simulate data
                   simul <- simulator(param = param, nsim = input, extraArgs = extraArgs, ...)
                   
                   # Transform into summary statistics
                   if( stats == TRUE ) {
                     
                     if(!is.null(summaries) ) simul <- summaries(x = simul, extraArgs = extraArgs, ...)
                     
                   }
                   return( simul )
                 },
                 .parallel = multicore,
                 ...
    )
  }, warning = function(w) {
    # There is a bug in plyr concerning a useless warning about "..."
    if (length(grep("... may be used in an incorrect context", conditionMessage(w))))
      invokeRestart("muffleWarning")
  })
  
  # Close the cluster if it was opened inside this function
  if(multicore && clusterCreated) stopCluster(cluster)
  
  # We can't call rbind if we are simulating row data, as we don't know it's form (matrix, list, ect)
  if( length(coresSchedule) == 1 )
  {
    simul <- tmp[[1]]
  } else {
    if( stats ) simul <- do.call("rbind", tmp)
  }
  
  # Cleaning the stats from NANs
  if( clean ) simul <- .clean(X = simul, verbose = verbose)$cleanX
  
  return( simul )
}


##########
#' Simulate data or statistics from an object of class \code{synlik}. 
#' 
#' @param object An object of class \code{synlik}.
#' @param nsim   Number of simulations from the model.
#' @param seed   Random seed to be used. It is not passed to the simulator, but simply passed to \code{set.seed()} from within
#'               \code{simulate.synlik}.
#' @param param  Vector of parameters passed to \code{object@@simulator}.
#' @param stats If \code{TRUE} the function trasforms the simulated data into statistics using \code{object@@summaries}.
#' @param clean  If \code{TRUE} the function tries to clean the statistics from NaNs or non-finite values.
#'               Given that \code{object@@summaries} has to returns a numeric vector or 
#'               a matrix where each row is a simulation, rows containing non-finite values will be discarded.
#' @param verbose If \code{TRUE} the function will complain if, for instance, the simulations contain lots of non-finite values.
#' @param ... additional arguments to be passed to \code{object@@simulator} and \code{object@@summaries}.
#'            In general I would avoid using it and including \code{object@@extraArgs} everything they need.
#' @return If \code{stats == FALSE} the output will that of \code{object@@simulator}, which depends on the simulator used by the user.
#'         If \code{stats == TRUE} the output will be a matrix where each row is vector of simulated summary statistics.
#' @author Matteo Fasiolo <matteo.fasiolo@@gmail.com> 
#' @aliases simulate,synlik-method
#' @method simulate synlik
#' @seealso \code{\link{synlik-class}}, \code{\link{simulate}}. 
#' @rdname simulate-synlik
#' @examples
#' data(ricker_sl)
#' 
#' # Simulate data
#' simulate(ricker_sl, nsim = 2)
#' 
#' # Simulate statistics
#' simulate(ricker_sl, nsim = 2, stats = TRUE)                                              

setMethod("simulate", 
          signature = signature(object = "synlik"), 
          definition = .simulate.synlik)



