context("qcheck")

xb = logical(10); xb[5] = NA
xi = integer(10); xi[5] = NA
xr = double(10); xr[5] = NA
xc = complex(10); xc[5] = NA
xl = as.list(1:10); xl[5] = list(NULL)
xm = matrix(1:9, 3); xm[2, 3] = NA
xd = data.frame(a=1:5, b=1:5); xd$b[3] = NA
xe = new.env(); xe$foo = 1
xf = function(x) x

expect_succ = function(x, rules) {
  expect_true(qcheck(x, rules),
    info=sprintf("vector %s, rules: %s", deparse(substitute(x)), paste(rules, collapse=",")))
  expect_true(qassert(x, rules),
    info=sprintf("vector %s, rules: %s", deparse(substitute(x)), paste(rules, collapse=",")))
}

expect_fail = function(x, rules) {
  expect_false(qcheck(x, rules),
    info=sprintf("vector %s, rules: %s", deparse(substitute(x)), paste(rules, collapse=",")))
  expect_error(qassert(x, rules),
    info=sprintf("vector %s, rules: %s", deparse(substitute(x)), paste(rules, collapse=",")))
}

test_that("type and missingness", {
  expect_succ(xb, "b")
  expect_fail(xb, "B")
  expect_succ(xi, "i")
  expect_fail(xi, "I")
  expect_succ(xr, "r")
  expect_fail(xr, "R")
  expect_succ(xc, "c")
  expect_fail(xc, "C")
  expect_succ(xl, "l")
  expect_fail(xl, "L")
  expect_succ(xm, "m")
  expect_fail(xm, "M")
  expect_succ(xd, "d")
  expect_fail(xd, "D")
  expect_succ(xe, "e")
  expect_succ(xf, "f")

  expect_fail(xd, "b")
  expect_fail(xd, "i")
  expect_fail(xd, "r")
  expect_fail(xd, "c")
  expect_fail(xd, "l")
  expect_fail(xd, "m")
  expect_fail(xl, "e")
  expect_fail(xm, "r")
  expect_fail(xl, "d")
  expect_fail(xl, "f")
})

test_that("length", {
  expect_succ(xb, "b+")
  expect_succ(xb, "b10")
  expect_succ(logical(1), "b+")
  expect_succ(logical(1), "b?")
  expect_succ(logical(1), "b1")
  expect_fail(xb, "b?")
  expect_fail(xb, "b5")
  expect_fail(xb, "b>=50")
  expect_succ(xb, "b<=50")
  expect_succ(xe, "e1")
  expect_fail(xe, "e>=2")
  expect_fail(xe, "f+")
})

test_that("bounds", {
  xx = 1:3
  expect_succ(xx, "i+[1,3]")
  expect_succ(xx, "i+(0,4)")
  expect_succ(xx, "i+(0.9999,3.0001)")
  expect_succ(xx, "i+(0,1e2)")
  expect_fail(xx, "i+(1,3]")
  expect_fail(xx, "i+[1,3)")
  expect_succ(1, "n[0, 100]")

  expect_succ(xx, "i[1,)")
  expect_succ(xx, "i[,3]")
  expect_succ(Inf, "n(1,]")
  expect_succ(-Inf, "n[,1]")
  expect_succ(c(-Inf, 0, Inf), "n[,]")
  expect_fail(Inf, "n(1,)")
  expect_fail(-Inf, "n(,0]")
  expect_fail(c(-Inf, 0, Inf), "n(,]")
  expect_fail(c(-Inf, 0, Inf), "n(,)")
})

test_that("non-atomic types", {
  expect_succ(function() 1, "*")
  expect_fail(function() 1, "b")
  expect_succ(function() 1, "*")
  expect_succ(NULL, "0?")
  expect_fail(xi, "0")
  expect_fail(NULL, "0+")
  expect_succ(NULL, "00")
  expect_fail(xe, "b")
  expect_fail(xf, "b")
  expect_fail(as.symbol("x"), "n")
})

test_that("atomic types", {
  expect_succ(xb, "a+")
  expect_fail(xb, "A+")
  expect_succ(xi, "a+")
  expect_fail(xi, "A+")
  expect_succ(xr, "a+")
  expect_fail(xr, "A+")
  expect_succ(xm, "a+")
  expect_fail(xm, "A+")
  expect_fail(xl, "a+")
  expect_fail(xl, "A+")
  expect_fail(xe, "a+")
  expect_fail(xf, "a+")
})

test_that("optional chars", {
  expect_succ(TRUE, "b*")
  expect_succ(TRUE, "b=1")
  expect_succ(TRUE, "b>=0")
  expect_succ(TRUE, "b>0")
  expect_succ(TRUE, "b<2")
  expect_fail(TRUE, "b=2")
  expect_fail(TRUE, "b>=2")
  expect_fail(TRUE, "b>2")
  expect_fail(TRUE, "b<0")
})

test_that("malformated pattern", {
  expect_error(qassert(1, ""), "[Ee]mpty")
  # expect_warning(expect_error(qassert(1, "ä")), "locale")
  expect_error(qassert(1, "nn"), "length definition")
  expect_error(qassert(1, "n="), "length definition")
  expect_error(qassert(1, "n=="), "length definition")
  expect_error(qassert(1, "n==="), "length definition")
  expect_error(qassert(1, "n?1"), "bound definition")
  expect_error(qassert(1, "n>"))
  expect_error(qassert(1, "nö"))
  expect_error(qassert(1, "n\n"))
  expect_error(qassert(1, "n+a"), "opening")
  expect_error(qassert(1, "n+["), "bound")
  expect_error(qassert(1, "n+[1"), "lower")
  expect_error(qassert(1, "n+[x,]"), "lower")
  expect_error(qassert(1, "n+[,y]"), "upper")
  expect_error(qassert(1, "n*("), "bound definition")
  expect_error(qassert(1, "n*]"), "bound definition")
})

test_that("we get some output", {
  expect_error(qassert(1, "b"), "logical")
  expect_error(qassert(1, "l"), "list")
  expect_error(qassert(1:2, "n?"), "length <=")
})

test_that("empty vectors", {
  expect_succ(integer(0), "i*")
  expect_succ(integer(0), "i*[0,0]")
  expect_succ(integer(0), "n[0,0]")
  expect_fail(integer(0), "r[0,0]")
  expect_fail(integer(0), "*+")
})