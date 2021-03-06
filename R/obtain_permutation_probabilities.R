#' Obtain the probabilities of permutuations
#'
#' @param declaration A random assignment declaration, created by \code{\link{declare_ra}}.
#'
#' @return a vector of probabalities
#' @export
#'
#' @examples
#'
#' declaration <- declare_ra(N = 5, prob_each = c(.49, .51))
#' obtain_num_permutations(declaration)
#' perm_probs <- obtain_permutation_probabilities(declaration)
#' perms <- obtain_permutation_matrix(declaration)
#'
#' # probabilities of assignment from declaration *should* match the average over all permutations
#' true_probabilities <- declaration$probabilities_matrix[,2]
#' true_probabilities
#'
#' # correctly WRONG because the perms have different probs!
#' rowMeans(perms)
#'
#' # correctly correct!
#' perms %*% perm_probs
#'
obtain_permutation_probabilities <-
  function(declaration) {
    if (declaration$ra_type == "simple")  {

      N = nrow(declaration$probabilities_matrix)
      prob_each = declaration$probabilities_matrix[1, ]
      r_parts <- partitions::restrictedparts(N, length(prob_each))
      perms <- permutations(length(prob_each))
      
      r_parts_perms <-
        sapply(1:ncol(r_parts),
               function(i) {
                 apply(perms, 1, function(x)
                   r_parts[, i][x])
               }, simplify = FALSE)
      
      m_eaches <- unique(do.call(cbind, r_parts_perms), MARGIN = 2)
      
      probs <-
        sapply(1:ncol(m_eaches), function(j) {
          prod(prob_each ^ m_eaches[, j])
        })
      
      reps <-
        sapply(1:ncol(m_eaches), function(j) {
          multinomial_coefficient(N = N, m_each = m_eaches[, j])
        })
      permutation_probabilities <-
        rep(probs, reps)
      
    }
    
    if (declaration$ra_type == "complete") {
      permutation_probabilities <-
        complete_ra_permutation_probabilities(
          N = nrow(declaration$probabilities_matrix),
          prob_each = declaration$probabilities_matrix[1, ],
          condition_names = declaration$cleaned_arguments$condition_names
        )
      
    }
    
    if (declaration$ra_type == "blocked") {
      block_prob_each_local <-
        by(
          declaration$probabilities_matrix,
          INDICES = declaration$block_var,
          FUN = function(x) {
            x[1, ]
          }
        )
      block_prob_each_local <-
        lapply(block_prob_each_local, as.vector, mode = "numeric")
      
      ns_per_block_list <-
        lapply(split(declaration$block_var,
                     declaration$block_var),
               length)
      
      condition_names_list <- lapply(1:length(ns_per_block_list),
                                     function(x)
                                       declaration$cleaned_arguments$condition_names)
      
      permutation_probabilities_by_block <-
        mapply(FUN = complete_ra_permutation_probabilities,
               ns_per_block_list,
               block_prob_each_local,
               condition_names_list)
      
      permutation_probabilities <-
        Reduce(f = expand_vector, x = permutation_probabilities_by_block)
      
    }
    
    if (declaration$ra_type == "clustered") {
      prob_each_local <-
        declaration$probabilities_matrix[1, ]
      
      n_per_clust <-
        tapply(declaration$clust_var, declaration$clust_var, length)
      n_clust <- length(n_per_clust)
      
      permutation_probabilities <-
        complete_ra_permutation_probabilities(
          N = n_clust,
          prob_each = declaration$probabilities_matrix[1, ],
          condition_names = declaration$cleaned_arguments$condition_names
        )
      names(permutation_probabilities) <- NULL
      
    }
    
    if (declaration$ra_type == "blocked_and_clustered") {
      # Setup: obtain unique clusters
      n_per_clust <-
        tapply(declaration$clust_var, declaration$clust_var, length)
      n_clust <- length(n_per_clust)
      
      # get the block for each cluster
      clust_blocks <-
        tapply(declaration$block_var, declaration$clust_var, unique)
      
      block_prob_each_local <-
        by(
          declaration$probabilities_matrix,
          INDICES = declaration$block_var,
          FUN = function(x) {
            x[1, ]
          }
        )
      block_prob_each_local <-
        lapply(block_prob_each_local, as.vector, mode = "numeric")
      
      ns_per_block_list <-
        lapply(split(clust_blocks,
                     clust_blocks),
               length)
      
      condition_names_list <- lapply(1:length(ns_per_block_list),
                                     function(x)
                                       declaration$cleaned_arguments$condition_names)
      
      permutation_probabilities_by_block <-
        mapply(FUN = complete_ra_permutation_probabilities,
               ns_per_block_list,
               block_prob_each_local,
               condition_names_list)
      
      permutation_probabilities <-
        Reduce(f = expand_vector, x = permutation_probabilities_by_block)
      
    }
    
    return(permutation_probabilities)
    
  }


# Helper functions --------------------------------------------------------

expand_vector <-
  function(vec_1, vec_2) {
    return(c(vec_1 %*% t(vec_2)))
  }

exponentiate_vector <- function(vec, power) {
  if (power == 1) {
    return(vec)
  }
  if (power == 2) {
    return(c(vec %*% t(vec)))
  }
  if (power > 2) {
    return(c(exponentiate_vector(vec, power - 1) %*% t(vec)))
  }
}

complete_ra_permutation_probabilities <-
  function(N, prob_each, condition_names) {
    m_each_floor <- floor(N * prob_each)
    N_floor <- sum(m_each_floor)
    N_remainder <- N - N_floor
    
    if (N_remainder == 0) {
      num_permutations <-
        multinomial_coefficient(N, m_each = m_each_floor)
      
      permutation_probabilities <-
        rep(1 / num_permutations, num_permutations)
      
    } else {
      prob_each_fix_up <- ((prob_each * N) - m_each_floor) / N_remainder
      
      fix_ups <-
        expand.grid(replicate(N_remainder, condition_names, simplify = FALSE),
                    stringsAsFactors = FALSE)
      
      fix_ups_probs <-
        exponentiate_vector(prob_each_fix_up, power = ncol(fix_ups))
      
      fix_up_conditions <- apply(fix_ups, 1, as.character)
      
      if (is.null(dim(fix_up_conditions))) {
        fix_up_conditions <-
          matrix(fix_up_conditions, nrow = 1, byrow = TRUE)
      }
      
      m_eaches <-
        apply(fix_up_conditions, 2, function(x) {
          sapply(condition_names, function(i)
            sum(x %in% i)) + m_each_floor
        })
      
      num_possibilities <-
        apply(m_eaches, 2, function(x)
          multinomial_coefficient(N, m_each = x))
      
      permutation_probabilities <-
        rep(fix_ups_probs / num_possibilities, num_possibilities)
      
    }
    return(permutation_probabilities)
  }
