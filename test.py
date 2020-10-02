from scipy.misc import comb as c

sum1 = c(47,4)

a1s = [36,30,28,27]
sum2 = sum([c(n, 4) for n in a1s])

a2s = [19,17,16,11,10,8]
sum3 = sum([c(n, 4) for n in a2s])

print(sum1 - sum2 + sum3)
