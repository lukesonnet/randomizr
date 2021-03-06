% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/obtain_permutation_probabilities.R
\name{obtain_permutation_probabilities}
\alias{obtain_permutation_probabilities}
\title{Obtain the probabilities of permutuations}
\usage{
obtain_permutation_probabilities(declaration)
}
\arguments{
\item{declaration}{A random assignment declaration, created by \code{\link{declare_ra}}.}
}
\value{
a vector of probabalities
}
\description{
Obtain the probabilities of permutuations
}
\examples{

declaration <- declare_ra(N = 5, prob_each = c(.49, .51))
obtain_num_permutations(declaration)
perm_probs <- obtain_permutation_probabilities(declaration)
perms <- obtain_permutation_matrix(declaration)

# probabilities of assignment from declaration *should* match the average over all permutations
true_probabilities <- declaration$probabilities_matrix[,2]
true_probabilities

# correctly WRONG because the perms have different probs!
rowMeans(perms)

# correctly correct!
perms \%*\% perm_probs

}
