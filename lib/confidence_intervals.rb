# -*- encoding : utf-8 -*-
# Calculate the confidence interval for a samples from a binonial
# distribution using Wilson's score interval.  For more theoretical
# details, please see:
#
#  http://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval#Wilson%20score%20interval
#
# This is a variant of the function suggested here:
#
#  http://www.evanmiller.org/how-not-to-sort-by-average-rating.html
#
# total: the total number of observations
# successes: the subset of those observations that were "successes"
# power: for a 95% confidence interval, this should be 0.05
#
# The naive proportion is (successes / total).  This returns an array
# with the proportions that represent the lower and higher confidence
# intervals around that.

require 'statistics2'

def ci_bounds(successes, total, power)
    if total == 0
        raise RuntimeError, "Can't calculate the CI for 0 observations"
    end
    z = Statistics2.pnormaldist(1 - power/2)
    phat = successes.to_f/total
    offset = z*Math.sqrt((phat*(1 - phat) + z*z/(4*total))/total)
    denominator = 1 + z*z/total
    return [(phat + z*z/(2*total) - offset)/denominator,
            (phat + z*z/(2*total) + offset)/denominator]
end
