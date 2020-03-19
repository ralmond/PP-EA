library(EABN)
library(R.utils)

if (interactive()) {
    branch <- "PP-main"
} else {
    branch <- cmdArg("branch","PP-main")
}

system2("git", "pull")
system2("git", c("checkout",branch))
